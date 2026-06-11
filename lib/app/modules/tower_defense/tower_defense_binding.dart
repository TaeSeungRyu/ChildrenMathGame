import 'package:get/get.dart';

import 'tower_defense_controller.dart';

class TowerDefenseBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(TowerDefenseController.new);
  }
}
