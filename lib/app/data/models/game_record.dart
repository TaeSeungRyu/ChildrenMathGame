import 'game_type.dart';

class GameRecord {
  GameRecord({
    required this.finishedAt,
    required this.type,
    required this.level,
    required this.correctCount,
    required this.wrongCount,
    required this.unsolvedCount,
    required this.elapsedSeconds,
  });

  factory GameRecord.fromJson(Map<String, dynamic> json) => GameRecord(
    finishedAt: DateTime.parse(json['finishedAt'] as String),
    type: GameType.values.byName(json['type'] as String),
    level: json['level'] as int,
    correctCount: json['correctCount'] as int,
    wrongCount: json['wrongCount'] as int,
    unsolvedCount: json['unsolvedCount'] as int,
    elapsedSeconds: json['elapsedSeconds'] as int,
  );

  final DateTime finishedAt;
  final GameType type;
  final int level;
  final int correctCount;
  final int wrongCount;
  final int unsolvedCount;
  final int elapsedSeconds;

  int get solvedCount => correctCount + wrongCount;
  int get totalCount => correctCount + wrongCount + unsolvedCount;

  Map<String, dynamic> toJson() => {
    'finishedAt': finishedAt.toIso8601String(),
    'type': type.name,
    'level': level,
    'correctCount': correctCount,
    'wrongCount': wrongCount,
    'unsolvedCount': unsolvedCount,
    'elapsedSeconds': elapsedSeconds,
  };
}
