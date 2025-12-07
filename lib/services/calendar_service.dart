import 'package:flutter/foundation.dart';
import '../models/day_data.dart';
import '../models/subject.dart';
import '../models/monthly_goal.dart';
import '../utils/constants.dart';
import 'storage_service.dart';

class CalendarService extends ChangeNotifier {
  final StorageService _storageService;
  Map<String, DayData> _daysData = {};
  Map<String, MonthlyGoal> _monthlyGoals = {};

  CalendarService(this._storageService) {
    _loadData();
    _initializeMonthlyGoals();
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
    
    // Retornar matérias padrão
    return AppConstants.predefinedSubjects
        .asMap()
        .entries
        .map((entry) => Subject(
              id: (entry.key + 1).toString(),
              name: entry.value['name'] as String,
              sessions: entry.value['sessions'] as int,
            ))
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
      studyProgress: {}, // Limpar progresso ao alterar matérias
    );
    await _saveData();
    notifyListeners();
  }

  // Atualizar metas mensais
  Future<void> updateMonthlyGoals(String dateStr) async {
    final date = DateTime.parse(dateStr);
    final month = date.month;
    final year = date.year;
    
    // Resetar contadores
    _monthlyGoals.forEach((key, goal) {
      _monthlyGoals[key] = goal.copyWith(current: 0);
    });
    
    // Calcular dias no mês
    final lastDay = DateTime(year, month + 1, 0).day;
    
    // Contar horas estudadas no mês
    for (int day = 1; day <= lastDay; day++) {
      final dayDateStr = '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      final dayData = _daysData[dayDateStr];
      
      if (dayData?.studyProgress != null) {
        final subjects = getDaySubjects(dayDateStr);
        
        for (final subject in subjects) {
          final progress = dayData!.studyProgress[subject.id] ?? [];
          final hoursStudied = progress.length;
          
          if (_monthlyGoals.containsKey(subject.name)) {
            final currentGoal = _monthlyGoals[subject.name]!;
            _monthlyGoals[subject.name] = currentGoal.copyWith(
              current: currentGoal.current + hoursStudied,
            );
          }
        }
      }
    }
    
    notifyListeners();
  }

  // Obter progresso total de um dia
  Map<String, int> getDayProgress(String dateStr) {
    final subjects = getDaySubjects(dateStr);
    final dayData = _daysData[dateStr];
    
    int completedSessions = 0;
    int totalSessions = 0;
    
    for (final subject in subjects) {
      totalSessions += subject.sessions;
      final progress = dayData?.studyProgress[subject.id] ?? [];
      completedSessions += progress.length;
    }
    
    return {
      'completed': completedSessions,
      'total': totalSessions,
      'percentage': totalSessions > 0
          ? ((completedSessions / totalSessions) * 100).round()
          : 0,
    };
  }

  // Obter metas mensais
  Map<String, MonthlyGoal> get monthlyGoals => _monthlyGoals;
}