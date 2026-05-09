import '../../../features/questions/models/question.dart';

class PriorityItem {
  final String subject;
  final String topic;
  final String? subtopic;
  final int totalErrorCount;
  final Map<ErrorType, int> errorsByType;
  final List<Question> questions; // Referência para as questões com erro

  const PriorityItem({
    required this.subject,
    required this.topic,
    this.subtopic,
    required this.totalErrorCount,
    required this.errorsByType,
    required this.questions,
  });

  String get displayName {
    if (subtopic != null && subtopic!.isNotEmpty) {
      return '$topic › $subtopic';
    }
    return topic;
  }

  double get errorPercentage {
    if (questions.isEmpty) return 0;
    return totalErrorCount / questions.length;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PriorityItem &&
          runtimeType == other.runtimeType &&
          subject == other.subject &&
          topic == other.topic &&
          subtopic == other.subtopic;

  @override
  int get hashCode => Object.hash(subject, topic, subtopic);
}