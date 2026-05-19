import 'package:get/get.dart';

import 'equation_select_controller.dart';

class EquationSelectBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(EquationSelectController.new);
  }
}
