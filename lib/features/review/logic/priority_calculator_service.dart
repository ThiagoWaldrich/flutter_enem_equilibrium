// lib/features/review/logic/priority_calculator_service.dart
import 'package:equilibrium/features/core/services/database_service.dart';
import 'package:flutter/foundation.dart';
import '../../questions/models/question.dart';
import '../models/priority_item_model.dart';

class PriorityCalculatorService extends ChangeNotifier {
  final DatabaseService _databaseService;
  List<PriorityItem> _cachedItems = [];
  bool _isLoading = false;
  bool _hasLoaded = false;

  PriorityCalculatorService(this._databaseService);

  List<PriorityItem> get cachedItems => _cachedItems;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;

  Future<List<PriorityItem>> getPrioritizedTopics({bool forceRefresh = false}) async {
    if (!forceRefresh && _hasLoaded && _cachedItems.isNotEmpty) {
      return _cachedItems;
    }

    _isLoading = true;
    
    try {
      final allQuestions = await _databaseService.getQuestions(limit: 10000);
      final questionsWithErrors = allQuestions.where((q) => q.hasErrors).toList();

      if (questionsWithErrors.isEmpty) {
        _cachedItems = [];
        _hasLoaded = true;
        _isLoading = false;
        return [];
      }

      final Map<String, _PriorityItemBuilder> builderMap = {};

      for (final question in questionsWithErrors) {
        final key = '${question.subject}|${question.topic}|${question.subtopic ?? ''}';
        
        if (!builderMap.containsKey(key)) {
          builderMap[key] = _PriorityItemBuilder(
            subject: question.subject,
            topic: question.topic,
            subtopic: question.subtopic,
          );
        }
        
        builderMap[key]!.addQuestion(question);
      }

      var items = builderMap.values
          .map((b) => b.build())
          .toList();
      
      items.sort((a, b) => b.totalErrorCount.compareTo(a.totalErrorCount));
      
      _cachedItems = items;
      _hasLoaded = true;
      _isLoading = false;
      
      return items;
    } catch (e) {
      debugPrint('Erro ao calcular prioridades: $e');
      _isLoading = false;
      return [];
    }
  }

  void refresh() {
    getPrioritizedTopics(forceRefresh: true);
  }
}

class _PriorityItemBuilder {
  final String subject;
  final String topic;
  final String? subtopic;
  final List<Question> _questions = [];
  final Map<ErrorType, int> _errorCounts = {
    ErrorType.conteudo: 0,
    ErrorType.atencao: 0,
    ErrorType.tempo: 0,
  };

  _PriorityItemBuilder({
    required this.subject,
    required this.topic,
    this.subtopic,
  });

  void addQuestion(Question question) {
    _questions.add(question);
    for (final errorType in question.errorTypes) {
      _errorCounts[errorType] = (_errorCounts[errorType] ?? 0) + 1;
    }
  }

  int get totalErrorCount => _errorCounts.values.reduce((a, b) => a + b);

  PriorityItem build() {
    return PriorityItem(
      subject: subject,
      topic: topic,
      subtopic: subtopic,
      totalErrorCount: totalErrorCount,
      errorsByType: Map.from(_errorCounts),
      questions: List.from(_questions),
    );
  }
}