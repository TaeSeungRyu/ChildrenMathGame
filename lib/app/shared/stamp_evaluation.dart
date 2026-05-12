import '../data/models/game_record.dart';
import '../data/models/stamp_condition.dart';

/// Returns the number of records in [records] that satisfy [c]. The caller
/// compares against [StampCondition.targetCount] to decide if the stamp is
/// earned. Practice runs are already excluded upstream (not in records.all()).
int evaluateStampCondition(
  StampCondition c,
  Iterable<GameRecord> records,
) {
  var n = 0;
  for (final r in records) {
    if (_matches(c, r)) n++;
  }
  return n;
}

bool _matches(StampCondition c, GameRecord r) {
  // Times-table runs use level 0 as a placeholder. They aren't part of the
  // leveled difficulty progression, so they never count toward stamp goals.
  if (r.level < 1) return false;

  if (c.operation != null && r.type != c.operation) return false;
  if (c.level != null && r.level != c.level) return false;

  if (c.requirePerfect) {
    if (r.totalCount == 0 || r.correctCount != r.totalCount) return false;
  }

  if (c.maxSeconds != null && r.elapsedSeconds > c.maxSeconds!) return false;

  return true;
}
