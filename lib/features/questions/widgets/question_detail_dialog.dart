import 'dart:io';
import 'package:flutter/material.dart';
import 'package:equilibrium/features/questions/models/question.dart';

class QuestionDetailDialog extends StatelessWidget {
  final Question question;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const QuestionDetailDialog({
    super.key,
    required this.question,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(question.subject),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tópico: ${question.topic}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (question.subtopic != null)
              Text('Subtópico: ${question.subtopic}'),
            if (question.year != null) Text('Ano: ${question.year}'),
            if (question.source != null) Text('Fonte: ${question.source}'),
            const SizedBox(height: 16),
            if (question.errorDescription != null) ...[
              const Text(
                'Análise do Erro:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(question.errorDescription!),
              const SizedBox(height: 16),
            ],
            const Text(
              'Tipos de Erro:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            Wrap(
              spacing: 8,
              children: [
                if (question.errorTypes.contains(ErrorType.conteudo))
                  Chip(
                    label: const Text('Conteúdo'),
                    backgroundColor: Colors.red.withValues(alpha: 0.1),
                  ),
                if (question.errorTypes.contains(ErrorType.atencao))
                  Chip(
                    label: const Text('Atenção'),
                    backgroundColor: Colors.orange.withValues(alpha: 0.1),
                  ),
                if (question.errorTypes.contains(ErrorType.tempo))
                  Chip(
                    label: const Text('Tempo'),
                    backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  ),
              ],
            ),
            if (question.image != null) ...[
              const SizedBox(height: 16),
              const Text(
                'Imagem:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _QuestionImage(filePath: question.image!.filePath),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
        if (onEdit != null)
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onEdit!();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Editar'),
          ),
        if (onDelete != null)
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete!();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
      ],
    );
  }
}

class _QuestionImage extends StatelessWidget {
  final String filePath;

  const _QuestionImage({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    final file = File(filePath);
    final exists = filePath.isNotEmpty && file.existsSync();

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: exists
            ? Image.file(
                file,
                fit: BoxFit.cover,
                cacheHeight: 400,
                errorBuilder: (_, __, ___) => const _BrokenImagePlaceholder(),
              )
            : const _BrokenImagePlaceholder(),
      ),
    );
  }
}

class _BrokenImagePlaceholder extends StatelessWidget {
  const _BrokenImagePlaceholder();

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
}