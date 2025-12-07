class AppConstants {
  // Matérias pré-definidas
  static const List<Map<String, dynamic>> predefinedSubjects = [
    {'name': 'Matemática', 'sessions': 4},
    {'name': 'Física', 'sessions': 4},
    {'name': 'Química', 'sessions': 3},
    {'name': 'Biologia', 'sessions': 2},
    {'name': 'História', 'sessions': 1},
    {'name': 'Geografia', 'sessions': 1},
    {'name': 'Sociologia', 'sessions': 1},
    {'name': 'Filosofia', 'sessions': 1},
    {'name': 'Português', 'sessions': 1},
    {'name': 'Literatura', 'sessions': 2},
    {'name': 'Redação', 'sessions': 3},
    {'name': 'Artes', 'sessions': 1},
    {'name': 'Simulado', 'sessions': 1},
  ];

  // Metas mensais de horas por matéria
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

  // Feriados nacionais do Brasil para 2026
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
    '05-12': 'Dia das Mães',
    '06-12': 'Dia dos Namorados (Brasil)',
    '08-11': 'Dia dos Pais',
    '10-31': 'Halloween',
    '12-31': 'Réveillon',
  };

  // Storage Keys
  static const String keyDaysData = 'calendar_daysData';
  static const String keyGoals = 'calendar_goals';
  static const String keyReview = 'calendar_review';
  static const String keyMindMaps = 'mind_maps';
}