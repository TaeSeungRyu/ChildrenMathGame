import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/services/action_score_service.dart';
import '../../shared/action_record_line.dart';
import 'balance_game_controller.dart';

/// 저울 맞추기 화면 — 좌우 식의 대소 비교.
///
/// 화면 구조:
/// 1. AppBar — 제목 + HP + 남은 시간.
/// 2. 점수 바 — 맞힌 수 + 콤보.
/// 3. **저울 영역** — 기둥 위 빔 양 끝에 접시가 줄로 매달려 있고, 접시마다 식이
///    하나씩 올라가 있다. 평소엔 수평이고, 답을 고르면 **정답 방향으로** 기운다
///    (틀렸을 때도 정답 방향으로 기울어 눈으로 확인하게 한다). [_BalanceArea] 참고.
/// 4. **선택 버튼** — `>` / `=` / `<` 세 개. 기호만으로는 6~9세에게 모호해서
///    "왼쪽이 커요" 같은 말 라벨을 함께 단다.
class BalanceGameView extends GetView<BalanceGameController> {
  const BalanceGameView({super.key});

  static const _accent = Color(0xFFAD1457);
  static const _deep = Color(0xFF880E4F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '저울 맞추기',
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
                    solved: controller.solved.value,
                    combo: controller.combo.value,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(child: _BalanceArea(controller: controller)),
                const SizedBox(height: 12),
                _ChoiceRow(controller: controller),
                const SizedBox(height: 8),
                const _Hint(),
              ],
            ),
          ),
          Obx(() {
            if (!controller.isGameOver.value) return const SizedBox.shrink();
            return _GameOverOverlay(
              solved: controller.solved.value,
              best: Get.find<ActionScoreService>()
                  .bestFor(BalanceGameController.concept),
              isNewBest: controller.isNewBest.value,
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
      children: List.generate(BalanceGameController.maxHp, (i) {
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
  const _ScoreBar({required this.solved, required this.combo});

  final int solved;
  final int combo;

  @override
  Widget build(BuildContext context) {
    const accent = BalanceGameView._accent;
    return Row(
      children: [
        const Icon(Icons.balance, color: accent, size: 22),
        const SizedBox(width: 6),
        Text(
          '$solved개',
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
      '어느 쪽이 더 큰지 골라요!',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black.withValues(alpha: 0.55),
      ),
    );
  }
}

/// 저울 본체. 빔은 회전축(기둥 꼭대기)을 중심으로 기울고, 접시는 빔 양 끝에서
/// **수직으로 매달려** 있어 기울어도 접시와 글자는 늘 수평을 유지한다 —
/// 접시까지 같이 회전시키면 6~9세에게 식이 읽기 어려워진다.
///
/// 기울기 [_tilt]는 -1..1 로 정규화한 값이고 실제 각도는 [_maxAngle]을 곱해
/// 얻는다. 부호 규약: **+1 = 왼쪽이 무거워 왼쪽이 내려감**(= relation 1).
class _BalanceArea extends StatefulWidget {
  const _BalanceArea({required this.controller});

  final BalanceGameController controller;

  @override
  State<_BalanceArea> createState() => _BalanceAreaState();
}

class _BalanceAreaState extends State<_BalanceArea>
    with SingleTickerProviderStateMixin {
  /// 최대 기울기(라디안). 12°쯤이면 "확실히 기울었다"가 한눈에 보이면서도
  /// 접시가 영역 밖으로 밀려나지 않는다.
  static const double _maxAngle = 0.21;

  late final AnimationController _anim;
  late final Worker _revealWorker;

  // 기울기 보간 구간. 공개 시 0 → relation, 라운드 종료 시 relation → 0.
  // "현재 값 → 목표"로 잡아 두면 평형(relation == 0) 라운드처럼 시작과 끝이
  // 같은 경우가 저절로 무동작이 된다.
  double _from = 0;
  double _to = 0;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    final c = widget.controller;
    _revealWorker = ever<bool>(c.revealed, (on) {
      _tiltTo(on ? c.pair.value.relation.toDouble() : 0);
    });
  }

  @override
  void dispose() {
    _revealWorker.dispose();
    _anim.dispose();
    super.dispose();
  }

  double get _tiltValue =>
      _from + (_to - _from) * Curves.easeOutBack.transform(_anim.value);

  void _tiltTo(double to) {
    final now = _tiltValue; // 보간 구간을 갈아 끼우기 전의 현재 기울기
    setState(() {
      _from = now;
      _to = to;
    });
    _anim.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFCE4EC), Color(0xFFF8BBD0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, cons) {
            final w = cons.maxWidth;
            final h = cons.maxHeight;
            final cx = w / 2;
            final pivotY = h * 0.24; // 빔 회전축 높이
            final beamHalf = w * 0.30;
            final stringLen = h * 0.13;
            final panW = w * 0.38;
            final panH = h * 0.30;

            return AnimatedBuilder(
              animation: _anim,
              builder: (context, _) {
                final theta = _tiltValue * _maxAngle;
                final dx = math.cos(theta) * beamHalf;
                final dy = math.sin(theta) * beamHalf;
                // 화면 y는 아래로 증가 — theta>0 이면 왼쪽 끝이 내려간다.
                final lx = cx - dx;
                final ly = pivotY + dy;
                final rx = cx + dx;
                final ry = pivotY - dy;

                return Obx(() {
                  final pair = c.pair.value;
                  final showing = c.revealed.value;
                  final rel = pair.relation;
                  return Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      // 기둥 + 받침
                      Positioned(
                        left: cx - 6,
                        top: pivotY,
                        width: 12,
                        height: h - pivotY - h * 0.06,
                        child: const DecoratedBox(
                          decoration: BoxDecoration(color: Color(0xFF8D6E63)),
                        ),
                      ),
                      Positioned(
                        left: cx - w * 0.16,
                        bottom: h * 0.03,
                        width: w * 0.32,
                        height: h * 0.045,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0xFF5D4037),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      // 빔 — 회전축(cx, pivotY) 중심 회전. 화면 좌표계에서
                      // 양(+)의 회전은 시계 방향이라 -theta 를 준다.
                      Positioned(
                        left: cx - beamHalf,
                        top: pivotY - 5,
                        width: beamHalf * 2,
                        height: 10,
                        child: Transform.rotate(
                          angle: -theta,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xFF6D4C41),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ),
                      // 회전축 캡
                      Positioned(
                        left: cx - 11,
                        top: pivotY - 11,
                        width: 22,
                        height: 22,
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0xFF4E342E),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      // 좌/우 줄 + 접시
                      _PanHanger(
                        centerX: lx,
                        topY: ly,
                        stringLen: stringLen,
                        width: panW,
                        height: panH,
                        text: pair.left.questionText,
                        heavier: showing && rel > 0,
                        balanced: showing && rel == 0,
                      ),
                      _PanHanger(
                        centerX: rx,
                        topY: ry,
                        stringLen: stringLen,
                        width: panW,
                        height: panH,
                        text: pair.right.questionText,
                        heavier: showing && rel < 0,
                        balanced: showing && rel == 0,
                      ),
                      // 가운데 관계 기호 — 공개 중에만.
                      if (showing)
                        Positioned(
                          left: cx - 26,
                          top: pivotY + h * 0.16,
                          width: 52,
                          height: 52,
                          child: _RelationStamp(relation: rel),
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

/// 빔 끝에서 줄로 매달린 접시 하나. [topY]가 줄이 시작되는(빔 끝) 지점이고,
/// 접시는 그 아래 [stringLen]만큼 내려온 자리에 수평으로 놓인다.
class _PanHanger extends StatelessWidget {
  const _PanHanger({
    required this.centerX,
    required this.topY,
    required this.stringLen,
    required this.width,
    required this.height,
    required this.text,
    required this.heavier,
    required this.balanced,
  });

  final double centerX;
  final double topY;
  final double stringLen;
  final double width;
  final double height;
  final String text;

  /// 공개 중이고 이쪽이 더 무거울 때 — 초록으로 강조.
  final bool heavier;

  /// 공개 중이고 양쪽이 같을 때 — 양쪽 다 파랑으로 강조.
  final bool balanced;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color border;
    final Color fg;
    if (heavier) {
      bg = const Color(0xFFC8E6C9);
      border = const Color(0xFF2E7D32);
      fg = const Color(0xFF1B5E20);
    } else if (balanced) {
      bg = const Color(0xFFBBDEFB);
      border = const Color(0xFF1565C0);
      fg = const Color(0xFF0D47A1);
    } else {
      bg = Colors.white;
      border = const Color(0xFFAD1457);
      fg = const Color(0xFF880E4F);
    }
    return Positioned(
      left: centerX - width / 2,
      top: topY,
      width: width,
      height: stringLen + height,
      child: IgnorePointer(
        child: Column(
          children: [
            // 매다는 줄
            SizedBox(
              height: stringLen,
              child: Center(
                child: SizedBox(
                  width: 3,
                  height: stringLen,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(color: Color(0xFF8D6E63)),
                  ),
                ),
              ),
            ),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    text,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: fg,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 공개 중 저울 아래 가운데에 찍히는 정답 관계 기호.
class _RelationStamp extends StatelessWidget {
  const _RelationStamp({required this.relation});

  final int relation;

  @override
  Widget build(BuildContext context) {
    final symbol = relation > 0
        ? '>'
        : relation < 0
        ? '<'
        : '=';
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFAD1457), width: 3),
        ),
        child: Center(
          child: Text(
            symbol,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Color(0xFF880E4F),
            ),
          ),
        ),
      ),
    );
  }
}

/// `>` `=` `<` 세 버튼. 왼쪽→오른쪽 순서가 "왼쪽이 큼 / 같음 / 오른쪽이 큼"
/// 이라 문장 순서 그대로 읽힌다.
class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({required this.controller});

  final BalanceGameController controller;

  static const _options = [
    (1, '>', '왼쪽이 커요'),
    (0, '=', '같아요'),
    (-1, '<', '오른쪽이 커요'),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final showing = controller.revealed.value;
      final picked = controller.selected.value;
      final answer = controller.pair.value.relation;
      return Row(
        children: [
          for (var i = 0; i < _options.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: _ChoiceButton(
                symbol: _options[i].$2,
                label: _options[i].$3,
                // 공개 중에는 정답 버튼을 늘 초록으로, 틀리게 고른 버튼만
                // 빨강으로 — 어디를 눌렀고 어디가 정답이었는지 동시에 보인다.
                state: !showing
                    ? _ChoiceState.idle
                    : _options[i].$1 == answer
                    ? _ChoiceState.correct
                    : _options[i].$1 == picked
                    ? _ChoiceState.wrong
                    : _ChoiceState.idle,
                onTap: () => controller.onChoiceTap(_options[i].$1),
              ),
            ),
          ],
        ],
      );
    });
  }
}

enum _ChoiceState { idle, correct, wrong }

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.symbol,
    required this.label,
    required this.state,
    required this.onTap,
  });

  final String symbol;
  final String label;
  final _ChoiceState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color border;
    final Color fg;
    switch (state) {
      case _ChoiceState.correct:
        bg = const Color(0xFF66BB6A);
        border = const Color(0xFF2E7D32);
        fg = Colors.white;
      case _ChoiceState.wrong:
        bg = const Color(0xFFEF5350);
        border = const Color(0xFFC62828);
        fg = Colors.white;
      case _ChoiceState.idle:
        bg = Colors.white;
        border = const Color(0xFFF48FB1);
        fg = const Color(0xFF880E4F);
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              symbol,
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: fg,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({
    required this.solved,
    required this.best,
    required this.isNewBest,
    required this.onRestart,
    required this.onHome,
  });

  final int solved;
  final int best;
  final bool isNewBest;
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
              const Text('⚖️', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 6),
              const Text(
                'GAME OVER',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: BalanceGameView._deep,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '$solved개 맞혔어요!',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ActionRecordLine(best: best, isNewBest: isNewBest),
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
