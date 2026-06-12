import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import 'balloon_game_controller.dart';

/// 풍선 터뜨리기 MVP 화면.
///
/// 상단: HP 하트 + 남은 시간 + 라운드/처치/콤보 + 큰 "목표 답" 카드.
/// 본문: 풍선 Arena — 풍선들이 바닥에서 위로 천천히 떠오르고, 사용자가 답이
/// 목표와 같은 풍선만 탭해 터뜨린다. 위로 빠져나간 정답 풍선은 미스 처리.
///
/// 컨트롤러는 풍선 리스트와 라운드 상태만 들고 있고, 프레임 단위 위치는
/// 이 위젯 안 [Ticker] 로 계산한다. 컨트롤러의 [BalloonGameController.roundTrigger]
/// 가 증가하면 elapsed를 0으로 리셋해 새 라운드의 풍선들이 다시 바닥부터 떠오른다.
class BalloonGameView extends StatefulWidget {
  const BalloonGameView({super.key});

  @override
  State<BalloonGameView> createState() => _BalloonGameViewState();
}

class _BalloonGameViewState extends State<BalloonGameView>
    with SingleTickerProviderStateMixin {
  late final BalloonGameController _c;
  late final Ticker _ticker;
  // Ticker가 처음 fire 됐을 때의 절대시간을 저장. 이후 elapsed - _epoch 로
  // 라운드 시작 기준 ms를 얻는다. 라운드가 새로 시작되면 null로 리셋.
  Duration? _epoch;
  int _ms = 0;

  // 이번 라운드에서 이미 "빠져나갔다"고 컨트롤러에 통보한 풍선 id 집합.
  // Ticker는 매 프레임 발화하므로 같은 풍선에 대해 onBalloonEscape를 여러 번
  // 호출하지 않도록 가드한다. 라운드 리셋 시 비운다.
  final Set<int> _escaped = {};

  late final Worker _roundWorker;
  late final Worker _gameOverWorker;

  @override
  void initState() {
    super.initState();
    _c = Get.find<BalloonGameController>();
    _ticker = createTicker(_onTick)..start();
    _roundWorker = ever<int>(_c.roundTrigger, (_) => _resetRound());
    _gameOverWorker = ever<bool>(_c.isGameOver, (over) {
      if (over && _ticker.isActive) _ticker.stop();
    });
  }

  void _onTick(Duration elapsed) {
    _epoch ??= elapsed;
    final ms = (elapsed - _epoch!).inMilliseconds;
    setState(() => _ms = ms);
    // 컨트롤러에 세션 ms 캐시 — 풍선 탭 시 poppedAtMs 박을 때 쓰임.
    _c.onFrame(ms);
    _checkEscapes();
  }

  void _checkEscapes() {
    // RxList iteration outside of an Obx reactive context — `.toList()` 로
    // 스냅샷을 떠 build/setState 사이에 RxList가 바뀌어도 안전하게 순회한다.
    final snapshot = _c.balloons.toList();
    for (final b in snapshot) {
      if (_escaped.contains(b.id)) continue;
      // 이미 터지는 중인 풍선은 좌표가 freeze 돼 있어 escape 통보 대상에서 제외.
      if (b.poppedAtMs != null) continue;
      final p = (_ms - b.delayMs) / b.floatMs;
      if (p >= 1.0) {
        _escaped.add(b.id);
        // 같은 프레임 안에서 컨트롤러 상태를 변경하면 진행 중인 build와
        // 충돌할 수 있다 — 다음 프레임으로 미뤄 안전하게 통보.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _c.onBalloonEscape(b.id);
        });
      }
    }
  }

  void _resetRound() {
    _epoch = null;
    _escaped.clear();
    setState(() => _ms = 0);
  }

  @override
  void dispose() {
    _roundWorker.dispose();
    _gameOverWorker.dispose();
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '풍선 터뜨리기',
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
              MediaQuery.of(context).viewPadding.bottom + 12,
            ),
            child: Column(
              children: [
                Obx(
                  () => _ScoreBar(
                    round: _c.round.value,
                    pops: _c.pops.value,
                    combo: _c.combo.value,
                  ),
                ),
                const SizedBox(height: 8),
                Obx(() => _TargetCard(answer: _c.targetAnswer.value)),
                const SizedBox(height: 10),
                Expanded(child: _BalloonArena(controller: _c, elapsedMs: _ms)),
              ],
            ),
          ),
          Obx(() {
            if (!_c.isGameOver.value) return const SizedBox.shrink();
            return _GameOverOverlay(
              round: _c.round.value,
              pops: _c.pops.value,
              onRestart: () {
                _resetRound();
                _ticker.start();
                _c.restart();
              },
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
      children: List.generate(BalloonGameController.maxHp, (i) {
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
  const _ScoreBar({
    required this.round,
    required this.pops,
    required this.combo,
  });

  final int round;
  final int pops;
  final int combo;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFE65100);
    return Row(
      children: [
        const Icon(Icons.flag, color: accent, size: 22),
        const SizedBox(width: 6),
        Text(
          '$round라운드',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: accent,
          ),
        ),
        const SizedBox(width: 12),
        const Icon(Icons.celebration, color: accent, size: 20),
        const SizedBox(width: 4),
        Text(
          '$pops',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: accent,
          ),
        ),
        const Spacer(),
        if (combo >= 2) ...[
          const Icon(Icons.bolt, color: Color(0xFFD81B60), size: 22),
          const SizedBox(width: 4),
          Text(
            '$combo 연속',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD81B60),
            ),
          ),
        ],
      ],
    );
  }
}

/// 큰 글씨로 "목표 답"을 보여주는 카드. 풍선이 빠르게 움직이는 와중에도
/// 어린이 사용자가 빠른 시선 이동으로 확인할 수 있도록 본문 위에 고정 배치.
class _TargetCard extends StatelessWidget {
  const _TargetCard({required this.answer});

  final int answer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE082), Color(0xFFFFB74D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE65100).withValues(alpha: 0.18),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text(
            '목표 답',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5D4037),
            ),
          ),
          const Spacer(),
          // 큰 숫자 — 풍선과의 시각적 매핑이 빠르도록 단독 라인.
          Text(
            '$answer',
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5D4037),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// 풍선이 떠오르는 무대. LayoutBuilder로 실제 픽셀 높이/너비를 잰 뒤,
/// 각 풍선의 progress = (elapsedMs - delayMs) / floatMs 를 화면 좌표에 매핑.
///
/// progress < 0  → 아직 등장 전 (화면 밖, 안 보임)
/// 0..1          → 바닥 위에서 상단으로 떠오르는 중 (보임, 탭 가능)
/// progress ≥ 1  → 상단을 빠져나감 (안 보임, Ticker가 onBalloonEscape 통보)
class _BalloonArena extends StatelessWidget {
  const _BalloonArena({required this.controller, required this.elapsedMs});

  final BalloonGameController controller;
  final int elapsedMs;

  // 풍선 카드 시각 크기(폭/높이). 풍선 모양으로 보이게 살짝 세로로 긴 oval.
  static const double _balloonWidth = 92;
  static const double _balloonHeight = 110;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFFFF3E0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, c) {
            final h = c.maxHeight;
            final w = c.maxWidth;
            return Obx(() {
              final list = controller.balloons.toList();
              return Stack(
                children: [
                  for (final b in list)
                    _buildPositionedBalloon(b, w, h),
                ],
              );
            });
          },
        ),
      ),
    );
  }

  Widget _buildPositionedBalloon(Balloon b, double arenaW, double arenaH) {
    // 위치 계산용 기준 ms — 살아 있으면 현재, 터지는 중이면 freeze.
    final refMs = b.poppedAtMs ?? elapsedMs;
    final p = (refMs - b.delayMs) / b.floatMs;
    // 정상 비행 중인데 p ≥ 1 인 풍선(=빠져나감)은 화면에서 숨김 — 컨트롤러가
    // 곧 escape 처리로 popped 마킹하거나 제거한다.
    if (p < 0 || (b.poppedAtMs == null && p >= 1)) {
      return SizedBox.shrink(key: ValueKey('balloon-${b.id}'));
    }
    // 떠오르는 좌표: p=0 일 때 풍선 바닥이 무대 바닥에 닿아 **완전히 보이고**,
    // p=1 일 때 풍선이 상단 위로 완전히 빠져나간다.
    // 이전 공식은 풍선이 무대 아래에서부터 솟아오르도록 돼 있어 첫 풍선이 약 1초간
    // 보이지 않는 "게임이 시작 안 됨" 같은 체감을 만들었다 — 그 버그 수정.
    final top = (arenaH - _balloonHeight) - p * arenaH;
    final left = b.xFraction * arenaW - _balloonWidth / 2;

    // 터지는 진행도(0..1). non-null 이면 풍선 이펙트(스케일/페이드/흔들림)에 사용.
    final popProgress = b.poppedAtMs == null
        ? 0.0
        : ((elapsedMs - b.poppedAtMs!) /
                BalloonGameController.popDurationMs)
            .clamp(0.0, 1.0);

    return Positioned(
      key: ValueKey('balloon-${b.id}'),
      left: left.clamp(4.0, arenaW - _balloonWidth - 4),
      top: top,
      width: _balloonWidth,
      height: _balloonHeight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // 터지는 중인 풍선은 더 이상 탭 받지 않음.
        onTap: b.poppedAtMs != null
            ? null
            : () => controller.onBalloonTap(b.id),
        child: _BalloonCard(balloon: b, popProgress: popProgress),
      ),
    );
  }
}

/// 풍선 한 개의 시각 표현. 원형 컨테이너 + 짧은 끈으로 풍선 정체성을 살린다.
/// 6~9세에게 거부감 없는 파스텔톤 + 진한 외곽선으로 가독성을 동시에 확보.
///
/// [popProgress] 가 0 보다 크면 "터지는 중" — 정답이면 풍선이 살짝 커지며
/// ✨ 가 솟아 오르고, 오답이면 좌우로 흔들리며 ❌ 가 떠오른다. 어느 경우든
/// 풍선 자체는 popProgress 에 비례해 페이드 아웃.
class _BalloonCard extends StatelessWidget {
  const _BalloonCard({required this.balloon, required this.popProgress});

  final Balloon balloon;
  final double popProgress;

  @override
  Widget build(BuildContext context) {
    final isPopping = balloon.poppedAtMs != null;
    final isCorrect = balloon.isCorrectPop ?? false;

    // 풍선 본체의 변형: 정답이면 살짝 커지고, 오답이면 좌우 흔들림 + 약간 축소.
    final scale = isPopping
        ? (isCorrect
            ? 1.0 + popProgress * 0.35
            : 1.0 - popProgress * 0.2)
        : 1.0;
    final shakeX = (isPopping && !isCorrect)
        ? math.sin(popProgress * math.pi * 6) * 4
        : 0.0;
    final bodyOpacity = isPopping
        ? (1 - popProgress).clamp(0.0, 1.0)
        : 1.0;

    final balloonBody = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: _BalloonArena._balloonWidth,
          height: _BalloonArena._balloonHeight - 14,
          decoration: BoxDecoration(
            color: balloon.color,
            shape: BoxShape.rectangle,
            borderRadius: const BorderRadius.all(Radius.elliptical(60, 70)),
            border: Border.all(
              color: const Color(0xFF5D4037),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: FittedBox(
              child: Text(
                balloon.problem.questionText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3E2723),
                ),
              ),
            ),
          ),
        ),
        // 풍선 끈 — 단순한 작은 삼각형.
        SizedBox(
          width: 12,
          height: 12,
          child: CustomPaint(
            painter: _BalloonStringPainter(color: balloon.color),
          ),
        ),
      ],
    );

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Transform.translate(
          offset: Offset(shakeX, 0),
          child: Transform.scale(
            scale: scale,
            child: Opacity(opacity: bodyOpacity, child: balloonBody),
          ),
        ),
        if (isPopping)
          _PopEffect(
            isCorrect: isCorrect,
            progress: popProgress,
          ),
      ],
    );
  }
}

/// 정답/오답 이펙트 오버레이. 정답 = ✨ 가 위로 솟아 오르며 확장, 오답 = ❌ 가
/// 풍선 중앙에 등장해 살짝 커지며 페이드 — 6~9세 사용자에게 즉각 학습 피드백.
class _PopEffect extends StatelessWidget {
  const _PopEffect({required this.isCorrect, required this.progress});

  final bool isCorrect;
  final double progress;

  @override
  Widget build(BuildContext context) {
    if (isCorrect) {
      // ✨ 가 풍선 위로 부드럽게 솟아 오르며 점차 커지다 페이드. 풍선이
      // 부풀어 터지는 환호 느낌.
      final scale = 0.7 + progress * 1.0;
      final dy = -progress * 24; // 살짝 위로 뜸
      return Transform.translate(
        offset: Offset(0, dy),
        child: Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: (1 - progress).clamp(0.0, 1.0),
            child: const Text(
              '✨',
              style: TextStyle(fontSize: 56, height: 1.0),
            ),
          ),
        ),
      );
    }
    // 오답: ❌ 가 풍선 중앙에 등장해 살짝 커지며 페이드.
    final scale = 0.6 + progress * 0.7;
    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: (1 - progress * 0.5).clamp(0.0, 1.0),
        child: const Text(
          '❌',
          style: TextStyle(fontSize: 48, height: 1.0),
        ),
      ),
    );
  }
}

class _BalloonStringPainter extends CustomPainter {
  _BalloonStringPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..quadraticBezierTo(
        size.width,
        size.height / 2,
        size.width / 2,
        size.height,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BalloonStringPainter old) =>
      old.color != color;
}

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({
    required this.round,
    required this.pops,
    required this.onRestart,
    required this.onHome,
  });

  final int round;
  final int pops;
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
              const Text('🎈', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 6),
              const Text(
                'GAME OVER',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE65100),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '$pops개 터뜨림!',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$round라운드 도달',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black.withValues(alpha: 0.6),
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
