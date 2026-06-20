import 'package:children_math_game/app/data/models/game_record.dart';
import 'package:children_math_game/app/data/models/game_type.dart';
import 'package:children_math_game/app/data/models/problem_attempt.dart';
import 'package:children_math_game/app/shared/wrong_notebook.dart';
import 'package:flutter_test/flutter_test.dart';

ProblemAttempt _wrong({
  int a = 1,
  int b = 1,
  GameType type = GameType.addition,
  int correct = 2,
  int user = 9,
  AttemptStatus status = AttemptStatus.wrong,
  bool isEstimation = false,
}) {
  return ProblemAttempt(
    operandA: a,
    operandB: b,
    type: type,
    correctAnswer: correct,
    userAnswer: user,
    status: status,
    isEstimation: isEstimation,
  );
}

ProblemAttempt _correct({
  int a = 1,
  int b = 1,
  GameType type = GameType.addition,
  int correct = 2,
}) {
  return ProblemAttempt(
    operandA: a,
    operandB: b,
    type: type,
    correctAnswer: correct,
    userAnswer: correct,
    status: AttemptStatus.correct,
  );
}

GameRecord _record({
  required DateTime at,
  required List<ProblemAttempt> attempts,
  GameType type = GameType.addition,
  int level = 1,
}) {
  return GameRecord(
    finishedAt: at,
    type: type,
    level: level,
    correctCount: attempts.where((a) => a.status == AttemptStatus.correct).length,
    wrongCount: attempts.where((a) => a.status == AttemptStatus.wrong).length,
    unsolvedCount:
        attempts.where((a) => a.status == AttemptStatus.unsolved).length,
    elapsedSeconds: 60,
    attempts: attempts,
  );
}

void main() {
  group('aggregateWrongsByDay', () {
    test('empty records → empty list', () {
      expect(aggregateWrongsByDay(const []), isEmpty);
    });

    test('skips correct attempts and estimation answers', () {
      final records = [
        _record(
          at: DateTime(2026, 6, 20, 10),
          attempts: [
            _correct(),
            _wrong(isEstimation: true),
          ],
        ),
      ];
      expect(aggregateWrongsByDay(records), isEmpty);
    });

    test('groups attempts by local calendar day, newest day first', () {
      final records = [
        _record(at: DateTime(2026, 6, 18, 9), attempts: [_wrong(a: 1, b: 1)]),
        _record(at: DateTime(2026, 6, 20, 10), attempts: [_wrong(a: 2, b: 2)]),
        _record(at: DateTime(2026, 6, 19, 22), attempts: [_wrong(a: 3, b: 3)]),
      ];
      final days = aggregateWrongsByDay(records);
      expect(days.map((d) => d.date.day), [20, 19, 18]);
      expect(days.map((d) => d.count), [1, 1, 1]);
    });

    test('dedupes by signature within the same day, keeping newest attempt',
        () {
      // Same problem (1+1=2) missed twice on the same day — should appear once.
      final earlier = _wrong(a: 1, b: 1, user: 7);
      final later = _wrong(a: 1, b: 1, user: 9);
      final records = [
        _record(at: DateTime(2026, 6, 20, 9), attempts: [earlier]),
        _record(at: DateTime(2026, 6, 20, 14), attempts: [later]),
      ];
      final days = aggregateWrongsByDay(records);
      expect(days, hasLength(1));
      expect(days.single.attempts, hasLength(1));
      // Later attempt wins — its userAnswer is what's preserved.
      expect(days.single.attempts.single.userAnswer, 9);
    });

    test('same signature on different days surfaces once per day', () {
      // Cross-day, the wrong-notebook aggregator would merge these. The
      // by-day aggregator keeps them separate so each day's review is
      // self-contained.
      final records = [
        _record(at: DateTime(2026, 6, 19, 9), attempts: [_wrong(a: 1, b: 1)]),
        _record(at: DateTime(2026, 6, 20, 9), attempts: [_wrong(a: 1, b: 1)]),
      ];
      final days = aggregateWrongsByDay(records);
      expect(days, hasLength(2));
      expect(days.every((d) => d.attempts.length == 1), isTrue);
    });

    test('dismissed signature drops stale attempts but lets later misses pass',
        () {
      final sig = wrongNotebookSignature(_wrong(a: 1, b: 1));
      final dismissedAt = {sig: DateTime(2026, 6, 19, 12)};
      final records = [
        // Before dismissal → dropped.
        _record(at: DateTime(2026, 6, 19, 9), attempts: [_wrong(a: 1, b: 1)]),
        // After dismissal → kept.
        _record(at: DateTime(2026, 6, 20, 9), attempts: [_wrong(a: 1, b: 1)]),
      ];
      final days = aggregateWrongsByDay(records, dismissedAt: dismissedAt);
      expect(days, hasLength(1));
      expect(days.single.date.day, 20);
    });

    test('within a day, attempts sort newest-first', () {
      final a = _wrong(a: 1, b: 1);
      final b = _wrong(a: 2, b: 2);
      final c = _wrong(a: 3, b: 3);
      final records = [
        _record(at: DateTime(2026, 6, 20, 9), attempts: [a]),
        _record(at: DateTime(2026, 6, 20, 18), attempts: [c]),
        _record(at: DateTime(2026, 6, 20, 14), attempts: [b]),
      ];
      final days = aggregateWrongsByDay(records);
      expect(days, hasLength(1));
      expect(days.single.attempts.map((x) => x.operandA), [3, 2, 1]);
    });
  });
}
