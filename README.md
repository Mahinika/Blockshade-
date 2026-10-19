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

### AdMob ids

Test ids are the default. Replace them in one file before a store build:

`config/admob.json`

```json
{
  "ADMOB_APP_ID": "ca-app-pub-3940256099942544~3347511713",
  "ADMOB_INTERSTITIAL_UNIT_ID": "ca-app-pub-3940256099942544/1033173712",
  "ADMOB_REWARDED_UNIT_ID": "ca-app-pub-3940256099942544/5224354917",
  "PRIVACY_POLICY_URL": "https://mahinika.github.io/blockshade/privacy.html"
}
```

The Android manifest app id is read from that file at build time. Dart uses the same file, and `--dart-define=ADMOB_APP_ID=...` (plus `ADMOB_INTERSTITIAL_UNIT_ID` / `ADMOB_REWARDED_UNIT_ID` / `PRIVACY_POLICY_URL`) overrides it. UMP runs before ads initialize. Integritetsval in settings opens the privacy-options screen, which can show the consent form again. Integritetspolicy in settings and on that screen opens `PRIVACY_POLICY_URL`.

#### In-App Purchases (`lib/services/iap_catalog.dart`)

Create these ids in Play Console. Prices below are the proposed SEK amounts; the shop shows `ProductDetails.price` once the store responds.

| Product | Id suffix | Type | Proposed price |
|---|---|---|---|
| Remove ads | `remove_ads` | non-consumable | 39 kr |
| Starter pack (remove ads + hints) | `starter_pack` | non-consumable | 49 kr |
| Hints | `hints_small` / `hints_medium` / `hints_large` | consumable | 19 / 39 / 99 kr |
| Extra moves | `extra_moves` | consumable | 12 kr |
| Coins | `coins_small` / `coins_large` | consumable | 19 / 49 kr |

Full id: `se.cognifox.blockshade.<suffix>`.

Release signing: put `android/key.properties` (and the keystore) on the build machine. They are gitignored. Without them the release APK is signed with the debug key.

#### Firebase (Analytics & Remote Config)

1. Create a Firebase project at https://console.firebase.google.com
2. Add an Android app with package name `se.cognifox.blockshade`
3. Download `google-services.json` and place in `android/app/`
4. Enable Analytics and Remote Config in the Firebase console

### Remote Config Parameters

| Key | Default | Description |
|-----|---------|-------------|
| `min_level_for_interstitial` | 6 | First campaign level where interstitials can show (levels 1–5 never) |
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

- No interstitials during the first 5 campaign levels
- Max 1 interstitial per 3 completed levels
- Min 90 seconds between interstitials
- No interstitial after failure, after a rewarded video, or after a purchase in the session
- None if remove-ads is owned
- Rewarded video grants a reward only when an ad is loaded
- Max 6 rewarded videos per local day

## License

Proprietary - Cognifox Studio

## Contact

Cognifox Studio - https://cognifox.se
