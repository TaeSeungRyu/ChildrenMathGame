import 'package:children_math_game/app/data/models/custom_stamp.dart';
import 'package:children_math_game/app/data/models/game_record.dart';
import 'package:children_math_game/app/data/models/game_type.dart';
import 'package:children_math_game/app/data/models/stamp_condition.dart';
import 'package:children_math_game/app/shared/stamp_evaluation.dart';
import 'package:flutter_test/flutter_test.dart';

GameRecord _record({
  GameType type = GameType.addition,
  int level = 1,
  int correct = 10,
  int wrong = 0,
  int unsolved = 0,
  int elapsedSeconds = 60,
  DateTime? at,
}) {
  return GameRecord(
    finishedAt: at ?? DateTime(2026, 5, 12),
    type: type,
    level: level,
    correctCount: correct,
    wrongCount: wrong,
    unsolvedCount: unsolved,
    elapsedSeconds: elapsedSeconds,
    attempts: const [],
  );
}

void main() {
  group('StampCondition.describe', () {
    test('all-null condition reads as "아무 게임 N회"', () {
      const c = StampCondition(targetCount: 5);
      expect(c.describe(), '아무 게임 5회');
    });

    test('full condition reads in natural order', () {
      const c = StampCondition(
        operation: GameType.addition,
        level: 3,
        targetCount: 5,
        requirePerfect: true,
        maxSeconds: 30,
      );
      expect(c.describe(), '덧셈 레벨 3 (만점, 30초 이내) 5회');
    });

    test('partial condition omits null fields', () {
      const c = StampCondition(
        level: 5,
        targetCount: 2,
        requirePerfect: true,
      );
      expect(c.describe(), '레벨 5 (만점) 2회');
    });
  });

  group('StampCondition JSON', () {
    test('roundtrips with all fields set', () {
      const c = StampCondition(
        operation: GameType.multiplication,
        level: 2,
        targetCount: 7,
        requirePerfect: true,
        maxSeconds: 45,
      );
      final back = StampCondition.fromJson(c.toJson());
      expect(back.operation, c.operation);
      expect(back.level, c.level);
      expect(back.targetCount, c.targetCount);
      expect(back.requirePerfect, c.requirePerfect);
      expect(back.maxSeconds, c.maxSeconds);
    });

    test('roundtrips with null fields', () {
      const c = StampCondition(targetCount: 3);
      final back = StampCondition.fromJson(c.toJson());
      expect(back.operation, isNull);
      expect(back.level, isNull);
      expect(back.maxSeconds, isNull);
      expect(back.requirePerfect, isFalse);
      expect(back.targetCount, 3);
    });
  });

  group('CustomStamp back-compat', () {
    test('fromJson handles missing condition key', () {
      final json = {
        'id': 's_old',
        'title': 'Legacy',
        'emoji': '⭐',
        'colorValue': 0xFF1E88E5,
        'earned': true,
        'createdAt': DateTime(2026, 1, 1).toIso8601String(),
      };
      final stamp = CustomStamp.fromJson(json);
      expect(stamp.condition, isNull);
      expect(stamp.isAuto, isFalse);
      expect(stamp.earned, isTrue);
    });

    test('copyWith can explicitly clear condition', () {
      final original = CustomStamp(
        id: 's_1',
        title: 'A',
        emoji: '⭐',
        colorValue: 0,
        earned: false,
        createdAt: DateTime(2026, 5, 12),
        condition: const StampCondition(targetCount: 1),
      );
      final cleared = original.copyWith(condition: null);
      expect(cleared.condition, isNull);
      expect(cleared.isAuto, isFalse);
    });

    test('copyWith without condition arg preserves existing', () {
      final original = CustomStamp(
        id: 's_1',
        title: 'A',
        emoji: '⭐',
        colorValue: 0,
        earned: false,
        createdAt: DateTime(2026, 5, 12),
        condition: const StampCondition(targetCount: 5),
      );
      final updated = original.copyWith(title: 'B');
      expect(updated.condition?.targetCount, 5);
    });
  });

  group('evaluateStampCondition', () {
    test('empty records → progress 0', () {
      const c = StampCondition(targetCount: 1);
      expect(evaluateStampCondition(c, const []), 0);
    });

    test('counts only records matching the operation', () {
      const c = StampCondition(
        operation: GameType.addition,
        targetCount: 1,
      );
      final records = [
        _record(type: GameType.addition),
        _record(type: GameType.addition),
        _record(type: GameType.multiplication),
      ];
      expect(evaluateStampCondition(c, records), 2);
    });

    test('null operation matches every operation', () {
      const c = StampCondition(targetCount: 1);
      final records = [
        _record(type: GameType.addition),
        _record(type: GameType.multiplication),
        _record(type: GameType.division),
      ];
      expect(evaluateStampCondition(c, records), 3);
    });

    test('level filter is strict — no partial match', () {
      const c = StampCondition(level: 3, targetCount: 1);
      final records = [
        _record(level: 1),
        _record(level: 3),
        _record(level: 5),
      ];
      expect(evaluateStampCondition(c, records), 1);
    });

    test('requirePerfect excludes non-perfect games', () {
      const c = StampCondition(targetCount: 1, requirePerfect: true);
      final records = [
        _record(correct: 10, wrong: 0), // perfect
        _record(correct: 9, wrong: 1), // not perfect
        _record(correct: 0, unsolved: 10), // not perfect, also empty
      ];
      expect(evaluateStampCondition(c, records), 1);
    });

    test('maxSeconds excludes slower games', () {
      const c = StampCondition(targetCount: 1, maxSeconds: 60);
      final records = [
        _record(elapsedSeconds: 30),
        _record(elapsedSeconds: 60),
        _record(elapsedSeconds: 90),
      ];
      expect(evaluateStampCondition(c, records), 2);
    });

    test('combined filters AND together', () {
      const c = StampCondition(
        operation: GameType.multiplication,
        level: 3,
        targetCount: 1,
        requirePerfect: true,
        maxSeconds: 60,
      );
      final records = [
        // Matches all five criteria.
        _record(
          type: GameType.multiplication,
          level: 3,
          correct: 10,
          elapsedSeconds: 45,
        ),
        // Wrong type.
        _record(
          type: GameType.addition,
          level: 3,
          correct: 10,
          elapsedSeconds: 45,
        ),
        // Wrong level.
        _record(
          type: GameType.multiplication,
          level: 2,
          correct: 10,
          elapsedSeconds: 45,
        ),
        // Not perfect.
        _record(
          type: GameType.multiplication,
          level: 3,
          correct: 9,
          wrong: 1,
          elapsedSeconds: 45,
        ),
        // Too slow.
        _record(
          type: GameType.multiplication,
          level: 3,
          correct: 10,
          elapsedSeconds: 70,
        ),
      ];
      expect(evaluateStampCondition(c, records), 1);
    });

    test('times-table runs (level 0) never count', () {
      const c = StampCondition(targetCount: 1);
      final records = [_record(level: 0)];
      expect(evaluateStampCondition(c, records), 0);
    });
  });
}
