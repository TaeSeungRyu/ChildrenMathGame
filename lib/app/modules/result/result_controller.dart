import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../data/models/game_record.dart';
import '../../data/models/game_type.dart';
import '../../data/services/record_service.dart';

class ResultController extends GetxController {
  late final GameRecord record;
  late final int? tableNumber;
  late final List<GameType>? mixedTypes;
  late final bool isPractice;
  late final bool isNewPerfectBest;

  bool get isTimesTable => tableNumber != null;
  bool get isMixed => record.type == GameType.mixed;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map;
    record = args['record'] as GameRecord;
    tableNumber = args['tableNumber'] as int?;
    mixedTypes = (args['mixedTypes'] as List?)?.cast<GameType>();
    isPractice = (args['isPractice'] as bool?) ?? false;
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
    // Practice runs aren't persisted, so there's no history to beat.
    if (isPractice) return false;
    // Mixed runs at the same (type, level) can have different operation sets,
    // so comparing elapsed time across them isn't a fair "신기록" — skip.
    if (isMixed) return false;
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
