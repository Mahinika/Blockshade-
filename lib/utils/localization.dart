import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('sv'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('sv'),
    Locale('en'),
  ];

  static final Map<String, Map<String, String>> _localizedValues = {
    'sv': {
      'app_name': 'Blockshade',
      'play': 'Spela',
      'continue_game': 'Fortsätt',
      'settings': 'Inställningar',
      'shop': 'Butik',
      'world': 'Värld',
      'level': 'Bana',
      'moves': 'Drag',
      'moves_left': 'Drag kvar',
      'stars': 'Stjärnor',
      'coins': 'Mynt',
      'lives': 'Liv',
      'undo': 'Ångra',
      'pause': 'Paus',
      'resume': 'Fortsätt',
      'restart': 'Börja om',
      'quit': 'Avsluta',
      'next_level': 'Nästa bana',
      'level_complete': 'Banan klar!',
      'level_failed': 'Inga drag kvar',
      'out_of_moves': 'Dragen tog slut!',
      'extra_moves': '+5 drag',
      'watch_ad': 'Titta på video',
      'buy_coins': 'Köp för',
      'give_up': 'Ge upp',
      'double_coins': 'Dubbla mynt',
      'remove_ads': 'Ta bort annonser',
      'starter_pack': 'Startpaket',
      'coin_pack_small': 'Litet myntpaket',
      'coin_pack_large': 'Stort myntpaket',
      'locked': 'Låst',
      'unlocked': 'Upplåst',
      'tutorial_tap_block': 'Tryck på ett block för att flytta det',
      'tutorial_direction': 'Blocket rör sig åt pilens håll',
      'tutorial_exit': 'Flytta ut alla block ur banan',
      'tutorial_echo': 'Skuggblock lämnar en skugga i 2 drag',
      'tutorial_lock':
          'Låset öppnas när klossen med samma färg och mönster lämnar banan.',
      'tutorial_gate': 'Bara rätt färg passerar porten',
      'world_1_name': 'Lagret',
      'world_2_name': 'Valvet',
      'world_3_name': 'Hamnen',
      'no_lives': 'Inga liv kvar',
      'wait_for_life': 'Vänta på nytt liv eller titta på video',
      'new_life_in': 'Nytt liv om',
      'restore_purchases': 'Återställ köp',
      'sound': 'Ljud',
      'music': 'Musik',
      'vibration': 'Vibration',
      'on': 'På',
      'off': 'Av',
      'daily_puzzle': 'Dagens pussel',
      'daily_streak': 'Streak',
      'daily_complete': 'Klar idag',
      'daily_hint': 'Tips (video)',
      'daily_hint_body': 'Prova att flytta blocket som löser pusslet först.',
      'back_home': 'Tillbaka',
      'skip': 'Hoppa över',
      'got_it': 'Förstått',
    },
    'en': {
      'app_name': 'Blockshade',
      'play': 'Play',
      'continue_game': 'Continue',
      'settings': 'Settings',
      'shop': 'Shop',
      'world': 'World',
      'level': 'Level',
      'moves': 'Moves',
      'moves_left': 'Moves left',
      'stars': 'Stars',
      'coins': 'Coins',
      'lives': 'Lives',
      'undo': 'Undo',
      'pause': 'Pause',
      'resume': 'Resume',
      'restart': 'Restart',
      'quit': 'Quit',
      'next_level': 'Next level',
      'level_complete': 'Level complete!',
      'level_failed': 'Out of moves',
      'out_of_moves': 'No moves left!',
      'extra_moves': '+5 moves',
      'watch_ad': 'Watch video',
      'buy_coins': 'Buy for',
      'give_up': 'Give up',
      'double_coins': 'Double coins',
      'remove_ads': 'Remove ads',
      'starter_pack': 'Starter pack',
      'coin_pack_small': 'Small coin pack',
      'coin_pack_large': 'Large coin pack',
      'locked': 'Locked',
      'unlocked': 'Unlocked',
      'tutorial_tap_block': 'Tap a block to move it',
      'tutorial_direction': 'The block moves in the arrow direction',
      'tutorial_exit': 'Move all blocks out of the grid',
      'tutorial_echo': 'Shadow blocks leave a shadow for 2 moves',
      'tutorial_lock':
          'The lock opens when the block with the same color and pattern leaves the board.',
      'tutorial_gate': 'Only matching colors pass the gate',
      'world_1_name': 'The Warehouse',
      'world_2_name': 'The Vault',
      'world_3_name': 'The Harbor',
      'no_lives': 'No lives left',
      'wait_for_life': 'Wait for a new life or watch a video',
      'new_life_in': 'New life in',
      'restore_purchases': 'Restore purchases',
      'sound': 'Sound',
      'music': 'Music',
      'vibration': 'Vibration',
      'on': 'On',
      'off': 'Off',
      'daily_puzzle': 'Daily puzzle',
      'daily_streak': 'Streak',
      'daily_complete': 'Done today',
      'daily_hint': 'Hint (video)',
      'daily_hint_body': 'Try moving the block that starts the solution.',
      'back_home': 'Back',
      'skip': 'Skip',
      'got_it': 'Got it',
    },
  };

  String translate(String key) {
    final langCode = locale.languageCode;
    final values = _localizedValues[langCode] ?? _localizedValues['sv']!;
    return values[key] ?? _localizedValues['sv']![key] ?? key;
  }

  String get appName => translate('app_name');
  String get play => translate('play');
  String get continueGame => translate('continue_game');
  String get settings => translate('settings');
  String get shop => translate('shop');
  String get world => translate('world');
  String get level => translate('level');
  String get moves => translate('moves');
  String get movesLeft => translate('moves_left');
  String get stars => translate('stars');
  String get coins => translate('coins');
  String get lives => translate('lives');
  String get undo => translate('undo');
  String get pause => translate('pause');
  String get resume => translate('resume');
  String get restart => translate('restart');
  String get quit => translate('quit');
  String get nextLevel => translate('next_level');
  String get levelComplete => translate('level_complete');
  String get levelFailed => translate('level_failed');
  String get outOfMoves => translate('out_of_moves');
  String get extraMoves => translate('extra_moves');
  String get watchAd => translate('watch_ad');
  String get buyCoins => translate('buy_coins');
  String get giveUp => translate('give_up');
  String get doubleCoins => translate('double_coins');
  String get removeAds => translate('remove_ads');
  String get starterPack => translate('starter_pack');
  String get coinPackSmall => translate('coin_pack_small');
  String get coinPackLarge => translate('coin_pack_large');
  String get locked => translate('locked');
  String get unlocked => translate('unlocked');
  String get noLives => translate('no_lives');
  String get waitForLife => translate('wait_for_life');
  String get newLifeIn => translate('new_life_in');
  String get restorePurchases => translate('restore_purchases');
  String get sound => translate('sound');
  String get music => translate('music');
  String get vibration => translate('vibration');
  String get on => translate('on');
  String get off => translate('off');
  String get dailyPuzzle => translate('daily_puzzle');
  String get dailyStreak => translate('daily_streak');
  String get dailyComplete => translate('daily_complete');
  String get dailyHint => translate('daily_hint');
  String get dailyHintBody => translate('daily_hint_body');
  String get backHome => translate('back_home');
  String get skip => translate('skip');
  String get gotIt => translate('got_it');
  String get tutorialTapBlock => translate('tutorial_tap_block');
  String get tutorialDirection => translate('tutorial_direction');
  String get tutorialExit => translate('tutorial_exit');
  String get tutorialEcho => translate('tutorial_echo');
  String get tutorialLock => translate('tutorial_lock');

  /// Toast when a locked block is tapped. Swedish: "Få ut den blå klossen först".
  String lockKeyFirst(String colorName) {
    final name = _colorAdjective(colorName);
    if (locale.languageCode == 'en') {
      return 'Get the $name block out first';
    }
    return 'Få ut den $name klossen först';
  }

  String _colorAdjective(String colorName) {
    final english = locale.languageCode == 'en';
    switch (colorName.toLowerCase()) {
      case 'red':
        return english ? 'red' : 'röda';
      case 'blue':
        return english ? 'blue' : 'blå';
      case 'yellow':
        return english ? 'yellow' : 'gula';
      case 'green':
        return english ? 'green' : 'gröna';
      case 'purple':
        return english ? 'purple' : 'lila';
      case 'orange':
        return english ? 'orange' : 'orange';
      case 'cyan':
        return english ? 'cyan' : 'turkosa';
      case 'pink':
        return english ? 'pink' : 'rosa';
      default:
        return colorName;
    }
  }

  String worldName(int worldNum) {
    return translate('world_${worldNum}_name');
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['sv', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
