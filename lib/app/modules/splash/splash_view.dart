import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/services/profile_service.dart';
import 'splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    // Vertical gradient from sky-blue (top) into the home's cream tone
    // (bottom) so the splash→home transition feels like a continuous scene
    // rather than a jarring color swap. Floating 4-op symbols echo the
    // home tile palette and brand the screen as a math game without
    // relying on a single overwhelming blue.
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFB3E5FC), // top: light sky
              Color(0xFFFFF8E7), // bottom: cream (matches home)
            ],
          ),
        ),
        child: Stack(
          children: const [
            // Decorative floating math symbols — same per-op palette as the
            // home tiles, semi-transparent so they read as background
            // texture rather than content. Each symbol bobs up/down with a
            // unique period (bobMs) so they don't move in sync — gives a
            // gentle "floating in water" feel.
            Positioned(
              top: 80,
              left: 28,
              child: _FloatingSymbol(
                symbol: '+',
                color: Color(0xFFA5D6A7),
                size: 92,
                rotation: -0.18,
                bobMs: 2200,
              ),
            ),
            Positioned(
              top: 130,
              right: 24,
              child: _FloatingSymbol(
                symbol: '-',
                color: Color(0xFFFFB74D),
                size: 104,
                rotation: 0.22,
                bobMs: 2800,
              ),
            ),
            Positioned(
              bottom: 140,
              left: 36,
              child: _FloatingSymbol(
                symbol: '×',
                color: Color(0xFFCE93D8),
                size: 84,
                rotation: 0.14,
                bobMs: 2500,
              ),
            ),
            Positioned(
              bottom: 110,
              right: 32,
              child: _FloatingSymbol(
                symbol: '÷',
                color: Color(0xFFF48FB1),
                size: 88,
                rotation: -0.16,
                bobMs: 3100,
              ),
            ),
            _SplashCenter(),
          ],
        ),
      ),
    );
  }
}

class _FloatingSymbol extends StatefulWidget {
  const _FloatingSymbol({
    required this.symbol,
    required this.color,
    required this.size,
    required this.rotation,
    required this.bobMs,
  });

  final String symbol;
  final Color color;
  final double size;
  final double rotation;
  // Full period of the up-down bob in ms. Different values per symbol
  // desync the motion so the screen feels organic, not metronome-like.
  final int bobMs;

  @override
  State<_FloatingSymbol> createState() => _FloatingSymbolState();
}

class _FloatingSymbolState extends State<_FloatingSymbol>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(
    duration: Duration(milliseconds: widget.bobMs),
    vsync: this,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bob,
      builder: (_, _) {
        // `_bob.value` ramps 0→1 then 1→0 because of `reverse: true`.
        // Curve it through easeInOut for a soft sine-like motion.
        final t = Curves.easeInOut.transform(_bob.value);
        // Bob vertically ±7 px and wobble rotation by ±0.03 rad — small
        // enough to be "살짝" yet visible.
        final dy = (t - 0.5) * 14;
        final wobble = (t - 0.5) * 0.06;
        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.rotate(
            angle: widget.rotation + wobble,
            child: Text(
              widget.symbol,
              style: TextStyle(
                fontSize: widget.size,
                fontWeight: FontWeight.bold,
                color: widget.color.withValues(alpha: 0.55),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SplashCenter extends StatelessWidget {
  const _SplashCenter();

  @override
  Widget build(BuildContext context) {
    final profile = Get.find<ProfileService>();
    const titleColor = Color(0xFF0D47A1);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Entry pop + continuous breathing + icon tilt — see
          // [_AnimatedSplashBadge] for the layered animation logic.
          const _AnimatedSplashBadge(),
          const SizedBox(height: 28),
          // Text fade-in: 0→1 alpha over 600ms — lags the badge pop slightly
          // (badge plays its elasticOut 0-700ms; text builds opacity over
          // the same window) so the eye lands on the icon first.
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            builder: (_, a, child) => Opacity(opacity: a, child: child),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Obx(
                      () => Text(
                        '연산 히어로\n${profile.name.value}!',
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.visible,
                        style: TextStyle(
                          fontFamily: Theme.of(
                            context,
                          ).textTheme.displayLarge?.fontFamily,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Children Math Game',
                  style: TextStyle(
                    fontFamily:
                        Theme.of(context).textTheme.titleMedium?.fontFamily,
                    fontSize: 16,
                    color: titleColor.withValues(alpha: 0.65),
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Three layered animations for the splash logo:
/// 1. **Entry** — elastic scale 0.6→1.0 over 700ms (one-shot, plays on mount)
/// 2. **Breath** — badge scale ±3% + shadow glow alpha/blur pulse, 1500ms
///    period, loops forever. Soft "alive" feel without being distracting.
/// 3. **Tilt** — inner Icon rotates ±5° on a 1100ms period, slightly faster
///    than the breath so the two motions don't sync up and feel mechanical.
class _AnimatedSplashBadge extends StatefulWidget {
  const _AnimatedSplashBadge();

  @override
  State<_AnimatedSplashBadge> createState() => _AnimatedSplashBadgeState();
}

class _AnimatedSplashBadgeState extends State<_AnimatedSplashBadge>
    with TickerProviderStateMixin {
  late final AnimationController _entry = AnimationController(
    duration: const Duration(milliseconds: 700),
    vsync: this,
  )..forward();
  late final AnimationController _breath = AnimationController(
    duration: const Duration(milliseconds: 1500),
    vsync: this,
  )..repeat(reverse: true);
  late final AnimationController _tilt = AnimationController(
    duration: const Duration(milliseconds: 1100),
    vsync: this,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _entry.dispose();
    _breath.dispose();
    _tilt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const iconColor = Color(0xFF1976D2);
    return AnimatedBuilder(
      animation: Listenable.merge([_entry, _breath, _tilt]),
      builder: (_, _) {
        // Entry: elasticOut can briefly exceed 1.0 — that overshoot is the
        // "bounce" feel, so we let it through without clamping.
        final entryT = Curves.elasticOut.transform(_entry.value);
        final entryScale = 0.6 + entryT * 0.4;
        // Breath 0..1..0 (reverse loop), smoothed.
        final breath = Curves.easeInOut.transform(_breath.value);
        final pulseScale = 1.0 + (breath - 0.5) * 0.06;
        // Tilt ±0.09 rad ≈ ±5°.
        final tilt =
            (Curves.easeInOut.transform(_tilt.value) - 0.5) * 0.18;
        return Transform.scale(
          scale: entryScale * pulseScale,
          child: Container(
            width: 144,
            height: 144,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  // Glow uses the icon color so the breathing reads as
                  // "the logo itself is alive" rather than a generic
                  // drop shadow.
                  color: iconColor.withValues(alpha: 0.15 + breath * 0.18),
                  blurRadius: 18 + breath * 14,
                  spreadRadius: breath * 2,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Transform.rotate(
                angle: tilt,
                child: const Icon(
                  Icons.calculate,
                  size: 88,
                  color: iconColor,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
