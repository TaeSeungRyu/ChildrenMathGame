import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'sign_guess_controller.dart';

/// 부호 맞추기 화면 — 식의 기호를 빈칸(?)으로 보여 주고, 아래 연산 버튼으로
/// 왼쪽부터 채운다.
class SignGuessView extends GetView<SignGuessController> {
  const SignGuessView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '부호 맞추기',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Obx(
            () => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${controller.index.value + 1} / ${controller.total}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                children: [
                  const Expanded(child: Center(child: _Expression())),
                  const _OpPad(),
                  const SizedBox(height: 8),
                  Obx(
                    () => TextButton.icon(
                      onPressed: controller.filled.isEmpty
                          ? null
                          : controller.deleteLast,
                      icon: const Icon(Icons.backspace_outlined),
                      label: const Text('지우기'),
                    ),
                  ),
                ],
              ),
            ),
            const _FinishOverlay(),
          ],
        ),
      ),
    );
  }
}

/// 피연산자 사이에 기호 슬롯을 끼워 식을 그린다.
class _Expression extends GetView<SignGuessController> {
  const _Expression();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final p = controller.current;
      final filled = controller.filled;
      final feedback = controller.feedback.value;
      final nextSlot = filled.length; // 현재 채울 빈칸 위치

      final parts = <Widget>[];
      for (var i = 0; i < p.operands.length; i++) {
        parts.add(_Num(p.operands[i]));
        if (i < p.operations.length) {
          final isFilled = i < filled.length;
          parts.add(
            _OpSlot(
              symbol: isFilled ? filled[i].symbol : null,
              active: i == nextSlot && feedback == 0,
            ),
          );
        }
      }
      // = 결과
      parts.add(const _Sym('='));
      parts.add(_Num(p.answer));

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: parts,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 34,
            child: feedback == 0
                ? const Text(
                    '빈칸에 알맞은 기호를 넣어요',
                    style: TextStyle(fontSize: 15, color: Colors.black54),
                  )
                : Text(
                    feedback == 1 ? '정답이에요! 🎉' : '아쉬워요. 다시 도전!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: feedback == 1
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFC62828),
                    ),
                  ),
          ),
        ],
      );
    });
  }
}

class _Num extends StatelessWidget {
  const _Num(this.value);
  final int value;
  @override
  Widget build(BuildContext context) => Text(
        '$value',
        style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold),
      );
}

class _Sym extends StatelessWidget {
  const _Sym(this.symbol);
  final String symbol;
  @override
  Widget build(BuildContext context) => Text(
        symbol,
        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
      );
}

/// 기호 빈칸. 채워지면 기호를, 아니면 "?"를 보여 준다.
class _OpSlot extends StatelessWidget {
  const _OpSlot({required this.symbol, required this.active});

  final String? symbol;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final filled = symbol != null;
    final border = active
        ? const Color(0xFF1976D2)
        : (filled ? const Color(0xFF90CAF9) : const Color(0xFFBDBDBD));
    return Container(
      width: 48,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE3F2FD) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border, width: active ? 2.5 : 1.5),
      ),
      child: Text(
        symbol ?? '?',
        style: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.bold,
          color: filled ? Colors.black : const Color(0xFF9E9E9E),
        ),
      ),
    );
  }
}

/// 후보 연산 버튼(레벨 1~3: +/−, 4~5: +/−/×/÷).
class _OpPad extends GetView<SignGuessController> {
  const _OpPad();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final disabled = controller.feedback.value != 0 || controller.isComplete;
      return Row(
        children: [
          for (var i = 0; i < controller.pool.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 72,
                child: FilledButton(
                  onPressed:
                      disabled ? null : () => controller.selectOp(controller.pool[i]),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    controller.pool[i].symbol,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    });
  }
}

class _FinishOverlay extends GetView<SignGuessController> {
  const _FinishOverlay();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.isFinished.value) return const SizedBox.shrink();
      return Positioned.fill(
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.55),
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔎', style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 8),
                  Text(
                    '${controller.correctCount.value} / ${controller.total} 맞혔어요!',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: controller.exitToHome,
                          icon: const Icon(Icons.home),
                          label: const Text('홈으로'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: controller.restart,
                          icon: const Icon(Icons.replay),
                          label: const Text('다시'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
