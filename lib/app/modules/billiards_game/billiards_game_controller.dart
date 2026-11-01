import 'dart:math' as math;

import 'package:get/get.dart';

import '../../data/models/game_type.dart';
import '../../data/services/billiards_score_service.dart';
import '../../shared/billiards_physics.dart';
import '../../shared/billiards_rules.dart';

class BilliardsGameController extends GetxController {
  late final GameType operation;
  late final int ballCount;
  late BilliardsLayout layout;
  late BilliardsTarget target;
  final selectedId = (-1).obs;
  final angle = (-math.pi / 2).obs;
  final power = 0.6.obs;
  final phase = 'aim'.obs; // aim, moving, feedback, won, quit
  final attempts = 0.obs;
  final revision = 0.obs;
  final best = Rxn<BilliardsValue>();
  final expression = ''.obs;
  final message = ''.obs;
  final hitIds = <int>[].obs;
  BilliardsShot? shot;
  bool _reported = false;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    operation = args is Map && args['operation'] is GameType
        ? args['operation'] as GameType
        : GameType.addition;
    ballCount = args is Map && args['ballCount'] is int
        ? (args['ballCount'] as int).clamp(4, 6)
        : 5;
    newGame();
  }

  void newGame() {
    for (var i = 0; i < 10; i++) {
      layout = BilliardsRules.generate(operation, ballCount);
      final candidate = findReachableTarget(layout, operation);
      if (candidate != null) {
        target = candidate;
        break;
      }
      if (i == 9) throw StateError('No reachable billiards layout');
    }
    selectedId.value = layout.starterIds.first;
    angle.value = -math.pi / 2;
    power.value = 0.6;
    attempts.value = 0;
    best.value = null;
    _reported = false;
    resetShot();
  }

  void resetShot() {
    shot = null;
    hitIds.clear();
    expression.value = '';
    message.value = '';
    phase.value = 'aim';
    revision.value++;
  }

  void select(int id) {
    if (phase.value == 'aim' && layout.starterIds.contains(id)) {
      selectedId.value = id;
    }
  }

  void aimAt(double x, double y) {
    if (phase.value != 'aim' || selectedId.value < 0) return;
    final ball = layout.balls.firstWhere((b) => b.id == selectedId.value);
    if (math.pow(x - ball.x, 2) + math.pow(y - ball.y, 2) < 0.0001) return;
    angle.value = math.atan2(y - ball.y, x - ball.x);
  }

  void rotate(double delta) {
    if (phase.value == 'aim') angle.value += delta;
  }

  void setPower(double value) {
    if (phase.value == 'aim') power.value = value.clamp(0.1, 1.0);
  }

  void fire() {
    if (phase.value != 'aim' || selectedId.value < 0) return;
    shot = BilliardsShot(
      layout: layout,
      starterId: selectedId.value,
      angle: angle.value,
      power: power.value,
    );
    attempts.value++;
    phase.value = 'moving';
  }

  void tick(double seconds) {
    if (phase.value != 'moving' || shot == null) return;
    shot!.advance(seconds);
    hitIds.assignAll(shot!.hitIds);
    final starter = layout.balls.firstWhere((b) => b.id == selectedId.value);
    final hitNumbers = hitIds.map(
      (id) => layout.balls.firstWhere((b) => b.id == id).number,
    );
    if (hitIds.isNotEmpty) {
      expression.value = BilliardsRules.expression(
        operation,
        starter.number,
        hitNumbers,
      );
    }
    revision.value++;
    if (shot!.stopped) _finish();
  }

  void _finish() {
    if (hitIds.isEmpty) {
      message.value = '공을 맞혀야 기록이 생겨요. 다시 도전해요!';
      phase.value = 'feedback';
      return;
    }
    final starter = layout.balls.firstWhere((b) => b.id == selectedId.value);
    final hitNumbers = hitIds.map(
      (id) => layout.balls.firstWhere((b) => b.id == id).number,
    );
    final result = BilliardsRules.result(operation, starter.number, hitNumbers);
    if (best.value == null || result.compareTo(best.value!) > 0) {
      best.value = result;
    }
    if (result.compareTo(target.value) >= 0) {
      message.value = '최고의 수를 만들었어요!';
      phase.value = 'won';
      _report();
    } else {
      message.value = '아쉽네요! 가장 큰 수가 아니에요. 다시 도전해 볼까요?';
      phase.value = 'feedback';
    }
  }

  void quit() {
    if (phase.value == 'moving') return;
    _report();
    phase.value = 'quit';
  }

  void _report() {
    if (_reported) return;
    _reported = true;
    if (Get.isRegistered<BilliardsScoreService>()) {
      Get.find<BilliardsScoreService>().report(
        operation,
        ballCount,
        best.value,
      );
    }
  }
}
