import 'game_type.dart';

class Problem {
  Problem({required this.operandA, required this.operandB, required this.type})
    : answer = _calc(operandA, operandB, type);

  final int operandA;
  final int operandB;
  final GameType type;
  final int answer;

  String get questionText => '$operandA ${type.symbol} $operandB';

  static int _calc(int a, int b, GameType t) {
    switch (t) {
      case GameType.addition:
        return a + b;
      case GameType.subtraction:
        return a - b;
      case GameType.multiplication:
        return a * b;
      case GameType.division:
        return a ~/ b;
      case GameType.mixed:
        // A single Problem never has type=mixed — only the GameRecord's
        // roll-up type can. Anything reaching here is a programmer error.
        throw StateError('Problem.type must be a concrete operation');
    }
  }
}
