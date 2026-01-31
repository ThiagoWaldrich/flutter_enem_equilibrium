import 'package:equilibrium/features/questions/widgets/notebook_tab.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:equilibrium/features/analytics/screen/register_tab.dart';
import 'package:equilibrium/features/analytics/screen/charts_tab.dart';
import 'package:equilibrium/features/questions/models/question.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
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

  late final TabController _tabController;

  String? _selectedSubject;
  String? _selectedTopic;
  String? _selectedSubtopic;
  String? _selectedYear;
  String? _selectedSource;

  List<String> _availableTopics = [];
  List<String> _availableSubtopics = [];

  late final TextEditingController _errorDescriptionController;
  late final TextEditingController _topicController;
  late final TextEditingController _subtopicController;
  late final TextEditingController _yearController;
  late final TextEditingController _sourceController;

  bool _contentError = false;
  bool _attentionError = false;
  bool _timeError = false;
  String? _imageFilePath;

  Question? _questionToEdit;
  bool _isEditing = false;

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _errorDescriptionController = TextEditingController();
    _topicController = TextEditingController();
    _subtopicController = TextEditingController();
    _yearController = TextEditingController();
    _sourceController = TextEditingController();
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _errorDescriptionController.dispose();
    _topicController.dispose();
    _subtopicController.dispose();
    _yearController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  void _updateTopics() {
    final data = SubjectDataConstants.subjectData[_selectedSubject];
    setState(() {
      _selectedTopic = null;
      _selectedSubtopic = null;
      _availableTopics = data?.keys.toList() ?? [];
      _availableSubtopics = [];
    });
  }

  void _updateSubtopics() {
    final topics = SubjectDataConstants.subjectData[_selectedSubject];
    setState(() {
      _selectedSubtopic = null;
      _availableSubtopics =
          (topics != null && _selectedTopic != null)
              ? topics[_selectedTopic] ?? []
              : [];
    });
  }

  Future<void> _loadInitialData() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final db = context.read<DatabaseService>();

    try {
      final results = await Future.wait([
        db.getSubjectStats(), 
        db.getYearStats(),
        db.getSourceStats(),
        db.getQuestionCount(),
        db.getQuestions(limit: _pageSize), 
      ]);

      final questions = results[4] as List<Question>;
      final errorStats = _computeErrorStats(questions);

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

  static Map<String, Map<String, dynamic>> _computeErrorStats(
    List<Question> questions,
  ) {
    final stats = <String, Map<String, dynamic>>{};
    for (final q in questions) {
      final entry = stats.putIfAbsent(
        q.subject,
        () => {
          'total': 0,
          'conteudo': 0,
          'atencao': 0,
          'tempo': 0,
        },
      );
      entry['total'] = (entry['total'] as int) + 1;
      if (q.errorTypes.contains(ErrorType.conteudo)) {
        entry['conteudo'] = (entry['conteudo'] as int) + 1;
      }
      if (q.errorTypes.contains(ErrorType.atencao)) {
        entry['atencao'] = (entry['atencao'] as int) + 1;
      }
      if (q.errorTypes.contains(ErrorType.tempo)) {
        entry['tempo'] = (entry['tempo'] as int) + 1;
      }
    }
    return stats;
  }

  Future<void> _loadMoreQuestions() async {
    if (_isLoadingMore || !_hasMoreQuestions) return;
    setState(() => _isLoadingMore = true);

    _currentPage++;
    final db = context.read<DatabaseService>();

    try {
      final more = await db.getQuestions(
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      if (!mounted) return;

      setState(() {
        _displayedQuestions = [..._displayedQuestions, ...more];
        _hasMoreQuestions = more.length >= _pageSize;
        _isLoadingMore = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar mais: $e');
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Selecionar Imagem'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Galeria'),
                onTap: null,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, ImageSource.gallery),
              child: const Text('Galeria'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, ImageSource.camera),
              child: const Text('Câmera'),
            ),
          ],
        ),
      );

      if (source == null || !mounted) return;

      final image = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );

      if (image == null || !mounted) return;

      final tempFile = File(image.path);
      if (await tempFile.length() > 3 * 1024 * 1024) {
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

      final dir = await getApplicationDocumentsDirectory();
      final saved = await tempFile.copy(
        '${dir.path}/${DateTime.now().millisecondsSinceEpoch}_${path.basename(image.path)}',
      );

      if (mounted) setState(() => _imageFilePath = saved.path);
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

    final db = context.read<DatabaseService>();

    try {
      if (_isEditing) {
        await db.updateQuestion(question);
      } else {
        await db.insertQuestion(question);
      }

      final wasEditing = _isEditing;
      _clearForm();
      await _loadInitialData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Questão ${wasEditing ? 'atualizada' : 'salva'}!'),
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
      _availableTopics = [];
      _availableSubtopics = [];
      _contentError = false;
      _attentionError = false;
      _timeError = false;
      _imageFilePath = null;
    });
    _errorDescriptionController.clear();
    _topicController.clear();
    _subtopicController.clear();
    _yearController.clear();
    _sourceController.clear();
  }

  void _editQuestion(Question question) {
    setState(() {
      _questionToEdit = question;
      _isEditing = true;
      _selectedSubject = question.subject;
      _selectedTopic = question.topic;
      _selectedSubtopic = question.subtopic;
      _selectedYear = question.year;
      _selectedSource = question.source;
      _contentError = question.errorTypes.contains(ErrorType.conteudo);
      _attentionError = question.errorTypes.contains(ErrorType.atencao);
      _timeError = question.errorTypes.contains(ErrorType.tempo);
      _imageFilePath = null;

      final data = SubjectDataConstants.subjectData[question.subject];
      _availableTopics = data?.keys.toList() ?? [];
      _availableSubtopics = (data != null && question.topic != null)
          ? data[question.topic] ?? []
          : [];
    });

    _errorDescriptionController.text = question.errorDescription ?? '';
    _tabController.animateTo(0);
  }

  Future<void> _deleteQuestion(Question question) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
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

    if (confirm != true || !mounted) return;

    final db = context.read<DatabaseService>();
    await db.deleteQuestions([question.id]);
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
          unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
          tabs: const [
            Tab(icon: Icon(Icons.add), text: 'Cadastrar'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Gráficos'),
            Tab(icon: Icon(Icons.menu_book), text: 'Caderno'),
            Tab(icon: Icon(Icons.lightbulb), text: 'Mapas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          RegisterTab(
            selectedSubject: _selectedSubject,
            selectedTopic: _selectedTopic,
            selectedSubtopic: _selectedSubtopic,
            selectedYear: _selectedYear,
            selectedSource: _selectedSource,
            availableTopics: _availableTopics,
            availableSubtopics: _availableSubtopics,
            topicController: _topicController,
            subtopicController: _subtopicController,
            errorDescriptionController: _errorDescriptionController,
            yearController: _yearController,
            sourceController: _sourceController,
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
            onSubtopicChanged: (value) =>
                setState(() => _selectedSubtopic = value),
            onYearChanged: (value) => setState(() => _selectedYear = value),
            onSourceChanged: (value) =>
                setState(() => _selectedSource = value),
            onContentErrorChanged: (value) =>
                setState(() => _contentError = value),
            onAttentionErrorChanged: (value) =>
                setState(() => _attentionError = value),
            onTimeErrorChanged: (value) => setState(() => _timeError = value),
            onPickImage: _pickImage,
            onClearImage: () => setState(() => _imageFilePath = null),
            onSaveQuestion: _saveQuestion,
            onClearForm: _clearForm,
          ),
          ChartsTab(
            stats: {},
            subjectStats: _subjectStats,
            yearStats: _yearStats,
            sourceStats: _sourceStats,
            errorStats: _errorStats,
            totalQuestions: _totalQuestions,
            questions: _displayedQuestions,
            isLoading: _isLoading,
          ),
          NotebookTab(
            questions: _displayedQuestions,
            subjectStats: _subjectStats,
            yearStats: _yearStats,
            sourceStats: _sourceStats,
            totalQuestions: _totalQuestions,
            isLoading: _isLoading,
            hasMoreQuestions: _hasMoreQuestions,
            onEditQuestion: _editQuestion,
            onDeleteQuestion: _deleteQuestion,
            onLoadMore: _loadMoreQuestions,
          ),
          const MindMapsScreen(key: PageStorageKey<String>('mindmaps')),
        ],
      ),
    );
  }
}