import 'package:get/get.dart';

import 'balloon_game_controller.dart';

class BalloonGameBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(BalloonGameController.new);
  }
}
