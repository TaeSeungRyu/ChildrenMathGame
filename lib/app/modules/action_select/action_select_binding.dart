import 'package:get/get.dart';

import 'action_select_controller.dart';

class ActionSelectBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(ActionSelectController.new);
  }
}
