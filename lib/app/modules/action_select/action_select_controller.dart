import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/action_concept.dart';
import '../../data/models/game_type.dart';

/// 액션 게임 4종이 공유하는 진입 선택 화면의 컨트롤러.
///
/// - [concept]: `Get.arguments['concept']`로 받은 컨셉(몬스터/풍선/타워/두더지).
/// - [selectedOp]: 사용자가 고른 연산. `null` 이면 "🎲 랜덤"(매 문제 무작위 연산).
/// - [selectedDigits]: (자릿수A, 자릿수B) 조합. 5가지 중 하나.
///
/// 시작하기 누르면 [concept.gameRoute]로 라우팅하면서 본편 컨트롤러가 읽어갈
/// `gameType` / `digitsA` / `digitsB` 인자를 전달한다. 마지막 선택값은
/// SharedPreferences(`action_last_op_v1`, `action_last_digits_v1`)에 저장돼
/// 다음 진입 시 기본값으로 복원된다.
class ActionSelectController extends GetxController {
  static const _kOpKey = 'action_last_op_v1';
  static const _kDigitsKey = 'action_last_digits_v1';

  // 사용자가 고를 수 있는 연산 5개. `null`이 "🎲 랜덤"을 뜻한다. roll-up 타입
  // (mixed/equation/flash)은 액션 모드 출제에 부적절하므로 노출하지 않는다.
  static const List<GameType?> opChoices = [
    GameType.addition,
    GameType.subtraction,
    GameType.multiplication,
    GameType.division,
    null,
  ];

  // 자릿수 조합 — challenge 모드의 level 1..5와 의도적으로 동일한 사다리.
  // (1,1) / (2,1) / (2,2) / (3,2) / (3,3).
  static const List<(int, int)> digitChoices = [
    (1, 1),
    (2, 1),
    (2, 2),
    (3, 2),
    (3, 3),
  ];

  late final ActionConcept concept;

  final Rxn<GameType> selectedOp = Rxn<GameType>(GameType.addition);
  final Rx<(int, int)> selectedDigits = (1, 1).obs;

  SharedPreferences? _prefs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['concept'] is ActionConcept) {
      concept = args['concept'] as ActionConcept;
    } else {
      // 인자가 빠진 경우(딥링크/테스트 등) — 기본 컨셉으로 폴백.
      concept = ActionConcept.monster;
    }
    _restore();
  }

  Future<void> _restore() async {
    _prefs = await SharedPreferences.getInstance();
    final op = _prefs!.getString(_kOpKey);
    if (op != null) {
      if (op == 'random') {
        selectedOp.value = null;
      } else {
        final match = GameType.values
            .where((t) => t.name == op && opChoices.contains(t))
            .firstOrNull;
        if (match != null) selectedOp.value = match;
      }
    }
    final digits = _prefs!.getString(_kDigitsKey);
    if (digits != null) {
      final parts = digits.split('x');
      if (parts.length == 2) {
        final a = int.tryParse(parts[0]);
        final b = int.tryParse(parts[1]);
        if (a != null && b != null && digitChoices.contains((a, b))) {
          selectedDigits.value = (a, b);
        }
      }
    }
  }

  void setOp(GameType? op) {
    selectedOp.value = op;
    _prefs?.setString(_kOpKey, op?.name ?? 'random');
  }

  void setDigits((int, int) pair) {
    selectedDigits.value = pair;
    _prefs?.setString(_kDigitsKey, '${pair.$1}x${pair.$2}');
  }

  void start() {
    final pair = selectedDigits.value;
    Get.toNamed(
      concept.gameRoute,
      arguments: {
        'gameType': selectedOp.value, // null == 🎲 랜덤
        'digitsA': pair.$1,
        'digitsB': pair.$2,
      },
    );
  }
}
