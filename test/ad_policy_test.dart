import 'package:flutter_test/flutter_test.dart';
import 'package:blockshade/services/ad_policy.dart';

void main() {
  const policy = InterstitialPolicy();
  final t0 = DateTime(2026, 10, 19, 12);

  InterstitialDecision eval({
    int world = 1,
    int level = 8,
    bool adsRemoved = false,
    bool adLoaded = true,
    int completed = 3,
    DateTime? lastShown,
    bool failed = false,
    bool rewarded = false,
    bool purchased = false,
    DateTime? now,
  }) {
    return policy.evaluate(
      world: world,
      levelInWorld: level,
      adsRemoved: adsRemoved,
      adLoaded: adLoaded,
      completedLevelsSinceLastAd: completed,
      lastShownAt: lastShown,
      now: now ?? t0,
      justFailedLevel: failed,
      justWatchedRewarded: rewarded,
      purchaseMadeInSession: purchased,
    );
  }

  test('campaign index treats world 2 level 1 as level 21', () {
    expect(policy.campaignLevel(1, 5), 5);
    expect(policy.campaignLevel(2, 1), 21);
  });

  test('never shows during the first 5 campaign levels', () {
    final decision = eval(world: 1, level: 5, completed: 5);
    expect(decision.show, isFalse);
    expect(decision.skipRule, 'first_levels');
  });

  test('shows on level 6 after 3 completions and 90 seconds', () {
    final decision = eval(
      level: 6,
      completed: 3,
      lastShown: t0.subtract(const Duration(seconds: 90)),
    );
    expect(decision.show, isTrue);
    expect(decision.skipRule, isNull);
  });

  test('blocks when fewer than 3 levels were completed', () {
    expect(eval(completed: 2).skipRule, 'level_gap');
  });

  test('blocks when the last interstitial was under 90 seconds ago', () {
    final decision = eval(lastShown: t0.subtract(const Duration(seconds: 89)));
    expect(decision.show, isFalse);
    expect(decision.skipRule, 'cooldown');
  });

  test('blocks when remove-ads is owned or the ad is not loaded', () {
    expect(eval(adsRemoved: true).skipRule, 'ads_removed');
    expect(eval(adLoaded: false).skipRule, 'not_loaded');
  });

  test('rewarded quota is 6 per local day and resets the next day', () {
    const quota = RewardedDayQuota(dayKey: '2026-10-19', count: 0, maxPerDay: 6);
    final now = DateTime(2026, 10, 19, 23);
    RewardedDayQuota? current = quota;
    for (var i = 0; i < 6; i++) {
      current = current!.consume(now);
      expect(current, isNotNull);
    }
    expect(current!.consume(now), isNull);
    expect(current.canWatch, isFalse);

    final tomorrow = DateTime(2026, 10, 20, 0, 5);
    final rolled = current.rolledTo(tomorrow);
    expect(rolled.count, 0);
    expect(rolled.canWatch, isTrue);
    expect(rolled.consume(tomorrow)!.count, 1);
  });

  test('reward is offered only when an ad is loaded and the cap is open', () {
    const quota = RewardedDayQuota(dayKey: '2026-10-19', count: 6, maxPerDay: 6);
    final now = DateTime(2026, 10, 19, 8);
    final capped = RewardedAvailability.decide(
      consentAllowsAds: true,
      adLoaded: true,
      quota: quota,
      now: now,
    );
    expect(capped.canShow, isFalse);
    expect(capped.reason, RewardedBlockReason.dailyCap);
    expect(capped.messageSv, contains('6'));

    final missing = RewardedAvailability.decide(
      consentAllowsAds: true,
      adLoaded: false,
      quota: const RewardedDayQuota(dayKey: '2026-10-19', count: 1, maxPerDay: 6),
      now: now,
    );
    expect(missing.reason, RewardedBlockReason.notLoaded);
    expect(missing.messageSv, contains('Ingen video'));
    expect(missing.canShow, isFalse);
  });
}
