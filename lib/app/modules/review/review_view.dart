import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'review_controller.dart';

class ReviewView extends GetView<ReviewController> {
  const ReviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          if (controller.phase.value == ReviewPhase.done) {
            return const Text(
              '복습 완료',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            );
          }
          return Text(
            '복습 ${controller.currentIndex.value + 1} / ${controller.totalCount}',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          );
        }),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context).viewPadding.bottom + 24,
        ),
        child: Obx(() => controller.phase.value == ReviewPhase.done
            ? const _DoneBody()
            : const _AnsweringBody()),
      ),
    );
  }
}

class _AnsweringBody extends GetView<ReviewController> {
  const _AnsweringBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Obx(() {
                  final a = controller.current;
                  final ops = a.operations.length;
                  final double base;
                  if (ops <= 1) {
                    base = 56;
                  } else if (ops == 2) {
                    base = 44;
                  } else if (ops == 3) {
                    base = 38;
                  } else {
                    base = 32;
                  }
                  return Text(
                    '${a.questionText} = ?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: base,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const _AnswerDisplay(),
        const SizedBox(height: 12),
        const _Keypad(),
      ],
    );
  }
}

class _AnswerDisplay extends GetView<ReviewController> {
  const _AnswerDisplay();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final phase = controller.phase.value;
      if (phase == ReviewPhase.feedback) {
        final correct = controller.lastWasCorrect.value;
        final color = correct ? Colors.green : Colors.red;
        final label = correct ? '정답!' : '틀렸어요';
        return Container(
          height: 72,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                correct ? Icons.check_circle : Icons.cancel,
                color: color,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                correct
                    ? label
                    : '$label  정답: ${controller.current.correctAnswer}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        );
      }
      final value = controller.answer.value;
      return Container(
        height: 62,
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: value.isEmpty
            ? Text(
                '정답 입력',
                style: TextStyle(fontSize: 24, color: theme.hintColor),
              )
            : Text(
                value,
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
      );
    });
  }
}

class _Keypad extends GetView<ReviewController> {
  const _Keypad();

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
            _KeypadButton(
              label: '지우기',
              onPressed: controller.deleteLast,
              backgroundColor: Colors.orange.shade400,
              foregroundColor: Colors.white,
              fontSize: 22,
            ),
            _digit('0'),
            Obx(() {
              final isFeedback =
                  controller.phase.value == ReviewPhase.feedback;
              return _KeypadButton(
                label: isFeedback
                    ? (controller.isLast ? '완료' : '다음')
                    : '입력',
                onPressed: isFeedback ? controller.next : controller.submit,
                backgroundColor: Colors.green.shade500,
                foregroundColor: Colors.white,
                fontSize: 22,
              );
            }),
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
  final VoidCallback? onPressed;
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
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _DoneBody extends GetView<ReviewController> {
  const _DoneBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.emoji_events,
                  color: Colors.amber,
                  size: 96,
                ),
                const SizedBox(height: 16),
                const Text(
                  '복습 끝!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Obx(
                  () => Text(
                    '${controller.totalCount}문제 중 '
                    '${controller.retryCorrectCount.value}문제 정답',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            onPressed: () => Get.back(),
            child: const Text(
              '돌아가기',
              style: TextStyle(fontSize: 20),
            ),
          ),
        ),
      ],
    );
  }
}
