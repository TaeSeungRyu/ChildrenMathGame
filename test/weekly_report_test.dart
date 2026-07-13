import 'package:children_math_game/app/data/models/game_record.dart';
import 'package:children_math_game/app/data/models/game_type.dart';
import 'package:children_math_game/app/shared/weekly_report.dart';
import 'package:flutter_test/flutter_test.dart';

GameRecord _rec(DateTime when, {int correct = 8, int wrong = 2}) => GameRecord(
      finishedAt: when,
      type: GameType.addition,
      level: 1,
      correctCount: correct,
      wrongCount: wrong,
      unsolvedCount: 0,
      elapsedSeconds: 30,
      attempts: const [],
    );

void main() {
  final now = DateTime(2026, 7, 13, 10); // fixed "today"

  test('always returns 7 days ending today, oldest first', () {
    final r = computeWeeklyReport(const [], now: now);
    expect(r.days.length, 7);
    expect(r.days.first.day, DateTime(2026, 7, 7));
    expect(r.days.last.day, DateTime(2026, 7, 13));
  });

  test('buckets records into the right day and sums totals', () {
    final records = [
      _rec(DateTime(2026, 7, 13, 9)), // today
      _rec(DateTime(2026, 7, 13, 20)), // today again
      _rec(DateTime(2026, 7, 10, 15)), // 3 days ago
    ];
    final r = computeWeeklyReport(records, now: now);
    expect(r.days.last.games, 2);
    expect(r.days[3].games, 1); // 7/10 is index 3
    expect(r.totalGames, 3);
    expect(r.totalCorrect, 24);
    expect(r.totalProblems, 30);
    expect(r.activeDays, 2);
    expect(r.maxGames, 2);
    expect(r.accuracy, closeTo(24 / 30, 1e-9));
  });

  test('records outside the 7-day window are ignored', () {
    final records = [
      _rec(DateTime(2026, 7, 6, 9)), // 7 days ago — just outside
      _rec(DateTime(2026, 6, 1, 9)), // long ago
    ];
    final r = computeWeeklyReport(records, now: now);
    expect(r.totalGames, 0);
    expect(r.activeDays, 0);
  });

  test('shareText embeds the name and headline numbers', () {
    final r = computeWeeklyReport([_rec(now)], now: now);
    final text = r.shareText('민준');
    expect(text, contains('민준'));
    expect(text, contains('정답률 80%'));
  });
}
