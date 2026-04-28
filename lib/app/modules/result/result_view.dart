import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../../shared/date_format.dart';
import 'result_controller.dart';

class ResultView extends GetView<ResultController> {
  const ResultView({super.key});

  @override
  Widget build(BuildContext context) {
    final r = controller.record;
    return Scaffold(
      appBar: AppBar(title: const Text('결과'), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Text(
                '${r.correctCount} / ${r.totalCount}',
                style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text('맞춘 문제', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 32),
              _Row(label: '게임', value: '${r.type.label} 레벨 ${r.level}'),
              _Row(label: '맞춘 갯수', value: '${r.correctCount}'),
              _Row(label: '틀린 갯수', value: '${r.wrongCount}'),
              _Row(label: '소요 시간', value: formatElapsedSeconds(r.elapsedSeconds)),
              _Row(label: '종료 시간', value: formatRecordDate(r.finishedAt)),
              const Spacer(),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 18, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
