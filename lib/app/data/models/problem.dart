import 'game_type.dart';

class Problem {
  Problem({required this.operandA, required this.operandB, required this.type})
    : operands = [operandA, operandB],
      operations = [type],
      answer = _calc(operandA, operandB, type);

  /// Compound problem with N operations and N+1 operands (e.g. 5 + 3 × 2 = ?).
  /// `type` is set to [GameType.mixed]; concrete ops live in [operations].
  /// `answer` is computed by the caller (the generator) and passed in, because
  /// chain evaluation with precedence happens during generation anyway.
  Problem.compound({
    required this.operands,
    required this.operations,
    required this.answer,
  }) : assert(
         operands.length == operations.length + 1,
         'compound: need ops.length + 1 operands',
       ),
       assert(operations.isNotEmpty, 'compound: need at least one operation'),
       operandA = operands[0],
       operandB = operands[1],
       type = GameType.mixed;

  final int operandA;
  final int operandB;
  // Full operand chain. Length == operations.length + 1. For a simple
  // (single-op) problem this is [operandA, operandB].
  final List<int> operands;
  // Operations in the order they appear in the chain. For a simple problem
  // this is [type]; for compound, a list of concrete ops (never `mixed`).
  final List<GameType> operations;
  final GameType type;
  final int answer;

  bool get isCompound => operations.length > 1;

  String get questionText {
    if (!isCompound) return '$operandA ${type.symbol} $operandB';
    final buf = StringBuffer('${operands[0]}');
    for (var i = 0; i < operations.length; i++) {
      buf.write(' ${operations[i].symbol} ${operands[i + 1]}');
    }
    return buf.toString();
  }

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
