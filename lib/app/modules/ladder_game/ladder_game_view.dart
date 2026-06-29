import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'ladder_game_controller.dart';

/// 숫자 사다리 화면 — 발판 위 객관식 등반.
///
/// 화면 구조:
/// 1. AppBar — 제목 + HP + 남은 시간.
/// 2. 점수 바 — 오른 칸 수(높이) + 콤보.
/// 3. **사다리 등반 영역** — 클라이머 바로 위 발판마다 답 후보가 적혀 있다.
///    정답 발판을 누르면 클라이머가 그 칸으로 점프해 올라가고, 카메라가 그
///    칸까지 따라 올라가 다음 후보 발판이 위에서 내려온다. 오답 발판을 누르면
///    클라이머가 흔들리고 발판이 빨갛게 깜빡인다. [_ClimbArea] 참고.
/// 4. **문제 배너** — 현재 풀 문제.
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
                Expanded(child: _ClimbArea(controller: controller)),
                const SizedBox(height: 12),
                Obx(
                  () => _ProblemBanner(
                    text: controller.currentProblem.value.questionText,
                  ),
                ),
                const SizedBox(height: 8),
                const _Hint(),
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

class _Hint extends StatelessWidget {
  const _Hint();

  @override
  Widget build(BuildContext context) {
    return Text(
      '정답이 적힌 발판을 밟아요!',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black.withValues(alpha: 0.55),
      ),
    );
  }
}

/// 등반 영역. 발판은 클라이머 위쪽 칸(world index `base+1 .. base+N`)에 깔리고
/// 각 발판이 답 후보 하나를 든다.
///
/// 좌표는 "카메라가 클라이머를 따라간다" 모델로 계산한다. world index `i`의
/// 화면 y = baseScreenY - (i - cam) * rungGap. 클라이머는 평소 base 칸(화면
/// 고정 위치)에 서 있고, 정답 시:
///   0.0~0.5 구간 — 클라이머가 정답 발판(base+landing)으로 점프(카메라 정지),
///   0.5~1.0 구간 — 카메라가 그 칸까지 따라 올라옴(클라이머는 발판에 고정).
/// 전환이 끝나면 컨트롤러가 새 문제를 내고, base 를 정답 칸으로 옮긴 뒤 새
/// 후보 발판이 위쪽에 나타난다 — 아래로 떨어지는 듯한 리셋이 없다.
class _ClimbArea extends StatefulWidget {
  const _ClimbArea({required this.controller});

  final LadderGameController controller;

  @override
  State<_ClimbArea> createState() => _ClimbAreaState();
}

class _ClimbAreaState extends State<_ClimbArea>
    with TickerProviderStateMixin {
  late final AnimationController _advance;
  late final AnimationController _shake;
  late final Worker _inputWorker;
  late final Worker _problemWorker;

  // 클라이머가 서 있는 칸(world index). 정답 전환이 끝날 때 정답 칸으로 옮긴다.
  int _base = 0;
  // 이번 정답에서 올라갈 칸 수(정답 발판의 위치, 1..choiceCount).
  int _landing = 0;
  bool _advancing = false;

  @override
  void initState() {
    super.initState();
    _advance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );

    final c = widget.controller;
    _inputWorker = ever<int>(c.inputTick, (_) {
      if (c.feedbackValue.value == -1) return;
      if (c.feedbackCorrect.value) {
        final idx = c.choices.indexOf(c.currentProblem.value.answer);
        _landing = (idx < 0 ? 0 : idx) + 1;
        _advancing = true;
        _advance.forward(from: 0);
      } else {
        _shake.forward(from: 0);
      }
    });
    _problemWorker = ever(c.currentProblem, (_) {
      setState(() {
        if (_advancing) {
          _base += _landing;
        } else {
          _base = 0; // restart / 새 게임
        }
        _advancing = false;
        _landing = 0;
      });
      _advance.value = 0;
      _shake.value = 0;
    });
  }

  @override
  void dispose() {
    _inputWorker.dispose();
    _problemWorker.dispose();
    _advance.dispose();
    _shake.dispose();
    super.dispose();
  }

  double get _t => Curves.easeOut.transform(_advance.value);

  double get _climberWorld {
    if (!_advancing) return _base.toDouble();
    final t = _t;
    if (t <= 0.5) return _base + _landing * (t / 0.5);
    return (_base + _landing).toDouble();
  }

  double get _camWorld {
    if (!_advancing) return _base.toDouble();
    final t = _t;
    if (t <= 0.5) return _base.toDouble();
    return _base + _landing * ((t - 0.5) / 0.5);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
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
          builder: (context, cons) {
            final h = cons.maxHeight;
            final w = cons.maxWidth;
            final rungGap = h / 5.5;
            final baseScreenY = h * 0.72;
            final railInset = w * 0.24;
            final xLeft = railInset;
            final xRight = w - railInset;

            return AnimatedBuilder(
              animation: Listenable.merge([_advance, _shake]),
              builder: (context, _) {
                final cam = _camWorld;
                final climberWorld = _climberWorld;
                final shakeX = _shake.isAnimating || _shake.value > 0
                    ? math.sin(_shake.value * math.pi * 5) *
                          10 *
                          (1 - _shake.value)
                    : 0.0;
                double screenY(num i) => baseScreenY - (i - cam) * rungGap;

                return Obx(() {
                  final choices = c.choices;
                  final fbValue = c.feedbackValue.value;
                  final fbCorrect = c.feedbackCorrect.value;
                  final barH = rungGap * 0.72;
                  return Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _LadderPainter(
                            cam: cam,
                            rungGap: rungGap,
                            baseScreenY: baseScreenY,
                            xLeft: xLeft,
                            xRight: xRight,
                          ),
                        ),
                      ),
                      // 후보 발판들 — base 바로 위 칸부터 차례로.
                      for (var k = 0; k < choices.length; k++)
                        _CandidateRung(
                          value: choices[k],
                          top: screenY(_base + 1 + k) - barH / 2,
                          left: xLeft - rungGap * 0.18,
                          width: (xRight - xLeft) + rungGap * 0.36,
                          height: barH,
                          highlighted: choices[k] == fbValue,
                          highlightCorrect: fbCorrect,
                          onTap: () => c.onChoiceTap(choices[k]),
                        ),
                      // 클라이머 — 발판 탭을 막지 않도록 IgnorePointer.
                      Positioned(
                        left: 0,
                        right: 0,
                        top: screenY(climberWorld) - rungGap * 0.95,
                        height: rungGap * 0.95,
                        child: IgnorePointer(
                          child: Transform.translate(
                            offset: Offset(shakeX, 0),
                            child: Center(
                              child: Text(
                                '🧗',
                                style: TextStyle(
                                  fontSize: rungGap * 0.8,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                });
              },
            );
          },
        ),
      ),
    );
  }
}

/// 사다리 레일 2개 + 가로 발판들. "카메라"가 [cam] 칸을 따라가므로 world index
/// i 의 화면 y = baseScreenY - (i - cam) * rungGap. 후보 발판이 올라앉는
/// 칸에는 가로줄 대신 [_CandidateRung] 위젯이 덮인다.
class _LadderPainter extends CustomPainter {
  _LadderPainter({
    required this.cam,
    required this.rungGap,
    required this.baseScreenY,
    required this.xLeft,
    required this.xRight,
  });

  final double cam;
  final double rungGap;
  final double baseScreenY;
  final double xLeft;
  final double xRight;

  static const _wood = Color(0xFF8D6E63);
  static const _woodDark = Color(0xFF5D4037);

  @override
  void paint(Canvas canvas, Size size) {
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

    final loF = cam + (baseScreenY - size.height) / rungGap - 1;
    final hiF = cam + baseScreenY / rungGap + 1;
    final lo = loF.floor().clamp(0, 1 << 30);
    final hi = hiF.ceil();
    for (var i = lo; i <= hi; i++) {
      final y = baseScreenY - (i - cam) * rungGap;
      if (y < -rungGap || y > size.height + rungGap) continue;
      canvas.drawLine(Offset(xLeft, y), Offset(xRight, y), rungPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LadderPainter old) =>
      old.cam != cam ||
      old.rungGap != rungGap ||
      old.baseScreenY != baseScreenY ||
      old.xLeft != xLeft ||
      old.xRight != xRight;
}

/// 답 후보가 적힌 발판. 평소엔 나무색, 정답으로 밟으면 초록·오답이면 빨강.
class _CandidateRung extends StatelessWidget {
  const _CandidateRung({
    required this.value,
    required this.top,
    required this.left,
    required this.width,
    required this.height,
    required this.highlighted,
    required this.highlightCorrect,
    required this.onTap,
  });

  final int value;
  final double top;
  final double left;
  final double width;
  final double height;
  final bool highlighted;
  final bool highlightCorrect;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
      bg = const Color(0xFFFFCC80);
      fg = const Color(0xFF5D4037);
      border = const Color(0xFF8D6E63);
    }
    return Positioned(
      top: top,
      left: left,
      width: width,
      height: height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(height * 0.4),
            border: Border.all(color: border, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            '$value',
            style: TextStyle(
              fontSize: height * 0.5,
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
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
