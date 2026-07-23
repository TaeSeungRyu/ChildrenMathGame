import 'package:children_math_game/app/data/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() async => Get.deleteAll(force: true));

  test('defaults to ThemeMode.system on fresh install', () async {
    final svc = await ThemeService().init();
    expect(svc.mode.value, ThemeMode.system);
  });

  test('setMode persists and reloads', () async {
    final svc = await ThemeService().init();
    await svc.setMode(ThemeMode.dark);
    expect(svc.mode.value, ThemeMode.dark);

    final reloaded = await ThemeService().init();
    expect(reloaded.mode.value, ThemeMode.dark);
  });

  test('unknown stored value falls back to system', () async {
    SharedPreferences.setMockInitialValues({'theme_mode_v1': 'sepia'});
    final svc = await ThemeService().init();
    expect(svc.mode.value, ThemeMode.system);
  });
}
