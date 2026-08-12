import 'package:get/get.dart';

import 'balance_game_controller.dart';

class BalanceGameBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(BalanceGameController.new);
  }
}
