import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:blockshade/services/onboarding_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnboardingService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('onboarding is shown only once', () async {
      final service = OnboardingService();
      await service.init();

      expect(await service.isOnboardingCompleted(), isFalse);
      expect(service.shouldShowForLevel('w1-001', false), isTrue);
      expect(service.shouldShowForLevel('w1-004', false), isFalse);

      await service.markOnboardingCompleted();

      expect(await service.isOnboardingCompleted(), isTrue);
      expect(service.shouldShowForLevel('w1-001', true), isFalse);
      expect(service.shouldShowForLevel('w1-002', true), isFalse);
      expect(service.shouldShowForLevel('w1-003', true), isFalse);
    });

    test('lock hint is shown once, only on levels that have a lock', () async {
      final service = OnboardingService();
      await service.init();

      expect(await service.hasSeenLockHint(), isFalse);
      expect(
        service.shouldShowLockHint(levelHasLockedBlock: false, hintAlreadySeen: false),
        isFalse,
      );
      expect(
        service.shouldShowLockHint(levelHasLockedBlock: true, hintAlreadySeen: false),
        isTrue,
      );

      await service.markLockHintSeen();

      expect(await service.hasSeenLockHint(), isTrue);
      expect(
        service.shouldShowLockHint(levelHasLockedBlock: true, hintAlreadySeen: true),
        isFalse,
      );

      await service.resetForTesting();
      expect(await service.hasSeenLockHint(), isFalse);
      expect(await service.isOnboardingCompleted(), isFalse);
    });

    test('step index maps first three levels', () {
      final service = OnboardingService();
      expect(service.stepIndexForLevel('w1-001'), 0);
      expect(service.stepIndexForLevel('w1-002'), 1);
      expect(service.stepIndexForLevel('w1-003'), 2);
      expect(service.stepIndexForLevel('w1-010'), -1);
    });
  });
}
