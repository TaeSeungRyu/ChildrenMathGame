import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/coop_session_record.dart';
import '../../shared/date_format.dart';
import 'coop_records_controller.dart';

/// 함께 학습 기록 목록 (최신순). GameRecord와 분리된 경량 기록.
class CoopRecordsView extends GetView<CoopRecordsController> {
  const CoopRecordsView({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '함께 학습 기록',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        final records = controller.records;
        if (records.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                '아직 함께 학습한 기록이 없어요.\n부모님과 함께 시작해 보세요!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          );
        }
        return ListView.separated(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
          itemCount: records.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _RecordTile(record: records[i]),
        );
      }),
    );
  }
}

class _RecordTile extends GetView<CoopRecordsController> {
  const _RecordTile({required this.record});

  final CoopSessionRecord record;

  @override
  Widget build(BuildContext context) {
    final op = record.gameType?.label ?? '랜덤';
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Row(
          children: [
            Text(
              record.partnerAvatar,
              style: const TextStyle(fontSize: 30),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${record.partnerName} 님과 · $op 레벨 ${record.level}',
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
                  const SizedBox(height: 2),
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
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '삭제',
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('기록 삭제'),
        content: const Text('이 기록을 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              controller.delete(record);
              Navigator.of(context).pop();
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
