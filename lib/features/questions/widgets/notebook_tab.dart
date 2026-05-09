import 'package:flutter/material.dart';
import 'package:equilibrium/features/questions/models/question.dart';
import 'package:equilibrium/features/questions/widgets/questions_grid_view.dart';
import 'package:equilibrium/features/questions/widgets/question_card.dart';
import 'package:equilibrium/features/core/theme/theme.dart';
import 'question_detail_dialog.dart';

typedef OnEditQuestion = void Function(Question);
typedef OnDeleteQuestion = void Function(Question);

class NotebookTab extends StatefulWidget {
  final List<Question> questions;
  final Map<String, int> subjectStats;
  final Map<String, int> yearStats;
  final Map<String, int> sourceStats;
  final int totalQuestions;
  final bool isLoading;
  final bool hasMoreQuestions;
  final OnEditQuestion onEditQuestion;
  final OnDeleteQuestion onDeleteQuestion;
  final Future<void> Function() onLoadMore;

  const NotebookTab({
    super.key,
    required this.questions,
    required this.subjectStats,
    required this.yearStats,
    required this.sourceStats,
    required this.totalQuestions,
    required this.isLoading,
    required this.hasMoreQuestions,
    required this.onEditQuestion,
    required this.onDeleteQuestion,
    required this.onLoadMore,
  });

  @override
  State<NotebookTab> createState() => _NotebookTabState();
}

class _NotebookTabState extends State<NotebookTab> {
  String _searchQuery = '';
  String? _selectedSubject; // NOVO: filtro por matéria
  bool _isGridView = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Question> get _filteredQuestions {
    var result = widget.questions;

    // Filtro por matéria
    if (_selectedSubject != null) {
      result = result.where((q) => q.subject == _selectedSubject).toList();
    }

    // Busca por texto (tópico, subtópico, descrição do erro)
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((q) {
        return q.topic.toLowerCase().contains(query) ||
            (q.subtopic?.toLowerCase().contains(query) ?? false) ||
            (q.errorDescription?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    return result;
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedSubject = null;
      _searchController.clear();
    });
  }

  void _showDetails(Question q, {bool withActions = true}) {
    showDialog(
      context: context,
      builder: (_) => QuestionDetailDialog(
        question: q,
        onEdit: withActions ? () => widget.onEditQuestion(q) : null,
        onDelete: withActions ? () => widget.onDeleteQuestion(q) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final displayed = _filteredQuestions;
    final hasActiveFilters = _selectedSubject != null || _searchQuery.isNotEmpty;

    return Column(
      children: [
        // 🔍 Barra de busca + filtros
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar por tópico, subtópico ou erro...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                    _searchController.clear();
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                      onChanged: (value) => setState(() => _searchQuery = value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Botões de visualização
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.grid_view,
                              color: _isGridView ? Colors.blue : Colors.grey),
                          onPressed: () => setState(() => _isGridView = true),
                          tooltip: 'Visualização em grade',
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                        IconButton(
                          icon: Icon(Icons.view_list,
                              color: !_isGridView ? Colors.blue : Colors.grey),
                          onPressed: () => setState(() => _isGridView = false),
                          tooltip: 'Visualização em lista',
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Chips de filtro por matéria
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Chip "Todas" - limpa o filtro de matéria
                    FilterChip(
                      label: const Text('Todas as matérias'),
                      selected: _selectedSubject == null,
                      onSelected: (_) => setState(() => _selectedSubject = null),
                      backgroundColor: Colors.grey[100],
                      selectedColor: Colors.blue.shade50,
                      labelStyle: TextStyle(
                        color: _selectedSubject == null ? Colors.blue : Colors.grey[600],
                        fontWeight: _selectedSubject == null ? FontWeight.w500 : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Chips para cada matéria
                    ...widget.subjectStats.keys.map((subject) {
                      final count = widget.subjectStats[subject] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text('$subject ($count)'),
                          selected: _selectedSubject == subject,
                          onSelected: (_) => setState(() => _selectedSubject = subject),
                          backgroundColor: Colors.grey[100],
                          selectedColor: AppTheme.getSubjectColor(subject).withValues(alpha: 0.2),
                          labelStyle: TextStyle(
                            color: _selectedSubject == subject ? AppTheme.getSubjectColor(subject) : Colors.grey[600],
                            fontWeight: _selectedSubject == subject ? FontWeight.w500 : null,
                          ),
                          avatar: _selectedSubject == subject
                              ? Icon(Icons.check, size: 16, color: AppTheme.getSubjectColor(subject))
                              : null,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 📊 Linha com total de questões e botão limpar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${displayed.length} ${displayed.length == 1 ? 'questão' : 'questões'}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey),
              ),
              if (hasActiveFilters)
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear, size: 14),
                  label: const Text('Limpar filtros'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 4),

        // 📄 Lista / Grade de questões
        Expanded(
          child: displayed.isEmpty
              ? _EmptyState(hasActiveFilters: hasActiveFilters)
              : NotificationListener<ScrollNotification>(
                  onNotification: (info) {
                    if (widget.hasMoreQuestions &&
                        info.metrics.pixels >= info.metrics.maxScrollExtent - 200) {
                      widget.onLoadMore();
                    }
                    return false;
                  },
                  child: _isGridView
                      ? QuestionsGridView(
                          questions: displayed,
                          onQuestionTap: (q) => _showDetails(q),
                          onEditQuestion: widget.onEditQuestion,
                          onDeleteQuestion: widget.onDeleteQuestion,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: displayed.length + (widget.hasMoreQuestions ? 1 : 0),
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, index) {
                            if (index >= displayed.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            final q = displayed[index];
                            return QuestionCard(
                              question: q,
                              compact: true,
                              showThumbnail: true,
                              showImage: true,
                              onTap: () => _showDetails(q),
                              onEdit: () => widget.onEditQuestion(q),
                              onDelete: () => widget.onDeleteQuestion(q),
                            );
                          },
                        ),
                ),
        ),
      ],
    );
  }
}

// ========== ESTADO VAZIO ==========

class _EmptyState extends StatelessWidget {
  final bool hasActiveFilters;

  const _EmptyState({this.hasActiveFilters = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            hasActiveFilters ? 'Nenhuma questão encontrada' : 'Nenhuma questão cadastrada',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            hasActiveFilters 
                ? 'Tente ajustar os filtros ou a busca'
                : 'Adicione questões na aba "Cadastrar"',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}