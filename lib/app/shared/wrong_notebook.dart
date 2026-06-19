import '../data/models/game_record.dart';
import '../data/models/game_type.dart';
import '../data/models/problem_attempt.dart';
import '../data/models/wrong_notebook_entry.dart';

/// Aggregates wrong/unsolved attempts across all records, deduplicating by
/// problem identity (operands + operations + correctAnswer). Sorted by
/// frequency desc, then most recent first — frequently missed problems
/// surface to the top.
///
/// `dismissedAt` maps a [wrongNotebookSignature] to the moment the user
/// dismissed that problem from the notebook. Attempts in records finished at
/// or before that moment are filtered out, so newer misses of the same
/// problem still resurface the entry.
List<WrongNotebookEntry> aggregateWrongNotebook(
  List<GameRecord> records, {
  Map<String, DateTime> dismissedAt = const {},
}) {
  final byKey = <String, _Acc>{};
  for (final r in records) {
    for (final a in r.attempts) {
      if (a.status == AttemptStatus.correct) continue;
      // 어림셈 오답은 오답노트에서 제외. 정답이 "정확한 계산 결과"가 아니라
      // "반올림 어림값"이라 복습 화면이 정확값 입력을 받는 흐름과 맞지 않는다.
      if (a.isEstimation) continue;
      final key = wrongNotebookSignature(a);
      final dismissed = dismissedAt[key];
      if (dismissed != null && !r.finishedAt.isAfter(dismissed)) continue;
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

/// Stable key identifying a problem across attempts — same operands chain,
/// same operations, same expected answer. Used both for aggregation and for
/// the dismissal map persisted by `RecordService`.
String wrongNotebookSignature(ProblemAttempt a) {
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
