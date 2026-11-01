import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/billiards_rules.dart';
import '../models/game_type.dart';
import 'profile_service.dart';

class BilliardsScoreService extends GetxService {
  static const _baseKey = 'billiards_scores_v1';
  late SharedPreferences _prefs;
  final best = <String, BilliardsValue>{}.obs;
  final plays = <String, int>{}.obs;

  String get _storageKey =>
      '$_baseKey${Get.isRegistered<ProfileService>() ? Get.find<ProfileService>().scopeSuffix : ''}';
  String _bucket(GameType type, int count) => '${type.name}_$count';

  Future<BilliardsScoreService> init() async {
    _prefs = await SharedPreferences.getInstance();
    reload();
    return this;
  }

  void reload() {
    best.clear();
    plays.clear();
    final raw = _prefs.getString(_storageKey);
    if (raw == null) return;
    final data = jsonDecode(raw) as Map<String, dynamic>;
    for (final entry in data.entries) {
      final item = entry.value as Map<String, dynamic>;
      plays[entry.key] = item['plays'] as int? ?? 0;
      if (item['num'] is int && item['den'] is int) {
        best[entry.key] = BilliardsValue(
          item['num'] as int,
          item['den'] as int,
        );
      }
    }
  }

  BilliardsValue? bestFor(GameType type, int count) =>
      best[_bucket(type, count)];
  int playsFor(GameType type, int count) => plays[_bucket(type, count)] ?? 0;

  Future<void> report(GameType type, int count, BilliardsValue? score) async {
    final key = _bucket(type, count);
    plays[key] = (plays[key] ?? 0) + 1;
    if (score != null &&
        (best[key] == null || score.compareTo(best[key]!) > 0)) {
      best[key] = score;
    }
    final data = <String, dynamic>{};
    for (final bucket in plays.keys) {
      data[bucket] = {
        'plays': plays[bucket],
        if (best[bucket] != null) 'num': best[bucket]!.numerator,
        if (best[bucket] != null) 'den': best[bucket]!.denominator,
      };
    }
    await _prefs.setString(_storageKey, jsonEncode(data));
  }
}
