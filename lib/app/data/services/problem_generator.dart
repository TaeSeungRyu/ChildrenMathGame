import 'dart:math';

import '../models/game_type.dart';
import '../models/problem.dart';

class ProblemGenerator {
  static const totalProblems = 10;
  static final _random = Random();

  static List<Problem> generate({required GameType type, required int level}) {
    return List.generate(totalProblems, (_) => _one(type, level));
  }

  static Problem _one(GameType type, int level) {
    switch (type) {
      case GameType.addition:
        return Problem(
          operandA: _nDigit(level),
          operandB: _nDigit(level),
          type: type,
        );
      case GameType.subtraction:
        var a = _nDigit(level);
        var b = _nDigit(level);
        if (a < b) {
          final tmp = a;
          a = b;
          b = tmp;
        }
        return Problem(operandA: a, operandB: b, type: type);
      case GameType.multiplication:
        // Keep one operand single-digit so level 5 stays tractable for kids.
        return Problem(
          operandA: _nDigit(level),
          operandB: _random.nextInt(9) + 1,
          type: type,
        );
      case GameType.division:
        // Build dividend = quotient * divisor so the result is always integer.
        final divisor = level == 1 ? _random.nextInt(8) + 2 : _random.nextInt(8) + 2;
        final low = level == 1 ? 1 : _pow10(level - 1);
        final high = _pow10(level) - 1;
        final qMin = (low + divisor - 1) ~/ divisor;
        final qMax = high ~/ divisor;
        final quotient = qMax <= qMin
            ? qMin
            : qMin + _random.nextInt(qMax - qMin + 1);
        return Problem(
          operandA: quotient * divisor,
          operandB: divisor,
          type: type,
        );
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
