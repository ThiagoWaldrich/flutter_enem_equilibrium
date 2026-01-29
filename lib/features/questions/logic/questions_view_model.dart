import '../models/question.dart';

class QuestionsViewModel {
  final List<Question> _questions = [];

  List<Question> get questions => List.unmodifiable(_questions);

  void addQuestion(Question question) {
    _questions.add(question);
  }

  void toggleError(Question question, ErrorType errorType) {
    final index = _questions.indexOf(question);
    if (index == -1) return;

    final newErrorTypes = {...question.errorTypes};
    newErrorTypes.contains(errorType)
        ? newErrorTypes.remove(errorType)
        : newErrorTypes.add(errorType);

    _questions[index] = question.copyWith(errorTypes: newErrorTypes);
  }
}
