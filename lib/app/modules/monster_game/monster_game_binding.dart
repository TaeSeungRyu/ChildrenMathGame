import 'package:get/get.dart';

import 'monster_game_controller.dart';

class MonsterGameBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(MonsterGameController.new);
  }
}
