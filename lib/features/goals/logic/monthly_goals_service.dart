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
  Map<String, Map<String, dynamic>> _historicalGoals = {};
  List<String> _availableMonths = [];
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  String? _cachedMonth;
  String? _selectedLanguage;
  
  MonthlyGoalsService(this._storageService, this._databaseService) {
    _initializeGoals();
  }
  
  Map<String, dynamic>? get currentMonthGoals => _currentMonthGoals;
  Map<String, Map<String, dynamic>> get historicalGoals => _historicalGoals;
  List<String> get availableMonths => _availableMonths;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  String? get selectedLanguage => _selectedLanguage;
  
  void _initializeGoals() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _safeLoadCurrentMonthGoals();
    });
  }
  
  Future<void> _safeLoadCurrentMonthGoals() async {
    if (_isLoading) return;
    
    final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
  
    if (_cachedMonth == currentMonth && _currentMonthGoals != null) {
      _selectedLanguage = _currentMonthGoals?['config']?['selectedLanguage'];
      return;
    }
    
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await _loadAvailableMonths();
      await _loadCurrentMonthGoals();
      await _loadHistoricalGoals();
      _cachedMonth = currentMonth;
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Erro ao carregar metas: $e';
      if (kDebugMode) {
        print('Erro em _safeLoadCurrentMonthGoals: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> _loadAvailableMonths() async {
    try {
      final monthsKey = '${AppConstants.keyMonthlyGoals}_available_months';
      final savedMonths = _storageService.getData(monthsKey) as List<dynamic>?;
      
      if (savedMonths != null) {
        _availableMonths = savedMonths.map((m) => m.toString()).toList();
      } else {
        _availableMonths = [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao carregar meses disponíveis: $e');
      }
      _availableMonths = [];
    }
  }
  
  Future<void> _saveAvailableMonths() async {
    try {
      final monthsKey = '${AppConstants.keyMonthlyGoals}_available_months';
      await _storageService.saveData(monthsKey, _availableMonths);
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao salvar meses disponíveis: $e');
      }
    }
  }
  
  Future<void> _addMonthToAvailable(String month) async {
    if (!_availableMonths.contains(month)) {
      _availableMonths.add(month);
      _availableMonths.sort((a, b) => b.compareTo(a)); // Ordena do mais recente para o mais antigo
      await _saveAvailableMonths();
    }
  }
  
  Future<void> _removeMonthFromAvailable(String month) async {
    if (_availableMonths.contains(month)) {
      _availableMonths.remove(month);
      await _saveAvailableMonths();
    }
  }
  
  Future<void> _loadCurrentMonthGoals() async {
    final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
    final goalsKey = '${AppConstants.keyMonthlyGoals}_$currentMonth';
    
    final goals = _storageService.getData(goalsKey);
    
    if (!mapEquals(_currentMonthGoals, goals)) {
      _currentMonthGoals = goals;
      _selectedLanguage = goals?['config']?['selectedLanguage'];
    }
  }
  
  Future<void> _loadHistoricalGoals() async {
    try {
      _historicalGoals = {};
      
      // Carrega apenas os meses históricos (excluindo o atual)
      final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
      
      for (final month in _availableMonths) {
        if (month != currentMonth) {
          final goalsKey = '${AppConstants.keyMonthlyGoals}_$month';
          final goals = _storageService.getData(goalsKey);
          
          if (goals != null) {
            _historicalGoals[month] = goals;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao carregar metas históricas: $e');
      }
    }
  }
  
  Future<Map<String, dynamic>?> getGoalsForMonth(String month) async {
    if (month == DateFormat('yyyy-MM').format(DateTime.now())) {
      return _currentMonthGoals;
    }
    
    // Verifica no cache primeiro
    if (_historicalGoals.containsKey(month)) {
      return _historicalGoals[month];
    }
    
    // Carrega do storage
    final goalsKey = '${AppConstants.keyMonthlyGoals}_$month';
    final goals = _storageService.getData(goalsKey);
    
    if (goals != null) {
      _historicalGoals[month] = goals;
    }
    
    return goals;
  }
  
  Future<List<String>> getAvailableMonths() async {
    // Retorna uma cópia da lista ordenada
    return List.from(_availableMonths);
  }
  
  Future<List<Map<String, dynamic>>> getMonthlySummaries() async {
    final summaries = <Map<String, dynamic>>[];
    
    for (final month in _availableMonths) {
      final goals = await getGoalsForMonth(month);
      if (goals != null) {
        final progress = calculateProgressForMonth(goals);
        summaries.add(progress);
      }
    }
    
    return summaries;
  }
  
  Future<void> generateGoals({
    required double hoursPerDay,
    required bool includeSaturday,
    required bool includeSunday,
    required bool useAutodiagnostico,
    required Map<String, int> weights,
    required String selectedLanguage,
  }) async {
    if (_isLoading) return;
    
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    _selectedLanguage = selectedLanguage;
    notifyListeners();
    
    try {
      final now = DateTime.now();
      final currentMonth = DateFormat('yyyy-MM').format(now);
      
      // Verifica se já existem metas para o mês atual
      final existingGoals = _storageService.getData('${AppConstants.keyMonthlyGoals}_$currentMonth');
      final existingQuestions = existingGoals?['questions'] ?? {};
      final existingProgress = existingGoals?['progress'] ?? {};
      
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
      
      final goalsKey = '${AppConstants.keyMonthlyGoals}_$currentMonth';
      
      final goalsData = {
        'month': currentMonth,
        'monthName': _getMonthName(now),
        'config': {
          'hoursPerDay': hoursPerDay,
          'includeSaturday': includeSaturday,
          'includeSunday': includeSunday,
          'totalHours': totalHours,
          'studyDays': studyDays,
          'weights': weights,
          'useAutodiagnostico': useAutodiagnostico,
          'selectedLanguage': selectedLanguage,
        },
        'subjects': subjectHours,
        'questions': existingQuestions,
        'progress': existingProgress,
        'generatedAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      await _storageService.saveData(goalsKey, goalsData);
      
      // Adiciona o mês à lista de meses disponíveis
      await _addMonthToAvailable(currentMonth);
      
      _cachedMonth = currentMonth;
      
      // Atualiza o cache
      await _loadCurrentMonthGoals();
      await _loadHistoricalGoals();
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
  
  String _getMonthName(DateTime date) {
    final monthNames = {
      1: 'Janeiro',
      2: 'Fevereiro',
      3: 'Março',
      4: 'Abril',
      5: 'Maio',
      6: 'Junho',
      7: 'Julho',
      8: 'Agosto',
      9: 'Setembro',
      10: 'Outubro',
      11: 'Novembro',
      12: 'Dezembro',
    };
    
    return '${monthNames[date.month]} ${date.year}';
  }
  
  Map<String, double> _distributeByWeights(
    double totalHours,
    Map<String, int> weights,
  ) {
    final languageSubjects = _selectedLanguage == 'english' 
        ? ['Inglês']
        : ['Espanhol'];
    
    final areas = {
      'linguagens': ['Língua Portuguesa', 'Literatura', 'Artes', ...languageSubjects],
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
      
      final languageSubjects = _selectedLanguage == 'english' 
          ? ['Inglês']
          : ['Espanhol'];
      
      final areas = {
        'linguagens': ['Língua Portuguesa', 'Literatura', 'Artes', ...languageSubjects],
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
    _currentMonthGoals!['updatedAt'] = DateTime.now().toIso8601String();
    
    await _storageService.saveData(goalsKey, _currentMonthGoals);
    notifyListeners();
  }
  
  Future<void> updateSubjectProgress(String subject, Map<String, dynamic> progress) async {
    if (_currentMonthGoals == null) return;
    
    final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
    final goalsKey = '${AppConstants.keyMonthlyGoals}_$currentMonth';
    
    final progressData = Map<String, dynamic>.from(_currentMonthGoals!['progress'] ?? {});
    progressData[subject] = progress;
    
    _currentMonthGoals!['progress'] = progressData;
    _currentMonthGoals!['updatedAt'] = DateTime.now().toIso8601String();
    
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
    _currentMonthGoals!['updatedAt'] = DateTime.now().toIso8601String();
    
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
      await _removeMonthFromAvailable(currentMonth);
      
      _cachedMonth = null;
      _currentMonthGoals = null;
      
      await _loadHistoricalGoals();
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
  
  Future<void> deleteGoalsForMonth(String month) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final goalsKey = '${AppConstants.keyMonthlyGoals}_$month';
      
      await _storageService.removeData(goalsKey);
      await _removeMonthFromAvailable(month);
      
      // Remove do cache
      if (_historicalGoals.containsKey(month)) {
        _historicalGoals.remove(month);
      }
      
      // Se for o mês atual, limpa o cache
      if (month == DateFormat('yyyy-MM').format(DateTime.now())) {
        _currentMonthGoals = null;
        _cachedMonth = null;
      }
      
      notifyListeners();
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Erro ao excluir metas do mês $month: $e';
      if (kDebugMode) {
        print('Erro em deleteGoalsForMonth: $e');
      }
      rethrow;
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
  
  bool hasGoalsForMonth(String month) {
    if (month == DateFormat('yyyy-MM').format(DateTime.now())) {
      return _currentMonthGoals != null;
    }
    return _availableMonths.contains(month);
  }
  
  Future<void> reload() async {
    _cachedMonth = null;
    _historicalGoals.clear();
    await _safeLoadCurrentMonthGoals();
  }
  
  // Método para buscar metas antigas que não estão na lista
  Future<void> searchForOldGoals() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Verifica os últimos 24 meses
      final now = DateTime.now();
      for (int i = 0; i < 24; i++) {
        final date = DateTime(now.year, now.month - i, 1);
        final month = DateFormat('yyyy-MM').format(date);
        final goalsKey = '${AppConstants.keyMonthlyGoals}_$month';
        final goals = _storageService.getData(goalsKey);
        
        if (goals != null && !_availableMonths.contains(month)) {
          await _addMonthToAvailable(month);
          _historicalGoals[month] = goals;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro em searchForOldGoals: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Método para calcular o progresso de um mês específico
  Map<String, dynamic> calculateProgressForMonth(Map<String, dynamic> goals) {
    if (goals == null || goals.isEmpty) return {};
    
    final subjects = goals['subjects'] as Map<String, dynamic>? ?? {};
    final questions = goals['questions'] as Map<String, dynamic>? ?? {};
    final config = goals['config'] as Map<String, dynamic>? ?? {};
    final storedProgress = goals['progress'] as Map<String, dynamic>? ?? {};
    
    final progress = <String, Map<String, dynamic>>{};
    double totalGoalHours = 0;
    int totalQuestions = 0;
    
    for (final subject in subjects.keys) {
      final goalHours = (subjects[subject] as num).toDouble();
      final questionCount = (questions[subject] as num?)?.toInt() ?? 0;
      
      // Tenta usar o progresso armazenado, se disponível
      final stored = storedProgress[subject] as Map<String, dynamic>?;
      
      if (stored != null) {
        // Usa dados de progresso armazenados
        final completedHours = (stored['completedHours'] as num?)?.toDouble() ?? 0;
        final percentage = goalHours > 0 ? (completedHours / goalHours * 100) : 0;
        
        progress[subject] = {
          'goalHours': goalHours,
          'questions': questionCount,
          'completedHours': completedHours,
          'percentage': percentage.clamp(0, 100),
          'lastUpdated': stored['lastUpdated'],
        };
      } else {
        // Calcula com base em questões
        final estimatedHours = questionCount * 4 / 60.0;
        final percentage = goalHours > 0 ? (estimatedHours / goalHours * 100) : 0;
        
        progress[subject] = {
          'goalHours': goalHours,
          'questions': questionCount,
          'completedHours': estimatedHours,
          'percentage': percentage.clamp(0, 100),
        };
      }
      
      totalGoalHours += goalHours;
      totalQuestions += questionCount;
    }
    
    final totalCompletedHours = progress.values.fold<double>(
      0, (sum, p) => sum + (p['completedHours'] as double)
    );
    
    final totalPercentage = totalGoalHours > 0 ? (totalCompletedHours / totalGoalHours * 100) : 0;
    
    return {
      'month': goals['month'] ?? 'Mês Desconhecido',
      'monthName': goals['monthName'] ?? 'Mês Desconhecido',
      'config': config,
      'progressBySubject': progress,
      'summary': {
        'totalGoalHours': totalGoalHours,
        'totalCompletedHours': totalCompletedHours,
        'totalQuestions': totalQuestions,
        'totalPercentage': totalPercentage.clamp(0, 100),
        'daysStudied': config['studyDays'] ?? 0,
        'hoursPerDay': config['hoursPerDay'] ?? 0,
      },
      'generatedAt': goals['generatedAt'],
      'updatedAt': goals['updatedAt'],
    };
  }
}