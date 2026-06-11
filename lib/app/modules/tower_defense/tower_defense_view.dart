import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '../../shared/answer_pad.dart';
import 'tower_defense_controller.dart';

/// 타워 디펜스 MVP 화면.
///
/// 레이아웃 (위→아래):
/// 1. AppBar — 제목 + 성 HP + 남은 세션 시간.
/// 2. 처치/콤보 점수 바.
/// 3. **선두 문제 배너** — 항상 [activeMonster]의 문제를 고정 위치에서 크게
///    보여 준다. 행진 중인 몬스터 머리 위에 작은 글씨로 띄우는 대신 한 곳에
///    크게 표시해 6~9세 사용자가 "어느 문제를 풀어야 하는지" 헷갈리지 않게 함.
/// 4. 전장(Arena) — 왼쪽에 성(🏰), 오른쪽에서부터 몬스터 행진. 선두 몬스터에는
///    링 표시. 다른 몬스터들은 작은 실루엣처럼 표시(문제 텍스트 X).
/// 5. AnswerDisplay + NumberKeypad — 몬스터 모드와 동일한 컴포넌트 재사용.
///
/// 프레임 단위 위치 계산은 컨트롤러에서 분리돼 있어, 이 위젯의 [Ticker]가
/// 매 프레임 elapsedMs 를 갱신하고 컨트롤러는 그 값을 캐시해
/// 새 몬스터 스폰 시점에 사용한다.
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

  // 이미 "성에 도달함" 통보를 마친 몬스터 id 집합. Ticker가 60Hz로 호출되므로
  // 같은 몬스터에 대해 onMonsterReachCastle을 여러 번 부르지 않도록 가드한다.
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
                Obx(() => _ProblemBanner(monster: _c.activeMonster)),
                const SizedBox(height: 10),
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

/// 선두 몬스터의 문제를 고정 위치에 크게 보여 주는 배너. 몬스터가 없으면
/// "준비 중!" 안내. 6~9세 시선이 가장 먼저 머무는 영역이므로 진한 대비 + 큰
/// 글씨로 가독성 최우선.
class _ProblemBanner extends StatelessWidget {
  const _ProblemBanner({required this.monster});

  final TowerMonster? monster;

  @override
  Widget build(BuildContext context) {
    final text = monster == null
        ? '준비!'
        : '${monster!.problem.questionText} = ?';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF26C6DA), Color(0xFF00838F)],
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
        text,
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

/// 전장 — 왼쪽에 성, 오른쪽 끝에서 몬스터 행진. 몬스터는 자기 [spawnMs]·
/// [travelMs]로 x 위치를 계산해 그린다.
///
/// 선두 몬스터(`controller.activeMonster`)는 골든 링으로 강조. 나머지는
/// 무리감만 주는 실루엣 — 텍스트가 겹쳐 시각적 노이즈가 되는 걸 피한다.
class _Battlefield extends StatelessWidget {
  const _Battlefield({required this.controller, required this.elapsedMs});

  final TowerDefenseController controller;
  final int elapsedMs;

  static const double _monsterSize = 56;
  static const double _castleSize = 72;

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
            // 몬스터들이 걸어가는 단일 가로 차로 — 화면 세로 중앙선.
            final laneCenterY = h / 2;
            // 성의 오른쪽 가장자리. 몬스터는 여기까지 도달하면 성에 닿은 것으로 본다.
            final castleRight = 16.0 + _castleSize;
            return Obx(() {
              final list = controller.monsters.toList();
              final activeId = controller.activeMonster?.id;
              return Stack(
                children: [
                  // 잔디 띠 — 차로 하단에 작은 띠를 둬서 행진 방향을 시각화.
                  Positioned(
                    left: 0,
                    right: 0,
                    top: laneCenterY + _monsterSize / 2 + 6,
                    height: 4,
                    child: Container(
                      color: const Color(0xFF00ACC1).withValues(alpha: 0.18),
                    ),
                  ),
                  // 성.
                  Positioned(
                    left: 12,
                    top: laneCenterY - _castleSize / 2,
                    width: _castleSize,
                    height: _castleSize,
                    child: const _CastleWidget(),
                  ),
                  // 몬스터들.
                  for (final m in list)
                    _buildMonster(
                      m,
                      isActive: m.id == activeId,
                      laneCenterY: laneCenterY,
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

  Widget _buildMonster(
    TowerMonster m, {
    required bool isActive,
    required double laneCenterY,
    required double castleRight,
    required double arenaWidth,
  }) {
    final p = (elapsedMs - m.spawnMs) / m.travelMs;
    // p < 0 : 아직 등장 전(이론상 spawnMs는 과거여야 하지만 클럭 동기 보호용)
    // 0..1 : 행진 중
    // ≥ 1  : 성 도달 — Ticker가 onMonsterReachCastle을 호출하고 컨트롤러가
    //         리스트에서 제거할 때까지 잠깐 화면에 남을 수 있어 안전을 위해 숨김.
    if (p < 0 || p >= 1.0) {
      return SizedBox.shrink(key: ValueKey('tower-monster-${m.id}'));
    }
    // 오른쪽 끝(arenaWidth - _monsterSize)에서 성 오른쪽 끝(castleRight)까지 보간.
    final startX = arenaWidth - _monsterSize - 8;
    final endX = castleRight;
    final left = startX - p * (startX - endX);
    return Positioned(
      key: ValueKey('tower-monster-${m.id}'),
      left: left,
      top: laneCenterY - _monsterSize / 2,
      width: _monsterSize,
      height: _monsterSize,
      child: _MonsterSprite(emoji: m.emoji, isActive: isActive),
    );
  }
}

class _CastleWidget extends StatelessWidget {
  const _CastleWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF006064),
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: const Text('🏰', style: TextStyle(fontSize: 40)),
    );
  }
}

class _MonsterSprite extends StatelessWidget {
  const _MonsterSprite({required this.emoji, required this.isActive});

  final String emoji;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // 선두만 골든 링 + 흰 배경으로 강조. 나머지는 옅은 배경.
        color: isActive
            ? Colors.white.withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.4),
        border: isActive
            ? Border.all(color: const Color(0xFFFFB300), width: 3)
            : null,
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFFFFB300).withValues(alpha: 0.55),
                  blurRadius: 10,
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        emoji,
        style: TextStyle(fontSize: isActive ? 30 : 26),
      ),
    );
  }
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
