import '../models/question_image.dart';

enum ErrorType { conteudo, atencao, tempo }

extension ErrorTypeExtension on ErrorType {
  String get displayName {
    switch (this) {
      case ErrorType.conteudo:
        return 'Conteúdo';
      case ErrorType.atencao:
        return 'Atenção';
      case ErrorType.tempo:
        return 'Tempo';
    }
  }
}

class Question {
  final String id;
  final String subject;
  final String topic;
  final String? subtopic;
  final String? year;
  final String? source;
  final String? errorDescription;
  final Set<ErrorType> errorTypes;
  final QuestionImage? image;
  final DateTime timestamp;
  

  const Question({
    required this.id,
    required this.subject,
    required this.topic,
    this.subtopic,
    this.year,
    this.source,
    this.errorDescription,
    Set<ErrorType>? errorTypes,
    this.image,
    required this.timestamp,
  }) : errorTypes = errorTypes ?? const {};

  // Domínio
  bool get hasErrors => errorTypes.isNotEmpty;
  bool get hasImage => image != null;

  bool isRecent({int days = 7}) {
    return DateTime.now().difference(timestamp).inDays < days;
  }

  bool hasError(ErrorType type) => errorTypes.contains(type);

  String get errorSummary {
    if (errorTypes.isEmpty) return 'Sem erros';
    return errorTypes.map((e) => e.displayName).join(', ');
  }

  Question toggleError(ErrorType errorType) {
    final newErrors = {...errorTypes};
    newErrors.contains(errorType)
        ? newErrors.remove(errorType)
        : newErrors.add(errorType);

    return copyWith(errorTypes: newErrors);
  }

  Question withImage(QuestionImage image) {
    return copyWith(image: image);
  }

  Question removeImage() {
    return copyWith(image: null);
  }

  Question copyWith({
    String? id,
    String? subject,
    String? topic,
    String? subtopic,
    String? year,
    String? source,
    String? errorDescription,
    Set<ErrorType>? errorTypes,
    QuestionImage? image,
    DateTime? timestamp,
  }) {
    return Question(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      subtopic: subtopic ?? this.subtopic,
      year: year ?? this.year,
      source: source ?? this.source,
      errorDescription: errorDescription ?? this.errorDescription,
      errorTypes: errorTypes ?? this.errorTypes,
      image: image ?? this.image,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Question && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Question($id: $subject - $topic)';
  }
}
