import 'package:children_math_game/app/data/models/game_type.dart';
import 'package:children_math_game/app/data/models/problem.dart';
import 'package:children_math_game/app/data/services/problem_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProblemGenerator.estimationChoicesFor', () {
    test('returns 3 distinct positive choices including the rounded answer', () {
      for (var level = 1; level <= 5; level++) {
        final problems = ProblemGenerator.generate(
          type: GameType.addition,
          level: level,
        );
        for (final p in problems) {
          final c = ProblemGenerator.estimationChoicesFor(p, level);
          expect(c.choices, hasLength(3), reason: 'level $level');
          expect(c.choices.toSet().length, 3,
              reason: 'level $level — choices must be distinct');
          expect(c.choices.every((v) => v >= 0), isTrue,
              reason: 'level $level — no negatives');
          expect(c.choices.contains(c.correct), isTrue,
              reason: 'level $level — correct must appear among choices');
        }
      }
    });

    test('correct equals rounded-operand result for addition', () {
      // 47 + 28 at L3 (10단위): 50 + 30 = 80.
      final p = Problem(
        operandA: 47,
        operandB: 28,
        type: GameType.addition,
      );
      final c = ProblemGenerator.estimationChoicesFor(p, 3);
      expect(c.correct, 80);
    });

    test('correct equals rounded-operand result for multiplication at L5', () {
      // 247 × 138 at L5 (100단위): 200 × 100 = 20000.
      final p = Problem(
        operandA: 247,
        operandB: 138,
        type: GameType.multiplication,
      );
      final c = ProblemGenerator.estimationChoicesFor(p, 5);
      expect(c.correct, 20000);
    });

    test('subtraction never produces a negative correct', () {
      // 작은 값이라도 음수가 나오지 않도록 클램프.
      final p = Problem(operandA: 12, operandB: 9, type: GameType.subtraction);
      final c = ProblemGenerator.estimationChoicesFor(p, 3);
      expect(c.correct, greaterThanOrEqualTo(0));
    });
  });
}
