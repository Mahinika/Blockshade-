import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ljud med separata volymer; CC0-träklick när filer finns.
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  static const _sfxKey = 'sfx_enabled';
  static const _musicKey = 'music_enabled';

  final AudioPlayer _sfxPlayer = AudioPlayer();
  bool _sfxEnabled = true;
  bool _musicEnabled = true;
  bool _woodClickAvailable = false;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _sfxEnabled = prefs.getBool(_sfxKey) ?? true;
    _musicEnabled = prefs.getBool(_musicKey) ?? true;
    try {
      await _sfxPlayer.setSource(AssetSource('sounds/wood_tap.wav'));
      _woodClickAvailable = true;
    } catch (e) {
      _woodClickAvailable = false;
      debugPrint('Wood tap sound not loaded (hook only): $e');
    }
  }

  Future<void> setSfxEnabled(bool value) async {
    _sfxEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sfxKey, value);
  }

  Future<void> setMusicEnabled(bool value) async {
    _musicEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_musicKey, value);
  }

  bool get sfxEnabled => _sfxEnabled;
  bool get musicEnabled => _musicEnabled;

  Future<void> playWoodKnock() async {
    if (!_sfxEnabled || !_woodClickAvailable) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('sounds/wood_tap.wav'));
    } catch (e) {
      debugPrint('playWoodKnock: $e');
    }
  }

  Future<void> playWoodSlide() async {
    await playWoodKnock();
  }

  void dispose() {
    _sfxPlayer.dispose();
  }
}
