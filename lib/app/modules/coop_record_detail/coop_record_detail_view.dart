import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../shared/attempt_tile.dart';
import '../../shared/date_format.dart';
import 'coop_record_detail_controller.dart';

/// 함께 학습 한 판의 상세 — 푼 문제 목록 + "틀린 문제 다시풀기".
class CoopRecordDetailView extends GetView<CoopRecordDetailController> {
  const CoopRecordDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final record = controller.record;
    final op = record.gameType?.label ?? '랜덤';
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '학습 상세',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFFE3F2FD),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${record.partnerAvatar} ${record.partnerName} 님과 · $op 레벨 ${record.level}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '정답 ${record.correct} · 오답 ${record.wrong} · '
                  '정답률 ${(record.accuracy * 100).round()}% · '
                  '${formatElapsedSeconds(record.elapsedSeconds)}',
                  style: const TextStyle(fontSize: 13),
                ),
                Text(
                  formatRecordDate(record.finishedAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: record.attempts.isEmpty
                ? const Center(child: Text('저장된 문제 정보가 없어요.'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    itemCount: record.attempts.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AttemptTile(
                        index: i + 1,
                        attempt: record.attempts[i],
                      ),
                    ),
                  ),
          ),
          if (controller.hasWrong)
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + bottomInset),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: FilledButton.icon(
                  onPressed: controller.retryWrong,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF8E24AA),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.replay, size: 26),
                  label: Text(
                    '틀린 문제 다시풀기 (${controller.wrongCount})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
