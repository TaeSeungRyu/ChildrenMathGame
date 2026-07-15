import 'package:get/get.dart';

import 'coop_learn_controller.dart';

class CoopLearnBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CoopLearnController>(() => CoopLearnController());
  }
}
