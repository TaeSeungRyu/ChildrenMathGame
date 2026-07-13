import 'dart:async';
import 'dart:math';

import 'package:get/get.dart';

import '../../data/models/action_concept.dart';
import '../../data/models/game_type.dart';
import '../../data/models/problem.dart';
import '../../data/services/action_score_service.dart';
import '../../data/services/problem_generator.dart';
import '../../data/services/sfx_service.dart';

/// 숫자 사다리 컨트롤러 — 객관식 등반 모델.
///
/// 상단에 한 문제가 떠 있고, 하단에 [choiceCount]개의 답 후보(정답 1 + 디코이)가
/// 발판으로 깔린다. 정답 발판을 밟으면 사다리를 한 칸 올라가며(높이 +1, 콤보 +1)
/// 곧바로 다음 문제로 전환된다. 오답 발판을 밟으면 콤보가 끊기고 HP가 줄지만
/// 같은 문제를 다시 풀 수 있다(저학년 친화적인 관대한 규칙).
///
/// 종료 조건은 HP 0 또는 [totalSeconds] 도달 — 다른 액션 모드와 동일. 점수는
/// 오른 칸 수([height]).
class LadderGameController extends GetxController {
  static const int maxHp = 3;
  static const int totalSeconds = 60;

  /// 답 후보 수. 3개면 6~9세도 한눈에 스캔 가능하고 정답률이 너무 낮지 않다.
  static const int choiceCount = 3;

  /// 정답 후 다음 문제로 넘어가기까지의 텀. 클라이머가 정답 발판으로 점프하고
  /// 카메라가 그 칸까지 따라 올라가는 연출이 끝나는 길이. View 의 등반
  /// 애니메이션(점프→스크롤)은 이보다 살짝 짧게 잡아 자연스럽게 맞물린다.
  static const int advanceDelayMs = 460;

  final SfxService _sfx = Get.find();
  final ActionScoreService _scores = Get.find();
  final Random _rng = Random();

  static const ActionConcept concept = ActionConcept.ladder;

  // 진입 선택 화면 인자.
  late final GameType? gameType;
  late final int digitsA;
  late final int digitsB;

  final RxInt hp = maxHp.obs;
  final RxInt height = 0.obs; // 오른 칸 수 = 점수
  final RxInt combo = 0.obs;
  final RxBool isGameOver = false.obs;
  final RxBool isNewBest = false.obs;
  final RxInt elapsed = 0.obs;

  late final Rx<Problem> currentProblem;

  // 현재 문제의 답 후보(정답 1 + 디코이). 섞인 순서.
  final RxList<int> choices = <int>[].obs;

  // 마지막으로 누른 후보 값과 정오 — View 가 발판 색을 잠깐 강조하는 데 쓴다.
  // -1 이면 강조 없음.
  final RxInt feedbackValue = (-1).obs;
  final RxBool feedbackCorrect = false.obs;

  // 입력 이벤트 신호. 같은 값을 연속으로 눌러 [feedbackValue] 가 변하지 않는
  // 경우에도 View 의 애니메이션 트리거(점프/흔들림)가 매번 발화하도록, 탭이
  // 실제 처리될 때마다 1씩 증가시킨다.
  final RxInt inputTick = 0.obs;

  Timer? _secondTimer;
  // 정답 처리 → 다음 문제 전환 사이 입력 잠금.
  bool _locked = false;
  // 지연 콜백 타이머들. 종료/dispose 에서 일괄 취소해 disposed Rx 접근을 막는다.
  final List<Timer> _pending = [];

  int get remainingSeconds {
    final r = totalSeconds - elapsed.value;
    return r < 0 ? 0 : r;
  }

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
    currentProblem = _generateProblem().obs;
    _buildChoices();
    _startSecondTimer();
  }

  Problem _generateProblem() {
    return ProblemGenerator.generateOneForDigits(
      type: gameType,
      digitsA: digitsA,
      digitsB: digitsB,
    );
  }

  /// 정답 1 + (choiceCount-1) 디코이를 만들어 섞는다. 디코이는 같은
  /// (type, digits) 로 문제를 한 번 더 생성해 그 답을 가져온다 — "그럴듯한"
  /// 숫자 영역에 머물게 해 학습 효과를 유지.
  void _buildChoices() {
    final answers = <int>{currentProblem.value.answer};
    var tries = 0;
    while (answers.length < choiceCount && tries < 60) {
      tries++;
      final d = _generateDecoy(currentProblem.value.answer);
      if (d != null) answers.add(d);
    }
    final list = answers.toList()..shuffle(_rng);
    choices.assignAll(list);
  }

  int? _generateDecoy(int correct) {
    final p = _generateProblem();
    if (p.answer == correct) return null;
    if (p.answer < 0) return null;
    return p.answer;
  }

  // ───── 입력 ────────────────────────────────────────────────────────────────

  void onChoiceTap(int value) {
    if (isGameOver.value || _locked) return;
    final correct = value == currentProblem.value.answer;
    feedbackValue.value = value;
    feedbackCorrect.value = correct;
    inputTick.value += 1;

    if (correct) {
      _sfx.correct();
      height.value += 1;
      combo.value += 1;
      _locked = true;
      _delay(const Duration(milliseconds: advanceDelayMs), () {
        _locked = false;
        feedbackValue.value = -1;
        currentProblem.value = _generateProblem();
        _buildChoices();
      });
    } else {
      _sfx.wrong();
      combo.value = 0;
      _loseHp();
      if (isGameOver.value) return;
      // 오답 강조만 잠깐 보여 주고 해제 — 같은 문제 재도전.
      _delay(const Duration(milliseconds: 420), () {
        if (feedbackValue.value == value) feedbackValue.value = -1;
      });
    }
  }

  void _loseHp() {
    hp.value -= 1;
    if (hp.value <= 0) {
      hp.value = 0;
      _gameOver();
    }
  }

  Timer _delay(Duration d, void Function() action) {
    late final Timer t;
    t = Timer(d, () {
      _pending.removeWhere((x) => identical(x, t));
      if (isGameOver.value) return;
      action();
    });
    _pending.add(t);
    return t;
  }

  void _cancelPending() {
    for (final t in _pending) {
      t.cancel();
    }
    _pending.clear();
  }

  // ───── 타이머 / 종료 ───────────────────────────────────────────────────────

  void _startSecondTimer() {
    _secondTimer?.cancel();
    _secondTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (isGameOver.value) return;
      elapsed.value += 1;
      if (elapsed.value >= totalSeconds) _gameOver();
    });
  }

  void _gameOver() {
    isGameOver.value = true;
    _secondTimer?.cancel();
    _secondTimer = null;
    _cancelPending();
    _sfx.finish();
    _scores.report(concept, height.value).then((v) => isNewBest.value = v);
  }

  void restart() {
    hp.value = maxHp;
    height.value = 0;
    combo.value = 0;
    elapsed.value = 0;
    isGameOver.value = false;
    isNewBest.value = false;
    _locked = false;
    feedbackValue.value = -1;
    _cancelPending();
    currentProblem.value = _generateProblem();
    _buildChoices();
    _startSecondTimer();
  }

  void exitToHome() => Get.back();

  @override
  void onClose() {
    _secondTimer?.cancel();
    _cancelPending();
    super.onClose();
  }
}
