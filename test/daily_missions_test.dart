import 'package:children_math_game/app/data/models/daily_mission.dart';
import 'package:children_math_game/app/data/models/game_record.dart';
import 'package:children_math_game/app/data/models/game_type.dart';
import 'package:children_math_game/app/shared/daily_missions.dart';
import 'package:flutter_test/flutter_test.dart';

GameRecord _record({
  required GameType type,
  required int level,
  required int correct,
  int wrong = 0,
  int unsolved = 0,
  int maxCombo = 0,
  required DateTime at,
}) {
  return GameRecord(
    finishedAt: at,
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

void main() {
  group('generateDailyMissions', () {
    test('returns exactly 3 missions', () {
      final missions = generateDailyMissions(DateTime(2026, 5, 12));
      expect(missions, hasLength(3));
    });

    test('same day → same missions (deterministic)', () {
      final a = generateDailyMissions(DateTime(2026, 5, 12));
      final b = generateDailyMissions(DateTime(2026, 5, 12, 23, 59));
      // Time-of-day shouldn't matter — only Y/M/D feeds the seed.
      expect(a.map((m) => m.dedupeKey), b.map((m) => m.dedupeKey));
      expect(
        a.map((m) => m.target).toList(),
        b.map((m) => m.target).toList(),
      );
    });

    test('different days produce different mission sets (usually)', () {
      // Not a strong guarantee, but across a 30-day window we'd expect at
      // least some variation in the chosen mission shapes.
      final sets = <String>{};
      for (var d = 1; d <= 30; d++) {
        final missions = generateDailyMissions(DateTime(2026, 5, d));
        sets.add(missions.map((m) => m.dedupeKey).join(','));
      }
      expect(sets.length, greaterThan(5));
    });

    test('missions are distinct by dedupeKey', () {
      // 50-day sweep — every day's 3 missions must be distinct shapes.
      for (var d = 1; d <= 50; d++) {
        final missions = generateDailyMissions(DateTime(2026, 1, d));
        final keys = missions.map((m) => m.dedupeKey).toList();
        expect(keys.toSet().length, 3, reason: 'day $d had duplicate shapes');
      }
    });
  });

  group('evaluateDailyMissions', () {
    final today = DateTime(2026, 5, 12, 10);
    final yesterday = DateTime(2026, 5, 11, 23);

    test('returns 3 statuses with zero progress when no records', () {
      final result = evaluateDailyMissions(const [], now: today);
      expect(result, hasLength(3));
      for (final s in result) {
        expect(s.progress, 0);
        expect(s.isComplete, isFalse);
      }
    });

    test('only today\'s records contribute to progress', () {
      // Build records: a big perfect game yesterday, nothing today.
      final records = [
        _record(
          type: GameType.addition,
          level: 1,
          correct: 50,
          maxCombo: 10,
          at: yesterday,
        ),
      ];
      final result = evaluateDailyMissions(records, now: today);
      for (final s in result) {
        expect(s.progress, 0);
      }
    });

    test('correctAnswers sums today\'s correctCount', () {
      // Generate a known day's missions, find any "correctAnswers" one if
      // present. We can't pin to a specific day picking it, so try a few.
      DateTime? dayWithMission;
      int? target;
      for (var d = 1; d <= 50; d++) {
        final day = DateTime(2026, 5, d, 10);
        final ms = generateDailyMissions(day);
        final m = ms.firstWhere(
          (m) => m.type == DailyMissionType.correctAnswers,
          orElse: () => const DailyMission(
            type: DailyMissionType.perfectGames,
            target: -1,
          ),
        );
        if (m.target > 0) {
          dayWithMission = day;
          target = m.target;
          break;
        }
      }
      expect(
        dayWithMission,
        isNotNull,
        reason: 'should find a correctAnswers mission within 50 days',
      );

      final records = [
        _record(
          type: GameType.addition,
          level: 1,
          correct: 8,
          at: dayWithMission!,
        ),
        _record(
          type: GameType.multiplication,
          level: 2,
          correct: 7,
          at: dayWithMission,
        ),
      ];
      final result = evaluateDailyMissions(records, now: dayWithMission);
      final status = result.firstWhere(
        (s) => s.mission.type == DailyMissionType.correctAnswers,
      );
      expect(status.progress, 15);
      expect(status.isComplete, 15 >= target!);
    });

    test('achieveCombo reads max combo across today\'s records', () {
      DateTime? day;
      for (var d = 1; d <= 50; d++) {
        final candidate = DateTime(2026, 5, d, 10);
        final ms = generateDailyMissions(candidate);
        if (ms.any((m) => m.type == DailyMissionType.achieveCombo)) {
          day = candidate;
          break;
        }
      }
      expect(day, isNotNull);
      final records = [
        _record(
          type: GameType.addition,
          level: 1,
          correct: 5,
          maxCombo: 3,
          at: day!,
        ),
        _record(
          type: GameType.addition,
          level: 1,
          correct: 8,
          maxCombo: 8,
          at: day,
        ),
      ];
      final result = evaluateDailyMissions(records, now: day);
      final status = result.firstWhere(
        (s) => s.mission.type == DailyMissionType.achieveCombo,
      );
      expect(status.progress, 8);
    });

    test('perfectGames counts only fully-correct games', () {
      DateTime? day;
      for (var d = 1; d <= 50; d++) {
        final candidate = DateTime(2026, 5, d, 10);
        final ms = generateDailyMissions(candidate);
        if (ms.any((m) => m.type == DailyMissionType.perfectGames)) {
          day = candidate;
          break;
        }
      }
      expect(day, isNotNull);
      final records = [
        // Perfect.
        _record(
          type: GameType.addition,
          level: 1,
          correct: 10,
          at: day!,
        ),
        // Not perfect (one wrong).
        _record(
          type: GameType.addition,
          level: 1,
          correct: 9,
          wrong: 1,
          at: day,
        ),
        // Empty (no problems answered) — must not count as perfect.
        _record(
          type: GameType.addition,
          level: 1,
          correct: 0,
          unsolved: 10,
          at: day,
        ),
      ];
      final result = evaluateDailyMissions(records, now: day);
      final status = result.firstWhere(
        (s) => s.mission.type == DailyMissionType.perfectGames,
      );
      expect(status.progress, 1);
    });

    test('correctInType only counts matching operation', () {
      DateTime? day;
      DailyMission? mission;
      for (var d = 1; d <= 50; d++) {
        final candidate = DateTime(2026, 5, d, 10);
        final ms = generateDailyMissions(candidate);
        final m = ms.firstWhere(
          (m) => m.type == DailyMissionType.correctInType,
          orElse: () => const DailyMission(
            type: DailyMissionType.perfectGames,
            target: -1,
          ),
        );
        if (m.target > 0) {
          day = candidate;
          mission = m;
          break;
        }
      }
      expect(mission, isNotNull);
      final records = [
        _record(
          type: mission!.gameType!,
          level: 1,
          correct: 7,
          at: day!,
        ),
        // Different operation — should be ignored.
        _record(
          type: GameType.values.firstWhere((t) => t != mission!.gameType),
          level: 1,
          correct: 10,
          at: day,
        ),
      ];
      final result = evaluateDailyMissions(records, now: day);
      final status = result.firstWhere(
        (s) =>
            s.mission.type == DailyMissionType.correctInType &&
            s.mission.gameType == mission!.gameType,
      );
      expect(status.progress, 7);
    });
  });

  group('DailyMissionStatus', () {
    test('progressClamped never exceeds target', () {
      const mission = DailyMission(
        type: DailyMissionType.correctAnswers,
        target: 15,
      );
      final s = DailyMissionStatus(mission: mission, progress: 30);
      expect(s.progressClamped, 15);
      expect(s.isComplete, isTrue);
    });

    test('description reads naturally for each type', () {
      const m1 = DailyMission(
        type: DailyMissionType.correctAnswers,
        target: 20,
      );
      expect(m1.description, '오늘 정답 20개 맞히기');

      const m2 = DailyMission(
        type: DailyMissionType.perfectGames,
        target: 1,
      );
      expect(m2.description, '오늘 만점 1회 달성');

      const m3 = DailyMission(
        type: DailyMissionType.achieveCombo,
        target: 7,
      );
      expect(m3.description, '7 이상 콤보 기록');

      const m4 = DailyMission(
        type: DailyMissionType.correctInType,
        gameType: GameType.multiplication,
        target: 10,
      );
      expect(m4.description, '곱셈 10개 정답');
    });
  });
}
