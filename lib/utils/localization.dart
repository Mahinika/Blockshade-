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
      'tutorial_lock': 'Upplås det låsta blocket först',
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
      'tutorial_lock': 'Unlock the locked block first',
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
