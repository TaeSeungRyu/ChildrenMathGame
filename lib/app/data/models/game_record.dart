import 'game_type.dart';
import 'problem_attempt.dart';
import 'session_mode.dart';

class GameRecord {
  GameRecord({
    required this.finishedAt,
    required this.type,
    required this.level,
    required this.correctCount,
    required this.wrongCount,
    required this.unsolvedCount,
    required this.elapsedSeconds,
    required this.attempts,
    this.maxCombo = 0,
    this.mode = SessionMode.challenge,
  });

  // `maxCombo` and `mode` are read with null fallbacks so records persisted
  // before each field existed still load. New writes always include them.
  factory GameRecord.fromJson(Map<String, dynamic> json) => GameRecord(
    finishedAt: DateTime.parse(json['finishedAt'] as String),
    type: GameType.values.byName(json['type'] as String),
    level: json['level'] as int,
    correctCount: json['correctCount'] as int,
    wrongCount: json['wrongCount'] as int,
    unsolvedCount: json['unsolvedCount'] as int,
    elapsedSeconds: json['elapsedSeconds'] as int,
    attempts: (json['attempts'] as List<dynamic>)
        .map((e) => ProblemAttempt.fromJson(e as Map<String, dynamic>))
        .toList(),
    maxCombo: (json['maxCombo'] as int?) ?? 0,
    mode: SessionMode.fromName(json['mode'] as String?),
  );

  final DateTime finishedAt;
  final GameType type;
  final int level;
  final int correctCount;
  final int wrongCount;
  final int unsolvedCount;
  final int elapsedSeconds;
  final List<ProblemAttempt> attempts;
  final int maxCombo;
  final SessionMode mode;

  int get solvedCount => correctCount + wrongCount;
  int get totalCount => correctCount + wrongCount + unsolvedCount;
  bool get isTimeAttack => mode == SessionMode.timeAttack;

  Map<String, dynamic> toJson() => {
    'finishedAt': finishedAt.toIso8601String(),
    'type': type.name,
    'level': level,
    'correctCount': correctCount,
    'wrongCount': wrongCount,
    'unsolvedCount': unsolvedCount,
    'elapsedSeconds': elapsedSeconds,
    'attempts': attempts.map((a) => a.toJson()).toList(),
    'maxCombo': maxCombo,
    'mode': mode.name,
  };
}
