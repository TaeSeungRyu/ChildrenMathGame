import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/game_record.dart';
import '../../data/models/game_type.dart';
import '../../data/models/problem.dart';
import '../../data/models/problem_attempt.dart';
import '../../data/services/problem_generator.dart';
import '../../data/services/record_service.dart';
import '../../data/services/sfx_service.dart';
import '../../routes/app_routes.dart';

class GameController extends GetxController {
  static const totalSeconds = 180;
  static const totalProblems = ProblemGenerator.totalProblems;
  static const tickWarningThreshold = 5;

  late final GameType type;
  late final int level;
  late final List<Problem> problems;

  static const maxAnswerLength = 6;

  final currentIndex = 0.obs;
  final secondsLeft = totalSeconds.obs;
  final answer = ''.obs;

  final List<int?> _answers = List<int?>.filled(totalProblems, null);
  final List<bool> _attempted = List<bool>.filled(totalProblems, false);

  Timer? _ticker;
  bool _finished = false;

  final SfxService _sfx = Get.find<SfxService>();

  Problem get current => problems[currentIndex.value];

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map;
    type = args['type'] as GameType;
    level = args['level'] as int;
    problems = ProblemGenerator.generate(type: type, level: level);
  }

  @override
  void onReady() {
    super.onReady();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (secondsLeft.value <= 1) {
        secondsLeft.value = 0;
        _finish();
      } else {
        secondsLeft.value -= 1;
        if (secondsLeft.value <= tickWarningThreshold) {
          _sfx.tick();
        }
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
    } else {
      _sfx.wrong();
    }
    answer.value = '';
    if (currentIndex.value + 1 >= totalProblems) {
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
      elapsedSeconds: totalSeconds - secondsLeft.value,
      attempts: attempts,
    );
    Get.find<RecordService>().add(record);
    Get.offNamed(AppRoutes.result, arguments: record);
  }
}
