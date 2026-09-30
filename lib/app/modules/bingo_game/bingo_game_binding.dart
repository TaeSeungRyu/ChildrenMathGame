import 'package:get/get.dart';

import 'bingo_game_controller.dart';

class BingoGameBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(BingoGameController.new);
  }
}
