import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class SupabaseService {
  static final supabase = Supabase.instance.client;

  // ========== AUTENTICAÇÃO ==========
  static User? get currentUser => supabase.auth.currentUser;
  static bool get isAuthenticated => currentUser != null;

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      print('✅ Login realizado com sucesso');
      return response;
    } catch (e) {
      print('❌ Erro no login: $e');
      rethrow;
    }
  }

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );
      print('✅ Cadastro realizado com sucesso');
      return response;
    } catch (e) {
      print('❌ Erro no cadastro: $e');
      rethrow;
    }
  }

  static Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
      print('✅ Logout realizado');
    } catch (e) {
      print('❌ Erro ao fazer logout: $e');
      rethrow;
    }
  }

  // ========== UPLOAD DE IMAGENS ==========
  static Future<String?> uploadQuestionImage({
    required File imageFile,
    required String sourceName,
    required String year,
    required int questionNumber,
  }) async {
    try {
      if (!isAuthenticated) {
        throw Exception('Usuário não autenticado');
      }

      final userId = currentUser!.id;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName =
          '${sourceName}_${year}_q${questionNumber.toString().padLeft(3, '0')}_${timestamp}_${userId.substring(0, 8)}.jpg';
      final path = '$sourceName/$year/$fileName';

      print('📤 Fazendo upload para: $path');

      await supabase.storage.from('question-images').upload(path, imageFile,
          fileOptions: FileOptions(
            cacheControl: '3600',
            upsert: false,
          ));

      final publicUrl =
          supabase.storage.from('question-images').getPublicUrl(path);

      print('✅ Upload concluído: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('❌ Erro no upload: $e');
      throw Exception('Falha no upload da imagem: $e');
    }
  }

  // ========== SUBJECTS ==========
  static Future<List<Map<String, dynamic>>> getSubjects() async {
    try {
      final response =
          await supabase.from('subjects').select().order('display_order');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Erro ao carregar matérias: $e');
      return [];
    }
  }

  // ========== TOPICS ==========
  // Adicione ou substitua este método no seu arquivo supabase_service.dart

  static Future<List<Map<String, dynamic>>> getTopicsBySubject(
      String subjectId) async {
    try {
      print('🔍 [DEBUG] Buscando tópicos para subjectId: $subjectId');
      print('🔍 [DEBUG] Tipo do subjectId: ${subjectId.runtimeType}');

      // Verifique se o subjectId é válido
      if (subjectId.isEmpty) {
        print('❌ [DEBUG] subjectId está vazio');
        return [];
      }

      // Primeiro, verifique se o subject existe
      final subjectCheck = await supabase
          .from('subjects')
          .select('id, name')
          .eq('id', subjectId)
          .maybeSingle();

      if (subjectCheck == null) {
        print('❌ [DEBUG] Matéria não encontrada no banco: $subjectId');
        return [];
      }

      print('✅ [DEBUG] Matéria encontrada: ${subjectCheck['name']}');

      // Agora busque os tópicos
      final response = await supabase
          .from('topics')
          .select()
          .eq('subject_id', subjectId)
          .order('display_order', ascending: true);

      print(
          '✅ [DEBUG] Query executada. ${response.length} tópicos encontrados');

      if (response.isEmpty) {
        print(
            'ℹ️ [DEBUG] Nenhum tópico encontrado para subject_id: $subjectId');

        // Vamos verificar se há tópicos na tabela de qualquer forma
        final allTopics = await supabase
            .from('topics')
            .select('id, name, subject_id')
            .limit(5);

        print('📋 [DEBUG] Primeiros tópicos na tabela:');
        for (var topic in allTopics) {
          print('   - ${topic['name']} (subject_id: ${topic['subject_id']})');
        }

        return [];
      }

      print('📋 [DEBUG] Tópicos encontrados:');
      for (var topic in response) {
        print(
            '   - ${topic['name']} (ID: ${topic['id']}, subject_id: ${topic['subject_id']})');
      }

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Erro ao carregar tópicos por matéria: $e');
      print('❌ Stack trace: ${e.toString()}');
      return [];
    }
  }

// Se você também tiver um método getTopics() geral, certifique-se de que ele está assim:
  static Future<List<Map<String, dynamic>>> getTopics() async {
    try {
      final response = await supabase
          .from('topics')
          .select('*')
          .order('subject_id')
          .order('display_order', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Erro ao carregar todos os tópicos: $e');
      return [];
    }
  }

// Método auxiliar para debug (opcional - pode remover depois)
  static Future<void> debugSubjectTopicRelation() async {
    try {
      print('\n🔍 === DEBUG: Relação Matérias x Tópicos ===\n');

      final subjects = await getSubjects();
      print('Total de matérias: ${subjects.length}');

      for (var subject in subjects) {
        print('\n📚 Matéria: ${subject['name']} (ID: ${subject['id']})');

        final topics = await getTopicsBySubject(subject['id']);

        if (topics.isEmpty) {
          print('   ⚠️ Nenhum tópico cadastrado');
        } else {
          print('   ✅ ${topics.length} tópico(s):');
          for (var topic in topics) {
            print('      - ${topic['name']}');
          }
        }
      }

      print('\n=== FIM DEBUG ===\n');
    } catch (e) {
      print('❌ Erro no debug: $e');
    }
  }

  // ========== FONTES E ANOS ==========
  static Future<List<Map<String, dynamic>>> getSources() async {
    try {
      final response =
          await supabase.from('question_sources').select().order('name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Erro ao carregar fontes: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getExamYears() async {
    try {
      final response = await supabase
          .from('exam_years')
          .select()
          .order('year', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Erro ao carregar anos: $e');
      return [];
    }
  }

  // ========== QUESTIONS ==========
  static Future<List<Map<String, dynamic>>> getQuestions({
    String? subjectId,
    String? topicId,
    String? sourceId,
    String? yearId,
    String? searchQuery,
    int limit = 1000,
    int from = 0,
  }) async {
    try {
      // Use !fk_subject para especificar qual relação usar
      var query = supabase.from('questions').select('''
      *,
      subject:subjects(id, name, color_hex),
      topic:topics(id, name),
      source:question_sources(id, name, type),
      year:exam_years(id, year)
    ''').eq('is_active', true);

      if (subjectId != null && subjectId.isNotEmpty) {
        query = query.eq('subject_id', subjectId);
      }

      if (topicId != null && topicId.isNotEmpty) {
        query = query.eq('topic_id', topicId);
      }

      if (sourceId != null && sourceId.isNotEmpty) {
        query = query.eq('source_id', sourceId);
      }

      if (yearId != null && yearId.isNotEmpty) {
        query = query.eq('year_id', yearId);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(from, from + limit - 1);

      var results = List<Map<String, dynamic>>.from(response);

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowerQuery = searchQuery.toLowerCase();
        results = results.where((q) {
          final subjectName =
              (q['subject']?['name'] ?? '').toString().toLowerCase();
          final topicName =
              (q['topic']?['name'] ?? '').toString().toLowerCase();
          final sourceName =
              (q['source']?['name'] ?? '').toString().toLowerCase();
          final year = (q['year']?['year'] ?? '').toString();

          return subjectName.contains(lowerQuery) ||
              topicName.contains(lowerQuery) ||
              sourceName.contains(lowerQuery) ||
              year.contains(lowerQuery);
        }).toList();
      }

      return results;
    } catch (e) {
      print('❌ Erro ao carregar questões: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getQuestionById(String id) async {
    try {
      final response = await supabase.from('questions').select('''
          *,
          subject:subjects!fk_subject(*),
          topic:topics(*),
          source:question_sources(*),
          year:exam_years(*)
        ''').eq('id', id).eq('is_active', true).single();

      return response;
    } catch (e) {
      print('❌ Erro ao carregar questão: $e');
      return null;
    }
  }

  // ========== CRUD QUESTIONS ==========
  static Future<void> addQuestion(Map<String, dynamic> questionData) async {
    print('🔍 [DEBUG] Iniciando addQuestion');
    print('🔍 [DEBUG] isAuthenticated: $isAuthenticated');
    print('🔍 [DEBUG] currentUser: $currentUser');
    print('🔍 [DEBUG] currentUser?.id: ${currentUser?.id}');
    try {
      if (!isAuthenticated) {
        throw Exception('Usuário não autenticado');
      }

      questionData['user_id'] = currentUser!.id;
      questionData['created_at'] = DateTime.now().toIso8601String();
      questionData['updated_at'] = DateTime.now().toIso8601String();
      questionData['is_active'] = true;

      if (questionData['year_id'] == null) {
        questionData.remove('year_id');
      }

      print('📝 Dados da questão antes de salvar:');
      print('   - user_id: ${questionData['user_id']}');
      print('   - subject_id: ${questionData['subject_id']}');
      print('   - topic_id: ${questionData['topic_id']}');
      print('   - source_id: ${questionData['source_id']}');
      print('   - correct_answer: ${questionData['correct_answer']}');

      final response =
          await supabase.from('questions').insert(questionData).select();

      print('✅ Questão adicionada com sucesso. ID: ${response[0]['id']}');
    } catch (e) {
      print('❌ Erro ao adicionar questão: $e');
      print('💡 Dados que causaram erro: $questionData');
      rethrow;
    }
  }

  static Future<void> updateQuestion(
      String id, Map<String, dynamic> updates) async {
    try {
      if (!isAuthenticated) {
        throw Exception('Usuário não autenticado');
      }

      updates['updated_at'] = DateTime.now().toIso8601String();

      await supabase
          .from('questions')
          .update(updates)
          .eq('id', id)
          .eq('user_id', currentUser!.id);

      print('✅ Questão atualizada: $id');
    } catch (e) {
      print('❌ Erro ao atualizar questão: $e');
      rethrow;
    }
  }

  static Future<void> deleteQuestion(String id) async {
    try {
      if (!isAuthenticated) {
        throw Exception('Usuário não autenticado');
      }

      await supabase
          .from('questions')
          .delete()
          .eq('id', id)
          .eq('user_id', currentUser!.id);

      print('✅ Questão excluída permanentemente: $id');
    } catch (e) {
      print('❌ Erro ao excluir questão: $e');
      rethrow;
    }
  }

  // ========== USER ATTEMPTS ==========
  static Future<void> saveAttempt(Map<String, dynamic> attemptData) async {
    try {
      if (!isAuthenticated) {
        throw Exception('Usuário não autenticado');
      }

      attemptData['user_id'] = currentUser!.id;
      attemptData['attempted_at'] = DateTime.now().toIso8601String();

      await supabase.from('user_attempts').insert(attemptData);

      print('✅ Tentativa registrada');
    } catch (e) {
      print('❌ Erro ao registrar tentativa: $e');
      rethrow;
    }
  }

  // ========== CONTAGEM ==========
  static Future<int> getQuestionCount({
    String? subjectId,
    String? topicId,
    String? sourceId,
    String? yearId,
  }) async {
    try {
      var query = supabase.from('questions').select().eq('is_active', true);

      if (subjectId != null && subjectId.isNotEmpty) {
        query = query.eq('subject_id', subjectId);
      }

      if (topicId != null && topicId.isNotEmpty) {
        query = query.eq('topic_id', topicId);
      }

      if (sourceId != null && sourceId.isNotEmpty) {
        query = query.eq('source_id', sourceId);
      }

      if (yearId != null && yearId.isNotEmpty) {
        query = query.eq('year_id', yearId);
      }

      final response = await query;
      return response.length;
    } catch (e) {
      print('❌ Erro ao contar questões: $e');
      return 0;
    }
  }

  // ========== VALIDAÇÃO DE SESSÃO ==========
  static Future<bool> validateSession() async {
    try {
      final session = supabase.auth.currentSession;
      return session != null;
    } catch (e) {
      print('❌ Erro ao validar sessão: $e');
      return false;
    }
  }

  // ========== ATUALIZAR SENHA ==========
  static Future<void> updatePassword(String newPassword) async {
    try {
      await supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      print('✅ Senha atualizada com sucesso');
    } catch (e) {
      print('❌ Erro ao atualizar senha: $e');
      rethrow;
    }
  }

  // ========== OBTER PERFIL DO USUÁRIO ==========
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      if (!isAuthenticated) {
        return null;
      }

      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', currentUser!.id)
          .single();

      return response;
    } catch (e) {
      print('❌ Erro ao obter perfil: $e');
      return null;
    }
  }

  // ========== ATUALIZAR PERFIL ==========
  static Future<void> updateUserProfile(
      Map<String, dynamic> profileData) async {
    try {
      if (!isAuthenticated) {
        throw Exception('Usuário não autenticado');
      }

      await supabase
          .from('profiles')
          .update(profileData)
          .eq('id', currentUser!.id);

      print('✅ Perfil atualizado com sucesso');
    } catch (e) {
      print('❌ Erro ao atualizar perfil: $e');
      rethrow;
    }
  }

  // ========== ESTATÍSTICAS DO USUÁRIO ==========
  static Future<Map<String, dynamic>> getUserStats() async {
    try {
      if (!isAuthenticated) {
        return {};
      }

      final userId = currentUser!.id;

      final questionsResponse = await supabase
          .from('questions')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true);

      final questionCount = questionsResponse.length;

      final attemptsResponse =
          await supabase.from('user_attempts').select().eq('user_id', userId);

      final attemptCount = attemptsResponse.length;

      String lastActivity = '';
      final lastActivityResponse = await supabase
          .from('questions')
          .select('created_at')
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(1);

      if (lastActivityResponse.isNotEmpty) {
        lastActivity = lastActivityResponse[0]['created_at'] as String;
      }

      double accuracy = 0.0;
      if (attemptCount > 0) {
        final correctAttemptsResponse = await supabase
            .from('user_attempts')
            .select()
            .eq('user_id', userId)
            .eq('is_correct', true);

        final correctCount = correctAttemptsResponse.length;
        accuracy = (correctCount / attemptCount) * 100;
      }

      return {
        'total_questions': questionCount,
        'total_attempts': attemptCount,
        'last_activity': lastActivity,
        'accuracy': accuracy,
      };
    } catch (e) {
      print('❌ Erro ao obter estatísticas do usuário: $e');
      return {};
    }
  }

  // No SupabaseService, adicione este método:
  static Future<void> debugAllTopicsAndSubjects() async {
    try {
      print('\n🔍 === DEBUG COMPLETO: Matérias e Tópicos ===\n');

      // Busca todas as matérias
      final subjects = await getSubjects();
      print('📚 Total de matérias: ${subjects.length}');

      for (var subject in subjects) {
        print('\n📚 Matéria: ${subject['name']} (ID: ${subject['id']})');

        // Busca tópicos usando a query direta
        final topics = await supabase
            .from('topics')
            .select('id, name, subject_id, display_order')
            .eq('subject_id', subject['id'])
            .order('display_order');

        print('   📝 Tópicos encontrados (query direta): ${topics.length}');

        for (var topic in topics) {
          print('      - ${topic['name']} (ID: ${topic['id']})');
        }

        if (topics.isEmpty) {
          print(
              '      ⚠️ Nenhum tópico encontrado com subject_id: ${subject['id']}');
        }
      }

      // Mostra todos os tópicos sem filtro
      print('\n🔍 Todos os tópicos na tabela:');
      final allTopics = await supabase
          .from('topics')
          .select('id, name, subject_id')
          .order('subject_id');

      for (var topic in allTopics) {
        final subjectId = topic['subject_id'];
        print('   - ${topic['name']} (subject_id: $subjectId)');
      }

      print('\n=== FIM DEBUG ===\n');
    } catch (e) {
      print('❌ Erro no debug completo: $e');
    }
  }
}
