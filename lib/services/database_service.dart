import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/question.dart';

class DatabaseService {
  static Database? _database;
  
  // Cache para estatísticas
  static final Map<String, dynamic> _statsCache = {};
  static DateTime? _statsCacheTime;
  static const Duration _statsCacheDuration = Duration(minutes: 5);
  
  // Cache para lista de questões (light) - chave é uma string combinando filtros
  final Map<String, List<Question>> _questionsCache = {};
  final Map<String, int> _questionsCacheTime = {};
  static const int _questionsCacheMaxAge = 30000; // 30 segundos em milissegundos

  // 1. Para autodiagnostico_screen.dart e monthly_goals_service.dart
  Future<Map<String, int>> getSubjectStats() async {
    final stats = await _getAllStatsIfNeeded();
    return stats['subjectStats'] as Map<String, int>;
  }

  // 2. Para autodiagnostico_screen.dart
  Future<int> getQuestionCount() async {
    final stats = await _getAllStatsIfNeeded();
    return stats['totalQuestions'] as int;
  }

  // 3. Para autodiagnostico_screen.dart
  Future<int> deleteQuestions(List<String> ids) async {
    if (ids.isEmpty) return 0;
    
    final db = await database;
    final placeholders = List.filled(ids.length, '?').join(',');
    
    // Invalida caches
    _invalidateCaches();
    
    return await db.delete(
      'questions',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

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

    final path = join(databasesPath, 'enem_questions.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      singleInstance: true,
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
        year TEXT,
        source TEXT,
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
    await db.execute('CREATE INDEX idx_year ON questions(year)');
    await db.execute('CREATE INDEX idx_source ON questions(source)');
    // Índices para os campos de erro
    await db.execute('CREATE INDEX idx_content_error ON questions(content_error)');
    await db.execute('CREATE INDEX idx_attention_error ON questions(attention_error)');
    await db.execute('CREATE INDEX idx_time_error ON questions(time_error)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE questions ADD COLUMN year TEXT');
        await db.execute('ALTER TABLE questions ADD COLUMN source TEXT');

        try {
          await db.execute('SELECT description FROM questions LIMIT 1');
        } catch (e) {
          await db.execute('ALTER TABLE questions ADD COLUMN description TEXT');
        }

        await db.execute('CREATE INDEX IF NOT EXISTS idx_year ON questions(year)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_source ON questions(source)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_content_error ON questions(content_error)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_attention_error ON questions(attention_error)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_time_error ON questions(time_error)');
      } catch (e) {
        print('⚠️ Erro na migração: $e');
      }
    }
  }

  // Função para inserir uma nova questão
  Future<int> insertQuestion(Question question) async {
    final db = await database;

    final map = {
      'id': question.id,
      'subject': question.subject,
      'topic': question.topic,
      'subtopic': question.subtopic,
      'year': question.year,
      'source': question.source,
      'error_description': question.errorDescription,
      'content_error': question.errors['conteudo'] == true ? 1 : 0,
      'attention_error': question.errors['atencao'] == true ? 1 : 0,
      'time_error': question.errors['tempo'] == true ? 1 : 0,
      'image_data': question.image?.data,
      'image_name': question.image?.name,
      'image_type': question.image?.type,
      'timestamp': question.timestamp,
    };

    // Invalida caches
    _invalidateCaches();
    
    return await db.insert('questions', map);
  }

  // Função auxiliar para converter map em Question
  Question _questionFromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'],
      subject: map['subject'],
      topic: map['topic'],
      subtopic: map['subtopic'],
      year: map['year'],
      source: map['source'],
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

  // Função para obter estatísticas por ano
  Future<Map<String, int>> getYearStats() async {
    final stats = await _getAllStatsIfNeeded();
    return stats['yearStats'] as Map<String, int>;
  }

  // Função para obter estatísticas por fonte
  Future<Map<String, int>> getSourceStats() async {
    final stats = await _getAllStatsIfNeeded();
    return stats['sourceStats'] as Map<String, int>;
  }

  // Função para obter anos distintos
  Future<List<String>> getDistinctYears() async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT DISTINCT year
      FROM questions
      WHERE year IS NOT NULL AND year != ''
      ORDER BY year DESC
    ''');

    return result.map((row) => row['year'] as String).toList();
  }

  // Função para obter fontes distintas
  Future<List<String>> getDistinctSources() async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT DISTINCT source
      FROM questions
      WHERE source IS NOT NULL AND source != ''
      ORDER BY source
    ''');

    return result.map((row) => row['source'] as String).toList();
  }

  // Função para atualizar uma questão
  Future<int> updateQuestion(Question question) async {
    final db = await database;

    final map = {
      'subject': question.subject,
      'topic': question.topic,
      'subtopic': question.subtopic,
      'year': question.year,
      'source': question.source,
      'error_description': question.errorDescription,
      'content_error': question.errors['conteudo'] == true ? 1 : 0,
      'attention_error': question.errors['atencao'] == true ? 1 : 0,
      'time_error': question.errors['tempo'] == true ? 1 : 0,
      'image_data': question.image?.data,
      'image_name': question.image?.name,
      'image_type': question.image?.type,
    };

    // Invalida caches
    _invalidateCaches();
    
    return await db.update(
      'questions',
      map,
      where: 'id = ?',
      whereArgs: [question.id],
    );
  }

  // Função principal para obter questões com filtros (com cache)
  Future<List<Question>> getQuestions({
    int limit = 100,
    int offset = 0,
    String? subject,
    String? year,
    String? source,
    String? errorType,
  }) async {
    // Criar chave de cache baseada nos parâmetros
    final cacheKey = '${subject ?? ''}_${year ?? ''}_${source ?? ''}_${errorType ?? ''}_$limit-$offset';
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Verificar se temos cache válido (menos de 30 segundos)
    if (_questionsCache.containsKey(cacheKey)) {
      final cacheTime = _questionsCacheTime[cacheKey] ?? 0;
      if (now - cacheTime < _questionsCacheMaxAge) {
        return _questionsCache[cacheKey]!;
      }
    }
    
    final db = await database;

    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (subject != null && subject.isNotEmpty) {
      whereClause = 'subject = ?';
      whereArgs.add(subject);
    }
    
    if (year != null && year.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'year = ?';
      whereArgs.add(year);
    }
    
    if (source != null && source.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'source = ?';
      whereArgs.add(source);
    }
    
    if (errorType != null && errorType.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      switch (errorType) {
        case 'conteudo':
          whereClause += 'content_error = 1';
          break;
        case 'atencao':
          whereClause += 'attention_error = 1';
          break;
        case 'tempo':
          whereClause += 'time_error = 1';
          break;
      }
    }
    
    final List<Map<String, dynamic>> maps = await db.query(
      'questions',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      limit: limit,
      offset: offset,
      orderBy: 'timestamp DESC',
    );

    final questions = List.generate(maps.length, (i) => _questionFromMap(maps[i]));
    
    // Atualizar cache
    _questionsCache[cacheKey] = questions;
    _questionsCacheTime[cacheKey] = now;
    
    return questions;
  }

  // Versão light sem cache (para quando sabemos que os dados mudaram)
  Future<List<Question>> getQuestionsLight({
    int limit = 100,
    int offset = 0,
    String? subject,
    String? year,
    String? source,
    String? errorType,
  }) async {
    final db = await database;

    String query = '''
      SELECT id, subject, topic, subtopic, year, source, 
             error_description, content_error, attention_error, 
             time_error, timestamp
      FROM questions
    ''';
    
    List<dynamic> args = [];
    List<String> whereConditions = [];
    
    if (subject != null && subject.isNotEmpty) {
      whereConditions.add('subject = ?');
      args.add(subject);
    }
    
    if (year != null && year.isNotEmpty) {
      whereConditions.add('year = ?');
      args.add(year);
    }
    
    if (source != null && source.isNotEmpty) {
      whereConditions.add('source = ?');
      args.add(source);
    }
    
    if (errorType != null && errorType.isNotEmpty) {
      switch (errorType) {
        case 'conteudo':
          whereConditions.add('content_error = 1');
          break;
        case 'atencao':
          whereConditions.add('attention_error = 1');
          break;
        case 'tempo':
          whereConditions.add('time_error = 1');
          break;
      }
    }
    
    if (whereConditions.isNotEmpty) {
      query += ' WHERE ${whereConditions.join(' AND ')}';
    }
    
    query += ' ORDER BY timestamp DESC LIMIT ? OFFSET ?';
    args.addAll([limit, offset]);

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, args);

    return List.generate(maps.length, (i) {
      final map = maps[i];
      return Question(
        id: map['id'],
        subject: map['subject'],
        topic: map['topic'],
        subtopic: map['subtopic'],
        year: map['year'],
        source: map['source'],
        errorDescription: map['error_description'],
        errors: {
          'conteudo': map['content_error'] == 1,
          'atencao': map['attention_error'] == 1,
          'tempo': map['time_error'] == 1,
        },
        timestamp: map['timestamp'],
      );
    });
  }

  // Função para obter todas as estatísticas de uma vez (com cache)
  Future<Map<String, dynamic>> getAllStats() async {
    return await _getAllStatsIfNeeded();
  }
  
  Future<Map<String, dynamic>> _getAllStatsIfNeeded() async {
    final now = DateTime.now();
    
    // Se o cache está válido, retornar
    if (_statsCacheTime != null && 
        now.difference(_statsCacheTime!) < _statsCacheDuration &&
        _statsCache.isNotEmpty) {
      return _statsCache;
    }
    
    // Caso contrário, buscar do banco
    final db = await database;
    
    final results = await Future.wait([
      _getSubjectStats(db),
      _getYearStats(db),
      _getSourceStats(db),
      _getQuestionCount(db),
      _calculateErrorStats(db),
    ]);
    
    _statsCache.clear();
    _statsCache['subjectStats'] = results[0] as Map<String, int>;
    _statsCache['yearStats'] = results[1] as Map<String, int>;
    _statsCache['sourceStats'] = results[2] as Map<String, int>;
    _statsCache['totalQuestions'] = results[3] as int;
    _statsCache['errorStats'] = results[4] as Map<String, Map<String, dynamic>>;
    _statsCacheTime = now;
    
    return _statsCache;
  }
  
  Future<Map<String, int>> _getSubjectStats(Database db) async {
    final result = await db.rawQuery('''
      SELECT subject, COUNT(*) as count
      FROM questions
      GROUP BY subject
      ORDER BY count DESC
    ''');
    final stats = <String, int>{};
    for (final row in result) {
      stats[row['subject'] as String] = (row['count'] as num).toInt();
    }
    return stats;
  }
  
  Future<Map<String, int>> _getYearStats(Database db) async {
    final result = await db.rawQuery('''
      SELECT year, COUNT(*) as count
      FROM questions
      WHERE year IS NOT NULL AND year != ''
      GROUP BY year
      ORDER BY year DESC
    ''');
    final stats = <String, int>{};
    for (final row in result) {
      stats[row['year'] as String] = (row['count'] as num).toInt();
    }
    return stats;
  }
  
  Future<Map<String, int>> _getSourceStats(Database db) async {
    final result = await db.rawQuery('''
      SELECT source, COUNT(*) as count
      FROM questions
      WHERE source IS NOT NULL AND source != ''
      GROUP BY source
      ORDER BY count DESC
      LIMIT 20
    ''');
    final stats = <String, int>{};
    for (final row in result) {
      stats[row['source'] as String] = (row['count'] as num).toInt();
    }
    return stats;
  }
  
  Future<int> _getQuestionCount(Database db) async {
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM questions');
    return Sqflite.firstIntValue(result) ?? 0;
  }
  
  Future<Map<String, Map<String, dynamic>>> _calculateErrorStats(Database db) async {
    final result = await db.rawQuery('''
      SELECT 
        subject,
        SUM(CASE WHEN content_error = 1 THEN 1 ELSE 0 END) as conteudo,
        SUM(CASE WHEN attention_error = 1 THEN 1 ELSE 0 END) as atencao,
        SUM(CASE WHEN time_error = 1 THEN 1 ELSE 0 END) as tempo,
        COUNT(*) as total
      FROM questions 
      GROUP BY subject
    ''');
    
    final errorStats = <String, Map<String, dynamic>>{};
    for (final row in result) {
      final subject = row['subject'] as String;
      errorStats[subject] = {
        'total': (row['total'] as num).toInt(),
        'conteudo': (row['conteudo'] as num).toInt(),
        'atencao': (row['atencao'] as num).toInt(),
        'tempo': (row['tempo'] as num).toInt(),
      };
    }
    return errorStats;
  }

  // Função para fechar o banco de dados
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    _invalidateCaches();
  }
  
  void _invalidateCaches() {
    _statsCache.clear();
    _statsCacheTime = null;
    _questionsCache.clear();
    _questionsCacheTime.clear();
  }
}