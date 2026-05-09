import 'package:equilibrium/features/review/models/study_topic_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';
import '../models/study_session_model.dart';
import '../models/study_topic_model.dart';
import '../models/study_session_model.dart';
import '../models/monthly_goal.dart';
import 'spaced_repetition_helper.dart';

class StudyScheduler {
  final Database db;
  final String tableName = 'study_topics';
  final String sessionsTable = 'study_sessions';
  final String goalsTable = 'monthly_goals';

  StudyScheduler(this.db);

  Future<void> initTable() async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id TEXT PRIMARY KEY,
        subject TEXT NOT NULL,
        topic TEXT NOT NULL,
        subtopic TEXT,
        createdAt TEXT NOT NULL,
        lastStudiedAt TEXT,
        nextReviewAt TEXT NOT NULL,
        reviewLevel INTEGER DEFAULT 0,
        totalMinutesStudied INTEGER DEFAULT 0,
        mastery REAL DEFAULT 0.0
      )
    ''');
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $sessionsTable (
        id TEXT PRIMARY KEY,
        topicId TEXT NOT NULL,
        topicName TEXT NOT NULL,
        subject TEXT NOT NULL,
        startedAt TEXT NOT NULL,
        finishedAt TEXT NOT NULL,
        durationMinutes INTEGER NOT NULL,
        qualityScore INTEGER
      )
    ''');
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $goalsTable (
        month TEXT PRIMARY KEY,
        targetMinutes INTEGER NOT NULL
      )
    ''');
    
    await db.execute('CREATE INDEX IF NOT EXISTS idx_next_review ON $tableName(nextReviewAt)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_subject ON $tableName(subject)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_session_date ON $sessionsTable(startedAt)');
  }

  Future<List<StudyTopic>> getAllTopics() async {
    final result = await db.query(tableName, orderBy: 'subject ASC, topic ASC');
    return result.map((m) => StudyTopic.fromMap(m)).toList();
  }

  Future<void> upsertTopic(StudyTopic topic) async {
    await db.insert(
      tableName,
      topic.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveSession(StudySession session) async {
    await db.insert(
      sessionsTable,
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteSession(String sessionId) async {
    await db.delete(sessionsTable, where: 'id = ?', whereArgs: [sessionId]);
  }

  Future<List<StudySession>> getAllSessions() async {
    final result = await db.query(sessionsTable, orderBy: 'startedAt DESC');
    final List<StudySession> sessions = [];
    for (final map in result) {
      try {
        sessions.add(StudySession.fromMap(map));
      } catch (e) {
        debugPrint('Erro ao carregar sessão: $e');
      }
    }
    return sessions;
  }

  Future<int> getTotalMinutesStudiedInMonth(DateTime month) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    
    final result = await db.rawQuery('''
      SELECT SUM(durationMinutes) as total
      FROM $sessionsTable
      WHERE startedAt >= ? AND startedAt <= ?
    ''', [startOfMonth.toIso8601String(), endOfMonth.toIso8601String()]);
    
    if (result.isEmpty || result.first['total'] == null) {
      return 0;
    }
    return (result.first['total'] as num).toInt();
  }

  Future<MonthlyGoal?> getMonthlyGoal(DateTime month) async {
    final monthKey = DateTime(month.year, month.month, 1).toIso8601String();
    final result = await db.query(
      goalsTable,
      where: 'month = ?',
      whereArgs: [monthKey],
    );
    if (result.isEmpty) return null;
    return MonthlyGoal(
      targetMinutes: result.first['targetMinutes'] as int,
      month: DateTime.parse(result.first['month'] as String),
    );
  }

  Future<void> setMonthlyGoal(DateTime month, int targetMinutes) async {
    final monthKey = DateTime(month.year, month.month, 1).toIso8601String();
    await db.insert(
      goalsTable,
      {'month': monthKey, 'targetMinutes': targetMinutes},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> recordSession(StudyTopic topic, int qualityScore, int minutesStudied) async {
    final now = DateTime.now();
    final nextInterval = SpacedRepetitionHelper.getNextInterval(qualityScore);
    
    final updatedTopic = topic.copyWith(
      lastStudiedAt: now,
      nextReviewAt: now.add(Duration(days: nextInterval)),
      reviewLevel: topic.reviewLevel + 1,
      totalMinutesStudied: topic.totalMinutesStudied + minutesStudied,
      mastery: SpacedRepetitionHelper.calculateMastery(topic.mastery, qualityScore),
    );
    
    await upsertTopic(updatedTopic);
  }
  
  Future<void> resetTopicReviews(StudyTopic topic) async {
    final resetTopic = topic.resetReviews();
    await upsertTopic(resetTopic);
  }
}