import 'package:equilibrium/features/core/services/database_service.dart';
import 'package:equilibrium/features/core/services/file_upload_service.dart';
import 'package:equilibrium/features/core/theme/theme.dart';
import 'package:equilibrium/features/mindmaps/logic/mind_map_service.dart';
import 'package:equilibrium/features/questions/widgets/mind_map_viewer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class MindMapsScreen extends StatefulWidget {
  const MindMapsScreen({super.key});

  @override
  State<MindMapsScreen> createState() => _MindMapsScreenState();
}

class _MindMapsScreenState extends State<MindMapsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final bool _showOnlyPending = false;
  Map<String, Set<String>>? _cachedTopics;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mindMapService = context.read<MindMapService>();
      mindMapService.ensureInitialized();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final mindMapService = context.watch<MindMapService>();

    if (mindMapService.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carregando mapas mentais...'),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: FutureBuilder(
        future: _loadTopics(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final topicsBySubject = snapshot.data ?? {};
          if (topicsBySubject.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum tópico cadastrado',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Adicione questões primeiro no Autodiagnóstico',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: topicsBySubject.length,
            itemBuilder: (context, index) {
              final subject = topicsBySubject.keys.elementAt(index);
              final topics = topicsBySubject[subject]!.toList()..sort();
              return _SubjectSection(
                subject: subject,
                topics: topics,
                showOnlyPending: _showOnlyPending,
              );
            },
          );
        },
      ),
    );
  }

  Future<Map<String, Set<String>>> _loadTopics() async {
    if (_cachedTopics != null) return _cachedTopics!;
    final databaseService = context.read<DatabaseService>();
    final questions = await databaseService.getQuestions(limit: 1000);
    final topicsBySubject = <String, Set<String>>{};
    for (final question in questions) {
      topicsBySubject.putIfAbsent(question.subject, () => {}).add(question.topic);
    }
    _cachedTopics = topicsBySubject;
    return topicsBySubject;
  }
}

class _SubjectSection extends StatefulWidget {
  final String subject;
  final List<String> topics;
  final bool showOnlyPending;

  const _SubjectSection({
    required this.subject,
    required this.topics,
    required this.showOnlyPending,
  });

  @override
  State<_SubjectSection> createState() => _SubjectSectionState();
}

class _SubjectSectionState extends State<_SubjectSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final mindMapService = context.watch<MindMapService>();
    if (mindMapService.isLoading) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Carregando...'),
          ],
        ),
      );
    }

    final completedTopics = widget.topics.where((topic) {
      return mindMapService.hasMindMaps(widget.subject, topic);
    }).length;
    final totalTopics = widget.topics.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppTheme.lightGray),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.getSubjectColor(widget.subject),
                    AppTheme.getSubjectColor(widget.subject).withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: _isExpanded
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(AppTheme.borderRadius),
                        topRight: Radius.circular(AppTheme.borderRadius),
                      )
                    : BorderRadius.circular(AppTheme.borderRadius),
              ),
              child: Row(
                children: [
                  const Icon(Icons.book, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.subject,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '$completedTopics/$totalTopics tópicos',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: widget.topics.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final topic = widget.topics[index];
                final hasMaps = mindMapService.hasMindMaps(widget.subject, topic);
                if (widget.showOnlyPending && hasMaps) {
                  return const SizedBox.shrink();
                }
                return _TopicItem(
                  subject: widget.subject,
                  topic: topic,
                  hasMaps: hasMaps,
                  fileCount: mindMapService.getFileCount(widget.subject, topic),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _TopicItem extends StatelessWidget {
  final String subject;
  final String topic;
  final bool hasMaps;
  final int fileCount;

  const _TopicItem({
    required this.subject,
    required this.topic,
    required this.hasMaps,
    required this.fileCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasMaps
            ? AppTheme.successColor.withValues(alpha: 0.05)
            : AppTheme.lightGray.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasMaps ? AppTheme.successColor.withValues(alpha: 0.3) : AppTheme.lightGray,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: hasMaps ? AppTheme.successColor : AppTheme.lightGray,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              hasMaps ? Icons.check : Icons.lightbulb_outline,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topic,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (hasMaps)
                  Text(
                    '$fileCount mapa${fileCount != 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (hasMaps) ...[
            IconButton(
              icon: const Icon(Icons.visibility, size: 20),
              onPressed: () => _viewMaps(context),
              tooltip: 'Visualizar',
              color: AppTheme.primaryColor,
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              onPressed: () => _deleteAllMaps(context),
              tooltip: 'Excluir Todos',
              color: AppTheme.dangerColor,
            ),
          ],
          IconButton(
            icon: const Icon(Icons.add_circle, size: 24),
            onPressed: () => _addMaps(context),
            tooltip: hasMaps ? 'Adicionar Mais' : 'Adicionar Mapa',
            color: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  void _addMaps(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _UploadBottomSheet(
        subject: subject,
        topic: topic,
      ),
    );
  }

  void _viewMaps(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MindMapViewer(
          subject: subject,
          topic: topic,
        ),
      ),
    );
  }

  void _deleteAllMaps(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Mapas'),
        content: Text('Tem certeza que deseja excluir todos os $fileCount mapa(s) de "$topic"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.dangerColor),
            child: const Text('Excluir Todos'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final mindMapService = context.read<MindMapService>();
      await mindMapService.removeAllFiles(subject, topic);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$fileCount mapa(s) excluído(s) com sucesso'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    }
  }
}

class _UploadBottomSheet extends StatefulWidget {
  final String subject;
  final String topic;

  const _UploadBottomSheet({
    required this.subject,
    required this.topic,
  });

  @override
  State<_UploadBottomSheet> createState() => _UploadBottomSheetState();
}

class _UploadBottomSheetState extends State<_UploadBottomSheet> {
  final List<File> _selectedFiles = [];
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.upload_file, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Adicionar Mapas Mentais',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.topic,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_selectedFiles.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.all(16),
                itemCount: _selectedFiles.length,
                itemBuilder: (context, index) {
                  final file = _selectedFiles[index];
                  final fileName = file.path.split('/').last;
                  return ListTile(
                    leading: Icon(
                      fileName.toLowerCase().endsWith('.pdf')
                          ? Icons.picture_as_pdf
                          : Icons.image,
                      color: AppTheme.primaryColor,
                    ),
                    title: Text(fileName),
                    subtitle: Text(_formatFileSize(file.lengthSync())),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.dangerColor),
                      onPressed: () {
                        setState(() {
                          _selectedFiles.removeAt(index);
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isUploading ? null : _pickFiles,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Selecionar Arquivos (PDF/Imagem)'),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _selectedFiles.isEmpty || _isUploading
                        ? null
                        : _uploadFiles,
                    icon: _isUploading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.check),
                    label: Text(
                      _isUploading
                          ? 'Enviando...'
                          : 'Salvar ${_selectedFiles.length} Arquivo(s)',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      allowMultiple: true,
    );
    if (result != null) {
      setState(() {
        _selectedFiles.addAll(result.paths.map((path) => File(path!)));
      });
    }
  }

  Future<void> _uploadFiles() async {
    setState(() {
      _isUploading = true;
    });
    try {
      final uploadService = context.read<FileUploadService>();
      final mindMapService = context.read<MindMapService>();
      final mindMapFiles = await uploadService.prepareFiles(_selectedFiles);
      await mindMapService.addFiles(widget.subject, widget.topic, mindMapFiles);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${mindMapFiles.length} mapa(s) adicionado(s) com sucesso!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar arquivos: ${e.toString()}'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}