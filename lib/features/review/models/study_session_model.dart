import 'package:flutter/material.dart';

class StudySession {
  final String id;
  final String topicId;
  final String topicName;
  final String subject;
  final DateTime startedAt;
  final DateTime finishedAt;
  final int durationMinutes;
  final int? qualityScore;

  StudySession({
    required this.id,
    required this.topicId,
    required this.topicName,
    required this.subject,
    required this.startedAt,
    required this.finishedAt,
    required this.durationMinutes,
    this.qualityScore,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'topicId': topicId,
    'topicName': topicName,
    'subject': subject,
    'startedAt': startedAt.toIso8601String(),
    'finishedAt': finishedAt.toIso8601String(),
    'durationMinutes': durationMinutes,
    'qualityScore': qualityScore,
  };

  factory StudySession.fromMap(Map<String, dynamic> map) => StudySession(
    id: map['id'] as String? ?? '',
    topicId: map['topicId'] as String? ?? '',
    topicName: map['topicName'] as String? ?? 'Tópico não encontrado',
    subject: map['subject'] as String? ?? 'Matéria',
    startedAt: map['startedAt'] != null ? DateTime.parse(map['startedAt'] as String) : DateTime.now(),
    finishedAt: map['finishedAt'] != null ? DateTime.parse(map['finishedAt'] as String) : DateTime.now(),
    durationMinutes: map['durationMinutes'] as int? ?? 0,
    qualityScore: map['qualityScore'] as int?,
  );
}