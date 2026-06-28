import 'package:get/get.dart';

import '../../data/models/game_type.dart';

/// 숫자 사다리 컨트롤러 — 현재는 인트로 셸. 진입 선택 화면에서 넘어온
/// (gameType, digitsA, digitsB) 인자만 보관하고, 실제 플레이 로직은 추후 추가.
class LadderGameController extends GetxController {
  late final GameType? gameType;
  late final int digitsA;
  late final int digitsB;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      gameType = args['gameType'] as GameType?;
      digitsA = (args['digitsA'] as int?) ?? 1;
      digitsB = (args['digitsB'] as int?) ?? 1;
    } else {
      gameType = GameType.addition;
      digitsA = 1;
      digitsB = 1;
    }
  }

  void exitToHome() => Get.back();
}
