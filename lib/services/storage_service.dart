import '../models/models.dart';
import 'preferences_store.dart';

class StorageService {
  static const String _progressKey = 'player_progress';
  static const String _sessionIdKey = 'session_id';
  static const String _firstOpenKey = 'first_open';
  static const String _installDateKey = 'install_date';

  final PreferencesStore _prefs = PreferencesStore.instance;

  Future<void> init() async {
    await _prefs.ensureReady();
  }

  Future<PlayerProgress> loadProgress() async {
    await _prefs.ensureReady();
    final jsonString = await _prefs.getString(_progressKey);
    if (jsonString == null) {
      return PlayerProgress.initial();
    }
    try {
      return PlayerProgress.fromJsonString(jsonString);
    } catch (e) {
      print('Error loading progress: $e');
      return PlayerProgress.initial();
    }
  }

  Future<void> saveProgress(PlayerProgress progress) async {
    await _prefs.ensureReady();
    await _prefs.setString(_progressKey, progress.toJsonString());
  }

  Future<String> getOrCreateSessionId() async {
    await _prefs.ensureReady();
    var sessionId = await _prefs.getString(_sessionIdKey);
    if (sessionId == null) {
      sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      await _prefs.setString(_sessionIdKey, sessionId);
    }
    return sessionId;
  }

  Future<void> resetSessionId() async {
    await _prefs.ensureReady();
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    await _prefs.setString(_sessionIdKey, sessionId);
  }

  Future<bool> isFirstOpen() async {
    await _prefs.ensureReady();
    final isFirst = await _prefs.getBool(_firstOpenKey) ?? true;
    if (isFirst) {
      await _prefs.setBool(_firstOpenKey, false);
      await _prefs.setString(_installDateKey, DateTime.now().toIso8601String());
    }
    return isFirst;
  }

  Future<int> getDaysSinceInstall() async {
    await _prefs.ensureReady();
    final installDateStr = await _prefs.getString(_installDateKey);
    if (installDateStr == null) return 0;

    try {
      final installDate = DateTime.parse(installDateStr);
      return DateTime.now().difference(installDate).inDays;
    } catch (_) {
      return 0;
    }
  }

  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
