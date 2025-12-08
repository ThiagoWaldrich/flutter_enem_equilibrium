class StudyTopic {
  final String id;
  final String subjectId;
  final String topic;
  final int sessions;

  StudyTopic({
    required this.id,
    required this.subjectId,
    required this.topic,
    required this.sessions,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject_id': subjectId,
      'topic': topic,
      'sessions': sessions,
    };
  }

  factory StudyTopic.fromJson(Map<String, dynamic> json) {
    return StudyTopic(
      id: json['id'] ?? '',
      subjectId: json['subject_id'] ?? '',
      topic: json['topic'] ?? '',
      sessions: json['sessions'] ?? 1,
    );
  }

  StudyTopic copyWith({
    String? id,
    String? subjectId,
    String? topic,
    int? sessions,
  }) {
    return StudyTopic(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      topic: topic ?? this.topic,
      sessions: sessions ?? this.sessions,
    );
  }
}