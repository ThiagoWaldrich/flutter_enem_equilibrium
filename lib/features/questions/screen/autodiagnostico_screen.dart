import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:equilibrium/features/analytics/screen/register_tab.dart';
import 'package:equilibrium/features/analytics/screen/charts_tab.dart';
import 'package:equilibrium/features/questions/models/question.dart';
import 'package:equilibrium/features/questions/widgets/questions_grid_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import '../../questions/models/question_image.dart';
import '../../core/services/database_service.dart';
import '../../core/theme/theme.dart';
import '../../mindmaps/screen/mind_maps_screen.dart';
import '../../core/utils/subject_data_constants.dart';

class AutodiagnosticoScreen extends StatefulWidget {
  const AutodiagnosticoScreen({super.key});

  @override
  State<AutodiagnosticoScreen> createState() => _AutodiagnosticoScreenState();
}

class _AutodiagnosticoScreenState extends State<AutodiagnosticoScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late TabController _tabController;

  String? _selectedSubject;
  String? _selectedTopic;
  String? _selectedSubtopic;
  String? _selectedYear;
  String? _selectedSource;

  final List<String> _availableTopics = [];
  final List<String> _availableSubtopics = [];

  final _errorDescriptionController = TextEditingController();

  bool _contentError = false;
  bool _attentionError = false;
  bool _timeError = false;

  String? _imageFilePath;

  static const int _pageSize = 50;
  int _currentPage = 0;
  List<Question> _displayedQuestions = [];
  bool _hasMoreQuestions = true;

  Map<String, int> _subjectStats = {};
  Map<String, int> _yearStats = {};
  Map<String, int> _sourceStats = {};
  Map<String, Map<String, dynamic>> _errorStats = {};
  int _totalQuestions = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;

  final ValueNotifier<String?> _filterSubjectNotifier = ValueNotifier(null);
  final ValueNotifier<String?> _filterYearNotifier = ValueNotifier(null);
  final ValueNotifier<String?> _filterSourceNotifier = ValueNotifier(null);
  final ValueNotifier<String?> _filterErrorTypeNotifier = ValueNotifier(null);

  Question? _questionToEdit;
  bool _isEditing = false;

  Timer? _filterDebounceTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadInitialData();

    _filterSubjectNotifier.addListener(_onFilterChanged);
    _filterYearNotifier.addListener(_onFilterChanged);
    _filterSourceNotifier.addListener(_onFilterChanged);
    _filterErrorTypeNotifier.addListener(_onFilterChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _errorDescriptionController.dispose();
    _filterSubjectNotifier.dispose();
    _filterYearNotifier.dispose();
    _filterSourceNotifier.dispose();
    _filterErrorTypeNotifier.dispose();
    _filterDebounceTimer?.cancel();

    _displayedQuestions.clear();
    _subjectStats.clear();
    _yearStats.clear();
    _sourceStats.clear();
    _errorStats.clear();

    super.dispose();
  }

  void _onFilterChanged() {
    _filterDebounceTimer?.cancel();
    _filterDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      _loadFilteredQuestions();
    });
  }

  void _updateTopics() {
    _availableTopics.clear();
    _selectedTopic = null;
    _availableSubtopics.clear();
    _selectedSubtopic = null;

    if (_selectedSubject != null &&
        SubjectDataConstants.subjectData.containsKey(_selectedSubject)) {
      _availableTopics
          .addAll(SubjectDataConstants.subjectData[_selectedSubject]!.keys);
    }
    setState(() {});
  }

  void _updateSubtopics() {
    _availableSubtopics.clear();
    _selectedSubtopic = null;

    if (_selectedSubject != null &&
        _selectedTopic != null &&
        SubjectDataConstants.subjectData.containsKey(_selectedSubject) &&
        SubjectDataConstants.subjectData[_selectedSubject]!
            .containsKey(_selectedTopic)) {
      _availableSubtopics.addAll(
          SubjectDataConstants.subjectData[_selectedSubject]![_selectedTopic]!);
    }
    setState(() {});
  }

  Future<void> _loadInitialData() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final databaseService = context.read<DatabaseService>();

    try {
      final results = await Future.wait([
        databaseService.getSubjectStats(),
        databaseService.getYearStats(),
        databaseService.getSourceStats(),
        databaseService.getQuestionCount(),
      ]);

      final questions = await databaseService.getQuestions(
        limit: _pageSize,
      );

      final errorStats = await _calculateErrorStats(databaseService);

      if (!mounted) return;

      setState(() {
        _subjectStats = results[0] as Map<String, int>;
        _yearStats = results[1] as Map<String, int>;
        _sourceStats = results[2] as Map<String, int>;
        _totalQuestions = results[3] as int;
        _errorStats = errorStats;
        _displayedQuestions = questions;
        _currentPage = 0;
        _hasMoreQuestions = questions.length >= _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar dados: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Map<String, Map<String, dynamic>>> _calculateErrorStats(
      DatabaseService db) async {
    final questions = await db.getQuestions(limit: 1000);

    final errorStats = <String, Map<String, dynamic>>{};
    for (final q in questions) {
      final subject = q.subject;
      if (!errorStats.containsKey(subject)) {
        errorStats[subject] = {
          'total': 0,
          'conteudo': 0,
          'atencao': 0,
          'tempo': 0,
        };
      }
      errorStats[subject]!['total']++;
      if (q.errorTypes.contains(ErrorType.conteudo))
        errorStats[subject]!['conteudo']++;
      if (q.errorTypes.contains(ErrorType.atencao))
        errorStats[subject]!['conteudo']++;
      if (q.errorTypes.contains(ErrorType.tempo))
        errorStats[subject]!['conteudo']++;
    }
    return errorStats;
  }

  Future<void> _loadFilteredQuestions() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _displayedQuestions.clear();
    });

    final databaseService = context.read<DatabaseService>();

    try {
      final questions = await databaseService.getQuestions(
        limit: _pageSize,
        subject: _filterSubjectNotifier.value,
        year: _filterYearNotifier.value,
        source: _filterSourceNotifier.value,
      );

      var filtered = questions;
      if (_filterErrorTypeNotifier.value != null) {
        // Converter string para ErrorType
        ErrorType? errorType;
        switch (_filterErrorTypeNotifier.value) {
          case 'conteudo':
            errorType = ErrorType.conteudo;
            break;
          case 'atencao':
            errorType = ErrorType.atencao;
            break;
          case 'tempo':
            errorType = ErrorType.tempo;
            break;
        }

        if (errorType != null) {
          filtered =
              questions.where((q) => q.errorTypes.contains(errorType)).toList();
        }
      }

      if (!mounted) return;

      setState(() {
        _displayedQuestions = filtered;
        _hasMoreQuestions = questions.length >= _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao filtrar: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreQuestions() async {
    if (_isLoadingMore || !_hasMoreQuestions) return;

    setState(() => _isLoadingMore = true);

    final databaseService = context.read<DatabaseService>();
    _currentPage++;

    try {
      final moreQuestions = await databaseService.getQuestions(
        limit: _pageSize,
        offset: _currentPage * _pageSize,
        subject: _filterSubjectNotifier.value,
        year: _filterYearNotifier.value,
        source: _filterSourceNotifier.value,
      );

      if (!mounted) return;

      setState(() {
        _displayedQuestions.addAll(moreQuestions);
        _hasMoreQuestions = moreQuestions.length >= _pageSize;
        _isLoadingMore = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar mais: $e');
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _pickImage() async {
    try {
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
            ],
          ),
        ),
      );

      if (source == null) return;

      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );

      if (image == null) return;

      final tempFile = File(image.path);
      final fileSize = await tempFile.length();

      if (fileSize > 3 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Imagem muito grande. Máximo 3MB.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // 🔹 AQUI ESTÁ A PARTE CRÍTICA 🔹
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(image.path)}';

      final savedImage = await tempFile.copy('${directory.path}/$fileName');

      setState(() {
        _imageFilePath = savedImage.path; // ✅ caminho permanente
      });
    } catch (e) {
      debugPrint('Erro ao selecionar imagem: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao selecionar imagem'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveQuestion() async {
    if (_selectedSubject == null || _selectedTopic == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha Matéria e Tópico!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedYear == null || _selectedYear!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe o ano da prova!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final question = Question(
      id: _isEditing
          ? _questionToEdit!.id
          : 'q_${DateTime.now().millisecondsSinceEpoch}',
      subject: _selectedSubject!,
      topic: _selectedTopic!,
      subtopic: _selectedSubtopic,
      year: _selectedYear,
      source: _selectedSource,
      errorDescription: _errorDescriptionController.text.isEmpty
          ? null
          : _errorDescriptionController.text,
      errorTypes: {
        if (_contentError) ErrorType.conteudo,
        if (_attentionError) ErrorType.atencao,
        if (_timeError) ErrorType.tempo,
      },
      image: _imageFilePath != null
          ? QuestionImage(
              filePath: _imageFilePath!,
              name: _imageFilePath!.split('/').last,
              type: 'image/jpeg',
            )
          : (_isEditing ? _questionToEdit!.image : null),
      timestamp: _isEditing ? _questionToEdit!.timestamp : DateTime.now(),
    );

    final databaseService = context.read<DatabaseService>();

    try {
      if (_isEditing) {
        await databaseService.updateQuestion(question);
      } else {
        await databaseService.insertQuestion(question);
      }

      _clearForm();
      await _loadInitialData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Questão ${_isEditing ? 'atualizada' : 'salva'}!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Erro ao salvar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao salvar questão'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearForm() {
    setState(() {
      _questionToEdit = null;
      _isEditing = false;
      _selectedSubject = null;
      _selectedTopic = null;
      _selectedSubtopic = null;
      _selectedYear = null;
      _selectedSource = null;
      _availableTopics.clear();
      _availableSubtopics.clear();
      _errorDescriptionController.clear();
      _contentError = false;
      _attentionError = false;
      _timeError = false;
      _imageFilePath = null;
    });
  }

  Future<void> _editQuestion(Question question) async {
    setState(() {
      _questionToEdit = question;
      _isEditing = true;

      _selectedSubject = question.subject;
      _selectedTopic = question.topic;
      _selectedSubtopic = question.subtopic;
      _selectedYear = question.year;
      _selectedSource = question.source;
      _errorDescriptionController.text = question.errorDescription ?? '';
      _contentError = question.errorTypes.contains(ErrorType.conteudo);
      _attentionError = question.errorTypes.contains(ErrorType.atencao);
      _timeError = question.errorTypes.contains(ErrorType.tempo);

      _imageFilePath = null;
    });

    _updateTopics();
    _updateSubtopics();

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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final databaseService = context.read<DatabaseService>();
      await databaseService.deleteQuestions([question.id]);
      await _loadInitialData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Questão excluída'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // Future<void> _exportData() async {
  //   final data = _displayedQuestions
  //       .map((q) => {
  //             'materia': q.subject,
  //             'topico': q.topic,
  //             'subtopico': q.subtopic ?? '',
  //             'ano': q.year ?? '',
  //             'fonte': q.source ?? '',
  //             'erro_descricao': q.errorDescription ?? '',
  //             'erro_conteudo': q.errors['conteudo'] ?? false,
  //             'erro_atencao': q.errors['atencao'] ?? false,
  //             'erro_tempo': q.errors['tempo'] ?? false,
  //             'data': q.timestamp,
  //           })
  //       .toList();
  // }

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
              if (question.year != null) Text('Ano: ${question.year}'),
              if (question.source != null) Text('Fonte: ${question.source}'),
              const SizedBox(height: 16),
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
              Wrap(
                spacing: 8,
                children: [
                  if (question.hasError(ErrorType.conteudo) == true)
                    Chip(
                      label: const Text('Conteúdo'),
                      backgroundColor: Colors.red.withValues(alpha: 0.1),
                    ),
                  if (question.hasError(ErrorType.conteudo) == true)
                    Chip(
                      label: const Text('Atenção'),
                      backgroundColor: Colors.orange.withValues(alpha: 0.1),
                    ),
                  if (question.hasError(ErrorType.conteudo) == true)
                    Chip(
                      label: const Text('Tempo'),
                      backgroundColor: Colors.blue.withValues(alpha: 0.1),
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
                    child: Image.file(
                      File(question.image!.filePath),
                      fit: BoxFit.cover,
                      cacheHeight: 400,
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
    super.build(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('📊 Autodiagnóstico ENEM'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadInitialData,
            tooltip: 'Atualizar',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.add), text: 'Cadastrar'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Gráficos'),
            Tab(icon: Icon(Icons.table_chart), text: 'Planilha'),
            Tab(icon: Icon(Icons.menu_book), text: 'Caderno'),
            Tab(icon: Icon(Icons.lightbulb), text: 'Mapas'),
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
    return RegisterTab(
      selectedSubject: _selectedSubject,
      selectedTopic: _selectedTopic,
      selectedSubtopic: _selectedSubtopic,
      selectedYear: _selectedYear,
      selectedSource: _selectedSource,
      availableTopics: _availableTopics,
      availableSubtopics: _availableSubtopics,
      topicController: TextEditingController(),
      subtopicController: TextEditingController(),
      errorDescriptionController: _errorDescriptionController,
      yearController: TextEditingController(),
      sourceController: TextEditingController(),
      contentError: _contentError,
      attentionError: _attentionError,
      timeError: _timeError,
      imageFile: _imageFilePath != null ? File(_imageFilePath!) : null,
      imageFilePath: _imageFilePath,
      isEditing: _isEditing,
      questionToEdit: _questionToEdit,
      onSubjectChanged: (value) {
        setState(() => _selectedSubject = value);
        _updateTopics();
      },
      onTopicChanged: (value) {
        setState(() => _selectedTopic = value);
        _updateSubtopics();
      },
      onSubtopicChanged: (value) => setState(() => _selectedSubtopic = value),
      onYearChanged: (value) => setState(() => _selectedYear = value),
      onSourceChanged: (value) => setState(() => _selectedSource = value),
      onContentErrorChanged: (value) => setState(() => _contentError = value),
      onAttentionErrorChanged: (value) =>
          setState(() => _attentionError = value),
      onTimeErrorChanged: (value) => setState(() => _timeError = value),
      onPickImage: _pickImage,
      onClearImage: () => setState(() => _imageFilePath = null),
      onSaveQuestion: _saveQuestion,
      onClearForm: _clearForm,
    );
  }

  Widget _buildChartsTab() {
    return ChartsTab(
      stats: {},
      questions: _displayedQuestions,
      isLoading: _isLoading,
      subjectStats: _subjectStats,
      yearStats: _yearStats,
      sourceStats: _sourceStats,
      errorStats: _errorStats,
      totalQuestions: _totalQuestions,
    );
  }

  Widget _buildDataTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              ValueListenableBuilder<String?>(
                valueListenable: _filterSubjectNotifier,
                builder: (context, filterValue, _) {
                  return DropdownButtonFormField<String?>(
                    initialValue: filterValue,
                    decoration: const InputDecoration(
                      labelText: 'Filtrar por matéria',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todas')),
                      ..._subjectStats.keys.map(
                          (s) => DropdownMenuItem(value: s, child: Text(s))),
                    ],
                    onChanged: (value) => _filterSubjectNotifier.value = value,
                  );
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _displayedQuestions.isEmpty
              ? const Center(child: Text('Nenhuma questão encontrada'))
              : NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    if (!_isLoadingMore &&
                        _hasMoreQuestions &&
                        scrollInfo.metrics.pixels >=
                            scrollInfo.metrics.maxScrollExtent - 200) {
                      _loadMoreQuestions();
                    }
                    return false;
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _displayedQuestions.length +
                        (_hasMoreQuestions ? 1 : 0),
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      if (index >= _displayedQuestions.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final question = _displayedQuestions[index];
                      return Card(
                        child: ListTile(
                          leading: Container(
                            width: 4,
                            height: 50,
                            color: AppTheme.getSubjectColor(question.subject),
                          ),
                          title: Text(question.subject,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(question.topic),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon:
                                    const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editQuestion(question),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteQuestion(question),
                              ),
                            ],
                          ),
                          onTap: () => _showQuestionDetails(question),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildNotebookTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_displayedQuestions.isEmpty) {
      return const Center(child: Text('Nenhuma questão cadastrada'));
    }

    return QuestionsGridView(
      questions: _displayedQuestions,
    );
  }
}
