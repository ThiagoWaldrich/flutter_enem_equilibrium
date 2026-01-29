import 'dart:typed_data';
import 'package:equilibrium/features/questions/models/question_image.dart';

class QuestionLocalModel {
  int? id;
  String? questionText;
  String? answer;
  int? subjectId;
  int? topicId;
  int? difficulty;
  

  Map<String, bool> errors = {}; 
  String? topic;
  String? subtopic;
  String? errorDescription;
  String? timestamp; 
  
  String? year;
  String? exam;
  DateTime? lastReview;
  DateTime? nextReview;
  int? correctCount;
  int? wrongCount;
  double? efactor;
  int? interval;
  int? repetition;
  

  Uint8List? image; 
  QuestionImage? questionImage; 

  QuestionLocalModel({
    this.id,
    this.questionText,
    this.answer,
    this.subjectId,
    this.topicId,
    this.difficulty,
    Map<String, bool>? errors, 
    this.topic,
    this.subtopic,
    this.errorDescription,
    this.timestamp,
    
    this.year,
    this.exam,
    this.lastReview,
    this.nextReview,
    this.correctCount,
    this.wrongCount,
    this.efactor,
    this.interval,
    this.repetition,
    
    this.image,
    this.questionImage,
  }) : errors = errors ?? {};

  Uint8List? get imageData => image ?? questionImage?.data;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'questionText': questionText,
      'answer': answer,
      'subjectId': subjectId,
      'topicId': topicId,
      'difficulty': difficulty,
      'errors': errors.entries.map((e) => '${e.key}:${e.value}').join(';'),
      'topic': topic,
      'subtopic': subtopic,
      'errorDescription': errorDescription,
      'timestamp': timestamp,
      'year': year,
      'exam': exam,
      'lastReview': lastReview?.toIso8601String(),
      'nextReview': nextReview?.toIso8601String(),
      'correctCount': correctCount,
      'wrongCount': wrongCount,
      'efactor': efactor,
      'interval': interval,
      'repetition': repetition,
    };
  }

  factory QuestionLocalModel.fromMap(Map<String, dynamic> map) {
    final errors = <String, bool>{};
    if (map['errors'] != null) {
      final errorList = map['errors'].toString().split(';');
      for (var error in errorList) {
        final parts = error.split(':');
        if (parts.length == 2) {
          errors[parts[0]] = parts[1] == 'true';
        }
      }
    }
    
    return QuestionLocalModel(
      id: map['id'],
      questionText: map['questionText'],
      answer: map['answer'],
      subjectId: map['subjectId'],
      topicId: map['topicId'],
      difficulty: map['difficulty'],
      errors: errors,
      topic: map['topic'],
      subtopic: map['subtopic'],
      errorDescription: map['errorDescription'],
      timestamp: map['timestamp'],
      year: map['year'],
      exam: map['exam'],
      lastReview: map['lastReview'] != null ? DateTime.parse(map['lastReview']) : null,
      nextReview: map['nextReview'] != null ? DateTime.parse(map['nextReview']) : null,
      correctCount: map['correctCount'],
      wrongCount: map['wrongCount'],
      efactor: map['efactor']?.toDouble(),
      interval: map['interval'],
      repetition: map['repetition'],
    );
  }
}