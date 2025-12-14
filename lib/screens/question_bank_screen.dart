// lib/screens/question_bank_screen.dart
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'add_question_screen.dart';
import '../utils/theme.dart';
import '../widgets/question_bank_grid.dart';

class QuestionBankScreen extends StatefulWidget {
  const QuestionBankScreen({super.key});

  @override
  State<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends State<QuestionBankScreen> {
  List<Map<String, dynamic>> _questions = [];
  List<Map<String, dynamic>> _filteredQuestions = [];
  bool _isLoading = true;

  // Filtros
  String? _selectedSubjectId;
  String? _selectedTopicId;
  String? _selectedSourceId;
  String? _selectedYearId;
  String _searchQuery = '';

  // Listas para dropdowns
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _topics = [];
  List<Map<String, dynamic>> _sources = [];
  List<Map<String, dynamic>> _years = [];
  List<Map<String, dynamic>> _filteredTopics = [];

  // View mode: grid ou list
  bool _isGridView = false;

  // Ordenação
  String _sortBy = 'date';
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    void _runDebug() async {
      print('🔄 Executando debug...');
      await SupabaseService.debugAllTopicsAndSubjects();
    }
  }

  void _runDebug() async {
    print('🔄 Executando debug...');
    await SupabaseService.debugAllTopicsAndSubjects();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final [questions, subjects, sources, years, topics] = await Future.wait([
        SupabaseService.getQuestions(),
        SupabaseService.getSubjects(),
        SupabaseService.getSources(),
        SupabaseService.getExamYears(),
        SupabaseService.getTopics(),
      ]);

      print('📊 Dados carregados:');
      print('   - ${(subjects as List).length} matérias');
      print('   - ${(sources as List).length} fontes');
      print('   - ${(years as List).length} anos');
      print('   - ${(topics as List).length} tópicos');
      print('   - ${(questions as List).length} questões');

      setState(() {
        _questions = questions as List<Map<String, dynamic>>;
        _filteredQuestions = _questions;
        _subjects = subjects as List<Map<String, dynamic>>;
        _sources = sources as List<Map<String, dynamic>>;
        _years = years as List<Map<String, dynamic>>;
        _topics = topics as List<Map<String, dynamic>>;
        _filteredTopics = _topics;
        _isLoading = false;
      });

      _sortQuestions(_filteredQuestions);
    } catch (e) {
      print('❌ Erro ao carregar dados: $e');
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _sortQuestions(List<Map<String, dynamic>> questions) {
    questions.sort((a, b) {
      int comparison = 0;

      switch (_sortBy) {
        case 'subject':
          final aSubject = a['subject']?['name'] ?? '';
          final bSubject = b['subject']?['name'] ?? '';
          comparison = aSubject.compareTo(bSubject);
          break;
        case 'date':
          final aDate = a['created_at'] ?? '';
          final bDate = b['created_at'] ?? '';
          comparison = aDate.compareTo(bDate);
          break;
        case 'difficulty':
          final aDiff = a['difficulty_level'] ?? 3;
          final bDiff = b['difficulty_level'] ?? 3;
          comparison = aDiff.compareTo(bDiff);
          break;
        default:
          comparison = 0;
      }

      return _sortAscending ? comparison : -comparison;
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredQuestions = _questions.where((question) {
        // Filtro por matéria
        if (_selectedSubjectId != null &&
            question['subject_id'] != _selectedSubjectId) {
          return false;
        }

        // Filtro por tópico
        if (_selectedTopicId != null &&
            question['topic_id'] != _selectedTopicId) {
          return false;
        }

        // Filtro por fonte
        if (_selectedSourceId != null &&
            question['source_id'] != _selectedSourceId) {
          return false;
        }

        // Filtro por ano
        if (_selectedYearId != null && question['year_id'] != _selectedYearId) {
          return false;
        }

        // Filtro por busca textual
        if (_searchQuery.isNotEmpty) {
          final searchLower = _searchQuery.toLowerCase();

          // Buscar no nome da matéria
          final subjectName =
              question['subject']?['name']?.toString().toLowerCase() ?? '';
          if (subjectName.contains(searchLower)) return true;

          // Buscar no nome do tópico
          final topicName =
              question['topic']?['name']?.toString().toLowerCase() ?? '';
          if (topicName.contains(searchLower)) return true;

          // Buscar no nome da fonte
          final sourceName =
              question['source']?['name']?.toString().toLowerCase() ?? '';
          if (sourceName.contains(searchLower)) return true;

          // Buscar no ano
          final year = question['year']?['year']?.toString() ?? '';
          if (year.contains(searchLower)) return true;

          return false;
        }

        return true;
      }).toList();

      _sortQuestions(_filteredQuestions);
    });
  }

  void _filterTopicsBySubject(String? subjectId) async {
    print('🔍 [SCREEN] Filtrando tópicos para matéria ID: $subjectId');

    if (subjectId == null || subjectId.isEmpty) {
      setState(() {
        _filteredTopics = _topics;
        _selectedTopicId = null;
      });
      print('📋 [SCREEN] Mostrando todos os ${_topics.length} tópicos');
      return;
    }

    setState(() {
      _filteredTopics = []; // Limpa para mostrar estado de carregamento
      _selectedTopicId = null;
    });

    try {
      print('🔄 [SCREEN] Chamando SupabaseService.getTopicsBySubject...');
      final topicsForSubject =
          await SupabaseService.getTopicsBySubject(subjectId);

      print('✅ [SCREEN] Resposta recebida: ${topicsForSubject.length} tópicos');

      setState(() {
        _filteredTopics = topicsForSubject;
        _selectedTopicId = null;
      });

      // Atualiza os filtros após carregar os tópicos
      _applyFilters();
    } catch (e) {
      print('❌ [SCREEN] Erro ao carregar tópicos: $e');
      setState(() {
        _filteredTopics = [];
        _selectedTopicId = null;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedSubjectId = null;
      _selectedTopicId = null;
      _selectedSourceId = null;
      _selectedYearId = null;
      _searchQuery = '';
      _filteredTopics = _topics;
      _filteredQuestions = _questions;
      _sortQuestions(_filteredQuestions);
    });
  }

  Future<void> _deleteQuestion(String questionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text('Tem certeza que deseja excluir esta questão?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupabaseService.deleteQuestion(questionId);

        // Remove localmente sem recarregar tudo
        setState(() {
          _questions.removeWhere((q) => q['id'] == questionId);
          _filteredQuestions.removeWhere((q) => q['id'] == questionId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Questão excluída com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao excluir: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildFilters() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Barra de busca
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Buscar...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                setState(() => _searchQuery = '');
                                _applyFilters();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                      _applyFilters();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                PopupMenuButton<String>(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: const Icon(Icons.sort, size: 24),
                  ),
                  onSelected: (value) {
                    setState(() {
                      if (value == 'toggle') {
                        _sortAscending = !_sortAscending;
                      } else {
                        _sortBy = value;
                      }
                      _sortQuestions(_filteredQuestions);
                    });
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'date',
                      child: Row(
                        children: [
                          Icon(
                            _sortBy == 'date' ? Icons.check : null,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          const Text('Data'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'subject',
                      child: Row(
                        children: [
                          Icon(
                            _sortBy == 'subject' ? Icons.check : null,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          const Text('Matéria'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'difficulty',
                      child: Row(
                        children: [
                          Icon(
                            _sortBy == 'difficulty' ? Icons.check : null,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          const Text('Dificuldade'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            _sortAscending
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(_sortAscending ? 'Crescente' : 'Decrescente'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: _isGridView
                      ? 'Visualização em lista'
                      : 'Visualização em grid',
                  child: IconButton(
                    onPressed: () {
                      setState(() => _isGridView = !_isGridView);
                    },
                    icon: Icon(
                      _isGridView ? Icons.list : Icons.grid_view,
                      color: AppTheme.primaryColor,
                      size: 28,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[50],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Matéria e Fonte
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedSubjectId,
                    decoration: InputDecoration(
                      labelText: 'Matéria',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.grey[50],
                      hintText: 'Selecione uma matéria',
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Todas as matérias'),
                      ),
                      ..._subjects.map((subject) {
                        return DropdownMenuItem<String>(
                          value: subject['id'],
                          child: Text(subject['name']),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      print('📚 Matéria selecionada: $value');

                      setState(() {
                        _selectedSubjectId = value;
                        _filteredTopics = []; // Limpa enquanto carrega
                        _selectedTopicId = null;
                      });

                      _filterTopicsBySubject(value);
                      _applyFilters();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedSourceId,
                    decoration: InputDecoration(
                      labelText: 'Fonte',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Todas'),
                      ),
                      ..._sources.map((source) {
                        return DropdownMenuItem<String>(
                          value: source['id'],
                          child: Text('${source['name']} (${source['type']})'),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedSourceId = value;
                      });
                      _applyFilters();
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Tópico e Ano
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedTopicId,
                    decoration: InputDecoration(
                      labelText: 'Tópico',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.grey[50],
                      hintText: _selectedSubjectId == null
                          ? 'Selecione uma matéria primeiro'
                          : _filteredTopics.isEmpty
                              ? 'Carregando tópicos...'
                              : 'Selecione um tópico',
                    ),
                    items: _buildTopicDropdownItems(),
                    onChanged: (value) {
                      print('📝 Tópico selecionado: $value');
                      setState(() => _selectedTopicId = value);
                      _applyFilters();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedYearId,
                    decoration: InputDecoration(
                      labelText: 'Ano',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.grey[50],
                      hintText: 'Selecione um ano',
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Todos os anos'),
                      ),
                      ..._years.map((year) {
                        return DropdownMenuItem<String>(
                          value: year['id'],
                          child: Text(year['year'].toString()),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedYearId = value);
                      _applyFilters();
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Botão Limpar Filtros
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('Limpar Todos os Filtros'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      side: BorderSide(color: Colors.grey[400]!),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildTopicDropdownItems() {
    final items = <DropdownMenuItem<String>>[];

    if (_selectedSubjectId == null) {
      items.add(
        const DropdownMenuItem<String>(
          value: null,
          child: Text(
            'Selecione uma matéria primeiro',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    } else if (_filteredTopics.isEmpty) {
      items.add(
        const DropdownMenuItem<String>(
          value: null,
          child: Text(
            'Carregando tópicos...',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    } else {
      items.add(
        const DropdownMenuItem<String>(
          value: null,
          child: Text('Todos os tópicos'),
        ),
      );

      items.addAll(
        _filteredTopics.map((topic) {
          return DropdownMenuItem<String>(
            value: topic['id'],
            child: Text(topic['name']),
          );
        }),
      );
    }

    return items;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
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
              'Nenhuma questão encontrada',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty ||
                      _selectedSubjectId != null ||
                      _selectedSourceId != null ||
                      _selectedYearId != null
                  ? 'Tente ajustar os filtros de busca'
                  : 'Comece adicionando sua primeira questão!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionListItem(Map<String, dynamic> question, int index) {
    final subject = question['subject'] as Map<String, dynamic>?;
    final topic = question['topic'] as Map<String, dynamic>?;
    final source = question['source'] as Map<String, dynamic>?;
    final year = question['year'] as Map<String, dynamic>?;

    final difficulty = question['difficulty_level'] ?? 3;
    final correctAnswer = question['correct_answer']?.toString() ?? '';
    final imageUrl = _getImageUrl(question['image_url']);
    final displayNumber = index + 1;

    final subjectName = subject?['name'] ?? 'Sem matéria';
    final topicName = topic?['name'] ?? '';
    final sourceName = source?['name'] ?? '';
    final yearValue = year?['year'];

    Color subjectColor = _getSubjectColor(subjectName);

    Color getDifficultyColor(int level) {
      switch (level) {
        case 1:
          return Colors.green;
        case 2:
          return Colors.lightGreen;
        case 3:
          return Colors.amber;
        case 4:
          return Colors.orange;
        case 5:
          return Colors.red;
        default:
          return Colors.grey;
      }
    }

    String getDifficultyLabel(int level) {
      switch (level) {
        case 1:
          return 'Fácil';
        case 2:
          return 'Médio-Fácil';
        case 3:
          return 'Médio';
        case 4:
          return 'Difícil';
        case 5:
          return 'Muito Difícil';
        default:
          return 'N/A';
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _showQuestionDetails(question),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: subjectColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                subjectName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: subjectColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: getDifficultyColor(difficulty)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: getDifficultyColor(difficulty)
                                      .withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                getDifficultyLabel(difficulty),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: getDifficultyColor(difficulty),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (topicName.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              topicName,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF616161),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: subjectColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        displayNumber.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (correctAnswer.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle,
                              size: 12, color: Colors.green[700]),
                          const SizedBox(width: 4),
                          Text(
                            'Resp: $correctAnswer',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (sourceName.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.source, size: 12, color: Colors.blue[700]),
                          const SizedBox(width: 4),
                          Text(
                            yearValue != null
                                ? '$sourceName $yearValue'
                                : sourceName,
                            style: TextStyle(
                                fontSize: 12, color: Colors.blue[700]),
                          ),
                        ],
                      ),
                    ),
                  if (imageUrl != null)
                    GestureDetector(
                      onTap: () => _showImageFullScreen(context, imageUrl),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.purple.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.image,
                                size: 12, color: Colors.purple[700]),
                            const SizedBox(width: 4),
                            const Text('Ver Imagem',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.purple)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (question['created_at'] != null)
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 6),
                        Text(
                          _formatDate(question['created_at']),
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF757575)),
                        ),
                      ],
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit,
                            size: 20, color: AppTheme.primaryColor),
                        onPressed: () => _editQuestion(question),
                        tooltip: 'Editar',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            size: 20, color: Colors.red),
                        onPressed: () => _deleteQuestion(question['id']),
                        tooltip: 'Excluir',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editQuestion(Map<String, dynamic> question) {
    // TODO: Implementar tela de edição
    print('Editar questão: ${question['id']}');
  }

  Widget _buildListView() {
    return ListView.builder(
      itemCount: _filteredQuestions.length,
      itemBuilder: (context, index) =>
          _buildQuestionListItem(_filteredQuestions[index], index),
    );
  }

  Color _getSubjectColor(String subjectName) {
    final lowerName = subjectName.toLowerCase();
    if (lowerName.contains('biologia')) return const Color(0xFF4CAF50);
    if (lowerName.contains('física')) return const Color(0xFF2196F3);
    if (lowerName.contains('química')) return const Color(0xFF9C27B0);
    if (lowerName.contains('matemática')) return const Color(0xFFF44336);
    if (lowerName.contains('português') || lowerName.contains('literatura'))
      return const Color(0xFFFF9800);
    if (lowerName.contains('história')) return const Color(0xFF795548);
    if (lowerName.contains('geografia')) return const Color(0xFF009688);
    if (lowerName.contains('filosofia')) return const Color(0xFF607D8B);
    if (lowerName.contains('sociologia')) return const Color(0xFF9E9E9E);
    if (lowerName.contains('inglês') || lowerName.contains('espanhol'))
      return const Color(0xFF3F51B5);
    return AppTheme.primaryColor;
  }

  String? _getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return null;
    if (imagePath.startsWith('http')) return imagePath;

    // Se não começar com http, pode ser um caminho do Supabase Storage
    try {
      final supabase = SupabaseService.supabase;
      return supabase.storage.from('question-images').getPublicUrl(imagePath);
    } catch (e) {
      print('❌ Erro ao obter URL da imagem: $e');
      return null;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  void _showQuestionDetails(Map<String, dynamic> question) {
    final subject = question['subject'] as Map<String, dynamic>?;
    final topic = question['topic'] as Map<String, dynamic>?;
    final source = question['source'] as Map<String, dynamic>?;
    final year = question['year'] as Map<String, dynamic>?;
    final imageUrl = _getImageUrl(question['image_url']);
    final statement = question['statement']?.toString() ?? '';
    final contextText = question['context']?.toString() ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            'Detalhes da Questão #${question['id']?.substring(0, 8) ?? 'N/A'}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Matéria
              if (subject?['name'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.subject, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Matéria: ${subject!['name']}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),

              // Tópico
              if (topic?['name'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.category, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tópico: ${topic!['name']}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),

              // Fonte
              if (source?['name'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.source, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Fonte: ${source!['name']} ${year?['year'] ?? ''}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),

              // Resposta Correta
              if (question['correct_answer'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Resposta Correta: ${question['correct_answer']}',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),

              // Dificuldade
              if (question['difficulty_level'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(Icons.speed, size: 16, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Dificuldade: ${question['difficulty_level']}/5',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),

              // Enunciado
              if (statement.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enunciado:',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statement,
                      style: const TextStyle(fontSize: 13, height: 1.5),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),

              // Contexto
              if (contextText.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Contexto:',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      contextText,
                      style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: const Color(
                              0xFF616161)), // CORRIGIDO: Substitui Colors.grey[700] por Color(0xFF616161)
                    ),
                    const SizedBox(height: 12),
                  ],
                ),

              // Imagem (se houver)
              if (imageUrl != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Imagem da Questão:',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _showImageFullScreen(context, imageUrl),
                      child: Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image,
                                        size: 40, color: Colors.grey[400]),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Erro ao carregar imagem',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => _showImageFullScreen(context, imageUrl),
                      icon: const Icon(Icons.fullscreen, size: 16),
                      label: const Text('Ver em tela cheia'),
                    ),
                  ],
                ),
            ],
          ),
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

  void _showImageFullScreen(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.download, color: Colors.white),
                onPressed: () {
                  // TODO: Implementar download da imagem
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Download em breve...'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {
                  // TODO: Implementar compartilhamento
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Compartilhamento em breve...'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
              ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.1,
              maxScale: 10.0,
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: Colors.white,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image,
                          size: 80,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Erro ao carregar imagem',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          error.toString(),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Banco de Questões'),
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_filteredQuestions.length} questão${_filteredQuestions.length != 1 ? 'es' : ''} encontrada${_filteredQuestions.length != 1 ? 's' : ''}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const Spacer(),
                if (_sortBy == 'date')
                  Text(
                    _sortAscending ? 'Mais antigas' : 'Mais recentes',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredQuestions.isEmpty
                    ? _buildEmptyState()
                    : _isGridView
                        ? QuestionBankGrid(
                            questions: _filteredQuestions,
                            onQuestionTap: _showQuestionDetails,
                            onEditTap: (question) => _editQuestion(question),
                            onDeleteTap: (question) =>
                                _deleteQuestion(question['id']),
                            onAddToTestTap: (question) => print(
                                'Adicionar ao simulado: ${question['id']}'),
                          )
                        : _buildListView(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddQuestionScreen()),
        ).then((_) => _loadData()),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nova Questão'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
