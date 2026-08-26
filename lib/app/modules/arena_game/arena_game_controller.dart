import 'dart:async';
import 'dart:math';

import 'package:get/get.dart';

import '../../data/models/action_concept.dart';
import '../../data/models/arena_upgrade.dart';
import '../../data/models/game_type.dart';
import '../../data/models/problem.dart';
import '../../data/services/action_score_service.dart';
import '../../data/services/problem_generator.dart';
import '../../data/services/sfx_service.dart';

/// 아레나 컨트롤러 — 웨이브 생존형("서바이버라이크") 모델.
///
/// 기존 액션 7종은 전부 **한 판 = 고정 60초**의 평평한 구조라 "얼마나 오래
/// 버텼나"라는 축이 없었다. 아레나는 그 축을 연다: 웨이브를 하나씩 깨며
/// 올라가고, 웨이브마다 적이 늘고 제한시간이 줄어 **언젠가는 반드시 진다.**
/// 목표는 클리어가 아니라 최고 웨이브 갱신이다.
///
/// 한 웨이브 = 적 [enemiesLeft] 마리를 제한시간 안에 처치. 문제 하나가 공격
/// 한 번이고, 3지선다에서 정답을 고르면 적 하나가 쓰러진다.
///
/// - **정답** → 적 -1, 점수 +[baseScore] × 콤보 배수 (빠르면 크리티컬 보너스).
/// - **오답** → 방어막이 있으면 소모, 없으면 HP -1. 콤보 리셋, 적은 그대로.
/// - **시간 초과** → HP -1 후 같은 웨이브를 새 적으로 재시작.
/// - **웨이브 클리어** → 강화 카드 3장 중 1장 선택([upgradeOptions]) 후 다음 웨이브.
///
/// [bossEvery] 웨이브마다는 보스전이다. 적이 한 마리뿐이지만 HP가 여러 칸이라
/// 연속으로 맞혀야 하고, 대신 시간이 [bossExtraSeconds] 만큼 더 주어진다.
/// 웨이브 구성이 "잔몹 → 잔몹 → 보스"로 반복돼야 리듬이 생긴다.
///
/// 종료는 HP 0뿐 — 전체 제한시간은 없다(웨이브 타이머가 그 역할을 한다).
/// 점수는 누적 점수이고 [ActionScoreService]에 best로 기록된다.
class ArenaGameController extends GetxController {
  static const ActionConcept concept = ActionConcept.arena;

  static const int startingHp = 3;

  /// 강화([ArenaUpgrade.heal])로 올라갈 수 있는 하트 상한. 시작 HP보다 높게
  /// 둬서 "회복" 카드가 후반에도 의미를 갖게 한다.
  static const int maxHp = 5;

  static const int baseScore = 10;

  /// 문제가 뜨고 [critMs] 안에 맞히면 붙는 보너스. 정확도만이 아니라 속도도
  /// 보상해 리듬을 만든다.
  static const int critBonus = 5;
  static const int critMs = 2000;

  /// 보스 웨이브 주기와 보너스.
  static const int bossEvery = 3;
  static const int bossExtraSeconds = 6;
  static const int bossBonus = 50;

  static const int normalChoiceCount = 3;
  static const int reducedChoiceCount = 2;

  /// 정오답 연출 시간. 틀렸을 때 정답을 눈으로 확인할 시간을 조금 더 준다.
  static const int revealCorrectMs = 450;
  static const int revealWrongMs = 900;

  /// 웨이브 클리어 → 강화 카드가 뜨기까지의 짧은 승리 연출.
  static const int waveClearMs = 700;

  /// 한 번에 제시하는 강화 카드 수.
  static const int upgradeChoiceCount = 3;

  final SfxService _sfx = Get.find();
  final ActionScoreService _scores = Get.find();
  final Random _rng = Random();

  // 진입 선택 화면 인자.
  late final GameType? gameType;
  late final int digitsA;
  late final int digitsB;

  final RxInt hp = startingHp.obs;
  final RxInt wave = 1.obs;
  final RxInt score = 0.obs;
  final RxInt combo = 0.obs;
  final RxInt bestCombo = 0.obs;
  final RxInt enemiesLeft = 0.obs;
  final RxInt waveEnemyTotal = 0.obs;
  final RxInt waveRemaining = 0.obs;

  /// 이번 웨이브에 주어진 총 시간(강화로 늘어난 몫 포함). 뷰가 남은 시간과
  /// 견주어 "적이 얼마나 다가왔는지"를 그린다 — 시간 압박을 숫자가 아니라
  /// 위치로 보여 주기 위해 필요하다.
  final RxInt waveTotalSeconds = 0.obs;
  final RxBool isGameOver = false.obs;
  final RxBool isNewBest = false.obs;

  /// 방어막(오답 1회 무효) 보유 여부.
  final RxBool hasShield = false.obs;

  /// 현재 문제와 보기. 보기는 정답 1 + 오답 n-1 을 섞은 것.
  late final Rx<Problem> currentProblem;
  final RxList<int> choices = <int>[].obs;

  /// 강화 선택 중이면 타이머가 멈추고 입력이 잠긴다.
  final RxBool isChoosingUpgrade = false.obs;
  final RxList<ArenaUpgrade> upgradeOptions = <ArenaUpgrade>[].obs;

  /// 방금 고른 강화 — 다음 웨이브 배너에 "⚡ 점수 2배 적용 중"으로 띄운다.
  final Rxn<ArenaUpgrade> activeUpgrade = Rxn<ArenaUpgrade>();

  /// 웨이브 시작 연출용. 값이 바뀔 때마다 뷰가 "WAVE n" 배너를 다시 띄운다.
  /// 배너는 입력을 막지 않는다 — 6~9세에게 못 누르는 시간은 길게 느껴진다.
  final RxInt waveBannerTick = 0.obs;

  /// 피격 연출(화면 흔들림)용 카운터. 값이 바뀌면 뷰가 흔들기를 재생한다.
  final RxInt hitTick = 0.obs;

  /// 마지막 정답으로 얻은 점수와 그 팝업 트리거. `+35` 같은 플로팅 텍스트.
  final RxInt lastGain = 0.obs;
  final RxBool lastGainWasCrit = false.obs;
  final RxInt gainTick = 0.obs;

  /// 선택 직후 짧게 잠기는 구간(연출 재생 중). 연타 방지도 겸한다.
  final RxBool revealing = false.obs;
  final RxInt selectedChoice = _noSelection.obs;
  final RxBool lastCorrect = false.obs;

  static const int _noSelection = -1 << 30;

  // 다음 웨이브 한 판에만 적용되는 강화 효과.
  bool _doubleScoreNextWave = false;
  bool _extraTimeNextWave = false;
  bool _fewerChoicesNextWave = false;

  // 현재 웨이브에 적용 중인 효과.
  bool _doubleScoreActive = false;
  bool _fewerChoicesActive = false;

  Timer? _secondTimer;
  final List<Timer> _pending = [];
  final Stopwatch _questionWatch = Stopwatch();
  bool _locked = false;

  bool get isBossWave => isBossWaveNumber(wave.value);
  static bool isBossWaveNumber(int wave) => wave % bossEvery == 0;

  /// 콤보 배수 — 5연속부터 ×2, 10연속부터 ×3. 콤보가 끊기면 즉시 1로.
  int get comboMultiplier {
    if (combo.value >= 10) return 3;
    if (combo.value >= 5) return 2;
    return 1;
  }

  /// 점수 배수(콤보 × 강화). 뷰의 HUD가 "×4" 처럼 그대로 보여준다.
  int get scoreMultiplier => comboMultiplier * (_doubleScoreActive ? 2 : 1);

  int get choiceCount =>
      _fewerChoicesActive ? reducedChoiceCount : normalChoiceCount;

  /// 웨이브의 잔몹 수. 2웨이브마다 한 마리씩 늘고 8마리에서 멈춘다 — 더 늘리면
  /// 한 웨이브가 지루하게 길어진다. 보스 웨이브는 항상 "한 마리"다.
  static int enemiesForWave(int wave) {
    if (isBossWaveNumber(wave)) return 1;
    return (3 + (wave - 1) ~/ 2).clamp(3, 8);
  }

  /// 보스 HP — 보스전을 거듭할수록 한 칸씩 두꺼워진다.
  static int bossHpForWave(int wave) => 3 + (wave ~/ bossEvery) - 1;

  /// 웨이브 제한시간. 웨이브마다 1초씩 줄어들되 12초 밑으로는 안 내려간다
  /// (그 아래로는 읽고 계산할 시간 자체가 부족해 실력과 무관해진다).
  /// 보스 웨이브는 HP만큼 더 맞혀야 하므로 [bossExtraSeconds] 를 더 준다.
  static int secondsForWave(int wave) {
    final base = (22 - (wave - 1)).clamp(12, 22);
    return isBossWaveNumber(wave) ? base + bossExtraSeconds : base;
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
    _startWave(1);
    _startSecondTimer();
  }

  // ───── 웨이브 ──────────────────────────────────────────────────────────────

  void _startWave(int n) {
    wave.value = n;
    // 지난 웨이브에서 고른 카드의 효과를 이번 웨이브에 태운다.
    _doubleScoreActive = _doubleScoreNextWave;
    _fewerChoicesActive = _fewerChoicesNextWave;
    final extra = _extraTimeNextWave ? 5 : 0;
    _doubleScoreNextWave = false;
    _fewerChoicesNextWave = false;
    _extraTimeNextWave = false;

    final total = isBossWaveNumber(n) ? bossHpForWave(n) : enemiesForWave(n);
    waveEnemyTotal.value = total;
    enemiesLeft.value = total;
    waveTotalSeconds.value = secondsForWave(n) + extra;
    waveRemaining.value = waveTotalSeconds.value;
    waveBannerTick.value++;
    _nextProblem();
  }

  /// 제한시간 초과 — 하트를 하나 잃고 같은 웨이브를 새 적으로 다시 시작한다.
  /// 웨이브를 되돌리지 않는 이유: 아이 입장에서 "7웨이브까지 갔다가 5로
  /// 떨어짐"은 벌이 너무 무겁게 느껴진다.
  void _onWaveTimeout() {
    _sfx.wrong();
    combo.value = 0;
    _loseHp();
    if (isGameOver.value) return;
    _startWave(wave.value);
  }

  void _onWaveCleared() {
    _sfx.finish();
    if (isBossWave) score.value += bossBonus;
    _locked = true;
    _delay(const Duration(milliseconds: waveClearMs), () {
      _locked = false;
      upgradeOptions.assignAll(_rollUpgrades());
      isChoosingUpgrade.value = true;
    });
  }

  /// 카드 풀에서 무작위 [upgradeChoiceCount] 장. 하트가 가득이면 회복 카드는
  /// 후보에서 빼고(꽝을 뽑게 만들지 않는다), 방어막을 이미 들고 있으면 방어막도
  /// 뺀다. 후보가 모자라면 있는 만큼만 제시한다.
  List<ArenaUpgrade> _rollUpgrades() {
    final pool = ArenaUpgrade.values.where((u) {
      if (u == ArenaUpgrade.heal && hp.value >= maxHp) return false;
      if (u == ArenaUpgrade.shield && hasShield.value) return false;
      return true;
    }).toList()..shuffle(_rng);
    return pool.take(upgradeChoiceCount).toList();
  }

  /// 강화 카드 선택 → 효과 적용 후 다음 웨이브 시작.
  void chooseUpgrade(ArenaUpgrade upgrade) {
    if (!isChoosingUpgrade.value || isGameOver.value) return;
    _sfx.click();
    switch (upgrade) {
      case ArenaUpgrade.doubleScore:
        _doubleScoreNextWave = true;
      case ArenaUpgrade.heal:
        hp.value = (hp.value + 1).clamp(0, maxHp);
      case ArenaUpgrade.extraTime:
        _extraTimeNextWave = true;
      case ArenaUpgrade.shield:
        hasShield.value = true;
      case ArenaUpgrade.fewerChoices:
        _fewerChoicesNextWave = true;
    }
    activeUpgrade.value = upgrade;
    isChoosingUpgrade.value = false;
    upgradeOptions.clear();
    _startWave(wave.value + 1);
  }

  // ───── 문제 / 입력 ─────────────────────────────────────────────────────────

  Problem _generateProblem() => ProblemGenerator.generateOneForDigits(
    type: gameType,
    digitsA: digitsA,
    digitsB: digitsB,
  );

  void _nextProblem() {
    final p = _generateProblem();
    currentProblem.value = p;
    choices.assignAll(_buildChoices(p.answer));
    selectedChoice.value = _noSelection;
    _questionWatch
      ..reset()
      ..start();
  }

  /// 보기 = 정답 1 + 오답 n-1. 오답은 **같은 자릿수 조합으로 새로 만든 문제의
  /// 답**에서 뽑는다(물고기 잡기와 동일한 방식) — 크기대가 비슷해야 찍기가
  /// 어렵다. 그래도 안 모이면 정답 ±1, ±2… 근접값으로 채운다.
  List<int> _buildChoices(int correct) {
    final want = choiceCount;
    final picked = <int>{correct};
    var tries = 0;
    while (picked.length < want && tries < 40) {
      tries++;
      final p = _generateProblem();
      if (p.answer >= 0 && p.answer != correct) picked.add(p.answer);
    }
    for (var delta = 1; picked.length < want && delta <= 20; delta++) {
      if (correct - delta >= 0) picked.add(correct - delta);
      if (picked.length < want) picked.add(correct + delta);
    }
    return picked.take(want).toList()..shuffle(_rng);
  }

  void onChoiceTap(int value) {
    if (isGameOver.value || _locked || isChoosingUpgrade.value) return;
    _questionWatch.stop();
    final correct = value == currentProblem.value.answer;

    _locked = true;
    revealing.value = true;
    selectedChoice.value = value;
    lastCorrect.value = correct;

    if (correct) {
      _onCorrect();
      if (enemiesLeft.value <= 0) {
        // 웨이브 클리어 — 연출 후 강화 카드로.
        revealing.value = false;
        _onWaveCleared();
        return;
      }
    } else {
      _onWrong();
      if (isGameOver.value) return;
    }

    _delay(Duration(milliseconds: correct ? revealCorrectMs : revealWrongMs),
        () {
      _locked = false;
      revealing.value = false;
      _nextProblem();
    });
  }

  void _onCorrect() {
    _sfx.correct();
    combo.value += 1;
    if (combo.value > bestCombo.value) bestCombo.value = combo.value;
    if (combo.value >= 3 && combo.value % 3 == 0) _sfx.combo();

    final crit = _questionWatch.elapsedMilliseconds <= critMs;
    final gain = baseScore * scoreMultiplier + (crit ? critBonus : 0);
    score.value += gain;
    lastGain.value = gain;
    lastGainWasCrit.value = crit;
    gainTick.value++;
    enemiesLeft.value -= 1;
  }

  void _onWrong() {
    _sfx.wrong();
    combo.value = 0;
    if (hasShield.value) {
      // 방어막이 막아 준다 — 하트는 그대로. 흔들림도 생략해 "막았다"는 느낌을
      // 시각적으로 구분한다.
      hasShield.value = false;
      return;
    }
    hitTick.value++;
    _loseHp();
  }

  void _loseHp() {
    hp.value -= 1;
    if (hp.value <= 0) {
      hp.value = 0;
      _gameOver();
    }
  }

  // ───── 타이머 / 종료 ───────────────────────────────────────────────────────

  void _startSecondTimer() {
    _secondTimer?.cancel();
    _secondTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      // 연출 중(_locked)에는 시계를 세운다. 정답을 보여 주는 사이에 시간이
      // 다 되어 하트를 잃으면 아이 입장에선 이유를 알 수 없는 벌이 된다.
      if (isGameOver.value || isChoosingUpgrade.value || _locked) return;
      if (waveRemaining.value <= 0) return;
      waveRemaining.value -= 1;
      if (waveRemaining.value <= 3 && waveRemaining.value > 0) _sfx.tick();
      if (waveRemaining.value <= 0) _onWaveTimeout();
    });
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

  void _gameOver() {
    isGameOver.value = true;
    _secondTimer?.cancel();
    _secondTimer = null;
    _cancelPending();
    _questionWatch.stop();
    isChoosingUpgrade.value = false;
    _sfx.finish();
    _scores.report(concept, score.value).then((v) => isNewBest.value = v);
  }

  void restart() {
    hp.value = startingHp;
    score.value = 0;
    combo.value = 0;
    bestCombo.value = 0;
    hasShield.value = false;
    isGameOver.value = false;
    isNewBest.value = false;
    isChoosingUpgrade.value = false;
    upgradeOptions.clear();
    activeUpgrade.value = null;
    revealing.value = false;
    selectedChoice.value = _noSelection;
    _locked = false;
    _doubleScoreNextWave = false;
    _extraTimeNextWave = false;
    _fewerChoicesNextWave = false;
    _doubleScoreActive = false;
    _fewerChoicesActive = false;
    _cancelPending();
    _startWave(1);
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
