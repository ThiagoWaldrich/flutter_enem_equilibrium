import 'dart:ui';

class AppConstants {
  static const List<Map<String, dynamic>> predefinedSubjects = [
    {'name': 'Matemática', 'sessions': 1},
    {'name': 'Física', 'sessions': 1},
    {'name': 'Química', 'sessions': 1},
    {'name': 'Biologia', 'sessions': 1},
    {'name': 'História', 'sessions': 1},
    {'name': 'Geografia', 'sessions': 1},
    {'name': 'Sociologia', 'sessions': 1},
    {'name': 'Filosofia', 'sessions': 1},
    {'name': 'Português', 'sessions': 1},
    {'name': 'Literatura', 'sessions': 1},
    {'name': 'Redação', 'sessions': 1},
    {'name': 'Artes', 'sessions': 1},
  ];

  static const List<String> defaultTimeSlots = [
    '05:00', '06:00', '07:00', '08:00', '09:00', '10:00',
    '11:00', '12:00', '13:00', '14:00', '15:00', '16:00',
    '17:00', '18:00', '19:00', '20:00', '21:00', '22:00'
  ];

  static const List<String> weekDays = [
    'Domingo', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado'
  ];

  static const Map<String, int> monthlyGoalTargets = {
    'Literatura': 15,
    'Português': 8,
    'Artes': 8,
    'Matemática': 30,
    'Física': 26,
    'Química': 26,
    'Biologia': 23,
    'Filosofia': 8,
    'Sociologia': 7,
    'História': 7,
    'Geografia': 7,
    'Redação': 15,
  };


  static const String keyDaysData = 'calendar_daysData';
  static const String keyGoals = 'calendar_goals';
  static const String keyReview = 'calendar_review';
  static const String keyMindMaps = 'mind_maps';
  static const String keyMonthlyGoals = 'monthly_goals';

  static const Color holidayColor = Color(0xFFEF4444); 
  static const Color commemorativeDateColor = Color(0xFF4FC3F7); 
}