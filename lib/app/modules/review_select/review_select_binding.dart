import 'package:get/get.dart';

import 'review_select_controller.dart';

class ReviewSelectBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(ReviewSelectController.new);
  }
}
