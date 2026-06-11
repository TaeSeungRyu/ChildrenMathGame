import 'dart:async';
import 'dart:math';

import 'package:get/get.dart';

import '../../data/models/game_type.dart';
import '../../data/models/problem.dart';
import '../../data/services/problem_generator.dart';
import '../../data/services/sfx_service.dart';

/// 타워 디펜스 MVP 컨트롤러.
///
/// 몬스터들이 오른쪽 끝에서 등장해 왼쪽 성을 향해 행진한다. 한 문제는 가장
/// 앞(=성에 가장 가까운, 큐의 head) 몬스터가 들고 있고, 그 문제만 상단의
/// 고정 배너에 크게 표시된다. 사용자가 답을 입력하고 "입력"을 누르면 항상
/// **선두 몬스터**가 공격 대상이 된다 — 6~9세 사용자가 "어느 몬스터를 풀어야
/// 하지?" 헷갈리지 않도록 의도적으로 단순화. 선두를 처치하면 그 뒤의 몬스터가
/// 자동으로 새 선두가 되어 같은 자리에서 새 문제가 드러난다.
///
/// 위치/속도 같은 프레임 단위 정보는 View 측 [Ticker]가 다루고, 컨트롤러는
/// 큐와 스폰 타이밍·HP·콤보 같은 상태 머신만 유지한다.
class TowerDefenseController extends GetxController {
  static const int maxHp = 3;
  static const int maxInputLength = 6;
  // 몬스터 모드/풍선 모드와 같은 1분 세션 캡.
  static const int totalSeconds = 60;

  // ── 몬스터 행진 시간(ms). 오른쪽 끝에서 성까지 가는 데 걸리는 시간. 처치 수가
  //    늘수록 줄어들어 압박감이 점진적으로 증가. minTravelMs로 너무 가혹해지지
  //    않게 하한선을 둔다.
  static const int initialTravelMs = 12000;
  static const int minTravelMs = 7000;
  static const int travelStepMs = 250;

  // ── 다음 몬스터를 스폰하기까지의 간격(ms). 처치 수에 따라 점점 짧아져 화면에
  //    동시에 떠 있는 몬스터 수가 자연스럽게 늘어난다.
  static const int initialSpawnIntervalMs = 3500;
  static const int minSpawnIntervalMs = 1800;
  static const int spawnIntervalStepMs = 150;

  final SfxService _sfx = Get.find();
  final Random _rng = Random();

  // 셀렉트 화면 인자.
  late final GameType? gameType;
  late final int digitsA;
  late final int digitsB;

  final RxInt hp = maxHp.obs;
  final RxInt kills = 0.obs;
  final RxInt combo = 0.obs;
  final RxString answer = ''.obs;
  final RxBool isGameOver = false.obs;
  final RxInt elapsed = 0.obs;

  // 큐 — index 0 이 항상 "선두"(성에 가장 가까운) 몬스터.
  // RxList 인 이유: 추가/제거가 모두 View 의 Stack 자식 목록과 상단 배너의
  // 활성 문제 텍스트를 동시에 갱신해야 하기 때문.
  final RxList<TowerMonster> monsters = <TowerMonster>[].obs;

  // 세션 시작 시점 기준 ms. 몬스터 스폰 시 [TowerMonster.spawnMs]에 저장돼,
  // View 의 Ticker 가 (sessionElapsedMs - monster.spawnMs) / monster.travelMs
  // 로 각 몬스터의 진행도를 계산한다.
  int _sessionElapsedMs = 0;
  int get sessionElapsedMs => _sessionElapsedMs;

  // 세션 1초 카운트다운 타이머와, 다음 몬스터 스폰까지의 지연 타이머. 후자는
  // Timer.periodic 이 아니라 단일 Timer 를 연쇄적으로 재예약 — 매번 최신 간격을
  // 반영해야 하므로 periodic 으로는 표현할 수 없다.
  Timer? _secondTimer;
  Timer? _spawnTimer;

  int _nextMonsterId = 1;

  /// 현재 선두 몬스터. View 의 활성 배너/링 표시에 쓰인다.
  TowerMonster? get activeMonster =>
      monsters.isEmpty ? null : monsters.first;

  int get remainingSeconds {
    final r = totalSeconds - elapsed.value;
    return r < 0 ? 0 : r;
  }

  /// 현재 처치 수에 맞는 1회용 행진 시간(ms). 스폰 시점에 캐시되어 몬스터마다
  /// 고정 — 같은 라운드 안에서 늦게 스폰된 몬스터가 일찍 스폰된 것보다 빨라지는
  /// 일관성 깨짐을 피한다.
  int currentTravelMs() {
    final v = initialTravelMs - kills.value * travelStepMs;
    return v < minTravelMs ? minTravelMs : v;
  }

  int _currentSpawnIntervalMs() {
    final v = initialSpawnIntervalMs - kills.value * spawnIntervalStepMs;
    return v < minSpawnIntervalMs ? minSpawnIntervalMs : v;
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
    // 첫 몬스터는 게임 시작과 동시에 즉시 스폰 — 사용자가 빈 화면을 보지 않게.
    _spawnMonster();
    _scheduleNextSpawn();
    _startSecondTimer();
  }

  // ───── View → Controller 프레임 콜백 ───────────────────────────────────────

  /// View 의 Ticker 가 매 프레임 호출. [ms]는 세션 시작 시점 기준 경과 ms.
  /// 컨트롤러는 이 값을 캐시해 두고 몬스터 스폰 시 spawnMs 기준으로 사용한다.
  void onFrame(int ms) {
    _sessionElapsedMs = ms;
  }

  /// View 가 몬스터가 성에 도달했다고 알려줄 때 호출.
  void onMonsterReachCastle(int id) {
    if (isGameOver.value) return;
    final idx = monsters.indexWhere((m) => m.id == id);
    if (idx < 0) return;
    monsters.removeAt(idx);
    // 콤보 끊김 + 성 HP -1. 선두가 도달했든 후방이 어떤 이유로 먼저 도달했든
    // 동일하게 처리(MVP 에선 모든 몬스터가 같은 속도라 사실상 선두만 해당).
    combo.value = 0;
    _sfx.wrong();
    _loseHp();
  }

  // ───── 입력 처리 ──────────────────────────────────────────────────────────

  void appendDigit(String d) {
    if (isGameOver.value) return;
    if (answer.value.length >= maxInputLength) return;
    answer.value = answer.value + d;
    _sfx.click();
  }

  void deleteLast() {
    if (isGameOver.value) return;
    if (answer.value.isEmpty) return;
    answer.value = answer.value.substring(0, answer.value.length - 1);
    _sfx.click();
  }

  void submit() {
    if (isGameOver.value) return;
    if (answer.value.isEmpty) return;
    final parsed = int.tryParse(answer.value);
    if (parsed == null) return;
    final target = activeMonster;
    if (target == null) {
      // 화면에 몬스터가 한 마리도 없는 짧은 순간(첫 스폰 직전 등) — 무시.
      answer.value = '';
      return;
    }
    if (parsed == target.problem.answer) {
      _onCorrect(target);
    } else {
      _onWrong();
    }
  }

  void _onCorrect(TowerMonster target) {
    _sfx.correct();
    kills.value += 1;
    combo.value += 1;
    answer.value = '';
    monsters.removeWhere((m) => m.id == target.id);
  }

  void _onWrong() {
    _sfx.wrong();
    combo.value = 0;
    answer.value = '';
    _loseHp();
  }

  void _loseHp() {
    hp.value -= 1;
    if (hp.value <= 0) {
      hp.value = 0;
      _gameOver();
    }
  }

  // ───── 스폰 / 타이머 ───────────────────────────────────────────────────────

  void _spawnMonster() {
    final problem = ProblemGenerator.generateOneForDigits(
      type: gameType,
      digitsA: digitsA,
      digitsB: digitsB,
    );
    monsters.add(
      TowerMonster(
        id: _nextMonsterId++,
        problem: problem,
        spawnMs: _sessionElapsedMs,
        travelMs: currentTravelMs(),
        emoji: _pickEmoji(),
      ),
    );
  }

  // 단조로움을 줄이기 위해 몬스터 외형을 약간씩 섞는다 — 6~9세 사용자가
  // 시각적으로 한 마리 한 마리를 구분해 인지할 수 있게.
  static const _emojis = ['👹', '👺', '👻', '🧟', '🦇'];
  String _pickEmoji() => _emojis[_rng.nextInt(_emojis.length)];

  void _scheduleNextSpawn() {
    _spawnTimer?.cancel();
    _spawnTimer = Timer(
      Duration(milliseconds: _currentSpawnIntervalMs()),
      () {
        if (isGameOver.value) return;
        _spawnMonster();
        _scheduleNextSpawn();
      },
    );
  }

  void _startSecondTimer() {
    _secondTimer?.cancel();
    _secondTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (isGameOver.value) return;
      elapsed.value += 1;
      if (elapsed.value >= totalSeconds) _gameOver();
    });
  }

  void _stopAllTimers() {
    _secondTimer?.cancel();
    _secondTimer = null;
    _spawnTimer?.cancel();
    _spawnTimer = null;
  }

  void _gameOver() {
    isGameOver.value = true;
    _stopAllTimers();
    _sfx.finish();
  }

  // ───── 게임오버 오버레이 액션 ──────────────────────────────────────────────

  void restart() {
    hp.value = maxHp;
    kills.value = 0;
    combo.value = 0;
    answer.value = '';
    elapsed.value = 0;
    isGameOver.value = false;
    monsters.clear();
    _sessionElapsedMs = 0;
    _spawnMonster();
    _scheduleNextSpawn();
    _startSecondTimer();
  }

  void exitToHome() {
    Get.back();
  }

  @override
  void onClose() {
    _stopAllTimers();
    super.onClose();
  }
}

/// 행진 중인 몬스터 한 마리.
///
/// 위치는 View 가 (sessionElapsedMs - spawnMs) / travelMs 로 계산해 그린다.
/// progress ≥ 1.0 이 되면 성에 도달 — View 가 한 번만
/// [TowerDefenseController.onMonsterReachCastle]을 호출하도록 가드해야 한다.
class TowerMonster {
  TowerMonster({
    required this.id,
    required this.problem,
    required this.spawnMs,
    required this.travelMs,
    required this.emoji,
  });

  final int id;
  final Problem problem;
  final int spawnMs;
  final int travelMs;
  final String emoji;
}
