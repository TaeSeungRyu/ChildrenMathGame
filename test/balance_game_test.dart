import 'package:children_math_game/app/data/models/action_concept.dart';
import 'package:children_math_game/app/data/models/game_type.dart';
import 'package:children_math_game/app/data/services/action_score_service.dart';
import 'package:children_math_game/app/data/services/sfx_service.dart';
import 'package:children_math_game/app/modules/balance_game/balance_game_controller.dart';
import 'package:children_math_game/app/modules/balance_game/balance_game_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 저울 맞추기 화면 — 렌더링 + 한 라운드 진행.
///
/// 저울 빔/접시를 수식으로 배치하는 화면이라 레이아웃이 깨지기 쉬워, 실제로
/// 펌프해 예외 없이 그려지는지와 정오답이 점수/HP에 반영되는지를 본다.
void main() {
  late BalanceGameController controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SfxService.audioBackendEnabled = false;
    await Get.putAsync<SfxService>(() => SfxService().init());
    await Get.putAsync<ActionScoreService>(() => ActionScoreService().init());
    Get.testMode = true;
  });

  tearDown(() async {
    await Get.deleteAll(force: true);
  });

  Future<void> pumpGame(WidgetTester tester) async {
    // 기본 테스트 화면(800×600)은 이 앱이 상정하는 세로 폰과 비율이 딴판이라
    // 저울 배치가 넘치는지 확인이 안 된다. 실제 폰에 가까운 크기로 고정한다.
    tester.view.physicalSize = const Size(360, 690);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // 인자 없이 진입 — 컨트롤러가 (덧셈, 1×1)로 폴백한다.
    controller = Get.put(BalanceGameController());
    await tester.pumpWidget(
      const GetMaterialApp(home: BalanceGameView()),
    );
    await tester.pump();
  }

  testWidgets('renders the balance with both expressions and the three choices',
      (tester) async {
    await pumpGame(tester);

    expect(find.text(controller.pair.value.left.questionText), findsOneWidget);
    expect(find.text(controller.pair.value.right.questionText), findsOneWidget);
    expect(find.text('왼쪽이 커요'), findsOneWidget);
    expect(find.text('같아요'), findsOneWidget);
    expect(find.text('오른쪽이 커요'), findsOneWidget);
    expect(controller.hp.value, BalanceGameController.maxHp);

    await tester.pump(const Duration(seconds: 1));
    expect(controller.remainingSeconds, BalanceGameController.totalSeconds - 1);

    controller.onClose();
  });

  testWidgets('a correct pick scores, a wrong pick costs a heart',
      (tester) async {
    await pumpGame(tester);

    controller.onChoiceTap(controller.pair.value.relation);
    await tester.pump();
    expect(controller.solved.value, 1);
    expect(controller.combo.value, 1);
    expect(controller.hp.value, BalanceGameController.maxHp);
    // 공개 중에는 입력이 잠긴다 — 연타로 점수가 불어나면 안 된다.
    controller.onChoiceTap(controller.pair.value.relation);
    expect(controller.solved.value, 1);

    await tester.pump(
      const Duration(milliseconds: BalanceGameController.revealCorrectMs + 50),
    );

    final answer = controller.pair.value.relation;
    final wrong = answer == 1 ? -1 : 1;
    controller.onChoiceTap(wrong);
    await tester.pump();
    expect(controller.hp.value, BalanceGameController.maxHp - 1);
    expect(controller.combo.value, 0);
    expect(controller.solved.value, 1);

    await tester.pump(
      const Duration(milliseconds: BalanceGameController.revealWrongMs + 50),
    );
    controller.onClose();
  });

  testWidgets('losing all hearts ends the run and reports the score',
      (tester) async {
    await pumpGame(tester);

    for (var i = 0; i < BalanceGameController.maxHp; i++) {
      final answer = controller.pair.value.relation;
      controller.onChoiceTap(answer == 1 ? -1 : 1);
      await tester.pump(
        const Duration(milliseconds: BalanceGameController.revealWrongMs + 50),
      );
    }

    expect(controller.isGameOver.value, isTrue);
    await tester.pump();
    expect(find.text('GAME OVER'), findsOneWidget);
    expect(
      Get.find<ActionScoreService>().playsFor(ActionConcept.balance),
      1,
    );

    controller.onClose();
  });

  testWidgets('falls back to 1-digit addition without arguments',
      (tester) async {
    await pumpGame(tester);
    expect(controller.gameType, GameType.addition);
    expect(controller.digitsA, 1);
    expect(controller.digitsB, 1);
    controller.onClose();
  });
}
