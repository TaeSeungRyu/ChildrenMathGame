import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../data/models/game_record.dart';
import '../../data/models/game_type.dart';
import '../../data/models/session_mode.dart';
import '../../data/services/record_service.dart';

class ResultController extends GetxController {
  late final GameRecord record;
  late final int? tableNumber;
  late final List<GameType>? mixedTypes;
  late final bool isPractice;
  late final bool isTimeAttack;
  // True when a perfect (no-wrong) challenge run beat the prior best
  // elapsedSeconds at this (type, level). Always false for practice/mixed/
  // time attack.
  late final bool isNewPerfectBest;
  // True when a time-attack run beat the prior best correctCount at this
  // (type, level). Always false outside time attack.
  late final bool isNewTimeAttackBest;

  bool get isTimesTable => tableNumber != null;
  bool get isMixed => record.type == GameType.mixed;
  bool get isNewBest => isNewPerfectBest || isNewTimeAttackBest;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map;
    record = args['record'] as GameRecord;
    tableNumber = args['tableNumber'] as int?;
    mixedTypes = (args['mixedTypes'] as List?)?.cast<GameType>();
    isPractice = (args['isPractice'] as bool?) ?? false;
    isTimeAttack = (args['isTimeAttack'] as bool?) ?? false;
    isNewPerfectBest = _computeNewPerfectBest();
    isNewTimeAttackBest = _computeNewTimeAttackBest();
  }

  @override
  void onReady() {
    super.onReady();
    if (isNewBest) {
      HapticFeedback.heavyImpact();
    }
  }

  bool _computeNewPerfectBest() {
    // Practice runs aren't persisted, so there's no history to beat.
    if (isPractice) return false;
    // Time attack has its own "신기록" notion (highest correctCount); the
    // elapsedSeconds-based perfect-best comparison doesn't apply.
    if (isTimeAttack) return false;
    // Mixed runs at the same (type, level) can have different operation sets,
    // so comparing elapsed time across them isn't a fair "신기록" — skip.
    if (isMixed) return false;
    if (record.correctCount != record.totalCount) return false;
    final priors = Get.find<RecordService>().all().where(
      (r) =>
          r.mode == SessionMode.challenge &&
          r.type == record.type &&
          r.level == record.level &&
          r.correctCount == r.totalCount &&
          r.finishedAt != record.finishedAt,
    );
    if (priors.isEmpty) return false;
    final bestPrior = priors
        .map((r) => r.elapsedSeconds)
        .reduce((a, b) => a < b ? a : b);
    return record.elapsedSeconds < bestPrior;
  }

  bool _computeNewTimeAttackBest() {
    if (!isTimeAttack) return false;
    final priors = Get.find<RecordService>().all().where(
      (r) =>
          r.mode == SessionMode.timeAttack &&
          r.type == record.type &&
          r.level == record.level &&
          r.finishedAt != record.finishedAt,
    );
    if (priors.isEmpty) {
      // First time-attack run at this (type, level) — celebrate it only when
      // there's something to celebrate (at least one correct answer).
      return record.correctCount > 0;
    }
    final bestPrior =
        priors.map((r) => r.correctCount).reduce((a, b) => a > b ? a : b);
    return record.correctCount > bestPrior;
  }
}
