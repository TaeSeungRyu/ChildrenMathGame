import 'dart:async';
import 'dart:math';

import 'package:get/get.dart';

import '../../data/models/game_type.dart';
import '../../data/models/problem.dart';
import '../../data/services/problem_generator.dart';
import '../../data/services/sfx_service.dart';

/// 두더지 잡기 컨트롤러 — 객관식 망치질 모델.
///
/// A/B/C 와의 차별화 포인트는 **키패드가 없다**는 것. 상단에 한 문제가 큰 글씨로
/// 떠 있고, 3×3 구멍에서 두더지들이 자기 등에 "답 후보 숫자"를 들고 잠시
/// 튀어나왔다 사라진다. 사용자는 정답이 적힌 두더지만 망치로 탭하면 됨.
///
/// - **A**: 키패드로 답 입력 + 단일 낙하 몬스터
/// - **B**: 키패드 X — 답이 일치하는 풍선 탭
/// - **C**: 키패드 + 다중 마칭 + 답 매칭
/// - **D**: 키패드 X + 객관식 후보 중 정답 탭 + 그리드 + 반응속도
///
/// 라운드 = 문제 1개. 라운드 시작 시 1개의 정답 + (K-1)개의 오답 후보가
/// 시간차로 등장해 각자 [_lifespanMs] 동안 보였다 다시 들어간다. 사용자 행동:
///
/// - **정답 두더지 탭** → 처치 + 콤보 +1 → 즉시 다음 라운드.
/// - **오답 두더지 탭** → 콤보 끊김 + HP -1, 그 두더지만 사라지고 라운드는 계속.
/// - **정답 두더지가 못 본 채 다시 들어감** → 콤보 끊김 + HP -1, 라운드 실패로
///   처리하고 다음 라운드로 강제 전환.
///
/// 종료 조건은 HP 0 또는 [totalSeconds] 도달 — 다른 액션 모드와 동일.
class MoleGameController extends GetxController {
  static const int maxHp = 3;
  static const int totalSeconds = 60;

  /// 3×3 그리드. 칸 수를 더 늘리면 6~9세 아동의 시야 스캔 범위를 벗어나
  /// 정답을 놓치기 쉬워진다. 9가 적정선이라 판단.
  static const int gridSize = 9;

  /// 처치 이펙트(망치 애니메이션) 지속 시간. 너무 길면 다음 라운드 전환이
  /// 답답하고, 너무 짧으면 임팩트감이 사라진다.
  static const int hammerAnimMs = 320;

  final SfxService _sfx = Get.find();
  final Random _rng = Random();

  // 셀렉트 화면 인자.
  late final GameType? gameType;
  late final int digitsA;
  late final int digitsB;

  final RxInt hp = maxHp.obs;
  final RxInt kills = 0.obs;
  final RxInt combo = 0.obs;
  final RxInt round = 1.obs;
  final RxBool isGameOver = false.obs;
  final RxInt elapsed = 0.obs;

  // 현재 라운드의 문제. View 의 상단 배너가 이걸 보고 표시.
  late final Rx<Problem> currentProblem;

  // gridSize 길이의 슬롯 — 각 칸은 비어 있거나 두더지 한 마리. RxList 로 두고
  // 한 칸 갱신 시 [refresh] 로 View 에 통보한다.
  final RxList<Mole?> moles =
      RxList<Mole?>.filled(gridSize, null, growable: false);

  int _sessionElapsedMs = 0;
  int get sessionElapsedMs => _sessionElapsedMs;

  Timer? _secondTimer;
  // 라운드 내에서 스폰 예약된 두더지의 Timer 목록. 라운드가 끝날 때 일괄 취소
  // — 그렇지 않으면 이전 라운드의 두더지가 새 문제 위로 튀어나오는 버그 발생.
  final List<Timer> _pendingSpawnTimers = [];
  // 탭/만료 이후 두더지를 제거하는 Timer 도 라운드 전환에서 정리.
  final List<Timer> _pendingRemovalTimers = [];

  int _nextMoleId = 1;
  // 라운드 단조로움을 막기 위해 같은 라운드에서 정답 두더지가 두 번 처리되지
  // 않도록 가드 — 정답 탭 → 라운드 전환 사이의 짧은 시간 동안 또 탭이 들어와도
  // 무시한다.
  bool _roundResolved = false;

  int get remainingSeconds {
    final r = totalSeconds - elapsed.value;
    return r < 0 ? 0 : r;
  }

  /// 라운드별 (두더지 총 수, 등장 간격 ms, 두더지 한 마리 lifespan ms).
  /// 처음엔 후보 3개·간격 600·생존 2200, 라운드가 올라갈수록 더 많은 후보가
  /// 더 빨리 등장하고 더 짧게 보인다. 너무 가혹해지지 않도록 캡.
  ({int count, int staggerMs, int lifespanMs}) _roundConfig(int r) {
    final count = (3 + (r - 1) ~/ 3).clamp(3, 5); // 3,3,3,4,4,4,5,5,...
    final staggerMs = (600 - (r - 1) * 30).clamp(300, 600);
    final lifespanMs = (2200 - (r - 1) * 80).clamp(1400, 2200);
    return (count: count, staggerMs: staggerMs, lifespanMs: lifespanMs);
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
    _startSecondTimer();
    _startRound();
  }

  Problem _generateProblem() {
    return ProblemGenerator.generateOneForDigits(
      type: gameType,
      digitsA: digitsA,
      digitsB: digitsB,
    );
  }

  // ───── View → Controller 프레임 콜백 ───────────────────────────────────────

  /// View 의 Ticker 가 매 프레임 호출. 컨트롤러는 (1) 세션 경과 ms 캐시,
  /// (2) lifespan 을 넘긴 두더지 자동 제거를 처리한다. 자동 제거에서 정답
  /// 두더지가 빠져나가면 라운드 실패로 처리.
  void onFrame(int ms) {
    _sessionElapsedMs = ms;
    if (isGameOver.value) return;
    if (_roundResolved) return;

    var dirty = false;
    bool roundFailed = false;
    for (var i = 0; i < gridSize; i++) {
      final m = moles[i];
      if (m == null) continue;
      if (m.hammeredMs != null) continue; // 망치 애니메이션 진행 중 — Timer 가 정리.
      if (ms - m.appearedMs >= m.lifespanMs) {
        if (m.isCorrect) {
          roundFailed = true;
        }
        moles[i] = null;
        dirty = true;
      }
    }
    if (dirty) moles.refresh();
    if (roundFailed) {
      _roundResolved = true;
      _sfx.wrong();
      combo.value = 0;
      _loseHp();
      if (!isGameOver.value) {
        // 약간의 텀을 두고 다음 라운드 — 즉시 전환하면 사용자가 "내가 놓쳤구나"
        // 라는 자각 없이 새 문제로 넘어가 학습 피드백이 흐려진다.
        _scheduleRemoval(const Duration(milliseconds: 250), _startRound);
      }
    }
  }

  // ───── 입력 ────────────────────────────────────────────────────────────────

  void onMoleTap(int holeIndex) {
    if (isGameOver.value) return;
    if (_roundResolved) return;
    if (holeIndex < 0 || holeIndex >= gridSize) return;
    final m = moles[holeIndex];
    if (m == null) return;
    if (m.hammeredMs != null) return; // 이미 망치질 중

    m.hammeredMs = _sessionElapsedMs;
    moles.refresh();

    if (m.isCorrect) {
      _sfx.correct();
      kills.value += 1;
      combo.value += 1;
      _roundResolved = true;
      // 망치 애니메이션이 끝난 뒤 다음 라운드로.
      _scheduleRemoval(
        const Duration(milliseconds: hammerAnimMs),
        _startRound,
      );
    } else {
      _sfx.wrong();
      combo.value = 0;
      _loseHp();
      if (isGameOver.value) return;
      // 오답 두더지만 제거, 라운드는 계속.
      _scheduleRemoval(
        const Duration(milliseconds: hammerAnimMs),
        () {
          if (holeIndex < gridSize && moles[holeIndex]?.id == m.id) {
            moles[holeIndex] = null;
            moles.refresh();
          }
        },
      );
    }
  }

  void _scheduleRemoval(Duration d, void Function() action) {
    // late: 콜백 본문이 자신을 참조하는 self-reference. 타이머 인스턴스를
    // 먼저 만들고 콜백에 캡처해야 하므로 forward-declare.
    late final Timer t;
    t = Timer(d, () {
      _pendingRemovalTimers.removeWhere((x) => identical(x, t));
      if (isGameOver.value) return;
      action();
    });
    _pendingRemovalTimers.add(t);
  }

  void _loseHp() {
    hp.value -= 1;
    if (hp.value <= 0) {
      hp.value = 0;
      _gameOver();
    }
  }

  // ───── 라운드 ──────────────────────────────────────────────────────────────

  void _startRound() {
    _cancelPendingSpawns();
    _cancelPendingRemovals();
    for (var i = 0; i < gridSize; i++) {
      moles[i] = null;
    }
    moles.refresh();
    currentProblem.value = _generateProblem();
    _roundResolved = false;
    final cfg = _roundConfig(round.value);
    round.value += 1;

    // 후보 답 셋: 정답 1 + (count-1) 디코이.
    final answers = <int>{currentProblem.value.answer};
    var tries = 0;
    while (answers.length < cfg.count && tries < 60) {
      tries++;
      final decoy = _generateDecoy(currentProblem.value.answer);
      if (decoy != null) answers.add(decoy);
    }
    final ordered = answers.toList()..shuffle(_rng);
    final correctAnswer = currentProblem.value.answer;

    // 시간차 스폰 — 등장 위치는 매번 빈 칸 중 무작위.
    for (var i = 0; i < ordered.length; i++) {
      final number = ordered[i];
      final isCorrect = number == correctAnswer;
      final delay = Duration(milliseconds: i * cfg.staggerMs);
      late final Timer t;
      t = Timer(delay, () {
        _pendingSpawnTimers.removeWhere((x) => identical(x, t));
        if (isGameOver.value) return;
        if (_roundResolved) return;
        _spawnMole(number: number, isCorrect: isCorrect, lifespanMs: cfg.lifespanMs);
      });
      _pendingSpawnTimers.add(t);
    }
  }

  void _spawnMole({
    required int number,
    required bool isCorrect,
    required int lifespanMs,
  }) {
    final empty = <int>[
      for (var i = 0; i < gridSize; i++) if (moles[i] == null) i,
    ];
    if (empty.isEmpty) return; // 매우 드문 경우 — 그리드가 다 찼으면 스킵.
    final hole = empty[_rng.nextInt(empty.length)];
    moles[hole] = Mole(
      id: _nextMoleId++,
      number: number,
      isCorrect: isCorrect,
      holeIndex: hole,
      appearedMs: _sessionElapsedMs,
      lifespanMs: lifespanMs,
    );
    moles.refresh();
  }

  /// 디코이 후보 답 생성. 현재 (gameType, digitsA, digitsB) 로 같은 종류의
  /// 문제를 한 번 생성해 그 답을 가져온다 — 디코이도 "그럴듯한" 숫자 영역에
  /// 머물게 해 게임의 학습 효과를 유지. 답이 [correct] 와 같으면 거부.
  int? _generateDecoy(int correct) {
    final p = ProblemGenerator.generateOneForDigits(
      type: gameType,
      digitsA: digitsA,
      digitsB: digitsB,
    );
    if (p.answer == correct) return null;
    if (p.answer < 0) return null;
    return p.answer;
  }

  void _cancelPendingSpawns() {
    for (final t in _pendingSpawnTimers) {
      t.cancel();
    }
    _pendingSpawnTimers.clear();
  }

  void _cancelPendingRemovals() {
    for (final t in _pendingRemovalTimers) {
      t.cancel();
    }
    _pendingRemovalTimers.clear();
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
    _cancelPendingSpawns();
    _cancelPendingRemovals();
    _sfx.finish();
  }

  // ───── 게임오버 오버레이 액션 ──────────────────────────────────────────────

  void restart() {
    hp.value = maxHp;
    kills.value = 0;
    combo.value = 0;
    round.value = 1;
    elapsed.value = 0;
    isGameOver.value = false;
    _sessionElapsedMs = 0;
    _roundResolved = false;
    _cancelPendingSpawns();
    _cancelPendingRemovals();
    for (var i = 0; i < gridSize; i++) {
      moles[i] = null;
    }
    moles.refresh();
    currentProblem.value = _generateProblem();
    _startSecondTimer();
    _startRound();
  }

  void exitToHome() {
    Get.back();
  }

  @override
  void onClose() {
    _secondTimer?.cancel();
    _cancelPendingSpawns();
    _cancelPendingRemovals();
    super.onClose();
  }
}

/// 한 칸에 등장한 두더지.
///
/// View 는 (sessionElapsedMs - appearedMs) / lifespanMs 로 등장 진행도를 계산해
/// pop-up(올라옴) → 정지 → 들어감 시퀀스를 그린다. [hammeredMs] 가 set 되면
/// 망치 애니메이션 모드 — 정상 pop-up 진행도를 무시하고 그 시점부터
/// [MoleGameController.hammerAnimMs] 동안 망치 + 두더지 squash 이펙트를 표시.
class Mole {
  Mole({
    required this.id,
    required this.number,
    required this.isCorrect,
    required this.holeIndex,
    required this.appearedMs,
    required this.lifespanMs,
    this.hammeredMs,
  });

  final int id;
  final int number;
  final bool isCorrect;
  final int holeIndex;
  final int appearedMs;
  final int lifespanMs;
  int? hammeredMs;
}
