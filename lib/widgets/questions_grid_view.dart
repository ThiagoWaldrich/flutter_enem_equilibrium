import 'package:flutter/material.dart';
import '../models/question.dart';
import '../utils/theme.dart';
import 'question_card.dart';

class QuestionsGridView extends StatefulWidget {
  final List<Question> questions;

const QuestionsGridView({
  super.key, 
  required this.questions,
});

  @override
  State<QuestionsGridView> createState() => _QuestionsGridViewState();
}

class _QuestionsGridViewState extends State<QuestionsGridView> {
  final Set<String> _expandedSubjects = {};

  @override
  Widget build(BuildContext context) {
    // Agrupar questões por matéria
    final questionsBySubject = <String, List<Question>>{};
    for (final question in widget.questions) {
      questionsBySubject.putIfAbsent(question.subject, () => []).add(question);
    }

    // Ordenar matérias por número de questões
    final sortedSubjects = questionsBySubject.keys.toList()
      ..sort((a, b) => questionsBySubject[b]!.length.compareTo(
          questionsBySubject[a]!.length));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedSubjects.length,
      itemBuilder: (context, index) {
        final subject = sortedSubjects[index];
        final questions = questionsBySubject[subject]!;
        final isExpanded = _expandedSubjects.contains(subject);
        final subjectColor = AppTheme.getSubjectColor(subject);

        return Container(
          key: ValueKey(subject), // ADICIONADO: Key única
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header expansível
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedSubjects.remove(subject);
                      } else {
                        _expandedSubjects.add(subject);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: subjectColor.withValues(alpha:0.08),
                      borderRadius: isExpanded
                          ? const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            )
                          : BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        // Indicador colorido
                        Container(
                          width: 4,
                          height: 32,
                          decoration: BoxDecoration(
                            color: subjectColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Nome da matéria
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                subject,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: subjectColor,
                                ),
                              ),
                              Text(
                                '${questions.length} questõe${questions.length != 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Ícone de expandir/colapsar
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: subjectColor,
                          size: 28,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Grid de questões (quando expandido)
              if (isExpanded)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Calcular número de colunas baseado na largura
                      int crossAxisCount = 1;
                      if (constraints.maxWidth > 1400) {
                        crossAxisCount = 4;
                      } else if (constraints.maxWidth > 1000) {
                        crossAxisCount = 3;
                      } else if (constraints.maxWidth > 600) {
                        crossAxisCount = 2;
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: questions.length,
                        itemBuilder: (context, index) {
                          return QuestionCard(
                            key: ValueKey(questions[index].id), // ADICIONADO: Key única
                            question: questions[index],
                          );
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}