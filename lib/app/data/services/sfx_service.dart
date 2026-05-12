import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized SFX + haptic feedback.
///
/// Haptics always fire regardless of mute state — they're tactile cues that
/// don't disturb anyone nearby. Sounds respect [isMuted].
///
/// Asset playback is wrapped in try/catch so missing audio files don't crash
/// the game — haptics still work even if no audio is bundled yet.
class SfxService extends GetxService {
  static const _muteKey = 'sfx_muted_v1';

  /// Set to false in tests to skip plugin initialization. The audioplayers
  /// MethodChannel is not registered in widget-test isolates, so constructing
  /// an [AudioPlayer] there raises an unhandled MissingPluginException.
  static bool audioBackendEnabled = true;

  // Asset paths are relative to the asset root configured in pubspec.yaml,
  // i.e. AssetSource('audio/correct.wav') resolves to assets/audio/correct.wav.
  static const _correctAsset = 'audio/correct.wav';
  static const _wrongAsset = 'audio/wrong.wav';
  static const _finishAsset = 'audio/finish.wav';
  static const _tickAsset = 'audio/tick.wav';

  late final SharedPreferences _prefs;
  AudioPlayer? _player;

  final isMuted = false.obs;

  Future<SfxService> init() async {
    _prefs = await SharedPreferences.getInstance();
    isMuted.value = _prefs.getBool(_muteKey) ?? false;
    if (audioBackendEnabled) {
      final player = AudioPlayer();
      try {
        await player.setReleaseMode(ReleaseMode.stop);
        _player = player;
      } catch (_) {
        // Plugin unavailable (e.g. test environment) — keep _player null.
      }
    }
    return this;
  }

  Future<void> toggleMute() async {
    isMuted.value = !isMuted.value;
    await _prefs.setBool(_muteKey, isMuted.value);
  }

  void click() {
    HapticFeedback.selectionClick();
  }

  void correct() {
    HapticFeedback.mediumImpact();
    _play(_correctAsset);
  }

  void wrong() {
    HapticFeedback.heavyImpact();
    _play(_wrongAsset);
  }

  void finish() {
    HapticFeedback.heavyImpact();
    _play(_finishAsset);
  }

  void tick() {
    HapticFeedback.lightImpact();
    _play(_tickAsset);
  }

  // Combo milestone celebration. Audio is intentionally omitted — `correct()`
  // fires on the same submit, so we'd just double up. The heavy haptic alone
  // is the extra emphasis that distinguishes a milestone from a normal hit.
  void combo() {
    HapticFeedback.heavyImpact();
  }

  void _play(String assetPath) {
    if (isMuted.value) return;
    final player = _player;
    if (player == null) return;
    // Fire-and-forget; swallow errors so missing files don't surface to users.
    player.play(AssetSource(assetPath)).catchError((_) {});
  }

  @override
  void onClose() {
    _player?.dispose();
    super.onClose();
  }
}
