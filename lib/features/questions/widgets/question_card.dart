import 'dart:io';

import 'package:flutter/material.dart';
import '../models/question.dart';
import '../../core/theme/theme.dart';

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
    final errorTypes = question.errorTypes
        .map((e) => e.displayName)
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
        mainAxisSize: MainAxisSize.min,
        children: [
          // Imagem
          if (question.image != null && showImage)
            _buildImageSection(context),

          // Conteúdo
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tópico
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

                // Subtópico
                if (question.subtopic != null &&
                    question.subtopic!.isNotEmpty)
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

                // Descrição
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

                const SizedBox(height: 12),

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

                // Rodapé
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
          ),
        ],
      ),
    );
  }

  // ---------------- IMAGEM ----------------

  Widget _buildImageSection(BuildContext context) {
    return InkWell(
      onTap: () => _showImageDialog(context),
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
          color: Color(0xFFF5F5F5),
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

    final file = File(question.image!.filePath);

    if (!file.existsSync()) {
      return _imageError();
    }

    return Image.file(
      file,
      fit: BoxFit.cover,
      cacheWidth: 300,
      cacheHeight: 300,
    );
  }

  void _showImageDialog(BuildContext context) {
    if (question.image == null) return;

    showDialog(
      context: context,
      builder: (_) => Dialog(
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
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
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
    final file = File(question.image!.filePath);

    if (!file.existsSync()) {
      return _imageError();
    }

    return Image.file(
      file,
      fit: BoxFit.contain,
      cacheWidth: 800,
      cacheHeight: 800,
    );
  }

  Widget _imageError() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(
          Icons.broken_image,
          size: 40,
          color: Colors.grey,
        ),
      ),
    );
  }


  String _formatDate(DateTime timestamp) {
    return '${timestamp.day.toString().padLeft(2, '0')}/'
           '${timestamp.month.toString().padLeft(2, '0')}/'
           '${timestamp.year}';
  }
}
