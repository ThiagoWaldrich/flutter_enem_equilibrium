import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/calendar_service.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';

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

  // NOVO: Verificar se é feriado nacional
  bool _isNationalHoliday(DateTime date) {
    final dateStr = DateFormat('MM-dd').format(date);
    final holidayText = AppConstants.holidays2026[dateStr];
    
    // Lista de feriados nacionais (excluindo datas comemorativas)
    final nationalHolidays = {
      '01-01', // Ano Novo
      '04-03', // Sexta-feira Santa
      '04-21', // Tiradentes
      '05-01', // Dia do Trabalho
      '06-04', // Corpus Christi
      '09-07', // Independência do Brasil
      '10-12', // Nossa Senhora Aparecida
      '11-02', // Finados
      '11-15', // Proclamação da República
      '12-25', // Natal
      // Carnaval (datas móveis)
      '02-16', '02-17',
    };
    
    return holidayText != null && nationalHolidays.contains(dateStr);
  }

  // NOVO: Verificar se é data comemorativa
  bool _isCommemorativeDate(DateTime date) {
    final dateStr = DateFormat('MM-dd').format(date);
    final holidayText = AppConstants.holidays2026[dateStr];
    
    // Se está no mapa mas NÃO é feriado nacional, é data comemorativa
    return holidayText != null && !_isNationalHoliday(date);
  }

  // NOVO: Obter texto do feriado/data comemorativa
  String? _getHolidayText(DateTime date) {
    final dateStr = DateFormat('MM-dd').format(date);
    return AppConstants.holidays2026[dateStr];
  }

  @override
  Widget build(BuildContext context) {
    final calendarService = context.watch<CalendarService>();
    final days = _getDaysInMonth(selectedMonth);
    final weekdays = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

    return Container(
      decoration: BoxDecoration(
        color:const Color(0XFF042044),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            blurRadius: 10,
            offset: Offset(0, 2),
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
                          fontSize: daySize * 0.5, // Tamanho relativo
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

                  // NOVO: Verificar se é feriado ou data comemorativa
                  final holidayText = _getHolidayText(day);
                  final isNationalHoliday = _isNationalHoliday(day);
                  final isCommemorativeDate = _isCommemorativeDate(day);
                  final isSpecialDay = (isNationalHoliday || isCommemorativeDate) && isCurrentMonth;

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
                      holidayText: holidayText,
                      isNationalHoliday: isNationalHoliday,
                      isCommemorativeDate: isCommemorativeDate,
                      isSpecialDay: isSpecialDay,
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
  final String? holidayText;
  final bool isNationalHoliday;
  final bool isCommemorativeDate;
  final bool isSpecialDay;

  const _DayCell({
    required this.day,
    required this.isCurrentMonth,
    required this.isSelected,
    required this.isToday,
    required this.hasData,
    required this.percentage,
    required this.daySize,
    this.holidayText,
    required this.isNationalHoliday,
    required this.isCommemorativeDate,
    required this.isSpecialDay,
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
      textColor = AppTheme.textSecondary.withValues(alpha: 0.3);
    }

    // NOVO: Definir cor de fundo para dias especiais
    Color? specialDayBackgroundColor;
    if (isSpecialDay) {
      if (isNationalHoliday) {
        specialDayBackgroundColor = AppConstants.holidayColor;
      } else if (isCommemorativeDate) {
        specialDayBackgroundColor = AppConstants.commemorativeDateColor;
      }
    }

    return Container(
      margin: EdgeInsets.all(spacing * 0.25),
      decoration: BoxDecoration(
        color: specialDayBackgroundColor ?? backgroundColor,
        borderRadius: BorderRadius.circular(daySize * 0.2), 
        border: Border.all(
          color: borderColor ?? AppTheme.lightGray.withValues(alpha:0.5),
          width: borderColor != null ? 2 : 1,
        ),
      ),
      child: Stack(
        children: [
          // Número do dia
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day.toString(),
                  style: TextStyle(
                    fontSize: daySize * 0.3, // Tamanho relativo
                    fontWeight: isToday || isSelected 
                        ? FontWeight.bold 
                        : (isSpecialDay ? FontWeight.w600 : FontWeight.w500),
                    color: isSpecialDay 
                        ? Colors.white // Texto branco em fundo colorido
                        : textColor,
                  ),
                ),
                

                if (holidayText != null && isCurrentMonth && (isNationalHoliday || isCommemorativeDate))
                  Padding(
                    padding: EdgeInsets.only(top: daySize * 0.03),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: daySize * 0.03,
                        vertical: daySize * 0.01,
                      ),
                      decoration: BoxDecoration(
                        color: isNationalHoliday 
                            ? Colors.white.withValues(alpha:0.2)
                            : Colors.black.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(daySize * 0.04),
                      ),
                      child: Text(
                        _getShortHolidayName(holidayText!),
                        style: TextStyle(
                          fontSize: daySize * 0.20,
                          fontWeight: FontWeight.w600,
                          color: isNationalHoliday ? Colors.white : Colors.black,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Indicador de progresso
          if (hasData && isCurrentMonth && !isSelected && !isSpecialDay)
            Positioned(
              bottom: spacing * 0.5,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: daySize * 0.5, // Largura relativa
                  height: daySize * 0.06, // Altura relativa
                  decoration: BoxDecoration(
                    color: _getProgressColor(percentage).withValues(alpha:0.3),
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

          // Tooltip para mostrar o nome completo do feriado/data comemorativa
          if (holidayText != null && isCurrentMonth && (isNationalHoliday || isCommemorativeDate))
            Positioned.fill(
              child: Tooltip(
                message: holidayText!,
                waitDuration: const Duration(milliseconds: 500),
                textStyle: const TextStyle(fontSize: 12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Container(),
              ),
            ),
        ],
      ),
    );
  }

  double get spacing => daySize * 0.08; 


  String _getShortHolidayName(String fullName) {
    final shortNames = {
      'Ano Novo': 'Ano Novo',
      'Carnaval': 'Carnaval',
      'Sexta-feira Santa': 'Sexta Santa',
      'Tiradentes': 'Tiradentes',
      'Dia do Trabalho': 'Trabalho',
      'Corpus Christi': 'Corpus',
      'Independência do Brasil': 'Independência',
      'Nossa Senhora Aparecida': 'Aparecida',
      'Finados': 'Finados',
      'Proclamação da República': 'República',
      'Natal': 'Natal',
      'Dia dos Namorados': 'Namorados',
      'Dia Internacional da Mulher': 'Mulher',
      'Dia da Mentira': 'Mentira',
      'Descobrimento do Brasil': 'Descobrimento',
      'Dia das Mães': 'Mães',
      'Dia dos Pais': 'Pais',
      'Halloween': 'Halloween',
      'Réveillon': 'Réveillon',
    };
    
    return shortNames[fullName] ?? fullName;
  }

  Color _getProgressColor(int percentage) {
    if (percentage >= 100) return AppTheme.successColor;
    if (percentage >= 50) return AppTheme.warningColor;
    return AppTheme.dangerColor;
  }
}