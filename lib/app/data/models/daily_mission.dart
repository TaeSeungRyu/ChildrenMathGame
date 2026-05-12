import 'game_type.dart';

enum DailyMissionType {
  // Total correct answers across all of today's challenge runs.
  correctAnswers,
  // Number of perfect games (correct == total) today.
  perfectGames,
  // Max single-game combo achieved today.
  achieveCombo,
  // Correct answers within a specific operation type today.
  correctInType,
}

class DailyMission {
  const DailyMission({
    required this.type,
    required this.target,
    this.gameType,
  });

  final DailyMissionType type;
  final int target;
  // Only used when [type] is [DailyMissionType.correctInType].
  final GameType? gameType;

  // Stable key used for dedupe — two missions of the same shape (same type
  // and same gameType, regardless of target) shouldn't both appear today.
  String get dedupeKey => '${type.name}|${gameType?.name ?? ''}';

  String get description {
    switch (type) {
      case DailyMissionType.correctAnswers:
        return '오늘 정답 $target개 맞히기';
      case DailyMissionType.perfectGames:
        return '오늘 만점 $target회 달성';
      case DailyMissionType.achieveCombo:
        return '$target 이상 콤보 기록';
      case DailyMissionType.correctInType:
        return '${gameType!.label} $target개 정답';
    }
  }
}

class DailyMissionStatus {
  const DailyMissionStatus({
    required this.mission,
    required this.progress,
  });

  final DailyMission mission;
  final int progress;

  bool get isComplete => progress >= mission.target;
  // Clamped value useful for progress bars / X/Y displays.
  int get progressClamped =>
      progress > mission.target ? mission.target : progress;
}
