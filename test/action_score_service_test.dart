import 'package:children_math_game/app/data/models/action_concept.dart';
import 'package:children_math_game/app/data/services/action_score_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await Get.deleteAll(force: true);
  });

  test('fresh install reports zero best/plays', () async {
    final svc = await ActionScoreService().init();
    expect(svc.bestFor(ActionConcept.mole), 0);
    expect(svc.playsFor(ActionConcept.mole), 0);
  });

  test('report increments plays and tracks the best score', () async {
    final svc = await ActionScoreService().init();
    expect(await svc.report(ActionConcept.mole, 5), isTrue); // first record
    expect(await svc.report(ActionConcept.mole, 3), isFalse); // lower
    expect(await svc.report(ActionConcept.mole, 9), isTrue); // new best
    expect(svc.bestFor(ActionConcept.mole), 9);
    expect(svc.playsFor(ActionConcept.mole), 3);
  });

  test('a zero score is not treated as a new record', () async {
    final svc = await ActionScoreService().init();
    expect(await svc.report(ActionConcept.fishing, 0), isFalse);
    expect(svc.playsFor(ActionConcept.fishing), 1);
    expect(svc.bestFor(ActionConcept.fishing), 0);
  });

  test('scores are per-concept and persist across re-init', () async {
    final svc = await ActionScoreService().init();
    await svc.report(ActionConcept.mole, 7);
    await svc.report(ActionConcept.balloon, 4);

    final reloaded = await ActionScoreService().init();
    expect(reloaded.bestFor(ActionConcept.mole), 7);
    expect(reloaded.bestFor(ActionConcept.balloon), 4);
    expect(reloaded.bestFor(ActionConcept.tower), 0);
  });
}
