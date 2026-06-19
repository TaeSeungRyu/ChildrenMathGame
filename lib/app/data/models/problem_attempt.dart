import 'game_type.dart';

enum AttemptStatus { correct, wrong, unsolved }

class ProblemAttempt {
  ProblemAttempt({
    required this.operandA,
    required this.operandB,
    required this.type,
    required this.correctAnswer,
    required this.userAnswer,
    required this.status,
    List<int>? operands,
    List<GameType>? operations,
    this.isEquation = false,
    this.isEstimation = false,
  }) : operands = operands ?? [operandA, operandB],
       operations = operations ?? [type];

  factory ProblemAttempt.fromJson(Map<String, dynamic> json) {
    final operandsJson = json['operands'] as List?;
    final operationsJson = json['operations'] as List?;
    final operands = operandsJson?.cast<int>();
    final operations = operationsJson
        ?.cast<String>()
        .map(GameType.values.byName)
        .toList();
    return ProblemAttempt(
      operandA: json['operandA'] as int,
      operandB: json['operandB'] as int,
      type: GameType.values.byName(json['type'] as String),
      correctAnswer: json['correctAnswer'] as int,
      userAnswer: json['userAnswer'] as int?,
      status: AttemptStatus.values.byName(json['status'] as String),
      operands: operands,
      operations: operations,
      isEquation: (json['isEquation'] as bool?) ?? false,
      isEstimation: (json['isEstimation'] as bool?) ?? false,
    );
  }

  final int operandA;
  final int operandB;
  final GameType type;
  // Value the player had to enter:
  //   - normal: A op B (the result)
  //   - equation: operandB (the hidden operand)
  final int correctAnswer;
  final int? userAnswer;
  final AttemptStatus status;
  // Full operand chain (length == operations.length + 1). For non-compound
  // attempts this is [operandA, operandB] and `operations` is [type].
  final List<int> operands;
  final List<GameType> operations;
  // True when this attempt came from 방정식 mode: the question is shown as
  // "A op ? = C" and the player solves for operandB. Always false for
  // compound (mixed) attempts.
  final bool isEquation;
  // True when this attempt came from 어림셈 mode: the question is shown as
  // "A op B ≈ ?" and the player picked one of three rounded choices.
  // `correctAnswer` here is the rounded estimate, not the exact result.
  final bool isEstimation;

  bool get isCompound => operations.length > 1;

  String get questionText {
    if (isEquation) {
      // operandB is hidden; the visible result is A op B (the original answer
      // the generator would have produced for a forward problem).
      return '$operandA ${type.symbol} ? = ${_forwardResult()}';
    }
    if (isEstimation) {
      return '$operandA ${type.symbol} $operandB ≈ ?';
    }
    if (!isCompound) return '$operandA ${type.symbol} $operandB';
    final buf = StringBuffer('${operands[0]}');
    for (var i = 0; i < operations.length; i++) {
      buf.write(' ${operations[i].symbol} ${operands[i + 1]}');
    }
    return buf.toString();
  }

  int _forwardResult() {
    switch (type) {
      case GameType.addition:
        return operandA + operandB;
      case GameType.subtraction:
        return operandA - operandB;
      case GameType.multiplication:
        return operandA * operandB;
      case GameType.division:
        return operandA ~/ operandB;
      case GameType.mixed:
      case GameType.equation:
      case GameType.flash:
      case GameType.estimation:
        return 0;
    }
  }

  Map<String, dynamic> toJson() => {
    'operandA': operandA,
    'operandB': operandB,
    'type': type.name,
    'correctAnswer': correctAnswer,
    'userAnswer': userAnswer,
    'status': status.name,
    if (isCompound) 'operands': operands,
    if (isCompound) 'operations': [for (final o in operations) o.name],
    if (isEquation) 'isEquation': true,
    if (isEstimation) 'isEstimation': true,
  };
}
