import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../../data/models/wrong_notebook_entry.dart';
import 'wrong_notebook_controller.dart';

class WrongNotebookView extends GetView<WrongNotebookController> {
  const WrongNotebookView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '오답 노트',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: controller.totalWrongCount == 0
          ? const _EmptyState()
          : _NotebookBody(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 160,
              child: Lottie.asset(
                'assets/lottie/empty_state.json',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '아직 틀린 문제가 없어요!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '게임을 하면서 틀린 문제는\n여기 모아서 다시 풀어볼 수 있어요.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotebookBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WrongNotebookController>();
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return Column(
      children: [
        _FilterChips(),
        Expanded(
          child: Obx(() {
            final list = controller.filtered;
            if (list.isEmpty) {
              return Center(
                child: Text(
                  '이 유형에는 틀린 문제가 없어요.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              );
            }
            final now = DateTime.now();
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _EntryTile(
                entry: list[i],
                now: now,
                onTap: () => controller.retrySingle(list[i].sample),
              ),
            );
          }),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: Obx(() {
              final count = controller.filtered.length;
              return FilledButton.icon(
                onPressed: count == 0 ? null : controller.retryFiltered,
                icon: const Icon(Icons.refresh, size: 22),
                label: Text(
                  count == 0 ? '다시 풀 문제 없음' : '전체 다시 풀기 ($count)',
                  style: const TextStyle(fontSize: 20),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _FilterChips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WrongNotebookController>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: SizedBox(
        height: 40,
        child: Obx(() {
          final selected = controller.selectedBucket.value;
          final buckets = controller.availableBuckets;
          return ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _Chip(
                label: '전체',
                selected: selected == null,
                onTap: () => controller.selectBucket(null),
              ),
              for (final b in buckets) ...[
                const SizedBox(width: 8),
                _Chip(
                  label: b.label,
                  selected: selected == b,
                  onTap: () => controller.selectBucket(b),
                ),
              ],
            ],
          );
        }),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.entry,
    required this.now,
    required this.onTap,
  });

  final WrongNotebookEntry entry;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = entry.sample;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${a.questionText} = ${a.correctAnswer}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _CountBadge(count: entry.wrongCount),
                        const SizedBox(width: 8),
                        Text(
                          _agoLabel(entry.lastWrongAt, now),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: '다시 풀기',
                onPressed: onTap,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text(
        '$count번 틀림',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.red.shade700,
        ),
      ),
    );
  }
}

String _agoLabel(DateTime when, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final that = DateTime(when.year, when.month, when.day);
  final days = today.difference(that).inDays;
  if (days <= 0) return '오늘';
  if (days == 1) return '어제';
  if (days < 7) return '$days일 전';
  return '${when.month}월 ${when.day}일';
}
