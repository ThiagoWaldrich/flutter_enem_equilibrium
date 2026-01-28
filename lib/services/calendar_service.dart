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
  // Utilitário seguro de Data - CORRIGIDO
  // -------------------------
  DateTime _parseDate(String dateStr) {
    try {
      // Se já for uma data completa yyyy-MM-dd, usar parse normal
      if (dateStr.length == 10 && dateStr.contains('-')) {
        return DateTime.parse(dateStr);
      }
      
      // Se for apenas yyyy-MM (como "2025-12"), adicionar dia 01
      if (dateStr.length == 7 && dateStr.contains('-')) {
        return DateTime.parse('${dateStr}-01');
      }
      
      // Se não tiver o formato esperado, tentar parse normal
      return DateTime.parse(dateStr);
    } catch (e) {
      // Fallback: se der erro, criar data com dia 1
      try {
        final parts = dateStr.split('-');
        if (parts.length >= 2) {
          final year = int.tryParse(parts[0]) ?? DateTime.now().year;
          final month = int.tryParse(parts[1]) ?? DateTime.now().month;
          return DateTime(year, month, 1);
        }
      } catch (_) {
        // Último fallback
      }
      
      // Retorna data atual como fallback final
      return DateTime.now();
    }
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
    final progress = Map<String, List<StudySession>>.from(dayData.studyProgress);

    if (!progress.containsKey(subjectId)) {
      progress[subjectId] = [];
    }

    final subjectProgress = List<StudySession>.from(progress[subjectId]!);

    // Verificar se a sessão já existe
    final existingIndex = subjectProgress.indexWhere((s) => s.sessionNumber == session);
    
    if (existingIndex != -1) {
      // Remover sessão existente
      subjectProgress.removeAt(existingIndex);
    } else {
      // Adicionar nova sessão com 0 questões
      subjectProgress.add(StudySession(session));
      // Ordenar por número de sessão
      subjectProgress.sort((a, b) => a.sessionNumber.compareTo(b.sessionNumber));
    }

    progress[subjectId] = subjectProgress;

    _daysData[dateStr] = dayData.copyWith(studyProgress: progress);
    await _saveData();

    await updateMonthlyGoals(dateStr);
    notifyListeners();
  }

  // Atualizar contagem de questões para uma sessão
  Future<void> updateQuestionCount(
    String dateStr,
    String subjectId,
    int session,
    int questionCount,
  ) async {
    final dayData = _daysData[dateStr];
    if (dayData == null) return;

    final progress = Map<String, List<StudySession>>.from(dayData.studyProgress);
    if (!progress.containsKey(subjectId)) {
      // Se não houver sessão, criar uma
      progress[subjectId] = [StudySession(session, questionCount: questionCount)];
    } else {
      final subjectProgress = List<StudySession>.from(progress[subjectId]!);
      final sessionIndex = subjectProgress.indexWhere((s) => s.sessionNumber == session);
      
      if (sessionIndex != -1) {
        // Atualizar questão existente
        subjectProgress[sessionIndex].questionCount = questionCount;
      } else {
        // Adicionar nova sessão com questões
        subjectProgress.add(StudySession(session, questionCount: questionCount));
        subjectProgress.sort((a, b) => a.sessionNumber.compareTo(b.sessionNumber));
      }
      
      progress[subjectId] = subjectProgress;
    }

    _daysData[dateStr] = dayData.copyWith(studyProgress: progress);
    await _saveData();
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
    try {
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
    } catch (e) {
      print('❌ Erro em updateMonthlyGoals: $e');
    }
  }

  // -------------------------
  // QUESTÕES MENSAIS (NOVO)
  // -------------------------

  // Obter questões mensais por matéria
  Map<String, int> getMonthlyQuestions(String monthStr) {
    final date = _parseDate(monthStr);
    final year = date.year;
    final month = date.month;
    final lastDay = DateTime(year, month + 1, 0).day;

    final monthlyQuestions = <String, int>{};

    for (int day = 1; day <= lastDay; day++) {
      final dateStr = '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      final dayData = _daysData[dateStr];

      if (dayData != null) {
        // Para cada matéria do dia
        final subjects = getDaySubjects(dateStr);
        for (final subject in subjects) {
          final sessions = dayData.studyProgress[subject.id] ?? [];
          final totalQuestions = sessions.fold(0, (sum, session) => sum + session.questionCount);
          
          // Acumular por nome da matéria
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

  // Método auxiliar para obter todos os dias do mês
  List<DateTime> getAllDaysInMonth(int year, int month) {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    
    final days = <DateTime>[];
    for (var i = 0; i <= lastDay.difference(firstDay).inDays; i++) {
      days.add(firstDay.add(Duration(days: i)));
    }
    
    return days;
  }

  // Obter resumo mensal com questões
  Map<String, Map<String, dynamic>> getMonthlySummary(DateTime date) {
    final month = DateFormat('yyyy-MM').format(date);
    final days = getAllDaysInMonth(date.year, date.month);
    
    final result = <String, Map<String, dynamic>>{};
    final subjectsSummary = <String, Map<String, dynamic>>{};
    
    for (final day in days) {
      final dateStr = DateFormat('yyyy-MM-dd').format(day);
      final dayData = getDayData(dateStr);
      
      if (dayData != null) {
        // Obter as matérias deste dia específico
        final daySubjects = getDaySubjects(dateStr);
        
        for (final subject in daySubjects) {
          final progress = dayData.studyProgress[subject.id] ?? [];
          final hoursStudied = progress.length;
          final questions = progress.fold(0, (sum, session) => sum + session.questionCount);
          
          if (!subjectsSummary.containsKey(subject.name)) {
            subjectsSummary[subject.name] = {
              'hours': 0.0,
              'questions': 0,
              'sessions': 0,
            };
          }
          
          subjectsSummary[subject.name]!['hours'] = subjectsSummary[subject.name]!['hours'] + hoursStudied;
          subjectsSummary[subject.name]!['questions'] = subjectsSummary[subject.name]!['questions'] + questions;
          subjectsSummary[subject.name]!['sessions'] = subjectsSummary[subject.name]!['sessions'] + progress.length;
        }
      }
    }
    
    result[month] = subjectsSummary;
    return result;
  }

  // -------------------------
  // PROGRESSO DIÁRIO (ATUALIZADO)
  // -------------------------
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
      totalQuestions += sessions.fold(0, (sum, session) => sum + session.questionCount);
    }

    return {
      'completed': completed,
      'total': total,
      'questions': totalQuestions,
      'percentage': total == 0 ? 0 : ((completed / total) * 100).round(),
    };
  }

  Map<String, MonthlyGoal> get monthlyGoals => _monthlyGoals;
}