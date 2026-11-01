import 'package:get/get.dart';

import '../../data/models/game_type.dart';
import '../../routes/app_routes.dart';

class BilliardsSelectController extends GetxController {
  final operation = GameType.addition.obs;
  final ballCount = 5.obs;

  void start() => Get.toNamed(
    AppRoutes.billiardsGame,
    arguments: {'operation': operation.value, 'ballCount': ballCount.value},
  );
}
