import 'package:flutter/material.dart';
import 'package:equilibrium/features/questions/models/question.dart';
import 'package:equilibrium/features/questions/widgets/questions_grid_view.dart';
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
  String? _filterSubject;
  String? _filterYear;
  String? _filterSource;
  String? _filterErrorType;
  bool _isGridView = true;

  List<Question> get _filteredQuestions {
    var result = widget.questions;

    if (_filterSubject != null) {
      result = result.where((q) => q.subject == _filterSubject).toList();
    }
    if (_filterYear != null) {
      result = result.where((q) => q.year == _filterYear).toList();
    }
    if (_filterSource != null) {
      result = result.where((q) => q.source == _filterSource).toList();
    }
    if (_filterErrorType != null) {
      final errorType = switch (_filterErrorType) {
        'conteudo' => ErrorType.conteudo,
        'atencao' => ErrorType.atencao,
        'tempo' => ErrorType.tempo,
        _ => null,
      };
      if (errorType != null) {
        result = result.where((q) => q.errorTypes.contains(errorType)).toList();
      }
    }

    return result;
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

    return Column(
      children: [
        _FilterBar(
          subjectStats: widget.subjectStats,
          yearStats: widget.yearStats,
          sourceStats: widget.sourceStats,
          totalQuestions: widget.totalQuestions,
          filterSubject: _filterSubject,
          filterYear: _filterYear,
          filterSource: _filterSource,
          filterErrorType: _filterErrorType,
          isGridView: _isGridView,
          onSubjectChanged: (v) => setState(() => _filterSubject = v),
          onYearChanged: (v) => setState(() => _filterYear = v),
          onSourceChanged: (v) => setState(() => _filterSource = v),
          onErrorTypeChanged: (v) => setState(() => _filterErrorType = v),
          onGridToggle: (v) => setState(() => _isGridView = v),
        ),
        const SizedBox(height: 4),
        _ResultsHeader(
          count: displayed.length,
          isLoadingMore: false, // controlado pelo pai via hasMoreQuestions
        ),
        const SizedBox(height: 4),
        Expanded(
          child: displayed.isEmpty
              ? const _EmptyState()
              : NotificationListener<ScrollNotification>(
                  onNotification: (info) {
                    if (widget.hasMoreQuestions &&
                        info.metrics.pixels >=
                            info.metrics.maxScrollExtent - 200) {
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
                      : _ListViewContent(
                          questions: displayed,
                          hasMore: widget.hasMoreQuestions,
                          onTap: (q) => _showDetails(q),
                          onEdit: widget.onEditQuestion,
                          onDelete: widget.onDeleteQuestion,
                          onDetails: (q) => _showDetails(q, withActions: false),
                        ),
                ),
        ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  final Map<String, int> subjectStats;
  final Map<String, int> yearStats;
  final Map<String, int> sourceStats;
  final int totalQuestions;

  final String? filterSubject;
  final String? filterYear;
  final String? filterSource;
  final String? filterErrorType;
  final bool isGridView;

  final ValueChanged<String?> onSubjectChanged;
  final ValueChanged<String?> onYearChanged;
  final ValueChanged<String?> onSourceChanged;
  final ValueChanged<String?> onErrorTypeChanged;
  final ValueChanged<bool> onGridToggle;

  const _FilterBar({
    required this.subjectStats,
    required this.yearStats,
    required this.sourceStats,
    required this.totalQuestions,
    required this.filterSubject,
    required this.filterYear,
    required this.filterSource,
    required this.filterErrorType,
    required this.isGridView,
    required this.onSubjectChanged,
    required this.onYearChanged,
    required this.onSourceChanged,
    required this.onErrorTypeChanged,
    required this.onGridToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          _FilterDropdown(
            value: filterSubject,
            label: 'Filtrar por matéria',
            allLabel: 'Todas',
            items: subjectStats.keys.toList(),
            onChanged: onSubjectChanged,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _FilterDropdown(
                  value: filterYear,
                  label: 'Filtrar por ano',
                  allLabel: 'Todos',
                  items: yearStats.keys.toList(),
                  onChanged: onYearChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FilterDropdown(
                  value: filterSource,
                  label: 'Filtrar por fonte',
                  allLabel: 'Todas',
                  items: sourceStats.keys.toList(),
                  onChanged: onSourceChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _FilterDropdown(
            value: filterErrorType,
            label: 'Filtrar por tipo de erro',
            allLabel: 'Todos',
            items: const ['conteudo', 'atencao', 'tempo'],
            displayNames: const {
              'conteudo': 'Conteúdo',
              'atencao': 'Atenção',
              'tempo': 'Tempo',
            },
            onChanged: onErrorTypeChanged,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: $totalQuestions questões',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.grid_view,
                      color: isGridView ? Colors.blue : Colors.grey,
                    ),
                    onPressed: () => onGridToggle(true),
                    tooltip: 'Visualização em grade',
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.view_list,
                      color: !isGridView ? Colors.blue : Colors.grey,
                    ),
                    onPressed: () => onGridToggle(false),
                    tooltip: 'Visualização em lista',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String? value;
  final String label;
  final String allLabel;
  final List<String> items;
  final Map<String, String>? displayNames;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.value,
    required this.label,
    required this.allLabel,
    required this.items,
    this.displayNames,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      items: [
        DropdownMenuItem(value: null, child: Text(allLabel)),
        ...items.map(
          (item) => DropdownMenuItem(
            value: item,
            child: Text(displayNames?[item] ?? item),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  final int count;
  final bool isLoadingMore;

  const _ResultsHeader({
    required this.count,
    required this.isLoadingMore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[50],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Resultados: $count questões',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          if (isLoadingMore)
            const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.search_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Nenhuma questão encontrada',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Tente ajustar os filtros',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _ListViewContent extends StatelessWidget {
  final List<Question> questions;
  final bool hasMore;
  final void Function(Question) onTap;
  final void Function(Question) onEdit;
  final void Function(Question) onDelete;
  final void Function(Question) onDetails;

  const _ListViewContent({
    required this.questions,
    required this.hasMore,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: questions.length + (hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, index) {
        if (index >= questions.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final q = questions[index];
        return Card(
          elevation: 2,
          child: ListTile(
            leading: Container(
              width: 4,
              height: 50,
              color: AppTheme.getSubjectColor(q.subject),
            ),
            title: Text(
              q.subject,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(q.topic),
                if (q.subtopic != null)
                  Text(
                    'Subtópico: ${q.subtopic}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                if (q.year != null)
                  Text(
                    'Ano: ${q.year}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                  onPressed: () => onEdit(q),
                  tooltip: 'Editar questão',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () => onDelete(q),
                  tooltip: 'Excluir questão',
                ),
                IconButton(
                  icon:
                      const Icon(Icons.visibility, color: Colors.green, size: 20),
                  onPressed: () => onDetails(q),
                  tooltip: 'Ver detalhes',
                ),
              ],
            ),
            onTap: () => onTap(q),
          ),
        );
      },
    );
  }
}