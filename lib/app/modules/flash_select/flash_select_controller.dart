import 'package:get/get.dart';

import '../../data/models/game_type.dart';
import '../../routes/app_routes.dart';

class FlashSelectController extends GetxController {
  static const choices = [
    GameType.addition,
    GameType.subtraction,
    GameType.multiplication,
    GameType.division,
  ];

  // Display windows in milliseconds — short = harder (less time to read).
  static const displayMsChoices = <int>[1500, 2000, 2500];

  final selectedType = GameType.addition.obs;
  final flashDisplayMs = 2000.obs;
  final isPractice = false.obs;

  void setType(GameType t) {
    selectedType.value = t;
  }

  void setFlashDisplayMs(int ms) {
    flashDisplayMs.value = ms;
  }

  void setPractice(bool value) {
    isPractice.value = value;
  }

  void startLevel(int level) {
    Get.toNamed(
      AppRoutes.game,
      arguments: {
        'type': selectedType.value,
        'level': level,
        'isPractice': isPractice.value,
        'isFlash': true,
        'flashDisplayMs': flashDisplayMs.value,
      },
    );
  }
}
