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
    );
  }

  final int operandA;
  final int operandB;
  final GameType type;
  final int correctAnswer;
  final int? userAnswer;
  final AttemptStatus status;
  // Full operand chain (length == operations.length + 1). For non-compound
  // attempts this is [operandA, operandB] and `operations` is [type].
  final List<int> operands;
  final List<GameType> operations;

  bool get isCompound => operations.length > 1;

  String get questionText {
    if (!isCompound) return '$operandA ${type.symbol} $operandB';
    final buf = StringBuffer('${operands[0]}');
    for (var i = 0; i < operations.length; i++) {
      buf.write(' ${operations[i].symbol} ${operands[i + 1]}');
    }
    return buf.toString();
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
  };
}
