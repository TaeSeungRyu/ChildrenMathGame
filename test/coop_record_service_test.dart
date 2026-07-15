import 'package:children_math_game/app/data/models/coop_session_record.dart';
import 'package:children_math_game/app/data/models/game_type.dart';
import 'package:children_math_game/app/data/services/coop_record_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

CoopSessionRecord _rec(DateTime when, {int correct = 8, int wrong = 2}) =>
    CoopSessionRecord(
      finishedAt: when,
      partnerName: '엄마',
      partnerAvatar: '👩',
      gameType: GameType.addition,
      level: 2,
      correct: correct,
      wrong: wrong,
      elapsedSeconds: 90,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() async => Get.deleteAll(force: true));

  test('fresh install has no records', () async {
    final svc = await CoopRecordService().init();
    expect(svc.records, isEmpty);
  });

  test('add inserts newest-first and persists', () async {
    final svc = await CoopRecordService().init();
    await svc.add(_rec(DateTime(2026, 7, 1)));
    await svc.add(_rec(DateTime(2026, 7, 2)));
    expect(svc.records.length, 2);
    expect(svc.records.first.finishedAt, DateTime(2026, 7, 2)); // newest first

    final reloaded = await CoopRecordService().init();
    expect(reloaded.records.length, 2);
    expect(reloaded.records.first.finishedAt, DateTime(2026, 7, 2));
  });

  test('record fields round-trip through storage', () async {
    final svc = await CoopRecordService().init();
    await svc.add(_rec(DateTime(2026, 7, 3), correct: 5, wrong: 1));
    final r = (await CoopRecordService().init()).records.first;
    expect(r.partnerName, '엄마');
    expect(r.gameType, GameType.addition);
    expect(r.level, 2);
    expect(r.correct, 5);
    expect(r.wrong, 1);
    expect(r.total, 6);
    expect(r.accuracy, closeTo(5 / 6, 1e-9));
  });

  test('delete removes by finishedAt', () async {
    final svc = await CoopRecordService().init();
    final a = _rec(DateTime(2026, 7, 4));
    await svc.add(a);
    await svc.add(_rec(DateTime(2026, 7, 5)));
    await svc.delete(a);
    expect(svc.records.length, 1);
    expect(svc.records.any((r) => r.finishedAt == a.finishedAt), isFalse);
  });
}
