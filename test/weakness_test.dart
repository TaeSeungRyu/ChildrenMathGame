import 'package:children_math_game/app/data/models/game_record.dart';
import 'package:children_math_game/app/data/models/game_type.dart';
import 'package:children_math_game/app/data/models/problem_attempt.dart';
import 'package:children_math_game/app/shared/weakness.dart';
import 'package:flutter_test/flutter_test.dart';

ProblemAttempt _attempt({
  required GameType type,
  required AttemptStatus status,
}) {
  return ProblemAttempt(
    operandA: 1,
    operandB: 1,
    type: type,
    correctAnswer: 2,
    userAnswer: status == AttemptStatus.correct ? 2 : 0,
    status: status,
  );
}

GameRecord _record({
  required GameType type,
  required int level,
  required int correct,
  int wrong = 0,
  int unsolved = 0,
  DateTime? at,
}) {
  final attempts = [
    for (var i = 0; i < correct; i++)
      _attempt(type: type, status: AttemptStatus.correct),
    for (var i = 0; i < wrong; i++)
      _attempt(type: type, status: AttemptStatus.wrong),
    for (var i = 0; i < unsolved; i++)
      _attempt(type: type, status: AttemptStatus.unsolved),
  ];
  return GameRecord(
    finishedAt: at ?? DateTime(2026, 5, 1),
    type: type,
    level: level,
    correctCount: correct,
    wrongCount: wrong,
    unsolvedCount: unsolved,
    elapsedSeconds: 60,
    attempts: attempts,
  );
}

void main() {
  group('analyzeWeakness', () {
    test('empty records → no buckets, no recommendation', () {
      final result = analyzeWeakness(const []);
      expect(result.buckets, isEmpty);
      expect(result.recommendation, isNull);
    });

    test('aggregates attempts across same (type, level) bucket', () {
      final records = [
        _record(type: GameType.addition, level: 2, correct: 6, wrong: 4),
        _record(type: GameType.addition, level: 2, correct: 4, wrong: 6),
      ];
      final result = analyzeWeakness(records);
      expect(result.buckets, hasLength(1));
      final b = result.buckets.single;
      expect(b.attemptsCount, 20);
      expect(b.correctCount, 10);
      expect(b.accuracy, 0.5);
    });

    test('unsolved counts toward attempts (lowers accuracy)', () {
      final records = [
        _record(
          type: GameType.addition,
          level: 1,
          correct: 5,
          unsolved: 5,
        ),
      ];
      final result = analyzeWeakness(records);
      final b = result.bucketFor(GameType.addition, 1)!;
      expect(b.attemptsCount, 10);
      expect(b.correctCount, 5);
      expect(b.accuracy, 0.5);
    });

    test('recommendation is null when all buckets meet threshold', () {
      final records = [
        _record(type: GameType.addition, level: 1, correct: 9, wrong: 1),
        _record(type: GameType.subtraction, level: 1, correct: 8, wrong: 2),
      ];
      final result = analyzeWeakness(records);
      expect(result.recommendation, isNull);
    });

    test('recommendation picks bucket below threshold', () {
      final records = [
        _record(type: GameType.addition, level: 1, correct: 9, wrong: 1),
        _record(type: GameType.division, level: 3, correct: 3, wrong: 7),
      ];
      final result = analyzeWeakness(records);
      expect(result.recommendation, isNotNull);
      expect(result.recommendation!.type, GameType.division);
      expect(result.recommendation!.level, 3);
    });

    test('recommendation picks lowest-accuracy bucket among weak ones', () {
      final records = [
        _record(type: GameType.subtraction, level: 2, correct: 4, wrong: 6),
        _record(type: GameType.division, level: 3, correct: 2, wrong: 8),
      ];
      final result = analyzeWeakness(records);
      expect(result.recommendation!.type, GameType.division);
      expect(result.recommendation!.level, 3);
    });

    test('minAttempts gate skips tiny buckets', () {
      // 1 attempt with 0 correct (0%) — below threshold but below minAttempts.
      final records = [
        _record(type: GameType.division, level: 3, correct: 0, wrong: 1),
        _record(type: GameType.addition, level: 1, correct: 4, wrong: 6),
      ];
      final result = analyzeWeakness(records, minAttempts: 5);
      // Recommendation should be addition L1 (10 attempts, 40%), not division
      // L3 (1 attempt, 0%) — the latter doesn't meet minAttempts.
      expect(result.recommendation!.type, GameType.addition);
      expect(result.recommendation!.level, 1);
    });

    test('recentN only considers most recent records', () {
      final old = _record(
        type: GameType.addition,
        level: 1,
        correct: 0,
        wrong: 10,
        at: DateTime(2026, 1, 1),
      );
      final newer = List.generate(
        3,
        (i) => _record(
          type: GameType.addition,
          level: 1,
          correct: 10,
          at: DateTime(2026, 5, 1 + i),
        ),
      );
      final result = analyzeWeakness([old, ...newer], recentN: 3);
      // Old record should be excluded — only the 3 perfect games count.
      final b = result.bucketFor(GameType.addition, 1)!;
      expect(b.attemptsCount, 30);
      expect(b.correctCount, 30);
      expect(result.recommendation, isNull);
    });

    test('tie-break: lower level preferred at equal accuracy', () {
      final records = [
        _record(type: GameType.addition, level: 3, correct: 4, wrong: 6),
        _record(type: GameType.addition, level: 1, correct: 4, wrong: 6),
      ];
      final result = analyzeWeakness(records);
      expect(result.recommendation!.level, 1);
    });

    test('tie-break: enum order when accuracy and level tied', () {
      // addition is enum index 0, subtraction is 1 → addition wins.
      final records = [
        _record(type: GameType.subtraction, level: 2, correct: 4, wrong: 6),
        _record(type: GameType.addition, level: 2, correct: 4, wrong: 6),
      ];
      final result = analyzeWeakness(records);
      expect(result.recommendation!.type, GameType.addition);
    });

    test('mixed-type records are excluded from analysis', () {
      // Recommendation card sends users to a single (type, level) drill, so
      // mixed runs (which bundle several ops) shouldn't influence the pick.
      final records = [
        _record(
          type: GameType.mixed,
          level: 3,
          correct: 0,
          wrong: 10,
        ),
      ];
      final result = analyzeWeakness(records);
      expect(result.buckets, isEmpty);
      expect(result.recommendation, isNull);
    });

    test('level 0 records (times-table practice) are excluded', () {
      // Times-table runs are practice-only and use level 0 as a placeholder.
      // They shouldn't influence weakness analysis even if they leaked through.
      final records = [
        _record(
          type: GameType.multiplication,
          level: 0,
          correct: 0,
          wrong: 10,
        ),
      ];
      final result = analyzeWeakness(records);
      expect(result.buckets, isEmpty);
      expect(result.recommendation, isNull);
    });
  });
}
