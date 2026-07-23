import 'package:get/get.dart';

import '../../data/models/profile.dart';
import '../../data/services/profile_service.dart';
import '../../routes/app_routes.dart';

/// First-launch onboarding: pick a name + avatar before the tutorial. The
/// tutorial then plays as usual and lands on the home screen. Multi-profile
/// infra already exists — this just fills the primary profile the very first
/// time the app is opened.
class OnboardingController extends GetxController {
  final ProfileService _profile = Get.find();

  static const int maxNameLength = ProfileService.maxNameLength;

  final RxString name = ''.obs;
  final RxString avatar = Profile.defaultAvatar.obs;

  bool get canSubmit => name.value.trim().isNotEmpty;

  void setAvatar(String emoji) => avatar.value = emoji;
  void setName(String value) => name.value = value;

  Future<void> submit() async {
    if (!canSubmit) return;
    await _profile.setName(name.value);
    await _profile.setAvatar(avatar.value);
    await _profile.markOnboardingSeen();
    // Continue into the tutorial exactly like the very-first-launch path used
    // to; when it finishes, tutorial routes to home itself.
    Get.offNamed(
      AppRoutes.tutorial,
      arguments: const {'isFirstRun': true},
    );
  }

  /// Skip without setting anything — keeps the default '어린이' profile but
  /// marks the flag so we don't ask again.
  Future<void> skip() async {
    await _profile.markOnboardingSeen();
    Get.offNamed(
      AppRoutes.tutorial,
      arguments: const {'isFirstRun': true},
    );
  }
}
