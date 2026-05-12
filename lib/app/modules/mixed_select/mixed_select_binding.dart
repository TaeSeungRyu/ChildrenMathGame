import 'package:get/get.dart';

import 'mixed_select_controller.dart';

class MixedSelectBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(MixedSelectController.new);
  }
}
