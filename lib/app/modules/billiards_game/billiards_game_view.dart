import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import 'billiards_game_controller.dart';

class BilliardsGameView extends StatefulWidget {
  const BilliardsGameView({super.key});

  @override
  State<BilliardsGameView> createState() => _BilliardsGameViewState();
}

class _BilliardsGameViewState extends State<BilliardsGameView>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final BilliardsGameController controller = Get.find();
  late final Ticker ticker;
  Duration? previous;
  bool paused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ticker = createTicker((elapsed) {
      if (paused) {
        previous = elapsed;
        return;
      }
      final delta = previous == null
          ? 0.016
          : (elapsed - previous!).inMicroseconds / 1000000;
      previous = elapsed;
      controller.tick(delta);
    })..start();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    paused = state != AppLifecycleState.resumed;
    previous = null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('연산 당구'), centerTitle: true),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
        child: Column(
          children: [
            Obx(
              () => Wrap(
                spacing: 12,
                children: [
                  Text(
                    '${controller.operation.label}  ·  ${controller.ballCount}개 공',
                  ),
                  Text('발사 ${controller.attempts.value}회'),
                  Text('충돌 ${controller.hitIds.length}/1'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Obx(
              () => Text(
                controller.expression.value.isEmpty
                    ? '공을 골라 조준해요'
                    : controller.expression.value,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 0.65,
                  child: LayoutBuilder(
                    builder: (context, constraints) => GestureDetector(
                      onPanUpdate: (details) => controller.aimAt(
                        details.localPosition.dx / constraints.maxWidth,
                        details.localPosition.dy / constraints.maxHeight,
                      ),
                      child: Obx(() {
                        controller.revision.value;
                        final phase = controller.phase.value;
                        final selected = controller.selectedId.value;
                        final angle = controller.angle.value;
                        return DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0xFF126B55),
                            border: Border.all(
                              color: const Color(0xFF5D4037),
                              width: 8,
                            ),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Stack(
                            children: [
                              for (final ball in controller.layout.balls)
                                Positioned(
                                  left:
                                      ((ball.id == selected &&
                                                  controller.shot != null
                                              ? controller.shot!.x
                                              : ball.x) *
                                          constraints.maxWidth) -
                                      20,
                                  top:
                                      ((ball.id == selected &&
                                                  controller.shot != null
                                              ? controller.shot!.y
                                              : ball.y) *
                                          constraints.maxHeight) -
                                      20,
                                  child: GestureDetector(
                                    onTap: () => controller.select(ball.id),
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color:
                                            controller.hitIds.contains(ball.id)
                                            ? Colors.amber
                                            : controller.layout.starterIds
                                                  .contains(ball.id)
                                            ? Colors.white
                                            : const Color(0xFF80DEEA),
                                        border: Border.all(
                                          color: selected == ball.id
                                              ? Colors.orange
                                              : Colors.black26,
                                          width: selected == ball.id ? 4 : 1,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${ball.number}${controller.hitIds.contains(ball.id) ? '✓' : ''}',
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              if (phase == 'aim' && selected >= 0)
                                Positioned(
                                  left:
                                      controller.layout.balls[selected].x *
                                          constraints.maxWidth -
                                      12 +
                                      math.cos(angle) * 48,
                                  top:
                                      controller.layout.balls[selected].y *
                                          constraints.maxHeight -
                                      12 +
                                      math.sin(angle) * 48,
                                  child: Transform.rotate(
                                    angle: angle,
                                    child: const Icon(
                                      Icons.arrow_forward,
                                      color: Colors.orange,
                                      size: 24,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Obx(
              () => Text(
                controller.message.value,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Obx(() => Text('이번 판 최고: ${controller.best.value?.label ?? '-'}')),
            Obx(
              () => controller.phase.value == 'aim'
                  ? Column(
                      children: [
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final id in controller.layout.starterIds)
                              ChoiceChip(
                                label: Text(
                                  '공 ${controller.layout.balls[id].number} · ${id + 1}번',
                                ),
                                selected: controller.selectedId.value == id,
                                onSelected: (_) => controller.select(id),
                              ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => controller.rotate(-0.08),
                              icon: const Icon(Icons.rotate_left),
                              tooltip: '왼쪽 조준',
                            ),
                            Expanded(
                              child: Slider(
                                value: controller.power.value,
                                min: 0.1,
                                max: 1,
                                onChanged: controller.setPower,
                              ),
                            ),
                            IconButton(
                              onPressed: () => controller.rotate(0.08),
                              icon: const Icon(Icons.rotate_right),
                              tooltip: '오른쪽 조준',
                            ),
                          ],
                        ),
                        Text('파워 ${(controller.power.value * 100).round()}%'),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: controller.fire,
                            icon: const Icon(Icons.sports_baseball),
                            label: const Text('발사'),
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            Obx(
              () => controller.phase.value == 'feedback'
                  ? FilledButton(
                      onPressed: controller.resetShot,
                      child: const Text('다시 도전'),
                    )
                  : controller.phase.value == 'won' ||
                        controller.phase.value == 'quit'
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => Get.back(),
                          child: const Text('나가기'),
                        ),
                        FilledButton(
                          onPressed: controller.newGame,
                          child: const Text('새 게임'),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            Obx(
              () =>
                  controller.phase.value == 'aim' ||
                      controller.phase.value == 'feedback'
                  ? TextButton(
                      onPressed: controller.quit,
                      child: const Text('그만하기'),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    ),
  );
}
