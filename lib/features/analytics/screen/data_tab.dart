import 'package:equilibrium/features/questions/models/question.dart';
import 'package:flutter/material.dart';
import 'package:easy_debounce/easy_debounce.dart';
import '../../core/theme/theme.dart';
import '../../questions/logic/questions_view_model.dart';
import '../../core/utils/subject_data_constants.dart';

class DataTab extends StatefulWidget {
  final List<Question> questions;
  final List<Question> allQuestions;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMoreQuestions;
  final ValueNotifier<String?> filterSubjectNotifier;
  final ValueNotifier<String?> filterYearNotifier;
  final ValueNotifier<String?> filterSourceNotifier;
  final ValueNotifier<String?> filterErrorTypeNotifier;
  final Map<String, int> subjectStats;
  final Map<String, int> yearStats;
  final Map<String, int> sourceStats;
  final Function(Question) onEditQuestion;
  final Function(Question) onDeleteQuestion;
  final Function(Question) onShowQuestionDetails;
  final Function() onLoadMore;
  final Function() onClearFilters;

  const DataTab({
    super.key,
    required this.questions,
    required this.allQuestions,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMoreQuestions,
    required this.filterSubjectNotifier,
    required this.filterYearNotifier,
    required this.filterSourceNotifier,
    required this.filterErrorTypeNotifier,
    required this.subjectStats,
    required this.yearStats,
    required this.sourceStats,
    required this.onEditQuestion,
    required this.onDeleteQuestion,
    required this.onShowQuestionDetails,
    required this.onLoadMore,
    required this.onClearFilters,
  });

  @override
  State<DataTab> createState() => _DataTabState();
}

class _DataTabState extends State<DataTab> {
  final ScrollController _scrollController = ScrollController();
  bool _showClearFilters = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Observar mudanças nos filtros
    widget.filterSubjectNotifier.addListener(_updateFilterVisibility);
    widget.filterYearNotifier.addListener(_updateFilterVisibility);
    widget.filterSourceNotifier.addListener(_updateFilterVisibility);
    widget.filterErrorTypeNotifier.addListener(_updateFilterVisibility);

    _updateFilterVisibility();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    EasyDebounce.cancel('filter');
    super.dispose();
  }

  void _updateFilterVisibility() {
    setState(() {
      _showClearFilters = widget.filterSubjectNotifier.value != null ||
          widget.filterYearNotifier.value != null ||
          widget.filterSourceNotifier.value != null ||
          widget.filterErrorTypeNotifier.value != null;
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !widget.isLoadingMore &&
        widget.hasMoreQuestions) {
      widget.onLoadMore();
    }
  }

  List<Question> _getFilteredQuestions() {
    final filterSubject = widget.filterSubjectNotifier.value;
    final filterYear = widget.filterYearNotifier.value;
    final filterSource = widget.filterSourceNotifier.value;
    final filterErrorType = widget.filterErrorTypeNotifier.value;

    var filtered = widget.questions;

    if (filterSubject != null && filterSubject.isNotEmpty) {
      filtered = filtered.where((q) => q.subject == filterSubject).toList();
    }

    if (filterYear != null && filterYear.isNotEmpty) {
      filtered = filtered.where((q) => q.year == filterYear).toList();
    }

    if (filterSource != null && filterSource.isNotEmpty) {
      filtered = filtered.where((q) => q.source == filterSource).toList();
    }

    if (filterErrorType != null && filterErrorType.isNotEmpty) {
      filtered = filtered.where((q) {
        // Converter a string para ErrorType
        switch (filterErrorType) {
          case 'conteudo':
            return q.errorTypes.contains(ErrorType.conteudo);
          case 'atencao':
            return q.errorTypes.contains(ErrorType.atencao);
          case 'tempo':
            return q.errorTypes.contains(ErrorType.tempo);
          default:
            return false;
        }
      }).toList();
    }

    filtered.sort((a, b) {
      final subjectCompare = a.subject.compareTo(b.subject);
      if (subjectCompare != 0) return subjectCompare;
      return a.topic.compareTo(b.topic);
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final filteredQuestions = _getFilteredQuestions();

    return Column(
      children: [
        // Filtros
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
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
                  child: ValueListenableBuilder<String?>(
                    valueListenable: widget.filterSubjectNotifier,
                    builder: (context, value, _) {
                      return DropdownButton<String?>(
                        value: value,
                        isExpanded: true,
                        underline: const SizedBox(),
                        hint: const Text('Filtrar por matéria'),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Todas as matérias'),
                          ),
                          ...SubjectDataConstants.subjectData.keys
                              .where((subject) =>
                                  widget.subjectStats.containsKey(subject))
                              .map((subject) => DropdownMenuItem<String?>(
                                    value: subject,
                                    child: Text(
                                        '$subject (${widget.subjectStats[subject] ?? 0})'),
                                  ))
                        ],
                        onChanged: (String? newValue) {
                          EasyDebounce.debounce(
                            'filter',
                            const Duration(milliseconds: 300),
                            () {
                              widget.filterSubjectNotifier.value = newValue;
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Dropdown de Ano
              Container(
                height: 50,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: ValueListenableBuilder<String?>(
                    valueListenable: widget.filterYearNotifier,
                    builder: (context, value, _) {
                      return DropdownButton<String?>(
                        value: value,
                        isExpanded: true,
                        underline: const SizedBox(),
                        hint: const Text('Filtrar por ano'),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Todos os anos'),
                          ),
                          ...SubjectDataConstants.years
                              .where(
                                  (year) => widget.yearStats.containsKey(year))
                              .map((year) => DropdownMenuItem<String?>(
                                    value: year,
                                    child: Text(
                                        '$year (${widget.yearStats[year] ?? 0})'),
                                  ))
                        ],
                        onChanged: (String? newValue) {
                          EasyDebounce.debounce(
                            'filter',
                            const Duration(milliseconds: 300),
                            () {
                              widget.filterYearNotifier.value = newValue;
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Dropdown de Fonte
              Container(
                height: 50,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: ValueListenableBuilder<String?>(
                    valueListenable: widget.filterSourceNotifier,
                    builder: (context, value, _) {
                      return DropdownButton<String?>(
                        value: value,
                        isExpanded: true,
                        underline: const SizedBox(),
                        hint: const Text('Filtrar por fonte'),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Todas as fontes'),
                          ),
                          ...SubjectDataConstants.sources
                              .where((source) =>
                                  widget.sourceStats.containsKey(source))
                              .map((source) => DropdownMenuItem<String?>(
                                    value: source,
                                    child: Text(
                                        '$source (${widget.sourceStats[source] ?? 0})'),
                                  ))
                        ],
                        onChanged: (String? newValue) {
                          EasyDebounce.debounce(
                            'filter',
                            const Duration(milliseconds: 300),
                            () {
                              widget.filterSourceNotifier.value = newValue;
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Dropdown de Tipo de Erro
              Container(
                height: 50,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: ValueListenableBuilder<String?>(
                    valueListenable: widget.filterErrorTypeNotifier,
                    builder: (context, value, _) {
                      return DropdownButton<String?>(
                        value: value,
                        isExpanded: true,
                        underline: const SizedBox(),
                        hint: const Text('Filtrar por tipo de erro'),
                        items: const [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Todos os erros'),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'conteudo',
                            child: Text('Erro de conteúdo'),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'atencao',
                            child: Text('Erro de atenção'),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'tempo',
                            child: Text('Erro de tempo'),
                          ),
                        ],
                        onChanged: (String? newValue) {
                          EasyDebounce.debounce(
                            'filter',
                            const Duration(milliseconds: 300),
                            () {
                              widget.filterErrorTypeNotifier.value = newValue;
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

              // Botão Limpar
              if (_showClearFilters)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: widget.onClearFilters,
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
          child: widget.isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredQuestions.isEmpty
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
                          if (_showClearFilters)
                            Text(
                              'Tente alterar os filtros',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      cacheExtent: 500,
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredQuestions.length +
                          (widget.hasMoreQuestions ? 1 : 0) +
                          (widget.isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= filteredQuestions.length) {
                          if (widget.isLoadingMore) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          if (widget.hasMoreQuestions) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: OutlinedButton(
                                  onPressed: widget.onLoadMore,
                                  child: const Text('Carregar mais'),
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }

                        final question = filteredQuestions[index];
                        return _buildQuestionCard(question);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(Question question) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
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
            if (question.year != null || question.source != null) ...[
              const SizedBox(height: 2),
              Wrap(
                spacing: 8,
                children: [
                  if (question.year != null)
                    Chip(
                      label: Text(question.year!),
                      backgroundColor: Colors.blue.withValues(alpha: 0.1),
                      side: BorderSide.none,
                      visualDensity: VisualDensity.compact,
                    ),
                  if (question.source != null)
                    Chip(
                      label: Text(question.source!),
                      backgroundColor: Colors.green.withValues(alpha: 0.1),
                      side: BorderSide.none,
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                if (question.errorTypes.contains(ErrorType.conteudo))
                  _buildErrorBadge('C', Colors.red),
                if (question.errorTypes.contains(ErrorType.atencao))
                  _buildErrorBadge('A', Colors.orange),
                if (question.errorTypes.contains(ErrorType.tempo))
                  _buildErrorBadge('T', Colors.blue),
              ],
            )
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: AppTheme.infoColor),
              onPressed: () => widget.onEditQuestion(question),
              tooltip: 'Editar questão',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: AppTheme.dangerColor),
              onPressed: () => widget.onDeleteQuestion(question),
              tooltip: 'Excluir questão',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        onTap: () {
          widget.onShowQuestionDetails(question);
        },
      ),
    );
  }

  Widget _buildErrorBadge(String letter, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
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
}
