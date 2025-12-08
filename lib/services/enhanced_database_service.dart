import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/question.dart';
import '../models/flashcard.dart';
import '../models/access_log.dart';
import '../models/study_topic.dart';
import '../models/subject.dart';
import '../models/day_data.dart';

class EnhancedDatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<void> init() async {
    await database;
  }

  Future<Database> _initDatabase() async {
    if (!kIsWeb) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String databasesPath;
    
    if (kIsWeb) {
      databasesPath = '';
    } else {
      final appDir = await getApplicationDocumentsDirectory();
      databasesPath = appDir.path;
    }
    
    final path = join(databasesPath, 'equilibrium_complete.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabela de questões
    await db.execute('''
      CREATE TABLE questions (
        id TEXT PRIMARY KEY,
        subject TEXT NOT NULL,
        topic TEXT NOT NULL,
        subtopic TEXT,
        description TEXT,
        error_description TEXT,
        content_error INTEGER DEFAULT 0,
        attention_error INTEGER DEFAULT 0,
        time_error INTEGER DEFAULT 0,
        image_data TEXT,
        image_name TEXT,
        image_type TEXT,
        timestamp TEXT NOT NULL
      )
    ''');

    // Tabela de flashcards
    await db.execute('''
      CREATE TABLE flashcards (
        id TEXT PRIMARY KEY,
        subject TEXT NOT NULL,
        topic TEXT NOT NULL,
        front TEXT NOT NULL,
        back TEXT NOT NULL,
        ease_factor INTEGER DEFAULT 250,
        interval INTEGER DEFAULT 1,
        next_review TEXT,
        review_count INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        last_reviewed_at TEXT
      )
    ''');

    // Tabela de logs de acesso
    await db.execute('''
      CREATE TABLE access_logs (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL UNIQUE,
        access_count INTEGER DEFAULT 1,
        first_access_time TEXT NOT NULL,
        last_access_time TEXT NOT NULL
      )
    ''');

    // Tabela de dados do dia
    await db.execute('''
      CREATE TABLE day_data (
        date TEXT PRIMARY KEY,
        mood INTEGER,
        energy INTEGER,
        notes TEXT
      )
    ''');

    // Tabela de matérias do dia
    await db.execute('''
      CREATE TABLE day_subjects (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        subject_name TEXT NOT NULL,
        sessions INTEGER DEFAULT 1,
        FOREIGN KEY (date) REFERENCES day_data(date)
      )
    ''');

    // Tabela de tópicos de estudo do dia
    await db.execute('''
      CREATE TABLE day_study_topics (
        id TEXT PRIMARY KEY,
        day_subject_id TEXT NOT NULL,
        topic TEXT NOT NULL,
        sessions INTEGER DEFAULT 1,
        FOREIGN KEY (day_subject_id) REFERENCES day_subjects(id)
      )
    ''');

    // Tabela de progresso de estudo
    await db.execute('''
      CREATE TABLE study_progress (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        subject_id TEXT NOT NULL,
        topic_id TEXT,
        session_number INTEGER NOT NULL,
        completed_at TEXT NOT NULL
      )
    ''');

    // Índices
    await db.execute('CREATE INDEX idx_questions_subject ON questions(subject)');
    await db.execute('CREATE INDEX idx_questions_topic ON questions(topic)');
    await db.execute('CREATE INDEX idx_questions_timestamp ON questions(timestamp)');
    await db.execute('CREATE INDEX idx_flashcards_subject ON flashcards(subject)');
    await db.execute('CREATE INDEX idx_flashcards_next_review ON flashcards(next_review)');
    await db.execute('CREATE INDEX idx_access_logs_date ON access_logs(date)');
    await db.execute('CREATE INDEX idx_day_subjects_date ON day_subjects(date)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _onCreate(db, newVersion);
    }
  }

  // ========== QUESTÕES ==========
  Future<int> insertQuestion(Question question) async {
    final db = await database;
    
    final map = {
      'id': question.id,
      'subject': question.subject,
      'topic': question.topic,
      'subtopic': question.subtopic,
      'description': question.description,
      'error_description': question.errorDescription,
      'content_error': question.errors['conteudo'] == true ? 1 : 0,
      'attention_error': question.errors['atencao'] == true ? 1 : 0,
      'time_error': question.errors['tempo'] == true ? 1 : 0,
      'image_data': question.image?.data,
      'image_name': question.image?.name,
      'image_type': question.image?.type,
      'timestamp': question.timestamp,
    };

    return await db.insert('questions', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Question>> getQuestions({
    int? limit,
    int offset = 0,
    String? subject,
  }) async {
    final db = await database;
    
    String query = 'SELECT * FROM questions';
    List<dynamic> args = [];
    
    if (subject != null) {
      query += ' WHERE subject = ?';
      args.add(subject);
    }
    
    query += ' ORDER BY timestamp DESC';
    
    if (limit != null) {
      query += ' LIMIT ? OFFSET ?';
      args.addAll([limit, offset]);
    }
    
    final List<Map<String, dynamic>> maps = await db.rawQuery(query, args);
    
    return maps.map((map) => _questionFromMap(map)).toList();
  }

  // ========== FLASHCARDS ==========
  Future<int> insertFlashcard(Flashcard flashcard) async {
    final db = await database;
    return await db.insert('flashcards', flashcard.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateFlashcard(Flashcard flashcard) async {
    final db = await database;
    return await db.update(
      'flashcards',
      flashcard.toJson(),
      where: 'id = ?',
      whereArgs: [flashcard.id],
    );
  }

  Future<List<Flashcard>> getFlashcards({String? subject, String? topic}) async {
    final db = await database;
    
    String query = 'SELECT * FROM flashcards WHERE 1=1';
    List<dynamic> args = [];
    
    if (subject != null) {
      query += ' AND subject = ?';
      args.add(subject);
    }
    
    if (topic != null) {
      query += ' AND topic = ?';
      args.add(topic);
    }
    
    query += ' ORDER BY next_review ASC, created_at DESC';
    
    final maps = await db.rawQuery(query, args);
    return maps.map((map) => Flashcard.fromJson(map)).toList();
  }

  Future<List<Flashcard>> getDueFlashcards() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    final maps = await db.query(
      'flashcards',
      where: 'next_review IS NULL OR next_review <= ?',
      whereArgs: [now],
      orderBy: 'next_review ASC',
    );
    
    return maps.map((map) => Flashcard.fromJson(map)).toList();
  }

  Future<int> deleteFlashcard(String id) async {
    final db = await database;
    return await db.delete('flashcards', where: 'id = ?', whereArgs: [id]);
  }

  // ========== LOGS DE ACESSO ==========
  Future<void> registerAccess() async {
    final db = await database;
    final now = DateTime.now();
    final dateStr = now.toIso8601String().split('T')[0];
    final timeStr = now.toIso8601String();

    final existing = await db.query(
      'access_logs',
      where: 'date = ?',
      whereArgs: [dateStr],
    );

    if (existing.isEmpty) {
      await db.insert('access_logs', {
        'id': 'log_$dateStr',
        'date': dateStr,
        'access_count': 1,
        'first_access_time': timeStr,
        'last_access_time': timeStr,
      });
    } else {
      final current = AccessLog.fromJson(existing.first);
      await db.update(
        'access_logs',
        {
          'access_count': current.accessCount + 1,
          'last_access_time': timeStr,
        },
        where: 'date = ?',
        whereArgs: [dateStr],
      );
    }
  }

  Future<List<AccessLog>> getAccessLogs({int? limit}) async {
    final db = await database;
    
    String query = 'SELECT * FROM access_logs ORDER BY date DESC';
    if (limit != null) {
      query += ' LIMIT ?';
    }
    
    final maps = await db.rawQuery(query, limit != null ? [limit] : []);
    return maps.map((map) => AccessLog.fromJson(map)).toList();
  }

  Future<AccessLog?> getTodayAccess() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    final maps = await db.query(
      'access_logs',
      where: 'date = ?',
      whereArgs: [today],
    );
    
    if (maps.isEmpty) return null;
    return AccessLog.fromJson(maps.first);
  }

  // ========== DADOS DO DIA ==========
  Future<void> saveDayData(String date, DayData dayData) async {
    final db = await database;
    
    await db.insert(
      'day_data',
      {
        'date': date,
        'mood': dayData.mood,
        'energy': dayData.energy,
        'notes': dayData.notes,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<DayData?> getDayData(String date) async {
    final db = await database;
    
    final maps = await db.query('day_data', where: 'date = ?', whereArgs: [date]);
    
    if (maps.isEmpty) return null;
    
    final map = maps.first;
    return DayData(
      date: map['date'] as String,
      mood: map['mood'] as int?,
      energy: map['energy'] as int?,
      notes: map['notes'] as String?,
    );
  }

  // ========== MATÉRIAS E TÓPICOS DO DIA ==========
  Future<void> saveDaySubjectsWithTopics(String date, List<Subject> subjects, Map<String, List<StudyTopic>> topicsBySubject) async {
    final db = await database;
    
    await db.delete('day_subjects', where: 'date = ?', whereArgs: [date]);
    
    for (final subject in subjects) {
      await db.insert('day_subjects', {
        'id': subject.id,
        'date': date,
        'subject_name': subject.name,
        'sessions': subject.sessions,
      });
      
      final topics = topicsBySubject[subject.id] ?? [];
      for (final topic in topics) {
        await db.insert('day_study_topics', topic.toJson());
      }
    }
  }

  Future<List<Subject>> getDaySubjects(String date) async {
    final db = await database;
    
    final maps = await db.query('day_subjects', where: 'date = ?', whereArgs: [date]);
    
    return maps.map((map) => Subject(
      id: map['id'] as String,
      name: map['subject_name'] as String,
      sessions: map['sessions'] as int,
    )).toList();
  }

  Future<List<StudyTopic>> getSubjectTopics(String subjectId) async {
    final db = await database;
    
    final maps = await db.query(
      'day_study_topics',
      where: 'day_subject_id = ?',
      whereArgs: [subjectId],
    );
    
    return maps.map((map) => StudyTopic.fromJson(map)).toList();
  }

  // ========== PROGRESSO DE ESTUDO ==========
  Future<void> toggleStudySession(String date, String subjectId, String? topicId, int sessionNumber) async {
    final db = await database;
    
    final existing = await db.query(
      'study_progress',
      where: 'date = ? AND subject_id = ? AND session_number = ? AND (topic_id = ? OR (topic_id IS NULL AND ? IS NULL))',
      whereArgs: [date, subjectId, sessionNumber, topicId, topicId],
    );
    
    if (existing.isEmpty) {
      await db.insert('study_progress', {
        'id': 'progress_${DateTime.now().millisecondsSinceEpoch}',
        'date': date,
        'subject_id': subjectId,
        'topic_id': topicId,
        'session_number': sessionNumber,
        'completed_at': DateTime.now().toIso8601String(),
      });
    } else {
      await db.delete(
        'study_progress',
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    }
  }

  Future<List<int>> getCompletedSessions(String date, String subjectId, String? topicId) async {
    final db = await database;
    
    final maps = await db.query(
      'study_progress',
      where: 'date = ? AND subject_id = ? AND (topic_id = ? OR (topic_id IS NULL AND ? IS NULL))',
      whereArgs: [date, subjectId, topicId, topicId],
    );
    
    return maps.map((map) => map['session_number'] as int).toList();
  }

  // ========== ESTATÍSTICAS ==========
  Future<Map<String, int>> getSubjectStats() async {
    final db = await database;
    
    final result = await db.rawQuery('''
      SELECT subject, COUNT(*) as count
      FROM questions
      GROUP BY subject
      ORDER BY count DESC
    ''');
    
    final stats = <String, int>{};
    for (final row in result) {
      stats[row['subject'] as String] = row['count'] as int;
    }
    
    return stats;
  }

  Future<int> getQuestionCount({String? subject}) async {
    final db = await database;
    
    String query = 'SELECT COUNT(*) as count FROM questions';
    List<dynamic> args = [];
    
    if (subject != null) {
      query += ' WHERE subject = ?';
      args.add(subject);
    }
    
    final result = await db.rawQuery(query, args);
    return _firstIntValue(result) ?? 0;
  }

  Future<int> getFlashcardCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM flashcards');
    return _firstIntValue(result) ?? 0;
  }

  Future<int> getDueFlashcardCount() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM flashcards WHERE next_review IS NULL OR next_review <= ?',
      [now],
    );
    return _firstIntValue(result) ?? 0;
  }

  // ========== HELPERS ==========
  Question _questionFromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'],
      subject: map['subject'],
      topic: map['topic'],
      subtopic: map['subtopic'],
      description: map['description'],
      errorDescription: map['error_description'],
      errors: {
        'conteudo': map['content_error'] == 1,
        'atencao': map['attention_error'] == 1,
        'tempo': map['time_error'] == 1,
      },
      image: map['image_data'] != null
          ? QuestionImage(
              data: map['image_data'],
              name: map['image_name'] ?? '',
              type: map['image_type'] ?? '',
            )
          : null,
      timestamp: map['timestamp'],
    );
  }

  int? _firstIntValue(List<Map<String, dynamic>> list) {
    if (list.isEmpty) return null;
    final value = list.first.values.first;
    return value is int ? value : int.tryParse(value.toString());
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}