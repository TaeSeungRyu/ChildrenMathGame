import 'package:get/get.dart';

import '../../data/models/game_type.dart';
import '../../routes/app_routes.dart';

class MixedSelectController extends GetxController {
  // Choices exclude `mixed` itself — it's a roll-up, not a pickable op.
  static const choices = [
    GameType.addition,
    GameType.subtraction,
    GameType.multiplication,
    GameType.division,
  ];

  // Defaults: 덧셈 + 뺄셈 (matches the most common first-grade mix).
  final selectedTypes = <GameType>{
    GameType.addition,
    GameType.subtraction,
  }.obs;

  final isPractice = false.obs;

  void toggleType(GameType t) {
    if (selectedTypes.contains(t)) {
      // Don't let the user clear the last selection — leaves nothing to play.
      if (selectedTypes.length > 1) {
        selectedTypes.remove(t);
      }
    } else {
      selectedTypes.add(t);
    }
    selectedTypes.refresh();
  }

  void setPractice(bool value) {
    isPractice.value = value;
  }

  void startLevel(int level) {
    Get.toNamed(
      AppRoutes.game,
      arguments: {
        'mixedTypes': selectedTypes.toList(),
        'level': level,
        'isPractice': isPractice.value,
      },
    );
  }
}
