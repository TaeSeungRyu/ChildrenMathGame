import 'package:get/get.dart';

import 'times_table_select_controller.dart';

class TimesTableSelectBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(TimesTableSelectController.new);
  }
}
