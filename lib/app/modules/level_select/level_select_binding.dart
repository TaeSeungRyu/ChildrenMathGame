import 'package:get/get.dart';

import 'level_select_controller.dart';

class LevelSelectBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(LevelSelectController.new);
  }
}
