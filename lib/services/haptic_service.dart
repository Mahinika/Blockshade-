import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Abstrakta haptikmönster enligt stilriktning Verkstad.
class HapticService {
  HapticService._();
  static final HapticService instance = HapticService._();

  static const _prefKey = 'haptics_enabled';
  bool _enabled = true;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_prefKey) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
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
