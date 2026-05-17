import 'package:get/get.dart';

import 'wrong_notebook_controller.dart';

class WrongNotebookBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(WrongNotebookController.new);
  }
}
