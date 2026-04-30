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
          () => Text(
            '${controller.currentIndex.value + 1} / ${GameController.totalProblems}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Obx(() {
                final s = controller.secondsLeft.value;
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Obx(() {
                final progress =
                    controller.secondsLeft.value / GameController.totalSeconds;
                return LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 8,
                );
              }),
              const SizedBox(height: 16),
              SizedBox(
                height: 100,
                child: Lottie.asset(
                  'assets/lottie/game_character.json',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Center(
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
              const SizedBox(height: 12),
              _AnswerDisplay(),
              const SizedBox(height: 12),
              _Keypad(),
            ],
          ),
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
      height: 72,
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
            fontSize: 40,
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
