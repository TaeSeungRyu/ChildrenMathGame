import 'dart:async';

import 'package:get/get.dart';

import '../../data/models/game_type.dart';
import '../../data/models/problem.dart';
import '../../data/services/problem_generator.dart';
import '../../data/services/sfx_service.dart';

/// 부호 맞추기 — 식의 연산 기호를 가리고 아이가 채우는 특별 모드.
///
/// 레벨별로 맞혀야 하는 기호 개수와 후보 연산 풀이 다르다(문제 생성은
/// [ProblemGenerator.generateSignGuess]). 아이는 빈칸을 왼쪽부터 채우고, 모두
/// 채우면 자동 채점 → 잠깐 피드백 후 다음 문제로 넘어간다. 결과는 기록에
/// 저장하지 않는다(구구단처럼 연습 성격).
class SignGuessController extends GetxController {
  final SfxService _sfx = Get.find();

  late final int level;
  late final List<GameType> pool;
  late final List<Problem> problems;

  final RxInt index = 0.obs;
  final RxInt correctCount = 0.obs;
  // 현재 문제에서 채운 기호들(왼쪽부터). 길이는 정답 기호 수까지 늘어난다.
  final RxList<GameType> filled = <GameType>[].obs;
  // 방금 제출한 결과 피드백: 1 정답 / -1 오답 / 0 없음.
  final RxInt feedback = 0.obs;
  final RxBool isFinished = false.obs;

  Problem get current => problems[index.value];
  int get opCount => current.operations.length;
  int get total => problems.length;
  bool get isComplete => filled.length >= opCount;

  Timer? _advanceTimer;

  @override
  void onInit() {
    super.onInit();
    level = (Get.arguments as Map)['level'] as int;
    pool = ProblemGenerator.signGuessPool(level);
    problems = ProblemGenerator.generateSignGuess(level);
  }

  void selectOp(GameType op) {
    if (feedback.value != 0 || isFinished.value) return;
    if (filled.length >= opCount) return;
    _sfx.click();
    filled.add(op);
    if (filled.length == opCount) _check();
  }

  void deleteLast() {
    if (feedback.value != 0 || isFinished.value) return;
    if (filled.isEmpty) return;
    _sfx.click();
    filled.removeLast();
  }

  void _check() {
    final correct =
        ProblemGenerator.evaluateChain(current.operands, filled.toList()) ==
            current.answer.toDouble();
    if (correct) {
      correctCount.value += 1;
      feedback.value = 1;
      _sfx.correct();
    } else {
      feedback.value = -1;
      _sfx.wrong();
    }
    _advanceTimer?.cancel();
    _advanceTimer = Timer(const Duration(milliseconds: 900), _advance);
  }

  void _advance() {
    feedback.value = 0;
    filled.clear();
    if (index.value >= problems.length - 1) {
      isFinished.value = true;
      _sfx.finish();
      return;
    }
    index.value += 1;
  }

  void restart() {
    _advanceTimer?.cancel();
    problems = ProblemGenerator.generateSignGuess(level);
    index.value = 0;
    correctCount.value = 0;
    filled.clear();
    feedback.value = 0;
    isFinished.value = false;
  }

  void exitToHome() => Get.back();

  @override
  void onClose() {
    _advanceTimer?.cancel();
    super.onClose();
  }
}
