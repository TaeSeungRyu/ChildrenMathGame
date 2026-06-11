import 'package:get/get.dart';

import 'mole_game_controller.dart';

class MoleGameBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(MoleGameController.new);
  }
}
