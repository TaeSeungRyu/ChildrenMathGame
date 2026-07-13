import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/streak.dart';
import '../models/game_record.dart';
import 'profile_service.dart';

class RecordService extends GetxService {
  static const _storageBase = 'game_records_v4';
  static const _dismissedWrongBase = 'wrong_notebook_dismissed_v1';

  late final SharedPreferences _prefs;

  // Storage keys are scoped to the active profile so siblings keep separate
  // records. The primary profile uses an empty suffix, preserving the original
  // keys for existing single-user installs.
  // Falls back to the primary (empty) scope when ProfileService isn't
  // registered — e.g. service-only unit tests.
  String get _scope => Get.isRegistered<ProfileService>()
      ? Get.find<ProfileService>().scopeSuffix
      : '';
  String get _storageKey => '$_storageBase$_scope';
  String get _dismissedWrongKey => '$_dismissedWrongBase$_scope';

  Future<RecordService> init() async {
    _prefs = await SharedPreferences.getInstance();
    return this;
  }

  List<GameRecord> all() {
    final raw = _prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => GameRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> add(GameRecord record) async {
    final records = all()..add(record);
    await _save(records);
  }

  int currentStreak({DateTime? now}) {
    return computeStreak(
      all().map((r) => r.finishedAt),
      today: now ?? DateTime.now(),
    );
  }

  // Records are matched by `finishedAt` — DateTime equality is value-based and
  // millisecond precision makes collisions effectively impossible.
  Future<void> delete(GameRecord record) async {
    final records = all()
      ..removeWhere((r) => r.finishedAt == record.finishedAt);
    await _save(records);
  }

  Future<void> _save(List<GameRecord> records) async {
    await _prefs.setString(
      _storageKey,
      jsonEncode(records.map((r) => r.toJson()).toList()),
    );
  }

  // Wrong-notebook dismissals: signature -> moment the user dismissed it.
  // Attempts in records older than that moment are hidden; newer misses of
  // the same problem still resurface the entry.
  Map<String, DateTime> dismissedWrongSignatures() {
    final raw = _prefs.getString(_dismissedWrongKey);
    if (raw == null || raw.isEmpty) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return {
      for (final e in map.entries)
        e.key: DateTime.fromMillisecondsSinceEpoch(e.value as int),
    };
  }

  Future<void> dismissWrongSignature(String signature, {DateTime? at}) async {
    final map = dismissedWrongSignatures()
      ..[signature] = at ?? DateTime.now();
    await _prefs.setString(
      _dismissedWrongKey,
      jsonEncode({
        for (final e in map.entries) e.key: e.value.millisecondsSinceEpoch,
      }),
    );
  }
}
