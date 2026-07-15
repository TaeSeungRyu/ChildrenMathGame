import 'package:get/get.dart';

import 'coop_records_controller.dart';

class CoopRecordsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CoopRecordsController>(() => CoopRecordsController());
  }
}
