import 'package:get/get.dart';

import '../../data/models/achievement_badge.dart';
import '../../data/services/record_service.dart';
import '../../shared/badges.dart';
import '../../shared/streak.dart';

class BadgesController extends GetxController {
  final RecordService _records = Get.find<RecordService>();

  late final List<BadgeStatus> badges = evaluateBadges(
    _records.all(),
    maxStreak: computeMaxStreak(_records.all().map((r) => r.finishedAt)),
  );

  int get unlockedCount => badges.where((b) => b.unlocked).length;
  int get totalCount => badges.length;
}
