# Mafia Roles

A tiny, fully offline Android app whose only job is to randomly and
securely assign Mafia game roles at the start of a game.

No login, no database, no ads, no sound, no analytics, no network access.
Everything lives in RAM and disappears the moment "End Game" is pressed.

## Requirements

- Flutter 3.13 or newer (uses `PopScope`; if you're on an older Flutter,
  swap `PopScope` in `lib/screens/game_screen.dart` for `WillPopScope`).
- No other setup — the only external package is `flutter_svg`, used purely
  to render the role thumbnails.

## Running it

```bash
flutter pub get
flutter run
```

## Building a release APK

```bash
flutter build apk --release
```

The output APK will be small since the only assets are nine tiny SVG
icons (a few hundred bytes to a couple of KB each) and there are no fonts,
images, or bundled libraries beyond `flutter_svg`.

## Project structure

```
lib/
  constants/
    app_colors.dart     # every color in one place
    app_theme.dart       # single dark Material theme
    role_data.dart       # role names, descriptions, icons, colors
  models/
    role_type.dart       # RoleType enum
    role.dart             # immutable Role data class
  logic/
    role_generator.dart  # role-count tables per player count + secure shuffle
    game_state.dart       # in-memory (RAM-only) assignment storage
  screens/
    player_count_screen.dart   # Screen 1: pick player count
    game_screen.dart            # player-by-player reveal flow
  widgets/
    role_reveal_card.dart       # closed/revealed card + fade-scale animation
    preset_dialog.dart          # 5-player preset A/B chooser
  main.dart
assets/
  icons/*.svg           # one thumbnail per role
```

## How the "assign once, never change" rule is enforced

`GameState.startGame()` is the single place a shuffle happens
(`RoleGenerator.generate`, using `Random.secure()` with a Fisher-Yates
shuffle). The resulting list is stored in `GameState` and never
reshuffled or regenerated — `GameState.roleFor(playerNumber)` just reads
from that fixed list. The only way to get a new shuffle is to call
`GameState.endGame()` (wipes the list) and pick a player count again.

## Extending with new roles or combinations

1. Add a new value to `RoleType` (`lib/models/role_type.dart`).
2. Add its name/description/color/icon to `RoleData.all`
   (`lib/constants/role_data.dart`).
3. Drop a small SVG thumbnail into `assets/icons/`.
4. Reference the new `RoleType` in whichever player-count list(s) in
   `RoleGenerator._composition()` should use it.

No UI code needs to change for a new role to work correctly.

## Monetization (AdMob)

The app ships with Google Mobile Ads wired in, using **Google's public
test ad unit IDs** by default (safe to build/run as-is - they always
serve real test ads, never risking a policy violation, and never earn
real money either).

To switch to your own ads once you have an AdMob account:

1. Register your app in the AdMob console and create a banner + an
   interstitial ad unit.
2. Update `lib/constants/ad_ids.dart` with your real ad unit IDs.
3. Update the AdMob **App ID** in `.github/workflows/build_apk.yml`
   (search for `ca-app-pub-3940256099942544~3347511713` and replace it
   with your app's real App ID from the AdMob console). This has to be
   re-patched into `AndroidManifest.xml` on every build because that
   file is regenerated fresh each time - the workflow already does this
   automatically, you just need to swap the ID.

Ads require internet only for themselves - if the device is offline,
ad loading simply fails silently, and gameplay (which needs no network
at all) is completely unaffected.
