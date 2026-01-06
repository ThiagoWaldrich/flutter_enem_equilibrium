import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/question.dart';

class DatabaseService {
  static Database? _database;
  // 1. Para autodiagnostico_screen.dart e monthly_goals_service.dart
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
      // Converte o valor para int
      stats[row['subject'] as String] = (row['count'] as num).toInt();
    }
    return stats;
  }

// 2. Para autodiagnostico_screen.dart
  Future<int> getQuestionCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM questions');
    // Usa Sqflite.firstIntValue para extrair o valor corretamente
    return Sqflite.firstIntValue(result) ?? 0;
  }

// 3. Para autodiagnostico_screen.dart
  Future<int> deleteQuestions(List<String> ids) async {
    final db = await database;
    final placeholders = List.filled(ids.length, '?').join(',');
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
      version: 2, // Aumente a versão para 2
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // Adicione a migração
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
        year TEXT,          -- NOVO CAMPO
        source TEXT,        -- NOVO CAMPO
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
    await db.execute('CREATE INDEX idx_year ON questions(year)'); // NOVO
    await db.execute('CREATE INDEX idx_source ON questions(source)'); // NOVO
  }

  // Função de migração da versão 1 para 2
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        // Adicionar novas colunas
        await db.execute('ALTER TABLE questions ADD COLUMN year TEXT');
        await db.execute('ALTER TABLE questions ADD COLUMN source TEXT');

        // Se existir a coluna description, manter para compatibilidade
        // Se não existir, criar (alguns sistemas podem não ter)
        try {
          await db.execute('SELECT description FROM questions LIMIT 1');
        } catch (e) {
          // Coluna não existe, criar
          await db.execute('ALTER TABLE questions ADD COLUMN description TEXT');
        }

        // Criar novos índices
        await db
            .execute('CREATE INDEX IF NOT EXISTS idx_year ON questions(year)');
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_source ON questions(source)');

        print(
            '✅ Migração da versão $oldVersion para $newVersion concluída com sucesso!');
      } catch (e) {
        print('⚠️ Erro na migração: $e');
        // Continua mesmo com erro
      }
    }
  }

  // Atualize a função insertQuestion para incluir os novos campos
  Future<int> insertQuestion(Question question) async {
    final db = await database;

    final map = {
      'id': question.id,
      'subject': question.subject,
      'topic': question.topic,
      'subtopic': question.subtopic, // Mantido para compatibilidade
      'year': question.year, // NOVO
      'source': question.source, // NOVO
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

  // Atualize a função _questionFromMap para incluir os novos campos
  Question _questionFromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'],
      subject: map['subject'],
      topic: map['topic'],
      subtopic: map['subtopic'], // Mantido para compatibilidade
      year: map['year'], // NOVO
      source: map['source'], // NOVO
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

  // Adicione funções para obter estatísticas dos novos campos
  Future<Map<String, int>> getYearStats() async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT year, COUNT(*) as count
      FROM questions
      WHERE year IS NOT NULL AND year != ''
      GROUP BY year
      ORDER BY year DESC
    ''');

    final stats = <String, int>{};
    for (final row in result) {
      stats[row['year'] as String] = row['count'] as int;
    }

    return stats;
  }

  Future<Map<String, int>> getSourceStats() async {
    final db = await database;

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
      stats[row['source'] as String] = row['count'] as int;
    }

    return stats;
  }

  // Adicione funções para obter valores distintos
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

  // Atualize a função updateQuestion para os novos campos
  Future<int> updateQuestion(Question question) async {
    final db = await database;

    final map = {
      'subject': question.subject,
      'topic': question.topic,
      'subtopic': question.subtopic,
      'year': question.year, // NOVO
      'source': question.source, // NOVO
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

  // ... resto das funções existentes mantidas
  Future<List<Question>> getQuestions({
    int limit = 100,
    int offset = 0,
    String? subject,
    String? year, // NOVO parâmetro
    String? source, // NOVO parâmetro
  }) async {
    final db = await database;

    String query = 'SELECT * FROM questions WHERE 1=1';
    List<dynamic> args = [];

    if (subject != null && subject.isNotEmpty) {
      query += ' AND subject = ?';
      args.add(subject);
    }

    if (year != null && year.isNotEmpty) {
      query += ' AND year = ?';
      args.add(year);
    }

    if (source != null && source.isNotEmpty) {
      query += ' AND source = ?';
      args.add(source);
    }

    query += ' ORDER BY timestamp DESC LIMIT ? OFFSET ?';
    args.addAll([limit, offset]);

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, args);

    return maps.map((map) => _questionFromMap(map)).toList();
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
