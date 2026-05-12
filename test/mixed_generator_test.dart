import 'package:children_math_game/app/data/models/game_type.dart';
import 'package:children_math_game/app/data/services/problem_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProblemGenerator.generateMixed (single type)', () {
    test('single-type selection still yields simple problems', () {
      final problems = ProblemGenerator.generateMixed(
        const [GameType.multiplication],
        1,
      );
      expect(problems, hasLength(ProblemGenerator.totalProblems));
      for (final p in problems) {
        expect(p.type, GameType.multiplication);
        expect(p.isCompound, isFalse);
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
  });

  group('ProblemGenerator.generateMixed (compound)', () {
    test('produces totalProblems problems for 2-type mix', () {
      final problems = ProblemGenerator.generateMixed(
        const [GameType.addition, GameType.subtraction],
        2,
      );
      expect(problems, hasLength(ProblemGenerator.totalProblems));
    });

    test('every problem is compound and uses every selected op exactly once',
        () {
      const allowed = [
        GameType.addition,
        GameType.subtraction,
        GameType.multiplication,
      ];
      for (var i = 0; i < 30; i++) {
        final problems = ProblemGenerator.generateMixed(allowed, 2);
        for (final p in problems) {
          expect(p.isCompound, isTrue);
          expect(p.operations, hasLength(allowed.length));
          expect(p.operations.toSet(), equals(allowed.toSet()));
          expect(p.operands, hasLength(allowed.length + 1));
        }
      }
    });

    test('compound problems for 4-type mix include all four ops', () {
      const allowed = [
        GameType.addition,
        GameType.subtraction,
        GameType.multiplication,
        GameType.division,
      ];
      for (var i = 0; i < 30; i++) {
        final problems = ProblemGenerator.generateMixed(allowed, 1);
        for (final p in problems) {
          expect(p.operations.toSet(), equals(allowed.toSet()));
        }
      }
    });

    test('answer matches precedence-aware evaluation of operands/operations',
        () {
      const allowed = [
        GameType.addition,
        GameType.multiplication,
        GameType.subtraction,
      ];
      for (var i = 0; i < 30; i++) {
        final problems = ProblemGenerator.generateMixed(allowed, 3);
        for (final p in problems) {
          expect(p.answer, _evalWithPrecedence(p.operands, p.operations));
        }
      }
    });

    test('all intermediate values stay non-negative integers', () {
      const allowed = [
        GameType.addition,
        GameType.subtraction,
        GameType.multiplication,
        GameType.division,
      ];
      for (var i = 0; i < 30; i++) {
        final problems = ProblemGenerator.generateMixed(allowed, 3);
        for (final p in problems) {
          final trace = _intermediateValues(p.operands, p.operations);
          for (final v in trace) {
            expect(v, isNonNegative, reason: '$trace for ${p.questionText}');
          }
        }
      }
    });

    test('questionText renders the full chain', () {
      final problems = ProblemGenerator.generateMixed(
        const [GameType.addition, GameType.multiplication],
        1,
      );
      final p = problems.first;
      final expected =
          '${p.operands[0]} ${p.operations[0].symbol} ${p.operands[1]} '
          '${p.operations[1].symbol} ${p.operands[2]}';
      expect(p.questionText, expected);
    });
  });
}

// Mirrors the generator's evaluation contract so tests can independently
// verify answers (×/÷ first, then +/− left-to-right).
int _evalWithPrecedence(List<int> operands, List<GameType> operations) {
  final terms = <int>[];
  final betweens = <GameType>[];
  var current = operands[0];
  for (var i = 0; i < operations.length; i++) {
    final op = operations[i];
    final next = operands[i + 1];
    if (op == GameType.multiplication) {
      current *= next;
    } else if (op == GameType.division) {
      current ~/= next;
    } else {
      terms.add(current);
      betweens.add(op);
      current = next;
    }
  }
  terms.add(current);
  var sum = terms[0];
  for (var i = 0; i < betweens.length; i++) {
    sum = betweens[i] == GameType.addition
        ? sum + terms[i + 1]
        : sum - terms[i + 1];
  }
  return sum;
}

// All term-level and +/- running totals as the chain evaluates, in order.
List<int> _intermediateValues(
  List<int> operands,
  List<GameType> operations,
) {
  final trace = <int>[];
  final terms = <int>[];
  final betweens = <GameType>[];
  var current = operands[0];
  trace.add(current);
  for (var i = 0; i < operations.length; i++) {
    final op = operations[i];
    final next = operands[i + 1];
    if (op == GameType.multiplication) {
      current *= next;
      trace.add(current);
    } else if (op == GameType.division) {
      // Division cleanliness is part of the contract.
      expect(current % next, 0);
      current ~/= next;
      trace.add(current);
    } else {
      terms.add(current);
      betweens.add(op);
      current = next;
      trace.add(current);
    }
  }
  terms.add(current);
  var sum = terms[0];
  trace.add(sum);
  for (var i = 0; i < betweens.length; i++) {
    sum = betweens[i] == GameType.addition
        ? sum + terms[i + 1]
        : sum - terms[i + 1];
    trace.add(sum);
  }
  return trace;
}
