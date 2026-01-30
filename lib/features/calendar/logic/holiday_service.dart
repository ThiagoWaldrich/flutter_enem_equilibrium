// calendar/logic/holiday_service.dart
import 'package:intl/intl.dart';

class HolidayService {
  static const Map<String, String> holidays2026 = {
    '01-01': 'Ano Novo',
    '02-16': 'Carnaval',
    '02-17': 'Carnaval',
    '04-03': 'Sexta-feira Santa',
    '04-21': 'Tiradentes',
    '05-01': 'Dia do Trabalho',
    '06-04': 'Corpus Christi',
    '09-07': 'Independência do Brasil',
    '10-12': 'Nossa Senhora Aparecida',
    '11-02': 'Finados',
    '11-15': 'Proclamação da República',
    '12-25': 'Natal',
    // Datas comemorativas
    '02-14': 'Dia dos Namorados',
    '03-08': 'Dia Internacional da Mulher',
    '04-01': 'Dia da Mentira',
    '04-22': 'Descobrimento do Brasil',
    '05-10': 'Dia das Mães',
    '08-09': 'Dia dos Pais',
    '10-31': 'Halloween',
    '12-31': 'Réveillon',
  };

  static const nationalHolidays = {
    '01-01', '04-03', '04-21', '05-01', '06-04',
    '09-07', '10-12', '11-02', '11-15', '12-25',
    '02-16', '02-17',
  };

  static bool isNationalHoliday(DateTime date) {
    final dateStr = DateFormat('MM-dd').format(date);
    final holidayText = holidays2026[dateStr];
    return holidayText != null && nationalHolidays.contains(dateStr);
  }

  static bool isCommemorativeDate(DateTime date) {
    final dateStr = DateFormat('MM-dd').format(date);
    final holidayText = holidays2026[dateStr];
    return holidayText != null && !isNationalHoliday(date);
  }

  static String? getHolidayText(DateTime date) {
    final dateStr = DateFormat('MM-dd').format(date);
    return holidays2026[dateStr];
  }

  static String getShortHolidayName(String fullName) {
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
}