import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/custom_stamp.dart';
import '../models/stamp_condition.dart';

/// Persistent CRUD store for user-defined stamps. Backed by a single JSON
/// blob under SharedPreferences key `custom_stamps_v1`. The [stamps] list is
/// observable so the badges grid rebuilds automatically on add/edit/delete.
class CustomStampService extends GetxService {
  static const _storageKey = 'custom_stamps_v1';

  late final SharedPreferences _prefs;

  // Monotonic counter that breaks ties when multiple adds land in the same
  // microsecond (common in tests and rapid taps).
  int _idCounter = 0;

  final RxList<CustomStamp> stamps = <CustomStamp>[].obs;

  Future<CustomStampService> init() async {
    _prefs = await SharedPreferences.getInstance();
    stamps.assignAll(_load());
    return this;
  }

  List<CustomStamp> _load() {
    final raw = _prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return const [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => CustomStamp.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _save() async {
    await _prefs.setString(
      _storageKey,
      jsonEncode(stamps.map((s) => s.toJson()).toList()),
    );
  }

  Future<CustomStamp> add({
    required String title,
    required String emoji,
    required int colorValue,
    StampCondition? condition,
  }) async {
    final now = DateTime.now();
    // Timestamp + counter — counter breaks ties when adds happen within the
    // same microsecond. Avoids pulling in a uuid dependency.
    final stamp = CustomStamp(
      id: 's_${now.microsecondsSinceEpoch}_${_idCounter++}',
      title: title.trim(),
      emoji: emoji,
      colorValue: colorValue,
      earned: false,
      createdAt: now,
      condition: condition,
    );
    stamps.add(stamp);
    await _save();
    return stamp;
  }

  Future<void> update(CustomStamp stamp) async {
    final i = stamps.indexWhere((s) => s.id == stamp.id);
    if (i < 0) return;
    stamps[i] = stamp;
    await _save();
  }

  Future<void> delete(String id) async {
    stamps.removeWhere((s) => s.id == id);
    await _save();
  }

  Future<void> toggleEarned(String id) async {
    final i = stamps.indexWhere((s) => s.id == id);
    if (i < 0) return;
    stamps[i] = stamps[i].copyWith(earned: !stamps[i].earned);
    await _save();
  }
}
