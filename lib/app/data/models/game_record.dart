import 'game_type.dart';

class GameRecord {
  GameRecord({
    required this.finishedAt,
    required this.type,
    required this.level,
    required this.correctCount,
    required this.wrongCount,
  });

  factory GameRecord.fromJson(Map<String, dynamic> json) => GameRecord(
    finishedAt: DateTime.parse(json['finishedAt'] as String),
    type: GameType.values.byName(json['type'] as String),
    level: json['level'] as int,
    correctCount: json['correctCount'] as int,
    wrongCount: json['wrongCount'] as int,
  );

  final DateTime finishedAt;
  final GameType type;
  final int level;
  final int correctCount;
  final int wrongCount;

  int get totalCount => correctCount + wrongCount;

  Map<String, dynamic> toJson() => {
    'finishedAt': finishedAt.toIso8601String(),
    'type': type.name,
    'level': level,
    'correctCount': correctCount,
    'wrongCount': wrongCount,
  };
}
