import 'package:flutter/material.dart';
import '../models/question.dart';
import 'question_card.dart';

class QuestionsGridView extends StatelessWidget {
  final List<Question> questions;

  const QuestionsGridView({
    super.key,
    required this.questions,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 1;

        if (constraints.maxWidth >= 1800) {
          crossAxisCount = 5;
        } else if (constraints.maxWidth >= 1400) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth >= 1100) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth >= 700) {
          crossAxisCount = 2;
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemCount: questions.length,
          itemBuilder: (context, index) {
            return QuestionCard(
              key: ValueKey(questions[index].id),
              question: questions[index],
            );
          },
        );
      },
    );
  }
}
