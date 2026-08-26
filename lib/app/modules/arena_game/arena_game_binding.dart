import 'package:get/get.dart';

import 'arena_game_controller.dart';

class ArenaGameBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(ArenaGameController.new);
  }
}
