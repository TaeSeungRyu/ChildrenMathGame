import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '../../data/services/action_score_service.dart';
import '../../shared/action_record_line.dart';
import 'mole_game_controller.dart';

/// 두더지 잡기 화면 — 객관식 망치질.
///
/// 화면 구조:
/// 1. AppBar — 제목 + HP + 남은 시간.
/// 2. 점수 바 — 처치 수 + 콤보.
/// 3. **문제 배너** — 현재 풀어야 할 한 문제를 크게 표시.
/// 4. **3×3 두더지 그리드** — 각 칸에 두더지가 잠시 튀어나왔다 들어감.
///    두더지 등에 답 후보 숫자가 적혀 있어, 정답이 적힌 두더지만 탭하면 처치.
///
/// A/B/C 와의 핵심 차이는 **숫자 키패드가 없다**는 것 — 입력이 아닌 "선택"에
/// 기반한 반응속도 게임이라 게임 결이 완전히 다르다.
class MoleGameView extends StatefulWidget {
  const MoleGameView({super.key});

  @override
  State<MoleGameView> createState() => _MoleGameViewState();
}

class _MoleGameViewState extends State<MoleGameView>
    with SingleTickerProviderStateMixin {
  late final MoleGameController _c;
  late final Ticker _ticker;
  Duration? _epoch;
  int _ms = 0;
  late final Worker _gameOverWorker;

  @override
  void initState() {
    super.initState();
    _c = Get.find<MoleGameController>();
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
          '두더지 잡기',
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
                    kills: _c.kills.value,
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
                Expanded(child: _MoleGrid(controller: _c, elapsedMs: _ms)),
              ],
            ),
          ),
          Obx(() {
            if (!_c.isGameOver.value) return const SizedBox.shrink();
            return _GameOverOverlay(
              kills: _c.kills.value,
              best: Get.find<ActionScoreService>()
                  .bestFor(MoleGameController.concept),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(MoleGameController.maxHp, (i) {
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
    const accent = Color(0xFF33691E);
    return Row(
      children: [
        const Icon(Icons.gps_fixed, color: accent, size: 22),
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

/// 라운드의 한 문제를 큰 글씨로 보여 주는 배너. 두더지가 들고 있는 후보 숫자가
/// 답이 맞는지 빠르게 판단하려면 사용자가 자주 시선을 이쪽으로 돌려야 하므로
/// 진한 대비로 가독성 최우선.
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
          colors: [Color(0xFFAED581), Color(0xFF558B2F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withValues(alpha: 0.22),
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

/// 3×3 그리드. 가용 영역에서 정사각형 셀로 균등 분배. GridView 대신 Column/Row 로
/// 직접 배치한 이유: 각 셀에 정확한 정사각형 크기 + gap 을 보장하고, 그리드 전체를
/// 가용 영역 중앙에 배치하기 위함.
class _MoleGrid extends StatelessWidget {
  const _MoleGrid({required this.controller, required this.elapsedMs});

  final MoleGameController controller;
  final int elapsedMs;

  static const double _gap = 8;
  static const int _cols = 3;
  static const int _rows = 3;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        // 셀 한 변 = min(가용폭/3, 가용높이/3) - gap 보정.
        final maxByWidth = (c.maxWidth - _gap * (_cols - 1)) / _cols;
        final maxByHeight = (c.maxHeight - _gap * (_rows - 1)) / _rows;
        final cellSize = math.min(maxByWidth, maxByHeight);
        return Center(
          child: SizedBox(
            width: cellSize * _cols + _gap * (_cols - 1),
            height: cellSize * _rows + _gap * (_rows - 1),
            child: Obx(() {
              final list = controller.moles;
              return Column(
                children: [
                  for (var r = 0; r < _rows; r++) ...[
                    if (r > 0) const SizedBox(height: _gap),
                    Row(
                      children: [
                        for (var col = 0; col < _cols; col++) ...[
                          if (col > 0) const SizedBox(width: _gap),
                          SizedBox(
                            width: cellSize,
                            height: cellSize,
                            child: _MoleCell(
                              mole: list[r * _cols + col],
                              cellSize: cellSize,
                              elapsedMs: elapsedMs,
                              onTap: () =>
                                  controller.onMoleTap(r * _cols + col),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              );
            }),
          ),
        );
      },
    );
  }
}

/// 한 칸. 잔디 배경 + 흙더미(아래) + 두더지(애니메이션) 로 구성.
///
/// 두더지가 없는 칸은 흙더미와 빈 구멍만 보인다. 두더지가 있으면 lifespan
/// 진행도에 따라 흙더미 뒤에서 솟아올라 잠시 멈춘 뒤 다시 내려간다. 두더지가
/// 망치질됐다면 정상 pop 시퀀스 대신 망치 + squash 애니메이션으로 전환.
class _MoleCell extends StatelessWidget {
  const _MoleCell({
    required this.mole,
    required this.cellSize,
    required this.elapsedMs,
    required this.onTap,
  });

  final Mole? mole;
  final double cellSize;
  final int elapsedMs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dirtH = cellSize * 0.26;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: mole == null ? null : onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFDCEDC8), Color(0xFFAED581)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              // (z=0) 두더지 — 흙더미 뒤에 가려지도록 먼저 그린다.
              if (mole != null)
                _MoleSprite(
                  mole: mole!,
                  cellSize: cellSize,
                  dirtHeight: dirtH,
                  elapsedMs: elapsedMs,
                ),
              // (z=1) 흙더미 — 셀 하단을 차지하며 두더지의 아래 부분을 가린다.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: dirtH,
                child: _DirtMound(width: cellSize, height: dirtH),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 흙더미 — 갈색 둥근 모양 + 가운데에 진한 타원(구멍 입구).
class _DirtMound extends StatelessWidget {
  const _DirtMound({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF8D6E63), Color(0xFF5D4037)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
          ),
        ),
        // 구멍 입구 — 윗면의 진한 타원.
        Positioned(
          left: width * 0.18,
          right: width * 0.18,
          top: -1,
          height: height * 0.45,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF3E2723),
              borderRadius: BorderRadius.all(
                Radius.elliptical(width * 0.4, height * 0.22),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 두더지 본체 — pop 애니메이션 + 답 후보 숫자 배지 + 망치질 이펙트.
///
/// 정상 흐름: lifespan 동안 (1) 0..0.12 솟아오름, (2) 0.12..0.88 정지,
/// (3) 0.88..1.0 다시 들어감. hiddenY 0=완전 노출, 1=완전 매장.
///
/// 망치질: [Mole.hammeredMs] 가 set 된 순간부터 pop 진행도를 0.5(완전히 보이는
/// 상태)에 고정하고, hammerAnimMs 동안 정답이면 🔨 + 💥, 오답이면 ❌ + 좌우
/// 흔들림 이펙트를 표시. 두더지 본체는 squash + fade.
class _MoleSprite extends StatelessWidget {
  const _MoleSprite({
    required this.mole,
    required this.cellSize,
    required this.dirtHeight,
    required this.elapsedMs,
  });

  final Mole mole;
  final double cellSize;
  final double dirtHeight;
  final int elapsedMs;

  @override
  Widget build(BuildContext context) {
    final rawProgress = (elapsedMs - mole.appearedMs) / mole.lifespanMs;
    final progress = mole.hammeredMs != null
        ? 0.5
        : rawProgress.clamp(0.0, 1.0);

    double hiddenY;
    if (progress < 0.12) {
      hiddenY = 1 - (progress / 0.12);
    } else if (progress < 0.88) {
      hiddenY = 0;
    } else {
      hiddenY = (progress - 0.88) / 0.12;
    }

    final hp = mole.hammeredMs == null
        ? 0.0
        : ((elapsedMs - mole.hammeredMs!) /
                MoleGameController.hammerAnimMs)
            .clamp(0.0, 1.0);
    final hammered = mole.hammeredMs != null;

    final moleSize = cellSize * 0.42;
    final spritePopHeight = cellSize * 0.55;

    final core = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _NumberBadge(number: mole.number),
        const SizedBox(height: 2),
        Text(
          '🦫',
          style: TextStyle(fontSize: moleSize, height: 1.0),
        ),
      ],
    );

    final scaleY = hammered ? (1 - hp * 0.55).clamp(0.0, 1.0) : 1.0;
    final fade = hammered ? (1 - hp).clamp(0.0, 1.0) : 1.0;
    final shakeX = (hammered && !mole.isCorrect)
        ? math.sin(hp * math.pi * 6) * 5
        : 0.0;

    return Positioned(
      left: 0,
      right: 0,
      // 두더지가 fully popped 상태일 때 흙더미 살짝 위에 머리가 나오도록.
      bottom: dirtHeight * 0.5,
      child: Center(
        child: SizedBox(
          width: cellSize,
          // 두더지 + 배지 + 망치/💥 가 잘리지 않을 충분한 높이. 0.7 은 이모지 라인
          // 메트릭 여유분까지 고려하면 약 0.6px 마다 overflow 가 떴다 — 0.85 로 잡고
          // 흙더미와는 dirtHeight*0.5 만큼만 겹치게 둔다 (셀 총 높이 안에 들어옴:
          // 0.85 + 0.13 = 0.98 < 1.0).
          height: cellSize * 0.85,
          child: Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              Transform.translate(
                offset: Offset(shakeX, hiddenY * spritePopHeight),
                child: Transform.scale(
                  scaleY: scaleY,
                  alignment: Alignment.bottomCenter,
                  child: Opacity(opacity: fade, child: core),
                ),
              ),
              if (hammered)
                _HammerOverlay(
                  isCorrect: mole.isCorrect,
                  progress: hp,
                  cellSize: cellSize,
                ),
            ],
          ),
        ),
      ),
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
        border: Border.all(color: const Color(0xFF5D4037), width: 1.5),
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
          color: Color(0xFF3E2723),
        ),
      ),
    );
  }
}

/// 망치질 이펙트.
///
/// 정답: 🔨 가 우상단에서 회전하며 떨어진 뒤 💥 가 터지듯 확장.
/// 오답: ❌ 가 두더지 위에 떠올라 페이드 — 빨간 강조로 학습 피드백.
class _HammerOverlay extends StatelessWidget {
  const _HammerOverlay({
    required this.isCorrect,
    required this.progress,
    required this.cellSize,
  });

  final bool isCorrect;
  final double progress;
  final double cellSize;

  @override
  Widget build(BuildContext context) {
    if (isCorrect) {
      final dropT = (progress / 0.55).clamp(0.0, 1.0);
      final boomT = ((progress - 0.45) / 0.55).clamp(0.0, 1.0);
      return Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (boomT > 0)
            Transform.scale(
              scale: 0.5 + boomT * 1.4,
              child: Opacity(
                opacity: (1 - boomT).clamp(0.0, 1.0),
                child: Text(
                  '💥',
                  style: TextStyle(fontSize: cellSize * 0.45, height: 1.0),
                ),
              ),
            ),
          Transform.translate(
            offset: Offset(
              cellSize * 0.22 - dropT * cellSize * 0.22,
              -cellSize * 0.32 + dropT * cellSize * 0.32,
            ),
            child: Transform.rotate(
              angle: -math.pi / 4 + dropT * math.pi / 3,
              child: Opacity(
                opacity: (1 - boomT * 0.8).clamp(0.0, 1.0),
                child: Text(
                  '🔨',
                  style: TextStyle(fontSize: cellSize * 0.34, height: 1.0),
                ),
              ),
            ),
          ),
        ],
      );
    }
    return Transform.scale(
      scale: 0.6 + progress * 0.5,
      child: Opacity(
        opacity: (1 - progress * 0.5).clamp(0.0, 1.0),
        child: Text(
          '❌',
          style: TextStyle(fontSize: cellSize * 0.34, height: 1.0),
        ),
      ),
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({
    required this.kills,
    required this.best,
    required this.isNewBest,
    required this.onRestart,
    required this.onHome,
  });

  final int kills;
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
              const Text('🦫', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 6),
              const Text(
                'GAME OVER',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF33691E),
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
