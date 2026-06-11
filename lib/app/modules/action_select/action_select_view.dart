import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'action_select_controller.dart';

/// 액션 게임 4종이 공유하는 진입 선택 화면.
///
/// 두 줄로 구성: 연산(➕➖✖️➗🎲) 5지선다 + 자릿수(1×1~3×3) 5지선다.
/// 시작하기를 누르면 컨셉별 본편 라우트로 선택값이 전달된다.
class ActionSelectView extends GetView<ActionSelectController> {
  const ActionSelectView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          controller.concept.title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionTitle('연산을 골라요'),
            const SizedBox(height: 8),
            const _OpPicker(),
            const SizedBox(height: 20),
            const _SectionTitle('자릿수를 골라요'),
            const SizedBox(height: 8),
            const _DigitsPicker(),
            const SizedBox(height: 28),
            SizedBox(
              height: 68,
              child: FilledButton.icon(
                onPressed: controller.start,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.play_arrow, size: 30),
                label: const Text(
                  '시작하기',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
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

class _OpPicker extends GetView<ActionSelectController> {
  const _OpPicker();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.selectedOp.value;
      final choices = ActionSelectController.opChoices;
      return Row(
        children: [
          for (var i = 0; i < choices.length; i++) ...[
            Expanded(
              child: _ChoiceTile(
                primary: choices[i]?.symbol ?? '🎲',
                label: choices[i]?.label ?? '랜덤',
                selected: choices[i] == selected,
                onTap: () => controller.setOp(choices[i]),
              ),
            ),
            if (i != choices.length - 1) const SizedBox(width: 8),
          ],
        ],
      );
    });
  }
}

class _DigitsPicker extends GetView<ActionSelectController> {
  const _DigitsPicker();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.selectedDigits.value;
      final choices = ActionSelectController.digitChoices;
      return Row(
        children: [
          for (var i = 0; i < choices.length; i++) ...[
            Expanded(
              child: _ChoiceTile(
                primary: '${choices[i].$1}×${choices[i].$2}',
                label: '자리',
                selected: choices[i] == selected,
                onTap: () => controller.setDigits(choices[i]),
              ),
            ),
            if (i != choices.length - 1) const SizedBox(width: 8),
          ],
        ],
      );
    });
  }
}

/// 5지선다 1칸. `primary`(큰 기호/자릿수 표기) + `label`(보조 한글) 구성으로
/// 두 picker가 동일 위젯을 공유한다. 좁은 화면에서도 FittedBox로 안전 축소.
class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.primary,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String primary;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const selectedBg = Color(0xFF1976D2);
    const unselectedBg = Color(0xFFFFF3E0);
    const selectedFg = Colors.white;
    const unselectedFg = Color(0xFF5D4037);
    const unselectedBorder = Color(0xFFD7CCC8);

    final bg = selected ? selectedBg : unselectedBg;
    final fg = selected ? selectedFg : unselectedFg;
    final border = selected ? selectedBg : unselectedBorder;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: 1),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  primary,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: fg,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: fg,
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
