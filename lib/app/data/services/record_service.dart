import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_record.dart';

class RecordService extends GetxService {
  static const _storageKey = 'game_records_v1';

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
    await _prefs.setString(
      _storageKey,
      jsonEncode(records.map((r) => r.toJson()).toList()),
    );
  }
}
