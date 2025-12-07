import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/calendar_service.dart';
import '../utils/theme.dart';

class CalendarGrid extends StatelessWidget {
  final DateTime selectedMonth;
  final DateTime? selectedDate;
  final Function(DateTime) onDateSelected;
  final double daySize; // Novo parâmetro
  final double spacing; // Novo parâmetro

  const CalendarGrid({
    super.key,
    required this.selectedMonth,
    this.selectedDate,
    required this.onDateSelected,
    this.daySize = 30.0, // Tamanho padrão dos dias
    this.spacing = 8.0,
  });

  List<DateTime> _getDaysInMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);

    final firstWeekday = firstDay.weekday % 7;
    final previousMonthDays = List.generate(firstWeekday, (index) {
      return firstDay.subtract(Duration(days: firstWeekday - index));
    });

    final currentMonthDays = List.generate(lastDay.day, (index) {
      return DateTime(month.year, month.month, index + 1);
    });

    final totalDays = previousMonthDays.length + currentMonthDays.length;
    final nextMonthDaysCount = 42 - totalDays;
    final nextMonthDays = List.generate(nextMonthDaysCount, (index) {
      return lastDay.add(Duration(days: index + 1));
    });

    return [...previousMonthDays, ...currentMonthDays, ...nextMonthDays];
  }

  @override
  Widget build(BuildContext context) {
    final calendarService = context.watch<CalendarService>();
    final days = _getDaysInMonth(selectedMonth);
    final weekdays = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

    return Container(
      decoration: BoxDecoration(
        color: Color(0XFF042044),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing * 2), // Usar spacing dinâmico
        child: Column(
          children: [
            // Cabeçalho com dias da semana
            Container(
              padding: EdgeInsets.only(bottom: spacing),
              child: Row(
                children: weekdays.map((day) {
                  return Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: daySize * 0.22, // Tamanho relativo
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const Divider(height: 1),
            SizedBox(height: spacing),

            // Grid de dias
            Expanded(
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                ),
                itemCount: days.length,
                itemBuilder: (context, index) {
                  final day = days[index];
                  final isCurrentMonth = day.month == selectedMonth.month;
                  final isSelected = selectedDate != null &&
                      day.year == selectedDate!.year &&
                      day.month == selectedDate!.month &&
                      day.day == selectedDate!.day;
                  final isToday = day.year == DateTime.now().year &&
                      day.month == DateTime.now().month &&
                      day.day == DateTime.now().day;

                  final dateStr = DateFormat('yyyy-MM-dd').format(day);
                  final dayProgress = isCurrentMonth
                      ? calendarService.getDayProgress(dateStr)
                      : null;
                  final total = (dayProgress?['total'] ?? 0) as int;
                  final percentage = (dayProgress?['percentage'] ?? 0) as int;

                  final hasData = total > 0;

                  return GestureDetector(
                    onTap: () => onDateSelected(day),
                    child: _DayCell(
                      day: day.day,
                      isCurrentMonth: isCurrentMonth,
                      isSelected: isSelected,
                      isToday: isToday,
                      hasData: hasData,
                      percentage: percentage,
                      daySize: daySize,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isCurrentMonth;
  final bool isSelected;
  final bool isToday;
  final bool hasData;
  final int percentage;
  final double daySize;

  const _DayCell({
    required this.day,
    required this.isCurrentMonth,
    required this.isSelected,
    required this.isToday,
    required this.hasData,
    required this.percentage,
    required this.daySize,
  });

  @override
  Widget build(BuildContext context) {
    Color? backgroundColor;
    Color textColor = Colors.white;
    Color? borderColor;

    if (isSelected) {
      backgroundColor = AppTheme.primaryColor;
      textColor = Colors.white;
    } else if (isToday) {
      backgroundColor = AppTheme.primaryColor;
      borderColor = const Color(0xFFFF8000);
    }

    if (!isCurrentMonth) {
      textColor = AppTheme.textSecondary.withOpacity(0.3);
    }

    return Container(
      margin: EdgeInsets.all(spacing * 0.25), // Usar spacing relativo
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(daySize * 0.2), // Borda relativa
        border: Border.all(
          color: borderColor ?? AppTheme.lightGray.withOpacity(0.5),
          width: borderColor != null ? 2 : 1,
        ),
      ),
      child: Stack(
        children: [
          // Número do dia
          Center(
            child: Text(
              day.toString(),
              style: TextStyle(
                fontSize: daySize * 0.28, // Tamanho relativo
                fontWeight:
                    isToday || isSelected ? FontWeight.bold : FontWeight.w500,
                color: textColor,
              ),
            ),
          ),

          // Indicador de progresso
          if (hasData && isCurrentMonth && !isSelected)
            Positioned(
              bottom: spacing * 0.5,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: daySize * 0.5, // Largura relativa
                  height: daySize * 0.06, // Altura relativa
                  decoration: BoxDecoration(
                    color: _getProgressColor(percentage).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(daySize * 0.03),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (percentage / 100).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _getProgressColor(percentage),
                        borderRadius: BorderRadius.circular(daySize * 0.03),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Método getter para acessar spacing do widget pai
  double get spacing => daySize * 0.08; // Spacing baseado no daySize

  Color _getProgressColor(int percentage) {
    if (percentage >= 100) return AppTheme.successColor;
    if (percentage >= 50) return AppTheme.warningColor;
    return AppTheme.dangerColor;
  }
}