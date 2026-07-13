import '../data/models/game_record.dart';

/// One day's activity in the weekly report.
class DayActivity {
  const DayActivity({
    required this.day,
    required this.games,
    required this.correct,
    required this.problems,
  });

  final DateTime day;
  final int games;
  final int correct;
  final int problems;

  bool get isActive => games > 0;
  double get accuracy => problems == 0 ? 0 : correct / problems;
}

/// Parent-facing summary of the last 7 days (today inclusive).
class WeeklyReport {
  WeeklyReport({required this.days});

  /// Seven entries, oldest first, ending today.
  final List<DayActivity> days;

  int get totalGames => days.fold(0, (s, d) => s + d.games);
  int get totalCorrect => days.fold(0, (s, d) => s + d.correct);
  int get totalProblems => days.fold(0, (s, d) => s + d.problems);
  int get activeDays => days.where((d) => d.isActive).length;
  int get maxGames => days.fold(0, (m, d) => d.games > m ? d.games : m);
  double get accuracy => totalProblems == 0 ? 0 : totalCorrect / totalProblems;

  /// Plain-text summary for sharing with a parent (e.g. via KakaoTalk).
  String shareText(String name) {
    final pct = (accuracy * 100).round();
    return '[$name 주간 학습 리포트]\n'
        '최근 7일 동안 $activeDays일 학습했어요.\n'
        '푼 게임 $totalGames판 · 맞힌 문제 $totalCorrect개 · 정답률 $pct%\n'
        '연산 히어로와 함께 꾸준히 공부하고 있어요!';
  }
}

/// Buckets [records] into the last 7 calendar days ending on [now]'s date.
/// Roll-up/times-table records count too — this is a coarse "how much did my
/// child study" view for parents, not the apples-to-apples per-mode analysis.
WeeklyReport computeWeeklyReport(
  Iterable<GameRecord> records, {
  DateTime? now,
}) {
  final today = now ?? DateTime.now();
  final startDay = DateTime(today.year, today.month, today.day)
      .subtract(const Duration(days: 6));

  final games = List<int>.filled(7, 0);
  final correct = List<int>.filled(7, 0);
  final problems = List<int>.filled(7, 0);

  for (final r in records) {
    final d = DateTime(
      r.finishedAt.year,
      r.finishedAt.month,
      r.finishedAt.day,
    );
    final idx = d.difference(startDay).inDays;
    if (idx < 0 || idx > 6) continue;
    games[idx] += 1;
    correct[idx] += r.correctCount;
    problems[idx] += r.totalCount;
  }

  return WeeklyReport(
    days: [
      for (var i = 0; i < 7; i++)
        DayActivity(
          day: startDay.add(Duration(days: i)),
          games: games[i],
          correct: correct[i],
          problems: problems[i],
        ),
    ],
  );
}
