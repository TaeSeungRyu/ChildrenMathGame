import 'package:children_math_game/app/data/models/action_concept.dart';
import 'package:children_math_game/app/data/models/arena_upgrade.dart';
import 'package:children_math_game/app/data/models/game_type.dart';
import 'package:children_math_game/app/data/services/action_score_service.dart';
import 'package:children_math_game/app/data/services/sfx_service.dart';
import 'package:children_math_game/app/modules/arena_game/arena_game_controller.dart';
import 'package:children_math_game/app/modules/arena_game/arena_game_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 아레나(웨이브 생존) — 웨이브 진행 규칙과 강화 카드 흐름.
///
/// 이 모드는 다른 액션 게임과 달리 **상태가 웨이브를 넘어 이어진다**(강화 효과,
/// 방어막, 콤보 배수). 그래서 한 라운드 정오답뿐 아니라 "웨이브 클리어 → 카드
/// 선택 → 다음 웨이브"의 이음새를 함께 본다.
void main() {
  late ArenaGameController controller;

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
    // 세로 폰 비율 고정 — 기본 800×600으로는 HUD/아레나/보기 버튼이 한 화면에
    // 들어가는지 확인이 안 된다.
    tester.view.physicalSize = const Size(360, 690);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // 인자 없이 진입 — 컨트롤러가 (덧셈, 1×1)로 폴백한다.
    controller = Get.put(ArenaGameController());
    await tester.pumpWidget(const GetMaterialApp(home: ArenaGameView()));
    await tester.pump();
  }

  /// 현재 문제를 맞히고 연출이 끝날 때까지 진행한다.
  Future<void> answerCorrectly(WidgetTester tester) async {
    controller.onChoiceTap(controller.currentProblem.value.answer);
    await tester.pump();
    await tester.pump(
      const Duration(milliseconds: ArenaGameController.revealCorrectMs + 50),
    );
  }

  /// 현재 문제를 일부러 틀린다.
  Future<void> answerWrong(WidgetTester tester) async {
    final answer = controller.currentProblem.value.answer;
    final wrong = controller.choices.firstWhere(
      (c) => c != answer,
      orElse: () => answer + 1,
    );
    controller.onChoiceTap(wrong);
    await tester.pump();
    await tester.pump(
      const Duration(milliseconds: ArenaGameController.revealWrongMs + 50),
    );
  }

  group('웨이브 규칙 (순수 계산)', () {
    test('3웨이브마다 보스, 잔몹은 2웨이브마다 한 마리씩 최대 8까지', () {
      expect(ArenaGameController.isBossWaveNumber(3), isTrue);
      expect(ArenaGameController.isBossWaveNumber(6), isTrue);
      expect(ArenaGameController.isBossWaveNumber(4), isFalse);

      expect(ArenaGameController.enemiesForWave(1), 3);
      expect(ArenaGameController.enemiesForWave(2), 3);
      expect(ArenaGameController.enemiesForWave(4), 4);
      // 보스 웨이브는 "한 마리"로 표현되고 두께는 HP로 준다.
      expect(ArenaGameController.enemiesForWave(3), 1);
      // 40은 보스 웨이브가 아니라(40 % 3 == 1) 잔몹 상한이 적용된다.
      expect(ArenaGameController.enemiesForWave(40), 8);
    });

    test('보스는 거듭할수록 두꺼워진다', () {
      expect(ArenaGameController.bossHpForWave(3), 3);
      expect(ArenaGameController.bossHpForWave(6), 4);
      expect(ArenaGameController.bossHpForWave(9), 5);
    });

    test('제한시간은 1차 하한 12초에 닿은 뒤에도 10초까지 더 조여진다', () {
      expect(ArenaGameController.secondsForWave(1), 22);
      expect(ArenaGameController.secondsForWave(2), 21);
      // 보스 웨이브는 보너스 시간이 붙는다.
      expect(
        ArenaGameController.secondsForWave(3),
        20 + ArenaGameController.bossExtraSeconds,
      );

      // 웨이브 11에서 1차 하한(12초)에 도달.
      expect(
        ArenaGameController.secondsForWave(ArenaGameController.lateGameWave),
        ArenaGameController.softFloorSeconds,
      );
      // 그 뒤로는 3웨이브마다 1초씩 더 — 14는 11초, 17은 최종 하한 10초.
      expect(ArenaGameController.secondsForWave(14), 11);
      expect(
        ArenaGameController.secondsForWave(17),
        ArenaGameController.hardFloorSeconds,
      );
      // 최종 하한 아래로는 내려가지 않는다.
      expect(
        ArenaGameController.secondsForWave(40),
        ArenaGameController.hardFloorSeconds,
      );
      // 하한에 닿은 뒤에도 보스 보너스는 그대로 붙는다(42 % 3 == 0).
      expect(
        ArenaGameController.secondsForWave(42),
        ArenaGameController.hardFloorSeconds +
            ArenaGameController.bossExtraSeconds,
      );
    });
  });

  testWidgets('첫 웨이브가 문제·보기·하트와 함께 그려진다', (tester) async {
    await pumpGame(tester);

    expect(find.text('WAVE 1'), findsWidgets);
    expect(
      find.text('${controller.currentProblem.value.questionText} = ?'),
      findsOneWidget,
    );
    expect(controller.choices.length, ArenaGameController.baseChoiceCount);
    expect(
      controller.choices.contains(controller.currentProblem.value.answer),
      isTrue,
    );
    expect(controller.hp.value, ArenaGameController.startingHp);
    expect(controller.enemiesLeft.value, ArenaGameController.enemiesForWave(1));

    await tester.pump(const Duration(seconds: 1));
    expect(
      controller.waveRemaining.value,
      ArenaGameController.secondsForWave(1) - 1,
    );

    controller.onClose();
  });

  testWidgets('정답이면 적이 줄고 점수·콤보가 오른다 (연출 중 연타는 무시)',
      (tester) async {
    await pumpGame(tester);
    final enemies = controller.enemiesLeft.value;

    controller.onChoiceTap(controller.currentProblem.value.answer);
    await tester.pump();
    expect(controller.enemiesLeft.value, enemies - 1);
    expect(controller.combo.value, 1);
    expect(controller.score.value, greaterThanOrEqualTo(
      ArenaGameController.baseScore,
    ));
    expect(controller.hp.value, ArenaGameController.startingHp);

    // 연출 중 추가 입력은 먹지 않아야 한다.
    final scoreAfterFirst = controller.score.value;
    controller.onChoiceTap(controller.currentProblem.value.answer);
    expect(controller.score.value, scoreAfterFirst);
    expect(controller.enemiesLeft.value, enemies - 1);

    await tester.pump(
      const Duration(milliseconds: ArenaGameController.revealCorrectMs + 50),
    );
    controller.onClose();
  });

  testWidgets('오답이면 하트가 깎이고 콤보가 끊긴다', (tester) async {
    await pumpGame(tester);
    await answerCorrectly(tester);
    expect(controller.combo.value, 1);

    final enemies = controller.enemiesLeft.value;
    await answerWrong(tester);

    expect(controller.hp.value, ArenaGameController.startingHp - 1);
    expect(controller.combo.value, 0);
    // 틀려도 적은 그대로 — 다시 맞히면 된다.
    expect(controller.enemiesLeft.value, enemies);

    controller.onClose();
  });

  testWidgets('웨이브를 비우면 강화 카드가 뜨고, 고르면 다음 웨이브가 시작된다',
      (tester) async {
    await pumpGame(tester);

    final needed = controller.enemiesLeft.value;
    for (var i = 0; i < needed; i++) {
      await answerCorrectly(tester);
    }

    expect(controller.enemiesLeft.value, 0);
    await tester.pump(
      const Duration(milliseconds: ArenaGameController.waveClearMs + 50),
    );

    expect(controller.isChoosingUpgrade.value, isTrue);
    expect(controller.upgradeOptions, isNotEmpty);
    expect(
      controller.upgradeOptions.length,
      lessThanOrEqualTo(ArenaGameController.upgradeChoiceCount),
    );
    await tester.pump();
    expect(find.text('웨이브 클리어!'), findsOneWidget);

    // 카드를 고르기 전에는 다음 웨이브가 시작되지 않는다.
    expect(controller.wave.value, 1);

    controller.chooseUpgrade(ArenaUpgrade.extraTime);
    await tester.pump();

    expect(controller.isChoosingUpgrade.value, isFalse);
    expect(controller.wave.value, 2);
    expect(controller.enemiesLeft.value, ArenaGameController.enemiesForWave(2));
    // "시간 +5초" 가 다음 웨이브에 실제로 실렸는지.
    expect(
      controller.waveRemaining.value,
      ArenaGameController.secondsForWave(2) + 5,
    );

    controller.onClose();
  });

  testWidgets('방어막은 오답 한 번을 대신 막아 준다', (tester) async {
    await pumpGame(tester);

    final needed = controller.enemiesLeft.value;
    for (var i = 0; i < needed; i++) {
      await answerCorrectly(tester);
    }
    await tester.pump(
      const Duration(milliseconds: ArenaGameController.waveClearMs + 50),
    );
    controller.chooseUpgrade(ArenaUpgrade.shield);
    await tester.pump();
    expect(controller.hasShield.value, isTrue);

    await answerWrong(tester);
    // 하트는 그대로, 방어막만 소모.
    expect(controller.hp.value, ArenaGameController.startingHp);
    expect(controller.hasShield.value, isFalse);

    // 다음 오답부터는 정상적으로 하트가 깎인다.
    await answerWrong(tester);
    expect(controller.hp.value, ArenaGameController.startingHp - 1);

    controller.onClose();
  });

  testWidgets('보기 줄이기 강화를 고르면 다음 웨이브 보기가 2개가 된다',
      (tester) async {
    await pumpGame(tester);

    final needed = controller.enemiesLeft.value;
    for (var i = 0; i < needed; i++) {
      await answerCorrectly(tester);
    }
    await tester.pump(
      const Duration(milliseconds: ArenaGameController.waveClearMs + 50),
    );
    controller.chooseUpgrade(ArenaUpgrade.fewerChoices);
    await tester.pump();

    // 초반 웨이브라 3개에서 하나 줄어 2개.
    expect(
      controller.choices.length,
      ArenaGameController.baseChoiceCount - 1,
    );

    controller.onClose();
  });

  testWidgets('시간이 다 되면 하트를 잃고 같은 웨이브를 다시 시작한다',
      (tester) async {
    await pumpGame(tester);

    await tester.pump(
      Duration(seconds: ArenaGameController.secondsForWave(1) + 1),
    );

    expect(controller.hp.value, ArenaGameController.startingHp - 1);
    // 웨이브는 되돌리지 않는다 — 같은 번호로 새 적이 채워진다.
    expect(controller.wave.value, 1);
    expect(controller.enemiesLeft.value, ArenaGameController.enemiesForWave(1));
    // 22초째에 재시작되고 23초째 틱이 한 번 더 지나간 시점이라 1초가 빠져 있다.
    expect(
      controller.waveRemaining.value,
      ArenaGameController.secondsForWave(1) - 1,
    );

    controller.onClose();
  });

  testWidgets('하트를 모두 잃으면 종료되고 점수가 기록된다', (tester) async {
    await pumpGame(tester);

    for (var i = 0; i < ArenaGameController.startingHp; i++) {
      await answerWrong(tester);
    }

    expect(controller.isGameOver.value, isTrue);
    await tester.pump();
    expect(find.text('GAME OVER'), findsOneWidget);
    expect(
      Get.find<ActionScoreService>().playsFor(ActionConcept.arena),
      1,
    );

    controller.onClose();
  });

  testWidgets('3웨이브에 도달하면 보스가 HP를 달고 등장한다', (tester) async {
    await pumpGame(tester);

    // 웨이브 1, 2를 비우고 각각 강화 카드를 고른다.
    for (var w = 0; w < 2; w++) {
      final needed = controller.enemiesLeft.value;
      for (var i = 0; i < needed; i++) {
        await answerCorrectly(tester);
      }
      await tester.pump(
        const Duration(milliseconds: ArenaGameController.waveClearMs + 50),
      );
      controller.chooseUpgrade(ArenaUpgrade.extraTime);
      await tester.pump();
    }

    expect(controller.wave.value, 3);
    expect(controller.isBossWave, isTrue);
    // 보스는 "한 마리"지만 HP가 여러 칸이라 연속으로 맞혀야 한다.
    expect(controller.enemiesLeft.value, ArenaGameController.bossHpForWave(3));
    expect(find.textContaining('BOSS'), findsWidgets);

    // 애니메이션이 몇 프레임 돌아도 예외 없이 그려져야 한다(티커 구동 화면).
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    // 보스를 한 번 때리면 HP가 한 칸 줄고, 웨이브는 아직 끝나지 않는다.
    await answerCorrectly(tester);
    expect(
      controller.enemiesLeft.value,
      ArenaGameController.bossHpForWave(3) - 1,
    );
    expect(controller.isChoosingUpgrade.value, isFalse);

    controller.onClose();
  });

  testWidgets('웨이브가 오르면 자릿수 사다리가 한 칸씩 올라간다', (tester) async {
    await pumpGame(tester);

    // 진입 인자가 없어 시작 칸은 (1,1). 3웨이브마다 한 칸씩.
    expect(controller.digitsForWave(1), (1, 1));
    expect(controller.digitsForWave(3), (1, 1));
    expect(controller.digitsForWave(4), (2, 1));
    expect(controller.digitsForWave(7), (2, 2));
    expect(controller.digitsForWave(10), (3, 2));
    expect(controller.digitsForWave(13), (3, 3));
    // 사다리 꼭대기에서 멈춘다.
    expect(controller.digitsForWave(40), (3, 3));
    expect(controller.currentDigits, (1, 1));

    controller.onClose();
  });

  testWidgets('보스를 넘기면 다음 웨이브부터 숫자가 굵어진다', (tester) async {
    await pumpGame(tester);

    // 웨이브 1·2·3(보스)을 차례로 비운다.
    for (var w = 0; w < 3; w++) {
      final needed = controller.enemiesLeft.value;
      for (var i = 0; i < needed; i++) {
        await answerCorrectly(tester);
      }
      await tester.pump(
        const Duration(milliseconds: ArenaGameController.waveClearMs + 50),
      );
      controller.chooseUpgrade(ArenaUpgrade.extraTime);
      await tester.pump();
    }

    expect(controller.wave.value, 4);
    expect(controller.currentDigits, (2, 1));
    expect(controller.raisedDigits.value, isTrue);
    // 배너가 이유를 알려 준다 — 갑자기 숫자가 커진 걸 설명 없이 겪지 않도록.
    expect(find.textContaining('숫자가 커져요'), findsOneWidget);

    controller.onClose();
  });

  testWidgets('후반 웨이브에는 보기가 하나 늘어 찍기가 어려워진다',
      (tester) async {
    await pumpGame(tester);
    expect(controller.choiceCount, ArenaGameController.baseChoiceCount);

    // 11웨이브까지 실제로 플레이하면 테스트가 길어져 웨이브만 옮겨 확인한다.
    controller.wave.value = ArenaGameController.lateGameWave;
    expect(controller.choiceCount, ArenaGameController.lateChoiceCount);

    controller.onClose();
  });

  testWidgets('게임오버에서 다시 버튼을 누르면 1웨이브부터 새로 시작한다',
      (tester) async {
    await pumpGame(tester);

    await answerCorrectly(tester);
    for (var i = 0; i < ArenaGameController.startingHp; i++) {
      await answerWrong(tester);
    }
    expect(controller.isGameOver.value, isTrue);
    await tester.pump();

    await tester.tap(find.text('다시'));
    await tester.pump();

    expect(controller.isGameOver.value, isFalse);
    expect(controller.wave.value, 1);
    expect(controller.score.value, 0);
    expect(controller.hp.value, ArenaGameController.startingHp);
    expect(controller.enemiesLeft.value, ArenaGameController.enemiesForWave(1));

    controller.onClose();
  });

  testWidgets('인자 없이 진입하면 1자리 덧셈으로 폴백한다', (tester) async {
    await pumpGame(tester);
    expect(controller.gameType, GameType.addition);
    expect(controller.digitsA, 1);
    expect(controller.digitsB, 1);
    controller.onClose();
  });
}
