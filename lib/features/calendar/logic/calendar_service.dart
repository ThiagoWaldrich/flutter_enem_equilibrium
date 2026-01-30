import 'package:flutter/foundation.dart';
import '../widgets/day_data.dart';
import '../../subjects/models/subject.dart';
import '../../goals/models/monthly_goal.dart';
import '../../core/theme/constants.dart';
import '../../core/services/storage_service.dart';
import 'package:intl/intl.dart';
import '../logic/date_calculator_service.dart';

class CalendarService extends ChangeNotifier {
  final StorageService _storageService;
  Map<String, DayData> _daysData = {};
  final Map<String, MonthlyGoal> _monthlyGoals = {};

  CalendarService(this._storageService) {
    _loadData();
    _initializeMonthlyGoals();
  }

  Future<void> _loadData() async {
    final data = _storageService.getData(AppConstants.keyDaysData);
    if (data != null && data is Map) {
      _daysData = data.map(
        (key, value) => MapEntry(
          key as String,
          DayData.fromJson(value as Map<String, dynamic>),
        ),
      );
      notifyListeners();
    }
  }

  void _initializeMonthlyGoals() {
    AppConstants.monthlyGoalTargets.forEach((subject, target) {
      _monthlyGoals[subject] = MonthlyGoal(
        subject: subject,
        target: target,
        current: 0,
      );
    });
  }

  Future<void> _saveData() async {
    final data = _daysData.map(
      (key, value) => MapEntry(key, value.toJson()),
    );
    await _storageService.saveData(AppConstants.keyDaysData, data);
  }

  DayData? getDayData(String dateStr) {
    return _daysData[dateStr];
  }

  // ✅ MODIFICADO: Retorna lista VAZIA se não há matérias customizadas
  List<Subject> getDaySubjects(String dateStr) {
    final dayData = _daysData[dateStr];
    
    // SE tem matérias customizadas, retorna elas
    if (dayData?.customSubjects != null) {
      return dayData!.customSubjects!;
    }

    // ✅ SENÃO, retorna lista VAZIA (não as pré-definidas)
    return [];
  }

  Future<void> saveDayData(String dateStr, DayData dayData) async {
    _daysData[dateStr] = dayData;
    await _saveData();
    notifyListeners();
  }

  // Atualizar humor
  Future<void> updateMood(String dateStr, int mood) async {
    final dayData = _daysData[dateStr] ?? DayData(date: dateStr);
    _daysData[dateStr] = dayData.copyWith(mood: mood);
    await _saveData();
    notifyListeners();
  }

  // Atualizar energia
  Future<void> updateEnergy(String dateStr, int energy) async {
    final dayData = _daysData[dateStr] ?? DayData(date: dateStr);
    _daysData[dateStr] = dayData.copyWith(energy: energy);
    await _saveData();
    notifyListeners();
  }

  // Atualizar notas
  Future<void> updateNotes(String dateStr, String notes) async {
    final dayData = _daysData[dateStr] ?? DayData(date: dateStr);
    _daysData[dateStr] = dayData.copyWith(notes: notes);
    await _saveData();
    notifyListeners();
  }

  // Alternar sessão de estudo
  Future<void> toggleStudySession(
    String dateStr,
    String subjectId,
    int session,
  ) async {
    final dayData = _daysData[dateStr] ?? DayData(date: dateStr);
    final progress =
        Map<String, List<StudySession>>.from(dayData.studyProgress);

    if (!progress.containsKey(subjectId)) {
      progress[subjectId] = [];
    }

    final subjectProgress = List<StudySession>.from(progress[subjectId]!);
    final existingIndex =
        subjectProgress.indexWhere((s) => s.sessionNumber == session);

    if (existingIndex != -1) {
      subjectProgress.removeAt(existingIndex);
    } else {
      subjectProgress.add(StudySession(session));
      subjectProgress
          .sort((a, b) => a.sessionNumber.compareTo(b.sessionNumber));
    }

    progress[subjectId] = subjectProgress;

    _daysData[dateStr] = dayData.copyWith(studyProgress: progress);
    await _saveData();

    await updateMonthlyGoals(dateStr);
    notifyListeners();
  }

  Future<void> updateQuestionCount(
    String dateStr,
    String subjectId,
    int session,
    int questionCount,
  ) async {
    final dayData = _daysData[dateStr];
    if (dayData == null) return;

    final progress =
        Map<String, List<StudySession>>.from(dayData.studyProgress);

    final subjectProgress = List<StudySession>.from(progress[subjectId] ?? []);

    final sessionIndex =
        subjectProgress.indexWhere((s) => s.sessionNumber == session);

    if (sessionIndex != -1) {
      subjectProgress[sessionIndex] = subjectProgress[sessionIndex].copyWith(
        questionCount: questionCount,
      );
    } else {
      subjectProgress.add(
        StudySession(session, questionCount: questionCount),
      );
      subjectProgress
          .sort((a, b) => a.sessionNumber.compareTo(b.sessionNumber));
    }

    progress[subjectId] = subjectProgress;

    _daysData[dateStr] = dayData.copyWith(studyProgress: progress);
    await _saveData();
    notifyListeners();
  }

  // ✅ Salvar matérias customizadas (ISSO SALVA NO STORAGE!)
  Future<void> saveCustomSubjects(
      String dateStr, List<Subject> subjects) async {
    final dayData = _daysData[dateStr] ?? DayData(date: dateStr);
    _daysData[dateStr] = dayData.copyWith(
      customSubjects: subjects,
      // ❗ NÃO LIMPA O studyProgress - mantém as sessões completadas
      // studyProgress: {}, ← REMOVA ESTA LINHA
    );
    await _saveData();
    notifyListeners();
  }

  Future<void> updateMonthlyGoals(String dateStr) async {
    try {
      final date = DateCalculator.parseDate(dateStr);
      final year = date.year;
      final month = date.month;

      // Resetar metas
      _monthlyGoals.updateAll((_, goal) => goal.copyWith(current: 0));

      // Último dia do mês
      final lastDay = DateTime(year, month + 1, 0).day;

      for (int day = 1; day <= lastDay; day++) {
        final ds =
            '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
        final dayData = _daysData[ds];

        if (dayData != null) {
          final subjects = getDaySubjects(ds);

          for (final subject in subjects) {
            final progress = dayData.studyProgress[subject.id] ?? [];
            final hoursStudied = progress.length;

            if (_monthlyGoals.containsKey(subject.name)) {
              final goal = _monthlyGoals[subject.name]!;
              _monthlyGoals[subject.name] = goal.copyWith(
                current: goal.current + hoursStudied,
              );
            }
          }
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erro em updateMonthlyGoals: $e');
    }
  }

  // Obter questões mensais por matéria
  Map<String, int> getMonthlyQuestions(String monthStr) {
    final date = DateCalculator.parseDate(monthStr);
    final year = date.year;
    final month = date.month;
    final lastDay = DateTime(year, month + 1, 0).day;

    final monthlyQuestions = <String, int>{};

    for (int day = 1; day <= lastDay; day++) {
      final dateStr =
          '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      final dayData = _daysData[dateStr];

      if (dayData != null) {
        final subjects = getDaySubjects(dateStr);
        for (final subject in subjects) {
          final sessions = dayData.studyProgress[subject.id] ?? [];
          final totalQuestions =
              sessions.fold(0, (sum, session) => sum + session.questionCount);

          monthlyQuestions[subject.name] =
              (monthlyQuestions[subject.name] ?? 0) + totalQuestions;
        }
      }
    }

    return monthlyQuestions;
  }

  // Obter questões do mês atual
  Map<String, int> getCurrentMonthQuestions() {
    final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
    return getMonthlyQuestions(currentMonth);
  }

  // Obter total de questões do mês
  int getTotalMonthlyQuestions(String monthStr) {
    final questions = getMonthlyQuestions(monthStr);
    return questions.values.fold(0, (sum, count) => sum + count);
  }

  // Obter resumo mensal com questões
  Map<String, Map<String, dynamic>> getMonthlySummary(DateTime date) {
    final month = DateFormat('yyyy-MM').format(date);
    final days = DateCalculator.getAllDaysInMonth(date.year, date.month);
    final result = <String, Map<String, dynamic>>{};
    final subjectsSummary = <String, Map<String, dynamic>>{};

    for (final day in days) {
      final dateStr = DateFormat('yyyy-MM-dd').format(day);
      final dayData = getDayData(dateStr);

      if (dayData != null) {
        final daySubjects = getDaySubjects(dateStr);

        for (final subject in daySubjects) {
          final progress = dayData.studyProgress[subject.id] ?? [];
          final hoursStudied = progress.length;
          final questions =
              progress.fold(0, (sum, session) => sum + session.questionCount);

          if (!subjectsSummary.containsKey(subject.name)) {
            subjectsSummary[subject.name] = {
              'hours': 0.0,
              'questions': 0,
              'sessions': 0,
            };
          }

          subjectsSummary[subject.name]!['hours'] =
              subjectsSummary[subject.name]!['hours'] + hoursStudied;
          subjectsSummary[subject.name]!['questions'] =
              subjectsSummary[subject.name]!['questions'] + questions;
          subjectsSummary[subject.name]!['sessions'] =
              subjectsSummary[subject.name]!['sessions'] + progress.length;
        }
      }
    }

    result[month] = subjectsSummary;
    return result;
  }

  // Progresso diário
  Map<String, dynamic> getDayProgress(String dateStr) {
    final subjects = getDaySubjects(dateStr);
    final dayData = _daysData[dateStr];

    int completed = 0;
    int total = 0;
    int totalQuestions = 0;

    for (final s in subjects) {
      total += s.sessions;
      final sessions = dayData?.studyProgress[s.id] ?? [];
      completed += sessions.length;
      totalQuestions +=
          sessions.fold(0, (sum, session) => sum + session.questionCount);
    }

    return {
      'completed': completed,
      'total': total,
      'questions': totalQuestions,
      'percentage': total == 0 ? 0 : ((completed / total) * 100).round(),
    };
  }

  Map<String, MonthlyGoal> get monthlyGoals => _monthlyGoals;

  // ✅ NOVO MÉTODO: Obter matérias padrão (para o ManageSubjectsScreen)
  List<Subject> getDefaultSubjects() {
    return AppConstants.predefinedSubjects
        .asMap()
        .entries
        .map(
          (entry) => Subject(
            id: (entry.key + 1).toString(),
            name: entry.value['name'] as String,
            sessions: entry.value['sessions'] as int,
          ),
        )
        .toList();
  }

  // Métodos de formatação
  String formatMonth(DateTime date) => DateCalculator.formatMonth(date);
  String formatDay(DateTime date) => DateCalculator.formatDay(date);
}