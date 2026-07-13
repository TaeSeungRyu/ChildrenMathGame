import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized audio (BGM + SFX) + haptic feedback.
///
/// BGM and SFX are now independent channels, each with its own on/off toggle
/// and 0..1 volume. Haptics always fire regardless of audio settings — they're
/// tactile cues that don't disturb anyone nearby.
///
/// Asset playback is wrapped in try/catch so missing audio files don't crash
/// the game — haptics still work even if no audio is bundled yet.
class SfxService extends GetxService {
  // Legacy single-mute key (pre BGM/SFX split). Read once on init to migrate.
  static const _legacyMuteKey = 'sfx_muted_v1';
  static const _sfxEnabledKey = 'sfx_enabled_v1';
  static const _sfxVolumeKey = 'sfx_volume_v1';
  static const _bgmEnabledKey = 'bgm_enabled_v1';
  static const _bgmVolumeKey = 'bgm_volume_v1';

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
  static const _bgmAsset = 'audio/bgm.wav';

  late final SharedPreferences _prefs;
  AudioPlayer? _sfxPlayer;
  AudioPlayer? _bgmPlayer;

  final sfxEnabled = true.obs;
  final sfxVolume = 0.8.obs;
  final bgmEnabled = true.obs;
  final bgmVolume = 0.5.obs;

  // Tracks whether the loop player is currently started, so [startBgm] is
  // idempotent (Home can call it on every entry without stacking players).
  bool _bgmStarted = false;

  Future<SfxService> init() async {
    _prefs = await SharedPreferences.getInstance();

    // Migrate the legacy single mute toggle: muted == true meant "no SFX".
    final legacyMuted = _prefs.getBool(_legacyMuteKey);
    sfxEnabled.value =
        _prefs.getBool(_sfxEnabledKey) ?? (legacyMuted == null ? true : !legacyMuted);
    sfxVolume.value = _prefs.getDouble(_sfxVolumeKey) ?? 0.8;
    bgmEnabled.value = _prefs.getBool(_bgmEnabledKey) ?? true;
    bgmVolume.value = _prefs.getDouble(_bgmVolumeKey) ?? 0.5;

    if (audioBackendEnabled) {
      try {
        final sfx = AudioPlayer();
        await sfx.setReleaseMode(ReleaseMode.stop);
        _sfxPlayer = sfx;
        final bgm = AudioPlayer();
        await bgm.setReleaseMode(ReleaseMode.loop);
        _bgmPlayer = bgm;
      } catch (_) {
        // Plugin unavailable (e.g. test environment) — keep players null.
      }
    }
    return this;
  }

  // ---- SFX settings ----

  Future<void> setSfxEnabled(bool value) async {
    sfxEnabled.value = value;
    await _prefs.setBool(_sfxEnabledKey, value);
  }

  Future<void> setSfxVolume(double value) async {
    sfxVolume.value = value.clamp(0.0, 1.0);
    await _prefs.setDouble(_sfxVolumeKey, sfxVolume.value);
  }

  // ---- BGM settings ----

  Future<void> setBgmEnabled(bool value) async {
    bgmEnabled.value = value;
    await _prefs.setBool(_bgmEnabledKey, value);
    if (value) {
      await startBgm();
    } else {
      await stopBgm();
    }
  }

  Future<void> setBgmVolume(double value) async {
    bgmVolume.value = value.clamp(0.0, 1.0);
    await _prefs.setDouble(_bgmVolumeKey, bgmVolume.value);
    if (_bgmStarted) {
      await _bgmPlayer?.setVolume(bgmVolume.value);
    }
  }

  /// Start the looping background track. Idempotent and a no-op when BGM is
  /// disabled or the audio backend is unavailable.
  Future<void> startBgm() async {
    if (!bgmEnabled.value || _bgmStarted) return;
    final player = _bgmPlayer;
    if (player == null) return;
    _bgmStarted = true;
    try {
      await player.setVolume(bgmVolume.value);
      await player.play(AssetSource(_bgmAsset));
    } catch (_) {
      _bgmStarted = false;
    }
  }

  Future<void> stopBgm() async {
    _bgmStarted = false;
    try {
      await _bgmPlayer?.stop();
    } catch (_) {}
  }

  // ---- SFX + haptics ----

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
    if (!sfxEnabled.value) return;
    final player = _sfxPlayer;
    if (player == null) return;
    // Fire-and-forget; swallow errors so missing files don't surface to users.
    player.play(AssetSource(assetPath), volume: sfxVolume.value).catchError((_) {});
  }

  @override
  void onClose() {
    _sfxPlayer?.dispose();
    _bgmPlayer?.dispose();
    super.onClose();
  }
}
