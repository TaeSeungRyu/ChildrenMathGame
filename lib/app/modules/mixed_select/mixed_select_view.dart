import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import 'mixed_select_controller.dart';

class MixedSelectView extends GetView<MixedSelectController> {
  const MixedSelectView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '혼합 모드',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
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
              height: 100,
              child: Lottie.asset(
                'assets/lottie/level_banner.json',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 8),
            const _SectionTitle('어떤 연산을 섞을까?'),
            const SizedBox(height: 8),
            const _TypePicker(),
            const SizedBox(height: 16),
            const _ModeToggle(),
            const SizedBox(height: 16),
            const _SectionTitle('난이도'),
            const SizedBox(height: 8),
            ...List.generate(5, (i) {
              final level = i + 1;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 72,
                  child: FilledButton(
                    onPressed: () => controller.startLevel(level),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _TypePicker extends GetView<MixedSelectController> {
  const _TypePicker();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: MixedSelectController.choices.map((t) {
          final selected = controller.selectedTypes.contains(t);
          // The last remaining type is locked — the controller silently no-ops,
          // but disabling the chip makes the constraint visible.
          final isOnlyOne =
              selected && controller.selectedTypes.length == 1;
          return FilterChip(
            label: Text(
              '${t.symbol} ${t.label}',
              style: const TextStyle(fontSize: 16),
            ),
            selected: selected,
            onSelected: isOnlyOne ? null : (_) => controller.toggleType(t),
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 6,
            ),
          );
        }).toList(),
      );
    });
  }
}

class _ModeToggle extends GetView<MixedSelectController> {
  const _ModeToggle();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final practice = controller.isPractice.value;
      return Column(
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment<bool>(
                value: false,
                label: Text(
                  '도전',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                icon: Icon(Icons.timer),
              ),
              ButtonSegment<bool>(
                value: true,
                label: Text(
                  '연습',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                icon: Icon(Icons.spa),
              ),
            ],
            selected: {practice},
            onSelectionChanged: (s) => controller.setPractice(s.first),
            style: ButtonStyle(
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            practice ? '시간 제한 없이 풀어요 (기록 미저장)' : '180초 안에 10문제!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      );
    });
  }
}
