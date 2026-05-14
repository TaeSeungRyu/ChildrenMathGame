import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../data/services/profile_service.dart';
import '../../routes/app_routes.dart';

class TutorialController extends GetxController {
  final pageController = PageController();
  final currentIndex = 0.obs;
  // True when the splash auto-navigated here on first launch. In that mode
  // we hide the back arrow + intercept the Android back button, so the only
  // exit is the "시작하기" button.
  late final bool isFirstRun;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    isFirstRun = args is Map && args['isFirstRun'] == true;
    if (isFirstRun) {
      // Mark seen as soon as the tutorial mounts so a force-quit mid-walk
      // still counts — matches "한번이라도 실행이 되고 나면 두번다시 안 뜨게".
      Get.find<ProfileService>().markTutorialSeen();
    }
  }

  void finish() {
    if (isFirstRun) {
      Get.offAllNamed(AppRoutes.home);
    } else {
      Get.back();
    }
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
