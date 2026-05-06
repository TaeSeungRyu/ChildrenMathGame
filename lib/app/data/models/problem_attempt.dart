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
  });

  factory ProblemAttempt.fromJson(Map<String, dynamic> json) => ProblemAttempt(
    operandA: json['operandA'] as int,
    operandB: json['operandB'] as int,
    type: GameType.values.byName(json['type'] as String),
    correctAnswer: json['correctAnswer'] as int,
    userAnswer: json['userAnswer'] as int?,
    status: AttemptStatus.values.byName(json['status'] as String),
  );

  final int operandA;
  final int operandB;
  final GameType type;
  final int correctAnswer;
  final int? userAnswer;
  final AttemptStatus status;

  String get questionText => '$operandA ${type.symbol} $operandB';

  Map<String, dynamic> toJson() => {
    'operandA': operandA,
    'operandB': operandB,
    'type': type.name,
    'correctAnswer': correctAnswer,
    'userAnswer': userAnswer,
    'status': status.name,
  };
}
