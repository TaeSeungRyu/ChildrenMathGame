import 'dart:async';
import 'dart:math';

import 'package:get/get.dart';

import '../../data/models/game_type.dart';
import '../../data/models/problem.dart';
import '../../data/services/problem_generator.dart';
import '../../data/services/sfx_service.dart';

/// 물고기 잡기 컨트롤러 — 객관식 "움직이는 타겟" 모델.
///
/// 두더지 잡기(3×3 구멍에서 팝업)의 객관식 구조를 **가로로 헤엄치는 물고기**로
/// 옮긴 것. 상단에 한 문제가 크게 떠 있고, 여러 마리의 물고기가 각자 등에 답
/// 후보 숫자를 달고 화면을 좌↔우로 가로질러 헤엄친다. 사용자는 정답이 적힌
/// 물고기만 탭해서 낚으면 됨.
///
/// 라운드 = 문제 1개. 라운드 시작 시 1마리의 정답 + (K-1)마리의 오답 후보가
/// 시간차로 등장해 각자 [durationMs] 동안 화면을 가로지른다. 사용자 행동:
///
/// - **정답 물고기 탭** → 낚음 + 콤보 +1 → 즉시 다음 라운드.
/// - **오답 물고기 탭** → 콤보 끊김 + HP -1, 그 물고기만 사라지고 라운드는 계속.
/// - **정답 물고기가 못 낚인 채 화면을 벗어남** → 콤보 끊김 + HP -1, 라운드
///   실패로 처리하고 다음 라운드로 강제 전환. (오답 물고기가 나가는 건 무패널티.)
///
/// 종료 조건은 HP 0 또는 [totalSeconds] 도달 — 다른 액션 모드와 동일.
///
/// 좌표계는 **정규화(0..1)** 로 다뤄 View 의 실제 픽셀 폭/높이에 의존하지 않는다.
/// 물고기의 가로 진행도는 `(sessionElapsedMs - appearedMs) / durationMs` 로
/// 계산되고, View 가 이걸 가용 폭에 매핑한다. 컨트롤러는 진행도 1.0(완전히
/// 화면 밖) 을 벗어남 판정에만 쓴다.
class FishingGameController extends GetxController {
  static const int maxHp = 3;
  static const int totalSeconds = 60;

  /// 낚기 이펙트(낚싯바늘 + ✨) 지속 시간. 두더지의 hammerAnimMs 와 같은 역할.
  static const int catchAnimMs = 340;

  /// 물고기가 헤엄칠 세로 레인 수. 후보 물고기가 최대 5마리이므로 5레인이면
  /// 한 마리씩 겹치지 않는 레인을 배정할 수 있다.
  static const int lanes = 5;

  final SfxService _sfx = Get.find();
  final Random _rng = Random();

  // 셀렉트 화면 인자.
  late final GameType? gameType;
  late final int digitsA;
  late final int digitsB;

  final RxInt hp = maxHp.obs;
  final RxInt catches = 0.obs;
  final RxInt combo = 0.obs;
  final RxInt round = 1.obs;
  final RxBool isGameOver = false.obs;
  final RxInt elapsed = 0.obs;

  // 현재 라운드의 문제. View 상단 배너가 이걸 보고 표시.
  late final Rx<Problem> currentProblem;

  // 화면에서 헤엄치는 물고기들. add/remove 로 갱신하면 Obx 가 재빌드.
  final RxList<Fish> fishes = <Fish>[].obs;

  int _sessionElapsedMs = 0;
  int get sessionElapsedMs => _sessionElapsedMs;

  Timer? _secondTimer;
  // 라운드 내에서 스폰 예약된 물고기 Timer 목록. 라운드 전환/종료 때 일괄 취소
  // — 그렇지 않으면 이전 라운드의 물고기가 새 문제 위로 등장하는 버그 발생.
  final List<Timer> _pendingSpawnTimers = [];
  // 낚기/오답 이펙트 뒤 물고기를 제거하거나 다음 라운드로 넘어가는 Timer.
  final List<Timer> _pendingRemovalTimers = [];

  int _nextFishId = 1;
  // 정답 처리 ~ 라운드 전환 사이의 짧은 시간 동안 또 탭이 들어와도 무시.
  bool _roundResolved = false;

  int get remainingSeconds {
    final r = totalSeconds - elapsed.value;
    return r < 0 ? 0 : r;
  }

  /// 라운드별 (물고기 총 수, 등장 간격 ms, 한 마리가 화면을 가로지르는 ms).
  /// 처음엔 후보 3마리·간격 700·횡단 4200ms(느긋), 라운드가 오를수록 더 많은
  /// 후보가 더 빨리 등장하고 더 빠르게 헤엄친다. 너무 가혹해지지 않도록 캡.
  ({int count, int staggerMs, int durationMs}) _roundConfig(int r) {
    final count = (3 + (r - 1) ~/ 3).clamp(3, lanes); // 3,3,3,4,4,4,5,...
    final staggerMs = (700 - (r - 1) * 30).clamp(400, 700);
    final durationMs = (4200 - (r - 1) * 180).clamp(2400, 4200);
    return (count: count, staggerMs: staggerMs, durationMs: durationMs);
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

  /// View 의 Ticker 가 매 프레임 호출. 세션 경과 ms 를 캐시하고, 화면을 완전히
  /// 벗어난(진행도 ≥ 1) 물고기를 제거한다. 정답 물고기가 못 낚인 채 벗어나면
  /// 라운드 실패로 처리.
  void onFrame(int ms) {
    _sessionElapsedMs = ms;
    if (isGameOver.value) return;
    if (_roundResolved) return;

    var dirty = false;
    var roundFailed = false;
    fishes.removeWhere((f) {
      if (f.hookedMs != null) return false; // 낚기/이펙트 진행 중 — Timer 가 정리.
      final progress = (ms - f.appearedMs) / f.durationMs;
      if (progress >= 1.0) {
        if (f.isCorrect) roundFailed = true;
        dirty = true;
        return true;
      }
      return false;
    });
    if (dirty) fishes.refresh();
    if (roundFailed) {
      _roundResolved = true;
      _sfx.wrong();
      combo.value = 0;
      _loseHp();
      if (!isGameOver.value) {
        // 살짝 텀을 두고 다음 라운드 — 즉시 전환하면 "놓쳤구나" 자각 없이
        // 새 문제로 넘어가 학습 피드백이 흐려진다.
        _scheduleRemoval(const Duration(milliseconds: 300), _startRound);
      }
    }
  }

  // ───── 입력 ────────────────────────────────────────────────────────────────

  void onFishTap(int id) {
    if (isGameOver.value) return;
    if (_roundResolved) return;
    final i = fishes.indexWhere((f) => f.id == id);
    if (i < 0) return;
    final f = fishes[i];
    if (f.hookedMs != null) return; // 이미 낚는 중

    f.hookedMs = _sessionElapsedMs;
    fishes.refresh();

    if (f.isCorrect) {
      _sfx.correct();
      catches.value += 1;
      combo.value += 1;
      _roundResolved = true;
      // 낚기 이펙트가 끝난 뒤 다음 라운드로.
      _scheduleRemoval(
        const Duration(milliseconds: catchAnimMs),
        _startRound,
      );
    } else {
      _sfx.wrong();
      combo.value = 0;
      _loseHp();
      if (isGameOver.value) return;
      // 오답 물고기만 제거, 라운드는 계속.
      _scheduleRemoval(const Duration(milliseconds: catchAnimMs), () {
        fishes.removeWhere((x) => x.id == f.id);
        fishes.refresh();
      });
    }
  }

  void _scheduleRemoval(Duration d, void Function() action) {
    // late: 콜백이 자신을 참조하는 self-reference. 타이머 인스턴스를 먼저 만들고
    // 콜백에 캡처해야 하므로 forward-declare.
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
    fishes.clear();
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
    // 레인은 겹치지 않게 섞어서 배정 — 정답 물고기 레인을 예측 못하게.
    final laneOrder = List<int>.generate(lanes, (i) => i)..shuffle(_rng);

    // 시간차 스폰.
    for (var i = 0; i < ordered.length; i++) {
      final number = ordered[i];
      final isCorrect = number == correctAnswer;
      final lane = laneOrder[i % lanes];
      final delay = Duration(milliseconds: i * cfg.staggerMs);
      late final Timer t;
      t = Timer(delay, () {
        _pendingSpawnTimers.removeWhere((x) => identical(x, t));
        if (isGameOver.value) return;
        if (_roundResolved) return;
        _spawnFish(
          number: number,
          isCorrect: isCorrect,
          lane: lane,
          durationMs: cfg.durationMs,
        );
      });
      _pendingSpawnTimers.add(t);
    }
  }

  void _spawnFish({
    required int number,
    required bool isCorrect,
    required int lane,
    required int durationMs,
  }) {
    // 레인 중심을 정규화 y 로. 위/아래 가장자리를 조금 피하도록 lane+0.5 배치.
    final laneY = (lane + 0.5) / lanes;
    // 횡단 시간에 ±300ms 지터를 줘 물고기들이 기계적으로 같은 속도로 줄지어
    // 가지 않게 한다. 라운드 캡(2400) 아래로는 안 내려가게 보정.
    final jitter = _rng.nextInt(600) - 300;
    final dur = (durationMs + jitter).clamp(2000, 6000);
    fishes.add(
      Fish(
        id: _nextFishId++,
        number: number,
        isCorrect: isCorrect,
        laneY: laneY,
        ltr: _rng.nextBool(),
        appearedMs: _sessionElapsedMs,
        durationMs: dur,
      ),
    );
    fishes.refresh();
  }

  /// 디코이 후보 답 생성. 현재 (gameType, digitsA, digitsB) 로 같은 종류의 문제를
  /// 한 번 생성해 그 답을 가져온다 — 디코이도 "그럴듯한" 숫자 영역에 머물게 해
  /// 학습 효과를 유지. 답이 [correct] 와 같거나 음수면 거부.
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
    catches.value = 0;
    combo.value = 0;
    round.value = 1;
    elapsed.value = 0;
    isGameOver.value = false;
    _sessionElapsedMs = 0;
    _roundResolved = false;
    _cancelPendingSpawns();
    _cancelPendingRemovals();
    fishes.clear();
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

/// 화면을 가로질러 헤엄치는 물고기 한 마리.
///
/// View 는 `(sessionElapsedMs - appearedMs) / durationMs` 로 횡단 진행도(0..1)를
/// 계산해 가로 위치를 그린다. [ltr] 이면 좌→우, 아니면 우→좌. [laneY] 는 세로
/// 위치(0=상단, 1=하단)의 정규화 값. [hookedMs] 가 set 되면 낚기 이펙트 모드 —
/// 정상 횡단을 멈추고 그 시점부터 [FishingGameController.catchAnimMs] 동안 정답이면
/// 낚싯바늘로 끌어올림 + ✨, 오답이면 ❌ 이펙트를 표시.
class Fish {
  Fish({
    required this.id,
    required this.number,
    required this.isCorrect,
    required this.laneY,
    required this.ltr,
    required this.appearedMs,
    required this.durationMs,
    this.hookedMs,
  });

  final int id;
  final int number;
  final bool isCorrect;
  final double laneY;
  final bool ltr;
  final int appearedMs;
  final int durationMs;
  int? hookedMs;
}
