import 'package:flutter/material.dart';

import '../data/models/problem_attempt.dart';

class AttemptTile extends StatelessWidget {
  const AttemptTile({super.key, required this.index, required this.attempt});

  final int index;
  final ProblemAttempt attempt;

  @override
  Widget build(BuildContext context) {
    final (color, icon, statusLabel) = switch (attempt.status) {
      AttemptStatus.correct => (Colors.green, Icons.check_circle, '맞음'),
      AttemptStatus.wrong => (Colors.red, Icons.cancel, '틀림'),
      AttemptStatus.unsolved => (Colors.grey, Icons.help_outline, '미풀이'),
    };
    final showUserAnswer = attempt.status == AttemptStatus.wrong;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                '$index.',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${attempt.questionText} = ${attempt.correctAnswer}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (showUserAnswer) ...[
                    const SizedBox(height: 4),
                    Text(
                      '내 답: ${attempt.userAnswer ?? '-'}',
                      style: const TextStyle(fontSize: 14, color: Colors.red),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              children: [
                Icon(icon, color: color, size: 28),
                Text(statusLabel, style: TextStyle(fontSize: 12, color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
