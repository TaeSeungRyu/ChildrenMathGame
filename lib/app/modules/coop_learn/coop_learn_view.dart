import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../shared/answer_pad.dart';
import '../../shared/stroke_painter.dart';
import 'coop_learn_controller.dart';

/// 아이 화면 — 평소처럼 문제를 풀고, 화면/입력이 부모에게 실시간 미러링된다.
/// 부모가 보낸 이모지 리액션이 마리오파티식으로 팝업된다.
class CoopLearnView extends GetView<CoopLearnController> {
  const CoopLearnView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '함께 학습',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: controller.endSession,
            child: const Text('끝내기', style: TextStyle(fontSize: 15)),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                children: [
                  const _ConnectedBadge(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Stack(
                      children: [
                        Center(
                          child: Obx(
                            () => Text(
                              '${controller.current.value.questionText} = ?',
                              style: const TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        // Coach's pen strokes, mirrored over the problem area.
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Obx(
                              () => CustomPaint(
                                painter: StrokePainter(
                                  strokes: controller.strokes.toList(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Obx(() => AnswerDisplay(value: controller.answer.value)),
                  const SizedBox(height: 12),
                  NumberKeypad(
                    onAppendDigit: controller.appendDigit,
                    onDelete: controller.deleteDigit,
                    onSubmit: controller.submit,
                  ),
                ],
              ),
            ),
            const _ReactionLayer(),
            const _PauseOverlay(),
            const _PartnerLeftOverlay(),
          ],
        ),
      ),
    );
  }
}

class _ConnectedBadge extends GetView<CoopLearnController> {
  const _ConnectedBadge();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final partner = controller.session.partner.value;
      final who = partner == null ? '부모님' : '${partner.avatar} ${partner.name}';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFE1F5FE),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.link, size: 18, color: Color(0xFF0277BD)),
            const SizedBox(width: 6),
            Text(
              '$who 님과 함께하는 중',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0277BD),
              ),
            ),
          ],
        ),
      );
    });
  }
}

/// 부모가 보낸 이모지를 한 번 팝업.
class _ReactionLayer extends GetView<CoopLearnController> {
  const _ReactionLayer();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final r = controller.reaction.value;
      if (r == null) return const SizedBox.shrink();
      return Positioned.fill(
        child: IgnorePointer(
          child: Center(child: _Pop(key: ValueKey(r.id), emoji: r.emoji)),
        ),
      );
    });
  }
}

/// 마리오파티식 팝: 커지며 위로 떠오르다 사라진다. id가 바뀌면 새 인스턴스가
/// 만들어져 애니메이션이 재생된다.
class _Pop extends StatefulWidget {
  const _Pop({super.key, required this.emoji});

  final String emoji;

  @override
  State<_Pop> createState() => _PopState();
}

class _PopState extends State<_Pop> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    duration: const Duration(milliseconds: 1200),
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
        final t = _c.value;
        final scale = 0.5 + 1.0 * Curves.easeOutBack.transform(t.clamp(0, 1));
        final dy = -80 * Curves.easeOut.transform(t);
        final opacity = t < 0.7 ? 1.0 : (1.0 - (t - 0.7) / 0.3);
        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Text(widget.emoji, style: const TextStyle(fontSize: 96)),
            ),
          ),
        );
      },
    );
  }
}

class _PauseOverlay extends GetView<CoopLearnController> {
  const _PauseOverlay();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.paused.value) return const SizedBox.shrink();
      return Positioned.fill(
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.6),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.pause_circle, size: 72, color: Colors.white),
                SizedBox(height: 12),
                Text(
                  '잠시 멈췄어요',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _PartnerLeftOverlay extends GetView<CoopLearnController> {
  const _PartnerLeftOverlay();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.partnerLeft.value) return const SizedBox.shrink();
      return Positioned.fill(
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.7),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.link_off, size: 72, color: Colors.white),
                const SizedBox(height: 12),
                const Text(
                  '상대가 나갔어요',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: Get.back,
                  child: const Text('나가기'),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
