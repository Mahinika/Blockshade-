/// Frequency rules for interstitials and the daily rewarded cap.
///
/// Pure logic so it can be tested without the Mobile Ads plugin.
class InterstitialPolicy {
  const InterstitialPolicy({
    this.levelsPerWorld = 20,
    this.minCompletedLevelsBetween = 3,
    this.minSecondsBetween = 90,
    this.firstCampaignLevelsWithoutAds = 5,
  });

  final int levelsPerWorld;
  final int minCompletedLevelsBetween;
  final int minSecondsBetween;
  final int firstCampaignLevelsWithoutAds;

  /// Campaign index starting at 1. World 1 level 1 is 1.
  int campaignLevel(int world, int levelInWorld) {
    if (world <= 1) return levelInWorld;
    return (world - 1) * levelsPerWorld + levelInWorld;
  }

  InterstitialDecision evaluate({
    required int world,
    required int levelInWorld,
    required bool adsRemoved,
    required bool adLoaded,
    required int completedLevelsSinceLastAd,
    required DateTime? lastShownAt,
    required DateTime now,
    required bool justFailedLevel,
    required bool justWatchedRewarded,
    required bool purchaseMadeInSession,
  }) {
    final secondsSince = lastShownAt == null ? -1 : now.difference(lastShownAt).inSeconds;
    final campaign = campaignLevel(world, levelInWorld);

    String? rule;
    if (adsRemoved) {
      rule = 'ads_removed';
    } else if (campaign <= firstCampaignLevelsWithoutAds) {
      rule = 'first_levels';
    } else if (justFailedLevel) {
      rule = 'after_fail';
    } else if (justWatchedRewarded) {
      rule = 'after_rv';
    } else if (purchaseMadeInSession) {
      rule = 'after_purchase';
    } else if (completedLevelsSinceLastAd < minCompletedLevelsBetween) {
      rule = 'level_gap';
    } else if (lastShownAt != null && secondsSince < minSecondsBetween) {
      rule = 'cooldown';
    } else if (!adLoaded) {
      rule = 'not_loaded';
    }

    return InterstitialDecision(
      show: rule == null,
      skipRule: rule,
      campaignLevel: campaign,
      levelsSinceLast: completedLevelsSinceLastAd,
      secondsSinceLast: secondsSince < 0 ? 0 : secondsSince,
    );
  }
}

class InterstitialDecision {
  const InterstitialDecision({
    required this.show,
    required this.skipRule,
    required this.campaignLevel,
    required this.levelsSinceLast,
    required this.secondsSinceLast,
  });

  final bool show;
  final String? skipRule;
  final int campaignLevel;
  final int levelsSinceLast;
  final int secondsSinceLast;
}

/// Rewarded videos allowed per local calendar day.
class RewardedDayQuota {
  const RewardedDayQuota({
    required this.dayKey,
    required this.count,
    required this.maxPerDay,
  });

  final String dayKey;
  final int count;
  final int maxPerDay;

  static String dayKeyFor(DateTime local) {
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  bool get canWatch => count < maxPerDay;
  int get remaining => (maxPerDay - count).clamp(0, maxPerDay);

  RewardedDayQuota rolledTo(DateTime localNow) {
    final key = dayKeyFor(localNow);
    if (key == dayKey) return this;
    return RewardedDayQuota(dayKey: key, count: 0, maxPerDay: maxPerDay);
  }

  /// Null when the cap for [localNow] is already used up.
  RewardedDayQuota? consume(DateTime localNow) {
    final current = rolledTo(localNow);
    if (!current.canWatch) return null;
    return RewardedDayQuota(
      dayKey: current.dayKey,
      count: current.count + 1,
      maxPerDay: current.maxPerDay,
    );
  }
}

enum RewardedBlockReason { none, notLoaded, dailyCap, noConsent }

class RewardedAvailability {
  const RewardedAvailability({
    required this.canShow,
    required this.reason,
    required this.messageSv,
    required this.watchedToday,
    required this.remaining,
  });

  final bool canShow;
  final RewardedBlockReason reason;
  final String messageSv;
  final int watchedToday;
  final int remaining;

  static RewardedAvailability decide({
    required bool consentAllowsAds,
    required bool adLoaded,
    required RewardedDayQuota quota,
    required DateTime now,
  }) {
    final rolled = quota.rolledTo(now);
    if (!consentAllowsAds) {
      return RewardedAvailability(
        canShow: false,
        reason: RewardedBlockReason.noConsent,
        messageSv: 'Annonser är avstängda tills du har gjort ett integritetsval.',
        watchedToday: rolled.count,
        remaining: rolled.remaining,
      );
    }
    if (!rolled.canWatch) {
      return RewardedAvailability(
        canShow: false,
        reason: RewardedBlockReason.dailyCap,
        messageSv: 'Du har tittat på dagens ${rolled.maxPerDay} videor. Kom tillbaka imorgon.',
        watchedToday: rolled.count,
        remaining: 0,
      );
    }
    if (!adLoaded) {
      return RewardedAvailability(
        canShow: false,
        reason: RewardedBlockReason.notLoaded,
        messageSv: 'Ingen video är laddad just nu. Försök igen om en stund.',
        watchedToday: rolled.count,
        remaining: rolled.remaining,
      );
    }
    return RewardedAvailability(
      canShow: true,
      reason: RewardedBlockReason.none,
      messageSv: '',
      watchedToday: rolled.count,
      remaining: rolled.remaining,
    );
  }
}
