import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../../shared/op_tile.dart';
import 'estimation_select_controller.dart';

class EstimationSelectView extends GetView<EstimationSelectController> {
  const EstimationSelectView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '어림셈 모드',
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
            const _Hint(),
            const SizedBox(height: 12),
            const _SectionTitle('어떤 연산으로 풀까?'),
            const SizedBox(height: 8),
            const _TypePicker(),
            const SizedBox(height: 16),
            const _ModeToggle(),
            const SizedBox(height: 16),
            const _SectionTitle('난이도'),
            const SizedBox(height: 8),
            ...List.generate(5, (i) {
              final level = i + 1;
              // "레벨 N (..)" 한 줄 표기는 fontSize 22 + 작은 화면(360dp)에서 5
              // 레벨 라벨이 강제 개행된다. 메인은 "레벨 N"으로 크게, 자릿수·
              // 반올림 단위는 작은 부제로 내려, 의도된 두 줄 구조로 만든다.
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 72,
                  child: FilledButton(
                    onPressed: () => controller.startLevel(level),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '레벨 $level',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _levelLabel(level),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
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
        return '1자리 · 5단위';
      case 2:
        return '2자리+1자리 · 10단위';
      case 3:
        return '2자리+2자리 · 10단위';
      case 4:
        return '3자리+2자리 · 10단위';
      case 5:
        return '3자리+3자리 · 100단위';
      default:
        return '';
    }
  }
}

class _Hint extends StatelessWidget {
  const _Hint();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '정확한 답이 아니라 "약 얼마?"를 골라요.\n자릿수로 어림하는 감각!',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: scheme.onSecondaryContainer,
        ),
      ),
    );
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

/// +/−/× 셋 단일 선택. OpTileGrid는 4타일을 강제하므로, 어림셈에선
/// 3개를 단일 Row로 늘어놓는다.
class _TypePicker extends GetView<EstimationSelectController> {
  const _TypePicker();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.selectedType.value;
      final tiles = EstimationSelectController.choices.map((t) {
        return Expanded(
          child: OpTile(
            symbol: t.symbol,
            label: t.label,
            selected: t == selected,
            onTap: () => controller.setType(t),
          ),
        );
      }).toList();
      // Expanded 사이에 spacing 박스 끼우기.
      final spaced = <Widget>[];
      for (var i = 0; i < tiles.length; i++) {
        if (i > 0) spaced.add(const SizedBox(width: 10));
        spaced.add(tiles[i]);
      }
      return Row(children: spaced);
    });
  }
}

class _ModeToggle extends GetView<EstimationSelectController> {
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
