/// Counts consecutive days (ending today or yesterday) that contain at least
/// one entry in [finishedAt]. Returns 0 when the most recent entry is older
/// than yesterday — so a kid who plays daily keeps the streak even if they
/// haven't opened the app yet today, but a multi-day gap resets it.
int computeStreak(Iterable<DateTime> finishedAt, {required DateTime today}) {
  if (finishedAt.isEmpty) return 0;

  final days = <DateTime>{
    for (final d in finishedAt) _dayOf(d),
  };

  final todayDay = _dayOf(today);
  final yesterdayDay = _dayOf(today.subtract(const Duration(days: 1)));

  DateTime cursor;
  if (days.contains(todayDay)) {
    cursor = todayDay;
  } else if (days.contains(yesterdayDay)) {
    cursor = yesterdayDay;
  } else {
    return 0;
  }

  var streak = 0;
  while (days.contains(cursor)) {
    streak++;
    cursor = _dayOf(cursor.subtract(const Duration(days: 1)));
  }
  return streak;
}

/// Longest run of consecutive days ever recorded. Used for streak badges that
/// must stay unlocked once earned, even if the current streak later breaks.
int computeMaxStreak(Iterable<DateTime> finishedAt) {
  if (finishedAt.isEmpty) return 0;
  final days = <DateTime>{
    for (final d in finishedAt) _dayOf(d),
  }.toList()..sort();

  var best = 1;
  var run = 1;
  for (var i = 1; i < days.length; i++) {
    final expected = _dayOf(days[i - 1].add(const Duration(days: 1)));
    if (days[i] == expected) {
      run++;
      if (run > best) best = run;
    } else {
      run = 1;
    }
  }
  return best;
}

DateTime _dayOf(DateTime d) {
  final local = d.toLocal();
  return DateTime(local.year, local.month, local.day);
}
