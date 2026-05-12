import 'package:children_math_game/app/data/models/game_type.dart';
import 'package:children_math_game/app/data/services/record_service.dart';
import 'package:children_math_game/app/data/services/sfx_service.dart';
import 'package:children_math_game/app/modules/game/game_binding.dart';
import 'package:children_math_game/app/modules/game/game_controller.dart';
import 'package:children_math_game/app/modules/game/game_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<GameController> _bootGameController(
  WidgetTester tester, {
  required bool isPractice,
}) async {
  // Default test surface (800x600) is shorter than a real phone — GameView's
  // keypad column overflows. Bump to a phone-shaped viewport so layout fits.
  await tester.binding.setSurfaceSize(const Size(400, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    GetMaterialApp(
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Get.to<void>(
                  () => const GameView(),
                  binding: GameBinding(),
                  arguments: {
                    'type': GameType.addition,
                    'level': 1,
                    'isPractice': isPractice,
                  },
                ),
                child: const Text('go'),
              ),
            ),
          );
        },
      ),
    ),
  );
  await tester.tap(find.text('go'));
  // pump (not pumpAndSettle) — pumpAndSettle hangs on the running game timer.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
  return Get.find<GameController>();
}

void _submit(GameController c, int answer) {
  c.answer.value = answer.toString();
  c.submit();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SfxService.audioBackendEnabled = false;
    await Get.putAsync<RecordService>(() => RecordService().init());
    await Get.putAsync<SfxService>(() => SfxService().init());
  });

  tearDown(() async {
    await Get.deleteAll(force: true);
  });

  testWidgets('comboCount starts at 0', (tester) async {
    final c = await _bootGameController(tester, isPractice: true);
    expect(c.comboCount.value, 0);
  });

  testWidgets('correct answer increments comboCount', (tester) async {
    final c = await _bootGameController(tester, isPractice: true);
    _submit(c, c.current.answer);
    expect(c.comboCount.value, 1);
    _submit(c, c.current.answer);
    expect(c.comboCount.value, 2);
  });

  testWidgets('wrong answer resets comboCount to 0', (tester) async {
    final c = await _bootGameController(tester, isPractice: true);
    _submit(c, c.current.answer);
    _submit(c, c.current.answer);
    expect(c.comboCount.value, 2);
    // Force a wrong answer (answer is always >= 2 in level 1 addition since
    // operands are 1..9 so 1+1=2 minimum — subtract 1 to guarantee mismatch).
    _submit(c, c.current.answer - 1);
    expect(c.comboCount.value, 0);
  });

  testWidgets('combo can reach a milestone threshold', (tester) async {
    final c = await _bootGameController(tester, isPractice: true);
    for (var i = 0; i < 3; i++) {
      _submit(c, c.current.answer);
    }
    // 3 is the first milestone — combo counter must hit it cleanly.
    expect(c.comboCount.value, 3);
    expect(GameController.comboMilestones.contains(3), isTrue);
  });

  test('milestone thresholds match the spec (3 / 5 / 7 / 10)', () {
    expect(GameController.comboMilestones, {3, 5, 7, 10});
  });
}
