import 'package:get/get.dart';

import 'record_detail_controller.dart';

class RecordDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(RecordDetailController.new);
  }
}
