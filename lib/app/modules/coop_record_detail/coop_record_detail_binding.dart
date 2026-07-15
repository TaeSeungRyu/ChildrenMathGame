import 'package:get/get.dart';

import 'coop_record_detail_controller.dart';

class CoopRecordDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CoopRecordDetailController>(() => CoopRecordDetailController());
  }
}
