import 'package:children_math_game/app/data/models/game_type.dart';
import 'package:children_math_game/app/data/services/problem_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProblemGenerator.generateMixed', () {
    test('produces totalProblems problems', () {
      final problems = ProblemGenerator.generateMixed(
        const [GameType.addition, GameType.subtraction],
        2,
      );
      expect(problems, hasLength(ProblemGenerator.totalProblems));
    });

    test('every problem uses one of the allowed types', () {
      const allowed = [GameType.addition, GameType.multiplication];
      // Run a few times to reduce the chance of an unlucky type miss.
      for (var i = 0; i < 5; i++) {
        final problems = ProblemGenerator.generateMixed(allowed, 1);
        for (final p in problems) {
          expect(allowed, contains(p.type));
        }
      }
    });

    test('every allowed type appears at least once (2-type mix)', () {
      const allowed = [GameType.addition, GameType.subtraction];
      // Round-robin distribution is deterministic enough that a single run
      // must already hit every type; loop only to guard against regressions.
      for (var i = 0; i < 20; i++) {
        final problems = ProblemGenerator.generateMixed(allowed, 2);
        final seen = problems.map((p) => p.type).toSet();
        for (final t in allowed) {
          expect(seen, contains(t), reason: 'run #$i missed $t');
        }
      }
    });

    test('every allowed type appears at least once (3-type mix)', () {
      const allowed = [
        GameType.addition,
        GameType.subtraction,
        GameType.multiplication,
      ];
      for (var i = 0; i < 20; i++) {
        final problems = ProblemGenerator.generateMixed(allowed, 2);
        final seen = problems.map((p) => p.type).toSet();
        for (final t in allowed) {
          expect(seen, contains(t), reason: 'run #$i missed $t');
        }
      }
    });

    test('answers are always integers and consistent', () {
      // Division within a mixed game still yields integer answers (the
      // generator's retry loop guarantees it).
      final problems = ProblemGenerator.generateMixed(
        const [GameType.division, GameType.multiplication],
        3,
      );
      for (final p in problems) {
        expect(p.answer, isA<int>());
        switch (p.type) {
          case GameType.addition:
            expect(p.answer, p.operandA + p.operandB);
          case GameType.subtraction:
            expect(p.answer, p.operandA - p.operandB);
          case GameType.multiplication:
            expect(p.answer, p.operandA * p.operandB);
          case GameType.division:
            expect(p.operandA % p.operandB, 0);
            expect(p.answer, p.operandA ~/ p.operandB);
          case GameType.mixed:
            fail('Problem.type must never be mixed');
        }
      }
    });

    test('throws when allowedTypes is empty', () {
      expect(
        () => ProblemGenerator.generateMixed(const [], 1),
        throwsArgumentError,
      );
    });

    test('throws when allowedTypes contains mixed itself', () {
      expect(
        () => ProblemGenerator.generateMixed(
          const [GameType.addition, GameType.mixed],
          1,
        ),
        throwsArgumentError,
      );
    });

    test('single-type allowedTypes produces problems all of that type', () {
      final problems = ProblemGenerator.generateMixed(
        const [GameType.multiplication],
        1,
      );
      for (final p in problems) {
        expect(p.type, GameType.multiplication);
      }
    });
  });
}
