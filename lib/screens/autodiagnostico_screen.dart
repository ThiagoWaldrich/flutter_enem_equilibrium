import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'dart:io';
import '../services/database_service.dart';
import '../models/question.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';
import '../widgets/questions_grid_view.dart';
import 'mind_maps_screen.dart';

class AutodiagnosticoScreen extends StatefulWidget {
  const AutodiagnosticoScreen({super.key});

  @override
  State<AutodiagnosticoScreen> createState() => _AutodiagnosticoScreenState();
}

class _AutodiagnosticoScreenState extends State<AutodiagnosticoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String? _selectedSubject;
  final _topicController = TextEditingController();
  final _subtopicController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _errorDescriptionController = TextEditingController();

  bool _contentError = false;
  bool _attentionError = false;
  bool _timeError = false;

  File? _imageFile;
  String? _imageData;

  List<Question> _questions = [];
  Map<String, int> _subjectStats = {};
  Map<String, Map<String, dynamic>> _errorStats = {};
  int _totalQuestions = 0;
  bool _isLoading = false;

  String? _filterSubject;
  String? _filterErrorType;

  Question? _questionToEdit;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _topicController.dispose();
    _subtopicController.dispose();
    _descriptionController.dispose();
    _errorDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final databaseService = context.read<DatabaseService>();

    final questions = await databaseService.getQuestions(limit: 1000);
    final stats = await databaseService.getSubjectStats();
    final count = await databaseService.getQuestionCount();

    final errorStats = <String, Map<String, dynamic>>{};
    for (final question in questions) {
      final subject = question.subject;
      if (!errorStats.containsKey(subject)) {
        errorStats[subject] = {
          'total': 0,
          'conteudo': 0,
          'atencao': 0,
          'tempo': 0,
        };
      }
      errorStats[subject]!['total']++;
      if (question.errors['conteudo'] == true) {
        errorStats[subject]!['conteudo']++;
      }
      if (question.errors['atencao'] == true) {
        errorStats[subject]!['atencao']++;
      }
      if (question.errors['tempo'] == true) {
        errorStats[subject]!['tempo']++;
      }
    }

    setState(() {
      _questions = questions;
      _subjectStats = stats;
      _errorStats = errorStats;
      _totalQuestions = count;
      _isLoading = false;
    });
  }

  Map<String, Map<String, int>> _loadTopicStats() {
    final topicStats = <String, Map<String, int>>{};

    for (final question in _questions) {
      final subject = question.subject;
      final topic = question.topic;

      if (!topicStats.containsKey(subject)) {
        topicStats[subject] = {};
      }

      if (!topicStats[subject]!.containsKey(topic)) {
        topicStats[subject]![topic] = 0;
      }

      topicStats[subject]![topic] = topicStats[subject]![topic]! + 1;
    }

    return topicStats;
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();

    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecionar Imagem'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Câmera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _imageFile = File(image.path);
        _imageData = base64Encode(bytes);
      });
    }
  }

  Future<void> _saveQuestion() async {
    if (_selectedSubject == null || _topicController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha Matéria e Tópico!'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
      return;
    }

    final question = Question(
      id: _isEditing
          ? _questionToEdit!.id
          : 'q_${DateTime.now().millisecondsSinceEpoch}',
      subject: _selectedSubject!,
      topic: _topicController.text,
      subtopic:
          _subtopicController.text.isEmpty ? null : _subtopicController.text,
      description: _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text,
      errorDescription: _errorDescriptionController.text.isEmpty
          ? null
          : _errorDescriptionController.text,
      errors: {
        'conteudo': _contentError,
        'atencao': _attentionError,
        'tempo': _timeError,
      },
      image: _imageData != null
          ? QuestionImage(
              data: 'data:image/jpeg;base64,$_imageData',
              name: _imageFile?.path.split('/').last ?? 'image.jpg',
              type: 'image/jpeg',
            )
          : null,
      timestamp: _isEditing
          ? _questionToEdit!.timestamp
          : DateTime.now().toIso8601String(),
    );

    final databaseService = context.read<DatabaseService>();

    if (_isEditing) {
      await databaseService.updateQuestion(question);
    } else {
      await databaseService.insertQuestion(question);
    }

    _clearForm();
    await _loadData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '✅ Questão ${_isEditing ? 'atualizada' : 'salva'} com sucesso!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  void _clearForm() {
    setState(() {
      _questionToEdit = null;
      _isEditing = false;
      _selectedSubject = null;
      _topicController.clear();
      _subtopicController.clear();
      _descriptionController.clear();
      _errorDescriptionController.clear();
      _contentError = false;
      _attentionError = false;
      _timeError = false;
      _imageFile = null;
      _imageData = null;
    });
  }

  Future<void> _editQuestion(Question question) async {
    setState(() {
      _questionToEdit = question;
      _isEditing = true;

      _selectedSubject = question.subject;
      _topicController.text = question.topic;
      _subtopicController.text = question.subtopic ?? '';
      _descriptionController.text = question.description ?? '';
      _errorDescriptionController.text = question.errorDescription ?? '';
      _contentError = question.errors['conteudo'] ?? false;
      _attentionError = question.errors['atencao'] ?? false;
      _timeError = question.errors['tempo'] ?? false;

      if (question.image != null) {
        _imageData = question.image!.data.split(',').last;
      }
    });

    _tabController.animateTo(0);
  }

  Future<void> _deleteQuestion(Question question) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Questão'),
        content: const Text('Tem certeza que deseja excluir esta questão?'),
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

    if (confirm == true) {
      final databaseService = context.read<DatabaseService>();
      await databaseService.deleteQuestions([question.id]);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Questão excluída com sucesso'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
      }
    }
  }

  Future<void> _exportData() async {
    final data = _questions
        .map((q) => {
              'materia': q.subject,
              'topico': q.topic,
              'subtopico': q.subtopic ?? '',
              'descricao': q.description ?? '',
              'erro_descricao': q.errorDescription ?? '',
              'erro_conteudo': q.errors['conteudo'] ?? false,
              'erro_atencao': q.errors['atencao'] ?? false,
              'erro_tempo': q.errors['tempo'] ?? false,
              'data': q.timestamp,
            })
        .toList();

    final jsonData = jsonEncode(data);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exportar Dados'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total de questões: ${_questions.length}'),
            const SizedBox(height: 16),
            const Text(
              'Dados preparados para exportação em formato JSON.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            SelectableText(
              jsonData.length > 200
                  ? '${jsonData.substring(0, 200)}...'
                  : jsonData,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  List<Question> _getFilteredQuestions() {
    var filtered = _questions;

    if (_filterSubject != null) {
      filtered = filtered.where((q) => q.subject == _filterSubject).toList();
    }

    if (_filterErrorType != null) {
      filtered = filtered.where((q) {
        return q.errors[_filterErrorType] == true;
      }).toList();
    }

    return filtered;
  }

  void _showQuestionDetails(Question question) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(question.subject),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tópico: ${question.topic}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (question.subtopic != null)
                Text('Subtópico: ${question.subtopic}'),
              const SizedBox(height: 16),
              if (question.description != null) ...[
                const Text(
                  'Descrição:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(question.description!),
                const SizedBox(height: 16),
              ],
              if (question.errorDescription != null) ...[
                const Text(
                  'Análise do Erro:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(question.errorDescription!),
                const SizedBox(height: 16),
              ],
              const Text(
                'Tipos de Erro:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Row(
                children: [
                  if (question.errors['conteudo'] == true)
                    Chip(
                      label: const Text('Conteúdo'),
                      backgroundColor: Colors.red.withOpacity(0.1),
                      side: BorderSide(color: Colors.red.withOpacity(0.3)),
                    ),
                  const SizedBox(width: 8),
                  if (question.errors['atencao'] == true)
                    Chip(
                      label: const Text('Atenção'),
                      backgroundColor: Colors.orange.withOpacity(0.1),
                      side: BorderSide(color: Colors.orange.withOpacity(0.3)),
                    ),
                  const SizedBox(width: 8),
                  if (question.errors['tempo'] == true)
                    Chip(
                      label: const Text('Tempo'),
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      side: BorderSide(color: Colors.blue.withOpacity(0.3)),
                    ),
                ],
              ),
              if (question.image != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Imagem:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      base64Decode(question.image!.data.split(',').last),
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _editQuestion(question);
            },
            child: const Text('Editar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('📊 Autodiagnóstico ENEM'),
        backgroundColor: const Color(0xFF011B3D),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: _exportData,
            tooltip: 'Exportar Dados',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
            tooltip: 'Atualizar',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 13,
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(
              icon: Icon(Icons.add, color: Colors.white),
              text: 'Cadastrar',
            ),
            Tab(
              icon: Icon(Icons.bar_chart, color: Colors.white),
              text: 'Gráficos',
            ),
            Tab(
              icon: Icon(Icons.table_chart, color: Colors.white),
              text: 'Planilha',
            ),
            Tab(
              icon: Icon(Icons.menu_book, color: Colors.white),
              text: 'Caderno',
            ),
            Tab(
              icon: Icon(Icons.lightbulb, color: Colors.white),
              text: 'Mapas',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRegisterTab(),
          _buildChartsTab(),
          _buildDataTab(),
          _buildNotebookTab(),
          const MindMapsScreen(),
        ],
      ),
    );
  }

  Widget _buildRegisterTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _isEditing ? Icons.edit : Icons.add_circle_outline,
                      color: AppTheme.primaryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEditing ? 'Editar Questão' : 'Cadastrar Questão',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          _isEditing
                              ? 'Atualize os dados da questão'
                              : 'Registre questões que você errou para análise',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),

              DropdownButtonFormField<String>(
                value: _selectedSubject,
                decoration: const InputDecoration(
                  labelText: 'Matéria *',
                  prefixIcon: Icon(Icons.book),
                ),
                items: AppConstants.predefinedSubjects
                    .map((s) => s['name'] as String)
                    .toSet()
                    .map((name) => DropdownMenuItem(
                          value: name,
                          child: Text(name),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedSubject = value),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _topicController,
                decoration: const InputDecoration(
                  labelText: 'Tópico *',
                  prefixIcon: Icon(Icons.topic),
                  hintText: 'Ex: Termodinâmica, Revolução Industrial...',
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _subtopicController,
                decoration: const InputDecoration(
                  labelText: 'Subtópico',
                  prefixIcon: Icon(Icons.subdirectory_arrow_right),
                  hintText: 'Ex: Primeira Lei, Era Vargas...',
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descrição da Questão',
                  hintText: 'Resuma o enunciado ou cite a fonte...',
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _errorDescriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Análise do Erro',
                  hintText: 'Explique POR QUE você errou e o que aprendeu...',
                  prefixIcon: Icon(Icons.psychology),
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 24),

              // Seção de imagem
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.lightGray.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.lightGray),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.image,
                            size: 20, color: AppTheme.textSecondary),
                        const SizedBox(width: 8),
                        const Text(
                          'Imagem da Questão',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_imageFile != null)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _imageFile!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.close,
                                    color: Colors.white, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _imageFile = null;
                                    _imageData = null;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      )
                    else if (_imageData != null)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              base64Decode(_imageData!),
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.close,
                                    color: Colors.white, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _imageFile = null;
                                    _imageData = null;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('Adicionar Imagem'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Tipos de erro
              const Text(
                'Tipo de Erro',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Selecione um ou mais tipos de erro',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 12),

              _ErrorCheckbox(
                label: 'Conteúdo',
                subtitle: 'Não sabia o conteúdo necessário',
                icon: Icons.menu_book,
                value: _contentError,
                onChanged: (value) => setState(() => _contentError = value),
              ),
              const SizedBox(height: 8),
              _ErrorCheckbox(
                label: 'Atenção',
                subtitle: 'Erro de interpretação ou distração',
                icon: Icons.visibility_off,
                value: _attentionError,
                onChanged: (value) => setState(() => _attentionError = value),
              ),
              const SizedBox(height: 8),
              _ErrorCheckbox(
                label: 'Tempo',
                subtitle: 'Não tive tempo suficiente',
                icon: Icons.access_time,
                value: _timeError,
                onChanged: (value) => setState(() => _timeError = value),
              ),

              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _clearForm,
                      child: const Text('Limpar Formulário'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _saveQuestion,
                      icon: Icon(_isEditing ? Icons.update : Icons.check),
                      label: Text(_isEditing
                          ? 'Atualizar Questão'
                          : 'Adicionar Questão'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChartsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final sortedStats = _subjectStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Calcular estatísticas de tópicos por matéria
    final topicStats = _loadTopicStats();

    // Obter a matéria selecionada para o gráfico
    String? selectedChartSubject;
    if (_selectedSubject != null && topicStats.containsKey(_selectedSubject)) {
      selectedChartSubject = _selectedSubject;
    } else if (topicStats.isNotEmpty) {
      selectedChartSubject = topicStats.keys.first;
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Cards de resumo
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total de Questões',
                    _totalQuestions.toString(),
                    Icons.quiz,
                    AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Matérias',
                    _subjectStats.length.toString(),
                    Icons.book,
                    AppTheme.successColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Estatísticas de erros
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tipos de Erros',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildErrorStatCard(
                          'Conteúdo',
                          _countErrorType('conteudo'),
                          Colors.red,
                          Icons.menu_book,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildErrorStatCard(
                          'Atenção',
                          _countErrorType('atencao'),
                          Colors.orange,
                          Icons.visibility_off,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildErrorStatCard(
                          'Tempo',
                          _countErrorType('tempo'),
                          Colors.blue,
                          Icons.access_time,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Gráfico de Pizza
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Distribuição por Matéria',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_totalQuestions > 0)
                    SizedBox(
                      height: 250,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 60,
                          sections: sortedStats.take(10).map((entry) {
                            final color = AppTheme.getSubjectColor(entry.key);
                            final percentage = (_totalQuestions > 0
                                    ? (entry.value / _totalQuestions * 100)
                                    : 0)
                                .round();

                            return PieChartSectionData(
                              value: entry.value.toDouble(),
                              title: '$percentage%',
                              color: color,
                              radius: 80,
                              titleStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    )
                  else
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text('Nenhum dado disponível'),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    children: sortedStats.take(10).map((entry) {
                      final color = AppTheme.getSubjectColor(entry.key);
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${entry.key} (${entry.value})',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Gráfico de Barras (Tópicos por Matéria) - CORRIGIDO
            if (selectedChartSubject != null &&
                topicStats.containsKey(selectedChartSubject))
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Tópicos de $selectedChartSubject',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        if (topicStats.length > 1)
                          StatefulBuilder(
                            builder: (context, setLocalState) {
                              return DropdownButton<String>(
                                value: selectedChartSubject,
                                items: topicStats.keys.map((subject) {
                                  return DropdownMenuItem(
                                    value: subject,
                                    child: Text(
                                      subject,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  // CORREÇÃO: Usar Future.delayed para evitar o erro do mouse_tracker
                                  Future.delayed(Duration.zero, () {
                                    if (mounted && value != null) {
                                      setState(() {
                                        _selectedSubject = value;
                                      });
                                    }
                                  });
                                },
                                underline: Container(),
                              );
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (topicStats[selectedChartSubject]!.isNotEmpty)
                      _buildTopicsBarChart(selectedChartSubject!,
                          topicStats[selectedChartSubject]!)
                    else
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Text(
                              'Nenhum tópico cadastrado para esta matéria'),
                        ),
                      ),
                    if (topicStats[selectedChartSubject]!.isNotEmpty)
                      _buildTopicsLegend(selectedChartSubject!,
                          topicStats[selectedChartSubject]!),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicsBarChart(String subject, Map<String, int> topicsData) {
    final topicsEntries = topicsData.entries.toList();
    topicsEntries.sort((a, b) => b.value.compareTo(a.value));

    // CORREÇÃO: Verificar se há dados suficientes
    if (topicsEntries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text('Nenhum dado disponível para o gráfico'),
        ),
      );
    }

    final barGroups = topicsEntries.asMap().entries.map((entry) {
      final color = AppTheme.getSubjectColor(subject);
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value.value.toDouble(),
            color: color,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
        ],
      );
    }).toList();

    final maxValue = topicsEntries.isNotEmpty
        ? topicsEntries
                .map((e) => e.value)
                .reduce((a, b) => a > b ? a : b)
                .toDouble() *
            1.2
        : 0;

    return SizedBox(
      height: 400,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxValue.toDouble(),
          // CORREÇÃO: Configurar barTouchData para evitar RangeError
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.blueGrey.withOpacity(0.9),
              tooltipPadding: const EdgeInsets.all(8),
              tooltipMargin: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                // CORREÇÃO: Verificar se o índice está dentro dos limites
                if (groupIndex < 0 || groupIndex >= topicsEntries.length) {
                  return null;
                }
                final topic = topicsEntries[groupIndex].key;
                final value = topicsEntries[groupIndex].value;
                return BarTooltipItem(
                  '$topic\n$value questão${value != 1 ? 's' : ''}',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                );
              },
            ),
            touchCallback: (event, response) {
              // CORREÇÃO: Verificar se response não é null
              if (response != null && response.spot != null) {
                final spot = response.spot!;
                if (spot.touchedBarGroupIndex >= 0 &&
                    spot.touchedBarGroupIndex < topicsEntries.length) {
                  // Interação válida
                }
              }
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  // CORREÇÃO: Verificar se o índice está dentro dos limites
                  final index = value.toInt();
                  if (index >= 0 && index < topicsEntries.length) {
                    final topic = topicsEntries[index].key;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: Text(
                          topic.length > 15
                              ? '${topic.substring(0, 15)}...'
                              : topic,
                          style: const TextStyle(fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                reservedSize: 60,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 11),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
          ),
          borderData: FlBorderData(show: false),
          barGroups: barGroups,
        ),
      ),
    );
  }

  Widget _buildTopicsLegend(String subject, Map<String, int> topicsData) {
    final topicsEntries = topicsData.entries.toList();
    topicsEntries.sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Legenda de Tópicos:',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: topicsEntries.take(10).map((entry) {
            return Chip(
              label: Text(
                '${entry.key} (${entry.value})',
                style: const TextStyle(fontSize: 12),
              ),
              backgroundColor:
                  AppTheme.getSubjectColor(subject).withOpacity(0.1),
              side: BorderSide.none,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDataTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Criar cópia para evitar modificar a lista original
    final allQuestions = List<Question>.from(_questions);

    // Aplicar filtros
    List<Question> filteredQuestions = allQuestions;

    if (_filterSubject != null && _filterSubject!.isNotEmpty) {
      filteredQuestions =
          filteredQuestions.where((q) => q.subject == _filterSubject).toList();
    }

    if (_filterErrorType != null && _filterErrorType!.isNotEmpty) {
      filteredQuestions = filteredQuestions.where((q) {
        return q.errors[_filterErrorType] == true;
      }).toList();
    }

    // Ordenar por matéria e tópico
    filteredQuestions.sort((a, b) {
      final subjectCompare = a.subject.compareTo(b.subject);
      if (subjectCompare != 0) return subjectCompare;
      return a.topic.compareTo(b.topic);
    });

    return Column(
      children: [
        // Filtros
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Dropdown de Matéria
              Container(
                height: 50,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButton<String?>(
                    value: _filterSubject,
                    isExpanded: true,
                    underline: const SizedBox(), // Remove a linha padrão
                    hint: const Text('Filtrar por matéria'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Todas as matérias'),
                      ),
                      ..._subjectStats.keys
                          .map((subject) => DropdownMenuItem<String?>(
                                value: subject,
                                child: Text(subject),
                              ))
                          .toList(),
                    ],
                    onChanged: (String? value) {
                      setState(() {
                        _filterSubject = value;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 12),
              Container(
                height: 50,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButton<String>(
                    value: _filterErrorType,
                    isExpanded: true,
                    underline: const SizedBox(), // Remove a linha padrão
                    hint: const Text('Filtrar por tipo de erro'),
                    items: const [
                      DropdownMenuItem<String>(
                          value: 'all', child: Text('Todos os erros')),
                      DropdownMenuItem<String>(
                          value: 'conteudo', child: Text('Erro de conteúdo')),
                      DropdownMenuItem<String>(
                          value: 'atencao', child: Text('Erro de atenção')),
                      DropdownMenuItem<String>(
                          value: 'tempo', child: Text('Erro de tempo')),
                    ],
                    onChanged: (String? value) {
                      setState(() {
                        _filterErrorType = value;
                      });
                    },
                  ),
                ),
              ),

              // Botão Limpar
              if (_filterSubject != null || _filterErrorType != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _filterSubject = null;
                          _filterErrorType = null;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.clear,
                                size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              'Limpar filtros',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Lista de questões
        Expanded(
          child: filteredQuestions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhuma questão encontrada',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  // MUDANÇA: ListView.separated em vez de ListView.builder
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredQuestions.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final question = filteredQuestions[index];
                    return Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: Container(
                          width: 4,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppTheme.getSubjectColor(question.subject),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        title: Text(
                          question.subject,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${question.topic}${question.subtopic != null ? " - ${question.subtopic}" : ""}',
                            ),
                            if (question.description != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                question.description!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (question.errors['conteudo'] == true)
                                  _buildErrorBadge('C', Colors.red),
                                if (question.errors['atencao'] == true)
                                  _buildErrorBadge('A', Colors.orange),
                                if (question.errors['tempo'] == true)
                                  _buildErrorBadge('T', Colors.blue),
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (question.image != null)
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  color: AppTheme.infoColor),
                              onPressed: () => _editQuestion(question),
                              tooltip: 'Editar questão',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: AppTheme.dangerColor),
                              onPressed: () => _deleteQuestion(question),
                              tooltip: 'Excluir questão',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        // onTap: () {
                        //   _showQuestionDetails(question);
                        // },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildNotebookTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_questions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma questão cadastrada ainda',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Use a aba "Cadastrar" para adicionar questões',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }
    final sortedQuestions = List<Question>.from(_questions);
    sortedQuestions.sort((a, b) {
      // Primeiro ordena por matéria
      final subjectComparison = a.subject.compareTo(b.subject);
      if (subjectComparison != 0) return subjectComparison;

      // Depois ordena por tópico dentro da mesma matéria
      return a.topic.compareTo(b.topic);
    });

    return QuestionsGridView(
        questions: sortedQuestions); // ← Use sortedQuestions
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorStatCard(
      String label, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBadge(String letter, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  int _countErrorType(String errorType) {
    return _questions.where((q) => q.errors[errorType] == true).length;
  }
}

class _ErrorCheckbox extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool value;
  final Function(bool) onChanged;

  const _ErrorCheckbox({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: value
            ? AppTheme.primaryColor.withOpacity(0.05)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? AppTheme.primaryColor : AppTheme.lightGray,
          width: value ? 2 : 1,
        ),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: (val) => onChanged(val ?? false),
        title: Row(
          children: [
            Icon(icon,
                size: 20,
                color: value ? AppTheme.primaryColor : AppTheme.textSecondary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: value ? AppTheme.primaryColor : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        controlAffinity: ListTileControlAffinity.trailing,
        activeColor: AppTheme.primaryColor,
      ),
    );
  }
}
