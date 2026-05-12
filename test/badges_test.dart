import 'package:children_math_game/app/data/models/game_record.dart';
import 'package:children_math_game/app/data/models/game_type.dart';
import 'package:children_math_game/app/shared/badges.dart';
import 'package:flutter_test/flutter_test.dart';

GameRecord _record({
  required GameType type,
  required int level,
  required int correct,
  int wrong = 0,
  int unsolved = 0,
  int maxCombo = 0,
  DateTime? at,
}) {
  return GameRecord(
    finishedAt: at ?? DateTime(2026, 5, 1),
    type: type,
    level: level,
    correctCount: correct,
    wrongCount: wrong,
    unsolvedCount: unsolved,
    elapsedSeconds: 60,
    attempts: const [],
    maxCombo: maxCombo,
  );
}

GameRecord _perfect(GameType type, int level, {DateTime? at}) =>
    _record(type: type, level: level, correct: 10, at: at);

void main() {
  group('evaluateBadges', () {
    test('all locked when no records', () {
      final result = evaluateBadges(const [], maxStreak: 0);
      expect(result.length, 17);
      expect(result.every((b) => !b.unlocked), isTrue);
    });

    test('first_game unlocks on any record', () {
      final result = evaluateBadges(
        [_record(type: GameType.addition, level: 1, correct: 0, wrong: 10)],
        maxStreak: 0,
      );
      final firstGame = result.firstWhere((b) => b.badge.id == 'first_game');
      expect(firstGame.unlocked, isTrue);
    });

    test('first_perfect requires correctCount == totalCount and total > 0', () {
      // All-zeros record (every problem unsolved) must NOT count as perfect.
      final allUnsolved = _record(
        type: GameType.addition,
        level: 1,
        correct: 0,
        unsolved: 10,
      );
      var result = evaluateBadges([allUnsolved], maxStreak: 0);
      expect(
        result.firstWhere((b) => b.badge.id == 'first_perfect').unlocked,
        isFalse,
      );

      result = evaluateBadges([_perfect(GameType.addition, 1)], maxStreak: 0);
      expect(
        result.firstWhere((b) => b.badge.id == 'first_perfect').unlocked,
        isTrue,
      );
    });

    test('cumulative correct totals power correct_50/100/300', () {
      final records = List.generate(
        7,
        (_) => _record(type: GameType.addition, level: 1, correct: 8, wrong: 2),
      );
      final result = evaluateBadges(records, maxStreak: 0);
      expect(
        result.firstWhere((b) => b.badge.id == 'correct_50').unlocked,
        isTrue,
      );
      final c100 = result.firstWhere((b) => b.badge.id == 'correct_100');
      expect(c100.unlocked, isFalse);
      expect(c100.current, 56);
      expect(c100.target, 100);
      expect(c100.progress, closeTo(0.56, 1e-6));
    });

    test('streak badges read from maxStreak', () {
      final result = evaluateBadges(const [], maxStreak: 7);
      expect(
        result.firstWhere((b) => b.badge.id == 'streak_3').unlocked,
        isTrue,
      );
      expect(
        result.firstWhere((b) => b.badge.id == 'streak_7').unlocked,
        isTrue,
      );
      expect(
        result.firstWhere((b) => b.badge.id == 'streak_30').unlocked,
        isFalse,
      );
    });

    test('operation master requires level 5 perfect for that type', () {
      // Level 4 perfect of addition must not unlock add_master.
      var result = evaluateBadges(
        [_perfect(GameType.addition, 4)],
        maxStreak: 0,
      );
      expect(
        result.firstWhere((b) => b.badge.id == 'add_master').unlocked,
        isFalse,
      );

      // Level 5 perfect of addition unlocks only add_master.
      result = evaluateBadges(
        [_perfect(GameType.addition, 5)],
        maxStreak: 0,
      );
      expect(
        result.firstWhere((b) => b.badge.id == 'add_master').unlocked,
        isTrue,
      );
      expect(
        result.firstWhere((b) => b.badge.id == 'sub_master').unlocked,
        isFalse,
      );
    });

    test('all_ops_perfect requires one perfect game per operation', () {
      var result = evaluateBadges([
        _perfect(GameType.addition, 1),
        _perfect(GameType.subtraction, 1),
        _perfect(GameType.multiplication, 1),
      ], maxStreak: 0);
      expect(
        result.firstWhere((b) => b.badge.id == 'all_ops_perfect').unlocked,
        isFalse,
      );

      result = evaluateBadges([
        _perfect(GameType.addition, 1),
        _perfect(GameType.subtraction, 1),
        _perfect(GameType.multiplication, 1),
        _perfect(GameType.division, 1),
      ], maxStreak: 0);
      expect(
        result.firstWhere((b) => b.badge.id == 'all_ops_perfect').unlocked,
        isTrue,
      );
    });

    test('combo_5/combo_10 read the best maxCombo across all records', () {
      // No combos yet — both locked, progress reads 0.
      var result = evaluateBadges(
        [_record(type: GameType.addition, level: 1, correct: 5, wrong: 5)],
        maxStreak: 0,
      );
      final c5 = result.firstWhere((b) => b.badge.id == 'combo_5');
      expect(c5.unlocked, isFalse);
      expect(c5.current, 0);

      // A 5-combo unlocks combo_5 but not combo_10.
      result = evaluateBadges(
        [
          _record(
            type: GameType.addition,
            level: 1,
            correct: 5,
            wrong: 5,
            maxCombo: 5,
          ),
        ],
        maxStreak: 0,
      );
      expect(
        result.firstWhere((b) => b.badge.id == 'combo_5').unlocked,
        isTrue,
      );
      final c10 = result.firstWhere((b) => b.badge.id == 'combo_10');
      expect(c10.unlocked, isFalse);
      expect(c10.current, 5);

      // Picks the max across records.
      result = evaluateBadges(
        [
          _record(
            type: GameType.addition,
            level: 1,
            correct: 5,
            maxCombo: 3,
          ),
          _record(
            type: GameType.multiplication,
            level: 1,
            correct: 10,
            maxCombo: 10,
          ),
        ],
        maxStreak: 0,
      );
      expect(
        result.firstWhere((b) => b.badge.id == 'combo_10').unlocked,
        isTrue,
      );
    });

    test('perfect_5/perfect_20 count perfect games', () {
      final records = [
        for (var i = 0; i < 5; i++) _perfect(GameType.addition, 1),
        // Non-perfect game must not count.
        _record(type: GameType.addition, level: 1, correct: 9, wrong: 1),
      ];
      final result = evaluateBadges(records, maxStreak: 0);
      expect(
        result.firstWhere((b) => b.badge.id == 'perfect_5').unlocked,
        isTrue,
      );
      final p20 = result.firstWhere((b) => b.badge.id == 'perfect_20');
      expect(p20.unlocked, isFalse);
      expect(p20.current, 5);
      expect(p20.target, 20);
    });
  });
}
