import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../data/models/problem_attempt.dart';

enum ReviewPhase { answering, feedback, done }

class ReviewController extends GetxController {
  static const maxAnswerLength = 6;

  late final List<ProblemAttempt> problems;

  final currentIndex = 0.obs;
  final answer = ''.obs;
  final phase = ReviewPhase.answering.obs;
  final lastWasCorrect = false.obs;
  final retryCorrectCount = 0.obs;

  ProblemAttempt get current => problems[currentIndex.value];
  int get totalCount => problems.length;
  bool get isLast => currentIndex.value >= problems.length - 1;

  @override
  void onInit() {
    super.onInit();
    problems = (Get.arguments as List).cast<ProblemAttempt>();
  }

  void appendDigit(String digit) {
    if (phase.value != ReviewPhase.answering) return;
    if (answer.value.length >= maxAnswerLength) return;
    answer.value = answer.value + digit;
  }

  void deleteLast() {
    if (phase.value != ReviewPhase.answering) return;
    if (answer.value.isEmpty) return;
    answer.value = answer.value.substring(0, answer.value.length - 1);
  }

  void submit() {
    if (phase.value != ReviewPhase.answering) return;
    if (answer.value.isEmpty) {
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
    final parsed = int.tryParse(answer.value);
    final correct = parsed != null && parsed == current.correctAnswer;
    lastWasCorrect.value = correct;
    if (correct) {
      retryCorrectCount.value += 1;
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.mediumImpact();
    }
    phase.value = ReviewPhase.feedback;
  }

  void next() {
    if (phase.value != ReviewPhase.feedback) return;
    if (isLast) {
      phase.value = ReviewPhase.done;
      return;
    }
    currentIndex.value += 1;
    answer.value = '';
    phase.value = ReviewPhase.answering;
  }
}
