import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/action_concept.dart';
import 'profile_service.dart';

/// Best-score + play-count store for the six action mini-games.
///
/// The action games don't go through `RecordService`/`GameRecord` (they're a
/// separate arcade track), so this tiny service keeps their persistent
/// progress: the highest score reached and how many times each concept was
/// played. Data is scoped per profile like the other stores.
///
/// A single JSON blob per profile: `{ "<concept.name>": {"best": N, "plays": M} }`.
class ActionScoreService extends GetxService {
  static const _storageBase = 'action_scores_v1';

  late final SharedPreferences _prefs;

  // concept.name -> best score, and -> plays. Reactive so intro/select screens
  // and game-over overlays rebuild when a run finishes.
  final RxMap<String, int> best = <String, int>{}.obs;
  final RxMap<String, int> plays = <String, int>{}.obs;

  // Falls back to the primary (empty) scope when ProfileService isn't
  // registered — e.g. service-only unit tests.
  String get _storageKey =>
      '$_storageBase${Get.isRegistered<ProfileService>() ? Get.find<ProfileService>().scopeSuffix : ''}';

  Future<ActionScoreService> init() async {
    _prefs = await SharedPreferences.getInstance();
    _load();
    return this;
  }

  void _load() {
    best.clear();
    plays.clear();
    final raw = _prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    for (final e in map.entries) {
      final v = e.value as Map<String, dynamic>;
      best[e.key] = (v['best'] as int?) ?? 0;
      plays[e.key] = (v['plays'] as int?) ?? 0;
    }
  }

  /// Re-reads scores for the active profile (call after a profile switch).
  void reload() => _load();

  int bestFor(ActionConcept concept) => best[concept.name] ?? 0;
  int playsFor(ActionConcept concept) => plays[concept.name] ?? 0;

  /// Records a finished run. Increments the play count and updates the best
  /// score. Returns true when [score] set a new record (strictly greater than
  /// the previous best; the very first run counts as a record only if > 0).
  Future<bool> report(ActionConcept concept, int score) async {
    final key = concept.name;
    plays[key] = (plays[key] ?? 0) + 1;
    final prev = best[key] ?? 0;
    final isNewBest = score > prev;
    if (isNewBest) best[key] = score;
    await _save();
    return isNewBest && score > 0;
  }

  Future<void> _save() async {
    final map = <String, dynamic>{};
    final keys = {...best.keys, ...plays.keys};
    for (final k in keys) {
      map[k] = {'best': best[k] ?? 0, 'plays': plays[k] ?? 0};
    }
    await _prefs.setString(_storageKey, jsonEncode(map));
  }
}
