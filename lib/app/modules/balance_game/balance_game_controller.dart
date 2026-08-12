import 'dart:async';

import 'package:get/get.dart';

import '../../data/models/action_concept.dart';
import '../../data/models/balance_pair.dart';
import '../../data/models/game_type.dart';
import '../../data/services/action_score_service.dart';
import '../../data/services/problem_generator.dart';
import '../../data/services/sfx_service.dart';

/// 저울 맞추기 컨트롤러 — 비교(대소) 모델.
///
/// 기존 6종과의 차별화 포인트는 **답을 만들지 않는다**는 것. 다른 모드는 전부
/// `식 하나 → 답 하나`(키패드로 입력하거나 후보 중 정답을 탭)인데, 여기서는
/// 좌우 접시에 식이 하나씩 올라가고 아이는 둘의 **대소 관계**만 고른다:
/// `>` / `=` / `<`. 정확히 계산하지 않아도 어림으로 판단할 수 있어 어림셈
/// 모드와 결이 이어지고, 수감각(어느 쪽이 더 큰가)을 직접 다룬다.
///
/// 라운드 = 비교 1개. 사용자 행동:
///
/// - **정답 관계 탭** → 점수 +1, 콤보 +1.
/// - **오답 관계 탭** → 콤보 끊김 + HP -1.
///
/// 정오답 어느 쪽이든 저울이 **실제 정답 방향으로 기울며** 잠깐 공개된 뒤
/// 다음 라운드로 넘어간다. 오답일 때 같은 문제를 재도전시키지 않는 이유는
/// 선택지가 3개뿐이라 재도전이 곧 찍기가 되기 때문 — 대신 공개 시간을 길게
/// 줘서 "아, 이쪽이 더 컸구나"를 보고 넘어가게 한다.
///
/// 난이도는 [ProblemGenerator.balancePair]가 [solved] 를 받아 좌우 답의 차이
/// 폭을 좁히는 방식으로 올라간다. 종료 조건은 HP 0 또는 [totalSeconds] 도달 —
/// 다른 액션 모드와 동일. 점수는 맞힌 비교 수([solved]).
class BalanceGameController extends GetxController {
  static const int maxHp = 3;
  static const int totalSeconds = 60;

  /// 정답 공개(저울이 기울어 있는) 시간. 맞혔을 때는 짧게 끊어 리듬을 살리고,
  /// 틀렸을 때는 정답 관계를 눈으로 확인할 시간을 더 준다.
  static const int revealCorrectMs = 750;
  static const int revealWrongMs = 1300;

  /// 선택 없음을 뜻하는 [selected] 센티널. 관계 코드가 -1/0/1 이라 범위 밖의
  /// 값을 써야 한다.
  static const int noSelection = -9;

  final SfxService _sfx = Get.find();
  final ActionScoreService _scores = Get.find();

  static const ActionConcept concept = ActionConcept.balance;

  // 진입 선택 화면 인자.
  late final GameType? gameType;
  late final int digitsA;
  late final int digitsB;

  final RxInt hp = maxHp.obs;
  final RxInt solved = 0.obs; // 맞힌 비교 수 = 점수
  final RxInt combo = 0.obs;
  final RxBool isGameOver = false.obs;
  final RxBool isNewBest = false.obs;
  final RxInt elapsed = 0.obs;

  late final Rx<BalancePair> pair;

  /// 정답 공개 중인지. true 동안 저울이 정답 방향으로 기울고 버튼은 잠긴다.
  final RxBool revealed = false.obs;

  /// 사용자가 고른 관계(-1/0/1) 또는 [noSelection].
  final RxInt selected = noSelection.obs;

  /// 마지막 선택의 정오. 버튼 색(초록/빨강)에 쓰인다.
  final RxBool lastCorrect = false.obs;

  Timer? _secondTimer;
  bool _locked = false;
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
    pair = _generatePair().obs;
    _startSecondTimer();
  }

  BalancePair _generatePair() => ProblemGenerator.balancePair(
    type: gameType,
    digitsA: digitsA,
    digitsB: digitsB,
    solved: solved.value,
  );

  // ───── 입력 ────────────────────────────────────────────────────────────────

  /// [relation] 은 `1`(왼쪽이 큼) / `0`(같음) / `-1`(오른쪽이 큼).
  void onChoiceTap(int relation) {
    if (isGameOver.value || _locked) return;
    final correct = relation == pair.value.relation;

    _locked = true;
    selected.value = relation;
    lastCorrect.value = correct;
    revealed.value = true;

    if (correct) {
      _sfx.correct();
      solved.value += 1;
      combo.value += 1;
    } else {
      _sfx.wrong();
      combo.value = 0;
      _loseHp();
      if (isGameOver.value) return;
    }

    final wait = correct ? revealCorrectMs : revealWrongMs;
    _delay(Duration(milliseconds: wait), () {
      _locked = false;
      revealed.value = false;
      selected.value = noSelection;
      pair.value = _generatePair();
    });
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
    _scores.report(concept, solved.value).then((v) => isNewBest.value = v);
  }

  void restart() {
    hp.value = maxHp;
    solved.value = 0;
    combo.value = 0;
    elapsed.value = 0;
    isGameOver.value = false;
    isNewBest.value = false;
    _locked = false;
    revealed.value = false;
    selected.value = noSelection;
    _cancelPending();
    pair.value = _generatePair();
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
