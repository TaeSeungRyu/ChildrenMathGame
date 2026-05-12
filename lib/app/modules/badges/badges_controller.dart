import 'package:get/get.dart';

import '../../data/models/achievement_badge.dart';
import '../../data/models/custom_stamp.dart';
import '../../data/models/game_record.dart';
import '../../data/models/stamp_condition.dart';
import '../../data/services/custom_stamp_service.dart';
import '../../data/services/record_service.dart';
import '../../shared/badges.dart';
import '../../shared/stamp_evaluation.dart';
import '../../shared/streak.dart';

/// View-facing status for a [CustomStamp] — earned state and (for auto
/// stamps) progress are precomputed here so the tile widget stays dumb.
class CustomStampStatus {
  const CustomStampStatus({
    required this.stamp,
    required this.earned,
    this.progress,
    this.target,
  });

  final CustomStamp stamp;
  final bool earned;
  // Non-null for auto stamps; current count of matching records.
  final int? progress;
  // Non-null for auto stamps; copy of stamp.condition.targetCount.
  final int? target;

  bool get isAuto => progress != null;
  double get progressRatio {
    if (target == null || target == 0) return 0;
    return (progress! / target!).clamp(0.0, 1.0);
  }
}

class BadgesController extends GetxController {
  final RecordService _records = Get.find<RecordService>();
  final CustomStampService _customStamps = Get.find<CustomStampService>();

  // Cached at first access — built-in badges don't change within a session
  // since records.add only happens off-screen during a game.
  late final List<GameRecord> _recordsSnapshot = _records.all();

  late final List<BadgeStatus> badges = evaluateBadges(
    _recordsSnapshot,
    maxStreak: computeMaxStreak(_recordsSnapshot.map((r) => r.finishedAt)),
  );

  RxList<CustomStamp> get customStamps => _customStamps.stamps;

  List<CustomStampStatus> get customStampStatuses {
    return customStamps.map((s) {
      if (s.condition == null) {
        return CustomStampStatus(stamp: s, earned: s.earned);
      }
      final n = evaluateStampCondition(s.condition!, _recordsSnapshot);
      return CustomStampStatus(
        stamp: s,
        earned: n >= s.condition!.targetCount,
        progress: n,
        target: s.condition!.targetCount,
      );
    }).toList();
  }

  int get unlockedBuiltIn => badges.where((b) => b.unlocked).length;
  int get earnedCustom =>
      customStampStatuses.where((s) => s.earned).length;
  int get unlockedCount => unlockedBuiltIn + earnedCustom;
  int get totalCount => badges.length + customStamps.length;

  Future<void> addCustomStamp({
    required String title,
    required String emoji,
    required int colorValue,
    StampCondition? condition,
  }) {
    return _customStamps.add(
      title: title,
      emoji: emoji,
      colorValue: colorValue,
      condition: condition,
    );
  }

  Future<void> updateCustomStamp(CustomStamp stamp) {
    return _customStamps.update(stamp);
  }

  Future<void> deleteCustomStamp(String id) {
    return _customStamps.delete(id);
  }

  Future<void> toggleCustomEarned(String id) {
    return _customStamps.toggleEarned(id);
  }
}
