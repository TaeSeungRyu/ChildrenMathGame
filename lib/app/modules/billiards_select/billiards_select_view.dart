import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/game_type.dart';
import 'billiards_select_controller.dart';

class BilliardsSelectView extends GetView<BilliardsSelectController> {
  const BilliardsSelectView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('연산 당구'), centerTitle: true),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('연산을 골라요', style: TextStyle(fontSize: 22)),
          const SizedBox(height: 12),
          Obx(
            () => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final op in [
                  GameType.addition,
                  GameType.subtraction,
                  GameType.multiplication,
                  GameType.division,
                ])
                  ChoiceChip(
                    label: Text('${op.symbol} ${op.label}'),
                    selected: controller.operation.value == op,
                    onSelected: (_) => controller.operation.value = op,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('공 개수', style: TextStyle(fontSize: 22)),
          Obx(
            () => SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 4, label: Text('4개')),
                ButtonSegment(value: 5, label: Text('5개')),
                ButtonSegment(value: 6, label: Text('6개')),
              ],
              selected: {controller.ballCount.value},
              onSelectionChanged: (selection) =>
                  controller.ballCount.value = selection.first,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '작은 수(+, ×) 또는 큰 수(-, ÷)의 공을 골라 방향과 힘을 조절해요. 최대 두 번 맞히고, 가장 큰 수를 만들 때까지 다시 도전할 수 있어요.',
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 60,
            child: FilledButton.icon(
              onPressed: controller.start,
              icon: const Icon(Icons.play_arrow),
              label: const Text('시작하기', style: TextStyle(fontSize: 22)),
            ),
          ),
        ],
      ),
    ),
  );
}
