import 'package:flutter/material.dart';

class StudyTopic {
  final String id;
  final String subject;
  final String topic;
  final String? subtopic;
  
  DateTime createdAt;
  DateTime? lastStudiedAt;
  DateTime nextReviewAt;
  int reviewLevel;
  int totalMinutesStudied;
  double mastery;

  StudyTopic({
    required this.id,
    required this.subject,
    required this.topic,
    this.subtopic,
    DateTime? createdAt,
    this.lastStudiedAt,
    DateTime? nextReviewAt,
    this.reviewLevel = 0,
    this.totalMinutesStudied = 0,
    this.mastery = 0.0,
  }) : createdAt = createdAt ?? DateTime.now(),
       nextReviewAt = nextReviewAt ?? DateTime.now();

  bool get isNew => reviewLevel == 0;
  bool get isDueForReview => DateTime.now().isAfter(nextReviewAt);
  int get estimatedHours => 1;
  
  int get priorityScore {
    int score = 0;
    if (isDueForReview) {
      final daysOverdue = DateTime.now().difference(nextReviewAt).inDays;
      score += daysOverdue.clamp(0, 10);
    }
    score += (5 - reviewLevel).clamp(0, 5);
    score += ((100 - mastery) ~/ 20);
    return score;
  }
  
  String get priorityLabel {
    if (priorityScore >= 8) return 'Urgente';
    if (priorityScore >= 5) return 'Alta';
    if (priorityScore >= 3) return 'Média';
    return 'Baixa';
  }
  
  Color get priorityColor {
    if (priorityScore >= 8) return Colors.red;
    if (priorityScore >= 5) return Colors.orange;
    if (priorityScore >= 3) return Colors.blue;
    return Colors.grey;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'subject': subject,
    'topic': topic,
    'subtopic': subtopic,
    'createdAt': createdAt.toIso8601String(),
    'lastStudiedAt': lastStudiedAt?.toIso8601String(),
    'nextReviewAt': nextReviewAt.toIso8601String(),
    'reviewLevel': reviewLevel,
    'totalMinutesStudied': totalMinutesStudied,
    'mastery': mastery,
  };

  factory StudyTopic.fromMap(Map<String, dynamic> map) => StudyTopic(
    id: map['id'] as String,
    subject: map['subject'] as String,
    topic: map['topic'] as String,
    subtopic: map['subtopic'] as String?,
    createdAt: DateTime.parse(map['createdAt'] as String),
    lastStudiedAt: map['lastStudiedAt'] != null ? DateTime.parse(map['lastStudiedAt'] as String) : null,
    nextReviewAt: DateTime.parse(map['nextReviewAt'] as String),
    reviewLevel: map['reviewLevel'] as int,
    totalMinutesStudied: map['totalMinutesStudied'] as int,
    mastery: (map['mastery'] as num).toDouble(),
  );

  StudyTopic copyWith({
    DateTime? lastStudiedAt,
    DateTime? nextReviewAt,
    int? reviewLevel,
    int? totalMinutesStudied,
    double? mastery,
  }) {
    return StudyTopic(
      id: id,
      subject: subject,
      topic: topic,
      subtopic: subtopic,
      createdAt: createdAt,
      lastStudiedAt: lastStudiedAt ?? this.lastStudiedAt,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      reviewLevel: reviewLevel ?? this.reviewLevel,
      totalMinutesStudied: totalMinutesStudied ?? this.totalMinutesStudied,
      mastery: mastery ?? this.mastery,
    );
  }
  
  StudyTopic resetReviews() {
    return copyWith(
      reviewLevel: 0,
      totalMinutesStudied: 0,
      mastery: 0.0,
      lastStudiedAt: null,
      nextReviewAt: DateTime.now(),
    );
  }
}

class GroupedTopic {
  final String subject;
  final String topic;
  final List<StudyTopic> questions;
  
  GroupedTopic({
    required this.subject,
    required this.topic,
    required this.questions,
  });
  
  int get count => questions.length;
  List<String> get subtopics => questions
      .where((q) => q.subtopic != null && q.subtopic!.isNotEmpty)
      .map((q) => q.subtopic!)
      .toSet()
      .toList();
  
  int get totalReviewCount => questions.fold(0, (sum, q) => sum + q.reviewLevel);
  int get priorityScore => questions.map((q) => q.priorityScore).reduce((a, b) => a > b ? a : b);
  
  double get errorRate {
    int errorCount = 0;
    for (final q in questions) {
      if (q.priorityScore >= 5) errorCount++;
    }
    return errorCount / count;
  }
  
  String get priorityLabel {
    if (priorityScore >= 8) return 'Urgente';
    if (priorityScore >= 5) return 'Alta';
    if (priorityScore >= 3) return 'Média';
    return 'Baixa';
  }
  
  Color get priorityColor {
    if (priorityScore >= 8) return Colors.red;
    if (priorityScore >= 5) return Colors.orange;
    if (priorityScore >= 3) return Colors.blue;
    return Colors.grey;
  }
}