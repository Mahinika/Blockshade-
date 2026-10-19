import 'package:flutter/services.dart';

import 'preferences_store.dart';

/// Abstrakta haptikmönster enligt stilriktning Verkstad.
class HapticService {
  HapticService._();
  static final HapticService instance = HapticService._();

  static const _prefKey = 'haptics_enabled';
  final PreferencesStore _prefs = PreferencesStore.instance;
  bool _enabled = true;

  Future<void> load() async {
    await _prefs.ensureReady();
    _enabled = await _prefs.getBool(_prefKey) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    await _prefs.setBool(_prefKey, value);
  }

  bool get isEnabled => _enabled;

  Future<void> light() async {
    if (!_enabled) return;
    await HapticFeedback.lightImpact();
  }

  Future<void> medium() async {
    if (!_enabled) return;
    await HapticFeedback.mediumImpact();
  }

  Future<void> heavy() async {
    if (!_enabled) return;
    await HapticFeedback.heavyImpact();
  }

  Future<void> success() async {
    if (!_enabled) return;
    await HapticFeedback.mediumImpact();
  }

  Future<void> error() async {
    if (!_enabled) return;
    await HapticFeedback.heavyImpact();
  }
}
