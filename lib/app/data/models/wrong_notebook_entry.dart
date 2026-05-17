import 'game_type.dart';
import 'problem_attempt.dart';

class WrongNotebookEntry {
  WrongNotebookEntry({
    required this.sample,
    required this.wrongCount,
    required this.lastWrongAt,
    required this.bucket,
  });

  // The most recent wrong (or unsolved) attempt for this problem. Used as the
  // canonical question to retry — operands/operations/correctAnswer are
  // deterministic for a given problem, so any sample suffices for replay; we
  // keep the latest for an accurate "내 답" snapshot.
  final ProblemAttempt sample;
  // Total number of times this exact problem was missed (wrong or unsolved)
  // across all stored records.
  final int wrongCount;
  final DateTime lastWrongAt;
  // Operation bucket for filter chips. Compound attempts collapse to mixed.
  final GameType bucket;
}
