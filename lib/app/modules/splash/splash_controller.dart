import 'dart:async';

import 'package:get/get.dart';

import '../../data/services/profile_service.dart';
import '../../routes/app_routes.dart';

class SplashController extends GetxController {
  Timer? _timer;

  @override
  void onReady() {
    super.onReady();
    _timer = Timer(const Duration(seconds: 2), () {
      // First launch ever → auto-show the tutorial; afterwards skip straight
      // to home. The tutorial itself marks the flag on entry (onInit), so
      // force-quitting mid-tutorial still counts as "seen".
      final seen = Get.find<ProfileService>().tutorialSeen.value;
      if (seen) {
        Get.offNamed(AppRoutes.home);
      } else {
        Get.offNamed(
          AppRoutes.tutorial,
          arguments: const {'isFirstRun': true},
        );
      }
    });
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
