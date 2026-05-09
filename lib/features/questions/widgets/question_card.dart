import 'dart:io';
import 'package:flutter/material.dart';
import '../models/question.dart';
import '../../core/theme/theme.dart';

class QuestionCard extends StatelessWidget {
  final Question question;
  final bool showImage;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool compact;
  final bool showThumbnail;

  const QuestionCard({
    super.key,
    required this.question,
    this.showImage = true,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.compact = false,
    this.showThumbnail = true,
  });

  @override
  Widget build(BuildContext context) {
    final errorTypes = question.errorTypes.map((e) => e.displayName).toList();
    final hasImage = question.image != null && showImage;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasImage && !compact)
              InkWell(
                onTap: () => _showImageDialog(context),
                child: Container(
                  width: double.infinity,
                  height: 160,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                    color: Color(0xFFF5F5F5),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                    child: _buildImage(fit: BoxFit.cover, cacheSize: 400),
                  ),
                ),
              ),
            
            Padding(
              padding: compact 
                  ? const EdgeInsets.fromLTRB(12, 10, 12, 10)
                  : const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (compact && showThumbnail && hasImage)
                    GestureDetector(
                      onTap: () => _showImageDialog(context),
                      child: Container(
                        width: 45,
                        height: 45,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[100],
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildImage(fit: BoxFit.cover, cacheSize: 100),
                        ),
                      ),
                    ),
                  
                  if (compact && !(showThumbnail && hasImage))
                    Container(
                      width: 3,
                      height: 36,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.getSubjectColor(question.subject),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              question.subject,
                              style: TextStyle(
                                fontSize: compact ? 10 : 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (errorTypes.isNotEmpty && compact)
                              ...errorTypes.take(2).map((type) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                margin: const EdgeInsets.only(right: 4),
                                decoration: BoxDecoration(
                                  color: _getErrorColor(type).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  type,
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: _getErrorColor(type),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              )),
                            if (errorTypes.length > 2 && compact)
                              Text(
                                '+${errorTypes.length - 2}',
                                style: TextStyle(fontSize: 8, color: Colors.grey[500]),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          question.topic,
                          style: TextStyle(
                            fontSize: compact ? 13 : 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (question.subtopic != null && question.subtopic!.isNotEmpty)
                          Text(
                            question.subtopic!,
                            style: TextStyle(
                              fontSize: compact ? 10 : 12,
                              color: Colors.grey[500],
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (!compact && question.errorDescription != null && question.errorDescription!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF9E6),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                question.errorDescription!,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF595959)),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onEdit != null)
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: onEdit,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                        ),
                      if (onDelete != null)
                        IconButton(
                          icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                          onPressed: onDelete,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                        ),
                      if (hasImage && !compact)
                        IconButton(
                          icon: const Icon(Icons.image, size: 18, color: Colors.blue),
                          onPressed: () => _showImageDialog(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            
            if (!compact)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDate(question.timestamp),
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getErrorColor(String errorType) {
    switch (errorType) {
      case 'Conteúdo': return Colors.red;
      case 'Atenção': return Colors.orange;
      case 'Tempo': return Colors.blue;
      default: return Colors.grey;
    }
  }

  Widget _buildImage({required BoxFit fit, required int cacheSize}) {
    final file = File(question.image!.filePath);
    if (!file.existsSync()) return _imageError();

    return Image.file(
      file,
      fit: fit,
      cacheWidth: cacheSize,
      cacheHeight: cacheSize,
      errorBuilder: (_, __, ___) => _imageError(),
    );
  }

  void _showImageDialog(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

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
                  maxWidth: size.width * 0.9,
                  maxHeight: size.height * 0.9,
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
                    child: _buildImage(fit: BoxFit.contain, cacheSize: 1200),
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

  Widget _imageError() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 24, color: Colors.grey),
            SizedBox(height: 4),
            Text(
              'Erro',
              style: TextStyle(fontSize: 9, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime timestamp) {
    return '${timestamp.day.toString().padLeft(2, '0')}/'
        '${timestamp.month.toString().padLeft(2, '0')}/'
        '${timestamp.year}';
  }
}