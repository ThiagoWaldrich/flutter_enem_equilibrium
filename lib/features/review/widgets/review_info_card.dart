import 'package:equilibrium/features/core/theme/theme.dart';
import 'package:equilibrium/features/questions/models/question.dart';
import 'package:flutter/material.dart';
import '../../core/services/database_service.dart';  

class ReviewInfoCard extends StatelessWidget {
  final Question question;
  final Function(Question) onUpdate;

  const ReviewInfoCard({
    super.key,
    required this.question,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.info,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '📋 INFORMAÇÕES DO TÓPICO',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildInfoRow('Matéria', question.subject),
          const SizedBox(height: 8),
          
          _buildInfoRow('Tópico', question.topic),
          const SizedBox(height: 8),
          
          if (question.subtopic != null && question.subtopic!.isNotEmpty)
            _buildInfoRow('Subtópico', question.subtopic!),
          const SizedBox(height: 8),
          
          if (question.year != null && question.year!.isNotEmpty)
            _buildInfoRow('Ano', question.year!),
          
          const Divider(height: 24),
          
          if (question.errorDescription != null && question.errorDescription!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📝 Análise do Erro:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    question.errorDescription!,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 16),
          
          if (question.errorTypes.isNotEmpty)
            Wrap(
              spacing: 8,
              children: question.errorTypes.map((type) {
                Color color;
                switch (type) {
                  case ErrorType.conteudo:
                    color = Colors.red;
                    break;
                  case ErrorType.atencao:
                    color = Colors.orange;
                    break;
                  case ErrorType.tempo:
                    color = Colors.blue;
                    break;
                }
                return Chip(
                  label: Text(type.displayName),
                  backgroundColor: color.withValues(alpha: 0.1),
                  labelStyle: TextStyle(color: color),
                  avatar: Icon(
                    type == ErrorType.conteudo ? Icons.menu_book :
                    type == ErrorType.atencao ? Icons.visibility_off :
                    Icons.access_time,
                    size: 14,
                    color: color,
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}