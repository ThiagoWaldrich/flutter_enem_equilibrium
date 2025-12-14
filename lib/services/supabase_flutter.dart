import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class QuestionImageService {
  final supabase = Supabase.instance.client;
  
  /// Upload de imagem de questÃ£o
  Future<String?> uploadQuestionImage({
    required File imageFile,
    required String source, // 'enem', 'vestibular', etc.
    required String year,
    required int questionNumber,
  }) async {
    try {
      // Gerar nome Ãºnico
      final fileName = 'q${questionNumber.toString().padLeft(3, '0')}.jpg';
      final path = '$source/$year/$fileName';
      
      // Upload
      final response = await supabase.storage
          .from('question-images')
          .upload(
            path,
            imageFile,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );
      
      // Obter URL pÃºblica
      final publicUrl = supabase.storage
          .from('question-images')
          .getPublicUrl(path);
      
      return publicUrl;
    } catch (e) {
      print('Erro no upload: $e');
      return null;
    }
  }
  
  /// Upload de mÃºltiplas imagens
  Future<List<String>> uploadMultipleImages(
    List<File> images,
    String prefix,
  ) async {
    final urls = <String>[];
    
    for (var i = 0; i < images.length; i++) {
      final url = await uploadQuestionImage(
        imageFile: images[i],
        source: prefix,
        year: DateTime.now().year.toString(),
        questionNumber: i + 1,
      );
      
      if (url != null) urls.add(url);
    }
    
    return urls;
  }
}