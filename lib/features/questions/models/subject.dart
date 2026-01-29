class Subject {
  final String id;
  final String name;
  final int sessions;

  Subject({
    required this.id,
    required this.name,
    required this.sessions,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sessions': sessions,
    };
  }

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      sessions: json['sessions'] ?? 1,
    );
  }

  Subject copyWith({
    String? id,
    String? name,
    int? sessions,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      sessions: sessions ?? this.sessions,
    );
  }
}
