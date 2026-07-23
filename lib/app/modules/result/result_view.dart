import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/problem_attempt.dart';
import '../../data/services/profile_service.dart';
import '../../routes/app_routes.dart';
import '../../shared/attempt_tile.dart';
import '../../shared/date_format.dart';
import '../../shared/korean_particle.dart';
import '../../shared/mixed_label.dart';
import 'result_controller.dart';

class ResultView extends StatefulWidget {
  const ResultView({super.key});

  @override
  State<ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends State<ResultView> {
  final ResultController controller = Get.find<ResultController>();
  final GlobalKey _shareKey = GlobalKey();
  bool _sharing = false;

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final boundary = _shareKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;
      final pngBytes = bytes.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/math_result_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(pngBytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: _summaryText(),
      );
    } catch (_) {
      // 공유 취소 또는 실패는 조용히 무시한다.
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  String _summaryText() {
    final r = controller.record;
    final label = controller.isTimesTable
        ? '${controller.tableNumber}단 연습'
        : controller.isMixed
              ? '혼합(${componentLabel(r)}) 레벨 ${r.level}'
                    '${controller.isPractice ? ' 연습' : ''}'
              : controller.isEquation
                    ? '방정식(${componentLabel(r)}) 레벨 ${r.level}'
                          '${controller.isPractice ? ' 연습' : ''}'
                    : controller.isFlash
                          ? '플래시(${componentLabel(r)}) 레벨 ${r.level}'
                                '${controller.isPractice ? ' 연습' : ''}'
                          : controller.isEstimation
                              ? '어림셈(${componentLabel(r)}) 레벨 ${r.level}'
                                    '${controller.isPractice ? ' 연습' : ''}'
                          : controller.isTimeAttack
                                ? '${r.type.label} 레벨 ${r.level} 타임어택'
                                : controller.isEndless
                                      ? '${r.type.label} 레벨 ${r.level} 연속도전'
                                      : controller.isPractice
                                            ? '${r.type.label} 레벨 ${r.level} 연습'
                                            : '${r.type.label} 레벨 ${r.level}';
    final score = controller.isTimeAttack
        ? '${r.correctCount}문제 정답'
        : controller.isEndless
            ? '${r.correctCount} 연속'
            : '${r.correctCount} / ${r.totalCount} 정답';
    final time = formatElapsedSeconds(r.elapsedSeconds);
    final newBest = controller.isNewBest ? '\n🏆 신기록 달성!' : '';
    return '🎯 연산 히어로\n$label · $score · $time$newBest';
  }

  @override
  Widget build(BuildContext context) {
    final r = controller.record;
    final isNewBest = controller.isNewBest;
    final isTimeAttack = controller.isTimeAttack;
    final isEndless = controller.isEndless;
    final reviewable = r.attempts
        .where((a) => a.status != AttemptStatus.correct && !a.isEstimation)
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '결과',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: '공유하기',
            onPressed: _sharing ? null : _share,
            icon: _sharing
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.share),
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context).viewPadding.bottom + 24,
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    RepaintBoundary(
                      key: _shareKey,
                      child: Container(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                        child: Column(
                          children: [
                            SizedBox(
                              height: isNewBest ? 200 : 140,
                              child: Lottie.asset(
                                'assets/lottie/result_celebrate.json',
                                fit: BoxFit.contain,
                              ),
                            ),
                            if (isNewBest) ...[
                              const SizedBox(height: 8),
                              _NewRecordBadge(
                                label: isEndless
                                    ? '최다 연속 신기록!'
                                    : isTimeAttack
                                        ? '최다 정답 신기록!'
                                        : '최단 시간 신기록!',
                              ),
                            ],
                            const SizedBox(height: 16),
                            if (controller.showStars) ...[
                              _StarRow(count: controller.starCount),
                              const SizedBox(height: 12),
                            ],
                            _ScoreText(
                              text: isEndless || isTimeAttack
                                  ? '${r.correctCount}'
                                  : '${r.correctCount} / ${r.totalCount}',
                              highlight: isNewBest,
                            ),
                            Text(
                              isNewBest
                                  ? '신기록 달성!'
                                  : isEndless
                                      ? '연속 정답'
                                      : '맞춘 문제',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: isNewBest ? FontWeight.bold : null,
                                color: isNewBest ? Colors.amber.shade800 : null,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _Greeting(
                              score: r.correctCount,
                              total: r.totalCount,
                            ),
                            const SizedBox(height: 20),
                            _Row(
                              label: '게임',
                              value: controller.isTimesTable
                                  ? '${controller.tableNumber}단 연습'
                                  : controller.isMixed
                                  ? '혼합 (${componentLabel(r)}) 레벨 ${r.level}'
                                        '${controller.isPractice ? ' (연습)' : ''}'
                                  : controller.isEquation
                                  ? '방정식 (${componentLabel(r)}) 레벨 ${r.level}'
                                        '${controller.isPractice ? ' (연습)' : ''}'
                                  : controller.isFlash
                                  ? '플래시 (${componentLabel(r)}) 레벨 ${r.level}'
                                        '${controller.isPractice ? ' (연습)' : ''}'
                                  : controller.isEstimation
                                  ? '어림셈 (${componentLabel(r)}) 레벨 ${r.level}'
                                        '${controller.isPractice ? ' (연습)' : ''}'
                                  : controller.isTimeAttack
                                  ? '${r.type.label} 레벨 ${r.level} (타임어택)'
                                  : controller.isEndless
                                  ? '${r.type.label} 레벨 ${r.level} (연속도전)'
                                  : controller.isPractice
                                  ? '${r.type.label} 레벨 ${r.level} (연습)'
                                  : '${r.type.label} 레벨 ${r.level}',
                            ),
                            _Row(label: '푼 문제', value: '${r.solvedCount}'),
                            _Row(label: '못 푼 문제', value: '${r.unsolvedCount}'),
                            _Row(label: '맞은 문제', value: '${r.correctCount}'),
                            _Row(label: '틀린 문제', value: '${r.wrongCount}'),
                            if (r.maxCombo >= 2)
                              _Row(
                                label: '최고 콤보',
                                value: '${r.maxCombo} 연속',
                              ),
                            _Row(
                              label: '소요 시간',
                              value: formatElapsedSeconds(r.elapsedSeconds),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '🎯 연산 히어로',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '문제별 결과',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (var i = 0; i < r.attempts.length; i++) ...[
                      AttemptTile(index: i + 1, attempt: r.attempts[i]),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (reviewable.isNotEmpty) ...[
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () => Get.toNamed(
                    AppRoutes.review,
                    arguments: reviewable,
                  ),
                  icon: const Icon(Icons.refresh, size: 22),
                  label: Text(
                    '틀린 문제 다시 풀기 (${reviewable.length})',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: () => Get.offAllNamed(AppRoutes.home),
                child: const Text('홈으로', style: TextStyle(fontSize: 20)),
              ),
            ),
          ],
        ),
      ),
      // 만점(3★)일 때만 상단에 잠깐 폭죽이 터진다.
      if (controller.isPerfect)
        const Positioned.fill(
          child: IgnorePointer(child: _ConfettiOverlay()),
        ),
        ],
      ),
    );
  }
}

/// 결과 화면 별점(1~3). 획득한 별은 금색 채움, 나머지는 회색 윤곽.
class _StarRow extends StatefulWidget {
  const _StarRow({required this.count});

  final int count;

  @override
  State<_StarRow> createState() => _StarRowState();
}

class _StarRowState extends State<_StarRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    duration: const Duration(milliseconds: 900),
    vsync: this,
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            // Stagger — each star pops in ~250ms after the previous.
            final start = i * 0.25;
            final t = ((_c.value - start) / 0.55).clamp(0.0, 1.0);
            final scale = Curves.elasticOut.transform(t);
            final earned = i < widget.count;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Transform.scale(
                scale: earned ? scale : 1.0,
                child: Icon(
                  earned ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 56,
                  color:
                      earned ? const Color(0xFFFFB300) : Colors.grey.shade400,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// 만점 셀러브레이션 폭죽. CustomPainter로 파티클 몇 개를 잠깐 뿌린다
/// (외부 의존성 없이 오프라인·저비용).
class _ConfettiOverlay extends StatefulWidget {
  const _ConfettiOverlay();

  @override
  State<_ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<_ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    duration: const Duration(milliseconds: 1800),
    vsync: this,
  )..forward();

  static const List<Color> _palette = [
    Color(0xFFE53935),
    Color(0xFF43A047),
    Color(0xFF1E88E5),
    Color(0xFFFB8C00),
    Color(0xFF8E24AA),
    Color(0xFFFFC107),
  ];

  static const int _particleCount = 40;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => CustomPaint(
        painter: _ConfettiPainter(
          progress: _c.value,
          palette: _palette,
          count: _particleCount,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({
    required this.progress,
    required this.palette,
    required this.count,
  });

  final double progress;
  final List<Color> palette;
  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    // Deterministic pseudo-random so particles feel consistent across frames.
    for (var i = 0; i < count; i++) {
      final seed = i * 9301 + 49297;
      final rx = ((seed % 233280) / 233280.0);
      final ry = (((seed * 1103) % 233280) / 233280.0);
      final rc = ((seed * 51749) % palette.length);
      final drift = (rx - 0.5) * size.width * 0.9;
      final startX = size.width / 2 + drift * 0.2;
      final startY = -30.0;
      final fallEnd = size.height * (0.35 + ry * 0.55);
      final t = progress;
      final easedFall = Curves.easeIn.transform(t);
      final x = startX + drift * t;
      final y = startY + (fallEnd + 30) * easedFall;
      final rot = t * 6.28 * (rx + 0.4);
      final opacity = (1.0 - Curves.easeIn.transform((t - 0.75).clamp(0, 1) / 0.25))
          .clamp(0.0, 1.0);
      final paint = Paint()..color = palette[rc].withValues(alpha: opacity);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rot);
      canvas.drawRect(
        const Rect.fromLTWH(-4, -6, 8, 12),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.score, required this.total});

  final int score;
  final int total;

  @override
  Widget build(BuildContext context) {
    final profile = Get.find<ProfileService>();
    return Obx(() {
      final addressed = addressedName(profile.name.value);
      final phrase = _phraseFor(score, total);
      return Text(
        addressed.isEmpty ? phrase : '$addressed, $phrase',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      );
    });
  }

  String _phraseFor(int correct, int total) {
    if (total == 0) return '다음에 다시 해 보자!';
    final ratio = correct / total;
    if (ratio >= 1.0) return '완벽해! 🎉';
    if (ratio >= 0.8) return '아주 잘했어!';
    if (ratio >= 0.5) return '잘했어!';
    return '괜찮아, 계속 해 보자!';
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ScoreText extends StatelessWidget {
  const _ScoreText({required this.text, required this.highlight});

  final String text;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: highlight ? 64 : 56,
      fontWeight: FontWeight.bold,
      color: highlight ? Colors.amber.shade800 : null,
    );
    if (!highlight) return Text(text, style: style);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.elasticOut,
      builder: (context, t, child) => Transform.scale(scale: t, child: child),
      child: Text(text, style: style),
    );
  }
}

class _NewRecordBadge extends StatelessWidget {
  const _NewRecordBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.elasticOut,
      builder: (context, t, child) => Transform.scale(
        scale: t,
        child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD54F), Color(0xFFFB8C00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.6),
              blurRadius: 16,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, color: Colors.white, size: 26),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
