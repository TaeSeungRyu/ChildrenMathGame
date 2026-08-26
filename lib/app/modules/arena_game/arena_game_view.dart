import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/arena_upgrade.dart';
import '../../data/services/action_score_service.dart';
import '../../shared/action_record_line.dart';
import 'arena_game_controller.dart';

/// 아레나 화면 — 웨이브 생존.
///
/// 화면 구조:
/// 1. AppBar — WAVE 번호 + 하트 + 웨이브 남은 시간.
/// 2. 상단 바 — 점수, 콤보 배수, 방어막 표시.
/// 3. **아레나** — 남은 적(이모지) 또는 보스 1마리 + HP 바. 정답이면 적이
///    사라지고, 오답이면 화면이 흔들린다. 얻은 점수는 플로팅 텍스트로 뜬다.
/// 4. 문제 카드 + 보기 버튼(2~3개).
/// 5. 오버레이 — 웨이브 클리어 시 **강화 카드 3장**, 종료 시 GAME OVER.
class ArenaGameView extends GetView<ArenaGameController> {
  const ArenaGameView({super.key});

  static const _accent = Color(0xFF4527A0);
  static const _deep = Color(0xFF311B92);
  static const _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () => Text(
            controller.isBossWave
                ? 'WAVE ${controller.wave.value} · BOSS'
                : 'WAVE ${controller.wave.value}',
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
                  Obx(() => _HpHearts(hp: controller.hp.value)),
                  const SizedBox(width: 10),
                  Obx(
                    () => _RemainingTime(seconds: controller.waveRemaining.value),
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
                const _ScoreBar(),
                const SizedBox(height: 8),
                Expanded(child: _ArenaStage(controller: controller)),
                const SizedBox(height: 10),
                const _QuestionCard(),
                const SizedBox(height: 10),
                const _ChoiceRow(),
              ],
            ),
          ),
          Obx(() {
            if (!controller.isChoosingUpgrade.value) {
              return const SizedBox.shrink();
            }
            return _UpgradeOverlay(
              options: controller.upgradeOptions.toList(),
              onPick: controller.chooseUpgrade,
            );
          }),
          Obx(() {
            if (!controller.isGameOver.value) return const SizedBox.shrink();
            return _GameOverOverlay(
              wave: controller.wave.value,
              score: controller.score.value,
              bestCombo: controller.bestCombo.value,
              best: Get.find<ActionScoreService>()
                  .bestFor(ArenaGameController.concept),
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
    // 강화로 하트가 늘 수 있어 칸 수는 "현재 hp와 시작 hp 중 큰 쪽"으로 잡는다.
    // 늘 5칸을 그려 두면 시작하자마자 2칸이 비어 보여 손해 본 느낌이 든다.
    final slots = math.max(hp, ArenaGameController.startingHp);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(slots, (i) {
        final alive = i < hp;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1.5),
          child: Icon(
            alive ? Icons.favorite : Icons.favorite_border,
            size: 20,
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
    final urgent = seconds <= 5;
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

/// 점수 · 콤보 배수 · 방어막. 배수는 콤보 5/10에서 올라가므로 "지금 몇 배인지"를
/// 항상 보여 줘야 콤보를 이어 갈 동기가 생긴다.
class _ScoreBar extends GetView<ArenaGameController> {
  const _ScoreBar();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final multiplier = controller.scoreMultiplier;
      return Row(
        children: [
          const Icon(Icons.star_rounded, color: ArenaGameView._gold, size: 24),
          const SizedBox(width: 4),
          Text(
            '${controller.score.value}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ArenaGameView._accent,
            ),
          ),
          const Spacer(),
          if (controller.hasShield.value) ...[
            const Text('🛡️', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
          ],
          if (multiplier > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

/// 아레나 본체 — 적 이모지(또는 보스) + 웨이브 배너 + 점수 팝업 + 피격 흔들림.
class _ArenaStage extends StatelessWidget {
  const _ArenaStage({required this.controller});

  final ArenaGameController controller;

  // 잔몹 이모지 풀. 웨이브 번호로 골라 웨이브마다 적이 바뀌는 느낌을 준다.
  static const _minions = ['👾', '👻', '🤖', '🦠', '🐙', '🦖'];
  static const _bosses = ['👹', '🐲', '🦑', '🧟'];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF311B92), Color(0xFF5E35B1)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 피격 시 스테이지 전체가 좌우로 흔들린다.
          Obx(() {
            final tick = controller.hitTick.value;
            return _Shake(
              tick: tick,
              child: Obx(
                () => controller.isBossWave
                    ? _BossFigure(
                        emoji: _bosses[controller.wave.value % _bosses.length],
                        hp: controller.enemiesLeft.value,
                        maxHp: controller.waveEnemyTotal.value,
                      )
                    : _MinionRow(
                        emoji:
                            _minions[controller.wave.value % _minions.length],
                        left: controller.enemiesLeft.value,
                        total: controller.waveEnemyTotal.value,
                      ),
              ),
            );
          }),
          const Positioned(top: 10, child: _WaveBanner()),
          const Positioned(bottom: 12, child: _GainPopup()),
        ],
      ),
    );
  }
}

/// 남은 잔몹을 이모지로 늘어놓는다. 쓰러진 자리는 흐릿한 잔상으로 남겨
/// "몇 마리 중 몇 마리 잡았는지"를 한눈에 보여 준다.
class _MinionRow extends StatelessWidget {
  const _MinionRow({
    required this.emoji,
    required this.left,
    required this.total,
  });

  final String emoji;
  final int left;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: List.generate(total, (i) {
          final alive = i < left;
          return AnimatedScale(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            scale: alive ? 1.0 : 0.55,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: alive ? 1.0 : 0.22,
              child: Text(emoji, style: const TextStyle(fontSize: 40)),
            ),
          );
        }),
      ),
    );
  }
}

/// 보스 — 큰 이모지 + HP 바. 잔몹 웨이브와 시각적으로 확실히 달라야 "보스가
/// 나왔다"는 긴장이 생긴다.
class _BossFigure extends StatelessWidget {
  const _BossFigure({
    required this.emoji,
    required this.hp,
    required this.maxHp,
  });

  final String emoji;
  final int hp;
  final int maxHp;

  @override
  Widget build(BuildContext context) {
    final ratio = maxHp == 0 ? 0.0 : (hp / maxHp).clamp(0.0, 1.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 84)),
        const SizedBox(height: 10),
        SizedBox(
          width: 200,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: ratio, end: ratio),
              duration: const Duration(milliseconds: 300),
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 14,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation(Color(0xFFE53935)),
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
    );
  }
}

/// 웨이브가 바뀔 때마다 잠깐 뜨는 "WAVE n" 배너. 입력은 막지 않는다.
class _WaveBanner extends GetView<ArenaGameController> {
  const _WaveBanner();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tick = controller.waveBannerTick.value;
      final wave = controller.wave.value;
      final upgrade = controller.activeUpgrade.value;
      return TweenAnimationBuilder<double>(
        // tick 이 바뀌면 새 애니메이션으로 다시 재생된다.
        key: ValueKey(tick),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1400),
        builder: (context, t, child) {
          // 앞 25%는 나타나고, 뒤 25%는 사라진다.
          final opacity = t < 0.25
              ? t / 0.25
              : (t > 0.75 ? (1 - t) / 0.25 : 1.0);
          return Opacity(opacity: opacity.clamp(0.0, 1.0), child: child);
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
            upgrade != null
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

/// 정답마다 떠오르는 `+35` 팝업. 크리티컬이면 금색 + "퍼펙트!".
class _GainPopup extends GetView<ArenaGameController> {
  const _GainPopup();

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
        duration: const Duration(milliseconds: 800),
        builder: (context, t, child) => Opacity(
          opacity: (1 - t).clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, -22 * t), child: child),
        ),
        child: Text(
          crit ? '퍼펙트! +$gain' : '+$gain',
          style: TextStyle(
            fontSize: crit ? 22 : 20,
            fontWeight: FontWeight.bold,
            color: crit ? ArenaGameView._gold : Colors.white,
          ),
        ),
      );
    });
  }
}

/// 피격 흔들림. [tick] 이 바뀔 때마다 좌우로 감쇠 진동을 한 번 재생한다.
class _Shake extends StatelessWidget {
  const _Shake({required this.tick, required this.child});

  final int tick;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (tick == 0) return child;
    return TweenAnimationBuilder<double>(
      key: ValueKey(tick),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 380),
      builder: (context, t, inner) {
        // 진폭이 줄어드는 사인파 — 툭 치고 잦아든다.
        final dx = math.sin(t * math.pi * 6) * 12 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: inner);
      },
      child: child,
    );
  }
}

class _QuestionCard extends GetView<ArenaGameController> {
  const _QuestionCard();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '${controller.currentProblem.value.questionText} = ?',
            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class _ChoiceRow extends GetView<ArenaGameController> {
  const _ChoiceRow();

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
      _ChoiceState.idle => (const Color(0xFFEDE7F6), ArenaGameView._deep),
    };
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
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
    );
  }
}

/// 웨이브 클리어 보상 — 카드 3장 중 하나를 고른다. 고르기 전엔 다음 웨이브가
/// 시작되지 않는다(타이머도 멈춘 상태).
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
                const Text('⚔️', style: TextStyle(fontSize: 44)),
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
                for (final u in options) ...[
                  _UpgradeCard(upgrade: u, onTap: () => onPick(u)),
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
  const _UpgradeCard({required this.upgrade, required this.onTap});

  final ArenaUpgrade upgrade;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
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
                        color: ArenaGameView._deep,
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
                  color: ArenaGameView._deep,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'WAVE $wave 까지!',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: ArenaGameView._accent,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$score점 · 최고 콤보 $bestCombo',
                style: const TextStyle(fontSize: 16, color: Color(0xFF6D6D6D)),
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
                      label: const Text('홈으로', style: TextStyle(fontSize: 16)),
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
                      label: const Text('다시', style: TextStyle(fontSize: 16)),
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
