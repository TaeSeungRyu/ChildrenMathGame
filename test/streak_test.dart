import 'package:children_math_game/app/shared/streak.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 5, 9, 14, 30);

  group('computeStreak', () {
    test('returns 0 when no records exist', () {
      expect(computeStreak(const [], today: today), 0);
    });

    test('counts a single play today as streak 1', () {
      expect(
        computeStreak([DateTime(2026, 5, 9, 9, 0)], today: today),
        1,
      );
    });

    test('counts consecutive days ending today', () {
      final dates = [
        DateTime(2026, 5, 9, 8, 0),
        DateTime(2026, 5, 8, 18, 0),
        DateTime(2026, 5, 7, 12, 0),
      ];
      expect(computeStreak(dates, today: today), 3);
    });

    test('keeps streak when latest play was yesterday', () {
      final dates = [
        DateTime(2026, 5, 8, 20, 0),
        DateTime(2026, 5, 7, 20, 0),
      ];
      expect(computeStreak(dates, today: today), 2);
    });

    test('resets to 0 when latest play was 2+ days ago', () {
      final dates = [
        DateTime(2026, 5, 7, 20, 0),
        DateTime(2026, 5, 6, 20, 0),
      ];
      expect(computeStreak(dates, today: today), 0);
    });

    test('breaks at the first day-gap', () {
      final dates = [
        DateTime(2026, 5, 9, 8, 0),
        DateTime(2026, 5, 8, 8, 0),
        // 5/7 missing — gap
        DateTime(2026, 5, 6, 8, 0),
        DateTime(2026, 5, 5, 8, 0),
      ];
      expect(computeStreak(dates, today: today), 2);
    });

    test('multiple plays on the same day count as one', () {
      final dates = [
        DateTime(2026, 5, 9, 8, 0),
        DateTime(2026, 5, 9, 18, 0),
        DateTime(2026, 5, 9, 21, 0),
      ];
      expect(computeStreak(dates, today: today), 1);
    });

    test('order of input does not matter', () {
      final dates = [
        DateTime(2026, 5, 7, 12, 0),
        DateTime(2026, 5, 9, 8, 0),
        DateTime(2026, 5, 8, 18, 0),
      ];
      expect(computeStreak(dates, today: today), 3);
    });
  });

  group('computeMaxStreak', () {
    test('returns 0 when empty', () {
      expect(computeMaxStreak(const []), 0);
    });

    test('returns 1 for a single day', () {
      expect(computeMaxStreak([DateTime(2026, 5, 1)]), 1);
    });

    test('returns longest run when multiple separate runs exist', () {
      // Run A: May 1-2 (2 days). Run B: May 4-7 (4 days). Run C: May 9 (1).
      final dates = [
        DateTime(2026, 5, 1, 9),
        DateTime(2026, 5, 2, 9),
        DateTime(2026, 5, 4, 9),
        DateTime(2026, 5, 5, 9),
        DateTime(2026, 5, 6, 9),
        DateTime(2026, 5, 7, 9),
        DateTime(2026, 5, 9, 9),
      ];
      expect(computeMaxStreak(dates), 4);
    });

    test('multiple plays on the same day count once', () {
      final dates = [
        DateTime(2026, 5, 1, 9),
        DateTime(2026, 5, 1, 18),
        DateTime(2026, 5, 2, 9),
      ];
      expect(computeMaxStreak(dates), 2);
    });

    test('handles month boundary', () {
      final dates = [
        DateTime(2026, 4, 30, 9),
        DateTime(2026, 5, 1, 9),
        DateTime(2026, 5, 2, 9),
      ];
      expect(computeMaxStreak(dates), 3);
    });
  });
}
