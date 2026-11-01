import 'package:get/get.dart';
import 'billiards_select_controller.dart';

class BilliardsSelectBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(BilliardsSelectController.new);
}
