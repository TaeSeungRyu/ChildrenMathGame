import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../../routes/app_routes.dart';
import '../../shared/attempt_tile.dart';
import '../../shared/date_format.dart';
import 'result_controller.dart';

class ResultView extends GetView<ResultController> {
  const ResultView({super.key});

  @override
  Widget build(BuildContext context) {
    final r = controller.record;
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
                      height: 140,
                      child: Lottie.asset(
                        'assets/lottie/result_celebrate.json',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${r.correctCount} / ${r.totalCount}',
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('맞춘 문제', style: TextStyle(fontSize: 18)),
                    const SizedBox(height: 32),
                    _Row(label: '게임', value: '${r.type.label} 레벨 ${r.level}'),
                    _Row(label: '푼 문제', value: '${r.solvedCount}'),
                    _Row(label: '못 푼 문제', value: '${r.unsolvedCount}'),
                    _Row(label: '맞은 문제', value: '${r.correctCount}'),
                    _Row(label: '틀린 문제', value: '${r.wrongCount}'),
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
            style: const TextStyle(fontSize:15, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
