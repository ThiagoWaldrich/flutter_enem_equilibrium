import '../../subjects/models/subject.dart';

class StudySession {
  final int sessionNumber;
  final int questionCount;

  StudySession(
    this.sessionNumber, {
    this.questionCount = 0,
  });

  StudySession copyWith({
    int? questionCount,
  }) {
    return StudySession(
      sessionNumber,
      questionCount: questionCount ?? this.questionCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionNumber': sessionNumber,
      'questionCount': questionCount,
    };
  }

  factory StudySession.fromJson(Map<String, dynamic> json) {
    return StudySession(
      json['sessionNumber'] as int,
      questionCount: json['questionCount'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudySession &&
          runtimeType == other.runtimeType &&
          sessionNumber == other.sessionNumber &&
          questionCount == other.questionCount;

  @override
  int get hashCode => Object.hash(sessionNumber, questionCount);
}

class DayData {
  final String date;
  final int? mood;
  final int? energy;
  final String? notes;
  final List<Subject>? customSubjects;
  final Map<String, List<StudySession>> studyProgress;

  DayData({
    required this.date,
    this.mood,
    this.energy,
    this.notes,
    this.customSubjects,
    Map<String, List<StudySession>>? studyProgress,
  }) : studyProgress = studyProgress ?? const {};

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'mood': mood,
      'energy': energy,
      'notes': notes,
      'customSubjects': customSubjects?.map((s) => s.toJson()).toList(),
      'studyProgress': studyProgress.map(
        (key, value) => MapEntry(
          key,
          value.map((session) => session.toJson()).toList(),
        ),
      ),
    };
  }

  factory DayData.fromJson(Map<String, dynamic> json) {
    Map<String, List<StudySession>> studyProgress = {};

    if (json['studyProgress'] != null) {
      final progressData = json['studyProgress'] as Map<String, dynamic>;
      progressData.forEach((subjectId, sessions) {
        if (sessions is List) {
          if (sessions.isNotEmpty && sessions.first is int) {
            studyProgress[subjectId] = (sessions as List<int>)
                .map((sessionNumber) => StudySession(sessionNumber))
                .toList();
          } else if (sessions.isNotEmpty && sessions.first is Map) {
            studyProgress[subjectId] = (sessions)
                .map((sessionJson) =>
                    StudySession.fromJson(sessionJson as Map<String, dynamic>))
                .toList();
          }
        }
      });
    }

    return DayData(
      date: json['date'] ?? '',
      mood: json['mood'],
      energy: json['energy'],
      notes: json['notes'],
      customSubjects: json['customSubjects'] != null
          ? (json['customSubjects'] as List)
              .map((s) => Subject.fromJson(s))
              .toList()
          : null,
      studyProgress: studyProgress,
    );
  }

  DayData copyWith({
    String? date,
    int? mood,
    int? energy,
    String? notes,
    List<Subject>? customSubjects,
    Map<String, List<StudySession>>? studyProgress,
  }) {
    return DayData(
      date: date ?? this.date,
      mood: mood ?? this.mood,
      energy: energy ?? this.energy,
      notes: notes ?? this.notes,
      customSubjects: customSubjects ?? this.customSubjects,
      studyProgress: studyProgress ?? this.studyProgress,
    );
  }

  int getTotalQuestionsForSubject(String subjectId) {
    final sessions = studyProgress[subjectId] ?? [];
    return sessions.fold(0, (sum, session) => sum + session.questionCount);
  }

  int getTotalQuestionsForDay() {
    int total = 0;
    studyProgress.forEach((subjectId, sessions) {
      total += sessions.fold(0, (sum, session) => sum + session.questionCount);
    });
    return total;
  }
}
