import 'package:children_math_game/app/modules/billiards_game/billiards_game_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('reachable target can be won and a new game resets attempts', () {
    Get.testMode = true;
    final controller = Get.put(BilliardsGameController());
    final target = controller.target;
    controller.select(target.starterId);
    controller.angle.value = target.angle;
    controller.setPower(target.power);
    controller.fire();
    expect(controller.phase.value, 'moving');
    for (var i = 0; i < 375 && controller.phase.value == 'moving'; i++) {
      controller.tick(0.016);
    }
    expect(controller.hitIds, target.hitIds);
    expect(controller.phase.value, 'won');
    expect(controller.attempts.value, 1);
    controller.newGame();
    expect(controller.phase.value, 'aim');
    expect(controller.attempts.value, 0);
    Get.delete<BilliardsGameController>(force: true);
  });

  test('missed shot allows another attempt on the same layout', () {
    Get.testMode = true;
    final controller = Get.put(BilliardsGameController());
    final originalLayout = controller.layout;
    final selected = controller.selectedId.value;
    controller.fire();
    for (var i = 0; i < 375 && controller.phase.value == 'moving'; i++) {
      controller.tick(0.016);
    }
    if (controller.phase.value == 'feedback') {
      controller.resetShot();
      expect(controller.layout, same(originalLayout));
      expect(controller.selectedId.value, selected);
      expect(controller.attempts.value, 1);
      expect(controller.phase.value, 'aim');
    }
    Get.delete<BilliardsGameController>(force: true);
  });
}
