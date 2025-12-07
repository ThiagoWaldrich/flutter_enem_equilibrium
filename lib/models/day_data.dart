import 'subject.dart';

class DayData {
  final String date;
  int? mood;
  int? energy;
  String? notes;
  List<Subject>? customSubjects;
  Map<String, List<int>> studyProgress;

  DayData({
    required this.date,
    this.mood,
    this.energy,
    this.notes,
    this.customSubjects,
    Map<String, List<int>>? studyProgress,
  }) : studyProgress = studyProgress ?? {};

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'mood': mood,
      'energy': energy,
      'notes': notes,
      'customSubjects': customSubjects?.map((s) => s.toJson()).toList(),
      'studyProgress': studyProgress.map(
        (key, value) => MapEntry(key, value),
      ),
    };
  }

  factory DayData.fromJson(Map<String, dynamic> json) {
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
      studyProgress: json['studyProgress'] != null
          ? (json['studyProgress'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(
                key,
                (value as List).map((e) => e as int).toList(),
              ),
            )
          : {},
    );
  }

  DayData copyWith({
    String? date,
    int? mood,
    int? energy,
    String? notes,
    List<Subject>? customSubjects,
    Map<String, List<int>>? studyProgress,
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
}