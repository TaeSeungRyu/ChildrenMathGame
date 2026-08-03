import 'package:get/get.dart';

import 'sign_guess_controller.dart';

class SignGuessBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SignGuessController>(() => SignGuessController());
  }
}
