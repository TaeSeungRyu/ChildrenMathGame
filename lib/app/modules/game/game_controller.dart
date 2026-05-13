import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
  // True when this run does not impose a time limit and does not persist a
  // record. Auto-true for times-table runs; otherwise comes from level select.
  late final bool isPractice;
  // True for the 60-second open-ended race. Mutually exclusive with practice;
  // not available for times-table or mixed sessions.
  late final bool isTimeAttack;

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
    if (isTimesTable) {
      type = GameType.multiplication;
      level = 0;
      problems = ProblemGenerator.generateTimesTable(tableNumber!);
      isPractice = true;
      isTimeAttack = false;
    } else if (isMixed) {
      type = GameType.mixed;
      level = args['level'] as int;
      problems = ProblemGenerator.generateMixed(mixedTypes!, level);
      isPractice = (args['isPractice'] as bool?) ?? false;
      isTimeAttack = false;
    } else {
      type = args['type'] as GameType;
      level = args['level'] as int;
      isTimeAttack = (args['isTimeAttack'] as bool?) ?? false;
      // Time attack starts with one problem and lazily appends more on each
      // submission. Challenge/practice get the full fixed-length batch.
      if (isTimeAttack) {
        problems = <Problem>[
          ProblemGenerator.generateOne(type: type, level: level),
        ];
        isPractice = false;
      } else {
        problems = ProblemGenerator.generate(type: type, level: level);
        isPractice = (args['isPractice'] as bool?) ?? false;
      }
    }
    _answers = List<int?>.filled(problems.length, null, growable: isTimeAttack);
    _attempted = List<bool>.filled(
      problems.length,
      false,
      growable: isTimeAttack,
    );
  }

  @override
  void onReady() {
    super.onReady();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsed.value += 1;
      // Practice has no time pressure — tick up forever, never auto-finish.
      if (isPractice && !isTimeAttack) return;
      final remain = totalSeconds - elapsed.value;
      if (remain <= 0) {
        _finish();
      } else if (remain <= tickWarningThreshold) {
        _sfx.tick();
      }
    });
  }

  @override
  void onClose() {
    _ticker?.cancel();
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

  void submit() {
    if (_finished) return;
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
    if (parsed != null && parsed == current.answer) {
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
    answer.value = '';
    if (isTimeAttack) {
      // Open-ended race — append the next problem and advance. The timer is
      // the only thing that can end the session.
      problems.add(ProblemGenerator.generateOne(type: type, level: level));
      _answers.add(null);
      _attempted.add(false);
      currentIndex.value += 1;
    } else if (currentIndex.value + 1 >= problems.length) {
      _finish();
    } else {
      currentIndex.value += 1;
    }
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
      final AttemptStatus status;
      if (!_attempted[i]) {
        unsolved++;
        status = AttemptStatus.unsolved;
      } else if (_answers[i] != null && _answers[i] == p.answer) {
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
          correctAnswer: p.answer,
          userAnswer: _answers[i],
          status: status,
          operands: p.isCompound ? p.operands : null,
          operations: p.isCompound ? p.operations : null,
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
      mode: isTimeAttack ? SessionMode.timeAttack : SessionMode.challenge,
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
      },
    );
  }
}
