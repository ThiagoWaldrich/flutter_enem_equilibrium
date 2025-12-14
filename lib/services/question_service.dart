import 'dart:io';

import 'package:equilibrium/services/supabase_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuestionService {
  final supabase = Supabase.instance.client;
  
  Future<void> insertQuestion({
    required String subjectId,
    required String topicId,
    required String sourceId,
    required String correctAnswer,
    String? statement,
    File? imageFile,
    int? questionNumber,
  }) async {
    try {
      // 1. Upload da imagem (se existir)
      String? imageUrl;
      if (imageFile != null) {
        final imageService = QuestionImageService();
        imageUrl = await imageService.uploadQuestionImage(
          imageFile: imageFile,
          source: 'custom',
          year: DateTime.now().year.toString(),
          questionNumber: questionNumber ?? DateTime.now().millisecondsSinceEpoch,
        );
      }
      
      // 2. Inserir questÃ£o no banco
      await supabase.from('questions').insert({
        'subject_id': subjectId,
        'topic_id': topicId,
        'source_id': sourceId,
        'statement': statement,
        'correct_answer': correctAnswer,
        'image_url': imageUrl,
        'question_number': questionNumber,
      });
      
      print('âœ… QuestÃ£o inserida com sucesso!');
    } catch (e) {
      print('Erro ao inserir questão: $e');
      rethrow;
    }
  }
}