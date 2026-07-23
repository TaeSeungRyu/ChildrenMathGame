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
  late final bool isEndless;
  late final bool isEquation;
  late final GameType? equationType;
  late final bool isFlash;
  late final GameType? flashType;
  late final bool isEstimation;
  late final GameType? estimationType;
  // True when a perfect (no-wrong) challenge run beat the prior best
  // elapsedSeconds at this (type, level). Always false for practice/mixed/
  // time attack/endless/equation/flash.
  late final bool isNewPerfectBest;
  // True when a time-attack run beat the prior best correctCount at this
  // (type, level). Always false outside time attack.
  late final bool isNewTimeAttackBest;
  // True when an endless run beat the prior best correctCount (= longest
  // streak) at this (type, level). Always false outside endless.
  late final bool isNewEndlessBest;

  bool get isTimesTable => tableNumber != null;
  bool get isMixed => record.type == GameType.mixed;
  bool get isNewBest =>
      isNewPerfectBest || isNewTimeAttackBest || isNewEndlessBest;

  /// 도전 모드에서만 1~3개의 별을 준다. 미풀이 문제는 정답률에 페널티를 준다.
  /// - 3★: 만점 (모두 정답)
  /// - 2★: 80% 이상
  /// - 1★: 50% 이상
  /// - 0★: 그 외 (별 표시 자체를 감춤)
  /// 연습·구구단·타임어택·연속·roll-up 모드는 시간/셋 구성이 달라 별점 부여를
  /// 하지 않는다(신기록 뱃지가 이미 그 역할).
  int get starCount {
    if (isPractice) return 0;
    if (isTimesTable) return 0;
    if (isTimeAttack || isEndless) return 0;
    if (isMixed || isEquation || isFlash || isEstimation) return 0;
    final total = record.totalCount;
    if (total == 0) return 0;
    final rate = record.correctCount / total;
    if (rate >= 1.0) return 3;
    if (rate >= 0.8) return 2;
    if (rate >= 0.5) return 1;
    return 0;
  }

  bool get showStars => starCount > 0;
  bool get isPerfect => starCount == 3;


  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map;
    record = args['record'] as GameRecord;
    tableNumber = args['tableNumber'] as int?;
    mixedTypes = (args['mixedTypes'] as List?)?.cast<GameType>();
    isPractice = (args['isPractice'] as bool?) ?? false;
    isTimeAttack = (args['isTimeAttack'] as bool?) ?? false;
    isEndless = (args['isEndless'] as bool?) ?? false;
    isEquation = (args['isEquation'] as bool?) ?? false;
    equationType = args['equationType'] as GameType?;
    isFlash = (args['isFlash'] as bool?) ?? false;
    flashType = args['flashType'] as GameType?;
    isEstimation = (args['isEstimation'] as bool?) ?? false;
    estimationType = args['estimationType'] as GameType?;
    isNewPerfectBest = _computeNewPerfectBest();
    isNewTimeAttackBest = _computeNewTimeAttackBest();
    isNewEndlessBest = _computeNewEndlessBest();
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
    // Time attack / endless have their own "신기록" notion (highest
    // correctCount); the elapsedSeconds-based perfect-best comparison
    // doesn't apply.
    if (isTimeAttack) return false;
    if (isEndless) return false;
    // Mixed runs at the same (type, level) can have different operation sets,
    // so comparing elapsed time across them isn't a fair "신기록" — skip.
    if (isMixed) return false;
    // Equation runs at the same (type, level) bucket can use any of the four
    // underlying ops, so the elapsed-time comparison isn't apples-to-apples
    // until we segment by sub-op. Skip for now.
    if (isEquation) return false;
    // Flash runs share a (type=flash, level) bucket across multiple display
    // windows (1.5s/2s/2.5s) and across the four underlying ops; comparing
    // elapsed time across those isn't a fair "신기록" — skip.
    if (isFlash) return false;
    // 어림셈 runs share a (type=estimation, level) bucket across three sub-ops
    // (+/−/×); elapsed-time comparison across different ops isn't fair — skip.
    if (isEstimation) return false;
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

  bool _computeNewEndlessBest() {
    if (!isEndless) return false;
    final priors = Get.find<RecordService>().all().where(
      (r) =>
          r.mode == SessionMode.endless &&
          r.type == record.type &&
          r.level == record.level &&
          r.finishedAt != record.finishedAt,
    );
    if (priors.isEmpty) return record.correctCount > 0;
    final bestPrior =
        priors.map((r) => r.correctCount).reduce((a, b) => a > b ? a : b);
    return record.correctCount > bestPrior;
  }
}
