import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../calendar/logic/calendar_service.dart';
import '../logic/monthly_goals_service.dart';
import '../../core/theme/theme.dart';

class MonthlyGoalsPanel extends StatefulWidget {
  const MonthlyGoalsPanel({super.key});

  @override
  State<MonthlyGoalsPanel> createState() => _MonthlyGoalsPanelState();
}

class _MonthlyGoalsPanelState extends State<MonthlyGoalsPanel> {
  // Cache para evitar recálculos
  Map<String, double>? _cachedStudiedHours;
  List<String>? _cachedSubjects;
  String? _cachedMonthKey;
  
  @override
  void initState() {
    super.initState();
    // Sincroniza apenas uma vez na inicialização
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncOnce();
    });
  }

  /// Sincroniza apenas UMA VEZ quando o widget é criado
  void _syncOnce() {
    final calendarService = context.read<CalendarService>();
    final goalsService = context.read<MonthlyGoalsService>();
    
    if (!goalsService.hasGoalsForCurrentMonth()) return;
    
    final calendarQuestions = calendarService.getCurrentMonthQuestions();
    goalsService.syncWithCalendar(calendarQuestions);
  }

  @override
  Widget build(BuildContext context) {
    return Selector<MonthlyGoalsService, bool>(
      selector: (_, service) => service.hasGoalsForCurrentMonth(),
      builder: (context, hasGoals, _) {
        if (!hasGoals) {
          return _buildEmptyState(context);
        }
        
        return _buildGoalsContent();
      },
    );
  }

  Widget _buildGoalsContent() {
    // Usa Selector para reconstruir apenas quando necessário
    return Selector2<CalendarService, MonthlyGoalsService, _GoalsData>(
      selector: (_, calendar, goals) {
        final generatedGoals = goals.getAllSubjectGoals();
        final subjects = generatedGoals.keys.toList();
        final monthKey = '${DateTime.now().year}-${DateTime.now().month}';
        
        // Recalcula horas apenas se mudou o mês ou as matérias
        Map<String, double> studiedHours;
        if (_cachedMonthKey != monthKey || _cachedSubjects != subjects) {
          studiedHours = _calculateStudiedHours(calendar, subjects);
          _cachedStudiedHours = studiedHours;
          _cachedSubjects = subjects;
          _cachedMonthKey = monthKey;
        } else {
          studiedHours = _cachedStudiedHours!;
        }
        
        final calendarQuestions = calendar.getCurrentMonthQuestions();
        final goalsQuestions = goals.getAllSubjectQuestions();
        
        return _GoalsData(
          generatedGoals: generatedGoals,
          studiedHours: studiedHours,
          calendarQuestions: calendarQuestions,
          goalsQuestions: goalsQuestions,
        );
      },
      builder: (context, data, _) {
        return _buildGoalsList(data);
      },
    );
  }

  Widget _buildGoalsList(_GoalsData data) {
    final goalsList = data.generatedGoals.entries.map((entry) {
      final subject = entry.key;
      final target = entry.value;
      final current = data.studiedHours[subject] ?? 0.0;
      final questions = data.calendarQuestions[subject] ?? data.goalsQuestions[subject] ?? 0;

      return _GoalItem(
        subject: subject,
        target: target,
        current: current,
        questions: questions,
        percentage: target > 0 ? (current / target * 100).clamp(0, 100) : 0.0,
      );
    }).toList();

    goalsList.sort((a, b) => b.percentage.compareTo(a.percentage));

    double totalHours = 0;
    double totalTarget = 0;
    int totalQuestions = 0;
    int completedGoals = 0;

    for (final goal in goalsList) {
      totalHours += goal.current;
      totalTarget += goal.target;
      totalQuestions += goal.questions;
      if (goal.current >= goal.target) {
        completedGoals++;
      }
    }

    final overallPercentage = totalTarget > 0 ? (totalHours / totalTarget * 100).round() : 0;

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

          // Lista de metas
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: goalsList.length,
              itemBuilder: (context, index) {
                return _GoalCard(goal: goalsList[index]);
              },
            ),
          ),

          // Resumo
          _buildSummary(
            totalHours: totalHours,
            overallPercentage: overallPercentage,
            totalTarget: totalTarget,
            totalQuestions: totalQuestions,
            completedGoals: completedGoals,
            totalGoals: goalsList.length,
          ),
        ],
      ),
    );
  }

  Widget _buildSummary({
    required double totalHours,
    required int overallPercentage,
    required double totalTarget,
    required int totalQuestions,
    required int completedGoals,
    required int totalGoals,
  }) {
    return Container(
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
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.3,
            child: _SummaryCard(
              icon: Icons.check_circle,
              value: '$completedGoals/$totalGoals',
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
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma meta definida',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Clique no ícone 🏴 para\ngerar suas metas mensais',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Map<String, double> _calculateStudiedHours(
    CalendarService calendarService,
    List<String> subjects,
  ) {
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
      final dateStr = '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      final dayData = calendarService.getDayData(dateStr);

      if (dayData?.studyProgress != null) {
        final daySubjects = calendarService.getDaySubjects(dateStr);

        for (final subject in daySubjects) {
          final progress = dayData!.studyProgress[subject.id] ?? [];
          final hoursStudied = progress.length.toDouble();

          // Adicionar às horas estudadas se o subject estiver nas metas
          if (studiedHours.containsKey(subject.name)) {
            studiedHours[subject.name] = studiedHours[subject.name]! + hoursStudied;
          }
        }
      }
    }

    return studiedHours;
  }
}

// Classe para encapsular os dados das metas
class _GoalsData {
  final Map<String, double> generatedGoals;
  final Map<String, double> studiedHours;
  final Map<String, int> calendarQuestions;
  final Map<String, int> goalsQuestions;

  const _GoalsData({
    required this.generatedGoals,
    required this.studiedHours,
    required this.calendarQuestions,
    required this.goalsQuestions,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _GoalsData &&
          runtimeType == other.runtimeType &&
          _mapsEqual(generatedGoals, other.generatedGoals) &&
          _mapsEqual(studiedHours, other.studiedHours) &&
          _mapsEqual(calendarQuestions, other.calendarQuestions) &&
          _mapsEqual(goalsQuestions, other.goalsQuestions);

  @override
  int get hashCode =>
      generatedGoals.hashCode ^
      studiedHours.hashCode ^
      calendarQuestions.hashCode ^
      goalsQuestions.hashCode;

  bool _mapsEqual(Map a, Map b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }
}

// Item de meta - imutável
class _GoalItem {
  final String subject;
  final double target;
  final double current;
  final int questions;
  final double percentage;

  const _GoalItem({
    required this.subject,
    required this.target,
    required this.current,
    required this.questions,
    required this.percentage,
  });
}

// Card de meta individual - StatelessWidget para melhor performance
class _GoalCard extends StatelessWidget {
  final _GoalItem goal;

  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getSubjectColor(goal.subject);

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
                  goal.subject,
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
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${goal.current.toStringAsFixed(1)}h/${goal.target.toStringAsFixed(1)}h',
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
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (goal.percentage / 100).clamp(0.0, 1.0),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color,
                        color.withValues(alpha: 0.7),
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
                '${goal.percentage.round()}% concluído',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${goal.questions} questões resolvidas',
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
            color: color.withValues(alpha: 0.3),
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