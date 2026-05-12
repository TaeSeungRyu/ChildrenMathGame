import 'dart:math';

import '../data/models/daily_mission.dart';
import '../data/models/game_record.dart';
import '../data/models/game_type.dart';

// Static pool of possible daily missions. The day-seeded shuffle picks 3
// distinct shapes (by `dedupeKey`) from here. Keep targets achievable in
// a typical play session — a child who plays 1-2 challenge games should be
// able to clear at least one mission.
const _pool = <DailyMission>[
  DailyMission(type: DailyMissionType.correctAnswers, target: 15),
  DailyMission(type: DailyMissionType.correctAnswers, target: 25),
  DailyMission(type: DailyMissionType.perfectGames, target: 1),
  DailyMission(type: DailyMissionType.perfectGames, target: 2),
  DailyMission(type: DailyMissionType.achieveCombo, target: 5),
  DailyMission(type: DailyMissionType.achieveCombo, target: 7),
  DailyMission(type: DailyMissionType.achieveCombo, target: 10),
  DailyMission(
    type: DailyMissionType.correctInType,
    gameType: GameType.addition,
    target: 10,
  ),
  DailyMission(
    type: DailyMissionType.correctInType,
    gameType: GameType.subtraction,
    target: 10,
  ),
  DailyMission(
    type: DailyMissionType.correctInType,
    gameType: GameType.multiplication,
    target: 10,
  ),
  DailyMission(
    type: DailyMissionType.correctInType,
    gameType: GameType.division,
    target: 10,
  ),
];

/// Date-seeded pick of three distinct mission shapes for [day]. Same day
/// always returns the same three. Day boundary is local-time midnight.
List<DailyMission> generateDailyMissions(DateTime day) {
  final seed = day.year * 10000 + day.month * 100 + day.day;
  final pool = [..._pool]..shuffle(Random(seed));
  final selected = <DailyMission>[];
  final usedKeys = <String>{};
  for (final m in pool) {
    if (usedKeys.contains(m.dedupeKey)) continue;
    usedKeys.add(m.dedupeKey);
    selected.add(m);
    if (selected.length == 3) break;
  }
  return selected;
}

/// Builds today's three missions and computes each one's progress from
/// [allRecords]. Only records finished on [now]'s local calendar day count —
/// missions reset at midnight. Practice runs aren't in `RecordService.all()`
/// so they're naturally excluded.
List<DailyMissionStatus> evaluateDailyMissions(
  List<GameRecord> allRecords, {
  DateTime? now,
}) {
  final today = now ?? DateTime.now();
  final missions = generateDailyMissions(today);
  final todaysRecords = allRecords.where((r) {
    return r.finishedAt.year == today.year &&
        r.finishedAt.month == today.month &&
        r.finishedAt.day == today.day;
  }).toList();
  return [
    for (final m in missions)
      DailyMissionStatus(
        mission: m,
        progress: _progressFor(m, todaysRecords),
      ),
  ];
}

int _progressFor(DailyMission m, List<GameRecord> todays) {
  switch (m.type) {
    case DailyMissionType.correctAnswers:
      return todays.fold<int>(0, (s, r) => s + r.correctCount);
    case DailyMissionType.perfectGames:
      return todays.where(_isPerfect).length;
    case DailyMissionType.achieveCombo:
      return todays.fold<int>(
        0,
        (m, r) => r.maxCombo > m ? r.maxCombo : m,
      );
    case DailyMissionType.correctInType:
      return todays
          .where((r) => r.type == m.gameType)
          .fold<int>(0, (s, r) => s + r.correctCount);
  }
}

bool _isPerfect(GameRecord r) =>
    r.totalCount > 0 && r.correctCount == r.totalCount;
