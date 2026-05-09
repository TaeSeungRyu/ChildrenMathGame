import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/problem_attempt.dart';
import '../../routes/app_routes.dart';
import '../../shared/attempt_tile.dart';
import '../../shared/date_format.dart';
import 'record_detail_controller.dart';

class RecordDetailView extends GetView<RecordDetailController> {
  const RecordDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final r = controller.record;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final reviewable = r.attempts
        .where((a) => a.status != AttemptStatus.correct)
        .toList();
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
          if (reviewable.isNotEmpty) ...[
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => Get.toNamed(
                  AppRoutes.review,
                  arguments: reviewable,
                ),
                icon: const Icon(Icons.refresh, size: 20),
                label: Text(
                  '틀린 문제 다시 풀기 (${reviewable.length})',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          for (var i = 0; i < r.attempts.length; i++) ...[
            AttemptTile(index: i + 1, attempt: r.attempts[i]),
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

