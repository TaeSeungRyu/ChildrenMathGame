import 'game_type.dart';
import 'problem_attempt.dart';

/// Lightweight record of one 부모와 함께하는 학습 session, shown in the "함께 →
/// 기록보기" list. Intentionally separate from `GameRecord` so coop practice
/// never skews learning stats / badges / streaks. Each device stores its own
/// record from its own perspective (partner = the other person).
class CoopSessionRecord {
  const CoopSessionRecord({
    required this.finishedAt,
    required this.partnerName,
    required this.partnerAvatar,
    required this.gameType,
    required this.level,
    required this.correct,
    required this.wrong,
    required this.elapsedSeconds,
    this.attempts = const [],
  });

  final DateTime finishedAt;
  final String partnerName;
  final String partnerAvatar;

  /// null == 🎲 랜덤 (mixed op each problem).
  final GameType? gameType;
  final int level;
  final int correct;
  final int wrong;
  final int elapsedSeconds;

  /// Every problem solved this session, in order — powers the detail view and
  /// the "틀린 문제 다시풀기" flow.
  final List<ProblemAttempt> attempts;

  int get total => correct + wrong;
  double get accuracy => total == 0 ? 0 : correct / total;

  List<ProblemAttempt> get wrongAttempts =>
      attempts.where((a) => a.status == AttemptStatus.wrong).toList();

  Map<String, dynamic> toJson() => {
        'finishedAt': finishedAt.toIso8601String(),
        'partnerName': partnerName,
        'partnerAvatar': partnerAvatar,
        'gameType': gameType?.name,
        'level': level,
        'correct': correct,
        'wrong': wrong,
        'elapsedSeconds': elapsedSeconds,
        'attempts': attempts.map((a) => a.toJson()).toList(),
      };

  factory CoopSessionRecord.fromJson(Map<String, dynamic> j) {
    final g = j['gameType'] as String?;
    final rawAttempts = j['attempts'] as List<dynamic>?;
    return CoopSessionRecord(
      finishedAt: DateTime.parse(j['finishedAt'] as String),
      partnerName: j['partnerName'] as String? ?? '',
      partnerAvatar: j['partnerAvatar'] as String? ?? '',
      gameType: g == null ? null : GameType.values.byName(g),
      level: j['level'] as int? ?? 1,
      correct: j['correct'] as int? ?? 0,
      wrong: j['wrong'] as int? ?? 0,
      elapsedSeconds: j['elapsedSeconds'] as int? ?? 0,
      attempts: rawAttempts == null
          ? const []
          : rawAttempts
              .map((e) => ProblemAttempt.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }
}
