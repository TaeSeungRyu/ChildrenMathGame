import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '../../shared/answer_pad.dart';
import 'tower_defense_controller.dart';

/// 타워 디펜스 화면 — 다중 타겟 + 답 매칭.
///
/// 화면 구조 (위→아래):
/// 1. AppBar — 제목 + 성 HP + 남은 세션 시간.
/// 2. 처치/콤보 점수 바.
/// 3. **전장** — 가로 3차로. 왼쪽에 성, 오른쪽에서 몬스터들이 각자 자기 문제를
///    머리 위에 들고 행진. 사용자가 키패드로 어떤 답을 입력하면 그 답을 가진
///    가장 가까운 몬스터에 마법이 발사돼 폭발. 일치 답이 없으면 오답으로 처리.
/// 4. AnswerDisplay + NumberKeypad — 다른 액션 모드들과 동일.
///
/// 컨트롤러는 큐/스폰 타이밍/HP 만 관리하고, 프레임 단위 위치/이펙트는 이
/// 위젯의 [Ticker]가 (sessionElapsedMs - spawnMs)/travelMs 로 계산한다.
class TowerDefenseView extends StatefulWidget {
  const TowerDefenseView({super.key});

  @override
  State<TowerDefenseView> createState() => _TowerDefenseViewState();
}

class _TowerDefenseViewState extends State<TowerDefenseView>
    with SingleTickerProviderStateMixin {
  late final TowerDefenseController _c;
  late final Ticker _ticker;
  Duration? _epoch;
  int _ms = 0;

  // 이미 "성에 도달함" 통보를 마친 몬스터 id 집합. Ticker 가 60Hz로 호출되므로
  // 같은 몬스터에 대해 onMonsterReachCastle 을 여러 번 부르지 않도록 가드한다.
  final Set<int> _hit = {};

  late final Worker _gameOverWorker;

  @override
  void initState() {
    super.initState();
    _c = Get.find<TowerDefenseController>();
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
    _checkReaches();
  }

  void _checkReaches() {
    final snapshot = _c.monsters.toList();
    for (final m in snapshot) {
      if (_hit.contains(m.id)) continue;
      if (m.hitAtMs != null) continue; // 처치 이펙트 중이면 성 도달로 안 침.
      final p = (_ms - m.spawnMs) / m.travelMs;
      if (p >= 1.0) {
        _hit.add(m.id);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _c.onMonsterReachCastle(m.id);
        });
      }
    }
  }

  void _onRestart() {
    _hit.clear();
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
          '타워 디펜스',
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
                    kills: _c.kills.value,
                    combo: _c.combo.value,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(child: _Battlefield(controller: _c, elapsedMs: _ms)),
                const SizedBox(height: 12),
                Obx(() => AnswerDisplay(value: _c.answer.value)),
                const SizedBox(height: 10),
                NumberKeypad(
                  onAppendDigit: _c.appendDigit,
                  onDelete: _c.deleteLast,
                  onSubmit: _c.submit,
                ),
              ],
            ),
          ),
          Obx(() {
            if (!_c.isGameOver.value) return const SizedBox.shrink();
            return _GameOverOverlay(
              kills: _c.kills.value,
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
      children: List.generate(TowerDefenseController.maxHp, (i) {
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
  const _ScoreBar({required this.kills, required this.combo});

  final int kills;
  final int combo;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF006064);
    return Row(
      children: [
        const Icon(Icons.castle, color: accent, size: 22),
        const SizedBox(width: 6),
        Text(
          '처치 $kills',
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

/// 전장 — 가로 3차로(lane). 각 몬스터는 자기 차로 안에서 자기 [spawnMs]/
/// [travelMs] 에 따라 우→좌로 행진하며, 머리 위에 자기 문제를 들고 있다.
/// 사용자가 키패드로 답을 입력해 "입력"을 누르면 답이 일치하는 가장 가까운
/// 몬스터가 폭발한다. 처치 이펙트 동안 좌표는 hitAtMs 시점에서 freeze.
class _Battlefield extends StatelessWidget {
  const _Battlefield({required this.controller, required this.elapsedMs});

  final TowerDefenseController controller;
  final int elapsedMs;

  // 몬스터 한 셀의 시각 크기. 위쪽에 문제 카드, 아래쪽에 몬스터 sprite 가 들어가는
  // 세로 스택 구조라 sprite 보다 넉넉하게 잡아 둔다. 이전 78 은 Column 의 자연 높이
  // (문제 카드 ~28 + 갭 + 이모지 영역 ~56)보다 작아 overflow 경고가 떴다.
  static const double _spriteHeight = 52;
  static const double _problemCardHeight = 28;
  static const double _cellWidth = 96;
  static const double _cellHeight = _problemCardHeight + 4 + _spriteHeight; // 84

  // 성 가로 너비. 전체 3 차로를 한 번에 방어하는 큰 성 한 채를 가로 왼쪽 가장자리에.
  static const double _castleWidth = 64;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final h = c.maxHeight;
            // 각 차로의 세로 중심 y.
            final laneHeight = h / TowerDefenseController.laneCount;
            // 성의 오른쪽 경계 — 몬스터가 여기까지 오면 성 도달.
            final castleRight = 12.0 + _castleWidth;
            return Obx(() {
              final list = controller.monsters.toList();
              return Stack(
                children: [
                  // 차로 구분선 — 옅은 가로 점선 느낌의 띠 2 개.
                  for (var i = 1; i < TowerDefenseController.laneCount; i++)
                    Positioned(
                      left: 8,
                      right: 8,
                      top: i * laneHeight - 1,
                      height: 2,
                      child: Container(
                        color:
                            const Color(0xFF00ACC1).withValues(alpha: 0.18),
                      ),
                    ),
                  // 성 — 차로 3 개 전부를 세로로 덮는다.
                  Positioned(
                    left: 12,
                    top: 8,
                    bottom: 8,
                    width: _castleWidth,
                    child: const _CastleWidget(),
                  ),
                  // 몬스터 + 처치 이펙트.
                  for (final m in list)
                    _buildMonster(
                      m,
                      laneHeight: laneHeight,
                      castleRight: castleRight,
                      arenaWidth: w,
                    ),
                  // 마법 발사 이펙트 — 성에서 처치된 몬스터까지 짧게 직선 트레일.
                  // 처치 이펙트(0..1) 의 앞 절반(0..0.5) 구간 동안만 표시해
                  // "발사 → 도달 → 폭발" 순서감을 만든다.
                  for (final m in list)
                    if (m.hitAtMs != null)
                      _buildSpellTrail(
                        m,
                        laneHeight: laneHeight,
                        castleRight: castleRight,
                        arenaWidth: w,
                      ),
                ],
              );
            });
          },
        ),
      ),
    );
  }

  // 몬스터 한 마리의 위치/이펙트.
  Widget _buildMonster(
    TowerMonster m, {
    required double laneHeight,
    required double castleRight,
    required double arenaWidth,
  }) {
    // 위치 계산용 기준 ms — 살아 있으면 현재, 처치 중이면 freeze.
    final refMs = m.hitAtMs ?? elapsedMs;
    final p = (refMs - m.spawnMs) / m.travelMs;
    if (p < 0 || (m.hitAtMs == null && p >= 1.0)) {
      return SizedBox.shrink(key: ValueKey('td-${m.id}'));
    }
    final clamped = p < 0 ? 0.0 : (p > 1.0 ? 1.0 : p);

    // 오른쪽 끝(arenaWidth - _cellWidth - 8) 에서 성 오른쪽(castleRight) 까지 보간.
    final startX = arenaWidth - _cellWidth - 8;
    final endX = castleRight;
    final left = startX - clamped * (startX - endX);

    final laneCenterY = laneHeight * m.laneIndex + laneHeight / 2;
    final top = laneCenterY - _cellHeight / 2;

    // 처치 이펙트 진행도(0..1). null 이면 살아 있음.
    final defeatProgress = m.hitAtMs == null
        ? 0.0
        : ((elapsedMs - m.hitAtMs!) /
                TowerDefenseController.defeatDurationMs)
            .clamp(0.0, 1.0);

    return Positioned(
      key: ValueKey('td-${m.id}'),
      left: left,
      top: top,
      width: _cellWidth,
      height: _cellHeight,
      child: IgnorePointer(
        child: _MonsterCell(
          monster: m,
          problemCardHeight: _problemCardHeight,
          spriteHeight: _spriteHeight,
          defeatProgress: defeatProgress,
        ),
      ),
    );
  }

  // 처치된 몬스터 위로 성에서 마법 트레일을 그려준다. 0..0.4 구간 동안 끝점이
  // 성에서 몬스터까지 이동(=마법 비행), 그 이후 0.4..1.0 동안 점차 페이드 아웃
  // (이 사이엔 폭발 💥 이펙트가 우위). 0.5 에서 한 번에 사라지지 않게 해 깜빡임 방지.
  Widget _buildSpellTrail(
    TowerMonster m, {
    required double laneHeight,
    required double castleRight,
    required double arenaWidth,
  }) {
    final defeatProgress = m.hitAtMs == null
        ? 0.0
        : ((elapsedMs - m.hitAtMs!) /
                TowerDefenseController.defeatDurationMs)
            .clamp(0.0, 1.0);
    final refMs = m.hitAtMs ?? elapsedMs;
    final p = (refMs - m.spawnMs) / m.travelMs;
    final clamped = p < 0 ? 0.0 : (p > 1.0 ? 1.0 : p);
    final startX = arenaWidth - _cellWidth - 8;
    final endX = castleRight;
    final monsterLeft = startX - clamped * (startX - endX);
    final monsterCenterX = monsterLeft + _cellWidth / 2;
    final monsterCenterY = laneHeight * m.laneIndex + laneHeight / 2;

    // 성의 마법 발사 지점(전면 중앙).
    final castleFireX = castleRight - 8;
    final castleCenterY = laneHeight * TowerDefenseController.laneCount / 2;

    // 끝점 이동(0..0.4) — 그 이후는 몬스터 위치에 고정.
    final tipT = (defeatProgress / 0.4).clamp(0.0, 1.0);
    final tipX = castleFireX + (monsterCenterX - castleFireX) * tipT;
    final tipY = castleCenterY + (monsterCenterY - castleCenterY) * tipT;

    // 0..0.4 까지 full opacity, 그 후 0.4..1.0 동안 부드럽게 페이드 아웃.
    final fadeT = ((defeatProgress - 0.4) / 0.6).clamp(0.0, 1.0);
    final opacity = (1 - fadeT).clamp(0.0, 1.0);
    if (opacity <= 0.01) {
      return SizedBox.shrink(key: ValueKey('td-trail-${m.id}'));
    }

    return Positioned.fill(
      key: ValueKey('td-trail-${m.id}'),
      child: IgnorePointer(
        child: CustomPaint(
          painter: _SpellTrailPainter(
            from: Offset(castleFireX, castleCenterY),
            to: Offset(tipX, tipY),
            opacity: opacity,
          ),
        ),
      ),
    );
  }
}

class _CastleWidget extends StatelessWidget {
  const _CastleWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF006064), width: 2),
      ),
      alignment: Alignment.center,
      child: const FittedBox(
        child: Text('🏰', style: TextStyle(fontSize: 44)),
      ),
    );
  }
}

/// 한 몬스터의 셀 — 문제 카드(상단) + 본체 sprite(하단) + (처치 시) 폭발 이펙트.
///
/// Column 대신 Stack 으로 그린다: Column 은 자식들의 자연 높이가 부모
/// 제약(Positioned 의 [_Battlefield._cellHeight])을 넘으면 overflow 경고가 뜨는데,
/// 이모지의 line-height 같은 미세 변동까지 다 맞추기 어렵다. Stack 으로 위치를
/// 절대 좌표(top/bottom)로 명시하면 자식 자연 높이가 약간 커도 외부에 영향 X.
///
/// 처치 애니메이션은 전체 [defeatProgress] (0..1) 위에서 연속적으로 동작 — 중간에
/// 자식을 빼고 넣는 분기를 두면 깜빡임이 발생하므로, 같은 자식을 opacity/scale 만
/// 보간한다.
class _MonsterCell extends StatelessWidget {
  const _MonsterCell({
    required this.monster,
    required this.problemCardHeight,
    required this.spriteHeight,
    required this.defeatProgress,
  });

  final TowerMonster monster;
  final double problemCardHeight;
  final double spriteHeight;
  final double defeatProgress;

  @override
  Widget build(BuildContext context) {
    final isDefeating = monster.hitAtMs != null;
    // 본체/문제 카드는 처치가 시작되면 부드럽게 페이드 아웃.
    final fade = (1 - defeatProgress).clamp(0.0, 1.0);
    // 폭발은 0..1 전 구간 동안 살짝 커지며 페이드 아웃. 처치 시작과 동시에 등장.
    final explosionScale = 0.6 + defeatProgress * 0.9;
    final explosionOpacity = isDefeating
        ? (1 - defeatProgress).clamp(0.0, 1.0)
        : 0.0;

    return Stack(
      children: [
        // 문제 카드 — 상단에 고정.
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: problemCardHeight,
          child: Opacity(
            opacity: fade,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF00838F),
                  width: 1.2,
                ),
              ),
              alignment: Alignment.center,
              child: FittedBox(
                child: Text(
                  monster.problem.questionText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF004D40),
                  ),
                ),
              ),
            ),
          ),
        ),
        // 몬스터 sprite — 하단 영역에 고정. 폭발 이펙트도 같은 영역 중앙에 겹친다.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: spriteHeight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: fade,
                child: Text(
                  monster.emoji,
                  style: TextStyle(
                    fontSize: spriteHeight * 0.78,
                    height: 1.0,
                  ),
                ),
              ),
              if (isDefeating)
                Transform.scale(
                  scale: explosionScale,
                  child: Opacity(
                    opacity: explosionOpacity,
                    child: Text(
                      '💥',
                      style: TextStyle(
                        fontSize: spriteHeight * 0.85,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 성에서 발사된 마법 트레일을 그리는 painter. from→to 직선을 노란/주황 그라데이션
/// stroke + 끝점에 작은 글로우로 표현. 짧은 시간만 보이는 이펙트라 디테일은 최소화.
class _SpellTrailPainter extends CustomPainter {
  _SpellTrailPainter({
    required this.from,
    required this.to,
    required this.opacity,
  });

  final Offset from;
  final Offset to;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFFFFEB3B).withValues(alpha: opacity * 0.85),
          const Color(0xFFFF7043).withValues(alpha: opacity),
        ],
      ).createShader(Rect.fromPoints(from, to))
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(from, to, paint);

    // 트레일 끝점의 작은 글로우.
    final tipPaint = Paint()
      ..color =
          const Color(0xFFFFC107).withValues(alpha: (opacity * 0.7).clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(to, 6, tipPaint);
  }

  @override
  bool shouldRepaint(covariant _SpellTrailPainter old) =>
      old.from != from || old.to != to || old.opacity != opacity;
}

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({
    required this.kills,
    required this.onRestart,
    required this.onHome,
  });

  final int kills;
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
              const Text('🏰', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 6),
              const Text(
                'GAME OVER',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF006064),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '$kills마리 처치!',
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

