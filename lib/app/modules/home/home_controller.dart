import 'package:get/get.dart';

import '../../data/models/game_type.dart';
import '../../data/services/record_service.dart';
import '../../routes/app_routes.dart';

class HomeController extends GetxController {
  final RecordService _records = Get.find<RecordService>();

  late final int streakDays = _records.currentStreak();

  void selectGame(GameType type) {
    Get.toNamed(AppRoutes.levelSelect, arguments: type);
  }

  void openRecords() {
    Get.toNamed(AppRoutes.records);
  }

  void openBadges() {
    Get.toNamed(AppRoutes.badges);
  }
}
