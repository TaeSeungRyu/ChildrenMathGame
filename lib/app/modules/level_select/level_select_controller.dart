import 'package:get/get.dart';

import '../../data/models/game_type.dart';
import '../../routes/app_routes.dart';

class LevelSelectController extends GetxController {
  late final GameType type;

  // Default to challenge mode — the screen is primarily about picking a level
  // with the timer; "연습" is the opt-in for casual no-timer practice.
  final isPractice = false.obs;

  @override
  void onInit() {
    super.onInit();
    type = Get.arguments as GameType;
  }

  void setPractice(bool value) {
    isPractice.value = value;
  }

  void selectLevel(int level) {
    Get.toNamed(
      AppRoutes.game,
      arguments: {
        'type': type,
        'level': level,
        'isPractice': isPractice.value,
      },
    );
  }
}
