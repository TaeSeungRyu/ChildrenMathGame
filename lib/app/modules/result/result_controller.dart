import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../data/models/game_record.dart';
import '../../data/services/record_service.dart';

class ResultController extends GetxController {
  late final GameRecord record;
  late final bool isNewPerfectBest;

  @override
  void onInit() {
    super.onInit();
    record = Get.arguments as GameRecord;
    isNewPerfectBest = _computeNewPerfectBest();
  }

  @override
  void onReady() {
    super.onReady();
    if (isNewPerfectBest) {
      HapticFeedback.heavyImpact();
    }
  }

  bool _computeNewPerfectBest() {
    if (record.correctCount != record.totalCount) return false;
    final priors = Get.find<RecordService>().all().where(
      (r) =>
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
}
