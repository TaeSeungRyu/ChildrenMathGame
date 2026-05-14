import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tiny single-profile store — the user's display name. UI (splash/home/
/// result greeting) reads [name] reactively via Obx so the change is
/// reflected immediately after the user edits it.
class ProfileService extends GetxService {
  static const _nameKey = 'profile_name_v1';
  static const _tutorialSeenKey = 'tutorial_seen_v1';
  static const defaultName = '어린이';
  // Max characters allowed for a name — UI also enforces via maxLength but
  // we trim and clamp here to stay defensive against any other entry path.
  static const maxNameLength = 10;

  late final SharedPreferences _prefs;
  final name = defaultName.obs;
  // True once the user has opened the tutorial at least once. Splash uses
  // this to decide whether to auto-show the tutorial before the home screen.
  final tutorialSeen = false.obs;

  Future<ProfileService> init() async {
    _prefs = await SharedPreferences.getInstance();
    name.value = _prefs.getString(_nameKey) ?? defaultName;
    tutorialSeen.value = _prefs.getBool(_tutorialSeenKey) ?? false;
    return this;
  }

  Future<void> markTutorialSeen() async {
    if (tutorialSeen.value) return;
    tutorialSeen.value = true;
    await _prefs.setBool(_tutorialSeenKey, true);
  }

  /// Persists [value] as the new display name. Whitespace-only or empty
  /// inputs are rejected (no-op). Values longer than [maxNameLength] are
  /// clamped — UI normally prevents this via the TextField's maxLength.
  Future<void> setName(String value) async {
    var trimmed = value.trim();
    if (trimmed.isEmpty) return;
    if (trimmed.length > maxNameLength) {
      trimmed = trimmed.substring(0, maxNameLength);
    }
    name.value = trimmed;
    await _prefs.setString(_nameKey, trimmed);
  }
}
