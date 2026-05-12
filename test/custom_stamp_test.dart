import 'package:children_math_game/app/data/models/custom_stamp.dart';
import 'package:children_math_game/app/data/services/custom_stamp_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('CustomStamp model', () {
    test('roundtrips through JSON', () {
      final stamp = CustomStamp(
        id: 's_1',
        title: '책 읽기',
        emoji: '📖',
        colorValue: 0xFF1E88E5,
        earned: true,
        createdAt: DateTime(2026, 5, 12, 10),
      );
      final json = stamp.toJson();
      final back = CustomStamp.fromJson(json);
      expect(back.id, stamp.id);
      expect(back.title, stamp.title);
      expect(back.emoji, stamp.emoji);
      expect(back.colorValue, stamp.colorValue);
      expect(back.earned, stamp.earned);
      expect(back.createdAt, stamp.createdAt);
    });

    test('copyWith only touches the named fields', () {
      final r = CustomStamp(
        id: 's_1',
        title: '책 읽기',
        emoji: '📖',
        colorValue: 0xFF1E88E5,
        earned: false,
        createdAt: DateTime(2026, 5, 12),
      );
      final updated = r.copyWith(earned: true);
      expect(updated.earned, isTrue);
      expect(updated.title, r.title);
      expect(updated.id, r.id);
      expect(updated.createdAt, r.createdAt);
    });
  });

  group('CustomStampService', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() async {
      await Get.deleteAll(force: true);
    });

    test('starts empty on fresh install', () async {
      final svc = await CustomStampService().init();
      expect(svc.stamps, isEmpty);
    });

    test('add appends a stamp and persists', () async {
      final svc = await CustomStampService().init();
      await svc.add(
        title: '책 읽기',
        emoji: '📖',
        colorValue: 0xFF1E88E5,
      );
      expect(svc.stamps.length, 1);
      expect(svc.stamps.first.title, '책 읽기');
      expect(svc.stamps.first.earned, isFalse);

      // Re-init reads from SharedPreferences.
      final svc2 = await CustomStampService().init();
      expect(svc2.stamps.length, 1);
      expect(svc2.stamps.first.emoji, '📖');
    });

    test('toggleEarned flips the bool', () async {
      final svc = await CustomStampService().init();
      await svc.add(title: 'A', emoji: '⭐', colorValue: 0);
      final id = svc.stamps.first.id;
      expect(svc.stamps.first.earned, isFalse);

      await svc.toggleEarned(id);
      expect(svc.stamps.first.earned, isTrue);

      await svc.toggleEarned(id);
      expect(svc.stamps.first.earned, isFalse);
    });

    test('update replaces by id, preserves others', () async {
      final svc = await CustomStampService().init();
      await svc.add(title: 'A', emoji: '⭐', colorValue: 0);
      await svc.add(title: 'B', emoji: '🎉', colorValue: 1);
      final b = svc.stamps.last;
      await svc.update(b.copyWith(title: 'B!'));
      expect(svc.stamps[0].title, 'A');
      expect(svc.stamps[1].title, 'B!');
      expect(svc.stamps[1].id, b.id);
    });

    test('delete removes by id', () async {
      final svc = await CustomStampService().init();
      await svc.add(title: 'A', emoji: '⭐', colorValue: 0);
      await svc.add(title: 'B', emoji: '🎉', colorValue: 1);
      final firstId = svc.stamps.first.id;
      await svc.delete(firstId);
      expect(svc.stamps.length, 1);
      expect(svc.stamps.first.title, 'B');
    });

    test('add trims whitespace in title', () async {
      final svc = await CustomStampService().init();
      await svc.add(title: '  하늘  ', emoji: '⭐', colorValue: 0);
      expect(svc.stamps.first.title, '하늘');
    });

    test('ids are unique across adds', () async {
      final svc = await CustomStampService().init();
      for (var i = 0; i < 5; i++) {
        await svc.add(title: 'S$i', emoji: '⭐', colorValue: 0);
      }
      final ids = svc.stamps.map((s) => s.id).toSet();
      expect(ids.length, 5);
    });
  });
}
