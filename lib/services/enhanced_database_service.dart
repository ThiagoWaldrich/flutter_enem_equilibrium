import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:async';
import 'dart:convert';
import '../models/subject.dart';
import '../models/study_topic.dart';
import '../utils/constants.dart';
import '../models/schedule_cell.dart';

class EnhancedDatabaseService {
  static const String _databaseName = 'equilibrium_enhanced.db';
  static const int _databaseVersion = 4;
  
  static bool _isInitialized = false;
  late Database _database;
  
  // Cache para day_subjects por data
  final _daySubjectsCache = <String, List<Subject>>{};
  // Cache para study_topics por subjectId
  final _studyTopicsCache = <String, List<StudyTopic>>{};
  
  Future<void> init() async {
    if (!_isInitialized) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      _isInitialized = true;
    }
    
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    
    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createTables,
      onUpgrade: _upgradeDatabase,
      singleInstance: true,
    );
  }

  Database get db => _database;

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS day_subjects (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        name TEXT NOT NULL,
        sessions INTEGER NOT NULL,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS study_topics (
        id TEXT PRIMARY KEY,
        subject_id TEXT NOT NULL,
        topic TEXT NOT NULL,
        sessions INTEGER NOT NULL,
        FOREIGN KEY (subject_id) REFERENCES day_subjects (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS weekly_schedule (
        id INTEGER PRIMARY KEY,
        time_slots TEXT,
        schedule_data TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_day_subjects_date 
      ON day_subjects(date)
    ''');
    
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_study_topics_subject_id 
      ON study_topics(subject_id)
    ''');
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS weekly_schedule (
          id INTEGER PRIMARY KEY,
          time_slots TEXT,
          schedule_data TEXT,
          updated_at TEXT
        )
      ''');
    }
    
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS weekly_schedule (
          id INTEGER PRIMARY KEY,
          time_slots TEXT,
          schedule_data TEXT,
          updated_at TEXT
        )
      ''');
    }
  }

  // ========== MÉTODOS PARA MATÉRIAS ==========
  
  Future<List<Subject>> getDaySubjects(String date) async {
    // Verificar cache
    if (_daySubjectsCache.containsKey(date)) {
      return _daySubjectsCache[date]!;
    }
    
    final results = await _database.query(
      'day_subjects',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'created_at ASC',
    );
    
    final subjects = results.map((row) => Subject(
      id: row['id'] as String,
      name: row['name'] as String,
      sessions: row['sessions'] as int,
    )).toList();
    
    // Atualizar cache
    _daySubjectsCache[date] = subjects;
    
    return subjects;
  }

  Future<Subject?> getSubject(String id) async {
    final results = await _database.query(
      'day_subjects',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (results.isNotEmpty) {
      final row = results.first;
      return Subject(
        id: row['id'] as String,
        name: row['name'] as String,
        sessions: row['sessions'] as int,
      );
    }
    
    return null;
  }

  Future<int> saveSubject(Subject subject, String date) async {
    // Invalida cache para esta data
    _daySubjectsCache.remove(date);
    
    return await _database.insert(
      'day_subjects',
      {
        'id': subject.id,
        'date': date,
        'name': subject.name,
        'sessions': subject.sessions,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> deleteSubject(String id) async {
    // Precisamos saber a data para invalidar o cache
    final subject = await getSubject(id);
    if (subject != null) {
      // Nota: não temos a data aqui, então não podemos invalidar o cache facilmente.
      // Podemos optar por limpar todo o cache ou mudar a abordagem.
      // Por simplicidade, vamos limpar todo o cache de day_subjects.
      _daySubjectsCache.clear();
    }
    
    await _database.delete(
      'study_topics',
      where: 'subject_id = ?',
      whereArgs: [id],
    );
    
    return await _database.delete(
      'day_subjects',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteDaySubjects(String date) async {
    // Invalida cache para esta data
    _daySubjectsCache.remove(date);
    
    final subjects = await _database.query(
      'day_subjects',
      where: 'date = ?',
      whereArgs: [date],
      columns: ['id'],
    );
    
    for (final subject in subjects) {
      await _database.delete(
        'study_topics',
        where: 'subject_id = ?',
        whereArgs: [subject['id']],
      );
    }
    
    return await _database.delete(
      'day_subjects',
      where: 'date = ?',
      whereArgs: [date],
    );
  }

  Future<void> saveDaySubjectsWithTopics(
    String date,
    List<Subject> subjects,
    Map<String, List<StudyTopic>> topicsBySubject,
  ) async {
    // Invalida cache para esta data
    _daySubjectsCache.remove(date);
    // Invalida cache de tópicos para os subjectIds envolvidos
    for (final subject in subjects) {
      _studyTopicsCache.remove(subject.id);
    }
    
    await _database.transaction((txn) async {
      await txn.delete(
        'day_subjects',
        where: 'date = ?',
        whereArgs: [date],
      );
      
      for (final subject in subjects) {
        await txn.insert(
          'day_subjects',
          {
            'id': subject.id,
            'date': date,
            'name': subject.name,
            'sessions': subject.sessions,
            'created_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        
        final topics = topicsBySubject[subject.id] ?? [];
        for (final topic in topics) {
          await txn.insert(
            'study_topics',
            {
              'id': topic.id,
              'subject_id': topic.subjectId,
              'topic': topic.topic,
              'sessions': topic.sessions,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });
  }

  // ========== MÉTODOS PARA TÓPICOS ==========
  
  Future<List<StudyTopic>> getSubjectTopics(String subjectId) async {
    // Verificar cache
    if (_studyTopicsCache.containsKey(subjectId)) {
      return _studyTopicsCache[subjectId]!;
    }
    
    final results = await _database.query(
      'study_topics',
      where: 'subject_id = ?',
      whereArgs: [subjectId],
      orderBy: 'topic ASC',
    );
    
    final topics = results.map((row) => StudyTopic(
      id: row['id'] as String,
      subjectId: row['subject_id'] as String,
      topic: row['topic'] as String,
      sessions: row['sessions'] as int,
    )).toList();
    
    // Atualizar cache
    _studyTopicsCache[subjectId] = topics;
    
    return topics;
  }

  Future<int> saveStudyTopic(StudyTopic topic) async {
    // Invalida cache para este subjectId
    _studyTopicsCache.remove(topic.subjectId);
    
    return await _database.insert(
      'study_topics',
      {
        'id': topic.id,
        'subject_id': topic.subjectId,
        'topic': topic.topic,
        'sessions': topic.sessions,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> deleteStudyTopic(String id) async {
    // Precisamos do subjectId para invalidar o cache
    final topic = await _database.query(
      'study_topics',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (topic.isNotEmpty) {
      final subjectId = topic.first['subject_id'] as String;
      _studyTopicsCache.remove(subjectId);
    }
    
    return await _database.delete(
      'study_topics',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, dynamic>> getWeeklySchedule() async {
    final results = await _database.query('weekly_schedule');

    if (results.isNotEmpty) {
      try {
        final first = results.first;
        final timeSlotsJson = first['time_slots'] as String? ?? '[]';
        final scheduleJson = first['schedule_data'] as String? ?? '[]';
        
        final timeSlots = List<String>.from(jsonDecode(timeSlotsJson));
        final scheduleData = List<List<dynamic>>.from(jsonDecode(scheduleJson));
        
        return {
          'timeSlots': timeSlots,
          'schedule': scheduleData,
        };
      } catch (e) {
        print('Erro no parse do weekly schedule: $e');
        return {};
      }
    }

    return {};
  }

  Future<void> saveWeeklySchedule({
    required List<String> timeSlots,
    required List<List<Map<String, dynamic>>> schedule,
  }) async {
    await _database.insert(
      'weekly_schedule',
      {
        'id': 1,
        'time_slots': jsonEncode(timeSlots),
        'schedule_data': jsonEncode(schedule),
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveWeeklyScheduleWithCells({
    required List<String> timeSlots,
    required List<List<ScheduleCell>> schedule,
  }) async {
    try {
      final scheduleData = schedule.map((day) => 
        day.map((cell) => cell.toMap()).toList()
      ).toList();
      
      await _database.insert(
        'weekly_schedule',
        {
          'id': 1,
          'time_slots': jsonEncode(timeSlots),
          'schedule_data': jsonEncode(scheduleData),
          'updated_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Erro ao salvar schedule: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getWeeklyScheduleWithCells() async {
    try {
      final results = await _database.query('weekly_schedule');
      
      if (results.isNotEmpty) {
        final first = results.first;
        final timeSlotsJson = first['time_slots'] as String? ?? '[]';
        final scheduleJson = first['schedule_data'] as String? ?? '[]';
        
        final timeSlots = List<String>.from(jsonDecode(timeSlotsJson));
        final scheduleData = List<List<dynamic>>.from(jsonDecode(scheduleJson));
        
        final schedule = scheduleData.map((day) => 
          day.map((cell) {
            try {
              return ScheduleCell.fromMap(Map<String, dynamic>.from(cell));
            } catch (e) {
              print('Erro ao converter célula: $e');
              return ScheduleCell(
                dayIndex: 0,
                timeIndex: 0,
                subject: '',
                color: Colors.transparent,
              );
            }
          }).toList()
        ).toList();
        
        return {
          'timeSlots': timeSlots,
          'schedule': schedule,
        };
      }
    } catch (e) {
      print('Erro ao carregar schedule: $e');
    }
    
    return {};
  }

  Future<void> clearWeeklySchedule() async {
    await _database.delete('weekly_schedule');
  }
  
  Future<List<Map<String, dynamic>>> getSubjectsSummary(DateTime startDate, DateTime endDate) async {
    final results = await _database.rawQuery('''
      SELECT 
        date,
        COUNT(*) as total_subjects,
        SUM(sessions) as total_sessions
      FROM day_subjects
      WHERE date BETWEEN ? AND ?
      GROUP BY date
      ORDER BY date ASC
    ''', [
      _formatDate(startDate),
      _formatDate(endDate),
    ]);
    
    return results;
  }

  Future<List<Map<String, dynamic>>> getMostStudiedSubjects({int limit = 5}) async {
    final results = await _database.rawQuery('''
      SELECT 
        name,
        COUNT(*) as days_studied,
        SUM(sessions) as total_sessions
      FROM day_subjects
      GROUP BY name
      ORDER BY total_sessions DESC
      LIMIT ?
    ''', [limit]);
    
    return results;
  }

  Future<Map<String, dynamic>> exportData() async {
    final subjects = await _database.query('day_subjects');
    final topics = await _database.query('study_topics');
    final schedule = await _database.query('weekly_schedule');
    
    return {
      'subjects': subjects,
      'topics': topics,
      'schedule': schedule,
      'exported_at': DateTime.now().toIso8601String(),
    };
  }

  Future<void> importData(Map<String, dynamic> data) async {
    _daySubjectsCache.clear();
    _studyTopicsCache.clear();
    
    await _database.transaction((txn) async {
      await txn.delete('day_subjects');
      await txn.delete('study_topics');
      await txn.delete('weekly_schedule');
      
      if (data['subjects'] != null) {
        for (final subject in data['subjects'] as List) {
          await txn.insert('day_subjects', subject as Map<String, dynamic>);
        }
      }
      
      if (data['topics'] != null) {
        for (final topic in data['topics'] as List) {
          await txn.insert('study_topics', topic as Map<String, dynamic>);
        }
      }
      
      if (data['schedule'] != null) {
        for (final schedule in data['schedule'] as List) {
          await txn.insert('weekly_schedule', schedule as Map<String, dynamic>);
        }
      }
    });
  }

  Future<void> close() async {
    await _database.close();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}