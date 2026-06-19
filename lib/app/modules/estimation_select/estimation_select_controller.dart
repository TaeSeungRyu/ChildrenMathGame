import 'package:get/get.dart';

import '../../data/models/game_type.dart';
import '../../routes/app_routes.dart';

class EstimationSelectController extends GetxController {
  // 어림셈은 +/−/× 셋만 — 나눗셈은 정수 몫이라 반올림할 거리가 없어 의미 없음.
  // ÷ 제외는 의도된 설계이므로 셀렉트 화면에서 아예 보기에서 빠진다.
  static const choices = [
    GameType.addition,
    GameType.subtraction,
    GameType.multiplication,
  ];

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
        'isEstimation': true,
      },
    );
  }
}
