import 'dart:io';
import 'package:equilibrium/features/mindmaps/models/mind_map.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/mind_map_service.dart';
import '../../core/theme/theme.dart';

class MindMapViewer extends StatefulWidget {
  final String subject;
  final String topic;

  const MindMapViewer({
    super.key,
    required this.subject,
    required this.topic,
  });

  @override
  State<MindMapViewer> createState() => _MindMapViewerState();
}

class _MindMapViewerState extends State<MindMapViewer> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mindMapService = context.watch<MindMapService>();
    final mindMap = mindMapService.getMindMap(widget.subject, widget.topic);

    if (mindMap == null || mindMap.files.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.topic),
        ),
        body: const Center(
          child: Text('Nenhum mapa encontrado'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.topic,
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              widget.subject,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteCurrentFile(mindMap.files.length),
            tooltip: 'Excluir Este Mapa',
          ),
        ],
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: mindMap.files.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final file = mindMap.files[index];
              return _buildImageView(file);
            },
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentPage + 1} / ${mindMap.files.length} - ${mindMap.files[_currentPage].name}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          if (mindMap.files.length > 1)
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.chevron_left,
                        size: 40, color: Colors.white),
                    onPressed: () {
                      if (_currentPage > 0) {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
          if (mindMap.files.length > 1)
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.chevron_right,
                        size: 40, color: Colors.white),
                    onPressed: () {
                      if (_currentPage < mindMap.files.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageView(MindMapFile file) {
    final fileExists = File(file.filePath).existsSync();
    
    if (!fileExists) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text('Arquivo não encontrado:\n${file.name}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final mindMapService = context.read<MindMapService>();
                mindMapService.removeFile(
                  widget.subject,
                  widget.topic,
                  _currentPage,
                );
                Navigator.pop(context);
              },
              child: const Text('Remover arquivo corrompido'),
            ),
          ],
        ),
      );
    }
    
    try {
      final imageFile = File(file.filePath);
      return InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(
          child: Image.file(
            imageFile,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.broken_image, size: 80, color: Colors.white54),
                    const SizedBox(height: 16),
                    const Text(
                      'Erro ao carregar imagem',
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        final mindMapService = context.read<MindMapService>();
                        mindMapService.removeFile(
                          widget.subject,
                          widget.topic,
                          _currentPage,
                        );
                        Navigator.pop(context);
                      },
                      child: const Text('Remover arquivo corrompido'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 80, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Erro ao decodificar imagem',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final mindMapService = context.read<MindMapService>();
                mindMapService.removeFile(
                  widget.subject,
                  widget.topic,
                  _currentPage,
                );
                Navigator.pop(context);
              },
              child: const Text('Remover arquivo corrompido'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _deleteCurrentFile(int totalFiles) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Mapa'),
        content: const Text('Tem certeza que deseja excluir este mapa?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.dangerColor),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final mindMapService = context.read<MindMapService>();
      await mindMapService.removeFile(
        widget.subject,
        widget.topic,
        _currentPage,
      );

      if (mounted) {
        if (totalFiles == 1) {
          Navigator.pop(context);
        } else {
          if (_currentPage >= totalFiles - 1) {
            _pageController.jumpToPage(_currentPage - 1);
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mapa excluído com sucesso'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    }
  }
}