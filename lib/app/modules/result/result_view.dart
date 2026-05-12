import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../../data/models/problem_attempt.dart';
import '../../routes/app_routes.dart';
import '../../shared/attempt_tile.dart';
import '../../shared/date_format.dart';
import 'result_controller.dart';

class ResultView extends GetView<ResultController> {
  const ResultView({super.key});

  @override
  Widget build(BuildContext context) {
    final r = controller.record;
    final isNewBest = controller.isNewPerfectBest;
    final reviewable = r.attempts
        .where((a) => a.status != AttemptStatus.correct)
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '결과',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context).viewPadding.bottom + 24,
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    SizedBox(
                      height: isNewBest ? 200 : 140,
                      child: Lottie.asset(
                        'assets/lottie/result_celebrate.json',
                        fit: BoxFit.contain,
                      ),
                    ),
                    if (isNewBest) ...[
                      const SizedBox(height: 8),
                      const _NewRecordBadge(),
                    ],
                    const SizedBox(height: 16),
                    _ScoreText(
                      text: '${r.correctCount} / ${r.totalCount}',
                      highlight: isNewBest,
                    ),
                    Text(
                      isNewBest ? '신기록 달성!' : '맞춘 문제',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: isNewBest ? FontWeight.bold : null,
                        color: isNewBest ? Colors.amber.shade800 : null,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _Row(
                      label: '게임',
                      value: controller.isTimesTable
                          ? '${controller.tableNumber}단 연습'
                          : controller.isPractice
                              ? '${r.type.label} 레벨 ${r.level} (연습)'
                              : '${r.type.label} 레벨 ${r.level}',
                    ),
                    _Row(label: '푼 문제', value: '${r.solvedCount}'),
                    _Row(label: '못 푼 문제', value: '${r.unsolvedCount}'),
                    _Row(label: '맞은 문제', value: '${r.correctCount}'),
                    _Row(label: '틀린 문제', value: '${r.wrongCount}'),
                    if (r.maxCombo >= 2)
                      _Row(label: '최고 콤보', value: '${r.maxCombo} 연속'),
                    _Row(
                      label: '소요 시간',
                      value: formatElapsedSeconds(r.elapsedSeconds),
                    ),
                    const SizedBox(height: 24),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '문제별 결과',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (var i = 0; i < r.attempts.length; i++) ...[
                      AttemptTile(index: i + 1, attempt: r.attempts[i]),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (reviewable.isNotEmpty) ...[
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () => Get.toNamed(
                    AppRoutes.review,
                    arguments: reviewable,
                  ),
                  icon: const Icon(Icons.refresh, size: 22),
                  label: Text(
                    '틀린 문제 다시 풀기 (${reviewable.length})',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: () => Get.offAllNamed(AppRoutes.home),
                child: const Text(
                  '홈으로',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ScoreText extends StatelessWidget {
  const _ScoreText({required this.text, required this.highlight});

  final String text;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: highlight ? 64 : 56,
      fontWeight: FontWeight.bold,
      color: highlight ? Colors.amber.shade800 : null,
    );
    if (!highlight) return Text(text, style: style);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.elasticOut,
      builder: (context, t, child) =>
          Transform.scale(scale: t, child: child),
      child: Text(text, style: style),
    );
  }
}

class _NewRecordBadge extends StatelessWidget {
  const _NewRecordBadge();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.elasticOut,
      builder: (context, t, child) => Transform.scale(
        scale: t,
        child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD54F), Color(0xFFFB8C00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.6),
              blurRadius: 16,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events, color: Colors.white, size: 26),
            SizedBox(width: 8),
            Text(
              '최단 시간 신기록!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
