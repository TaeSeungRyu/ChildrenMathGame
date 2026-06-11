import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/problem_attempt.dart';
import '../../data/services/sfx_service.dart';

enum ReviewPhase { answering, feedback, done }

class ReviewController extends GetxController {
  static const maxAnswerLength = 6;

  late final List<ProblemAttempt> problems;

  final currentIndex = 0.obs;
  final answer = ''.obs;
  final phase = ReviewPhase.answering.obs;
  final lastWasCorrect = false.obs;
  final retryCorrectCount = 0.obs;

  final SfxService _sfx = Get.find<SfxService>();

  ProblemAttempt get current => problems[currentIndex.value];
  int get totalCount => problems.length;
  bool get isLast => currentIndex.value >= problems.length - 1;

  @override
  void onInit() {
    super.onInit();
    // 정상 호출자는 항상 List<ProblemAttempt>를 넘기지만, 인자가 누락/오타입인
    // 경우(딥링크·핸들러 누수 등)에도 크래시 없이 빈 리뷰 세션으로 진입해
    // 곧장 "복습 끝!" 상태를 보여주도록 방어한다.
    final raw = Get.arguments;
    problems = raw is List ? raw.whereType<ProblemAttempt>().toList() : const [];
    if (problems.isEmpty) {
      phase.value = ReviewPhase.done;
    }
  }

  void appendDigit(String digit) {
    if (phase.value != ReviewPhase.answering) return;
    if (answer.value.length >= maxAnswerLength) return;
    _sfx.click();
    answer.value = answer.value + digit;
  }

  void deleteLast() {
    if (phase.value != ReviewPhase.answering) return;
    if (answer.value.isEmpty) return;
    _sfx.click();
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
      _sfx.correct();
    } else {
      _sfx.wrong();
    }
    phase.value = ReviewPhase.feedback;
  }

  void next() {
    if (phase.value != ReviewPhase.feedback) return;
    if (isLast) {
      _sfx.finish();
      phase.value = ReviewPhase.done;
      return;
    }
    currentIndex.value += 1;
    answer.value = '';
    phase.value = ReviewPhase.answering;
  }
}
