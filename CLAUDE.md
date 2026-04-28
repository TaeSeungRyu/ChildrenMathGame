# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Product

A children's math game (초등학생용). Flow:

1. **Splash** (`/splash`) — auto-advances to home after 2s.
2. **Home** (`/home`) — picks one of four operations (덧셈/뺄셈/곱셈/나눗셈), plus a "결과보기" button that opens past records.
3. **Level select** (`/level-select`) — 5 levels. Level *n* = *n*-digit operands (see "Difficulty rules" below).
4. **Game** (`/game`) — 10 problems, 120-second hard cap. Game ends on whichever comes first; remaining unanswered problems count as wrong.
5. **Result** (`/result`) — shows correct/wrong counts and persists a `GameRecord` (date, type, level, finishedAt, correct, wrong) via `RecordService`.
6. **Records** (`/records`) — list of past records, newest first.

### Difficulty rules

`ProblemGenerator` (`lib/app/data/services/problem_generator.dart`) is deliberately not "both operands n-digit" for every operation:

- **Addition / subtraction**: both operands are *n*-digit. Subtraction is reordered so `a >= b` (no negatives).
- **Multiplication**: one operand is *n*-digit, the other is single-digit. 5×5-digit multiplication would be unreasonable for kids.
- **Division**: dividend is *n*-digit, divisor is 2–9, and the dividend is constructed as `quotient * divisor` so results are always integers.

If you change these rules, update the level-select label (`'레벨 $n  ($n자릿수)'`) too — and double-check level 1 division stays solvable (only 8÷2, 9÷3, etc. exist).

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
- `RecordService` is registered in `main()` with `Get.putAsync` and is the single source of truth for record persistence (`shared_preferences`, JSON-encoded list under key `game_records_v1`). If you change the JSON shape, bump the key suffix to avoid crashes on old installs.
- Don't introduce another state-management or navigation library (Navigator 2.0, go_router, Riverpod, Bloc, Provider) — GetX is the chosen stack.
- Date formatting uses `lib/app/shared/date_format.dart` to avoid pulling `intl`. Keep using that helper.

## Stack & assets

- **Target platform**: Android only. Don't add iOS/web/desktop platform folders or platform-specific code paths. `flutter_launcher_icons` is configured with `ios: false` for the same reason.
- **Dart SDK**: `^3.11.4`. Code uses Dart 3 enhanced constructor inference (`colorScheme: .fromSeed(...)`, etc.) — don't "fix" those to fully-qualified forms.
- **Dependencies of note**: `get` (navigation + state), `shared_preferences` (record storage), `google_fonts` (typography), `flutter_launcher_icons` (dev).
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

Tests must call `SharedPreferences.setMockInitialValues({})` and register `RecordService` via `Get.putAsync` in `setUp` (and `Get.deleteAll(force: true)` in `tearDown`) before pumping `MyApp` — see `test/widget_test.dart` for the canonical pattern. Without this, any screen that touches `RecordService` will throw.
