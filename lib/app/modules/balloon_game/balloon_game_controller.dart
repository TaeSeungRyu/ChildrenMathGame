import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/game_type.dart';
import '../../data/models/problem.dart';
import '../../data/services/problem_generator.dart';
import '../../data/services/sfx_service.dart';

/// 풍선 터뜨리기 MVP 컨트롤러.
///
/// 라운드 단위 게임. 라운드마다 "목표 답"이 정해지고, 화면 위로 풍선 N개가
/// 천천히 떠오른다. 풍선 중 일부는 답이 [targetAnswer]와 같은 정답 풍선,
/// 나머지는 오답(디코이) 풍선이다.
///
/// 라운드 진행:
/// 1. [_startRound]가 목표 답과 풍선 세트를 한 번에 만들고 [balloons]에 넣는다.
/// 2. View 가 매 프레임 [Balloon.progress]를 계산해 화면에 그린다(0=바닥, 1=상단).
/// 3. 사용자가 풍선을 탭하면 [onBalloonTap] — 정답이면 처치/콤보 +1, 오답이면 HP -1.
/// 4. 풍선이 상단을 빠져나가면 View가 [onBalloonEscape]를 호출.
///    정답 풍선이 빠져나가면 -1 HP, 디코이는 그냥 사라진다.
/// 5. 모든 풍선이 사라지면(터지거나 빠져나가면) 다음 라운드.
///
/// 종료 조건은 HP 0 또는 [totalSeconds]초 경과 — 몬스터 모드와 동일한
/// 60초 세션 캡으로 한 판이 무한정 늘어지지 않게 한다. 현재 단계에서는
/// `GameRecord` 저장은 하지 않고, 게임오버 오버레이로 다시/홈 분기만 제공.
class BalloonGameController extends GetxController {
  static const int maxHp = 3;
  // 몬스터 모드와 동일한 1분 세션 캡. 풍선이 천천히 떠오르는 만큼 시간이
  // 너무 길면 어린이 사용자의 집중이 흐트러진다.
  static const int totalSeconds = 60;

  // 라운드별 풍선 수 / 정답 풍선 수 / 떠오르는 시간(ms). 라운드가 올라갈수록
  // 풍선 수와 정답 비중이 같이 늘고 속도도 빨라진다. minFloatMs로 5초 미만은
  // 차단해 어린이가 풀 수 없을 정도로 가혹해지지 않도록 한다.
  static const int initialFloatMs = 10000;
  static const int minFloatMs = 5500;
  static const int floatStepMs = 600;

  // 정답이 1개 미만이면 라운드가 즉시 끝나버려 게임감이 깨진다. 최소 1개 보장.
  static const int minMatching = 1;

  // 탭 시 정답/오답 이펙트가 보여지는 시간(ms). 풍선이 리스트에 잠시 남아 있다
  // 이펙트가 끝나면 제거된다 — 너무 길면 다음 풍선 탭이 답답하고 너무 짧으면
  // 이펙트가 눈에 안 들어온다.
  static const int popDurationMs = 380;

  final SfxService _sfx = Get.find();
  final Random _rng = Random();

  // 셀렉트 화면 인자.
  late final GameType? gameType;
  late final int digitsA;
  late final int digitsB;

  final RxInt hp = maxHp.obs;
  final RxInt pops = 0.obs; // 누적 정답 풍선 처치 수
  final RxInt combo = 0.obs;
  final RxInt round = 1.obs;
  final RxInt targetAnswer = 0.obs;
  final RxBool isGameOver = false.obs;
  final RxInt elapsed = 0.obs;

  // 현재 라운드의 풍선들. 풍선이 처리되면(터지거나 빠져나가면) 리스트에서 제거.
  final RxList<Balloon> balloons = <Balloon>[].obs;

  // View가 매 프레임 listen 해 현재 라운드의 풍선 위치를 갱신할 신호.
  // 라운드가 새로 시작할 때 1씩 증가시켜 View 측 [AnimationController]를
  // 0부터 다시 시작시킨다.
  final RxInt roundTrigger = 0.obs;

  Timer? _timer;
  int _nextBalloonId = 1;

  // 현재 라운드의 풍선 떠오르는 시간(ms).
  int _floatMs = initialFloatMs;

  int get currentFloatMs => _floatMs;

  // View 의 Ticker 가 매 프레임 [onFrame] 으로 갱신하는 세션 경과 ms. 풍선을
  // 탭/만료할 때 poppedAtMs 에 이 값을 박아 두면 View 는 그 시점의 위치를
  // freeze 한 채 이펙트 애니메이션을 그릴 수 있다.
  int _sessionElapsedMs = 0;
  int get sessionElapsedMs => _sessionElapsedMs;

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
    _startRound();
    _startTimer();
  }

  // ───── 라운드 ─────────────────────────────────────────────────────────────

  /// 라운드별 (총 풍선 수, 정답 풍선 수, 떠오르는 시간 ms).
  ({int total, int matching, int floatMs}) _roundConfig(int r) {
    final total = (4 + r).clamp(5, 9); // 5,6,7,8,9 …→ 9에서 캡
    // 정답 풍선은 라운드 1=2개, 2=2개, 3=3개, 4=3개, 5+=4개. 총 풍선 수보다는
    // 항상 적게.
    final matching = (1 + (r + 1) ~/ 2).clamp(minMatching, total - 1);
    final floatBase = initialFloatMs - (r - 1) * floatStepMs;
    final floatMs = floatBase < minFloatMs ? minFloatMs : floatBase;
    return (total: total, matching: matching, floatMs: floatMs);
  }

  void _startRound() {
    final cfg = _roundConfig(round.value);
    _floatMs = cfg.floatMs;

    final primary = _buildMatchingSet(cfg.matching);
    targetAnswer.value = primary.first.answer;

    final decoys = _buildDecoys(cfg.total - primary.length, primary.first.answer);

    // 진짜 풍선 수가 줄어든 경우에도 콤보·점수 흐름은 그대로 유지. _buildMatchingSet이
    // matchCount 보다 적게 반환할 수 있으므로(자릿수 조합 때문에 추가 합성에 실패한 경우)
    // 별도 안내 없이 자연스럽게 진행.
    final all = [...primary, ...decoys];
    all.shuffle(_rng);

    // 진입 딜레이를 분산해 풍선들이 한꺼번에 같은 높이로 떠오르지 않도록 한다.
    // 첫 풍선 0, 마지막 풍선 floatMs/2 까지 균등 분포. 동시에 너무 많은 풍선이
    // 화면 중앙에 몰리는 시각적 부담을 줄이려는 의도.
    final spreadMs = (_floatMs * 0.5).round();
    final list = <Balloon>[];
    for (var i = 0; i < all.length; i++) {
      final delayMs = all.length <= 1
          ? 0
          : (i * spreadMs ~/ (all.length - 1));
      list.add(
        Balloon(
          id: _nextBalloonId++,
          problem: all[i],
          xFraction: _spreadX(i, all.length),
          delayMs: delayMs,
          floatMs: _floatMs,
          color: _pickColor(i),
        ),
      );
    }

    balloons.assignAll(list);
    roundTrigger.value += 1;
  }

  /// 현재 (gameType, digitsA, digitsB) 설정으로 정답이 같은 풍선 N개를 만든다.
  /// 1) 첫 풍선은 [ProblemGenerator.generateOneForDigits]로 자유 생성 → 그 답을 target으로 고정.
  /// 2) 나머지는 [ProblemGenerator.synthesizeForAnswer]로 같은 답을 가지는 다른 식 합성.
  ///    합성에 실패하면 더 짧은 매칭 세트로 폴백(최소 [minMatching]개 보장).
  List<Problem> _buildMatchingSet(int desired) {
    // 자릿수 조합에 따라 target이 합성 불가능한 값(예: 1자리 곱셈에서 target=11)
    // 일 수 있으므로 primary 도 여러 번 시도한다.
    Problem? primary;
    for (var t = 0; t < 12; t++) {
      final p = ProblemGenerator.generateOneForDigits(
        type: gameType,
        digitsA: digitsA,
        digitsB: digitsB,
      );
      // synthesize가 같은 op로 추가 합성 가능한지 미리 한 번 검사 — 가능하지 않으면
      // 다른 target을 가지는 primary로 재시도.
      final extra = ProblemGenerator.synthesizeForAnswer(
        type: p.type,
        digitsA: digitsA,
        digitsB: digitsB,
        target: p.answer,
      );
      if (extra != null) {
        primary = p;
        break;
      }
      primary ??= p; // 마지막 폴백
    }
    final head = primary!;

    final target = head.answer;
    final out = <Problem>[head];
    final seenExpr = <String>{head.questionText};

    var attempts = 0;
    while (out.length < desired && attempts < 80) {
      attempts++;
      final extra = ProblemGenerator.synthesizeForAnswer(
        type: gameType,
        digitsA: digitsA,
        digitsB: digitsB,
        target: target,
      );
      if (extra == null) continue;
      if (seenExpr.contains(extra.questionText)) continue;
      seenExpr.add(extra.questionText);
      out.add(extra);
    }
    return out;
  }

  /// target과 답이 다른 디코이 풍선 [count]개 생성.
  List<Problem> _buildDecoys(int count, int target) {
    final out = <Problem>[];
    var attempts = 0;
    while (out.length < count && attempts < 80) {
      attempts++;
      final p = ProblemGenerator.generateOneForDigits(
        type: gameType,
        digitsA: digitsA,
        digitsB: digitsB,
      );
      if (p.answer == target) continue;
      out.add(p);
    }
    return out;
  }

  // 풍선 수에 따라 가로 위치를 균등 분포 + 약간의 jitter로 흩뿌린다.
  // 가장자리에 너무 붙으면 잘려 보이므로 0.1~0.9 사이 안쪽에서 분포.
  double _spreadX(int index, int total) {
    if (total <= 1) return 0.5;
    final lane = 0.1 + (0.8 * index / (total - 1));
    final jitter = (_rng.nextDouble() - 0.5) * 0.08;
    final v = lane + jitter;
    if (v < 0.05) return 0.05;
    if (v > 0.95) return 0.95;
    return v;
  }

  // 부드럽고 따뜻한 파스텔 팔레트. 풍선 정체성에 어울리고 6~9세에게 거부감이
  // 없는 색만 모았다.
  static const _colors = <Color>[
    Color(0xFFFFB3BA), // pink
    Color(0xFFFFDFBA), // peach
    Color(0xFFFFFFBA), // light yellow
    Color(0xFFBAFFC9), // mint
    Color(0xFFBAE1FF), // sky blue
    Color(0xFFD7BAFF), // lavender
  ];

  Color _pickColor(int index) => _colors[index % _colors.length];

  // ───── View → Controller 프레임 콜백 ───────────────────────────────────────

  /// View 의 Ticker 가 매 프레임 호출. 세션 시작 기준 ms 를 캐시 — 풍선이 탭되거나
  /// 빠져나갈 때 이펙트 freeze 시점으로 사용한다.
  void onFrame(int ms) {
    _sessionElapsedMs = ms;
  }

  // ───── 입력 처리 ────────────────────────────────────────────────────────────

  void onBalloonTap(int id) {
    if (isGameOver.value) return;
    final idx = balloons.indexWhere((b) => b.id == id);
    if (idx < 0) return;
    final b = balloons[idx];
    if (b.poppedAtMs != null) return; // 이미 터지는 중 — 중복 처리 방지.
    final isCorrect = b.problem.answer == targetAnswer.value;
    _markPopped(b, isCorrect: isCorrect);
    if (isCorrect) {
      _sfx.correct();
      pops.value += 1;
      combo.value += 1;
    } else {
      _sfx.wrong();
      combo.value = 0;
      _loseHp();
    }
  }

  /// View가 풍선이 화면 상단을 빠져나갔다고 알려줄 때 호출. 정답을 못 본 채
  /// 빠져나간 풍선은 오답 이펙트와 같은 시각 흐름으로 처리(빨간 X) — 사용자가
  /// "놓쳤다" 는 사실을 학습 피드백으로 받게 한다.
  void onBalloonEscape(int id) {
    if (isGameOver.value) return;
    final idx = balloons.indexWhere((b) => b.id == id);
    if (idx < 0) return;
    final b = balloons[idx];
    if (b.poppedAtMs != null) return;
    final wasCorrect = b.problem.answer == targetAnswer.value;
    if (wasCorrect) {
      // 놓친 정답 — HP 차감, 콤보 끊김, 그리고 escape 시점부터 잠시 X 이펙트를
      // 보이며 사라지도록 mark.
      _markPopped(b, isCorrect: false);
      _sfx.wrong();
      combo.value = 0;
      _loseHp();
    } else {
      // 오답 풍선의 자연 escape — 페널티 없이 그냥 제거.
      balloons.removeAt(idx);
      _checkRoundEnd();
    }
  }

  /// 풍선에 [poppedAtMs] / [isCorrectPop] 을 박아 둔 뒤 [popDurationMs] 후 리스트에서
  /// 제거하도록 Timer 예약. 라운드가 그 사이 게임오버되면 제거를 스킵한다.
  void _markPopped(Balloon b, {required bool isCorrect}) {
    b.poppedAtMs = _sessionElapsedMs;
    b.isCorrectPop = isCorrect;
    balloons.refresh();
    Timer(const Duration(milliseconds: popDurationMs), () {
      if (isGameOver.value) return;
      final i = balloons.indexWhere((x) => x.id == b.id);
      if (i < 0) return;
      balloons.removeAt(i);
      _checkRoundEnd();
    });
  }

  void _checkRoundEnd() {
    if (isGameOver.value) return;
    // 이펙트 재생 중인 풍선까지 모두 정리된 시점에서만 다음 라운드로 — 이펙트
    // 도중에 새 라운드 풍선이 위에서 등장하면 시각적으로 겹쳐 어수선해진다.
    if (balloons.isEmpty) {
      round.value += 1;
      _startRound();
    }
  }

  void _loseHp() {
    hp.value -= 1;
    if (hp.value <= 0) {
      hp.value = 0;
      _gameOver();
    }
  }

  // ───── 타이머 ──────────────────────────────────────────────────────────────

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (isGameOver.value) return;
      elapsed.value += 1;
      if (elapsed.value >= totalSeconds) _gameOver();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _gameOver() {
    isGameOver.value = true;
    _stopTimer();
    _sfx.finish();
  }

  // ───── 게임오버 오버레이 액션 ──────────────────────────────────────────────

  void restart() {
    hp.value = maxHp;
    pops.value = 0;
    combo.value = 0;
    round.value = 1;
    elapsed.value = 0;
    isGameOver.value = false;
    _startRound();
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

/// 화면에 떠 있는 풍선 한 개.
///
/// 컨트롤러는 위치/속도 같은 프레임 단위 정보를 직접 다루지 않는다 — View 측
/// `AnimationController.value` (0..1, 라운드 시작 시점 기준)에 [delayMs]/[floatMs]
/// 를 끼워 progress = (elapsedMs - delayMs) / floatMs 를 계산해 그린다.
class Balloon {
  Balloon({
    required this.id,
    required this.problem,
    required this.xFraction,
    required this.delayMs,
    required this.floatMs,
    required this.color,
    this.poppedAtMs,
    this.isCorrectPop,
  });

  /// 고유 식별자. 컨트롤러가 풍선 식별/제거에 쓴다.
  final int id;
  final Problem problem;

  /// 가로 위치(0..1). 0=왼쪽, 1=오른쪽. 풍선이 화면 가장자리에 잘리지 않도록
  /// 컨트롤러에서 0.05~0.95 범위로 클램프해 둔다.
  final double xFraction;

  /// 라운드 시작 시점부터 이 풍선이 등장하기까지의 지연(ms).
  final int delayMs;

  /// 풍선 한 개가 바닥에서 상단까지 떠오르는 데 걸리는 시간(ms).
  final int floatMs;

  final Color color;

  /// 탭/escape 으로 "터지는 중" 마크. null 이면 정상 비행. non-null 이면
  /// 그 시점 좌표가 freeze 되고 [BalloonGameController.popDurationMs] 동안 이펙트가
  /// 재생된 뒤 리스트에서 제거된다. 의도적으로 mutable — TowerMonster.hitAtMs 와
  /// 동일한 in-place 갱신 패턴.
  int? poppedAtMs;

  /// 터질 때의 정답 여부. null 이면 아직 안 터짐. [poppedAtMs] 와 짝.
  bool? isCorrectPop;
}
