# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Product

A children's math game (초등학생용). Flow:

1. **Splash** (`/splash`) — auto-advances to home after 2s.
2. **Home** (`/home`) — picks one of four operations (덧셈/뺄셈/곱셈/나눗셈), plus "도장판" / "구구단" / "결과보기" buttons.
3. **Level select** (`/level-select`) — 5 levels with progressive operand digit pairing (see "Difficulty rules" below).
   - **Times table select** (`/times-table-select`) — alternate entry from Home for practice mode. Picks 2단~9단 and jumps straight into the game.
4. **Game** (`/game`) — 10 problems (or 9 for 구구단), 180-second hard cap **in challenge mode only**. Game ends on whichever comes first; remaining unanswered problems count as wrong. The session is either **challenge** (timer + record save) or **practice** (no timer, no record save). Practice is opted into from the level-select segmented toggle, and times-table runs are always practice. The flag travels via `Get.arguments['isPractice']` (auto-true when `tableNumber` is set).
5. **Result** (`/result`) — shows correct/wrong counts, elapsed time, and persists a `GameRecord` (`finishedAt`, `type`, `level`, `correctCount`, `wrongCount`, `elapsedSeconds`) via `RecordService`. Elapsed time is computed as `totalSeconds - secondsLeft.value` at finish, so it equals the full 120s when the timer expires.
6. **Records** (`/records`) — list of past records, newest first. Each row has a delete button that opens an `AlertDialog` confirm; only on **확인** does the record get removed via `RecordService.delete` and from the in-memory `Rx` list.

### Difficulty rules

`ProblemGenerator` (`lib/app/data/services/problem_generator.dart`) pairs operand digit counts per level via `_digitsForLevel(level)`:

| Level | Operand A | Operand B |
|-------|-----------|-----------|
| 1     | 1-digit   | 1-digit   |
| 2     | 2-digit   | 1-digit   |
| 3     | 2-digit   | 2-digit   |
| 4     | 3-digit   | 2-digit   |
| 5     | 3-digit   | 3-digit   |

Operation specifics:

- **Addition / multiplication**: operands generated directly from the (A, B) digit pair.
- **Subtraction**: same pair, then swap so `a >= b` (no negatives).
- **Division**: dividend has A digits, divisor has B digits (1-digit divisor is restricted to 2–9 to skip trivial ÷1), dividend built as `quotient * divisor` with `quotient >= 2` to avoid trivial `n÷n=1`. Loop retries divisor picks that can't reach the dividend digit range.

If you change these rules, update **both** the `_digitsForLevel` table here and `_levelLabel` in `level_select_view.dart`. Level 1 division is intentionally a small set (e.g. `4÷2`, `6÷2`, `8÷2`, `6÷3`, `9÷3`, `8÷4`).

### Times-table practice mode

`ProblemGenerator.generateTimesTable(int table)` returns the 9 problems `1×N..9×N` (shuffled, `N` always the left operand). `GameController` enters this mode when `Get.arguments['tableNumber']` is non-null — in that case `type`/`level` args are ignored, `level` is set to 0 as a placeholder, and `isPractice` is forced to `true`. The Result screen renders "X단 연습" in the game-info row instead of "type 레벨 N", and never shows a "신기록" badge for practice runs.

### Challenge vs Practice

A run is either **challenge** (`isPractice == false`, default) or **practice** (`isPractice == true`). The timer infrastructure is shared: a single `elapsed` Rx counts up every second; challenge mode derives `remainingSeconds = totalSeconds - elapsed` and `_finish`-es at zero, while practice mode lets `elapsed` count up forever and never auto-finishes. Practice runs are not saved via `RecordService` (only "real" challenges contribute to streak/badges/stats), and the Result screen skips the new-record check for them. `GameView` swaps the AppBar timer (countdown red ↔ informational gray elapsed) and the progress bar (time drain ↔ problem progression) based on the mode. Don't reintroduce the old `secondsLeft` countdown Rx — derive from `elapsed`.

## Architecture

GetX module pattern under `lib/app/`:

```
lib/app/
  routes/      app_routes.dart (route name constants), app_pages.dart (GetPage list)
  data/
    models/    game_type.dart, problem.dart, game_record.dart
    services/  problem_generator.dart (pure), record_service.dart (GetxService, SharedPreferences)
  modules/<feature>/
    <feature>_view.dart        widgets (extends GetView<...>)
    <feature>_controller.dart  GetxController — state + business logic
    <feature>_binding.dart     Bindings — wires the controller to the route
  shared/      cross-cutting helpers (date_format.dart, etc.)
```

Conventions to keep:

- Each feature owns view + controller + binding; the binding is referenced from `app_pages.dart` via `GetPage(binding: ...)`. New screens should follow the same triplet.
- **Lazy vs eager binding**: bindings default to `Get.lazyPut`. That only instantiates the controller when something calls `Get.find<T>()` — `GetView<T>.controller` does this on first read. If a screen never reads `controller` in `build` (e.g. a splash that only kicks off a Timer in `onReady`, a side-effect-only page), `lazyPut` will silently never fire `onInit`/`onReady`. Use `Get.put(...)` for those screens. `SplashBinding` is the canonical example.
- Controllers receive screen arguments via `Get.arguments` in `onInit` (typed cast). Cross-screen data uses `Get.toNamed(route, arguments: ...)`, never globals.
- `RecordService` is registered in `main()` with `Get.putAsync` and is the single source of truth for record persistence (`shared_preferences`, JSON-encoded list under key `game_records_v2`). It identifies records for delete by `finishedAt` equality (DateTime millisecond precision is unique enough); if you ever add bulk-import or seeding, that assumption breaks and you'll need an explicit `id`. If you change the JSON shape, bump the key suffix to avoid `fromJson` crashes on old installs.
- `SfxService` is the single channel for SFX + haptic feedback (registered in `main()` via `Get.putAsync`). Haptics always fire; sound respects the persisted mute toggle (key `sfx_muted_v1`). Audio assets live in `assets/audio/` (`correct.wav`, `wrong.wav`, `finish.wav`, `tick.wav` — CC0 from Kenney Interface Sounds, see `assets/audio/LICENSE.txt`); `_play` swallows errors so missing files don't crash the game. Controllers must call `_sfx.click()` / `_sfx.correct()` etc. — don't sprinkle `HapticFeedback` calls directly elsewhere. Tests must set `SfxService.audioBackendEnabled = false` in `setUp` so the audioplayers MethodChannel (unregistered in widget-test isolates) isn't touched.
- Don't introduce another state-management or navigation library (Navigator 2.0, go_router, Riverpod, Bloc, Provider) — GetX is the chosen stack.
- Date formatting uses `lib/app/shared/date_format.dart` to avoid pulling `intl`. Keep using that helper.

## Stack & assets

- **Target platform**: Android only. Don't add iOS/web/desktop platform folders or platform-specific code paths. `flutter_launcher_icons` is configured with `ios: false` for the same reason.
- **Dart SDK**: `^3.11.4`. Code uses Dart 3 enhanced constructor inference (`colorScheme: .fromSeed(...)`, etc.) — don't "fix" those to fully-qualified forms.
- **Dependencies of note**: `get` (navigation + state), `shared_preferences` (record storage + mute toggle), `google_fonts` (typography), `audioplayers` (SFX), `lottie` (home/game animations), `flutter_launcher_icons` (dev).
- **Typography**: app-wide font is **Jua** (주아) via `GoogleFonts.juaTextTheme()` set on `MaterialApp.theme.textTheme` in `lib/main.dart`. Don't hard-code `fontFamily` on individual `TextStyle`s — read from `Theme.of(context).textTheme.<style>.fontFamily` if you need to mix sizes (see `splash_view.dart`). To swap fonts globally, change the single `juaTextTheme()` call. `google_fonts` downloads on first use; if you need offline guarantees, bundle the TTF in `assets/` and switch to `GoogleFonts.config.allowRuntimeFetching = false` plus a `pubspec.yaml` `fonts:` entry.
- **Assets**: `assets/images/` is wired as a directory entry in `pubspec.yaml` — drop files in and they're picked up automatically (no per-file listing). App launcher source: `assets/icon/app_icon.png` (replace and run the regenerate command below).

## Commands

All commands run from the repo root and require the Flutter SDK on PATH.

- `flutter pub get` — fetch dependencies
- `flutter run` — launch on the connected device/emulator with hot reload
- `flutter analyze` — static analysis (extends `package:flutter_lints/flutter.yaml`)
- `flutter test` — run all widget/unit tests
- `flutter test test/widget_test.dart` — single file
- `flutter test --plain-name "splash screen is shown"` — single test by name
- `flutter build apk` / `flutter build appbundle` — Android release artifacts
- `dart run flutter_launcher_icons` — regenerate Android/iOS launcher icons from `assets/icon/app_icon.png`

The project currently only configures the Android platform folder (`android/`). iOS/web/desktop folders need `flutter create --platforms=...` before building for those targets.

## Tests

Tests must call `SharedPreferences.setMockInitialValues({})` and register both `RecordService` and `SfxService` via `Get.putAsync` in `setUp` (and `Get.deleteAll(force: true)` in `tearDown`) before pumping `MyApp` — see `test/widget_test.dart` for the canonical pattern. Without this, any screen that touches those services will throw.
