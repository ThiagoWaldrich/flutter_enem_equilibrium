import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart'; // Contém 'firstIntValue'
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // Para FFI
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/question.dart';

class DatabaseService {
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
    // Configurar factory FFI para desktop
    if (!kIsWeb) {
      // Inicializar FFI se ainda não foi feito
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String databasesPath;
    
    if (kIsWeb) {
      // Web não tem filesystem
      databasesPath = '';
    } else {
      // Mobile/Desktop: pegar path do diretório de documentos
      final appDir = await getApplicationDocumentsDirectory();
      databasesPath = appDir.path;
    }
    
    final path = join(databasesPath, 'enem_questions.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
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

    await db.execute('CREATE INDEX idx_subject ON questions(subject)');
    await db.execute('CREATE INDEX idx_topic ON questions(topic)');
    await db.execute('CREATE INDEX idx_timestamp ON questions(timestamp)');
  }

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

    return await db.insert('questions', map);
  }

  Future<List<Question>> getQuestions({
    int limit = 100,
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
    
    query += ' ORDER BY timestamp DESC LIMIT ? OFFSET ?';
    args.addAll([limit, offset]);
    
    final List<Map<String, dynamic>> maps = await db.rawQuery(query, args);
    
    return maps.map((map) => _questionFromMap(map)).toList();
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
    return firstIntValue(result) ?? 0; // Alterado aqui
  }

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

  Future<List<Map<String, dynamic>>> getTopicsBySubject(String subject) async {
    final db = await database;
    
    final result = await db.rawQuery('''
      SELECT topic, COUNT(*) as count
      FROM questions
      WHERE subject = ?
      GROUP BY topic
      ORDER BY count DESC
    ''', [subject]);
    
    return result;
  }

  Future<List<Map<String, dynamic>>> getSubtopicsBySubject(String subject) async {
    final db = await database;
    
    final result = await db.rawQuery('''
      SELECT subtopic, COUNT(*) as count
      FROM questions
      WHERE subject = ? AND subtopic IS NOT NULL AND subtopic != ''
      GROUP BY subtopic
      ORDER BY count DESC
    ''', [subject]);
    
    return result;
  }

  Future<int> deleteQuestions(List<String> ids) async {
    final db = await database;
    
    final placeholders = List.filled(ids.length, '?').join(',');
    return await db.delete(
      'questions',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  Future<int> updateQuestion(Question question) async {
    final db = await database;
    
    final map = {
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
    };

    return await db.update(
      'questions',
      map,
      where: 'id = ?',
      whereArgs: [question.id],
    );
  }

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

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
int? firstIntValue(List<Map<String, dynamic>> list) {
  if (list.isEmpty) return null;
  final value = list.first.values.first;
  return value is int ? value : int.tryParse(value.toString());
}
