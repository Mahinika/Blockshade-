import 'preferences_store.dart';

/// Interactive onboarding shown once across the first three campaign levels.
class OnboardingService {
  static const String _completedKey = 'interactive_onboarding_completed';

  final PreferencesStore _prefs = PreferencesStore.instance;

  Future<bool> isOnboardingCompleted() async {
    await _prefs.ensureReady();
    return await _prefs.getBool(_completedKey) ?? false;
  }

  Future<void> markOnboardingCompleted() async {
    await _prefs.setBool(_completedKey, true);
  }

  Future<void> resetForTesting() async {
    await _prefs.remove(_completedKey);
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
