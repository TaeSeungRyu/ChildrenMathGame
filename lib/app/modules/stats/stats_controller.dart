import 'package:get/get.dart';

import '../../data/models/game_record.dart';
import '../../data/models/game_type.dart';
import '../../data/services/record_service.dart';
import '../../shared/weakness.dart';

class StatsAggregate {
  StatsAggregate({
    required this.gamesPlayed,
    required this.correctCount,
    required this.totalProblems,
    required this.totalSeconds,
  });

  final int gamesPlayed;
  final int correctCount;
  final int totalProblems;
  final int totalSeconds;

  double get accuracy =>
      totalProblems == 0 ? 0 : correctCount / totalProblems;

  int get averageSeconds =>
      gamesPlayed == 0 ? 0 : (totalSeconds / gamesPlayed).round();
}

class StatsController extends GetxController {
  static const levels = [1, 2, 3, 4, 5];

  late final StatsAggregate overall;
  late final Map<GameType, StatsAggregate> byType;
  late final Map<int, StatsAggregate> byLevel;
  late final WeaknessAnalysis weakness;

  @override
  void onInit() {
    super.onInit();
    final all = Get.find<RecordService>().all();
    overall = _aggregate(all);
    byType = {
      for (final t in GameType.values)
        t: _aggregate(all.where((r) => r.type == t)),
    };
    byLevel = {
      for (final l in levels)
        l: _aggregate(all.where((r) => r.level == l)),
    };
    weakness = analyzeWeakness(all);
  }

  StatsAggregate _aggregate(Iterable<GameRecord> records) {
    var games = 0;
    var correct = 0;
    var total = 0;
    var seconds = 0;
    for (final r in records) {
      games++;
      correct += r.correctCount;
      total += r.totalCount;
      seconds += r.elapsedSeconds;
    }
    return StatsAggregate(
      gamesPlayed: games,
      correctCount: correct,
      totalProblems: total,
      totalSeconds: seconds,
    );
  }
}
