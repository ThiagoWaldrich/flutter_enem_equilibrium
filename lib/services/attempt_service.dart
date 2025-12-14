import 'package:supabase_flutter/supabase_flutter.dart';

class AttemptService {
  final supabase = Supabase.instance.client;
  
  Future<void> registerAttempt({
    required String userId,
    required String questionId,
    required String correctAnswer,
    String? userAnswer,
    required int timeSpentSeconds,
    String? sessionId,
    String studyMode = 'practice',
  }) async {
    // Determinar status
    String status;
    if (userAnswer == null) {
      status = 'skipped';
    } else if (userAnswer == correctAnswer) {
      status = 'correct';
    } else {
      status = 'wrong';
    }
    
    try {
      // Inserir tentativa
      await supabase.from('user_attempts').insert({
        'user_id': userId,
        'question_id': questionId,
        'user_answer': userAnswer,
        'status': status,
        'time_spent_seconds': timeSpentSeconds,
        'session_id': sessionId,
        'study_mode': studyMode,
      });
      
      // Atualizar estatísticas (via trigger ou função)
      await _updateUserStatistics(userId, questionId, status, timeSpentSeconds);
      
      print('✅ Tentativa registrada!');
    } catch (e) {
      print('❌ Erro ao registrar tentativa: $e');
    }
  }
  
  Future<void> _updateUserStatistics(
    String userId,
    String questionId,
    String status,
    int timeSpent,
  ) async {
    // Buscar dados da questão
    final question = await supabase
        .from('questions')
        .select('subject_id, topic_id')
        .eq('id', questionId)
        .single();
    
    // Atualizar ou criar estatística
    await supabase.rpc('upsert_user_statistics', params: {
      'p_user_id': userId,
      'p_subject_id': question['subject_id'],
      'p_topic_id': question['topic_id'],
      'p_status': status,
      'p_time_spent': timeSpent,
    });
  }
}