import 'package:get/get.dart';

import 'fishing_game_controller.dart';

class FishingGameBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(FishingGameController.new);
  }
}
