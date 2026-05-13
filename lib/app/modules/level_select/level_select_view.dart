import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import 'level_select_controller.dart';

class LevelSelectView extends GetView<LevelSelectController> {
  const LevelSelectView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${controller.type.label} - 난이도 선택',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewPadding.bottom + 16,
        ),
        child: Column(
          children: [
            SizedBox(
              height: 120,
              child: Lottie.asset(
                'assets/lottie/level_banner.json',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
            const _ModeToggle(),
            const SizedBox(height: 16),
            ...List.generate(5, (i) {
              final level = i + 1;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 72,
                  child: FilledButton(
                    onPressed: () => controller.selectLevel(level),
                    child: Text(
                      '레벨 $level  (${_levelLabel(level)})',
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _levelLabel(int level) {
    switch (level) {
      case 1:
        return '1자리수';
      case 2:
        return '2자리수+1자리수';
      case 3:
        return '2자리수+2자리수';
      case 4:
        return '3자리수+2자리수';
      case 5:
        return '3자리수+3자리수';
      default:
        return '';
    }
  }
}

class _ModeToggle extends GetView<LevelSelectController> {
  const _ModeToggle();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final mode = controller.mode.value;
      return Column(
        children: [
          SegmentedButton<LevelSelectMode>(
            segments: const [
              ButtonSegment<LevelSelectMode>(
                value: LevelSelectMode.challenge,
                label: Text(
                  '도전',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                icon: Icon(Icons.timer),
              ),
              ButtonSegment<LevelSelectMode>(
                value: LevelSelectMode.timeAttack,
                label: Text(
                  '타임어택',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                icon: Icon(Icons.flash_on),
              ),
              ButtonSegment<LevelSelectMode>(
                value: LevelSelectMode.practice,
                label: Text(
                  '연습',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                icon: Icon(Icons.spa),
              ),
            ],
            selected: {mode},
            onSelectionChanged: (s) => controller.setMode(s.first),
            style: ButtonStyle(
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _modeHint(mode),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      );
    });
  }

  String _modeHint(LevelSelectMode mode) {
    switch (mode) {
      case LevelSelectMode.challenge:
        return '180초 안에 10문제!';
      case LevelSelectMode.timeAttack:
        return '60초 동안 최대한 많이!';
      case LevelSelectMode.practice:
        return '시간 제한 없이 풀어요 (기록 미저장)';
    }
  }
}
