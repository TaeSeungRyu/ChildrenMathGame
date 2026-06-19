import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/estimation_choices.dart';
import '../../data/models/game_record.dart';
import '../../data/models/game_type.dart';
import '../../data/models/problem.dart';
import '../../data/models/problem_attempt.dart';
import '../../data/models/session_mode.dart';
import '../../data/services/problem_generator.dart';
import '../../data/services/record_service.dart';
import '../../data/services/sfx_service.dart';
import '../../routes/app_routes.dart';

class GameController extends GetxController {
  static const challengeSeconds = 180;
  static const timeAttackSeconds = 60;
  static const tickWarningThreshold = 5;
  // Default cap is 6; compound mixed problems can produce wider answers (e.g.
  // 3-digit × 3-digit chains can climb past a million), so the entry limit
  // widens via [maxAnswerLength].
  static const _defaultMaxAnswerLength = 6;
  static const _compoundMaxAnswerLength = 10;
  // Combo thresholds that trigger the celebratory cue. Hit-once per ascent —
  // re-hitting after a reset re-fires (intended: each new streak earns it).
  static const comboMilestones = {3, 5, 7, 10};

  late final GameType type;
  late final int level;
  // Mutable in [SessionMode.timeAttack] runs — problems are appended lazily as
  // the player advances, so this list grows. For challenge/practice runs it's
  // populated once in [onInit] and never resized.
  late final List<Problem> problems;
  // Non-null when the session is a "단 연습" (times-table practice) run.
  late final int? tableNumber;
  // Non-null when the session is a 혼합 모드 run — holds the user-selected
  // operations. `type` rolls up to `GameType.mixed` in this case.
  late final List<GameType>? mixedTypes;
  // True when this run is a 방정식 (equation) session — problems are
  // generated for a single concrete op (held in [equationType]) but presented
  // as "A op ? = C" and the player solves for operandB. `type` rolls up to
  // `GameType.equation` for the record.
  late final bool isEquation;
  // Concrete op used to generate problems in equation mode. Null otherwise.
  late final GameType? equationType;
  // True when this run is a 플래시 (mental math flash) session — problems are
  // generated for a single concrete op (held in [flashType]) but shown only
  // for [flashDisplayMs] milliseconds before being hidden, forcing the player
  // to answer from memory. `type` rolls up to `GameType.flash` for the record.
  late final bool isFlash;
  // Concrete op used to generate problems in flash mode. Null otherwise.
  late final GameType? flashType;
  // True when this run is an 어림셈 (estimation) session — problems are
  // generated for a single concrete op (held in [estimationType]) and presented
  // alongside a 3-choice picker derived from rounding the operands. `type`
  // rolls up to [GameType.estimation] for the record.
  late final bool isEstimation;
  late final GameType? estimationType;
  // Pre-computed 3-choice sets keyed by problem index. Growable only when the
  // session is open-ended; estimation runs are fixed-length, so this is built
  // once in onInit alongside `problems`. Null in non-estimation runs.
  late final List<EstimationChoices>? estimationChoices;
  // How long the problem text is visible before being hidden in flash mode.
  // Always 0 outside flash mode.
  late final int flashDisplayMs;
  // True while the current problem is still within its flash display window.
  // Driven by [_flashTimer]; flips to false when the window expires. Always
  // true (and irrelevant) outside flash mode.
  final flashVisible = true.obs;
  Timer? _flashTimer;
  // True when this run does not impose a time limit and does not persist a
  // record. Auto-true for times-table runs; otherwise comes from level select.
  late final bool isPractice;
  // True for the 60-second open-ended race. Mutually exclusive with practice;
  // not available for times-table, mixed, or equation sessions.
  late final bool isTimeAttack;
  // True for 연속도전: no timer, no problem cap, the session ends on the
  // first wrong submission. Mutually exclusive with timeAttack/practice; not
  // available for times-table, mixed, equation, or flash sessions.
  late final bool isEndless;

  final currentIndex = 0.obs;
  // Seconds elapsed since the timer started. Counts up regardless of mode so
  // the same value feeds both the countdown display (challenge) and the
  // informational up-counter (practice).
  final elapsed = 0.obs;
  final answer = ''.obs;
  // Current consecutive-correct streak within this game. Resets on any
  // wrong/empty submission. `maxCombo` tracks the peak for the final record.
  final comboCount = 0.obs;
  int _maxCombo = 0;

  late final List<int?> _answers;
  late final List<bool> _attempted;
  // Running tally for the AppBar / progress UI — only meaningful in time
  // attack, but updated alongside `_answers` so it's always in sync.
  final correctCount = 0.obs;
  final wrongCount = 0.obs;

  Timer? _ticker;
  bool _finished = false;

  final SfxService _sfx = Get.find<SfxService>();

  Problem get current => problems[currentIndex.value];
  int get totalProblems => problems.length;
  bool get isTimesTable => tableNumber != null;
  bool get isMixed => mixedTypes != null;
  int get maxAnswerLength =>
      isMixed ? _compoundMaxAnswerLength : _defaultMaxAnswerLength;
  // Total seconds for the timed leg of this session. Time attack uses a
  // shorter window than challenge; practice runs ignore this (counter only).
  int get totalSeconds =>
      isTimeAttack ? timeAttackSeconds : challengeSeconds;
  int get remainingSeconds =>
      (totalSeconds - elapsed.value).clamp(0, totalSeconds);

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map;
    tableNumber = args['tableNumber'] as int?;
    mixedTypes = (args['mixedTypes'] as List?)?.cast<GameType>();
    isEquation = (args['isEquation'] as bool?) ?? false;
    isFlash = (args['isFlash'] as bool?) ?? false;
    isEstimation = (args['isEstimation'] as bool?) ?? false;
    if (isTimesTable) {
      type = GameType.multiplication;
      level = 0;
      problems = ProblemGenerator.generateTimesTable(tableNumber!);
      isPractice = true;
      isTimeAttack = false;
      isEndless = false;
      equationType = null;
      flashType = null;
      flashDisplayMs = 0;
      estimationType = null;
      estimationChoices = null;
    } else if (isMixed) {
      type = GameType.mixed;
      level = args['level'] as int;
      problems = ProblemGenerator.generateMixed(mixedTypes!, level);
      isPractice = (args['isPractice'] as bool?) ?? false;
      isTimeAttack = false;
      isEndless = false;
      equationType = null;
      flashType = null;
      flashDisplayMs = 0;
      estimationType = null;
      estimationChoices = null;
    } else if (isEquation) {
      // Equation runs always use a single concrete op; time attack is
      // intentionally not offered (the player picked 도전/연습 only).
      equationType = args['type'] as GameType;
      type = GameType.equation;
      level = args['level'] as int;
      problems = ProblemGenerator.generate(type: equationType!, level: level);
      isPractice = (args['isPractice'] as bool?) ?? false;
      isTimeAttack = false;
      isEndless = false;
      flashType = null;
      flashDisplayMs = 0;
      estimationType = null;
      estimationChoices = null;
    } else if (isFlash) {
      // Flash runs use a single concrete op + a display window. Time attack
      // is not offered (flash already has its own timing element).
      flashType = args['type'] as GameType;
      type = GameType.flash;
      level = args['level'] as int;
      flashDisplayMs = (args['flashDisplayMs'] as int?) ?? 2000;
      problems = ProblemGenerator.generate(type: flashType!, level: level);
      isPractice = (args['isPractice'] as bool?) ?? false;
      isTimeAttack = false;
      isEndless = false;
      equationType = null;
      estimationType = null;
      estimationChoices = null;
    } else if (isEstimation) {
      // 어림셈 — 단일 연산(+/−/×), 고정 10문제, 3지선다. 보기는 onInit에서
      // 한 번에 미리 만들어 두므로 화면 전환 중 새로 셔플되어 답이 바뀌는 일이
      // 없다. 시간 어택/엔드리스는 어림셈에 적용하지 않는다(보기 사전 생성과
      // 가변 길이 problems 가 충돌하므로).
      estimationType = args['type'] as GameType;
      type = GameType.estimation;
      level = args['level'] as int;
      problems = ProblemGenerator.generate(
        type: estimationType!,
        level: level,
      );
      estimationChoices = [
        for (final p in problems)
          ProblemGenerator.estimationChoicesFor(p, level),
      ];
      isPractice = (args['isPractice'] as bool?) ?? false;
      isTimeAttack = false;
      isEndless = false;
      flashType = null;
      flashDisplayMs = 0;
      equationType = null;
    } else {
      type = args['type'] as GameType;
      level = args['level'] as int;
      isTimeAttack = (args['isTimeAttack'] as bool?) ?? false;
      isEndless = (args['isEndless'] as bool?) ?? false;
      equationType = null;
      flashType = null;
      flashDisplayMs = 0;
      estimationType = null;
      estimationChoices = null;
      // Time attack and endless both start with one problem and lazily
      // append more on each submission. Challenge/practice get the full
      // fixed-length batch.
      if (isTimeAttack || isEndless) {
        problems = <Problem>[
          ProblemGenerator.generateOne(type: type, level: level),
        ];
        isPractice = false;
      } else {
        problems = ProblemGenerator.generate(type: type, level: level);
        isPractice = (args['isPractice'] as bool?) ?? false;
      }
    }
    final isGrowing = isTimeAttack || isEndless;
    _answers = List<int?>.filled(problems.length, null, growable: isGrowing);
    _attempted = List<bool>.filled(
      problems.length,
      false,
      growable: isGrowing,
    );
  }

  @override
  void onReady() {
    super.onReady();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsed.value += 1;
      // Practice / endless have no countdown — tick up forever for the info
      // display; only timeAttack/challenge enforce the limit.
      if ((isPractice && !isTimeAttack) || isEndless) return;
      final remain = totalSeconds - elapsed.value;
      if (remain <= 0) {
        _finish();
      } else if (remain <= tickWarningThreshold) {
        _sfx.tick();
      }
    });
    if (isFlash) _startFlashWindow();
  }

  // Shows the current problem for [flashDisplayMs], then hides it. Called on
  // session start and again every time [submit] advances to the next problem.
  void _startFlashWindow() {
    _flashTimer?.cancel();
    flashVisible.value = true;
    _flashTimer = Timer(Duration(milliseconds: flashDisplayMs), () {
      flashVisible.value = false;
    });
  }

  @override
  void onClose() {
    _ticker?.cancel();
    _flashTimer?.cancel();
    super.onClose();
  }

  void appendDigit(String digit) {
    if (_finished) return;
    if (answer.value.length >= maxAnswerLength) return;
    _sfx.click();
    answer.value = answer.value + digit;
  }

  void deleteLast() {
    if (_finished) return;
    if (answer.value.isEmpty) return;
    _sfx.click();
    answer.value = answer.value.substring(0, answer.value.length - 1);
  }

  /// 어림셈 모드 전용 — 키패드 대신 보기 버튼에서 한 번의 탭으로 제출.
  /// 답을 키패드 input(answer.value)이 아니라 [picked] 인자로 직접 받기 때문에
  /// 빈값 검증이 필요 없고, [submit]의 후처리(콤보·인덱스 진행·완주)만 그대로
  /// 재사용한다.
  void submitChoice(int picked) {
    if (_finished) return;
    if (!isEstimation) return;
    final expected = estimationChoices![currentIndex.value].correct;
    _answers[currentIndex.value] = picked;
    _attempted[currentIndex.value] = true;
    final wasCorrect = picked == expected;
    if (wasCorrect) {
      _sfx.correct();
      correctCount.value += 1;
      comboCount.value += 1;
      if (comboCount.value > _maxCombo) _maxCombo = comboCount.value;
      if (comboMilestones.contains(comboCount.value)) {
        _sfx.combo();
      }
    } else {
      _sfx.wrong();
      wrongCount.value += 1;
      comboCount.value = 0;
    }
    if (currentIndex.value + 1 >= problems.length) {
      _finish();
      return;
    }
    currentIndex.value += 1;
  }

  void submit() {
    if (_finished) return;
    // 어림셈은 키패드를 쓰지 않으므로 submit()이 호출될 일이 없지만, GameView
    // 분기 누락에 대비한 안전망.
    if (isEstimation) return;
    final text = answer.value;
    if (text.isEmpty) {
      Get.snackbar(
        '',
        '',
        titleText: const SizedBox.shrink(),
        messageText: const Text(
          '값을 입력 해 주세요.',
          style: TextStyle(color: Colors.white, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade400,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
        animationDuration: const Duration(milliseconds: 200),
      );
      return;
    }
    final parsed = int.tryParse(text);
    _answers[currentIndex.value] = parsed;
    _attempted[currentIndex.value] = true;
    final expected = isEquation ? current.operandB : current.answer;
    if (parsed != null && parsed == expected) {
      _sfx.correct();
      correctCount.value += 1;
      comboCount.value += 1;
      if (comboCount.value > _maxCombo) _maxCombo = comboCount.value;
      if (comboMilestones.contains(comboCount.value)) {
        _sfx.combo();
      }
    } else {
      _sfx.wrong();
      wrongCount.value += 1;
      comboCount.value = 0;
    }
    final wasCorrect = parsed != null && parsed == expected;
    answer.value = '';
    if (isEndless) {
      // 연속도전: a wrong answer ends the session immediately; the wrong
      // attempt is preserved in the record so the player sees it. On correct
      // answers we keep appending fresh problems indefinitely.
      if (!wasCorrect) {
        _finish();
        return;
      }
      problems.add(ProblemGenerator.generateOne(type: type, level: level));
      _answers.add(null);
      _attempted.add(false);
      currentIndex.value += 1;
    } else if (isTimeAttack) {
      // Open-ended race — append the next problem and advance. The timer is
      // the only thing that can end the session.
      problems.add(ProblemGenerator.generateOne(type: type, level: level));
      _answers.add(null);
      _attempted.add(false);
      currentIndex.value += 1;
    } else if (currentIndex.value + 1 >= problems.length) {
      _finish();
      return;
    } else {
      currentIndex.value += 1;
    }
    if (isFlash) _startFlashWindow();
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    _ticker?.cancel();
    _ticker = null;
    _sfx.finish();

    var correct = 0;
    var wrong = 0;
    var unsolved = 0;
    final attempts = <ProblemAttempt>[];
    for (var i = 0; i < problems.length; i++) {
      final p = problems[i];
      final int expected;
      if (isEquation) {
        expected = p.operandB;
      } else if (isEstimation) {
        expected = estimationChoices![i].correct;
      } else {
        expected = p.answer;
      }
      final AttemptStatus status;
      if (!_attempted[i]) {
        unsolved++;
        status = AttemptStatus.unsolved;
      } else if (_answers[i] != null && _answers[i] == expected) {
        correct++;
        status = AttemptStatus.correct;
      } else {
        wrong++;
        status = AttemptStatus.wrong;
      }
      attempts.add(
        ProblemAttempt(
          operandA: p.operandA,
          operandB: p.operandB,
          type: p.type,
          correctAnswer: expected,
          userAnswer: _answers[i],
          status: status,
          operands: p.isCompound ? p.operands : null,
          operations: p.isCompound ? p.operations : null,
          isEquation: isEquation,
          isEstimation: isEstimation,
        ),
      );
    }
    final record = GameRecord(
      finishedAt: DateTime.now(),
      type: type,
      level: level,
      correctCount: correct,
      wrongCount: wrong,
      unsolvedCount: unsolved,
      elapsedSeconds: elapsed.value,
      attempts: attempts,
      maxCombo: _maxCombo,
      mode: isEndless
          ? SessionMode.endless
          : isTimeAttack
              ? SessionMode.timeAttack
              : SessionMode.challenge,
    );
    // Practice + 구구단 runs don't write to history — keeps streak/badges/stats
    // free of "casual practice" noise.
    if (!isPractice) {
      Get.find<RecordService>().add(record);
    }
    Get.offNamed(
      AppRoutes.result,
      arguments: {
        'record': record,
        'tableNumber': tableNumber,
        'mixedTypes': mixedTypes,
        'isPractice': isPractice,
        'isTimeAttack': isTimeAttack,
        'isEndless': isEndless,
        'isEquation': isEquation,
        'equationType': equationType,
        'isFlash': isFlash,
        'flashType': flashType,
        'isEstimation': isEstimation,
        'estimationType': estimationType,
      },
    );
  }
}
