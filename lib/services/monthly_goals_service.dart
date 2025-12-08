import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'storage_service.dart';
import 'database_service.dart';
import '../utils/constants.dart';

class MonthlyGoalsService extends ChangeNotifier {
  final StorageService _storageService;
  final DatabaseService _databaseService;
  
  Map<String, dynamic>? _currentMonthGoals;
  
  MonthlyGoalsService(this._storageService, this._databaseService) {
    _loadCurrentMonthGoals();
  }
  
  Map<String, dynamic>? get currentMonthGoals => _currentMonthGoals;
  
  Future<void> _loadCurrentMonthGoals() async {
    final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
    final goalsKey = '${AppConstants.keyMonthlyGoals}_$currentMonth';
    
    _currentMonthGoals = _storageService.getData(goalsKey);
    notifyListeners();
  }
  
  Future<void> generateGoals({
    required double hoursPerDay,
    required bool includeSaturday,
    required bool includeSunday,
    required bool useAutodiagnostico,
    required Map<String, int> weights,
  }) async {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    
    // Calcular dias de estudo
    int studyDays = 0;
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(now.year, now.month, day);
      final weekday = date.weekday;
      
      if (weekday == 6 && !includeSaturday) continue;
      if (weekday == 7 && !includeSunday) continue;
      
      studyDays++;
    }
    
    final totalHours = hoursPerDay * studyDays;
    
    Map<String, double> subjectHours;
    
    if (useAutodiagnostico) {
      subjectHours = await _distributeByAutodiagnostico(totalHours);
    } else {
      subjectHours = _distributeByWeights(totalHours, weights);
    }
    
    // Salvar metas
    final currentMonth = DateFormat('yyyy-MM').format(now);
    final goalsKey = '${AppConstants.keyMonthlyGoals}_$currentMonth';
    
    final goalsData = {
      'config': {
        'hoursPerDay': hoursPerDay,
        'includeSaturday': includeSaturday,
        'includeSunday': includeSunday,
        'totalHours': totalHours,
        'studyDays': studyDays,
        'weights': weights,
        'useAutodiagnostico': useAutodiagnostico,
      },
      'subjects': subjectHours,
      'generatedAt': DateTime.now().toIso8601String(),
    };
    
    await _storageService.saveData(goalsKey, goalsData);
    await _loadCurrentMonthGoals();
  }
  
  Map<String, double> _distributeByWeights(
    double totalHours,
    Map<String, int> weights,
  ) {
    final areas = {
      'linguagens': ['Português', 'Literatura', 'Artes', 'Inglês', 'Espanhol'],
      'matematica': ['Matemática'],
      'natureza': ['Física', 'Química', 'Biologia'],
      'humanas': ['História', 'Geografia', 'Filosofia', 'Sociologia'],
    };
    
    final totalWeight = weights.values.reduce((a, b) => a + b);
    if (totalWeight == 0) return {};
    
    final subjectHours = <String, double>{};
    
    for (final entry in areas.entries) {
      final areaWeight = weights[entry.key] ?? 0;
      if (areaWeight == 0) continue;
      
      final areaHours = (totalHours * areaWeight / totalWeight);
      final subjectsInArea = entry.value.length;
      final hoursPerSubject = areaHours / subjectsInArea;
      
      for (final subject in entry.value) {
        subjectHours[subject] = hoursPerSubject;
      }
    }
    
    return subjectHours;
  }
  
  Future<Map<String, double>> _distributeByAutodiagnostico(
    double totalHours,
  ) async {
    // Buscar estatísticas do banco de dados
    final stats = await _databaseService.getSubjectStats();
    
    if (stats.isEmpty) {
      // Se não tem dados, usar distribuição padrão
      return _distributeByWeights(totalHours, {
        'linguagens': 2,
        'matematica': 3,
        'natureza': 3,
        'humanas': 2,
      });
    }
    
    final areas = {
      'linguagens': ['Português', 'Literatura', 'Artes', 'Inglês', 'Espanhol'],
      'matematica': ['Matemática'],
      'natureza': ['Física', 'Química', 'Biologia'],
      'humanas': ['História', 'Geografia', 'Filosofia', 'Sociologia'],
    };
    
    // Calcular erros por área
    final areaErrors = <String, int>{};
    for (final entry in areas.entries) {
      int errors = 0;
      for (final subject in entry.value) {
        errors += stats[subject] ?? 0;
      }
      areaErrors[entry.key] = errors;
    }
    
    final totalErrors = areaErrors.values.reduce((a, b) => a + b);
    if (totalErrors == 0) {
      return _distributeByWeights(totalHours, {
        'linguagens': 2,
        'matematica': 3,
        'natureza': 3,
        'humanas': 2,
      });
    }
    
    final subjectHours = <String, double>{};
    
    for (final entry in areas.entries) {
      final areaWeight = areaErrors[entry.key]!;
      if (areaWeight == 0) continue;
      
      final areaHours = (totalHours * areaWeight / totalErrors);
      
      final subjectsInArea = entry.value;
      final subjectStats = <String, int>{};
      int areaTotal = 0;
      
      for (final subject in subjectsInArea) {
        final count = stats[subject] ?? 0;
        subjectStats[subject] = count;
        areaTotal += count;
      }
      
      if (areaTotal == 0) {
        for (final subject in subjectsInArea) {
          subjectHours[subject] = areaHours / subjectsInArea.length;
        }
      } else {
        for (final subject in subjectsInArea) {
          final proportion = subjectStats[subject]! / areaTotal;
          subjectHours[subject] = areaHours * proportion;
        }
      }
    }
    
    return subjectHours;
  }
  
  Future<void> deleteCurrentMonthGoals() async {
    final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
    final goalsKey = '${AppConstants.keyMonthlyGoals}_$currentMonth';
    
    await _storageService.removeData(goalsKey);
    await _loadCurrentMonthGoals();
  }
  
  double getSubjectGoal(String subject) {
    if (_currentMonthGoals == null) return 0;
    
    final subjects = _currentMonthGoals!['subjects'] as Map<String, dynamic>?;
    if (subjects == null) return 0;
    
    final hours = subjects[subject];
    if (hours is num) return hours.toDouble();
    
    return 0;
  }
  
  Map<String, double> getAllSubjectGoals() {
    if (_currentMonthGoals == null) return {};
    
    final subjects = _currentMonthGoals!['subjects'] as Map<String, dynamic>?;
    if (subjects == null) return {};
    
    return subjects.map((key, value) {
      return MapEntry(key, (value as num).toDouble());
    });
  }
  
  bool hasGoalsForCurrentMonth() {
    return _currentMonthGoals != null;
  }
  
  // Recarregar dados (útil após mudanças)
  Future<void> reload() async {
    await _loadCurrentMonthGoals();
  }
}