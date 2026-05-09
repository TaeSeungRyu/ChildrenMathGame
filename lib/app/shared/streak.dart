/// Counts consecutive days (ending today or yesterday) that contain at least
/// one entry in [finishedAt]. Returns 0 when the most recent entry is older
/// than yesterday — so a kid who plays daily keeps the streak even if they
/// haven't opened the app yet today, but a multi-day gap resets it.
int computeStreak(Iterable<DateTime> finishedAt, {required DateTime today}) {
  if (finishedAt.isEmpty) return 0;

  final playedDays = <int>{
    for (final d in finishedAt) _dayKey(d),
  };

  final todayKey = _dayKey(today);
  final yesterdayKey = _dayKey(today.subtract(const Duration(days: 1)));

  var cursor = playedDays.contains(todayKey)
      ? today
      : playedDays.contains(yesterdayKey)
          ? today.subtract(const Duration(days: 1))
          : null;
  if (cursor == null) return 0;

  var streak = 0;
  while (playedDays.contains(_dayKey(cursor!))) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

int _dayKey(DateTime d) {
  final local = d.toLocal();
  return local.year * 10000 + local.month * 100 + local.day;
}
