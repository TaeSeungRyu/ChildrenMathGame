import 'package:get/get.dart';

import 'flash_select_controller.dart';

class FlashSelectBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(FlashSelectController.new);
  }
}
