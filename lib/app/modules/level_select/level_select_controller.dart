import 'package:get/get.dart';

import '../../data/models/game_type.dart';
import '../../routes/app_routes.dart';

/// Four-way mode toggle on the level-select screen. Challenge is the default
/// canonical run; timeAttack swaps the 10-problem cap for a 60s race; endless
/// removes both the timer and the problem cap (session ends on first wrong);
/// practice removes the timer entirely and skips record persistence.
enum LevelSelectMode { challenge, timeAttack, endless, practice }

class LevelSelectController extends GetxController {
  late final GameType type;

  // Default to challenge mode — the screen is primarily about picking a level
  // with the timer; timeAttack/practice are explicit opt-ins.
  final mode = LevelSelectMode.challenge.obs;

  @override
  void onInit() {
    super.onInit();
    type = Get.arguments as GameType;
  }

  void setMode(LevelSelectMode value) {
    mode.value = value;
  }

  void selectLevel(int level) {
    Get.toNamed(
      AppRoutes.game,
      arguments: {
        'type': type,
        'level': level,
        'isPractice': mode.value == LevelSelectMode.practice,
        'isTimeAttack': mode.value == LevelSelectMode.timeAttack,
        'isEndless': mode.value == LevelSelectMode.endless,
      },
    );
  }
}
