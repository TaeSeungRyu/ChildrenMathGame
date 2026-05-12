import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import 'game_controller.dart';

class GameView extends GetView<GameController> {
  const GameView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () {
            final progress =
                '${controller.currentIndex.value + 1} / ${controller.totalProblems}';
            final prefix = controller.isTimesTable
                ? '${controller.tableNumber}단  '
                : '';
            return Text(
              '$prefix$progress',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Obx(() {
                if (controller.isPractice) {
                  return Text(
                    '${controller.elapsed.value}초',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  );
                }
                final s = controller.remainingSeconds;
                final color = s <= 10 ? Colors.red : null;
                return Text(
                  '$s초',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context).viewPadding.bottom + 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Obx(() {
              // Practice: show problem progression. Challenge: show remaining
              // time so the bar drains visually as the countdown runs out.
              final double value;
              if (controller.isPractice) {
                value = (controller.currentIndex.value + 1) /
                    controller.totalProblems;
              } else {
                value = controller.remainingSeconds /
                    GameController.totalSeconds;
              }
              return LinearProgressIndicator(
                value: value.clamp(0.0, 1.0),
                minHeight: 8,
              );
            }),
            const SizedBox(height: 16),
            SizedBox(
              height: 80,
              child: Stack(
                // Don't clip — sparkle bursts radiate beyond the 80px row.
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Lottie.asset(
                      'assets/lottie/game_character.json',
                      fit: BoxFit.contain,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Obx(
                      () => _ComboIndicator(count: controller.comboCount.value),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Obx(() {
                      final p = controller.current;
                      // Compound chains are visibly longer; step the base size
                      // down with operator count so FittedBox doesn't shrink
                      // problem-to-problem in a distracting way.
                      final ops = p.operations.length;
                      final double base;
                      if (ops <= 1) {
                        base = 56;
                      } else if (ops == 2) {
                        base = 44;
                      } else if (ops == 3) {
                        base = 38;
                      } else {
                        base = 32;
                      }
                      return Text(
                        '${p.questionText} = ?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: base,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _AnswerDisplay(),
            const SizedBox(height: 12),
            _Keypad(),
          ],
        ),
      ),
    );
  }
}

class _AnswerDisplay extends GetView<GameController> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 62,
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Obx(() {
        final value = controller.answer.value;
        if (value.isEmpty) {
          return Text(
            '정답 입력',
            style: TextStyle(
              fontSize: 24,
              color: theme.hintColor,
            ),
          );
        }
        return Text(
          value,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        );
      }),
    );
  }
}

class _Keypad extends GetView<GameController> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _row([_digit('1'), _digit('2'), _digit('3')]),
        const SizedBox(height: 8),
        _row([_digit('4'), _digit('5'), _digit('6')]),
        const SizedBox(height: 8),
        _row([_digit('7'), _digit('8'), _digit('9')]),
        const SizedBox(height: 8),
        _row(
          [
            _action(
              label: '지우기',
              onPressed: controller.deleteLast,
              color: Colors.orange.shade400,
            ),
            _digit('0'),
            _action(
              label: '입력',
              onPressed: controller.submit,
              color: Colors.green.shade500,
            ),
          ],
          flexes: const [1, 1, 2],
          height: 96,
        ),
      ],
    );
  }

  Widget _row(
    List<Widget> children, {
    List<int>? flexes,
    double height = 64,
  }) {
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) items.add(const SizedBox(width: 8));
      items.add(Expanded(flex: flexes?[i] ?? 1, child: children[i]));
    }
    return SizedBox(height: height, child: Row(children: items));
  }

  Widget _digit(String d) {
    return _KeypadButton(
      label: d,
      onPressed: () => controller.appendDigit(d),
    );
  }

  Widget _action({
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return _KeypadButton(
      label: label,
      onPressed: onPressed,
      backgroundColor: color,
      foregroundColor: Colors.white,
      fontSize: 22,
    );
  }
}

class _ComboIndicator extends StatefulWidget {
  const _ComboIndicator({required this.count});

  final int count;

  @override
  State<_ComboIndicator> createState() => _ComboIndicatorState();
}

class _ComboIndicatorState extends State<_ComboIndicator>
    with TickerProviderStateMixin {
  // Slow breathing scale + glow while the streak is alive.
  late final AnimationController _pulse = AnimationController(
    duration: const Duration(milliseconds: 900),
    vsync: this,
  )..repeat(reverse: true);

  // One-shot sparkle burst that fires at milestone counts (3/5/7/10).
  late final AnimationController _burst = AnimationController(
    duration: const Duration(milliseconds: 700),
    vsync: this,
  );

  @override
  void didUpdateWidget(covariant _ComboIndicator old) {
    super.didUpdateWidget(old);
    if (widget.count != old.count &&
        GameController.comboMilestones.contains(widget.count)) {
      _burst.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _burst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(
            animation: _burst,
            builder: (_, _) {
              if (_burst.isDismissed) return const SizedBox.shrink();
              return _SparkleBurst(progress: _burst.value);
            },
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.elasticOut,
            transitionBuilder: (child, anim) {
              return ScaleTransition(
                scale: Tween<double>(begin: 0.4, end: 1.0).animate(anim),
                child: FadeTransition(opacity: anim, child: child),
              );
            },
            child: widget.count < 2
                ? const SizedBox.shrink(key: ValueKey('combo-empty'))
                : KeyedSubtree(
                    key: ValueKey('combo-${widget.count}'),
                    child: AnimatedBuilder(
                      animation: _pulse,
                      builder: (_, child) {
                        // 0..1..0 triangle: produces a smooth in-out pulse.
                        final t = (_pulse.value * 2 - 1).abs();
                        return Transform.scale(
                          scale: 1.0 + 0.05 * t,
                          child: child,
                        );
                      },
                      child: _ComboPill(count: widget.count),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ComboTier {
  const _ComboTier({required this.colors, required this.icon, required this.fontSize});
  final List<Color> colors;
  final IconData icon;
  final double fontSize;
}

_ComboTier _tierFor(int count) {
  if (count >= 10) {
    return const _ComboTier(
      colors: [
        Color(0xFFFFD54F),
        Color(0xFFFF6F00),
        Color(0xFFE11D48),
        Color(0xFF8E24AA),
      ],
      icon: Icons.auto_awesome,
      fontSize: 18,
    );
  }
  if (count >= 7) {
    return const _ComboTier(
      colors: [Color(0xFFEC407A), Color(0xFF8E24AA)],
      icon: Icons.electric_bolt,
      fontSize: 17,
    );
  }
  if (count >= 5) {
    return const _ComboTier(
      colors: [Color(0xFFFF6F00), Color(0xFFE11D48)],
      icon: Icons.bolt,
      fontSize: 16,
    );
  }
  if (count >= 3) {
    return const _ComboTier(
      colors: [Color(0xFFFF8A65), Color(0xFFE53935)],
      icon: Icons.local_fire_department,
      fontSize: 15,
    );
  }
  return const _ComboTier(
    colors: [Color(0xFFFFAB91), Color(0xFFFF8A65)],
    icon: Icons.local_fire_department,
    fontSize: 14,
  );
}

class _ComboPill extends StatelessWidget {
  const _ComboPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final tier = _tierFor(count);
    final glow = tier.colors.last;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: tier.colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.85),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: glow.withValues(alpha: 0.55),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tier.icon,
            color: Colors.white,
            size: tier.fontSize + 4,
          ),
          const SizedBox(width: 4),
          Text(
            '$count 연속',
            style: TextStyle(
              fontSize: tier.fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: const [
                Shadow(
                  color: Colors.black26,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SparkleBurst extends StatelessWidget {
  const _SparkleBurst({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: const Size(160, 60),
        painter: _BurstPainter(progress: progress),
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  _BurstPainter({required this.progress});

  final double progress;

  // 8 sparkles fly outward — colors cycle through the rainbow so the burst
  // reads as celebratory at any milestone (not tied to current tier).
  static const _colors = <Color>[
    Color(0xFFFF6F00),
    Color(0xFFFFB300),
    Color(0xFFFFEB3B),
    Color(0xFF4CAF50),
    Color(0xFF03A9F4),
    Color(0xFF3F51B5),
    Color(0xFF9C27B0),
    Color(0xFFE91E63),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width * 0.42;
    final eased = Curves.easeOutCubic.transform(progress.clamp(0.0, 1.0));
    final radius = maxR * eased;
    final fade = (1.0 - progress).clamp(0.0, 1.0);
    final starSize = 7.0 * fade + 1.0;
    final rotation = progress * math.pi; // sparkles tumble as they fly

    for (var i = 0; i < _colors.length; i++) {
      final angle = (i / _colors.length) * 2 * math.pi;
      final p = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      final paint = Paint()
        ..color = _colors[i].withValues(alpha: fade)
        ..style = PaintingStyle.fill;
      _drawStar(canvas, p, starSize, rotation, paint);
    }
  }

  void _drawStar(
    Canvas canvas,
    Offset center,
    double radius,
    double rotation,
    Paint paint,
  ) {
    if (radius <= 0) return;
    final path = Path();
    const points = 4;
    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius : radius * 0.4;
      final angle = rotation + (i * math.pi / points);
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) =>
      old.progress != progress;
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({
    required this.label,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.fontSize = 28,
  });

  final String label;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
