import 'package:get/get.dart';

import 'coop_coach_controller.dart';

class CoopCoachBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CoopCoachController>(() => CoopCoachController());
  }
}
