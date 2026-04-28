import 'package:get/get.dart';

import '../../data/models/game_type.dart';
import '../../routes/app_routes.dart';

class LevelSelectController extends GetxController {
  late final GameType type;

  @override
  void onInit() {
    super.onInit();
    type = Get.arguments as GameType;
  }

  void selectLevel(int level) {
    Get.toNamed(
      AppRoutes.game,
      arguments: {'type': type, 'level': level},
    );
  }
}
