import 'dart:convert';

import 'coop_role.dart';
import 'game_type.dart';

/// Wire protocol for 부모와 함께하는 학습. Each message is one JSON line sent as
/// a Nearby bytes payload. Encode with [encode]; decode an incoming line with
/// [CoopMessage.decode]. Unknown/newer types decode to [UnknownMessage] so a
/// version mismatch degrades gracefully instead of throwing.
sealed class CoopMessage {
  const CoopMessage();

  String get type;
  Map<String, dynamic> toJson();

  String encode() => jsonEncode(toJson());

  static CoopMessage decode(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final type = json['type'] as String?;
    switch (type) {
      case 'hello':
        return HelloMessage.fromJson(json);
      case 'session_config':
        return SessionConfigMessage.fromJson(json);
      case 'session_start':
        return const SessionStartMessage();
      case 'problem_state':
        return ProblemStateMessage.fromJson(json);
      case 'attempt_result':
        return AttemptResultMessage.fromJson(json);
      case 'set_difficulty':
        return SetDifficultyMessage.fromJson(json);
      case 'coach_emoji':
        return CoachEmojiMessage.fromJson(json);
      case 'session_pause':
        return const SessionPauseMessage();
      case 'session_resume':
        return const SessionResumeMessage();
      case 'session_summary':
        return SessionSummaryMessage.fromJson(json);
      case 'bye':
        return ByeMessage.fromJson(json);
      default:
        return UnknownMessage(type ?? '');
    }
  }
}

/// Handshake sent by both sides right after connecting.
class HelloMessage extends CoopMessage {
  const HelloMessage({
    required this.name,
    required this.avatar,
    required this.role,
    this.version = 1,
  });

  final String name;
  final String avatar;
  final CoopRole role;
  final int version;

  @override
  String get type => 'hello';

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'name': name,
        'avatar': avatar,
        'role': role.name,
        'version': version,
      };

  factory HelloMessage.fromJson(Map<String, dynamic> j) => HelloMessage(
        name: j['name'] as String? ?? '',
        avatar: j['avatar'] as String? ?? '',
        role: CoopRole.values.byName(j['role'] as String? ?? 'child'),
        version: j['version'] as int? ?? 1,
      );
}

/// Host → guest: the learning content chosen in the lobby.
class SessionConfigMessage extends CoopMessage {
  const SessionConfigMessage({required this.gameType, required this.level});

  /// null == 🎲 랜덤 (a mix each problem).
  final GameType? gameType;
  final int level;

  @override
  String get type => 'session_config';

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'gameType': gameType?.name,
        'level': level,
      };

  factory SessionConfigMessage.fromJson(Map<String, dynamic> j) {
    final g = j['gameType'] as String?;
    return SessionConfigMessage(
      gameType: g == null ? null : GameType.values.byName(g),
      level: j['level'] as int? ?? 1,
    );
  }
}

/// Host → guest: begin the session now.
class SessionStartMessage extends CoopMessage {
  const SessionStartMessage();
  @override
  String get type => 'session_start';
  @override
  Map<String, dynamic> toJson() => {'type': type};
}

/// Child → parent: what the child is looking at + typing right now.
class ProblemStateMessage extends CoopMessage {
  const ProblemStateMessage({
    required this.index,
    required this.operands,
    required this.op,
    required this.typedAnswer,
  });

  final int index;
  final List<int> operands;
  final String op;
  final String typedAnswer;

  @override
  String get type => 'problem_state';

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'index': index,
        'operands': operands,
        'op': op,
        'typedAnswer': typedAnswer,
      };

  factory ProblemStateMessage.fromJson(Map<String, dynamic> j) =>
      ProblemStateMessage(
        index: j['index'] as int? ?? 0,
        operands: (j['operands'] as List<dynamic>? ?? [])
            .map((e) => e as int)
            .toList(),
        op: j['op'] as String? ?? '+',
        typedAnswer: j['typedAnswer'] as String? ?? '',
      );
}

/// Child → parent: result of one submitted answer.
class AttemptResultMessage extends CoopMessage {
  const AttemptResultMessage({
    required this.index,
    required this.correct,
    required this.correctAnswer,
    this.userAnswer,
  });

  final int index;
  final bool correct;
  final int correctAnswer;
  final int? userAnswer;

  @override
  String get type => 'attempt_result';

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'index': index,
        'correct': correct,
        'correctAnswer': correctAnswer,
        'userAnswer': userAnswer,
      };

  factory AttemptResultMessage.fromJson(Map<String, dynamic> j) =>
      AttemptResultMessage(
        index: j['index'] as int? ?? 0,
        correct: j['correct'] as bool? ?? false,
        correctAnswer: j['correctAnswer'] as int? ?? 0,
        userAnswer: j['userAnswer'] as int?,
      );
}

/// Parent → child: change difficulty; applies from the next problem.
class SetDifficultyMessage extends CoopMessage {
  const SetDifficultyMessage({this.gameType, this.level});

  final GameType? gameType;
  final int? level;

  @override
  String get type => 'set_difficulty';

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'gameType': gameType?.name,
        'level': level,
      };

  factory SetDifficultyMessage.fromJson(Map<String, dynamic> j) {
    final g = j['gameType'] as String?;
    return SetDifficultyMessage(
      gameType: g == null ? null : GameType.values.byName(g),
      level: j['level'] as int?,
    );
  }
}

/// Parent → child: pop a Mario-Party-style emoji reaction on the child screen.
class CoachEmojiMessage extends CoopMessage {
  const CoachEmojiMessage({required this.emoji, required this.id});

  final String emoji;

  /// Unique per tap so the child side can de-dupe replays.
  final int id;

  @override
  String get type => 'coach_emoji';

  @override
  Map<String, dynamic> toJson() => {'type': type, 'emoji': emoji, 'id': id};

  factory CoachEmojiMessage.fromJson(Map<String, dynamic> j) => CoachEmojiMessage(
        emoji: j['emoji'] as String? ?? '👍',
        id: j['id'] as int? ?? 0,
      );
}

class SessionPauseMessage extends CoopMessage {
  const SessionPauseMessage();
  @override
  String get type => 'session_pause';
  @override
  Map<String, dynamic> toJson() => {'type': type};
}

class SessionResumeMessage extends CoopMessage {
  const SessionResumeMessage();
  @override
  String get type => 'session_resume';
  @override
  Map<String, dynamic> toJson() => {'type': type};
}

/// Child → parent: end-of-session totals.
class SessionSummaryMessage extends CoopMessage {
  const SessionSummaryMessage({
    required this.correct,
    required this.wrong,
    required this.elapsedMs,
  });

  final int correct;
  final int wrong;
  final int elapsedMs;

  @override
  String get type => 'session_summary';

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'correct': correct,
        'wrong': wrong,
        'elapsedMs': elapsedMs,
      };

  factory SessionSummaryMessage.fromJson(Map<String, dynamic> j) =>
      SessionSummaryMessage(
        correct: j['correct'] as int? ?? 0,
        wrong: j['wrong'] as int? ?? 0,
        elapsedMs: j['elapsedMs'] as int? ?? 0,
      );
}

/// Graceful disconnect notice.
class ByeMessage extends CoopMessage {
  const ByeMessage({this.reason = ''});
  final String reason;
  @override
  String get type => 'bye';
  @override
  Map<String, dynamic> toJson() => {'type': type, 'reason': reason};
  factory ByeMessage.fromJson(Map<String, dynamic> j) =>
      ByeMessage(reason: j['reason'] as String? ?? '');
}

/// Fallback for unrecognized/newer message types (forward compatibility).
class UnknownMessage extends CoopMessage {
  const UnknownMessage(this.rawType);
  final String rawType;
  @override
  String get type => rawType;
  @override
  Map<String, dynamic> toJson() => {'type': rawType};
}
