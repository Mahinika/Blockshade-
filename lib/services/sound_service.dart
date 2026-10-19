import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'preferences_store.dart';

/// Ljud med separata volymer; CC0-träklick när filer finns.
/// AudioPlayer skapas lazy (inte vid processstart) för att undvika native-häng.
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  static const _sfxKey = 'sfx_enabled';
  static const _musicKey = 'music_enabled';

  final PreferencesStore _prefs = PreferencesStore.instance;
  AudioPlayer? _sfxPlayer;
  bool _sfxEnabled = true;
  bool _musicEnabled = true;
  bool _woodClickAvailable = false;
  bool _initAttempted = false;

  Future<void> init() async {
    if (_initAttempted) return;
    _initAttempted = true;

    await _prefs.ensureReady();
    _sfxEnabled = await _prefs.getBool(_sfxKey) ?? true;
    _musicEnabled = await _prefs.getBool(_musicKey) ?? true;
    try {
      _sfxPlayer ??= AudioPlayer();
      await _sfxPlayer!.setSource(AssetSource('sounds/wood_tap.wav'));
      _woodClickAvailable = true;
    } catch (e) {
      _woodClickAvailable = false;
      debugPrint('Wood tap sound not loaded (hook only): $e');
    }
  }

  Future<void> setSfxEnabled(bool value) async {
    _sfxEnabled = value;
    await _prefs.setBool(_sfxKey, value);
  }

  Future<void> setMusicEnabled(bool value) async {
    _musicEnabled = value;
    await _prefs.setBool(_musicKey, value);
  }

  bool get sfxEnabled => _sfxEnabled;
  bool get musicEnabled => _musicEnabled;

  Future<void> playWoodKnock() async {
    if (!_sfxEnabled || !_woodClickAvailable) return;
    try {
      final player = _sfxPlayer;
      if (player == null) return;
      await player.stop();
      await player.play(AssetSource('sounds/wood_tap.wav'));
    } catch (e) {
      debugPrint('playWoodKnock: $e');
    }
  }

  Future<void> playWoodSlide() async {
    await playWoodKnock();
  }

  void dispose() {
    _sfxPlayer?.dispose();
    _sfxPlayer = null;
  }
}
