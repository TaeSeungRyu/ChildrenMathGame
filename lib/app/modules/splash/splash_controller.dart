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
      // First launch → onboarding (name + avatar) → tutorial → home.
      // Returning users skip straight to home once both flags are set. The
      // tutorial marks its own flag on entry, so mid-tutorial force-quits still
      // count as "seen" and won't re-trigger the onboarding.
      final profile = Get.find<ProfileService>();
      if (!profile.onboardingSeen.value) {
        Get.offNamed(AppRoutes.onboarding);
      } else if (!profile.tutorialSeen.value) {
        Get.offNamed(
          AppRoutes.tutorial,
          arguments: const {'isFirstRun': true},
        );
      } else {
        Get.offNamed(AppRoutes.home);
      }
    });
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
