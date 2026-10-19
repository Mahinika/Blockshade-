import 'package:shared_preferences/shared_preferences.dart';

/// Interactive onboarding shown once across the first three campaign levels.
class OnboardingService {
  static const String _completedKey = 'interactive_onboarding_completed';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<bool> isOnboardingCompleted() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return prefs.getBool(_completedKey) ?? false;
  }

  Future<void> markOnboardingCompleted() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool(_completedKey, true);
  }

  Future<void> resetForTesting() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.remove(_completedKey);
  }

  bool shouldShowForLevel(String levelId, bool onboardingCompleted) {
    if (onboardingCompleted) return false;
    return levelId == 'w1-001' || levelId == 'w1-002' || levelId == 'w1-003';
  }

  int stepIndexForLevel(String levelId) {
    switch (levelId) {
      case 'w1-001':
        return 0;
      case 'w1-002':
        return 1;
      case 'w1-003':
        return 2;
      default:
        return -1;
    }
  }
}
