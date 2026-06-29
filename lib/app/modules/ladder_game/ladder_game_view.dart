import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'ladder_game_controller.dart';

/// 숫자 사다리 화면 — 객관식 등반.
///
/// 화면 구조:
/// 1. AppBar — 제목 + HP + 남은 시간.
/// 2. 점수 바 — 오른 칸 수(높이) + 콤보.
/// 3. **사다리 등반 영역** — 클라이머가 화면 고정 위치에 있고, 정답을 맞히면
///    사다리(발판)가 아래로 흘러내려 "올라가는" 연출. [_LadderClimb] 참고.
/// 4. **문제 배너** — 현재 풀 문제.
/// 5. **답 발판 3개** — 정답 발판을 밟으면 한 칸 등반.
class LadderGameView extends GetView<LadderGameController> {
  const LadderGameView({super.key});

  static const _accent = Color(0xFFE65100);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '숫자 사다리',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Obx(() => _HpHearts(hp: controller.hp.value)),
                  const SizedBox(width: 10),
                  Obx(
                    () => _RemainingTime(seconds: controller.remainingSeconds),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              MediaQuery.of(context).viewPadding.bottom + 16,
            ),
            child: Column(
              children: [
                Obx(
                  () => _ScoreBar(
                    height: controller.height.value,
                    combo: controller.combo.value,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(child: _LadderClimb(controller: controller)),
                const SizedBox(height: 12),
                Obx(
                  () => _ProblemBanner(
                    text: controller.currentProblem.value.questionText,
                  ),
                ),
                const SizedBox(height: 12),
                _ChoiceRow(controller: controller),
              ],
            ),
          ),
          Obx(() {
            if (!controller.isGameOver.value) return const SizedBox.shrink();
            return _GameOverOverlay(
              height: controller.height.value,
              onRestart: controller.restart,
              onHome: controller.exitToHome,
            );
          }),
        ],
      ),
    );
  }
}

class _HpHearts extends StatelessWidget {
  const _HpHearts({required this.hp});

  final int hp;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(LadderGameController.maxHp, (i) {
        final alive = i < hp;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Icon(
            alive ? Icons.favorite : Icons.favorite_border,
            size: 22,
            color: alive
                ? const Color(0xFFE53935)
                : Colors.white.withValues(alpha: 0.55),
          ),
        );
      }),
    );
  }
}

class _RemainingTime extends StatelessWidget {
  const _RemainingTime({required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context) {
    final urgent = seconds <= 10;
    return Text(
      '$seconds초',
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: urgent ? const Color(0xFFE53935) : null,
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.height, required this.combo});

  final int height;
  final int combo;

  @override
  Widget build(BuildContext context) {
    const accent = LadderGameView._accent;
    return Row(
      children: [
        const Icon(Icons.stairs, color: accent, size: 22),
        const SizedBox(width: 6),
        Text(
          '$height칸',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: accent,
          ),
        ),
        const Spacer(),
        if (combo >= 2) ...[
          const Icon(Icons.bolt, color: Color(0xFFE53935), size: 22),
          const SizedBox(width: 4),
          Text(
            '$combo 연속',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE53935),
            ),
          ),
        ],
      ],
    );
  }
}

/// 사다리 등반 비주얼. 클라이머는 화면 고정 위치(세로 [_climberFrac])에 있고,
/// 높이가 오르면 사다리 발판이 아래로 흘러내려 "올라가는" 착시를 만든다.
/// 높이 값이 정수에서 정수로 바뀔 때 [TweenAnimationBuilder]로 부드럽게 보간.
class _LadderClimb extends StatelessWidget {
  const _LadderClimb({required this.controller});

  final LadderGameController controller;

  static const double _climberFrac = 0.66;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, c) {
            final h = c.maxHeight;
            final rungGap = h / 5.5;
            final climberY = h * _climberFrac;
            return Obx(() {
              final target = controller.height.value.toDouble();
              return TweenAnimationBuilder<double>(
                tween: Tween<double>(end: target),
                duration: const Duration(
                  milliseconds: LadderGameController.advanceDelayMs,
                ),
                curve: Curves.easeOut,
                builder: (context, animH, _) {
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _LadderPainter(
                            animH: animH,
                            rungGap: rungGap,
                            climberY: climberY,
                          ),
                        ),
                      ),
                      // 클라이머 — 현재 발판(climberY) 바로 위에 서 있다.
                      Positioned(
                        left: 0,
                        right: 0,
                        top: climberY - rungGap * 1.15,
                        height: rungGap * 1.15,
                        child: Center(
                          child: Text(
                            '🧗',
                            style: TextStyle(
                              fontSize: rungGap * 0.9,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            });
          },
        ),
      ),
    );
  }
}

/// 사다리 레일 2개 + 가로 발판들을 그린다. "카메라"가 클라이머([animH] 칸)를
/// 따라가므로, 발판 i 의 화면 y = climberY - (i - animH) * rungGap.
class _LadderPainter extends CustomPainter {
  _LadderPainter({
    required this.animH,
    required this.rungGap,
    required this.climberY,
  });

  final double animH;
  final double rungGap;
  final double climberY;

  static const _wood = Color(0xFF8D6E63);
  static const _woodDark = Color(0xFF5D4037);

  @override
  void paint(Canvas canvas, Size size) {
    final railInset = size.width * 0.30;
    final xLeft = railInset;
    final xRight = size.width - railInset;

    final railPaint = Paint()
      ..color = _woodDark
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(xLeft, 0), Offset(xLeft, size.height), railPaint);
    canvas.drawLine(Offset(xRight, 0), Offset(xRight, size.height), railPaint);

    final rungPaint = Paint()
      ..color = _wood
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    // 화면에 보이는 발판 인덱스 범위 (i >= 0).
    final loF = animH + (climberY - size.height) / rungGap - 1;
    final hiF = animH + climberY / rungGap + 1;
    final lo = loF.floor().clamp(0, 1 << 30);
    final hi = hiF.ceil();
    for (var i = lo; i <= hi; i++) {
      final y = climberY - (i - animH) * rungGap;
      if (y < -rungGap || y > size.height + rungGap) continue;
      canvas.drawLine(Offset(xLeft, y), Offset(xRight, y), rungPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LadderPainter old) =>
      old.animH != animH ||
      old.rungGap != rungGap ||
      old.climberY != climberY;
}

class _ProblemBanner extends StatelessWidget {
  const _ProblemBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB74D), Color(0xFFEF6C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE65100).withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '$text = ?',
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({required this.controller});

  final LadderGameController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final choices = controller.choices;
      final fbValue = controller.feedbackValue.value;
      final fbCorrect = controller.feedbackCorrect.value;
      return Row(
        children: [
          for (var i = 0; i < choices.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: _ChoiceTile(
                value: choices[i],
                highlighted: choices[i] == fbValue,
                highlightCorrect: fbCorrect,
                onTap: () => controller.onChoiceTap(choices[i]),
              ),
            ),
          ],
        ],
      );
    });
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.value,
    required this.highlighted,
    required this.highlightCorrect,
    required this.onTap,
  });

  final int value;
  final bool highlighted;
  final bool highlightCorrect;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const accent = LadderGameView._accent;
    final Color bg;
    final Color fg;
    final Color border;
    if (highlighted && highlightCorrect) {
      bg = const Color(0xFF66BB6A);
      fg = Colors.white;
      border = const Color(0xFF2E7D32);
    } else if (highlighted) {
      bg = const Color(0xFFEF5350);
      fg = Colors.white;
      border = const Color(0xFFC62828);
    } else {
      bg = Colors.white;
      fg = accent;
      border = accent.withValues(alpha: 0.5);
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: 72,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          '$value',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: fg,
          ),
        ),
      ),
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({
    required this.height,
    required this.onRestart,
    required this.onHome,
  });

  final int height;
  final VoidCallback onRestart;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
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
              const Text('🪜', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 6),
              const Text(
                'GAME OVER',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: LadderGameView._accent,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '$height칸 올라갔어요!',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onHome,
                      icon: const Icon(Icons.home),
                      label: const Text(
                        '홈으로',
                        style: TextStyle(fontSize: 16),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onRestart,
                      icon: const Icon(Icons.replay),
                      label: const Text(
                        '다시',
                        style: TextStyle(fontSize: 16),
                      ),
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
    );
  }
}
