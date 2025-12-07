class Question {
  final String id;
  final String subject;
  final String topic;
  final String? subtopic;
  final String? description;
  final String? errorDescription;
  final Map<String, bool> errors;
  final QuestionImage? image;
  final String timestamp;

  Question({
    required this.id,
    required this.subject,
    required this.topic,
    this.subtopic,
    this.description,
    this.errorDescription,
    Map<String, bool>? errors,
    this.image,
    required this.timestamp,
  }) : errors = errors ?? {'conteudo': false, 'atencao': false, 'tempo': false};

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'topic': topic,
      'subtopic': subtopic,
      'description': description,
      'errorDescription': errorDescription,
      'erros': errors,
      'image': image?.toJson(),
      'timestamp': timestamp,
    };
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] ?? '',
      subject: json['subject'] ?? '',
      topic: json['topic'] ?? '',
      subtopic: json['subtopic'],
      description: json['description'],
      errorDescription: json['errorDescription'],
      errors: json['erros'] != null
          ? Map<String, bool>.from(json['erros'])
          : {'conteudo': false, 'atencao': false, 'tempo': false},
      image: json['image'] != null ? QuestionImage.fromJson(json['image']) : null,
      timestamp: json['timestamp'] ?? DateTime.now().toIso8601String(),
    );
  }
}

class QuestionImage {
  final String data;
  final String name;
  final String type;
  final int? size;

  QuestionImage({
    required this.data,
    required this.name,
    required this.type,
    this.size,
  });

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'name': name,
      'type': type,
      'size': size,
    };
  }

  factory QuestionImage.fromJson(Map<String, dynamic> json) {
    return QuestionImage(
      data: json['data'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      size: json['size'],
    );
  }
}