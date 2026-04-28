import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/game_record.dart';
import '../../data/models/game_type.dart';
import '../../data/models/problem.dart';
import '../../data/services/problem_generator.dart';
import '../../data/services/record_service.dart';
import '../../routes/app_routes.dart';

class GameController extends GetxController {
  static const totalSeconds = 120;
  static const totalProblems = ProblemGenerator.totalProblems;

  late final GameType type;
  late final int level;
  late final List<Problem> problems;

  final currentIndex = 0.obs;
  final secondsLeft = totalSeconds.obs;
  final answerController = TextEditingController();

  final List<int?> _answers = List<int?>.filled(totalProblems, null);

  Timer? _ticker;
  bool _finished = false;

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
      }
    });
  }

  @override
  void onClose() {
    _ticker?.cancel();
    answerController.dispose();
    super.onClose();
  }

  void submit() {
    if (_finished) return;
    final parsed = int.tryParse(answerController.text.trim());
    _answers[currentIndex.value] = parsed;
    answerController.clear();
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

    var correct = 0;
    for (var i = 0; i < problems.length; i++) {
      if (_answers[i] != null && _answers[i] == problems[i].answer) {
        correct++;
      }
    }
    final record = GameRecord(
      finishedAt: DateTime.now(),
      type: type,
      level: level,
      correctCount: correct,
      wrongCount: totalProblems - correct,
    );
    Get.find<RecordService>().add(record);
    Get.offNamed(AppRoutes.result, arguments: record);
  }
}
