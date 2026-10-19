import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class StorageService {
  static const String _progressKey = 'player_progress';
  static const String _sessionIdKey = 'session_id';
  static const String _firstOpenKey = 'first_open';
  static const String _installDateKey = 'install_date';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<PlayerProgress> loadProgress() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_progressKey);
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
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(_progressKey, progress.toJsonString());
  }

  Future<String> getOrCreateSessionId() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    var sessionId = prefs.getString(_sessionIdKey);
    if (sessionId == null) {
      sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      await prefs.setString(_sessionIdKey, sessionId);
    }
    return sessionId;
  }

  Future<void> resetSessionId() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    await prefs.setString(_sessionIdKey, sessionId);
  }

  Future<bool> isFirstOpen() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final isFirst = prefs.getBool(_firstOpenKey) ?? true;
    if (isFirst) {
      await prefs.setBool(_firstOpenKey, false);
      await prefs.setString(_installDateKey, DateTime.now().toIso8601String());
    }
    return isFirst;
  }

  Future<int> getDaysSinceInstall() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final installDateStr = prefs.getString(_installDateKey);
    if (installDateStr == null) return 0;
    
    try {
      final installDate = DateTime.parse(installDateStr);
      return DateTime.now().difference(installDate).inDays;
    } catch (_) {
      return 0;
    }
  }

  Future<void> clearAll() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
