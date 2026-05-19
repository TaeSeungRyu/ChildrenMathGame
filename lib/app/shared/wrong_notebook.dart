import '../data/models/game_record.dart';
import '../data/models/game_type.dart';
import '../data/models/problem_attempt.dart';
import '../data/models/wrong_notebook_entry.dart';

/// Aggregates wrong/unsolved attempts across all records, deduplicating by
/// problem identity (operands + operations + correctAnswer). Sorted by
/// frequency desc, then most recent first — frequently missed problems
/// surface to the top.
List<WrongNotebookEntry> aggregateWrongNotebook(List<GameRecord> records) {
  final byKey = <String, _Acc>{};
  for (final r in records) {
    for (final a in r.attempts) {
      if (a.status == AttemptStatus.correct) continue;
      final key = _signatureOf(a);
      final existing = byKey[key];
      if (existing == null) {
        byKey[key] = _Acc(
          sample: a,
          wrongCount: 1,
          lastWrongAt: r.finishedAt,
        );
      } else {
        final newer = r.finishedAt.isAfter(existing.lastWrongAt);
        byKey[key] = _Acc(
          sample: newer ? a : existing.sample,
          wrongCount: existing.wrongCount + 1,
          lastWrongAt: newer ? r.finishedAt : existing.lastWrongAt,
        );
      }
    }
  }
  final list = byKey.values
      .map(
        (acc) => WrongNotebookEntry(
          sample: acc.sample,
          wrongCount: acc.wrongCount,
          lastWrongAt: acc.lastWrongAt,
          bucket: _bucketOf(acc.sample),
        ),
      )
      .toList();
  list.sort((a, b) {
    final byCount = b.wrongCount.compareTo(a.wrongCount);
    if (byCount != 0) return byCount;
    return b.lastWrongAt.compareTo(a.lastWrongAt);
  });
  return list;
}

String _signatureOf(ProblemAttempt a) {
  final ops = a.operations.map((o) => o.name).join(',');
  final operands = a.operands.join(',');
  return '$operands|$ops|${a.correctAnswer}';
}

GameType _bucketOf(ProblemAttempt a) {
  if (a.isCompound) return GameType.mixed;
  if (a.isEquation) return GameType.equation;
  return a.type;
}

class _Acc {
  _Acc({
    required this.sample,
    required this.wrongCount,
    required this.lastWrongAt,
  });

  final ProblemAttempt sample;
  final int wrongCount;
  final DateTime lastWrongAt;
}
