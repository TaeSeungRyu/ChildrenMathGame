import '../data/models/game_record.dart';
import '../data/models/game_type.dart';
import '../data/models/problem_attempt.dart';

class WeaknessBucket {
  const WeaknessBucket({
    required this.type,
    required this.level,
    required this.attemptsCount,
    required this.correctCount,
  });

  final GameType type;
  final int level;
  final int attemptsCount;
  final int correctCount;

  double get accuracy =>
      attemptsCount == 0 ? 0 : correctCount / attemptsCount;
}

class WeaknessAnalysis {
  const WeaknessAnalysis({
    required this.buckets,
    required this.recommendation,
  });

  final List<WeaknessBucket> buckets;
  final WeaknessBucket? recommendation;

  WeaknessBucket? bucketFor(GameType type, int level) {
    for (final b in buckets) {
      if (b.type == type && b.level == level) return b;
    }
    return null;
  }
}

WeaknessAnalysis analyzeWeakness(
  List<GameRecord> records, {
  int recentN = 10,
  double threshold = 0.6,
  int minAttempts = 5,
}) {
  final sorted = [...records]
    ..sort((a, b) => b.finishedAt.compareTo(a.finishedAt));
  final recent = sorted.take(recentN);

  final correctByKey = <String, int>{};
  final totalByKey = <String, int>{};

  for (final r in recent) {
    // Times-table practice runs use level 0 as a placeholder and aren't part
    // of the leveled difficulty progression — skip them for weakness analysis.
    if (r.level < 1) continue;
    final key = '${r.type.name}|${r.level}';
    for (final a in r.attempts) {
      totalByKey[key] = (totalByKey[key] ?? 0) + 1;
      if (a.status == AttemptStatus.correct) {
        correctByKey[key] = (correctByKey[key] ?? 0) + 1;
      }
    }
  }

  final buckets = <WeaknessBucket>[];
  for (final key in totalByKey.keys) {
    final parts = key.split('|');
    final type = GameType.values.byName(parts[0]);
    final level = int.parse(parts[1]);
    buckets.add(
      WeaknessBucket(
        type: type,
        level: level,
        attemptsCount: totalByKey[key]!,
        correctCount: correctByKey[key] ?? 0,
      ),
    );
  }

  WeaknessBucket? best;
  for (final b in buckets) {
    if (b.attemptsCount < minAttempts) continue;
    if (b.accuracy >= threshold) continue;
    if (best == null) {
      best = b;
      continue;
    }
    if (b.accuracy < best.accuracy) {
      best = b;
    } else if (b.accuracy == best.accuracy) {
      // Tie-break: lower level first (easier re-entry), then enum order.
      if (b.level < best.level ||
          (b.level == best.level && b.type.index < best.type.index)) {
        best = b;
      }
    }
  }

  return WeaknessAnalysis(buckets: buckets, recommendation: best);
}
