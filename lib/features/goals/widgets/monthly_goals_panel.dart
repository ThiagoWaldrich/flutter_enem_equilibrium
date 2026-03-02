import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../calendar/logic/calendar_service.dart';
import '../logic/monthly_goals_service.dart';
import '../../core/theme/theme.dart';

class MonthlyGoalsPanel extends StatefulWidget {
  const MonthlyGoalsPanel({super.key});

  @override
  State<MonthlyGoalsPanel> createState() => _MonthlyGoalsPanelState();
}

class _MonthlyGoalsPanelState extends State<MonthlyGoalsPanel> {
  String? _selectedMonth;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncOnce();
    });
  }

  void _syncOnce() {
    final calendarService = context.read<CalendarService>();
    final goalsService = context.read<MonthlyGoalsService>();
    
    if (!goalsService.hasGoalsForCurrentMonth()) return;
    
    final calendarQuestions = calendarService.getCurrentMonthQuestions();
    goalsService.syncWithCalendar(calendarQuestions);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MonthlyGoalsService>(
      builder: (context, goalsService, _) {
        final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
        final hasCurrentGoals = goalsService.hasGoalsForCurrentMonth();
        final availableMonths = goalsService.availableMonths;
        
        if (hasCurrentGoals && _selectedMonth == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _selectedMonth = currentMonth;
              });
            }
          });
        }
        
        if (!hasCurrentGoals && availableMonths.isNotEmpty && _selectedMonth == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _selectedMonth = availableMonths.first;
              });
            }
          });
        }
        
        if (_selectedMonth != null && !availableMonths.contains(_selectedMonth)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _selectedMonth = hasCurrentGoals ? currentMonth : 
                    (availableMonths.isNotEmpty ? availableMonths.first : null);
              });
            }
          });
        }

        final isViewingCurrentMonth = _selectedMonth == currentMonth;
        
        return Column(
          children: [
            if (availableMonths.length > 1) 
              _buildMonthSelector(goalsService, currentMonth, isViewingCurrentMonth),
            Expanded(
              child: _buildGoalsContent(goalsService, currentMonth),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMonthSelector(MonthlyGoalsService goalsService, String currentMonth, bool isViewingCurrentMonth) {
    final availableMonths = goalsService.availableMonths;
    
    return Container(
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF042044),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (!isViewingCurrentMonth && goalsService.hasGoalsForCurrentMonth())
            IconButton(
              icon: const Icon(Icons.refresh, size: 16),
              color: Colors.white,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: () {
                setState(() {
                  _selectedMonth = currentMonth;
                });
              },
              tooltip: 'Mês atual',
            ),
          
          Expanded(
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: availableMonths.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final month = availableMonths[index];
                  final isSelected = _selectedMonth == month;
                  final isCurrentMonth = month == currentMonth;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedMonth = month;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? AppTheme.primaryColor 
                            : const Color(0xFF0A2A55),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isCurrentMonth 
                              ? Colors.yellow.withOpacity(0.5) 
                              : Colors.transparent,
                          width: isCurrentMonth ? 1 : 0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isCurrentMonth) ...[
                            const Icon(Icons.star, size: 10, color: Colors.yellow),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            _formatMonthName(month),
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          if (availableMonths.length > 3)
            IconButton(
              icon: const Icon(Icons.more_horiz, size: 18),
              color: AppTheme.primaryColor,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: () => _showMonthPicker(goalsService, currentMonth),
            ),
        ],
      ),
    );
  }

  Widget _buildGoalsContent(MonthlyGoalsService goalsService, String currentMonth) {
    final isCurrentMonth = _selectedMonth == currentMonth;
    
    if (_selectedMonth == null || !goalsService.hasGoalsForMonth(_selectedMonth!)) {
      return _buildEmptyState(context, isHistorical: _selectedMonth != null && _selectedMonth != currentMonth);
    }
    
    return Selector2<CalendarService, MonthlyGoalsService, _GoalsData>(
      selector: (_, calendar, goals) {
        final month = _selectedMonth!;
        
        final monthData = month == currentMonth 
            ? goals.currentMonthGoals 
            : goals.historicalGoals[month];
        
        if (monthData == null) {
          return _GoalsData(
            generatedGoals: {},
            studiedHours: {},
            calendarQuestions: {},
            goalsQuestions: {},
            monthName: _formatMonthName(month),
            isHistorical: !isCurrentMonth,
          );
        }
        
        final generatedGoals = (monthData['subjects'] as Map<String, dynamic>? ?? {})
            .map((key, value) => MapEntry(key, (value as num).toDouble()));
        final subjects = generatedGoals.keys.toList();
        
        Map<String, double> studiedHours = isCurrentMonth
            ? _calculateCurrentMonthStudiedHours(calendar, subjects)
            : _calculateHistoricalStudiedHours(calendar, monthData, month);
        
        final calendarQuestions = isCurrentMonth
            ? calendar.getCurrentMonthQuestions()
            : (monthData['questions'] as Map<String, dynamic>? ?? {})
                .map((key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0));
        
        final goalsQuestions = (monthData['questions'] as Map<String, dynamic>? ?? {})
            .map((key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0));
        
        final monthName = monthData['monthName'] as String? ?? _formatMonthName(month);
        
        return _GoalsData(
          generatedGoals: generatedGoals,
          studiedHours: studiedHours,
          calendarQuestions: calendarQuestions,
          goalsQuestions: goalsQuestions,
          monthName: monthName,
          isHistorical: !isCurrentMonth,
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

    return Column(
      children: [
        _buildSummary(
          totalHours: totalHours,
          overallPercentage: overallPercentage,
          totalTarget: totalTarget,
          totalQuestions: totalQuestions,
          completedGoals: completedGoals,
          totalGoals: goalsList.length,
          isHistorical: data.isHistorical,
        ),
        Expanded(
          child: goalsList.isEmpty
              ? _buildNoDataState()
              : Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    itemCount: goalsList.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      return _GoalCard(goal: goalsList[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSummary({
    required double totalHours,
    required int overallPercentage,
    required double totalTarget,
    required int totalQuestions,
    required int completedGoals,
    required int totalGoals,
    required bool isHistorical,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHistorical 
            ? const Color(0xFF1A3A6A)
            : const Color(0xFF042044),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                icon: Icons.schedule,
                value: '${totalHours.toStringAsFixed(1)}h',
                label: 'Horas',
                color: AppTheme.infoColor,
              ),
              _buildSummaryItem(
                icon: Icons.pie_chart,
                value: '$overallPercentage%',
                label: 'Progresso',
                color: AppTheme.successColor,
              ),
              _buildSummaryItem(
                icon: Icons.track_changes,
                value: '${totalTarget.toStringAsFixed(1)}h',
                label: 'Meta',
                color: AppTheme.warningColor,
              ),
              _buildSummaryItem(
                icon: Icons.question_answer,
                value: '$totalQuestions',
                label: 'Resolvidas',
                color: AppTheme.secondaryColor,
              ),
              _buildSummaryItem(
                icon: Icons.check_circle,
                value: '$completedGoals/$totalGoals',
                label: 'Concluídas',
                color: AppTheme.primaryColor,
              ),
            ],
          ),
          if (isHistorical) ...[
            const SizedBox(height: 8),
            Text(
              'Dados históricos - sincronizado com calendário',
              style: TextStyle(
                fontSize: 10,
                color: Colors.orange.withOpacity(0.7),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 12,
              color: color.withOpacity(0.8),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flag_outlined,
              size: 40,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Sem dados para este mês',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Não foram encontradas metas\ngeradas para este período',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, {bool isHistorical = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flag_outlined,
              size: 40,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              isHistorical
                  ? 'Nenhuma meta para este mês'
                  : 'Nenhuma meta definida',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isHistorical
                  ? 'Selecione outro mês ou\ngere metas para o mês atual'
                  : 'Clique no ícone 🏴 para\ngerar suas metas mensais',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Map<String, double> _calculateCurrentMonthStudiedHours(
    CalendarService calendarService,
    List<String> subjects,
  ) {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;
    final lastDay = DateTime(year, month + 1, 0).day;

    final studiedHours = <String, double>{};
    for (final subject in subjects) {
      studiedHours[subject] = 0.0;
    }

    for (int day = 1; day <= lastDay; day++) {
      final dateStr = '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      final dayData = calendarService.getDayData(dateStr);

      if (dayData?.studyProgress != null) {
        final daySubjects = calendarService.getDaySubjects(dateStr);

        for (final subject in daySubjects) {
          final progress = dayData!.studyProgress[subject.id] ?? [];
          final hoursStudied = progress.length.toDouble();

          if (studiedHours.containsKey(subject.name)) {
            studiedHours[subject.name] = studiedHours[subject.name]! + hoursStudied;
          }
        }
      }
    }

    return studiedHours;
  }

  Map<String, double> _calculateHistoricalStudiedHours(
    CalendarService calendarService,
    Map<String, dynamic> monthData,
    String monthStr,
  ) {
    final studiedHours = <String, double>{};
    
    final storedProgress = monthData['progress'] as Map<String, dynamic>? ?? {};
    final subjects = (monthData['subjects'] as Map<String, dynamic>? ?? {}).keys.toList();
    
    for (final subject in subjects) {
      studiedHours[subject] = 0.0;
    }
    
    bool hasStoredProgress = false;
    for (final entry in storedProgress.entries) {
      final subject = entry.key;
      final progressData = entry.value as Map<String, dynamic>? ?? {};
      final completedHours = (progressData['completedHours'] as num?)?.toDouble() ?? 0.0;
      
      if (completedHours > 0 && studiedHours.containsKey(subject)) {
        studiedHours[subject] = completedHours;
        hasStoredProgress = true;
      }
    }
    
    if (!hasStoredProgress) {
      try {
        final parts = monthStr.split('-');
        if (parts.length == 2) {
          final year = int.tryParse(parts[0]);
          final month = int.tryParse(parts[1]);
          
          if (year != null && month != null) {
            final lastDay = DateTime(year, month + 1, 0).day;
            
            for (int day = 1; day <= lastDay; day++) {
              final dateStr = '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
              final dayData = calendarService.getDayData(dateStr);
              
              if (dayData?.studyProgress != null) {
                final daySubjects = calendarService.getDaySubjects(dateStr);
                
                for (final subject in daySubjects) {
                  final progress = dayData!.studyProgress[subject.id] ?? [];
                  final hoursStudied = progress.length.toDouble();
                  
                  if (studiedHours.containsKey(subject.name)) {
                    studiedHours[subject.name] = studiedHours[subject.name]! + hoursStudied;
                  }
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Erro ao calcular horas históricas: $e');
      }
    }
    
    return studiedHours;
  }

  String _formatMonthName(String monthStr) {
    try {
      final parts = monthStr.split('-');
      if (parts.length != 2) return monthStr;
      
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      
      if (year == null || month == null) return monthStr;
      
      final monthNames = {
        1: 'Jan',
        2: 'Fev', 
        3: 'Mar',
        4: 'Abr',
        5: 'Mai',
        6: 'Jun',
        7: 'Jul',
        8: 'Ago',
        9: 'Set',
        10: 'Out',
        11: 'Nov',
        12: 'Dez',
      };
      
      return '${monthNames[month] ?? month}/$year';
    } catch (e) {
      return monthStr;
    }
  }

  void _showMonthPicker(MonthlyGoalsService goalsService, String currentMonth) {
    final availableMonths = goalsService.availableMonths;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF042044),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.borderRadius)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Selecionar Mês',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: availableMonths.length,
                  itemBuilder: (context, index) {
                    final month = availableMonths[index];
                    final isCurrentMonth = month == currentMonth;
                    
                    return ListTile(
                      leading: isCurrentMonth
                          ? const Icon(Icons.star, color: Colors.yellow, size: 20)
                          : const Icon(Icons.history, color: Colors.white70, size: 20),
                      title: Text(
                        _formatMonthName(month),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: _selectedMonth == month ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: _selectedMonth == month
                          ? Icon(Icons.check, color: AppTheme.primaryColor)
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _selectedMonth = month;
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GoalsData {
  final Map<String, double> generatedGoals;
  final Map<String, double> studiedHours;
  final Map<String, int> calendarQuestions;
  final Map<String, int> goalsQuestions;
  final String monthName;
  final bool isHistorical;

  const _GoalsData({
    required this.generatedGoals,
    required this.studiedHours,
    required this.calendarQuestions,
    required this.goalsQuestions,
    required this.monthName,
    required this.isHistorical,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _GoalsData &&
          runtimeType == other.runtimeType &&
          monthName == other.monthName &&
          isHistorical == other.isHistorical &&
          _mapsEqual(generatedGoals, other.generatedGoals) &&
          _mapsEqual(studiedHours, other.studiedHours) &&
          _mapsEqual(calendarQuestions, other.calendarQuestions) &&
          _mapsEqual(goalsQuestions, other.goalsQuestions);

  @override
  int get hashCode =>
      monthName.hashCode ^
      isHistorical.hashCode ^
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

class _GoalCard extends StatelessWidget {
  final _GoalItem goal;

  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getSubjectColor(goal.subject);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF021328),
        borderRadius: BorderRadius.circular(10),
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
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${goal.current.toStringAsFixed(1)}h/${goal.target.toStringAsFixed(1)}h',
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 5,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (goal.percentage / 100).clamp(0.0, 1.0),
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color,
                        color.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${goal.percentage.round()}% concluído',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${goal.questions} questões resolvidas',
                style: TextStyle(
                  fontSize: 10,
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