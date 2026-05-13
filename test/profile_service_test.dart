import 'package:children_math_game/app/data/services/profile_service.dart';
import 'package:children_math_game/app/shared/korean_particle.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ProfileService', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() async {
      await Get.deleteAll(force: true);
    });

    test('defaults to "어린이" on fresh install', () async {
      final svc = await ProfileService().init();
      expect(svc.name.value, ProfileService.defaultName);
      expect(ProfileService.defaultName, '어린이');
    });

    test('setName persists across re-init', () async {
      final svc = await ProfileService().init();
      await svc.setName('민준');
      // Re-init reads from SharedPreferences.
      final svc2 = await ProfileService().init();
      expect(svc2.name.value, '민준');
    });

    test('setName trims whitespace', () async {
      final svc = await ProfileService().init();
      await svc.setName('  하늘  ');
      expect(svc.name.value, '하늘');
    });

    test('setName rejects empty / whitespace-only input', () async {
      final svc = await ProfileService().init();
      await svc.setName('어린이');
      await svc.setName('   ');
      // Unchanged from prior valid set.
      expect(svc.name.value, '어린이');
      await svc.setName('');
      expect(svc.name.value, '어린이');
    });

    test('setName clamps to maxNameLength', () async {
      final svc = await ProfileService().init();
      final long = 'A' * (ProfileService.maxNameLength + 5);
      await svc.setName(long);
      expect(svc.name.value.length, ProfileService.maxNameLength);
    });
  });

  group('vocativeParticle', () {
    test('returns "야" for names ending in vowel (no jongseong)', () {
      // 수, 아, 미 — all vowel-ending syllables.
      expect(vocativeParticle('어린이'), '야');
      expect(vocativeParticle('지아'), '야');
      expect(vocativeParticle('미'), '야');
    });

    test('returns "아" for names ending in consonant (has jongseong)', () {
      // 준, 호 — wait, 호 is vowel. Let me use clear cases.
      // 민준 ends in 준 (jongseong ㄴ), 강희 ends in 희 (no jongseong).
      expect(vocativeParticle('민준'), '아');
      expect(vocativeParticle('태풍'), '아');
      expect(vocativeParticle('강희'), '야');
    });

    test('returns empty for non-Hangul names', () {
      expect(vocativeParticle('Alex'), '');
      expect(vocativeParticle(''), '');
      expect(vocativeParticle('123'), '');
    });

    test('addressedName attaches the right particle', () {
      expect(addressedName('어린이'), '어린이야');
      expect(addressedName('민준'), '민준아');
      expect(addressedName('Alex'), 'Alex');
    });
  });
}
