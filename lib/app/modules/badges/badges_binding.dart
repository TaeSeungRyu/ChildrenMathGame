import 'package:get/get.dart';

import 'badges_controller.dart';

class BadgesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(BadgesController.new);
  }
}
