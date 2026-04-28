import 'package:get/get.dart';

import '../../data/models/game_type.dart';
import '../../routes/app_routes.dart';

class HomeController extends GetxController {
  void selectGame(GameType type) {
    Get.toNamed(AppRoutes.levelSelect, arguments: type);
  }

  void openRecords() {
    Get.toNamed(AppRoutes.records);
  }
}
