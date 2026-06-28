import 'package:get/get.dart';

import 'ladder_game_controller.dart';

class LadderGameBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(LadderGameController.new);
  }
}
