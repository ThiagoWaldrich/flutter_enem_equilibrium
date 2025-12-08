import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/calendar_service.dart';
import '../services/monthly_goals_service.dart';
import '../utils/theme.dart';

class MonthlyGoalsPanel extends StatelessWidget {
  const MonthlyGoalsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final calendarService = context.watch<CalendarService>();
    final goalsService = context.watch<MonthlyGoalsService>();
    
    // Verificar se existem metas geradas
    final hasGeneratedGoals = goalsService.hasGoalsForCurrentMonth();
    
    if (!hasGeneratedGoals) {
      return _buildEmptyState(context);
    }
    
    // Pegar as metas geradas
    final generatedGoals = goalsService.getAllSubjectGoals();
    
    // Calcular horas estudadas no mês atual
    final studiedHours = _calculateStudiedHours(calendarService, generatedGoals.keys.toList());
    
    // Preparar dados para exibição
    final goalsList = generatedGoals.entries.map((entry) {
      final subject = entry.key;
      final target = entry.value;
      final current = studiedHours[subject] ?? 0.0;
      
      return {
        'subject': subject,
        'target': target,
        'current': current,
        'percentage': target > 0 ? (current / target * 100).clamp(0, 100) : 0.0,
      };
    }).toList();
    
    // Ordenar por progresso (menor progresso primeiro)
    goalsList.sort((a, b) => (a['percentage'] as double).compareTo(b['percentage'] as double));
    
    // Calcular totais
    double totalHours = 0;
    double totalTarget = 0;
    int completedGoals = 0;
    
    for (final goal in goalsList) {
      totalHours += goal['current'] as double;
      totalTarget += goal['target'] as double;
      if ((goal['current'] as double) >= (goal['target'] as double)) {
        completedGoals++;
      }
    }
    
    final overallPercentage = totalTarget > 0
        ? (totalHours / totalTarget * 100).round()
        : 0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF042044),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Cabeçalho
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF042044),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppTheme.borderRadius),
                topRight: Radius.circular(AppTheme.borderRadius),
              ),
            ),
            child: const Row(
              children: [
                SizedBox(width: 12),
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
                final goal = goalsList[index];
                final subject = goal['subject'] as String;
                final current = goal['current'] as double;
                final target = goal['target'] as double;
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
                      // Nome e progresso
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
                              '${current.toStringAsFixed(1)}h/${target.toStringAsFixed(1)}h',
                              style: TextStyle(
                                fontSize: 12,
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 10),
                      
                      // Barra de progresso
                      Stack(
                        children: [
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: (percentage / 100).clamp(0.0, 1.0),
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    color,
                                    color.withOpacity(0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 6),
                      
                      // Percentual
                      Text(
                        '${percentage.round()}%',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Resumo
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF042044),
              border: Border(
                top: BorderSide(color: Color(0xFF042044)),
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        icon: Icons.pie_chart,
                        value: '$overallPercentage%',
                        label: 'Progresso',
                        color: AppTheme.successColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        icon: Icons.track_changes,
                        value: '${totalTarget.toStringAsFixed(1)}h',
                        label: 'Meta Total',
                        color: AppTheme.warningColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        icon: Icons.check_circle,
                        value: '$completedGoals/${goalsList.length}',
                        label: 'Concluídas',
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
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
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma meta definida',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Clique no ícone 🏴 para\ngerar suas metas mensais',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Map<String, double> _calculateStudiedHours(CalendarService calendarService, List<String> subjects) {
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.lightGray),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 22,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}