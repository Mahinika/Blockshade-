import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences with in-memory fallback when native/JNI storage fails (e.g. R8 on release).
class PreferencesStore {
  PreferencesStore._();
  static final PreferencesStore instance = PreferencesStore._();

  SharedPreferences? _native;
  final Map<String, Object?> _memory = {};
  bool _memoryOnly = false;
  bool _ready = false;

  bool get isMemoryOnly => _memoryOnly;

  Future<void> ensureReady() async {
    if (_ready) return;
    try {
      _native = await SharedPreferences.getInstance();
      _memoryOnly = false;
    } catch (e, stack) {
      debugPrint('PreferencesStore: native prefs unavailable ($e). Using memory.\n$stack');
      _memoryOnly = true;
      _native = null;
    }
    _ready = true;
  }

  void _activateMemoryFallback(Object error) {
    if (!_memoryOnly) {
      debugPrint('PreferencesStore: falling back to memory after error: $error');
      _memoryOnly = true;
      _native = null;
    }
  }

  Future<String?> getString(String key) async {
    await ensureReady();
    if (_memoryOnly) return _memory[key] as String?;
    try {
      return _native!.getString(key);
    } catch (e) {
      _activateMemoryFallback(e);
      return _memory[key] as String?;
    }
  }

  Future<bool> setString(String key, String value) async {
    await ensureReady();
    if (_memoryOnly) {
      _memory[key] = value;
      return true;
    }
    try {
      return await _native!.setString(key, value);
    } catch (e) {
      _activateMemoryFallback(e);
      _memory[key] = value;
      return true;
    }
  }

  Future<bool?> getBool(String key) async {
    await ensureReady();
    if (_memoryOnly) return _memory[key] as bool?;
    try {
      return _native!.getBool(key);
    } catch (e) {
      _activateMemoryFallback(e);
      return _memory[key] as bool?;
    }
  }

  Future<bool> setBool(String key, bool value) async {
    await ensureReady();
    if (_memoryOnly) {
      _memory[key] = value;
      return true;
    }
    try {
      return await _native!.setBool(key, value);
    } catch (e) {
      _activateMemoryFallback(e);
      _memory[key] = value;
      return true;
    }
  }

  Future<bool> remove(String key) async {
    await ensureReady();
    _memory.remove(key);
    if (_memoryOnly) return true;
    try {
      return await _native!.remove(key);
    } catch (e) {
      _activateMemoryFallback(e);
      return true;
    }
  }

  Future<bool> clear() async {
    await ensureReady();
    _memory.clear();
    if (_memoryOnly) return true;
    try {
      return await _native!.clear();
    } catch (e) {
      _activateMemoryFallback(e);
      return true;
    }
  }

  /// For tests only.
  @visibleForTesting
  void resetForTesting() {
    _native = null;
    _memory.clear();
    _memoryOnly = false;
    _ready = false;
  }
}
