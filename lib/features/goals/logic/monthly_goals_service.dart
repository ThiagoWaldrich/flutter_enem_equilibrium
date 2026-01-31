import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/database_service.dart';
import '../../core/theme/constants.dart';
import 'package:flutter/widgets.dart';

class MonthlyGoalsService extends ChangeNotifier {
  final StorageService _storageService;
  final DatabaseService _databaseService;
  
  Map<String, dynamic>? _currentMonthGoals;
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  

  String? _cachedMonth;
  
  MonthlyGoalsService(this._storageService, this._databaseService) {
    _initializeGoals();
  }
  
  Map<String, dynamic>? get currentMonthGoals => _currentMonthGoals;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  
  void _initializeGoals() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _safeLoadCurrentMonthGoals();
    });
  }
  
  Future<void> _safeLoadCurrentMonthGoals() async {
    if (_isLoading) return;
    
    final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
  
    if (_cachedMonth == currentMonth && _currentMonthGoals != null) {
      return;
    }
    
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await _loadCurrentMonthGoals();
      _cachedMonth = currentMonth;
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Erro ao carregar metas: $e';
      if (kDebugMode) {
        print('Erro em _loadCurrentMonthGoals: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> _loadCurrentMonthGoals() async {
    final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
    final goalsKey = '${AppConstants.keyMonthlyGoals}_$currentMonth';
    
    final goals = _storageService.getData(goalsKey);
    
    if (!mapEquals(_currentMonthGoals, goals)) {
      _currentMonthGoals = goals;
    }
  }
  
  Future<void> generateGoals({
    required double hoursPerDay,
    required bool includeSaturday,
    required bool includeSunday,
    required bool useAutodiagnostico,
    required Map<String, int> weights,
  }) async {
    if (_isLoading) return;
    
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final now = DateTime.now();
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      
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
        'questions': {},
        'generatedAt': DateTime.now().toIso8601String(),
      };
      
      await _storageService.saveData(goalsKey, goalsData);
      _cachedMonth = currentMonth; 
      await _loadCurrentMonthGoals();
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Erro ao gerar metas: $e';
      if (kDebugMode) {
        print('Erro em generateGoals: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Map<String, double> _distributeByWeights(
    double totalHours,
    Map<String, int> weights,
  ) {
    final areas = {
      'linguagens': ['Língua Portuguesa', 'Literatura', 'Artes', 'Inglês', 'Espanhol'],
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
    try {
      final stats = await _databaseService.getSubjectStats();
      
      if (stats.isEmpty) {
        return _distributeByWeights(totalHours, {
          'linguagens': 2,
          'matematica': 3,
          'natureza': 3,
          'humanas': 2,
        });
      }
      
      final areas = {
        'linguagens': ['Língua Portuguesa', 'Literatura', 'Artes', 'Inglês', 'Espanhol'],
        'matematica': ['Matemática'],
        'natureza': ['Física', 'Química', 'Biologia'],
        'humanas': ['História', 'Geografia', 'Filosofia', 'Sociologia'],
      };
      
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
          final hoursPerSubject = areaHours / subjectsInArea.length;
          for (final subject in subjectsInArea) {
            subjectHours[subject] = hoursPerSubject;
          }
        } else {
          for (final subject in subjectsInArea) {
            final proportion = subjectStats[subject]! / areaTotal;
            subjectHours[subject] = areaHours * proportion;
          }
        }
      }
      
      return subjectHours;
    } catch (e) {
      if (kDebugMode) {
        print('Erro em _distributeByAutodiagnostico: $e');
      }
      return _distributeByWeights(totalHours, {
        'linguagens': 2,
        'matematica': 3,
        'natureza': 3,
        'humanas': 2,
      });
    }
  }
  
  Future<void> updateSubjectQuestions(String subject, int questions) async {
    if (_currentMonthGoals == null) return;
    
    final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
    final goalsKey = '${AppConstants.keyMonthlyGoals}_$currentMonth';
    
    final questionsData = Map<String, dynamic>.from(_currentMonthGoals!['questions'] ?? {});
    final oldValue = questionsData[subject] ?? 0;
    final newValue = oldValue + questions;
    if (oldValue == newValue) return;
    
    questionsData[subject] = newValue;
    _currentMonthGoals!['questions'] = questionsData;
    
    await _storageService.saveData(goalsKey, _currentMonthGoals);
    notifyListeners();
  }
  
  int getSubjectQuestions(String subject) {
    if (_currentMonthGoals == null) return 0;
    
    final questions = _currentMonthGoals!['questions'] as Map<String, dynamic>?;
    if (questions == null || !questions.containsKey(subject)) return 0;
    
    return (questions[subject] as int?) ?? 0;
  }

  Map<String, int> getAllSubjectQuestions() {
    if (_currentMonthGoals == null) return {};
    
    final questions = _currentMonthGoals!['questions'] as Map<String, dynamic>?;
    if (questions == null) return {};
    
    return questions.map((key, value) => MapEntry(key, (value as int)));
  }

 
  Future<void> syncWithCalendar(Map<String, int> calendarQuestions) async {
    if (_currentMonthGoals == null) return;
    
 
    final currentQuestions = _currentMonthGoals!['questions'] as Map<String, dynamic>?;
    if (mapEquals(currentQuestions, calendarQuestions)) {
      return; 
    }
    
    final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
    final goalsKey = '${AppConstants.keyMonthlyGoals}_$currentMonth';
    
    _currentMonthGoals!['questions'] = calendarQuestions;
    
    await _storageService.saveData(goalsKey, _currentMonthGoals);
    notifyListeners();
  }
  
  Future<void> deleteCurrentMonthGoals() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
      final goalsKey = '${AppConstants.keyMonthlyGoals}_$currentMonth';
      
      await _storageService.removeData(goalsKey);
      _cachedMonth = null;
      await _loadCurrentMonthGoals();
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Erro ao excluir metas: $e';
      if (kDebugMode) {
        print('Erro em deleteCurrentMonthGoals: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
  
  Future<void> reload() async {
    _cachedMonth = null; 
    await _safeLoadCurrentMonthGoals();
  }
  
}