import 'package:children_math_game/app/data/models/game_type.dart';
import 'package:children_math_game/app/data/services/problem_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('division problems always have integer answers', () {
    for (var level = 1; level <= 5; level++) {
      for (var i = 0; i < 1000; i++) {
        final problems = ProblemGenerator.generate(
          type: GameType.division,
          level: level,
        );
        for (final p in problems) {
          expect(
            p.operandA % p.operandB,
            0,
            reason:
                'Level $level produced ${p.operandA} ÷ ${p.operandB} '
                '(remainder ${p.operandA % p.operandB})',
          );
          expect(p.operandA ~/ p.operandB, p.answer);
        }
      }
    }
  });
}
