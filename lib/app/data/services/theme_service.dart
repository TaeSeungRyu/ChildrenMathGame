import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the app's [ThemeMode] choice (system / light / dark). The value is
/// reactive so the `GetMaterialApp` can rebuild instantly on toggle.
class ThemeService extends GetxService {
  static const _key = 'theme_mode_v1';

  late final SharedPreferences _prefs;
  final Rx<ThemeMode> mode = ThemeMode.system.obs;

  Future<ThemeService> init() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs.getString(_key);
    mode.value = _parse(raw);
    return this;
  }

  Future<void> setMode(ThemeMode m) async {
    mode.value = m;
    await _prefs.setString(_key, m.name);
    Get.changeThemeMode(m);
  }

  ThemeMode _parse(String? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}
