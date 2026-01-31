import 'package:flutter/material.dart';
import '../models/question.dart';
import 'question_card.dart';

class QuestionsGridView extends StatelessWidget {
  final List<Question> questions;
  final void Function(Question) onQuestionTap;
  final void Function(Question)? onEditQuestion;
  final void Function(Question)? onDeleteQuestion;

  const QuestionsGridView({
    super.key,
    required this.questions,
    required this.onQuestionTap,
    this.onEditQuestion,
    this.onDeleteQuestion,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = switch (constraints.maxWidth) {
          >= 1800 => 5,
          >= 1400 => 4,
          >= 1100 => 3,
          >= 700 => 2,
          _ => 1,
        };

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemCount: questions.length,
          itemBuilder: (_, index) {
            final question = questions[index];

            return QuestionCard(
              key: ValueKey(question.id),
              question: question,
              onTap: () => onQuestionTap(question),
              onEdit:
                  onEditQuestion != null ? () => onEditQuestion!(question) : null,
              onDelete: onDeleteQuestion != null
                  ? () => onDeleteQuestion!(question)
                  : null,
            );
          },
        );
      },
    );
  }
}