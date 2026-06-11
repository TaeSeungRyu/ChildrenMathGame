import 'package:get/get.dart';

import '../../data/models/daily_mission.dart';
import '../../data/models/game_type.dart';
import '../../data/services/record_service.dart';
import '../../routes/app_routes.dart';
import '../../shared/daily_missions.dart';
import '../../shared/weakness.dart';

class HomeController extends GetxController {
  final RecordService _records = Get.find<RecordService>();

  // Current bottom-tab index. 0 = 학습, 1 = 게임, 2 = 기록.
  // Survives within the lifetime of the Home controller; reset to 0 on cold
  // start since the binding lazy-instantiates fresh.
  final RxInt tabIndex = 0.obs;

  late final int streakDays = _records.currentStreak();
  late final WeaknessAnalysis weakness = analyzeWeakness(_records.all());
  late final List<DailyMissionStatus> missions = evaluateDailyMissions(
    _records.all(),
  );

  WeaknessBucket? get recommendation => weakness.recommendation;
  int get missionsCompleted => missions.where((m) => m.isComplete).length;

  void setTab(int i) => tabIndex.value = i;

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

  void openMixed() {
    Get.toNamed(AppRoutes.mixedSelect);
  }

  void openEquation() {
    Get.toNamed(AppRoutes.equationSelect);
  }

  void openFlash() {
    Get.toNamed(AppRoutes.flashSelect);
  }

  void openWrongNotebook() {
    Get.toNamed(AppRoutes.wrongNotebook);
  }

  void openStats() {
    Get.toNamed(AppRoutes.stats);
  }

  void openReview() {
    Get.toNamed(AppRoutes.review);
  }

  void openMonsterGame() {
    Get.toNamed(AppRoutes.monsterGame);
  }

  void openBalloonGame() {
    Get.toNamed(AppRoutes.balloonGame);
  }

  void openTowerDefense() {
    Get.toNamed(AppRoutes.towerDefense);
  }

  void openMoleGame() {
    Get.toNamed(AppRoutes.moleGame);
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
