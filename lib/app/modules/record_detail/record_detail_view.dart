import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/problem_attempt.dart';
import '../../shared/date_format.dart';
import 'record_detail_controller.dart';

class RecordDetailView extends GetView<RecordDetailController> {
  const RecordDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final r = controller.record;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '문제 상세',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${r.type.label} 레벨 ${r.level}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatRecordDate(r.finishedAt),
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _Pill(
                        label: '맞음',
                        value: r.correctCount,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      _Pill(
                        label: '틀림',
                        value: r.wrongCount,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      _Pill(
                        label: '미풀이',
                        value: r.unsolvedCount,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '소요 ${formatElapsedSeconds(r.elapsedSeconds)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < r.attempts.length; i++) ...[
            _AttemptTile(index: i + 1, attempt: r.attempts[i]),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(label, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }
}

class _AttemptTile extends StatelessWidget {
  const _AttemptTile({required this.index, required this.attempt});

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
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
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
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              children: [
                Icon(icon, color: color, size: 28),
                Text(
                  statusLabel,
                  style: TextStyle(fontSize: 12, color: color),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
