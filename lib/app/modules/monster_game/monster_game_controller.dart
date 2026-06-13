import 'dart:async';
import 'dart:math';

import 'package:get/get.dart';

import '../../data/models/game_type.dart';
import '../../data/models/problem.dart';
import '../../data/services/problem_generator.dart';
import '../../data/services/sfx_service.dart';

/// 몬스터 처치 MVP 컨트롤러.
///
/// 셀렉트 화면에서 받은 (gameType, digitsA, digitsB)로 매 라운드 한 문제씩
/// 생성한다. 몬스터 한 마리 == 문제 한 개. 정답이면 처치 후 다음 몬스터,
/// 오답이거나 몬스터가 바닥에 닿으면 HP -1. HP 0이 되면 게임오버.
///
/// 낙하 애니메이션 자체는 View 측 [AnimationController]가 담당하고, 이 컨트롤러는
/// 매 새 라운드에 [spawnTrigger]를 증가시켜 View가 트윈을 reset/forward 하도록
/// 신호만 보낸다. 게임 로직과 화면 애니메이션을 분리해 두면 컨트롤러는
/// vsync 없이 순수 상태 머신으로 유지된다.
///
/// MVP 단계이므로 `GameRecord` 저장은 하지 않는다. SFX/햅틱은 기존
/// [SfxService]를 그대로 활용.
class MonsterGameController extends GetxController {
  static const int maxHp = 3;
  static const int maxInputLength = 6;

  // 첫 몬스터 8초 → kills마다 200ms씩 줄어 4초에 수렴. 어린이 사용자가
  // 점진적 압박감을 느끼되 후반에 비현실적으로 빨라지지 않도록 클램프.
  static const int initialFallMs = 8000;
  static const int minFallMs = 4000;
  static const int fallStepMs = 200;

  // 매 몬스터마다 ±[fallJitterPct]% 범위에서 랜덤 보정. 같은 kills 단계에서도
  // 한 마리는 약간 빠르고 한 마리는 약간 느리게 떨어져 단조로움을 줄이고
  // 6~9세 사용자가 "다음 몬스터는 얼마나 빠를까?"라는 작은 긴장감을 갖게 한다.
  // jitter는 한 번 굴려서 캐시(_fallMs)하므로, 뷰가 같은 라운드에서 currentFallMs를
  // 여러 번 읽어도 항상 동일 값을 본다.
  static const int fallJitterPct = 20;
  // jitter가 너무 큰 음수로 작용할 때(예: minFallMs 부근 -20%)에도 사용자가
  // 풀 시간이 보장되도록 절대 하한선.
  static const int fallFloorMs = 2500;

  // 세션 전체 제한 시간(초). 60초가 지나면 HP가 남아 있어도 게임오버.
  // HP 소진과 별도의 종료 조건이라, 빠른 처치를 유도하는 추가 압박감 역할.
  static const int totalSeconds = 60;

  // 정답 1개당 추가되는 보너스 시간(초). 누적으로 [bonusSeconds]에 합산돼
  // [remainingSeconds]를 늘린다.
  static const int correctBonusSeconds = 10;

  final SfxService _sfx = Get.find();

  // 셀렉트 화면 인자 — null 이면 무작위 연산.
  late final GameType? gameType;
  late final int digitsA;
  late final int digitsB;

  final RxInt hp = maxHp.obs;
  final RxInt kills = 0.obs;
  final RxInt combo = 0.obs;
  final RxString answer = ''.obs;
  final RxBool isGameOver = false.obs;
  late final Rx<Problem> current;

  // 경과 초. 매 초 +1 되며 [totalSeconds] + [bonusSeconds] 도달 시 자동 게임오버.
  final RxInt elapsed = 0.obs;
  // 정답으로 누적된 보너스 시간(초). 매 정답마다 [correctBonusSeconds]씩 증가.
  final RxInt bonusSeconds = 0.obs;
  Timer? _timer;

  // 현재 라운드 낙하 시간(ms). [_rollFallMs]로 매 spawn마다 갱신.
  int _fallMs = initialFallMs;
  final Random _rng = Random();

  int get remainingSeconds {
    final r = totalSeconds + bonusSeconds.value - elapsed.value;
    return r < 0 ? 0 : r;
  }

  // 매 새 몬스터마다 1씩 증가. View가 ever()로 듣고 낙하 트윈을 재시작한다.
  // Problem.value 비교만으로는 동일 문제 연속 생성 시 변화를 못 잡으므로
  // 명시적 트리거로 둔다.
  final RxInt spawnTrigger = 0.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      gameType = args['gameType'] as GameType?;
      digitsA = (args['digitsA'] as int?) ?? 1;
      digitsB = (args['digitsB'] as int?) ?? 1;
    } else {
      // 직접 라우팅(셀렉트 미경유) 폴백 — 가장 쉬운 설정으로.
      gameType = GameType.addition;
      digitsA = 1;
      digitsB = 1;
    }
    current = _generate().obs;
    _fallMs = _rollFallMs();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (isGameOver.value) return;
      elapsed.value += 1;
      if (remainingSeconds <= 0) _gameOver();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  int get currentFallMs => _fallMs;

  /// 결정론적 base(`initialFallMs - kills*fallStepMs`, `minFallMs`로 클램프)에
  /// ±[fallJitterPct]% 랜덤 지터를 더한 1회용 낙하 시간을 굴린다. 마지막에
  /// [fallFloorMs]로 안전 하한 적용. 매 [_spawnNext] / [onInit] / [restart]에서
  /// 한 번씩 호출돼 _fallMs에 캐시된다.
  int _rollFallMs() {
    final base = initialFallMs - kills.value * fallStepMs;
    final clamped = base < minFallMs ? minFallMs : base;
    final jitterRange = (clamped * fallJitterPct / 100).round();
    final jitter = jitterRange == 0
        ? 0
        : _rng.nextInt(jitterRange * 2 + 1) - jitterRange;
    final rolled = clamped + jitter;
    return rolled < fallFloorMs ? fallFloorMs : rolled;
  }

  Problem _generate() {
    return ProblemGenerator.generateOneForDigits(
      type: gameType,
      digitsA: digitsA,
      digitsB: digitsB,
    );
  }

  void _spawnNext() {
    answer.value = '';
    current.value = _generate();
    _fallMs = _rollFallMs();
    spawnTrigger.value += 1;
  }

  // ───── 입력 처리 ─────────────────────────────────────────────────────────
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
    if (parsed == current.value.answer) {
      _onCorrect();
    } else {
      _onWrong();
    }
  }

  void _onCorrect() {
    _sfx.correct();
    kills.value += 1;
    combo.value += 1;
    bonusSeconds.value += correctBonusSeconds;
    _spawnNext();
  }

  void _onWrong() {
    _sfx.wrong();
    combo.value = 0;
    _loseHp();
    // 같은 몬스터가 계속 낙하하면 1마리에서 HP를 여러 번 잃을 수 있어 6~9세
    // 사용자에게 과하게 가혹하다. 오답도 바닥 도달과 동일하게 "이 몬스터는
    // 실패" 처리 후 다음 몬스터로 넘긴다 — 한 마리당 최대 -1 HP로 일관.
    if (!isGameOver.value) _spawnNext();
  }

  /// View에서 낙하 애니메이션이 끝났을 때 호출. 콤보 끊김 + HP 1 차감 후
  /// 게임오버가 아니면 다음 몬스터 출현.
  void onMonsterReachedBottom() {
    if (isGameOver.value) return;
    combo.value = 0;
    _loseHp();
    if (!isGameOver.value) _spawnNext();
  }

  void _loseHp() {
    hp.value -= 1;
    if (hp.value <= 0) {
      hp.value = 0;
      _gameOver();
    }
  }

  void _gameOver() {
    isGameOver.value = true;
    _stopTimer();
    _sfx.finish();
  }

  // ───── 게임오버 오버레이 액션 ────────────────────────────────────────────
  void restart() {
    hp.value = maxHp;
    kills.value = 0;
    combo.value = 0;
    elapsed.value = 0;
    bonusSeconds.value = 0;
    isGameOver.value = false;
    _spawnNext();
    _startTimer();
  }

  void exitToHome() {
    Get.back();
  }

  @override
  void onClose() {
    _stopTimer();
    super.onClose();
  }
}
