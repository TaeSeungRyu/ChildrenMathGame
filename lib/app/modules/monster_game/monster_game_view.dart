import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../shared/answer_pad.dart';
import 'monster_game_controller.dart';

/// 몬스터 처치 MVP 화면.
///
/// 상단: HP 하트 + 처치/콤보 카운터.
/// 본문: 낙하 Arena — 몬스터(이모지) + 문제 카드가 8초~4초에 걸쳐 위→아래로
/// 내려온다. 정답 입력 시 즉시 다음 몬스터로 교체, 바닥 도달/오답이면 HP 차감.
/// HP 0 → 풀스크린 오버레이로 다시/홈으로 선택.
///
/// 컨트롤러는 게임 상태만 가지고 [MonsterGameController.spawnTrigger]로
/// "새 라운드 시작" 신호를 보낸다. 실제 낙하 트윈은 이 위젯의 로컬
/// [AnimationController]가 담당해 vsync에 맞춰 부드럽게 진행한다.
class MonsterGameView extends StatefulWidget {
  const MonsterGameView({super.key});

  @override
  State<MonsterGameView> createState() => _MonsterGameViewState();
}

class _MonsterGameViewState extends State<MonsterGameView>
    with SingleTickerProviderStateMixin {
  late final MonsterGameController _c;
  late final AnimationController _fall;

  @override
  void initState() {
    super.initState();
    _c = Get.find<MonsterGameController>();
    _fall = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _c.currentFallMs),
    )..addStatusListener(_onFallStatus);

    // 새 몬스터 신호 → 낙하 트윈 재시작.
    ever<int>(_c.spawnTrigger, (_) => _startFall());
    // 게임오버 시 트윈 일시정지.
    ever<bool>(_c.isGameOver, (over) {
      if (over) _fall.stop();
    });

    // 최초 낙하는 첫 빌드 직후에 시작 (initState 시점엔 컨트롤러 onInit 이후).
    WidgetsBinding.instance.addPostFrameCallback((_) => _startFall());
  }

  void _startFall() {
    if (_c.isGameOver.value) return;
    _fall.duration = Duration(milliseconds: _c.currentFallMs);
    _fall.reset();
    _fall.forward();
  }

  void _onFallStatus(AnimationStatus s) {
    if (s == AnimationStatus.completed) {
      _c.onMonsterReachedBottom();
    }
  }

  @override
  void dispose() {
    _fall.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '몬스터 처치',
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
                  Obx(
                    () => _RemainingTime(seconds: _c.remainingSeconds),
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
                Expanded(child: _FallArena(controller: _fall)),
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
              onRestart: _c.restart,
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
      children: List.generate(MonsterGameController.maxHp, (i) {
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

/// 남은 세션 시간(초). 10초 이하로 떨어지면 빨간색으로 강조해 어린이 사용자가
/// 마지막 카운트다운임을 즉시 알아차리게 한다. 기존 game_view의 동일 패턴을
/// 따라 일관성을 유지.
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
    const accent = Color(0xFF4A148C);
    return Row(
      children: [
        const Icon(Icons.shield, color: accent, size: 22),
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

/// 낙하 트랙. LayoutBuilder로 가용 높이를 잰 뒤, [controller].value (0→1) 를
/// 몬스터 카드의 top 오프셋에 매핑한다. 카드 하단이 트랙 바닥에 닿는 순간을
/// 1.0으로 맞춰 두면 '바닥 도달' 트리거가 시각적으로도 정확히 일치한다.
class _FallArena extends StatelessWidget {
  const _FallArena({required this.controller});

  final AnimationController controller;

  // 이모지(56pt, 줄높이 포함 ~70dp) + 4 + 문제 카드(패딩 16 + 26pt 텍스트 줄높이
  // 포함 ~36dp = 52dp) ≈ 126dp가 자연 높이. Jua 폰트의 line-height 여유 + 여백을
  // 위해 16dp 헤드룸을 더해 144로 고정. 더 줄이면 카드 안쪽이 잘려 오버플로
  // 경고가 다시 뜬다.
  static const double _cardHeight = 144;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE1F5FE), Color(0xFFFCE4EC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, c) {
            final maxTop = (c.maxHeight - _cardHeight).clamp(0.0, double.infinity);
            return Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 4,
                    color: const Color(0xFF4A148C).withValues(alpha: 0.18),
                  ),
                ),
                AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) {
                    final p = controller.value.clamp(0.0, 1.0);
                    final top = maxTop * p;
                    return Positioned(
                      top: top,
                      left: 0,
                      right: 0,
                      child: const _MonsterCard(),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MonsterCard extends StatelessWidget {
  const _MonsterCard();

  @override
  Widget build(BuildContext context) {
    final c = Get.find<MonsterGameController>();
    return SizedBox(
      height: _FallArena._cardHeight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('👹', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 4),
          Obx(() {
            final p = c.current.value;
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF4A148C),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '${p.questionText} = ?',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A148C),
                ),
              ),
            );
          }),
        ],
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
              const Text('👹', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 6),
              const Text(
                'GAME OVER',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A148C),
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
