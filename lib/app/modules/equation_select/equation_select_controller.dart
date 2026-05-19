import 'package:get/get.dart';

import '../../data/models/game_type.dart';
import '../../routes/app_routes.dart';

class EquationSelectController extends GetxController {
  static const choices = [
    GameType.addition,
    GameType.subtraction,
    GameType.multiplication,
    GameType.division,
  ];

  // Default sub-operation. Single-select — the underlying game generates
  // problems with this op and the player solves for the hidden operand.
  final selectedType = GameType.addition.obs;

  final isPractice = false.obs;

  void setType(GameType t) {
    selectedType.value = t;
  }

  void setPractice(bool value) {
    isPractice.value = value;
  }

  void startLevel(int level) {
    Get.toNamed(
      AppRoutes.game,
      arguments: {
        'type': selectedType.value,
        'level': level,
        'isPractice': isPractice.value,
        'isEquation': true,
      },
    );
  }
}
