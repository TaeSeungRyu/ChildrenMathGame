import 'package:children_math_game/app/data/models/game_type.dart';
import 'package:children_math_game/app/data/services/problem_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProblemGenerator.generateTimesTable', () {
    test('produces 9 multiplication problems for the chosen table', () {
      final problems = ProblemGenerator.generateTimesTable(3);
      expect(problems, hasLength(9));
      for (final p in problems) {
        expect(p.type, GameType.multiplication);
        expect(p.operandA, 3);
      }
    });

    test('covers every multiplier from 1 to 9 exactly once', () {
      final problems = ProblemGenerator.generateTimesTable(7);
      final multipliers = problems.map((p) => p.operandB).toList()..sort();
      expect(multipliers, [1, 2, 3, 4, 5, 6, 7, 8, 9]);
    });

    test('returns correct expected answers (table * multiplier)', () {
      final problems = ProblemGenerator.generateTimesTable(6);
      for (final p in problems) {
        expect(p.answer, 6 * p.operandB);
      }
    });
  });
}
