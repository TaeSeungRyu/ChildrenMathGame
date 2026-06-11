import 'dart:async';
import 'dart:math';

import 'package:get/get.dart';

import '../../data/models/game_type.dart';
import '../../data/models/problem.dart';
import '../../data/services/problem_generator.dart';
import '../../data/services/sfx_service.dart';

/// 타워 디펜스 컨트롤러 — 다중 타겟 + 답 매칭 모델.
///
/// A(몬스터 처치)와의 차별화 포인트는 "동시에 여러 문제를 보고 어느 것을 풀지
/// 선택"한다는 것. 화면에 떠 있는 모든 몬스터가 각자 자기 문제를 머리 위에 들고
/// 있고, 사용자가 키패드로 어떤 답을 입력해 "입력"을 누르면 **그 답을 가진
/// 몬스터** 중 가장 성에 가까운 한 마리가 처치된다. 같은 답을 가진 몬스터가
/// 없으면 오답 처리(성 HP -1).
///
/// 즉 게임 리듬이 "지금 들이닥치는 한 문제를 빨리 풀기"(A) 에서 "전장의 답들을
/// 훑어보고 어느 것부터 풀지 고르기"(C) 로 바뀐다. 같은 키패드 입력 UI 위에서도
/// 풀이 순서를 사용자가 결정한다는 점에서 의사 결정의 결이 다르다.
///
/// 3개의 가로 차로(lane) 에 몬스터들이 무작위로 스폰돼 시각적 복잡도도 함께
/// 올린다 — 그래도 6~9세가 따라갈 수 있도록 한 차로당 동시 등장 수는 캡.
class TowerDefenseController extends GetxController {
  static const int maxHp = 3;
  static const int maxInputLength = 6;
  static const int totalSeconds = 60;

  // 차로(lane) 수. 화면이 3개 가로 띠로 나뉘고 몬스터는 자기 차로 안에서만
  // 행진한다. 6~9세에게 4 차로 이상은 시각적 부담이 큰 것으로 판단해 3으로 고정.
  static const int laneCount = 3;

  // 한 차로에 동시에 떠 있을 수 있는 최대 몬스터 수. 이걸 넘으면 그 차로 스폰은
  // 스킵해 화면이 한 줄로 몰리는 걸 방지한다.
  static const int maxMonstersPerLane = 3;

  // 행진 시간 — 처치 수가 늘수록 짧아져 압박감 증가. 한 화면에 여러 마리가
  // 동시에 진행되므로 A(단일 낙하) 보다 약간 길게 잡아 사용자가 다중 문제를
  // 머리에서 처리할 시간을 준다.
  static const int initialTravelMs = 14000;
  static const int minTravelMs = 8500;
  static const int travelStepMs = 250;

  // 스폰 간격 — 차로가 3개이므로 같은 간격이면 화면이 빨리 가득 찬다.
  // A 보다 살짝 여유.
  static const int initialSpawnIntervalMs = 2800;
  static const int minSpawnIntervalMs = 1500;
  static const int spawnIntervalStepMs = 130;

  // 처치 시 "마법 발사 → 폭발" 비주얼 동안 몬스터를 리스트에 남겨두는 시간.
  // 너무 짧으면 이펙트가 안 보이고, 길면 사용자가 같은 답으로 다음 행동을 못 한다.
  static const int defeatDurationMs = 380;

  final SfxService _sfx = Get.find();
  final Random _rng = Random();

  late final GameType? gameType;
  late final int digitsA;
  late final int digitsB;

  final RxInt hp = maxHp.obs;
  final RxInt kills = 0.obs;
  final RxInt combo = 0.obs;
  final RxString answer = ''.obs;
  final RxBool isGameOver = false.obs;
  final RxInt elapsed = 0.obs;

  // 화면 위 모든 몬스터(살아 있는 것 + 처치 이펙트 재생 중인 것). 후자는
  // [TowerMonster.hitAtMs]가 non-null. View 는 살아 있는 몬스터는 정상 sprite,
  // hit 된 몬스터는 폭발 이펙트로 그린다.
  final RxList<TowerMonster> monsters = <TowerMonster>[].obs;

  int _sessionElapsedMs = 0;
  int get sessionElapsedMs => _sessionElapsedMs;

  Timer? _secondTimer;
  Timer? _spawnTimer;
  int _nextMonsterId = 1;

  int get remainingSeconds {
    final r = totalSeconds - elapsed.value;
    return r < 0 ? 0 : r;
  }

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
    // 첫 몬스터는 즉시. 두 번째부터는 스폰 간격에 맞춰.
    _spawnMonster();
    _scheduleNextSpawn();
    _startSecondTimer();
  }

  // ───── View → Controller 프레임 콜백 ───────────────────────────────────────

  void onFrame(int ms) {
    _sessionElapsedMs = ms;
  }

  /// 몬스터가 성에 도달했을 때 View 가 호출. 처치 이펙트가 재생 중인(=`hitAtMs`
  /// 가 set 된) 몬스터는 좌표가 freeze 돼 있어 이 콜백이 다시 발생하지 않는다.
  void onMonsterReachCastle(int id) {
    if (isGameOver.value) return;
    final idx = monsters.indexWhere((m) => m.id == id);
    if (idx < 0) return;
    final m = monsters[idx];
    if (m.hitAtMs != null) return; // 이미 처치 이펙트 중 — 중복 처리 방지.
    monsters.removeAt(idx);
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

    // 살아 있는(=처치 이펙트 재생 중이 아닌) 매칭 몬스터들 중 성에 가장 가까운
    // 한 마리를 우선 처치. 동일 답이 여러 마리 있는 흔치 않은 경우라도, "가장
    // 위급한 위협부터 제거" 라는 자연스러운 의사 결정 결과가 나온다.
    final candidates = monsters
        .where((m) => m.hitAtMs == null && m.problem.answer == parsed)
        .toList();
    if (candidates.isEmpty) {
      _onWrong();
      return;
    }
    candidates.sort((a, b) {
      final pa = (_sessionElapsedMs - a.spawnMs) / a.travelMs;
      final pb = (_sessionElapsedMs - b.spawnMs) / b.travelMs;
      return pb.compareTo(pa); // 진행도 큰 순(=성에 가까운 순)
    });
    _onCorrect(candidates.first);
  }

  void _onCorrect(TowerMonster target) {
    _sfx.correct();
    kills.value += 1;
    combo.value += 1;
    answer.value = '';
    // 처치 이펙트가 재생되는 동안 좌표를 freeze 하기 위해 hitAtMs 를 박는다.
    // View 는 hitAtMs 가 있으면 (sessionElapsedMs - spawnMs) 대신 (hitAtMs -
    // spawnMs) 를 써서 위치를 고정한 채 스케일/페이드 애니메이션을 입힌다.
    target.hitAtMs = _sessionElapsedMs;
    monsters.refresh();
    Timer(const Duration(milliseconds: defeatDurationMs), () {
      if (isGameOver.value) return;
      monsters.removeWhere((m) => m.id == target.id);
    });
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
    // 차로 별 살아 있는 몬스터 수를 세어 [maxMonstersPerLane]을 넘긴 차로는 후보에서 제외.
    // 모두 가득이면 스킵 — 다음 [_scheduleNextSpawn] 사이클에서 다시 시도한다.
    final perLane = List<int>.filled(laneCount, 0);
    for (final m in monsters) {
      if (m.hitAtMs == null) perLane[m.laneIndex] += 1;
    }
    final available = <int>[
      for (var i = 0; i < laneCount; i++)
        if (perLane[i] < maxMonstersPerLane) i,
    ];
    if (available.isEmpty) return;
    final lane = available[_rng.nextInt(available.length)];

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
        laneIndex: lane,
        emoji: _pickEmoji(),
      ),
    );
  }

  // 단조로움을 줄이기 위해 몬스터 외형을 약간씩 섞는다.
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
/// View 가 [hitAtMs] 가 null 이면 (sessionElapsedMs - spawnMs)/travelMs 로 x를
/// 계산해 정상 행진을 그리고, non-null 이면 그 시점에서 좌표를 freeze 한 채로
/// 폭발 이펙트(스케일 업 + 페이드 아웃)를 그린다. [hitAtMs] 는 처치 시점에
/// 한 번 set 되고 [TowerDefenseController.defeatDurationMs] 후 몬스터 자체가
/// 리스트에서 제거된다.
class TowerMonster {
  TowerMonster({
    required this.id,
    required this.problem,
    required this.spawnMs,
    required this.travelMs,
    required this.laneIndex,
    required this.emoji,
    this.hitAtMs,
  });

  final int id;
  final Problem problem;
  final int spawnMs;
  final int travelMs;
  final int laneIndex;
  final String emoji;

  /// 처치 시점의 sessionElapsedMs. null = 살아 있음. 의도적으로 mutable 로
  /// 두어 컨트롤러가 RxList 안의 객체를 그 자리에서 갱신하고 `refresh()` 로
  /// View에 통보한다 — 매번 새 인스턴스로 copy 하는 비용을 피하기 위함.
  int? hitAtMs;
}
