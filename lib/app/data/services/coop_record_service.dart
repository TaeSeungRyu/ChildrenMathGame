import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/coop_session_record.dart';
import 'profile_service.dart';

/// Persistent store for 부모와 함께하는 학습 session summaries (the "함께 →
/// 기록보기" list). Profile-scoped like the other record stores; kept separate
/// from `RecordService`/`GameRecord` so coop sessions don't affect learning
/// stats or badges.
class CoopRecordService extends GetxService {
  static const _storageBase = 'coop_records_v1';

  late final SharedPreferences _prefs;

  /// Newest first.
  final RxList<CoopSessionRecord> records = <CoopSessionRecord>[].obs;

  // Falls back to the primary (empty) scope when ProfileService isn't
  // registered — e.g. service-only unit tests.
  String get _storageKey =>
      '$_storageBase${Get.isRegistered<ProfileService>() ? Get.find<ProfileService>().scopeSuffix : ''}';

  Future<CoopRecordService> init() async {
    _prefs = await SharedPreferences.getInstance();
    _load();
    return this;
  }

  void _load() {
    final raw = _prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      records.clear();
      return;
    }
    final list = jsonDecode(raw) as List<dynamic>;
    records.assignAll(
      list.map((e) => CoopSessionRecord.fromJson(e as Map<String, dynamic>)),
    );
  }

  /// Re-read for the active profile (call after a profile switch).
  void reload() => _load();

  Future<void> add(CoopSessionRecord record) async {
    records.insert(0, record);
    await _save();
  }

  Future<void> delete(CoopSessionRecord record) async {
    records.removeWhere((r) => r.finishedAt == record.finishedAt);
    await _save();
  }

  Future<void> _save() async {
    await _prefs.setString(
      _storageKey,
      jsonEncode(records.map((r) => r.toJson()).toList()),
    );
  }
}
