# Blockshade

A mobile block puzzle game for adults (18+) with the unique "shadow block" (eko-block) mechanic. Built with Flutter for Android.

## Game Concept

Slide blocks out of the grid in the right order within a limited number of moves. The twist: **shadow blocks** leave a ghostly shadow behind that blocks other blocks for 2 moves, adding a temporal planning dimension.

### Features

- **3 Worlds, 60 Levels**: Lagret (basics + shadow blocks), Valvet (lock/key mechanics), Hamnen (color gates)
- **Shadow Block Mechanic**: Unique twist where ejected shadow blocks leave blocking shadows for 2 moves
- **Procedurally Generated Levels**: All levels verified solvable by the built-in solver
- **Stars & Progression**: Earn 1-3 stars based on move efficiency
- **Economy**: Coins, lives (5 max, regenerate every 30 min), Undo boosters
- **Monetization**: Interstitial ads, rewarded video, IAP (remove ads, starter pack, coin packs)

## Development

### Prerequisites

- Flutter SDK 3.13+
- Android SDK
- Dart 3.x

### Setup

```bash
# Clone the repository
git clone https://github.com/Cognifox-Studio/Blockshade.git
cd Blockshade

# Get dependencies
flutter pub get

# Run the app (debug mode)
flutter run
```

### Build Debug APK

```bash
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

### Build Release APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Run Tests

```bash
flutter test
```

### Run Full CI Check

```bash
./scripts/ci_check.sh
```

This runs:
1. `flutter pub get`
2. `flutter analyze --fatal-infos`
3. `flutter test`
4. Verifies all 60 levels are present and solvable

## Project Structure

```
lib/
├── main.dart              # App entry point
├── models/                # Data models
│   ├── block.dart         # Block, Direction, EchoShadow
│   ├── gate.dart          # Color gates
│   ├── level.dart         # Level definition
│   ├── game_state.dart    # Game state and rules
│   └── player_progress.dart
├── services/
│   ├── solver.dart        # BFS solver for level validation
│   ├── level_generator.dart # Backwards level generation
│   ├── level_service.dart # Level loading
│   ├── ad_service.dart    # AdMob integration
│   ├── iap_service.dart   # In-app purchases
│   ├── analytics_service.dart
│   └── remote_config_service.dart
├── providers/
│   └── game_provider.dart # State management
├── screens/
│   ├── home_screen.dart
│   ├── world_map_screen.dart
│   ├── game_screen.dart
│   └── shop_screen.dart
├── widgets/
│   ├── game_grid.dart
│   ├── block_widget.dart
│   └── gate_widget.dart
└── utils/
    ├── colors.dart
    └── localization.dart  # Swedish primary, English fallback

assets/
└── levels/
    ├── world1.json        # 20 levels - Lagret
    ├── world2.json        # 20 levels - Valvet
    └── world3.json        # 20 levels - Hamnen

tool/
└── generate_levels.dart   # Level generation CLI tool
```

## Configuration

### TODO: Replace Before Release

The following placeholder IDs need to be replaced with real values before publishing:

#### AdMob (lib/services/ad_service.dart)

```dart
// Current: Test IDs
static const String _testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
static const String _testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';

// TODO: Replace with production IDs from AdMob console
// static const String _prodInterstitialAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
// static const String _prodRewardedAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
```

Also update `android/app/src/main/AndroidManifest.xml` with your AdMob App ID:
```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX"/>
```

#### In-App Purchases (lib/services/iap_service.dart)

```dart
// Current: Placeholder product IDs
static const String removeAds = 'se.cognifox.blockshade.remove_ads';
static const String starterPack = 'se.cognifox.blockshade.starter_pack';
static const String coinPackSmall = 'se.cognifox.blockshade.coins_small';
static const String coinPackLarge = 'se.cognifox.blockshade.coins_large';
static const String extraMoves = 'se.cognifox.blockshade.extra_moves';

// TODO: Create these products in Google Play Console and verify IDs match
```

#### Firebase (Analytics & Remote Config)

1. Create a Firebase project at https://console.firebase.google.com
2. Add an Android app with package name `se.cognifox.blockshade`
3. Download `google-services.json` and place in `android/app/`
4. Enable Analytics and Remote Config in the Firebase console

### Remote Config Parameters

| Key | Default | Description |
|-----|---------|-------------|
| `min_level_for_interstitial` | 15 | First level where interstitials can show |
| `levels_per_interstitial` | 3 | Min levels between interstitials |
| `min_seconds_between_interstitials` | 90 | Min seconds between interstitials |
| `max_rewarded_videos_per_day` | 6 | Daily RV cap |
| `extra_moves_coin_cost` | 900 | Coin cost for +5 moves (first fail) |
| `extra_moves_coin_cost_second` | 1900 | Coin cost for +5 moves (second fail) |

## Level Generation

Levels are generated using a backwards algorithm that guarantees solvability:

1. Start with an empty grid
2. Insert blocks one at a time, ensuring each has a clear exit path
3. Run the solver to verify and calculate optimal moves
4. Set move limit = optimal + slack (varies by difficulty)

To regenerate levels:

```bash
cd tool
dart generate_levels.dart
```

## Localization

The app uses Swedish as the primary language with English fallback. Strings are defined in `lib/utils/localization.dart`.

## Ad Rules (from Design Doc)

- No ads in first 10 levels
- Interstitials start from level 15
- Max 1 interstitial per 3 levels
- Min 90 seconds between interstitials
- No interstitial after failure or purchase
- Rewarded video available at failure (max 1 per attempt)
- Max 6 rewarded videos per day total

## License

Proprietary - Cognifox Studio

## Contact

Cognifox Studio - https://cognifox.se
