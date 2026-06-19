import 'package:get/get.dart';

import 'estimation_select_controller.dart';

class EstimationSelectBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(EstimationSelectController.new);
  }
}
