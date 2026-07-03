import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import 'fishing_game_controller.dart';

/// 물고기 잡기 화면 — 객관식 "움직이는 타겟" 낚기.
///
/// 화면 구조:
/// 1. AppBar — 제목 + HP + 남은 시간.
/// 2. 점수 바 — 낚은 물고기 수 + 콤보.
/// 3. **문제 배너** — 현재 풀어야 할 한 문제를 크게 표시.
/// 4. **어항(수조)** — 여러 물고기가 등에 답 후보를 달고 좌↔우로 헤엄친다.
///    정답이 적힌 물고기만 탭하면 낚음.
///
/// 두더지와 마찬가지로 숫자 키패드가 없는 "선택+반응속도" 게임이지만, 타겟이
/// 구멍에서 팝업하는 대신 화면을 가로질러 헤엄쳐 이동 예측이 필요하다.
class FishingGameView extends StatefulWidget {
  const FishingGameView({super.key});

  @override
  State<FishingGameView> createState() => _FishingGameViewState();
}

class _FishingGameViewState extends State<FishingGameView>
    with SingleTickerProviderStateMixin {
  late final FishingGameController _c;
  late final Ticker _ticker;
  Duration? _epoch;
  int _ms = 0;
  late final Worker _gameOverWorker;

  @override
  void initState() {
    super.initState();
    _c = Get.find<FishingGameController>();
    _ticker = createTicker(_onTick)..start();
    _gameOverWorker = ever<bool>(_c.isGameOver, (over) {
      if (over && _ticker.isActive) _ticker.stop();
    });
  }

  void _onTick(Duration elapsed) {
    _epoch ??= elapsed;
    final ms = (elapsed - _epoch!).inMilliseconds;
    setState(() => _ms = ms);
    _c.onFrame(ms);
  }

  void _onRestart() {
    _epoch = null;
    setState(() => _ms = 0);
    if (!_ticker.isActive) _ticker.start();
    _c.restart();
  }

  @override
  void dispose() {
    _gameOverWorker.dispose();
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '물고기 잡기',
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
                  Obx(() => _HpHearts(hp: _c.hp.value)),
                  const SizedBox(width: 10),
                  Obx(() => _RemainingTime(seconds: _c.remainingSeconds)),
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
                    catches: _c.catches.value,
                    combo: _c.combo.value,
                  ),
                ),
                const SizedBox(height: 10),
                Obx(
                  () => _ProblemBanner(
                    text: _c.currentProblem.value.questionText,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(child: _Aquarium(controller: _c, elapsedMs: _ms)),
              ],
            ),
          ),
          Obx(() {
            if (!_c.isGameOver.value) return const SizedBox.shrink();
            return _GameOverOverlay(
              catches: _c.catches.value,
              onRestart: _onRestart,
              onHome: _c.exitToHome,
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
      children: List.generate(FishingGameController.maxHp, (i) {
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
  const _ScoreBar({required this.catches, required this.combo});

  final int catches;
  final int combo;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF00838F);
    return Row(
      children: [
        const Icon(Icons.set_meal, color: accent, size: 22),
        const SizedBox(width: 6),
        Text(
          '낚은 물고기 $catches',
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

/// 라운드의 한 문제를 큰 글씨로 보여 주는 배너. 바다 톤(청록) 그라데이션으로
/// 어항 배경과 이어지게 한다.
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
          colors: [Color(0xFF4DD0E1), Color(0xFF00838F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF006064).withValues(alpha: 0.22),
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

/// 어항 — 파란 물 배경 위에서 물고기들이 헤엄친다. 각 물고기는 정규화 위치를
/// 가용 폭/높이에 매핑해 Positioned 로 놓이고, 자체 GestureDetector 로 탭을
/// 받는다(별도 hit-test 불필요).
class _Aquarium extends StatelessWidget {
  const _Aquarium({required this.controller, required this.elapsedMs});

  final FishingGameController controller;
  final int elapsedMs;

  // 물고기 한 마리가 차지하는 대략의 폭/높이(px). 화면 밖에서 완전히 들어오고
  // 나가도록 진행도 매핑에도 이 폭을 쓴다.
  static const double _fishW = 96;
  static const double _fishH = 64;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF81D4FA), Color(0xFF0277BD)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final h = c.maxHeight;
            return Obx(() {
              final list = controller.fishes;
              return Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  // (z 최하단) 아래에서 위로 떠오르는 물방울 배경.
                  _BubbleLayer(elapsedMs: elapsedMs),
                  // 잔잔한 물결 느낌의 정적 장식(맨 아래 수초).
                  const Positioned(
                    left: 12,
                    bottom: 4,
                    child: Text('🌿', style: TextStyle(fontSize: 30)),
                  ),
                  const Positioned(
                    right: 16,
                    bottom: 2,
                    child: Text('🪸', style: TextStyle(fontSize: 28)),
                  ),
                  // (z 아래) 낚싯줄 — 낚인 정답 물고기마다 수면 위(어항 상단)에서
                  // 물고기까지 이어지는 줄. 물고기보다 먼저 그려 물고기가 줄 위에
                  // 겹쳐 보이게 한다.
                  for (final f in list)
                    if (f.hookedMs != null && f.hookedCorrect)
                      _FishingLine(
                        geom: _fishGeom(f, elapsedMs, w, h, _fishW, _fishH),
                        fishHeight: _fishH,
                      ),
                  for (final f in list)
                    _PositionedFish(
                      key: ValueKey(f.id),
                      fish: f,
                      elapsedMs: elapsedMs,
                      areaWidth: w,
                      areaHeight: h,
                      fishWidth: _fishW,
                      fishHeight: _fishH,
                      onTap: () => controller.onFishTap(f.id),
                    ),
                ],
              );
            });
          },
        ),
      ),
    );
  }
}

/// 물고기 한 마리의 화면상 배치(좌상단 위치 + 중심 x + 낚기 진행도)를 계산한다.
/// 낚싯줄과 물고기 스프라이트가 **같은** 좌표를 쓰도록 한 곳에 모아 둔다.
_FishGeom _fishGeom(
  Fish f,
  int elapsedMs,
  double areaWidth,
  double areaHeight,
  double fishWidth,
  double fishHeight,
) {
  final hooked = f.hookedMs != null;
  // 낚이면 그 시점 위치에 멈춰 이펙트만 재생하도록 진행도를 고정.
  final progress = hooked
      ? ((f.hookedMs! - f.appearedMs) / f.durationMs).clamp(0.0, 1.0)
      : ((elapsedMs - f.appearedMs) / f.durationMs).clamp(0.0, 1.0);

  // 화면 밖(-fishW)에서 반대편 밖(areaWidth)까지 완전히 횡단.
  final travel = areaWidth + fishWidth;
  final x = f.ltr
      ? -fishWidth + progress * travel
      : areaWidth - progress * travel;
  final baseY = (f.laneY * (areaHeight - fishHeight))
      .clamp(0.0, math.max(0.0, areaHeight - fishHeight))
      .toDouble();

  final catchT = hooked
      ? ((elapsedMs - f.hookedMs!) / FishingGameController.catchAnimMs)
            .clamp(0.0, 1.0)
      : 0.0;
  // 정답: 낚싯줄을 타고 수면(어항 상단, y=0)까지 끌려 올라간다. 오답: 제자리.
  // ease-out(1-(1-t)^2)으로 처음 빠르게 챘다가 수면 근처에서 느려지는 손맛.
  final reel = 1 - (1 - catchT) * (1 - catchT);
  final top = (hooked && f.hookedCorrect) ? baseY * (1 - reel) : baseY;

  return _FishGeom(
    left: x,
    top: top,
    centerX: x + fishWidth / 2,
    catchT: catchT,
  );
}

class _FishGeom {
  const _FishGeom({
    required this.left,
    required this.top,
    required this.centerX,
    required this.catchT,
  });

  final double left;
  final double top;
  final double centerX;
  final double catchT;
}

/// 수면(어항 상단)에서 낚인 물고기까지 이어지는 낚싯줄 + 끝의 낚싯바늘.
/// 물고기가 위로 끌려 올라갈수록(top 감소) 줄이 짧아지고, 낚기 애니메이션이
/// 끝나갈 즈음(catchT→1) 함께 옅어진다.
class _FishingLine extends StatelessWidget {
  const _FishingLine({required this.geom, required this.fishHeight});

  final _FishGeom geom;
  final double fishHeight;

  static const double _knot = 7;

  @override
  Widget build(BuildContext context) {
    // 줄이 물고기 머리(배지 부근)에 붙도록 물고기 상단에서 살짝 아래를 종점으로.
    final bottomY = math.max(0.0, geom.top + fishHeight * 0.30);
    final opacity = (1 - geom.catchT * 0.3).clamp(0.0, 1.0);
    // 매듭이 2px 줄보다 넓으므로, 매듭 폭 기준의 박스를 두고 그 안에서 줄/매듭을
    // 가운데 정렬한다(폭 불일치로 인한 오버플로 방지).
    return Positioned(
      left: geom.centerX - _knot / 2,
      top: 0,
      width: _knot,
      height: bottomY,
      child: Opacity(
        opacity: opacity,
        child: Stack(
          children: [
            // 줄 — 가운데 세로 3px, 위(수면)에서 물고기까지.
            Positioned(
              left: _knot / 2 - 1.5,
              top: 0,
              bottom: 0,
              width: 3,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // 줄 끝의 작은 낚싯바늘 매듭.
            Positioned(
              left: 0,
              bottom: 0,
              width: _knot,
              height: _knot,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFECEFF1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PositionedFish extends StatelessWidget {
  const _PositionedFish({
    super.key,
    required this.fish,
    required this.elapsedMs,
    required this.areaWidth,
    required this.areaHeight,
    required this.fishWidth,
    required this.fishHeight,
    required this.onTap,
  });

  final Fish fish;
  final int elapsedMs;
  final double areaWidth;
  final double areaHeight;
  final double fishWidth;
  final double fishHeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hooked = fish.hookedMs != null;
    final geom = _fishGeom(
      fish,
      elapsedMs,
      areaWidth,
      areaHeight,
      fishWidth,
      fishHeight,
    );
    // 올라가는 동안엔 계속 보이다가, 수면에 닿는 마지막 25% 구간에서만 페이드아웃
    // — 물고기가 줄을 타고 올라오는 모습이 끝까지 보이도록.
    final double fade;
    if (!hooked) {
      fade = 1.0;
    } else if (geom.catchT < 0.75) {
      fade = 1.0;
    } else {
      fade = (1 - (geom.catchT - 0.75) / 0.25).clamp(0.0, 1.0);
    }

    return Positioned(
      left: geom.left,
      top: geom.top,
      width: fishWidth,
      height: fishHeight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: hooked ? null : onTap,
        child: Opacity(
          opacity: fade,
          child: _FishSprite(
            number: fish.number,
            emoji: fish.emoji,
            faceRight: fish.ltr,
            hooked: hooked,
            isCorrect: fish.hookedCorrect,
            catchT: geom.catchT,
          ),
        ),
      ),
    );
  }
}

/// 물고기 본체 — 답 후보 배지 + 물고기 이모지 + (낚였을 때) ✨ 또는 ❌ 이펙트.
///
/// 물고기 이모지([emoji], 스폰 시 무작위)는 모두 기본적으로 왼쪽을 보므로,
/// 우→좌(RTL)로 헤엄칠 땐 그대로, 좌→우(LTR)로 헤엄칠 땐 좌우 반전해 진행
/// 방향을 바라보게 한다.
class _FishSprite extends StatelessWidget {
  const _FishSprite({
    required this.number,
    required this.emoji,
    required this.faceRight,
    required this.hooked,
    required this.isCorrect,
    required this.catchT,
  });

  final int number;
  final String emoji;
  final bool faceRight;
  final bool hooked;
  final bool isCorrect;
  final double catchT;

  @override
  Widget build(BuildContext context) {
    final wrongShake = (hooked && !isCorrect)
        ? math.sin(catchT * math.pi * 6) * 4
        : 0.0;

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Transform.translate(
          offset: Offset(wrongShake, 0),
          // FittedBox: 이모지 라인 메트릭이 폰트에 따라 커져 박스(96×64)를 넘칠
          // 수 있으므로 scaleDown 으로 항상 안에 맞춘다.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _NumberBadge(number: number),
                const SizedBox(height: 1),
                Transform.flip(
                  flipX: faceRight,
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 34, height: 1.0),
                  ),
                ),
              ],
            ),
          ),
        ),
        // 낚싯줄은 어항 Stack 에서 별도로 그리므로(위→물고기), 여기선 걸린 순간의
        // 반짝임만 얹는다.
        if (hooked && isCorrect)
          Transform.scale(
            scale: 0.6 + catchT * 1.2,
            child: Opacity(
              opacity: (1 - catchT).clamp(0.0, 1.0),
              child: const Text('✨', style: TextStyle(fontSize: 30)),
            ),
          ),
        if (hooked && !isCorrect)
          Transform.scale(
            scale: 0.6 + catchT * 0.5,
            child: Opacity(
              opacity: (1 - catchT * 0.5).clamp(0.0, 1.0),
              child: const Text('❌', style: TextStyle(fontSize: 30)),
            ),
          ),
      ],
    );
  }
}

class _NumberBadge extends StatelessWidget {
  const _NumberBadge({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF01579B), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        '$number',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF01579B),
        ),
      ),
    );
  }
}

/// 어항 배경의 물방울 레이어. 아래에서 위로 떠오르며 좌우로 살짝 흔들린다.
///
/// 물방울 각각의 크기·속도·시작 위치·흔들림은 [initState] 에서 **한 번만** 무작위로
/// 정해 두고(매 프레임 재생성하면 깜빡인다), 이후 프레임마다 [elapsedMs] 로 세로
/// 위치만 계산해 [CustomPaint] 로 그린다. 순수 장식이라 탭을 가로채지 않도록
/// [IgnorePointer] 로 감싼다.
class _BubbleLayer extends StatefulWidget {
  const _BubbleLayer({required this.elapsedMs});

  final int elapsedMs;

  @override
  State<_BubbleLayer> createState() => _BubbleLayerState();
}

class _BubbleLayerState extends State<_BubbleLayer> {
  static const int _count = 18;
  final math.Random _rng = math.Random();
  late final List<_Bubble> _bubbles;

  @override
  void initState() {
    super.initState();
    _bubbles = List.generate(_count, (_) {
      return _Bubble(
        xFraction: _rng.nextDouble(),
        radius: 2.5 + _rng.nextDouble() * 6.5, // 2.5..9
        riseMs: 3000 + _rng.nextInt(4500), // 3.0s..7.5s 상승
        phaseMs: _rng.nextInt(7500), // 시작 시점을 흩뿌려 동시 상승 방지
        swayAmp: 4 + _rng.nextDouble() * 12, // 좌우 흔들림 4..16px
        swayPeriodMs: 1200 + _rng.nextInt(1600),
        // 세로로 살짝 눌린/늘어난 타원까지 섞어 "랜덤한 모양" 느낌.
        squash: 0.78 + _rng.nextDouble() * 0.44, // 0.78..1.22
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _BubblePainter(bubbles: _bubbles, elapsedMs: widget.elapsedMs),
        ),
      ),
    );
  }
}

class _Bubble {
  const _Bubble({
    required this.xFraction,
    required this.radius,
    required this.riseMs,
    required this.phaseMs,
    required this.swayAmp,
    required this.swayPeriodMs,
    required this.squash,
  });

  final double xFraction;
  final double radius;
  final int riseMs;
  final int phaseMs;
  final double swayAmp;
  final int swayPeriodMs;
  final double squash;
}

class _BubblePainter extends CustomPainter {
  _BubblePainter({required this.bubbles, required this.elapsedMs});

  final List<_Bubble> bubbles;
  final int elapsedMs;

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in bubbles) {
      final t = ((elapsedMs + b.phaseMs) % b.riseMs) / b.riseMs; // 0..1
      // 아래(화면 밖)에서 위(화면 밖)로. t=0 → 바닥 아래, t=1 → 상단 위.
      final y = size.height - t * (size.height + b.radius * 4) + b.radius * 2;
      final sway =
          math.sin((elapsedMs + b.phaseMs) / b.swayPeriodMs * 2 * math.pi) *
          b.swayAmp;
      final x = b.xFraction * size.width + sway;
      // 상단 15% 구간에서 서서히 사라지게.
      final alpha = t > 0.85 ? (1 - (t - 0.85) / 0.15).clamp(0.0, 1.0) : 1.0;

      final rx = b.radius;
      final ry = b.radius * b.squash;
      final rect = Rect.fromCenter(
        center: Offset(x, y),
        width: rx * 2,
        height: ry * 2,
      );
      canvas.drawOval(
        rect,
        Paint()..color = Colors.white.withValues(alpha: 0.16 * alpha),
      );
      canvas.drawOval(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = Colors.white.withValues(alpha: 0.32 * alpha),
      );
      // 작은 하이라이트(좌상단)로 물방울 느낌 강조.
      canvas.drawCircle(
        Offset(x - rx * 0.3, y - ry * 0.35),
        math.max(1.0, rx * 0.22),
        Paint()..color = Colors.white.withValues(alpha: 0.55 * alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_BubblePainter oldDelegate) =>
      oldDelegate.elapsedMs != elapsedMs || oldDelegate.bubbles != bubbles;
}

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({
    required this.catches,
    required this.onRestart,
    required this.onHome,
  });

  final int catches;
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
              const Text('🐟', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 6),
              const Text(
                'GAME OVER',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00838F),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '$catches마리 낚음!',
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
