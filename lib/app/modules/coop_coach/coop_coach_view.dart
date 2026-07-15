import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../shared/stroke_painter.dart';
import 'coop_coach_controller.dart';

/// 부모(코치) 대시보드 — 아이 화면을 실시간으로 관찰하고, 난이도 조절·이모지
/// 응원을 보낸다.
class CoopCoachView extends GetView<CoopCoachController> {
  const CoopCoachView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '함께 학습 (부모)',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Obx(
            () => IconButton(
              tooltip: controller.paused.value ? '다시 시작' : '잠시 멈춤',
              icon: Icon(
                controller.paused.value ? Icons.play_arrow : Icons.pause,
              ),
              onPressed: controller.togglePause,
            ),
          ),
          TextButton(
            onPressed: controller.endSession,
            child: const Text('끝내기', style: TextStyle(fontSize: 15)),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: const [
                _MirrorCard(),
                SizedBox(height: 16),
                _SectionTitle('풀이 도와주기 (선긋기 / 지우개)'),
                SizedBox(height: 8),
                _DrawBoard(),
                SizedBox(height: 8),
                _DrawToolbar(),
                SizedBox(height: 16),
                _RecentWrong(),
                SizedBox(height: 16),
                _SectionTitle('난이도 바꾸기'),
                SizedBox(height: 8),
                _OpPicker(),
                SizedBox(height: 10),
                _LevelPicker(),
                SizedBox(height: 20),
                _SectionTitle('응원 보내기'),
                SizedBox(height: 8),
                _EmojiPalette(),
              ],
            ),
            const _EndedOverlay(),
          ],
        ),
      ),
    );
  }
}

/// 아이가 지금 보는 문제 + 입력 + 누적 성적.
class _MirrorCard extends GetView<CoopCoachController> {
  const _MirrorCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFE3F2FD),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Obx(() {
              if (!controller.hasProblem.value) {
                return const Text(
                  '아이가 곧 시작해요...',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                );
              }
              final expr = controller.operands.join(' ${controller.op.value} ');
              final typed = controller.typedAnswer.value;
              return Text(
                '$expr = ${typed.isEmpty ? '?' : typed}',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D47A1),
                ),
              );
            }),
            const SizedBox(height: 16),
            Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Stat('정답', '${controller.correctCount.value}',
                      const Color(0xFF2E7D32)),
                  _Stat('오답', '${controller.wrongCount.value}',
                      const Color(0xFFC62828)),
                  _Stat('정답률', '${(controller.accuracy * 100).round()}%',
                      const Color(0xFF1565C0)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}

/// 아이 화면 미리보기 위에 부모가 선을 긋는 보드. 정규화 좌표(0..1)로 아이
/// 기기에 미러링된다.
class _DrawBoard extends GetView<CoopCoachController> {
  const _DrawBoard();

  static const double _height = 170;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        const h = _height;
        double nx(double dx) => (dx / w).clamp(0.0, 1.0);
        double ny(double dy) => (dy / h).clamp(0.0, 1.0);
        return GestureDetector(
          onPanStart: (d) =>
              controller.panStart(nx(d.localPosition.dx), ny(d.localPosition.dy)),
          onPanUpdate: (d) =>
              controller.panUpdate(nx(d.localPosition.dx), ny(d.localPosition.dy)),
          onPanEnd: (_) => controller.panEnd(),
          child: Container(
            height: h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF90CAF9), width: 1.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Center(
                  child: Obx(() {
                    if (!controller.hasProblem.value) {
                      return const Text('아이가 시작하면 여기에 표시돼요');
                    }
                    final expr =
                        controller.operands.join(' ${controller.op.value} ');
                    final typed = controller.typedAnswer.value;
                    return Text(
                      '$expr = ${typed.isEmpty ? '?' : typed}',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D47A1),
                      ),
                    );
                  }),
                ),
                Positioned.fill(
                  child: Obx(
                    () => CustomPaint(
                      painter: StrokePainter(
                        strokes: controller.strokes.toList(),
                        live: controller.livePoints.toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DrawToolbar extends GetView<CoopCoachController> {
  const _DrawToolbar();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Row(
        children: [
          ChoiceChip(
            label: const Text('✏️ 펜'),
            selected: !controller.eraser.value,
            onSelected: (_) {
              if (controller.eraser.value) controller.toggleEraser();
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('🧽 지우개'),
            selected: controller.eraser.value,
            onSelected: (_) {
              if (!controller.eraser.value) controller.toggleEraser();
            },
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: controller.clearDrawing,
            icon: const Icon(Icons.clear_all, size: 20),
            label: const Text('전체 지우기'),
          ),
        ],
      ),
    );
  }
}

class _RecentWrong extends GetView<CoopCoachController> {
  const _RecentWrong();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final wrong = controller.recentWrong;
      if (wrong.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('최근 틀린 문제'),
          const SizedBox(height: 8),
          for (final w in wrong)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.close, size: 18, color: Color(0xFFC62828)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${w.expr} = ${w.userAnswer ?? '-'}  (정답 ${w.correctAnswer})',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    });
  }
}

class _OpPicker extends GetView<CoopCoachController> {
  const _OpPicker();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.selectedOp.value;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final op in CoopCoachController.opChoices)
            ChoiceChip(
              label: Text(
                op == null ? '🎲 랜덤' : '${op.symbol} ${op.label}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              selected: op == selected,
              onSelected: (_) => controller.setOp(op),
            ),
        ],
      );
    });
  }
}

class _LevelPicker extends GetView<CoopCoachController> {
  const _LevelPicker();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.selectedLevel.value;
      return Row(
        children: [
          for (final level in CoopCoachController.levelChoices) ...[
            Expanded(
              child: ChoiceChip(
                label: SizedBox(
                  width: double.infinity,
                  child: Text(
                    '$level',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                selected: level == selected,
                onSelected: (_) => controller.setLevel(level),
              ),
            ),
            if (level != CoopCoachController.levelChoices.last)
              const SizedBox(width: 6),
          ],
        ],
      );
    });
  }
}

class _EmojiPalette extends GetView<CoopCoachController> {
  const _EmojiPalette();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final emoji in CoopCoachController.emojiPalette)
          InkWell(
            onTap: () => controller.sendEmoji(emoji),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 60,
              height: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFCC80)),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 30)),
            ),
          ),
      ],
    );
  }
}

class _EndedOverlay extends GetView<CoopCoachController> {
  const _EndedOverlay();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.ended.value) return const SizedBox.shrink();
      final s = controller.summary.value;
      return Positioned.fill(
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.7),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.flag, size: 64, color: Colors.white),
                const SizedBox(height: 12),
                const Text(
                  '학습이 끝났어요',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (s != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    '정답 ${s.correct} · 오답 ${s.wrong} · ${_mmss(s.elapsedMs)}',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ],
                const SizedBox(height: 16),
                const Text(
                  '잠시 후 돌아가요',
                  style: TextStyle(fontSize: 15, color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  String _mmss(int ms) {
    final total = ms ~/ 1000;
    final m = total ~/ 60;
    final s = total % 60;
    return '$m분 $s초';
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }
}
