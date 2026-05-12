import 'game_type.dart';

/// Optional auto-evaluation criteria attached to a [CustomStamp]. When a
/// stamp has a condition, its earned state is derived from records rather
/// than toggled manually — every `null` field means "any" (no constraint).
class StampCondition {
  const StampCondition({
    this.operation,
    this.level,
    required this.targetCount,
    this.requirePerfect = false,
    this.maxSeconds,
  });

  factory StampCondition.fromJson(Map<String, dynamic> json) {
    return StampCondition(
      operation: json['operation'] == null
          ? null
          : GameType.values.byName(json['operation'] as String),
      level: json['level'] as int?,
      targetCount: json['targetCount'] as int,
      requirePerfect: (json['requirePerfect'] as bool?) ?? false,
      maxSeconds: json['maxSeconds'] as int?,
    );
  }

  /// `null` = "any operation". Mixed runs only match when [operation] is
  /// `null` or explicitly `mixed` — a 혼합 run shouldn't credit a "덧셈"
  /// condition even though it contains 덧셈 attempts (record-level type rules).
  final GameType? operation;

  /// `null` = "any level". Times-table runs (level 0) never match any level
  /// constraint and never count toward conditions.
  final int? level;

  /// How many matching games must be completed. Minimum 1.
  final int targetCount;

  /// When true, only correctCount == totalCount games count.
  final bool requirePerfect;

  /// When non-null, only games finished in this many seconds or fewer count.
  final int? maxSeconds;

  Map<String, dynamic> toJson() => {
    'operation': operation?.name,
    'level': level,
    'targetCount': targetCount,
    'requirePerfect': requirePerfect,
    'maxSeconds': maxSeconds,
  };

  StampCondition copyWith({
    Object? operation = _sentinel,
    Object? level = _sentinel,
    int? targetCount,
    bool? requirePerfect,
    Object? maxSeconds = _sentinel,
  }) {
    return StampCondition(
      operation: identical(operation, _sentinel)
          ? this.operation
          : operation as GameType?,
      level: identical(level, _sentinel) ? this.level : level as int?,
      targetCount: targetCount ?? this.targetCount,
      requirePerfect: requirePerfect ?? this.requirePerfect,
      maxSeconds: identical(maxSeconds, _sentinel)
          ? this.maxSeconds
          : maxSeconds as int?,
    );
  }

  /// Human-readable Korean description, e.g.
  /// "덧셈 레벨 3 (만점, 30초 이내) 5회".
  String describe() {
    final base = <String>[];
    if (operation != null) base.add(operation!.label);
    if (level != null) base.add('레벨 $level');
    if (base.isEmpty) base.add('아무 게임');

    final modifiers = <String>[];
    if (requirePerfect) modifiers.add('만점');
    if (maxSeconds != null) modifiers.add('$maxSeconds초 이내');

    final modSuffix = modifiers.isEmpty ? '' : ' (${modifiers.join(', ')})';
    return '${base.join(' ')}$modSuffix $targetCount회';
  }
}

// Sentinel so copyWith can distinguish "not passed" from "passed null".
const Object _sentinel = Object();
