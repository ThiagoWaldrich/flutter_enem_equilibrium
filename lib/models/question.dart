class Question {
  final String id;
  final String subject;
  final String topic;
  final String? subtopic;
  final String? year;           // NOVO CAMPO
  final String? source;         // NOVO CAMPO
  final String? errorDescription;
  final Map<String, bool> errors;
  final QuestionImage? image;
  final String timestamp;

  Question({
    required this.id,
    required this.subject,
    required this.topic,
    this.subtopic,
    this.year,                  // NOVO
    this.source,                // NOVO
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
      'year': year,            // NOVO
      'source': source,        // NOVO
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
      year: json['year'],      // NOVO
      source: json['source'],  // NOVO
      errorDescription: json['errorDescription'],
      errors: json['erros'] != null
          ? Map<String, bool>.from(json['erros'])
          : {'conteudo': false, 'atencao': false, 'tempo': false},
      image: json['image'] != null ? QuestionImage.fromJson(json['image']) : null,
      timestamp: json['timestamp'] ?? DateTime.now().toIso8601String(),
    );
  }
  Question copyWith({
    String? id,
    String? subject,
    String? topic,
    String? subtopic,
    String? year,
    String? source,
    String? errorDescription,
    Map<String, bool>? errors,
    QuestionImage? image,
    String? timestamp,
  }) {
    return Question(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      subtopic: subtopic ?? this.subtopic,
      year: year ?? this.year,
      source: source ?? this.source,
      errorDescription: errorDescription ?? this.errorDescription,
      errors: errors ?? this.errors,
      image: image ?? this.image,
      timestamp: timestamp ?? this.timestamp,
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