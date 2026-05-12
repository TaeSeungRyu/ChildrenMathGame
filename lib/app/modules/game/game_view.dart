import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import 'game_controller.dart';

class GameView extends GetView<GameController> {
  const GameView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () {
            final progress =
                '${controller.currentIndex.value + 1} / ${controller.totalProblems}';
            final prefix = controller.isTimesTable
                ? '${controller.tableNumber}단  '
                : '';
            return Text(
              '$prefix$progress',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Obx(() {
                if (controller.isPractice) {
                  return Text(
                    '${controller.elapsed.value}초',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  );
                }
                final s = controller.remainingSeconds;
                final color = s <= 10 ? Colors.red : null;
                return Text(
                  '$s초',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context).viewPadding.bottom + 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Obx(() {
              // Practice: show problem progression. Challenge: show remaining
              // time so the bar drains visually as the countdown runs out.
              final double value;
              if (controller.isPractice) {
                value = (controller.currentIndex.value + 1) /
                    controller.totalProblems;
              } else {
                value = controller.remainingSeconds /
                    GameController.totalSeconds;
              }
              return LinearProgressIndicator(
                value: value.clamp(0.0, 1.0),
                minHeight: 8,
              );
            }),
            const SizedBox(height: 16),
            SizedBox(
              height: 80,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Lottie.asset(
                      'assets/lottie/game_character.json',
                      fit: BoxFit.contain,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Obx(
                      () => _ComboIndicator(count: controller.comboCount.value),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Obx(
                      () => Text(
                        '${controller.current.questionText} = ?',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _AnswerDisplay(),
            const SizedBox(height: 12),
            _Keypad(),
          ],
        ),
      ),
    );
  }
}

class _AnswerDisplay extends GetView<GameController> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 62,
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Obx(() {
        final value = controller.answer.value;
        if (value.isEmpty) {
          return Text(
            '정답 입력',
            style: TextStyle(
              fontSize: 24,
              color: theme.hintColor,
            ),
          );
        }
        return Text(
          value,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        );
      }),
    );
  }
}

class _Keypad extends GetView<GameController> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _row([_digit('1'), _digit('2'), _digit('3')]),
        const SizedBox(height: 8),
        _row([_digit('4'), _digit('5'), _digit('6')]),
        const SizedBox(height: 8),
        _row([_digit('7'), _digit('8'), _digit('9')]),
        const SizedBox(height: 8),
        _row(
          [
            _action(
              label: '지우기',
              onPressed: controller.deleteLast,
              color: Colors.orange.shade400,
            ),
            _digit('0'),
            _action(
              label: '입력',
              onPressed: controller.submit,
              color: Colors.green.shade500,
            ),
          ],
          flexes: const [1, 1, 2],
          height: 96,
        ),
      ],
    );
  }

  Widget _row(
    List<Widget> children, {
    List<int>? flexes,
    double height = 64,
  }) {
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) items.add(const SizedBox(width: 8));
      items.add(Expanded(flex: flexes?[i] ?? 1, child: children[i]));
    }
    return SizedBox(height: height, child: Row(children: items));
  }

  Widget _digit(String d) {
    return _KeypadButton(
      label: d,
      onPressed: () => controller.appendDigit(d),
    );
  }

  Widget _action({
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return _KeypadButton(
      label: label,
      onPressed: onPressed,
      backgroundColor: color,
      foregroundColor: Colors.white,
      fontSize: 22,
    );
  }
}

class _ComboIndicator extends StatelessWidget {
  const _ComboIndicator({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    // 1 correct isn't a "streak" — hide until 2. Empty placeholder keeps the
    // Positioned slot stable so the indicator animates in/out cleanly.
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, anim) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.5, end: 1.0)
              .chain(CurveTween(curve: Curves.elasticOut))
              .animate(anim),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      child: count < 2
          ? const SizedBox.shrink(key: ValueKey('combo-empty'))
          : _ComboPill(key: ValueKey('combo-$count'), count: count),
    );
  }
}

class _ComboPill extends StatelessWidget {
  const _ComboPill({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final isMilestone = GameController.comboMilestones.contains(count);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isMilestone
              ? const [Color(0xFFFFB300), Color(0xFFFF6F00)]
              : const [Color(0xFFFF8A65), Color(0xFFE53935)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.deepOrange.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 4),
          Text(
            '$count 연속',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({
    required this.label,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.fontSize = 28,
  });

  final String label;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
