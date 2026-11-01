import 'dart:math' as math;

import '../data/models/game_type.dart';
import 'billiards_rules.dart';

class BilliardsShot {
  BilliardsShot({
    required this.layout,
    required this.starterId,
    required this.angle,
    required this.power,
  }) {
    final starter = layout.balls.firstWhere((b) => b.id == starterId);
    x = starter.x;
    y = starter.y;
    final speed = 0.45 + power.clamp(0.1, 1.0) * 1.15;
    vx = math.cos(angle) * speed;
    vy = math.sin(angle) * speed;
  }

  final BilliardsLayout layout;
  final int starterId;
  final double angle;
  final double power;
  late double x;
  late double y;
  late double vx;
  late double vy;
  double elapsed = 0;
  bool stopped = false;
  final List<int> hitIds = [];
  static const double _radius = BilliardsRules.radius;

  /// Advances with short substeps so fast shots cannot jump through a ball.
  void advance(double seconds) {
    if (stopped) return;
    var left = seconds.clamp(0.0, 0.12);
    while (left > 0 && !stopped) {
      final dt = math.min(left, 0.004);
      left -= dt;
      elapsed += dt;
      var nx = x + vx * dt;
      var ny = y + vy * dt;
      if (nx < _radius || nx > 1 - _radius) {
        vx = -vx * 0.88;
        nx = nx.clamp(_radius, 1 - _radius);
      }
      if (ny < _radius || ny > 1 - _radius) {
        vy = -vy * 0.88;
        ny = ny.clamp(_radius, 1 - _radius);
      }
      for (final ball in layout.balls) {
        if (ball.id == starterId || hitIds.contains(ball.id)) continue;
        final dx = nx - ball.x;
        final dy = ny - ball.y;
        final distance2 = dx * dx + dy * dy;
        if (distance2 >= 4 * _radius * _radius) continue;
        hitIds.add(ball.id);
        final distance = math.sqrt(distance2);
        final ux = distance > 0
            ? dx / distance
            : -vx / math.sqrt(vx * vx + vy * vy);
        final uy = distance > 0
            ? dy / distance
            : -vy / math.sqrt(vx * vx + vy * vy);
        nx = ball.x + ux * (2 * _radius + 0.001);
        ny = ball.y + uy * (2 * _radius + 0.001);
        final dot = vx * ux + vy * uy;
        vx = (vx - 2 * dot * ux) * 0.72;
        vy = (vy - 2 * dot * uy) * 0.72;
        if (hitIds.length == 2) stopped = true;
        break;
      }
      x = nx;
      y = ny;
      final friction = math.exp(-0.55 * dt);
      vx *= friction;
      vy *= friction;
      if (elapsed >= 6 || vx * vx + vy * vy < 0.0004) stopped = true;
    }
  }
}

class BilliardsTarget {
  const BilliardsTarget(
    this.value,
    this.starterId,
    this.angle,
    this.power,
    this.hitIds,
  );
  final BilliardsValue value;
  final int starterId;
  final double angle;
  final double power;
  final List<int> hitIds;
}

/// Maximum among simulated, reachable shots. The same simulator drives play.
BilliardsTarget? findReachableTarget(
  BilliardsLayout layout,
  GameType operation,
) {
  BilliardsTarget? best;
  for (final starterId in layout.starterIds) {
    final starter = layout.balls.firstWhere((b) => b.id == starterId);
    for (var direction = 0; direction < 72; direction++) {
      for (final power in [0.4, 0.7, 1.0]) {
        final angle = direction * 2 * math.pi / 72;
        final shot = BilliardsShot(
          layout: layout,
          starterId: starterId,
          angle: angle,
          power: power,
        );
        for (var i = 0; i < 375 && !shot.stopped; i++) {
          shot.advance(0.016);
        }
        if (shot.hitIds.isEmpty) continue;
        final hits = shot.hitIds.map(
          (id) => layout.balls.firstWhere((b) => b.id == id).number,
        );
        final value = BilliardsRules.result(operation, starter.number, hits);
        if (best == null || value.compareTo(best.value) > 0) {
          best = BilliardsTarget(
            value,
            starterId,
            angle,
            power,
            List<int>.of(shot.hitIds),
          );
        }
      }
    }
  }
  return best;
}
