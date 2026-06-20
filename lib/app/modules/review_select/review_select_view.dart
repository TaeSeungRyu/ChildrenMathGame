import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../../shared/wrong_notebook.dart';
import 'review_select_controller.dart';

class ReviewSelectView extends GetView<ReviewSelectController> {
  const ReviewSelectView({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '복습 날짜 선택',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: controller.isEmpty
          ? _EmptyState(bottomInset: bottomInset)
          : ListView.separated(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
              itemCount: controller.days.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final day = controller.days[i];
                return _DayTile(
                  day: day,
                  onTap: () => controller.startDay(day),
                );
              },
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.bottomInset});

  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
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
              '복습할 오답이 없어요',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              '게임 한 판 풀어보면 여기에 모여요',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({required this.day, required this.onTap});

  final DayWrongs day;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = _dayLabel(day.date);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: scheme.primaryContainer,
                child: Text(
                  '${day.date.day}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '오답 ${day.count}개',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: scheme.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "오늘 / 어제 / YYYY-MM-DD (요일)". `now` is read once per build via
/// `DateTime.now()`; precision down to the day is enough so it's fine even if
/// the user lingers on the screen past midnight.
String _dayLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(date).inDays;
  if (diff == 0) return '오늘';
  if (diff == 1) return '어제';
  return _formatDate(date);
}

String _formatDate(DateTime d) {
  String pad(int n) => n.toString().padLeft(2, '0');
  const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  final wd = weekdays[d.weekday - 1];
  return '${d.year}-${pad(d.month)}-${pad(d.day)} ($wd)';
}
