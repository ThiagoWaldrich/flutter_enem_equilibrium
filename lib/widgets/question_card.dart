import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // ADICIONADO
import 'dart:convert';
import '../models/question.dart';
import '../utils/theme.dart';

class QuestionCard extends StatelessWidget {
  final Question question;
  final bool showImage;

const QuestionCard({
  super.key,
  required this.question,
  this.showImage = true,
});

  @override
  Widget build(BuildContext context) {
    final errorTypes = question.errors.entries
        .where((e) => e.value)
        .map((e) => _getErrorLabel(e.key))
        .toList();

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagem (se houver e showImage for true)
          if (question.image != null && showImage)
            _buildImageSection(context),
          
          // Conteúdo
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tópico/Subtópico
                  Text(
                    question.topic,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1890FF),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  if (question.subtopic != null && question.subtopic!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        question.subtopic!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  
                  const SizedBox(height: 12),
                  
                  // Descrição da questão
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
          
                            Container(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Questão:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                ],
                              ),
                            ),
                          
                          // Análise do Erro
                          if (question.errorDescription != null && 
                              question.errorDescription!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF9E6),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFFFFE58F),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                question.errorDescription!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  height: 1.5,
                                  color: Color(0xFF595959),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Footer com tags e data
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tags de erro
                      if (errorTypes.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: errorTypes.map((type) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                type,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      
                      const SizedBox(height: 8),
                      
                      // Data e botão ver imagem
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDate(question.timestamp),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                          
                          if (question.image != null)
                            InkWell(
                              onTap: () => _showImageDialog(context),
                              child: const Text(
                                'Ver imagem',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.successColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    return InkWell(
      onTap: () => _showImageDialog(context),
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
          color: Colors.grey[100],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
          child: _buildImage(),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (question.image == null) return const SizedBox.shrink();

    try {
      String base64String = question.image!.data;
      if (base64String.contains(',')) {
        base64String = base64String.split(',')[1];
      }
      
      final bytes = base64Decode(base64String);
      return kIsWeb // ADICIONADO: Condicional para web
          ? Image.memory(
              bytes,
              fit: BoxFit.cover,
            )
          : Image.memory(
              bytes,
              cacheWidth: 300, // ADICIONADO: Cache otimizado
              cacheHeight: 300, // ADICIONADO: Cache otimizado
              fit: BoxFit.cover,
            );
    } catch (e) {
      return Container(
        color: Colors.grey[200],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 40, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'Erro ao carregar imagem',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _showImageDialog(BuildContext context) {
    if (question.image == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: _buildImageForDialog(),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 24),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageForDialog() {
    try {
      String base64String = question.image!.data;
      if (base64String.contains(',')) {
        base64String = base64String.split(',')[1];
      }
      
      final bytes = base64Decode(base64String);
      return kIsWeb // ADICIONADO: Condicional para web
          ? Image.memory(
              bytes,
              fit: BoxFit.contain,
            )
          : Image.memory(
              bytes,
              cacheWidth: 800, // ADICIONADO: Cache otimizado para tela cheia
              cacheHeight: 800, // ADICIONADO: Cache otimizado para tela cheia
              fit: BoxFit.contain,
            );
    } catch (e) {
      return Container(
        width: 300,
        height: 300,
        color: Colors.grey[300],
        child: const Center(
          child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
        ),
      );
    }
  }

  String _getErrorLabel(String key) {
    switch (key) {
      case 'conteudo':
        return 'Conteudo';
      case 'atencao':
        return 'Atencao';
      case 'tempo':
        return 'Tempo';
      default:
        return key;
    }
  }

  String _formatDate(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return timestamp;
    }
  }
}