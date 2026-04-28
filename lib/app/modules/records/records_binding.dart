import 'package:get/get.dart';

import 'records_controller.dart';

class RecordsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(RecordsController.new);
  }
}
