import 'package:flutter/foundation.dart';
import '../models/day_data.dart';
import '../models/subject.dart';
import '../models/monthly_goal.dart';
import '../utils/constants.dart';
import 'storage_service.dart';
import 'package:intl/intl.dart';

class CalendarService extends ChangeNotifier {
  final StorageService _storageService;
  Map<String, DayData> _daysData = {};
  Map<String, MonthlyGoal> _monthlyGoals = {};

  CalendarService(this._storageService) {
    _loadData();
    _initializeMonthlyGoals();
  }

  // -------------------------
  // Utilitário seguro de Data
  // -------------------------
  DateTime _parseDate(String dateStr) {
    // dateStr sempre vem no formato yyyy-MM-dd
    return DateTime.parse(dateStr);
  }

  // Carregar dados do armazenamento
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

  // Inicializar metas mensais
  void _initializeMonthlyGoals() {
    AppConstants.monthlyGoalTargets.forEach((subject, target) {
      _monthlyGoals[subject] = MonthlyGoal(
        subject: subject,
        target: target,
        current: 0,
      );
    });
  }

  // Salvar dados
  Future<void> _saveData() async {
    final data = _daysData.map(
      (key, value) => MapEntry(key, value.toJson()),
    );
    await _storageService.saveData(AppConstants.keyDaysData, data);
  }

  // Obter dados de um dia
  DayData? getDayData(String dateStr) {
    return _daysData[dateStr];
  }

  // Obter matérias de um dia
  List<Subject> getDaySubjects(String dateStr) {
    final dayData = _daysData[dateStr];
    if (dayData?.customSubjects != null) {
      return dayData!.customSubjects!;
    }

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

  // Salvar dados do dia
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
    final progress = Map<String, List<int>>.from(dayData.studyProgress);

    if (!progress.containsKey(subjectId)) {
      progress[subjectId] = [];
    }

    final subjectProgress = List<int>.from(progress[subjectId]!);

    if (subjectProgress.contains(session)) {
      subjectProgress.remove(session);
    } else {
      subjectProgress.add(session);
      subjectProgress.sort();
    }

    progress[subjectId] = subjectProgress;

    _daysData[dateStr] = dayData.copyWith(studyProgress: progress);
    await _saveData();

    await updateMonthlyGoals(dateStr);
    notifyListeners();
  }

  // Salvar matérias customizadas
  Future<void> saveCustomSubjects(String dateStr, List<Subject> subjects) async {
    final dayData = _daysData[dateStr] ?? DayData(date: dateStr);
    _daysData[dateStr] = dayData.copyWith(
      customSubjects: subjects,
      studyProgress: {},
    );
    await _saveData();
    notifyListeners();
  }

  // -------------------------
  // CÁLCULO DAS METAS MENSAIS
  // -------------------------
  Future<void> updateMonthlyGoals(String dateStr) async {
    final date = _parseDate(dateStr);
    final year = date.year;
    final month = date.month;

    final formattedMonth = DateFormat('yyyy-MM').format(date);

    // Resetar
    _monthlyGoals.updateAll((_, goal) => goal.copyWith(current: 0));

    // Último dia do mês
    final lastDay = DateTime(year, month + 1, 0).day;

    for (int day = 1; day <= lastDay; day++) {
      final ds = '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
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
  }

  // -------------------------
  // PROGRESSO DIÁRIO
  // -------------------------
  Map<String, int> getDayProgress(String dateStr) {
    final subjects = getDaySubjects(dateStr);
    final dayData = _daysData[dateStr];

    int completed = 0;
    int total = 0;

    for (final s in subjects) {
      total += s.sessions;
      completed += (dayData?.studyProgress[s.id] ?? []).length;
    }

    return {
      'completed': completed,
      'total': total,
      'percentage': total == 0 ? 0 : ((completed / total) * 100).round(),
    };
  }

  Map<String, MonthlyGoal> get monthlyGoals => _monthlyGoals;
}
