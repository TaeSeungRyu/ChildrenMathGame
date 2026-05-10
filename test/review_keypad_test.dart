import 'package:children_math_game/app/data/models/game_type.dart';
import 'package:children_math_game/app/data/models/problem_attempt.dart';
import 'package:children_math_game/app/modules/review/review_binding.dart';
import 'package:children_math_game/app/modules/review/review_controller.dart';
import 'package:children_math_game/app/modules/review/review_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  tearDown(() async {
    await Get.deleteAll(force: true);
  });

  testWidgets('digit press updates the answer display', (tester) async {
    final attempts = [
      ProblemAttempt(
        operandA: 12,
        operandB: 3,
        type: GameType.addition,
        correctAnswer: 15,
        userAnswer: 14,
        status: AttemptStatus.wrong,
      ),
    ];

    await tester.pumpWidget(
      GetMaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Get.to(
                    () => const ReviewView(),
                    binding: ReviewBinding(),
                    arguments: attempts,
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
    await tester.pumpAndSettle();

    expect(find.text('정답 입력'), findsOneWidget);
    expect(find.text('12 + 3 = ?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '1'));
    await tester.pump();
    expect(Get.find<ReviewController>().answer.value, '1');

    await tester.tap(find.widgetWithText(FilledButton, '5'));
    await tester.pump();
    expect(Get.find<ReviewController>().answer.value, '15');
    expect(find.text('15'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '입력'));
    await tester.pump();
    expect(find.text('정답!'), findsOneWidget);
  });
}
