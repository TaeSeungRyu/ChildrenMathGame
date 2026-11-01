import 'dart:math';

import 'package:children_math_game/app/data/models/game_type.dart';
import 'package:children_math_game/app/shared/billiards_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('four operations preserve order and exact division', () {
    expect(BilliardsRules.result(GameType.addition, 2, [9, 8]).label, '19');
    expect(
      BilliardsRules.result(GameType.multiplication, 2, [9, 8]).label,
      '144',
    );
    expect(BilliardsRules.result(GameType.subtraction, 80, [3, 8]).label, '69');
    expect(BilliardsRules.result(GameType.division, 120, [2, 3]).label, '20');
    expect(
      BilliardsValue(1, 3).compareTo(BilliardsValue(1, 4)),
      greaterThan(0),
    );
  });

  test('each count gives two valid starters and separated balls', () {
    for (final operation in [
      GameType.addition,
      GameType.subtraction,
      GameType.multiplication,
      GameType.division,
    ]) {
      for (final count in [4, 5, 6]) {
        final layout = BilliardsRules.generate(
          operation,
          count,
          random: Random(1),
        );
        expect(layout.balls, hasLength(count));
        expect(layout.starterIds, {0, 1});
        expect(layout.balls[0].number, layout.balls[1].number);
        for (var i = 0; i < count; i++) {
          for (var j = i + 1; j < count; j++) {
            final a = layout.balls[i];
            final b = layout.balls[j];
            expect(
              sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2)),
              greaterThan(BilliardsRules.radius * 2),
            );
          }
        }
      }
    }
  });
}
