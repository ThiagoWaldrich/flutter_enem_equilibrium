import 'package:flutter/material.dart';
import '../models/priority_item_model.dart';
import '../../../features/questions/models/question.dart';

class PriorityCardWidget extends StatelessWidget {
  final PriorityItem item;
  final VoidCallback onTap;

  const PriorityCardWidget({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final mainErrorType = _getMainErrorType();
    final mainErrorColor = _getErrorColor(mainErrorType);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Matéria e total de erros
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: mainErrorColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.subject,
                          style: TextStyle(
                            fontSize: 12,
                            color: mainErrorColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: mainErrorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${item.totalErrorCount} erro${item.totalErrorCount != 1 ? 's' : ''}',
                      style: TextStyle(
                        color: mainErrorColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Badges de tipos de erro
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: item.errorsByType.entries.map((entry) {
                  final errorType = entry.key;
                  final count = entry.value;
                  final color = _getErrorColor(errorType);
                  
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getErrorIcon(errorType),
                          size: 14,
                          color: color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${errorType.displayName}: $count',
                          style: TextStyle(
                            fontSize: 11,
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              
              if (item.questions.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.quiz, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      '${item.questions.length} questão${item.questions.length != 1 ? 'ões' : ''} com erro',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  ErrorType _getMainErrorType() {
    return item.errorsByType.entries.reduce(
      (a, b) => a.value > b.value ? a : b
    ).key;
  }

  Color _getErrorColor(ErrorType type) {
    switch (type) {
      case ErrorType.conteudo:
        return Colors.red;
      case ErrorType.atencao:
        return Colors.orange;
      case ErrorType.tempo:
        return Colors.blue;
    }
  }

  IconData _getErrorIcon(ErrorType type) {
    switch (type) {
      case ErrorType.conteudo:
        return Icons.menu_book;
      case ErrorType.atencao:
        return Icons.visibility_off;
      case ErrorType.tempo:
        return Icons.access_time;
    }
  }
}