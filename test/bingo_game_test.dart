import 'package:children_math_game/app/data/models/action_concept.dart';
import 'package:children_math_game/app/data/services/action_score_service.dart';
import 'package:children_math_game/app/data/services/sfx_service.dart';
import 'package:children_math_game/app/modules/bingo_game/bingo_game_controller.dart';
import 'package:children_math_game/app/modules/bingo_game/bingo_game_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late BingoGameController controller;

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
    tester.view.physicalSize = const Size(360, 690);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    controller = Get.put(BingoGameController());
    await tester.pumpWidget(const GetMaterialApp(home: BingoGameView()));
    await tester.pump();
  }

  testWidgets('renders a 3x3 board and the current question', (tester) async {
    await pumpGame(tester);

    expect(controller.boardProblems, hasLength(9));
    expect(find.text('${controller.current.questionText} = ?'), findsOneWidget);
    expect(find.text('가로·세로·대각선 한 줄을 완성해요!'), findsOneWidget);
    expect(find.byType(InkWell), findsAtLeastNWidgets(9));
    controller.onClose();
  });

  testWidgets('tapping the answer paints and keeps the tile marked', (
    tester,
  ) async {
    await pumpGame(tester);
    final index = controller.boardProblems.indexWhere(
      (problem) => problem.answer == controller.current.answer,
    );
    final tiles = find.descendant(
      of: find.byType(GridView),
      matching: find.byType(InkWell),
    );
    await tester.tap(tiles.at(index));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final background = find.descendant(
      of: tiles.at(index),
      matching: find.byType(AnimatedContainer),
    );
    expect(
      (tester.widget<AnimatedContainer>(background).decoration as BoxDecoration)
          .color,
      const Color(0xFF26A69A),
    );
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(tester.widget<InkWell>(tiles.at(index)).onTap, isNull);
    controller.restart();
    await tester.pump();
    expect(find.byIcon(Icons.check_circle), findsNothing);
    controller.onClose();
  });

  testWidgets(
    'a correct answer marks a cell and a wrong answer costs a heart',
    (tester) async {
      await pumpGame(tester);

      final answer = controller.current.answer;
      final correctIndex = controller.boardProblems.indexWhere(
        (problem) => problem.answer == answer,
      );
      controller.selectCell(correctIndex);
      await tester.pump();
      expect(controller.marked, contains(correctIndex));
      expect(controller.hp.value, BingoGameController.maxHp);

      await tester.pump(
        const Duration(milliseconds: BingoGameController.revealCorrectMs + 10),
      );
      final nextAnswer = controller.current.answer;
      final wrongIndex = controller.boardProblems.indexWhere(
        (problem) =>
            !controller.marked.contains(
              controller.boardProblems.indexOf(problem),
            ) &&
            problem.answer != nextAnswer,
      );
      if (wrongIndex >= 0) {
        controller.selectCell(wrongIndex);
        await tester.pump();
        expect(controller.hp.value, BingoGameController.maxHp - 1);
      }
      controller.onClose();
    },
  );

  testWidgets('completing a line wins and reports a score', (tester) async {
    await pumpGame(tester);

    // 같은 답의 문제/칸을 직접 맞춰 세 칸을 표시한 뒤 빙고 판정을 검증한다.
    controller.marked.addAll({0, 1});
    final target = controller.boardProblems[2].answer;
    controller.questionOrder[controller.questionIndex.value] =
        controller.boardProblems[2];
    expect(controller.current.answer, target);
    controller.selectCell(2);
    await tester.pump(
      const Duration(milliseconds: BingoGameController.revealCorrectMs + 10),
    );

    expect(controller.isWin.value, isTrue);
    expect(controller.isGameOver.value, isTrue);
    expect(controller.finalScore.value, greaterThan(0));
    await tester.pump();
    expect(find.text('빙고!'), findsOneWidget);
    expect(Get.find<ActionScoreService>().playsFor(ActionConcept.bingo), 1);
    controller.onClose();
  });

  test('winning line detection covers rows columns and diagonals', () async {
    controller = Get.put(BingoGameController());
    expect(controller.isWinningSet({0, 1, 2}), isTrue);
    expect(controller.isWinningSet({1, 4, 7}), isTrue);
    expect(controller.isWinningSet({2, 4, 6}), isTrue);
    expect(controller.isWinningSet({0, 1, 4}), isFalse);
  });
}
