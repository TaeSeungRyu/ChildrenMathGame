import 'package:children_math_game/app/data/models/game_type.dart';
import 'package:children_math_game/app/data/services/problem_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('op count per level: 1,2,3,3,5', () {
    expect(ProblemGenerator.signGuessOpCount(1), 1);
    expect(ProblemGenerator.signGuessOpCount(2), 2);
    expect(ProblemGenerator.signGuessOpCount(3), 3);
    expect(ProblemGenerator.signGuessOpCount(4), 3);
    expect(ProblemGenerator.signGuessOpCount(5), 5);
  });

  test('pool: levels 1-3 are +/− only, 4-5 add ×/÷', () {
    for (final l in [1, 2, 3]) {
      expect(ProblemGenerator.signGuessPool(l),
          [GameType.addition, GameType.subtraction]);
    }
    for (final l in [4, 5]) {
      final pool = ProblemGenerator.signGuessPool(l);
      expect(pool, contains(GameType.multiplication));
      expect(pool, contains(GameType.division));
    }
  });

  test('generated problems match op count, pool, and computed answer', () {
    for (var level = 1; level <= 5; level++) {
      final pool = ProblemGenerator.signGuessPool(level);
      final count = ProblemGenerator.signGuessOpCount(level);
      final problems = ProblemGenerator.generateSignGuess(level);
      expect(problems.length, 10);
      for (final p in problems) {
        expect(p.operations.length, count);
        expect(p.operands.length, count + 1);
        // Every operator is drawn from the level's pool.
        for (final op in p.operations) {
          expect(pool, contains(op));
        }
        // The stored answer equals evaluating the correct operators.
        expect(
          ProblemGenerator.evaluateChain(p.operands, p.operations),
          p.answer.toDouble(),
        );
      }
    }
  });

  test('evaluateChain honors precedence and accepts equivalent combos', () {
    // 2 + 2 == 2 × 2 == 4 → both accepted for the same operands/target.
    expect(
      ProblemGenerator.evaluateChain([2, 2], [GameType.addition]),
      4.0,
    );
    expect(
      ProblemGenerator.evaluateChain([2, 2], [GameType.multiplication]),
      4.0,
    );
    // 2 + 3 × 4 = 14 (×  before +).
    expect(
      ProblemGenerator.evaluateChain(
        [2, 3, 4],
        [GameType.addition, GameType.multiplication],
      ),
      14.0,
    );
  });
}
