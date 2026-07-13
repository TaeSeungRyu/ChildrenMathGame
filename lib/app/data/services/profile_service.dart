import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/profile.dart';

/// Multi-profile store. Siblings can each have their own profile (name +
/// avatar); records, stamps, action scores and stats are scoped per profile
/// via [scopeSuffix].
///
/// Backward compatibility: a fresh install with the old single-name key
/// (`profile_name_v1`) is migrated into one primary profile (id ==
/// [Profile.primaryId]) whose data keeps the original un-suffixed keys, so no
/// bulk data migration is needed. [name] mirrors the active profile's name so
/// existing UI (splash/home/result greeting) that reads it reactively keeps
/// working unchanged.
class ProfileService extends GetxService {
  static const _legacyNameKey = 'profile_name_v1';
  static const _profilesKey = 'profiles_v1';
  static const _activeIdKey = 'active_profile_v1';
  static const _tutorialSeenKey = 'tutorial_seen_v1';

  static const defaultName = '어린이';
  static const maxNameLength = 3;
  // Hard cap on sibling profiles — plenty for one family, keeps the switcher
  // UI simple.
  static const maxProfiles = 6;

  late final SharedPreferences _prefs;

  final RxList<Profile> profiles = <Profile>[].obs;
  final RxInt activeId = Profile.primaryId.obs;

  /// Active profile's display name — kept as its own Rx so the many existing
  /// `Obx(() => ...name.value...)` call sites need no change.
  final name = defaultName.obs;
  final avatar = Profile.defaultAvatar.obs;
  final tutorialSeen = false.obs;

  Future<ProfileService> init() async {
    _prefs = await SharedPreferences.getInstance();
    tutorialSeen.value = _prefs.getBool(_tutorialSeenKey) ?? false;
    _loadProfiles();
    return this;
  }

  void _loadProfiles() {
    final raw = _prefs.getString(_profilesKey);
    if (raw != null && raw.isNotEmpty) {
      final list = jsonDecode(raw) as List<dynamic>;
      profiles.assignAll(
        list.map((e) => Profile.fromJson(e as Map<String, dynamic>)),
      );
    }
    if (profiles.isEmpty) {
      // Migrate legacy single profile (or seed the default one).
      final legacyName = _prefs.getString(_legacyNameKey) ?? defaultName;
      profiles.add(
        Profile(
          id: Profile.primaryId,
          name: legacyName,
          avatar: Profile.defaultAvatar,
        ),
      );
      _persistProfiles();
    }
    final storedActive = _prefs.getInt(_activeIdKey);
    activeId.value = profiles.any((p) => p.id == storedActive)
        ? storedActive!
        : profiles.first.id;
    _syncActiveMirror();
  }

  Profile get active =>
      profiles.firstWhere((p) => p.id == activeId.value, orElse: () => profiles.first);

  /// Key suffix for the active profile's scoped data. `''` for the primary
  /// profile (legacy keys), `_p<id>` otherwise.
  String get scopeSuffix => active.scopeSuffix;

  bool get canAddProfile => profiles.length < maxProfiles;

  void _syncActiveMirror() {
    final a = active;
    name.value = a.name;
    avatar.value = a.avatar;
  }

  Future<void> _persistProfiles() async {
    await _prefs.setString(
      _profilesKey,
      jsonEncode(profiles.map((p) => p.toJson()).toList()),
    );
  }

  Future<void> markTutorialSeen() async {
    if (tutorialSeen.value) return;
    tutorialSeen.value = true;
    await _prefs.setBool(_tutorialSeenKey, true);
  }

  String _clampName(String value) {
    var trimmed = value.trim();
    if (trimmed.length > maxNameLength) {
      trimmed = trimmed.substring(0, maxNameLength);
    }
    return trimmed;
  }

  /// Renames the active profile. Whitespace-only input is rejected (no-op).
  Future<void> setName(String value) async {
    final trimmed = _clampName(value);
    if (trimmed.isEmpty) return;
    _updateActive((p) => p.copyWith(name: trimmed));
  }

  Future<void> setAvatar(String emoji) async {
    _updateActive((p) => p.copyWith(avatar: emoji));
  }

  void _updateActive(Profile Function(Profile) transform) {
    final i = profiles.indexWhere((p) => p.id == activeId.value);
    if (i < 0) return;
    profiles[i] = transform(profiles[i]);
    _syncActiveMirror();
    _persistProfiles();
  }

  /// Creates a new profile and switches to it. No-op past [maxProfiles].
  Future<Profile?> addProfile({required String name, String? avatar}) async {
    if (!canAddProfile) return null;
    final trimmed = _clampName(name);
    final nextId =
        profiles.map((p) => p.id).fold(0, (m, id) => id > m ? id : m) + 1;
    final profile = Profile(
      id: nextId,
      name: trimmed.isEmpty ? defaultName : trimmed,
      avatar: avatar ?? Profile.defaultAvatar,
    );
    profiles.add(profile);
    await _persistProfiles();
    await switchTo(profile.id);
    return profile;
  }

  /// The primary profile is protected (its data uses the legacy keys) and the
  /// last remaining profile can't be removed.
  bool canDelete(int id) => id != Profile.primaryId && profiles.length > 1;

  Future<void> deleteProfile(int id) async {
    if (!canDelete(id)) return;
    profiles.removeWhere((p) => p.id == id);
    await _persistProfiles();
    if (activeId.value == id) {
      await switchTo(profiles.first.id);
    }
  }

  /// Switches the active profile and reloads the caches of scoped services so
  /// the whole app reflects the new child immediately. Navigation is left to
  /// the caller.
  Future<void> switchTo(int id) async {
    if (!profiles.any((p) => p.id == id)) return;
    activeId.value = id;
    await _prefs.setInt(_activeIdKey, id);
    _syncActiveMirror();
  }
}
