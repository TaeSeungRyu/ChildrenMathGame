import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_record.dart';

class RecordService extends GetxService {
  static const _storageKey = 'game_records_v3';

  late final SharedPreferences _prefs;

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
}
