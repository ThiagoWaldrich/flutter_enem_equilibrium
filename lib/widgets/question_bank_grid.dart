import 'package:flutter/material.dart';
import '../utils/theme.dart';
class QuestionBankGrid extends StatelessWidget {
  final List<Map<String, dynamic>> questions;
  final Function(Map<String, dynamic> question) onQuestionTap;
  final Function(Map<String, dynamic> question)? onEditTap;
  final Function(Map<String, dynamic> question)? onDeleteTap;
  final Function(Map<String, dynamic> question)? onAddToTestTap;

  const QuestionBankGrid({
    super.key,
    required this.questions,
    required this.onQuestionTap,
    this.onEditTap,
    this.onDeleteTap,
    this.onAddToTestTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85, // Mais quadrado como no autodiagnóstico
      ),
      padding: const EdgeInsets.all(12),
      itemCount: questions.length,
      itemBuilder: (context, index) {
        return _buildQuestionCard(context, questions[index], index);
      },
    );
  }

  Widget _buildQuestionCard(BuildContext context, Map<String, dynamic> question, int index) {
    final subject = question['subject'] as Map<String, dynamic>?;
    final topic = question['topic'] as Map<String, dynamic>?;
    final source = question['source'] as Map<String, dynamic>?;
    final statement = question['statement']?.toString() ?? 'Sem enunciado';
    final contextText = question['context']?.toString() ?? '';
    final imageUrl = _getImageUrl(question['image_url']);
    final questionNumber = question['question_number'] ?? (index + 1);
    final difficulty = question['difficulty_level'] ?? 3;
    final correctAnswer = question['correct_answer']?.toString() ?? '';
    final createdAt = question['created_at']?.toString() ?? '';

    final subjectName = subject?['name'] ?? 'Sem matéria';
    final topicName = topic?['name'] ?? '';
    final sourceName = source?['name'] ?? '';
    final sourceYear = source?['year'];
    
    Color subjectColor = _getSubjectColor(subjectName);
    
    return GestureDetector(
      onTap: () => onQuestionTap(question),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho - SIMILAR AO AUTODIAGNÓSTICO
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: subjectColor.withOpacity(0.08),
                border: Border(
                  bottom: BorderSide(
                    color: subjectColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Indicador colorido à esquerda (igual no autodiagnóstico)
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: subjectColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Linha superior com matéria
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                subjectName,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: subjectColor,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Badge de dificuldade
                            _buildDifficultyBadge(difficulty),
                          ],
                        ),
                        
                        // Tópico
                        if (topicName.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              topicName,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                                height: 1.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Corpo da questão
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Enunciado - estilo compacto
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Texto da questão
                            if (statement.isNotEmpty && statement != 'Sem enunciado')
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  statement,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.5,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            
                            // Contexto (se houver)
                            if (contextText.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.all(8),
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.grey[200]!,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Contexto:',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      contextText,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[800],
                                        height: 1.4,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            
                            // Informações adicionais em badges
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                // Resposta correta
                                if (correctAnswer.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.green.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          size: 12,
                                          color: Colors.green[700],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Resp: $correctAnswer',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.green[700],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                
                                // Fonte
                                if (sourceName.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.blue.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.source,
                                          size: 12,
                                          color: Colors.blue[700],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          sourceYear != null ? '$sourceName $sourceYear' : sourceName,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.blue[700],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                
                                // Imagem
                                if (imageUrl != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.purple.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.image,
                                          size: 12,
                                          color: Colors.purple[700],
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          'Imagem',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.purple,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Footer - Data e botões de ação
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Data
                          if (createdAt.isNotEmpty)
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 12,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDate(createdAt),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          
                          // Botões de ação (como no autodiagnóstico)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Botão de menu popup (substitui os ícones individuais)
                              PopupMenuButton<String>(
                                icon: Icon(
                                  Icons.more_vert,
                                  color: Colors.grey[600],
                                  size: 18,
                                ),
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'view',
                                    child: Row(
                                      children: [
                                        Icon(Icons.visibility, size: 16, color: AppTheme.infoColor),
                                        const SizedBox(width: 8),
                                        const Text('Ver Detalhes'),
                                      ],
                                    ),
                                  ),
                                  if (onEditTap != null)
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, size: 16, color: Colors.blue),
                                          const SizedBox(width: 8),
                                          const Text('Editar'),
                                        ],
                                      ),
                                    ),
                                  if (onAddToTestTap != null)
                                    PopupMenuItem(
                                      value: 'add_to_test',
                                      child: Row(
                                        children: [
                                          Icon(Icons.add_circle, size: 16, color: Colors.green),
                                          const SizedBox(width: 8),
                                          const Text('Adicionar ao simulado'),
                                        ],
                                      ),
                                    ),
                                  if (onDeleteTap != null)
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, size: 16, color: Colors.red),
                                          const SizedBox(width: 8),
                                          const Text('Excluir'),
                                        ],
                                      ),
                                    ),
                                ],
                                onSelected: (value) {
                                  switch (value) {
                                    case 'view':
                                      onQuestionTap(question);
                                      break;
                                    case 'edit':
                                      onEditTap?.call(question);
                                      break;
                                    case 'delete':
                                      onDeleteTap?.call(question);
                                      break;
                                    case 'add_to_test':
                                      onAddToTestTap?.call(question);
                                      break;
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyBadge(int difficulty) {
    Color color;
    String label;
    
    switch (difficulty) {
      case 1:
        color = Colors.green;
        label = 'Fácil';
        break;
      case 2:
        color = Colors.lightGreen;
        label = 'Médio';
        break;
      case 3:
        color = Colors.amber;
        label = 'Médio';
        break;
      case 4:
        color = Colors.orange;
        label = 'Difícil';
        break;
      case 5:
        color = Colors.red;
        label = 'Muito Difícil';
        break;
      default:
        color = Colors.grey;
        label = 'N/A';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getSubjectColor(String subjectName) {
    final lowerName = subjectName.toLowerCase();
    if (lowerName.contains('biologia')) {
      return const Color(0xFF4CAF50);
    } else if (lowerName.contains('física')) {
      return const Color(0xFF2196F3);
    } else if (lowerName.contains('química')) {
      return const Color(0xFF9C27B0);
    } else if (lowerName.contains('matemática')) {
      return const Color(0xFFF44336);
    } else if (lowerName.contains('português') || lowerName.contains('literatura')) {
      return const Color(0xFFFF9800);
    } else if (lowerName.contains('história')) {
      return const Color(0xFF795548);
    } else if (lowerName.contains('geografia')) {
      return const Color(0xFF009688);
    } else if (lowerName.contains('filosofia')) {
      return const Color(0xFF607D8B);
    } else if (lowerName.contains('sociologia')) {
      return const Color(0xFF9E9E9E);
    } else if (lowerName.contains('inglês') || lowerName.contains('espanhol')) {
      return const Color(0xFF3F51B5);
    } else {
      return AppTheme.primaryColor;
    }
  }

  void _showImagePreview(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 300,
                        height: 300,
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 300,
                        height: 300,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image,
                                size: 50,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Erro ao carregar imagem',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String? _getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return null;

    if (imagePath.startsWith('http')) {
      return imagePath;
    }

  }
}