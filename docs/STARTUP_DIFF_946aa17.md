# Diff audit: `946aa17` (known-good) → `main` (Verkstad + PR #2/#3)

## New / changed dependencies (pubspec)

| Package | At 946aa17 | After Verkstad+ |
|---------|------------|-----------------|
| `audioplayers` | present | unchanged |
| `shared_preferences`, ads, IAP, Firebase | present | unchanged |
| **No new pub packages** in Verkstad | | |

## New assets (Verkstad `b33cc2b`)

| Path | Notes |
|------|--------|
| `assets/fonts/PatrickHand-Regular.ttf` | matches `pubspec` family `PatrickHand` |
| `assets/fonts/Recursive-Variable.ttf` | ~2.3MB variable font; family `Recursive` |
| `assets/fonts/OFL-*.txt` | license only |
| `assets/sounds/wood_tap.wav` | matches `assets/sounds/` in pubspec |
| `test/goldens/verkstad_grid.png` | test only |

PR #2/#3 added `assets/levels/daily_fallback.json` (under existing `assets/levels/`).

Font paths in `pubspec.yaml` match filenames (case-sensitive) ✓

## New Dart services (Verkstad)

- `HapticService` – SharedPreferences only
- `SoundService` – **audioplayers** `AudioPlayer` (Verkstad added **sync `init()` before `runApp`** in `main.dart`)
- `JuiceService` – in-game only

## Android native / theme

- `values-v35` / `values-night-v35`: `LaunchTheme` + `NormalTheme`, edge-to-edge flags (unchanged since 946aa17; **suspect on Android 15** if splash never hands off)
- `AndroidManifest`: AdMob test meta-data (unchanged)
- Release: `isMinifyEnabled` + `isShrinkResources` + `proguard-rules.pro` (unchanged since 946aa17)

## Prime suspect (reasoning)

1. **Verkstad `main.dart`**: `await HapticService.instance.load()` and **`await SoundService.instance.init()` before `runApp`** – `setSource` on `AudioPlayer` can block or fail badly on some Android 15 devices; field-init `AudioPlayer()` touched native audio at class load.
2. **Heavy custom fonts** on first real frame via `AppTypography` (secondary to audio blocking).
3. **R8** stripping plugin classes in release (mitigated with audioplayers keep rules + `--no-shrink` test build).
