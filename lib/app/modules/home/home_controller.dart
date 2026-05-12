import 'package:get/get.dart';

import '../../data/models/daily_mission.dart';
import '../../data/models/game_type.dart';
import '../../data/services/record_service.dart';
import '../../routes/app_routes.dart';
import '../../shared/daily_missions.dart';
import '../../shared/weakness.dart';

class HomeController extends GetxController {
  final RecordService _records = Get.find<RecordService>();

  late final int streakDays = _records.currentStreak();
  late final WeaknessAnalysis weakness = analyzeWeakness(_records.all());
  late final List<DailyMissionStatus> missions = evaluateDailyMissions(
    _records.all(),
  );

  WeaknessBucket? get recommendation => weakness.recommendation;
  int get missionsCompleted => missions.where((m) => m.isComplete).length;

  void selectGame(GameType type) {
    Get.toNamed(AppRoutes.levelSelect, arguments: type);
  }

  void openRecords() {
    Get.toNamed(AppRoutes.records);
  }

  void openBadges() {
    Get.toNamed(AppRoutes.badges);
  }

  void openTimesTable() {
    Get.toNamed(AppRoutes.timesTableSelect);
  }

  void startRecommended(WeaknessBucket bucket) {
    Get.toNamed(
      AppRoutes.game,
      arguments: {
        'type': bucket.type,
        'level': bucket.level,
        'isPractice': true,
      },
    );
  }
}
