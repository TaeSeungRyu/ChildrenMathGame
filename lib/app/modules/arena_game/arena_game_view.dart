import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '../../data/models/arena_upgrade.dart';
import '../../data/services/action_score_service.dart';
import '../../shared/action_record_line.dart';
import 'arena_game_controller.dart';

/// 아레나 화면 — 웨이브 생존.
///
/// 다른 액션 모드와 달리 **화면이 계속 움직인다.** 풍선/물고기와 같은 방식으로
/// 이 위젯이 [Ticker]를 들고 매 프레임 경과 ms를 만들어 자식에게 내려보내며,
/// 적의 부유·전진·보스의 호흡·배경 스크롤·공격 이펙트가 전부 그 ms 하나에서
/// 파생된다. 컨트롤러는 게임 상태와 tick 카운터만 갖고 애니메이션은 모른다.
///
/// 화면 구조:
/// 1. AppBar — WAVE 번호 + 하트 + 남은 시간(5초 이하면 두근거림).
/// 2. 상단 바 — 점수, 콤보 배수(오를 때 팝), 방어막.
/// 3. **아레나** — 흐르는 배경 위로 적이 둥둥 떠 있고, 웨이브 시간이 흐를수록
///    아래(히어로 쪽)로 내려온다. 정답이면 히어로가 ⚡를 쏘고 명중 💥.
/// 4. 문제 카드 + 보기 버튼.
/// 5. 오버레이 — 웨이브 클리어 시 강화 카드(차례로 등장), 종료 시 GAME OVER.
class ArenaGameView extends StatefulWidget {
  const ArenaGameView({super.key});

  static const accent = Color(0xFF4527A0);
  static const deep = Color(0xFF311B92);
  static const gold = Color(0xFFFFB300);

  @override
  State<ArenaGameView> createState() => _ArenaGameViewState();
}

class _ArenaGameViewState extends State<ArenaGameView>
    with SingleTickerProviderStateMixin {
  late final ArenaGameController _c;
  late final Ticker _ticker;
  late final Worker _gameOverWorker;
  Duration? _epoch;
  int _ms = 0;

  @override
  void initState() {
    super.initState();
    _c = Get.find<ArenaGameController>();
    _ticker = createTicker(_onTick)..start();
    // 끝난 뒤에도 배경이 계속 흐르면 오버레이 위로 산만하다. 물고기 잡기와
    // 같은 처리 — 종료 시 티커를 세우고 재시작 때 다시 돌린다.
    _gameOverWorker = ever<bool>(_c.isGameOver, (over) {
      if (over && _ticker.isActive) _ticker.stop();
    });
  }

  void _onTick(Duration elapsed) {
    _epoch ??= elapsed;
    setState(() => _ms = (elapsed - _epoch!).inMilliseconds);
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
        title: Obx(
          () => Text(
            _c.isBossWave
                ? 'WAVE ${_c.wave.value} · BOSS'
                : 'WAVE ${_c.wave.value}',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
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
                  Obx(
                    () => _RemainingTime(
                      seconds: _c.waveRemaining.value,
                      elapsedMs: _ms,
                    ),
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
              10,
              16,
              MediaQuery.of(context).viewPadding.bottom + 16,
            ),
            child: Column(
              children: [
                _ScoreBar(controller: _c),
                const SizedBox(height: 8),
                Expanded(child: _ArenaStage(controller: _c, elapsedMs: _ms)),
                const SizedBox(height: 10),
                _QuestionCard(controller: _c, elapsedMs: _ms),
                const SizedBox(height: 10),
                _ChoiceRow(controller: _c),
              ],
            ),
          ),
          Obx(() {
            if (!_c.isChoosingUpgrade.value) return const SizedBox.shrink();
            return _UpgradeOverlay(
              options: _c.upgradeOptions.toList(),
              onPick: _c.chooseUpgrade,
            );
          }),
          Obx(() {
            if (!_c.isGameOver.value) return const SizedBox.shrink();
            return _GameOverOverlay(
              wave: _c.wave.value,
              score: _c.score.value,
              bestCombo: _c.bestCombo.value,
              best: Get.find<ActionScoreService>()
                  .bestFor(ArenaGameController.concept),
              isNewBest: _c.isNewBest.value,
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
    // 강화로 하트가 늘 수 있어 칸 수는 "현재 hp와 시작 hp 중 큰 쪽"으로 잡는다.
    // 늘 5칸을 그려 두면 시작하자마자 2칸이 비어 보여 손해 본 느낌이 든다.
    final slots = math.max(hp, ArenaGameController.startingHp);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(slots, (i) {
        final alive = i < hp;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1.5),
          child: AnimatedScale(
            // 하트를 잃을 때 남은 하트가 살짝 튄다 — 변화가 눈에 걸리게.
            duration: const Duration(milliseconds: 220),
            scale: alive ? 1.0 : 0.82,
            child: Icon(
              alive ? Icons.favorite : Icons.favorite_border,
              size: 20,
              color: alive
                  ? const Color(0xFFE53935)
                  : Colors.white.withValues(alpha: 0.55),
            ),
          ),
        );
      }),
    );
  }
}

/// 남은 시간. 5초 이하부터는 심장박동처럼 커졌다 작아진다 — 숫자만 빨개지는
/// 것보다 시야 가장자리에서도 알아채기 쉽다.
class _RemainingTime extends StatelessWidget {
  const _RemainingTime({required this.seconds, required this.elapsedMs});

  final int seconds;
  final int elapsedMs;

  @override
  Widget build(BuildContext context) {
    final urgent = seconds <= 5;
    final pulse = urgent
        ? 1 + 0.14 * math.sin(elapsedMs / 1000 * math.pi * 4).abs()
        : 1.0;
    return Transform.scale(
      scale: pulse,
      child: Text(
        '$seconds초',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: urgent ? const Color(0xFFE53935) : null,
        ),
      ),
    );
  }
}

/// 점수 · 콤보 배수 · 방어막. 배수는 콤보 5/10에서 오르므로 "지금 몇 배인지"를
/// 항상 보여 줘야 콤보를 이어 갈 동기가 생긴다. 배수가 오르는 순간에는 칩이
/// 한 번 크게 튄다.
class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.controller});

  final ArenaGameController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final multiplier = controller.scoreMultiplier;
      return Row(
        children: [
          const Icon(Icons.star_rounded, color: ArenaGameView.gold, size: 24),
          const SizedBox(width: 4),
          // 점수는 숫자가 튀지 않고 굴러가듯 올라간다.
          TweenAnimationBuilder<double>(
            tween: Tween(end: controller.score.value.toDouble()),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOut,
            builder: (context, value, _) => Text(
              '${value.round()}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ArenaGameView.accent,
              ),
            ),
          ),
          const Spacer(),
          if (controller.hasShield.value) ...[
            const _ShieldChip(),
            const SizedBox(width: 8),
          ],
          if (multiplier > 1)
            TweenAnimationBuilder<double>(
              // 배수가 바뀔 때마다 새 애니메이션 → 펀치 스케일.
              key: ValueKey(multiplier),
              tween: Tween(begin: 1.6, end: 1.0),
              duration: const Duration(milliseconds: 420),
              curve: Curves.elasticOut,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF7043), Color(0xFFE53935)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '🔥 ×$multiplier',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else if (controller.combo.value >= 2)
            Text(
              '${controller.combo.value} 연속',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE53935),
              ),
            ),
        ],
      );
    });
  }
}

/// 방어막 보유 표시 — 가만히 있지 않고 천천히 맥동해 "지금 지켜지고 있다"는
/// 느낌을 준다.
class _ShieldChip extends StatefulWidget {
  const _ShieldChip();

  @override
  State<_ShieldChip> createState() => _ShieldChipState();
}

class _ShieldChipState extends State<_ShieldChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) => Opacity(
        opacity: 0.65 + 0.35 * _pulse.value,
        child: Transform.scale(
          scale: 1 + 0.10 * _pulse.value,
          child: const Text('🛡️', style: TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}

/// 아레나 본체. 매 프레임 [elapsedMs] 를 받아 배경·적·이펙트를 새로 그린다.
class _ArenaStage extends StatefulWidget {
  const _ArenaStage({required this.controller, required this.elapsedMs});

  final ArenaGameController controller;
  final int elapsedMs;

  @override
  State<_ArenaStage> createState() => _ArenaStageState();
}

class _ArenaStageState extends State<_ArenaStage> {
  // 웨이브별 잔몹/보스 이모지 풀. 웨이브가 바뀌면 적도 바뀌어 지루함을 던다.
  static const _minions = ['👾', '👻', '🤖', '🦠', '🐙', '🦖'];
  static const _bosses = ['👹', '🐲', '🦑', '🧟'];

  static const _attackMs = 300;
  static const _flashMs = 420;

  late final Worker _attackWorker;
  late final Worker _hitWorker;

  // 이펙트가 시작된 시각(프레임 ms). 지난 지 오래면 그리지 않는다.
  int _attackStartMs = -99999;
  int _hitStartMs = -99999;

  @override
  void initState() {
    super.initState();
    // 컨트롤러는 "정답이 나왔다/맞았다"는 사실만 tick 으로 알리고, 그걸 언제
    // 어떻게 그릴지는 전부 여기서 정한다.
    _attackWorker = ever<int>(widget.controller.gainTick, (_) {
      if (mounted) setState(() => _attackStartMs = widget.elapsedMs);
    });
    _hitWorker = ever<int>(widget.controller.hitTick, (_) {
      if (mounted) setState(() => _hitStartMs = widget.elapsedMs);
    });
  }

  @override
  void dispose() {
    _attackWorker.dispose();
    _hitWorker.dispose();
    super.dispose();
  }

  double _progress(int startMs, int durationMs) {
    final dt = widget.elapsedMs - startMs;
    if (dt < 0 || dt > durationMs) return -1; // 재생 중이 아님
    return dt / durationMs;
  }

  @override
  Widget build(BuildContext context) {
    final ms = widget.elapsedMs;
    final c = widget.controller;

    return Obx(() {
      final urgent = c.waveRemaining.value <= 5 && c.waveRemaining.value > 0;
      // 시간이 얼마나 흘렀나 → 적이 얼마나 내려왔나. 숫자를 안 보고 있어도
      // "다가온다"는 압박이 눈에 들어온다.
      final total = c.waveTotalSeconds.value;
      final approach = total == 0
          ? 0.0
          : (1 - c.waveRemaining.value / total).clamp(0.0, 1.0);
      final hitP = _progress(_hitStartMs, _flashMs);
      final attackP = _progress(_attackStartMs, _attackMs);

      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF311B92), Color(0xFF5E35B1)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            // 막판 5초에는 테두리가 붉게 깜빡인다.
            color: urgent
                ? Color.lerp(
                    const Color(0xFFE53935),
                    Colors.transparent,
                    (math.sin(ms / 1000 * math.pi * 4) + 1) / 2,
                  )!
                : Colors.transparent,
            width: 3,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: _Shake(
          progress: hitP,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // 1. 흐르는 배경 — 화면이 정지해 보이지 않게 하는 바탕.
                  Positioned.fill(
                    child: CustomPaint(painter: _StarfieldPainter(ms)),
                  ),

                  // 2. 적 (잔몹 여러 마리 또는 보스 하나).
                  if (c.isBossWave)
                    _BossFigure(
                      emoji: _bosses[c.wave.value % _bosses.length],
                      hp: c.enemiesLeft.value,
                      maxHp: c.waveEnemyTotal.value,
                      elapsedMs: ms,
                      approach: approach,
                      width: w,
                      height: h,
                    )
                  else
                    ..._buildMinions(c, ms, approach, w, h),

                  // 3. 히어로 — 바닥 중앙에서 둥실거리다 공격할 때 튄다.
                  Positioned(
                    left: w / 2 - 26,
                    bottom: 6,
                    child: _Hero(elapsedMs: ms, attackProgress: attackP),
                  ),

                  // 4. 공격 이펙트 — 히어로에서 적 쪽으로 날아가는 ⚡ 와 명중 💥.
                  if (attackP >= 0)
                    ..._buildAttackEffects(attackP, w, h, approach),

                  // 5. 오버레이 텍스트.
                  Positioned(
                    top: 10,
                    left: 0,
                    right: 0,
                    child: Center(child: _WaveBanner(controller: c)),
                  ),
                  Positioned(
                    bottom: 58,
                    left: 0,
                    right: 0,
                    child: Center(child: _GainPopup(controller: c)),
                  ),
                ],
              );
            },
          ),
        ),
      );
    });
  }

  /// 잔몹 배치 — 최대 4열, 필요하면 두 줄. 각자 다른 위상으로 떠 있고,
  /// 웨이브 시간이 흐를수록 전체가 아래로 내려온다.
  List<Widget> _buildMinions(
    ArenaGameController c,
    int ms,
    double approach,
    double w,
    double h,
  ) {
    final total = c.waveEnemyTotal.value;
    final left = c.enemiesLeft.value;
    if (total == 0) return const [];
    final emoji = _minions[c.wave.value % _minions.length];
    final columns = math.min(total, 4);

    // 위(0.06h)에서 시작해 히어로 바로 위(0.52h)까지 내려온다.
    final baseTop = h * (0.06 + 0.46 * approach);
    final rowGap = math.min(46.0, h * 0.14);

    return List.generate(total, (i) {
      final row = i ~/ columns;
      final col = i % columns;
      final inRow = math.min(columns, total - row * columns);
      final slot = w / (inRow + 1);
      final x = slot * (col + 1) - 22;
      // 각자 위상이 다른 부유 운동 — 줄 맞춰 흔들리면 기계처럼 보인다.
      final bob = math.sin(ms / 620 + i * 1.7) * 6;
      final tilt = math.sin(ms / 900 + i) * 0.12;
      final alive = i < left;
      return Positioned(
        left: x,
        top: baseTop + row * rowGap + bob,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutBack,
          scale: alive ? 1.0 : 0.5,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 260),
            opacity: alive ? 1.0 : 0.18,
            child: Transform.rotate(
              angle: alive ? tilt : 0.9, // 쓰러진 적은 옆으로 넘어간다.
              child: Text(emoji, style: const TextStyle(fontSize: 40)),
            ),
          ),
        ),
      );
    });
  }

  /// ⚡ 는 히어로 위치에서 적 무리 쪽으로 날아가고, 도착하는 순간 💥 가 터진다.
  List<Widget> _buildAttackEffects(
    double p,
    double w,
    double h,
    double approach,
  ) {
    final targetY = h * (0.10 + 0.46 * approach) + 20;
    final startY = h - 52;
    final y = startY + (targetY - startY) * p;
    return [
      if (p < 0.85)
        Positioned(
          left: w / 2 - 14,
          top: y,
          child: Opacity(
            opacity: 1 - p * 0.3,
            child: Transform.scale(
              scale: 1 + p * 0.6,
              child: const Text('⚡', style: TextStyle(fontSize: 28)),
            ),
          ),
        ),
      if (p >= 0.55)
        Positioned(
          left: w / 2 - 24,
          top: targetY - 6,
          child: Opacity(
            opacity: ((1 - p) / 0.45).clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 0.8 + (p - 0.55) * 2.2,
              child: const Text('💥', style: TextStyle(fontSize: 44)),
            ),
          ),
        ),
    ];
  }
}

/// 배경에 흐르는 빛 알갱이. 아래에서 위로 천천히 올라가며(전진하는 느낌),
/// 화면 밖으로 나가면 아래에서 다시 들어온다. 위치는 인덱스에서 결정적으로
/// 만들어 매 프레임 흔들리지 않는다.
class _StarfieldPainter extends CustomPainter {
  const _StarfieldPainter(this.elapsedMs);

  final int elapsedMs;

  static const _count = 26;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < _count; i++) {
      // 결정적 유사난수 — i 로만 만들어 프레임마다 같은 알갱이가 유지된다.
      final fx = ((i * 73) % 100) / 100;
      final speed = 12 + (i % 5) * 6; // px/s
      final radius = 1.0 + (i % 3) * 0.9;
      final travel = (elapsedMs / 1000) * speed;
      // 위로 흐르다 위쪽 밖으로 나가면 아래에서 재등장.
      final startY = ((i * 37) % 100) / 100 * size.height;
      var y = startY - travel % (size.height + 20);
      if (y < -10) y += size.height + 20;
      paint.color = Colors.white.withValues(alpha: 0.05 + (i % 4) * 0.045);
      canvas.drawCircle(Offset(fx * size.width, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_StarfieldPainter oldDelegate) =>
      oldDelegate.elapsedMs != elapsedMs;
}

/// 보스 — 숨 쉬듯 커졌다 작아지고 좌우로 천천히 흔들린다. HP가 낮을수록
/// 붉게 달아오르며 떨림이 커져 "곧 쓰러진다"가 보인다.
class _BossFigure extends StatelessWidget {
  const _BossFigure({
    required this.emoji,
    required this.hp,
    required this.maxHp,
    required this.elapsedMs,
    required this.approach,
    required this.width,
    required this.height,
  });

  final String emoji;
  final int hp;
  final int maxHp;
  final int elapsedMs;
  final double approach;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final ratio = maxHp == 0 ? 0.0 : (hp / maxHp).clamp(0.0, 1.0);
    // 체력이 낮을수록 빠르고 크게 떤다.
    final rage = 1 - ratio;
    final breathe = 1 + 0.06 * math.sin(elapsedMs / (620 - 220 * rage));
    final sway = math.sin(elapsedMs / 900) * (10 + 12 * rage);

    return Positioned(
      left: 0,
      right: 0,
      top: height * (0.04 + 0.30 * approach),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.translate(
            offset: Offset(sway, 0),
            child: Transform.scale(
              scale: breathe,
              child: Text(emoji, style: const TextStyle(fontSize: 84)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: math.min(200, width - 60),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: ratio),
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOut,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 14,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation(
                    Color.lerp(
                      const Color(0xFFFF7043),
                      const Color(0xFFE53935),
                      rage,
                    )!,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'BOSS  $hp / $maxHp',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// 히어로 — 평소엔 둥실거리고, 공격할 때 뒤로 반동했다 앞으로 튀어나간다.
class _Hero extends StatelessWidget {
  const _Hero({required this.elapsedMs, required this.attackProgress});

  final int elapsedMs;

  /// 0..1 이면 공격 재생 중, 음수면 대기.
  final double attackProgress;

  @override
  Widget build(BuildContext context) {
    final idle = math.sin(elapsedMs / 700) * 3;
    // 앞부분에서 살짝 웅크렸다가(스케일↓) 튀어나온다.
    final punch = attackProgress < 0
        ? 0.0
        : math.sin(attackProgress * math.pi) * 10;
    final scale = attackProgress < 0
        ? 1.0
        : 1 + 0.18 * math.sin(attackProgress * math.pi);
    return Transform.translate(
      offset: Offset(0, idle - punch),
      child: Transform.scale(
        scale: scale,
        child: const Text('🦸', style: TextStyle(fontSize: 46)),
      ),
    );
  }
}

/// 웨이브가 바뀔 때마다 위에서 미끄러져 들어왔다 사라지는 배너.
class _WaveBanner extends StatelessWidget {
  const _WaveBanner({required this.controller});

  final ArenaGameController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tick = controller.waveBannerTick.value;
      final wave = controller.wave.value;
      final upgrade = controller.activeUpgrade.value;
      // 자릿수가 올라간 웨이브에는 그 사실을 먼저 알린다 — 강화 이름보다
      // 드물게 일어나고, 갑자기 숫자가 커진 이유를 모르면 당황스럽다.
      final raised = controller.raisedDigits.value;
      return TweenAnimationBuilder<double>(
        // tick 이 바뀌면 새 애니메이션으로 다시 재생된다.
        key: ValueKey(tick),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1600),
        builder: (context, t, child) {
          // 앞 20%는 위에서 내려오며 나타나고, 뒤 20%는 위로 빠지며 사라진다.
          final opacity = t < 0.2
              ? t / 0.2
              : (t > 0.8 ? (1 - t) / 0.2 : 1.0);
          final dy = t < 0.2
              ? -24 * (1 - t / 0.2)
              : (t > 0.8 ? -16 * ((t - 0.8) / 0.2) : 0.0);
          return Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.translate(offset: Offset(0, dy), child: child),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            // 진입 선택 화면은 8종 공용이라 아레나 규칙을 설명할 자리가 없다.
            // 첫 웨이브 배너에 목표를 한 줄 얹어 두면 처음 들어온 아이도 뭘
            // 해야 하는지 알 수 있다. 강화 카드 규칙은 클리어 오버레이가 스스로
            // 설명하므로 여기서는 굳이 말하지 않는다.
            raised
                ? 'WAVE $wave · 🔢 숫자가 커져요!'
                : upgrade != null
                    ? 'WAVE $wave  ${upgrade.emoji} ${upgrade.title}'
                    : wave == 1
                        ? 'WAVE 1 · 적을 모두 물리쳐요!'
                        : 'WAVE $wave',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.0,
            ),
          ),
        ),
      );
    });
  }
}

/// 정답마다 떠오르는 `+35` 팝업. 크리티컬이면 금색 + "퍼펙트!" + 더 크게.
class _GainPopup extends StatelessWidget {
  const _GainPopup({required this.controller});

  final ArenaGameController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tick = controller.gainTick.value;
      if (tick == 0) return const SizedBox(height: 28);
      final gain = controller.lastGain.value;
      final crit = controller.lastGainWasCrit.value;
      return TweenAnimationBuilder<double>(
        key: ValueKey(tick),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 850),
        builder: (context, t, child) => Opacity(
          opacity: (1 - t * t).clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, -34 * t),
            // 처음에 확 커졌다가 제 크기로 — 눈에 먼저 걸리게.
            child: Transform.scale(scale: 1 + 0.5 * (1 - t) * (1 - t), child: child),
          ),
        ),
        child: Text(
          crit ? '퍼펙트! +$gain' : '+$gain',
          style: TextStyle(
            fontSize: crit ? 24 : 20,
            fontWeight: FontWeight.bold,
            color: crit ? ArenaGameView.gold : Colors.white,
            shadows: const [
              Shadow(blurRadius: 6, color: Colors.black45, offset: Offset(0, 2)),
            ],
          ),
        ),
      );
    });
  }
}

/// 피격 흔들림. [progress] 가 0..1 이면 감쇠 진동을 그리고, 음수면 정지.
class _Shake extends StatelessWidget {
  const _Shake({required this.progress, required this.child});

  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (progress < 0) return child;
    final dx = math.sin(progress * math.pi * 6) * 14 * (1 - progress);
    return Transform.translate(offset: Offset(dx, 0), child: child);
  }
}

/// 문제 카드 — 새 문제가 뜰 때마다 아래에서 살짝 올라오며 나타난다.
class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.controller, required this.elapsedMs});

  final ArenaGameController controller;
  final int elapsedMs;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final text = '${controller.currentProblem.value.questionText} = ?';
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.25),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: Container(
          // 문제 텍스트를 키로 삼아야 새 문제일 때만 전환이 돈다.
          key: ValueKey(text),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    });
  }
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({required this.controller});

  final ArenaGameController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final choices = controller.choices.toList();
      final selected = controller.selectedChoice.value;
      final revealing = controller.revealing.value;
      final answer = controller.currentProblem.value.answer;
      return Row(
        children: [
          for (var i = 0; i < choices.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: _ChoiceButton(
                value: choices[i],
                // 연출 중에는 정답 칸을 초록으로, 내가 고른 오답을 빨강으로.
                state: !revealing
                    ? _ChoiceState.idle
                    : choices[i] == answer
                        ? _ChoiceState.correct
                        : (choices[i] == selected
                            ? _ChoiceState.wrong
                            : _ChoiceState.idle),
                onTap: () => controller.onChoiceTap(choices[i]),
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
    required this.value,
    required this.state,
    required this.onTap,
  });

  final int value;
  final _ChoiceState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (state) {
      _ChoiceState.correct => (const Color(0xFF43A047), Colors.white),
      _ChoiceState.wrong => (const Color(0xFFE53935), Colors.white),
      _ChoiceState.idle => (const Color(0xFFEDE7F6), ArenaGameView.deep),
    };
    // 맞으면 부풀고, 틀리면 움츠러든다 — 색만 바뀌는 것보다 몸으로 읽힌다.
    final scale = switch (state) {
      _ChoiceState.correct => 1.06,
      _ChoiceState.wrong => 0.94,
      _ChoiceState.idle => 1.0,
    };
    return AnimatedScale(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      scale: scale,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Container(
              height: 66,
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: fg,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 웨이브 클리어 보상 — 카드 3장이 차례로 미끄러져 들어온다. 고르기 전엔
/// 다음 웨이브가 시작되지 않는다(타이머도 멈춘 상태).
class _UpgradeOverlay extends StatelessWidget {
  const _UpgradeOverlay({required this.options, required this.onPick});

  final List<ArenaUpgrade> options;
  final void Function(ArenaUpgrade) onPick;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.62),
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.4, end: 1),
                  duration: const Duration(milliseconds: 520),
                  curve: Curves.elasticOut,
                  builder: (context, s, child) =>
                      Transform.scale(scale: s, child: child),
                  child: const Text('⚔️', style: TextStyle(fontSize: 44)),
                ),
                const SizedBox(height: 6),
                const Text(
                  '웨이브 클리어!',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '힘을 하나 골라요',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 18),
                for (var i = 0; i < options.length; i++) ...[
                  _UpgradeCard(
                    upgrade: options[i],
                    // 카드마다 등장 시점을 어긋나게 해 "차례로 배분되는" 느낌.
                    delayMs: 90 * i,
                    onTap: () => onPick(options[i]),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UpgradeCard extends StatelessWidget {
  const _UpgradeCard({
    required this.upgrade,
    required this.delayMs,
    required this.onTap,
  });

  final ArenaUpgrade upgrade;
  final int delayMs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + delayMs),
      curve: Interval(
        // delay 를 커브 앞부분의 정지 구간으로 표현한다(추가 타이머 없이).
        delayMs / (320 + delayMs),
        1,
        curve: Curves.easeOutBack,
      ),
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(40 * (1 - t), 0), child: child),
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 280,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Text(upgrade.emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        upgrade.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ArenaGameView.deep,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        upgrade.description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6D6D6D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({
    required this.wave,
    required this.score,
    required this.bestCombo,
    required this.best,
    required this.isNewBest,
    required this.onRestart,
    required this.onHome,
  });

  final int wave;
  final int score;
  final int bestCombo;
  final int best;
  final bool isNewBest;
  final VoidCallback onRestart;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.55),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.7, end: 1),
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutBack,
          builder: (context, s, child) =>
              Transform.scale(scale: s, child: child),
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
                const Text('⚔️', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 6),
                const Text(
                  'GAME OVER',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: ArenaGameView.deep,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'WAVE $wave 까지!',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: ArenaGameView.accent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$score점 · 최고 콤보 $bestCombo',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6D6D6D),
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
      ),
    );
  }
}
