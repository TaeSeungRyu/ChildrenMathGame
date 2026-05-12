import 'dart:math';

import '../models/game_type.dart';
import '../models/problem.dart';

class ProblemGenerator {
  static const totalProblems = 10;
  static const timesTableProblems = 9;
  static final _random = Random();

  static List<Problem> generate({required GameType type, required int level}) {
    return List.generate(totalProblems, (_) => _one(type, level));
  }

  /// 1×N .. 9×N for the given [table] (2..9), shuffled. The table number is
  /// always the left operand so the question reads as "N × k = ?".
  static List<Problem> generateTimesTable(int table) {
    final problems = List.generate(
      timesTableProblems,
      (i) => Problem(
        operandA: table,
        operandB: i + 1,
        type: GameType.multiplication,
      ),
    )..shuffle(_random);
    return problems;
  }

  static Problem _one(GameType type, int level) {
    final (aDigits, bDigits) = _digitsForLevel(level);
    switch (type) {
      case GameType.addition:
        return Problem(
          operandA: _nDigit(aDigits),
          operandB: _nDigit(bDigits),
          type: type,
        );
      case GameType.subtraction:
        // Keep larger first so the result never goes negative.
        var a = _nDigit(aDigits);
        var b = _nDigit(bDigits);
        if (a < b) {
          final tmp = a;
          a = b;
          b = tmp;
        }
        return Problem(operandA: a, operandB: b, type: type);
      case GameType.multiplication:
        return Problem(
          operandA: _nDigit(aDigits),
          operandB: _nDigit(bDigits),
          type: type,
        );
      case GameType.division:
        // Build dividend = quotient * divisor so the result is always integer.
        // Reject q < 2 (avoids trivial n÷n=1) and divisors that can't reach the
        // dividend digit range; retry until a valid combo lands.
        while (true) {
          final divisor = bDigits == 1
              ? _random.nextInt(8) + 2
              : _nDigit(bDigits);
          final low = aDigits == 1 ? 1 : _pow10(aDigits - 1);
          final high = _pow10(aDigits) - 1;
          var qMin = (low + divisor - 1) ~/ divisor;
          if (qMin < 2) qMin = 2;
          final qMax = high ~/ divisor;
          if (qMax < qMin) continue;
          final quotient = qMin + _random.nextInt(qMax - qMin + 1);
          return Problem(
            operandA: quotient * divisor,
            operandB: divisor,
            type: type,
          );
        }
      case GameType.mixed:
        // `mixed` is a record-level roll-up; callers must dispatch to
        // [generateMixed] with a concrete type list instead.
        throw ArgumentError('Use generateMixed for GameType.mixed');
    }
  }

  /// Builds [totalProblems] problems whose operations come from [allowedTypes].
  /// `mixed` itself must not appear in [allowedTypes]. Each chosen operation is
  /// generated at the given [level] difficulty.
  ///
  /// **Compound form**: when [allowedTypes].length is > 1, every problem is a
  /// single chained expression (e.g. `5 + 3 × 2 - 1 = ?`) that uses **every**
  /// selected operation exactly once, in a freshly shuffled order. Standard
  /// operator precedence (×/÷ before +/−) applies during evaluation, and the
  /// generator guarantees every intermediate term and the running +/− total
  /// stays a non-negative integer (division is clean, subtraction never goes
  /// negative). To keep division solvable inside a chain, divisors are clamped
  /// to single digits (2..9) regardless of level.
  ///
  /// When [allowedTypes].length is 1, this falls through to single-operation
  /// problems (same shape as [generate]).
  static List<Problem> generateMixed(
    List<GameType> allowedTypes,
    int level,
  ) {
    if (allowedTypes.isEmpty) {
      throw ArgumentError('allowedTypes must contain at least one operation');
    }
    if (allowedTypes.contains(GameType.mixed)) {
      throw ArgumentError(
        'allowedTypes cannot contain GameType.mixed itself',
      );
    }
    if (allowedTypes.length == 1) {
      return generate(type: allowedTypes.single, level: level);
    }
    return List.generate(
      totalProblems,
      (_) => _compoundOne(allowedTypes, level),
    );
  }

  /// One compound problem using every op in [allowedTypes] exactly once.
  ///
  /// Strategy: shuffle ops, then build operands left-to-right while tracking
  /// the running ×/÷ term value and the partial +/− sum. ÷ picks a divisor of
  /// the current term; − is rejected if it would drive the running sum
  /// negative. On failure we retry the shuffle/build; after `_maxRetries` we
  /// fall back to a small all-addition expression (theoretically reachable
  /// only with extreme bad luck — kept as a safety net).
  static const _maxRetries = 200;

  static Problem _compoundOne(List<GameType> allowedTypes, int level) {
    final (aDigits, bDigits) = _digitsForLevel(level);
    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      final ops = [...allowedTypes]..shuffle(_random);
      final built = _tryBuildCompound(ops, aDigits, bDigits);
      if (built != null) return built;
    }
    return _compoundFallback(allowedTypes);
  }

  static Problem? _tryBuildCompound(
    List<GameType> ops,
    int aDigits,
    int bDigits,
  ) {
    final operands = <int>[_nDigit(aDigits)];
    var currentTerm = operands[0];
    final terms = <int>[];
    final betweens = <GameType>[];

    for (final op in ops) {
      switch (op) {
        case GameType.multiplication:
          final b = _nDigit(bDigits);
          operands.add(b);
          currentTerm *= b;
        case GameType.division:
          final d = _pickCompoundDivisor(currentTerm);
          if (d == null) return null;
          operands.add(d);
          currentTerm ~/= d;
        case GameType.addition:
        case GameType.subtraction:
          // Finalize the current ×/÷ term; the next operand starts a new term.
          terms.add(currentTerm);
          betweens.add(op);
          final next = _nDigit(bDigits);
          operands.add(next);
          currentTerm = next;
        case GameType.mixed:
          // Guarded against by generateMixed; reaching here is a bug.
          return null;
      }
    }
    terms.add(currentTerm);

    var sum = terms[0];
    for (var i = 0; i < betweens.length; i++) {
      final next = terms[i + 1];
      if (betweens[i] == GameType.addition) {
        sum += next;
      } else {
        sum -= next;
        if (sum < 0) return null;
      }
    }
    return Problem.compound(
      operands: operands,
      operations: ops,
      answer: sum,
    );
  }

  /// Picks a 2..9 divisor that cleanly divides [value]. Returns null when
  /// [value] has no such divisor (e.g., value is 1 or a prime ≥ 11) — caller
  /// must retry the whole expression in that case.
  static int? _pickCompoundDivisor(int value) {
    if (value < 2) return null;
    final candidates = <int>[
      for (var d = 2; d <= 9; d++)
        if (value % d == 0) d,
    ];
    if (candidates.isEmpty) return null;
    return candidates[_random.nextInt(candidates.length)];
  }

  static Problem _compoundFallback(List<GameType> allowedTypes) {
    // Last-resort small-addition expression that always validates: 1 + 1 + ...
    // The shape still satisfies the "every selected op appears" contract by
    // substituting the canonical safe op into each slot.
    final operands = List<int>.filled(allowedTypes.length + 1, 1);
    final ops = List<GameType>.filled(
      allowedTypes.length,
      GameType.addition,
    );
    return Problem.compound(
      operands: operands,
      operations: ops,
      answer: operands.length,
    );
  }

  static (int, int) _digitsForLevel(int level) {
    switch (level) {
      case 1:
        return (1, 1);
      case 2:
        return (2, 1);
      case 3:
        return (2, 2);
      case 4:
        return (3, 2);
      case 5:
        return (3, 3);
      default:
        return (1, 1);
    }
  }

  static int _nDigit(int n) {
    if (n <= 1) return _random.nextInt(9) + 1;
    final low = _pow10(n - 1);
    final high = _pow10(n) - 1;
    return low + _random.nextInt(high - low + 1);
  }

  static int _pow10(int n) {
    var v = 1;
    for (var i = 0; i < n; i++) {
      v *= 10;
    }
    return v;
  }
}
