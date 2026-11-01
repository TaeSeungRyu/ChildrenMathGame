import 'dart:math' as math;

import 'package:children_math_game/app/shared/billiards_physics.dart';
import 'package:children_math_game/app/shared/billiards_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('straight shot registers collision and stops after two', () {
    final layout = BilliardsLayout(
      [
        const BilliardsBall(0, 2, 0.20, 0.5),
        const BilliardsBall(1, 2, 0.8, 0.8),
        const BilliardsBall(2, 8, 0.45, 0.5),
        const BilliardsBall(3, 9, 0.08, 0.5),
      ],
      {0, 1},
    );
    final shot = BilliardsShot(
      layout: layout,
      starterId: 0,
      angle: 0,
      power: 1,
    );
    for (var i = 0; i < 600 && !shot.stopped; i++) {
      shot.advance(0.016);
    }
    expect(shot.hitIds, [2, 3]);
    expect(shot.stopped, isTrue);
  });

  test('empty shot ends and wall reflection stays in bounds', () {
    final layout = BilliardsLayout(
      [
        const BilliardsBall(0, 2, 0.2, 0.2),
        const BilliardsBall(1, 2, 0.8, 0.8),
      ],
      {0, 1},
    );
    final shot = BilliardsShot(
      layout: layout,
      starterId: 0,
      angle: -math.pi / 2,
      power: 1,
    );
    for (var i = 0; i < 600 && !shot.stopped; i++) {
      shot.advance(0.016);
      expect(
        shot.x,
        inInclusiveRange(BilliardsRules.radius, 1 - BilliardsRules.radius),
      );
      expect(
        shot.y,
        inInclusiveRange(BilliardsRules.radius, 1 - BilliardsRules.radius),
      );
    }
    expect(shot.stopped, isTrue);
  });
}
