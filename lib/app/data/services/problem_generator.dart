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
    }
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
