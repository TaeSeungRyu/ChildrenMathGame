import 'package:children_math_game/app/data/services/sfx_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SfxService.audioBackendEnabled = false;
  });

  Future<SfxService> makeService() => SfxService().init();

  test('defaults: BGM + SFX both on with sane volumes', () async {
    SharedPreferences.setMockInitialValues({});
    final sfx = await makeService();
    expect(sfx.sfxEnabled.value, isTrue);
    expect(sfx.bgmEnabled.value, isTrue);
    expect(sfx.sfxVolume.value, 0.8);
    expect(sfx.bgmVolume.value, 0.5);
  });

  test('legacy mute=true migrates to SFX disabled', () async {
    SharedPreferences.setMockInitialValues({'sfx_muted_v1': true});
    final sfx = await makeService();
    expect(sfx.sfxEnabled.value, isFalse);
    // BGM is a new channel and defaults on regardless of legacy mute.
    expect(sfx.bgmEnabled.value, isTrue);
  });

  test('legacy mute=false migrates to SFX enabled', () async {
    SharedPreferences.setMockInitialValues({'sfx_muted_v1': false});
    final sfx = await makeService();
    expect(sfx.sfxEnabled.value, isTrue);
  });

  test('new keys take precedence over legacy mute', () async {
    SharedPreferences.setMockInitialValues({
      'sfx_muted_v1': true,
      'sfx_enabled_v1': true,
    });
    final sfx = await makeService();
    expect(sfx.sfxEnabled.value, isTrue);
  });

  test('setters persist and volume clamps to 0..1', () async {
    SharedPreferences.setMockInitialValues({});
    final sfx = await makeService();

    await sfx.setBgmEnabled(false);
    await sfx.setSfxVolume(1.5);
    await sfx.setBgmVolume(-0.2);

    expect(sfx.sfxVolume.value, 1.0);
    expect(sfx.bgmVolume.value, 0.0);

    // Reload from the same backing store to confirm persistence.
    final reloaded = await makeService();
    expect(reloaded.bgmEnabled.value, isFalse);
    expect(reloaded.sfxVolume.value, 1.0);
    expect(reloaded.bgmVolume.value, 0.0);
  });
}
