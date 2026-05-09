import 'package:equilibrium/features/analytics/widgets/topic_bar_chart.dart';
import 'package:equilibrium/features/questions/models/question.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

class ChartsTab extends StatefulWidget {
  final Map<String, dynamic> stats;
  final List<Question> questions;
  final bool isLoading;
  final Map<String, int> subjectStats;
  final Map<String, int> yearStats;
  final Map<String, int> sourceStats;
  final Map<String, Map<String, dynamic>> errorStats;
  final int totalQuestions;
  final Function(String)? onSubjectSelected;

  const ChartsTab({
    super.key,
    required this.stats,
    required this.questions,
    required this.isLoading,
    required this.subjectStats,
    required this.yearStats,
    required this.sourceStats,
    required this.errorStats,
    required this.totalQuestions,
    this.onSubjectSelected,
  });

  @override
  State<ChartsTab> createState() => _ChartsTabState();
}

class _ChartsTabState extends State<ChartsTab> {
  String? _selectedSubject;
  bool _showTopicChart = false;
  bool _showSubtopicChart = false;
  Map<String, int> _topicStatsForSubject = {};
  Map<String, int> _subtopicStatsForSubject = {};

  @override
  void initState() {
    super.initState();
    _selectedSubject = widget.subjectStats.isNotEmpty
        ? widget.subjectStats.entries.first.key
        : null;
    _updateStatsForSelectedSubject();
  }

  void _updateStatsForSelectedSubject() {
    if (_selectedSubject == null) {
      _topicStatsForSubject = {};
      _subtopicStatsForSubject = {};
      return;
    }

    final topicStats = <String, int>{};
    final subtopicStats = <String, int>{};

    for (final question in widget.questions) {
      if (question.subject == _selectedSubject) {
        final topic = question.topic;
        topicStats[topic] = (topicStats[topic] ?? 0) + 1;

        if (question.subtopic != null && question.subtopic!.isNotEmpty) {
          final subtopic = question.subtopic!;
          subtopicStats[subtopic] = (subtopicStats[subtopic] ?? 0) + 1;
        }
      }
    }

    setState(() {
      _topicStatsForSubject = topicStats;
      _subtopicStatsForSubject = subtopicStats;
    });
  }

  void _selectSubject(String subject) {
    setState(() {
      _selectedSubject = subject;
      _showTopicChart = false;
      _showSubtopicChart = false;
      _updateStatsForSelectedSubject();
    });
    widget.onSubjectSelected?.call(subject);
  }

  Widget _buildPieChart() {
    final sortedStats = widget.subjectStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: RepaintBoundary(
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 60,
                  sections: sortedStats.take(10).map((entry) {
                    final color = AppTheme.getSubjectColor(entry.key);
                    final percentage = (widget.totalQuestions > 0
                            ? (entry.value / widget.totalQuestions * 100)
                            : 0)
                        .round();
                    final isSelected = entry.key == _selectedSubject;

                    return PieChartSectionData(
                      value: entry.value.toDouble(),
                      title: '$percentage%',
                      color: color.withValues(alpha: isSelected ? 1.0 : 0.7),
                      radius: isSelected ? 90 : 80,
                      titleStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: isSelected
                            ? [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 4,
                                )
                              ]
                            : null,
                      ),
                    );
                  }).toList(),
                  pieTouchData: PieTouchData(
                    touchCallback: (event, pieTouchResponse) {
                      if (event is FlTapUpEvent && pieTouchResponse != null) {
                        final section = pieTouchResponse.touchedSection;
                        if (section != null) {
                          final index = section.touchedSectionIndex;
                          if (index >= 0 && index < sortedStats.length) {
                            _selectSubject(sortedStats[index].key);
                          }
                        }
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: sortedStats.take(10).map((entry) {
              final color = AppTheme.getSubjectColor(entry.key);
              final isSelected = entry.key == _selectedSubject;
              return GestureDetector(
                onTap: () => _selectSubject(entry.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? color : color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: color,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${entry.key} (${entry.value})',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorStats() {
    final contentErrors = widget.questions
        .where((q) => q.errorTypes.contains(ErrorType.conteudo))
        .length;
    final attentionErrors = widget.questions
        .where((q) => q.errorTypes.contains(ErrorType.atencao))
        .length;
    final timeErrors = widget.questions
        .where((q) => q.errorTypes.contains(ErrorType.tempo))
        .length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                  contentErrors,
                  Colors.red,
                  Icons.menu_book,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildErrorStatCard(
                  'Atenção',
                  attentionErrors,
                  Colors.orange,
                  Icons.visibility_off,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildErrorStatCard(
                  'Tempo',
                  timeErrors,
                  Colors.blue,
                  Icons.access_time,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // GRÁFICO DE ERROS POR MATÉRIA - substitui o YearBarChart
  Widget _buildErrorsBySubjectChart() {
    // Calcula erros por matéria
    final Map<String, int> errorsBySubject = {};
    for (final question in widget.questions) {
      if (question.errorTypes.isNotEmpty) {
        errorsBySubject[question.subject] = 
            (errorsBySubject[question.subject] ?? 0) + 1;
      }
    }
    
    if (errorsBySubject.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.bar_chart, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Nenhum erro registrado ainda',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }
    
    // Ordenar por quantidade de erros (decrescente)
    final sortedEntries = errorsBySubject.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final maxErrors = sortedEntries.first.value.toDouble();
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart, color: Colors.red),
              SizedBox(width: 8),
              Text(
                '📊 Erros por Matéria',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Total de erros: ${errorsBySubject.values.reduce((a, b) => a + b)}',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 400,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxErrors * 1.1,
                minY: 0,
                barGroups: sortedEntries.asMap().entries.map((entry) {
                  final index = entry.key;
                  final subjectEntry = entry.value;
                  
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: subjectEntry.value.toDouble(),
                        color: AppTheme.getSubjectColor(subjectEntry.key),
                        width: 40,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < sortedEntries.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: RotatedBox(
                              quarterTurns: 1,
                              child: Text(
                                sortedEntries[index].key,
                                style: const TextStyle(fontSize: 11),
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
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                ),
                borderData: FlBorderData(show: true),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legenda com valores
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: sortedEntries.map((entry) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.getSubjectColor(entry.key).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.getSubjectColor(entry.key).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '${entry.key}: ${entry.value}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.getSubjectColor(entry.key),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectControls() {
    if (_selectedSubject == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Matéria selecionada: $_selectedSubject',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.pie_chart),
                label: const Text('Tópicos'),
                onPressed: () {
                  setState(() {
                    _showTopicChart = true;
                    _showSubtopicChart = false;
                  });
                },
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.donut_large),
                label: const Text('Subtópicos'),
                onPressed: () {
                  setState(() {
                    _showSubtopicChart = true;
                    _showTopicChart = false;
                  });
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _selectedSubject = null;
                    _showTopicChart = false;
                    _showSubtopicChart = false;
                  });
                },
                tooltip: 'Limpar seleção',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
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
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorStatCard(String label, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total de Questões',
                    widget.totalQuestions.toString(),
                    Icons.quiz,
                    AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Matérias',
                    widget.subjectStats.length.toString(),
                    Icons.book,
                    AppTheme.successColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildErrorStats(),
            const SizedBox(height: 24),
            if (widget.totalQuestions > 0) _buildPieChart(),
            const SizedBox(height: 16),
            if (_selectedSubject != null) ...[
              _buildSubjectControls(),
              const SizedBox(height: 16),
              if (_showTopicChart)
                TopicBarChart(data: _topicStatsForSubject, title: 'Tópicos de $_selectedSubject'),
              if (_showSubtopicChart)
                TopicBarChart(data: _subtopicStatsForSubject, title: 'Subtópicos de $_selectedSubject'),
            ],
            const SizedBox(height: 24),
            // GRÁFICO DE ERROS POR MATÉRIA (substitui o YearBarChart)
            _buildErrorsBySubjectChart(),
          ],
        ),
      ),
    );
  }
}