import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../calendar/logic/calendar_service.dart';
import '../logic/monthly_goals_service.dart';
import '../../core/theme/theme.dart';

class MonthlyGoalsPanel extends StatelessWidget {
  const MonthlyGoalsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final calendarService = context.watch<CalendarService>();
    final goalsService = context.watch<MonthlyGoalsService>();

    final hasGeneratedGoals = goalsService.hasGoalsForCurrentMonth();

    if (!hasGeneratedGoals) {
      return _buildEmptyState(context);
    }


    final generatedGoals = goalsService.getAllSubjectGoals();

    final studiedHours =
        _calculateStudiedHours(calendarService, generatedGoals.keys.toList());

    final calendarQuestions = calendarService.getCurrentMonthQuestions();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      goalsService.syncWithCalendar(calendarQuestions);
    });

    final goalsQuestions = goalsService.getAllSubjectQuestions();


    final goalsList = generatedGoals.entries.map((entry) {
      final subject = entry.key;
      final target = entry.value;
      final current = studiedHours[subject] ?? 0.0;
      final questions =
          calendarQuestions[subject] ?? goalsQuestions[subject] ?? 0;

      return {
        'subject': subject,
        'target': target,
        'current': current,
        'questions': questions,
        'percentage': target > 0 ? (current / target * 100).clamp(0, 100) : 0.0,
      };
    }).toList();

    goalsList.sort((a, b) =>
        (b['percentage'] as double).compareTo(a['percentage'] as double));

    double totalHours = 0;
    double totalTarget = 0;
    int totalQuestions = 0;
    int completedGoals = 0;

    for (final goal in goalsList) {
      totalHours += goal['current'] as double;
      totalTarget += goal['target'] as double;
      totalQuestions += goal['questions'] as int;
      if ((goal['current'] as double) >= (goal['target'] as double)) {
        completedGoals++;
      }
    }

    final overallPercentage =
        totalTarget > 0 ? (totalHours / totalTarget * 100).round() : 0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF042044),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      margin: const EdgeInsets.all(6),
      child: Column(
        children: [
          // Cabeçalho
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFF042044),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppTheme.borderRadius),
                topRight: Radius.circular(AppTheme.borderRadius),
              ),
            ),
            child: const Row(
              children: [
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    '📊 Progresso Mensal/Meta',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: goalsList.length,
              itemBuilder: (context, index) {
                final goal = goalsList[index];
                final subject = goal['subject'] as String;
                final current = goal['current'] as double;
                final target = goal['target'] as double;
                final questions = goal['questions'] as int;
                final percentage = goal['percentage'] as double;
                final color = AppTheme.getSubjectColor(subject);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF021328),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              subject,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha:0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${current.toStringAsFixed(1)}h/${target.toStringAsFixed(1)}h',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Stack(
                        children: [
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha:0.1),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: (percentage / 100).clamp(0.0, 1.0),
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    color,
                                    color.withValues(alpha:0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${percentage.round()}% concluído',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '$questions questões resolvidas',
                            style: TextStyle(
                              fontSize: 11,
                              color: color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF042044),
              border: Border(
                top: BorderSide(color: Color(0xFF1A2F4F), width: 1),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        icon: Icons.schedule,
                        value: '${totalHours.toStringAsFixed(1)}h',
                        label: 'Horas Estudadas',
                        color: AppTheme.infoColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryCard(
                        icon: Icons.pie_chart,
                        value: '$overallPercentage%',
                        label: 'Progresso Geral',
                        color: AppTheme.successColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryCard(
                        icon: Icons.track_changes,
                        value: '${totalTarget.toStringAsFixed(1)}h',
                        label: 'Meta Total',
                        color: AppTheme.warningColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryCard(
                        icon: Icons.question_answer,
                        value: '$totalQuestions',
                        label: 'Resolvidas',
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Segunda linha - 1 card centralizado
                
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Segundo card - Matérias Concluídas
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.3,
            child: _SummaryCard(
              icon: Icons.check_circle,
              value: '$completedGoals/${goalsList.length}',
              label: 'Matérias Concluídas',
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF042044),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flag_outlined,
              size: 44,
              color: Colors.white.withValues(alpha:0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma meta definida',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withValues(alpha:0.7),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Clique no ícone 🏴 para\ngerar suas metas mensais',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha:0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Map<String, double> _calculateStudiedHours(
      CalendarService calendarService, List<String> subjects) {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;
    final lastDay = DateTime(year, month + 1, 0).day;

    final studiedHours = <String, double>{};

    // Inicializar todos os subjects com 0
    for (final subject in subjects) {
      studiedHours[subject] = 0.0;
    }

    // Contar horas estudadas no mês
    for (int day = 1; day <= lastDay; day++) {
      final dateStr =
          '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      final dayData = calendarService.getDayData(dateStr);

      if (dayData?.studyProgress != null) {
        final daySubjects = calendarService.getDaySubjects(dateStr);

        for (final subject in daySubjects) {
          final progress = dayData!.studyProgress[subject.id] ?? [];
          final hoursStudied = progress.length.toDouble();

          // Adicionar às horas estudadas se o subject estiver nas metas
          if (studiedHours.containsKey(subject.name)) {
            studiedHours[subject.name] =
                studiedHours[subject.name]! + hoursStudied;
          }
        }
      }
    }

    return studiedHours;
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.lightGray, width: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color.withValues(alpha:0.3),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
