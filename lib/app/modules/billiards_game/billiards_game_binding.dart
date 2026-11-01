import 'package:get/get.dart';
import 'billiards_game_controller.dart';

class BilliardsGameBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(BilliardsGameController.new);
}
