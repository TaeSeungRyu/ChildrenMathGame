# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project status

Freshly scaffolded Flutter project. `lib/main.dart` is still the default counter demo (now wrapped in `GetMaterialApp`) and `test/widget_test.dart` only verifies the counter — none of the children's math-game features implied by the project name exist yet. Treat feature work as greenfield.

Stack decisions already made:
- **Navigation/state**: GetX (`get: ^4.7.3`). Use `GetMaterialApp`, `Get.to(...)`, `Get.toNamed(...)`, named routes via `getPages`, and `GetxController` for state. Do not introduce a second navigation/state library (Navigator 2.0, go_router, Riverpod, Bloc, Provider) without checking with the user.
- **Assets**: images live under `assets/images/` and are wired in `pubspec.yaml` as a directory entry, so new files in that folder are picked up automatically — no need to list each one. App launcher icon source is `assets/icon/app_icon.png` (not yet committed at the time of writing).
- **Launcher icon**: managed by `flutter_launcher_icons` (config block at the bottom of `pubspec.yaml`). Regenerate native icon assets with `dart run flutter_launcher_icons` after replacing `assets/icon/app_icon.png`.

The Dart SDK constraint is `^3.11.4`. Code uses Dart 3 enhanced enum/constructor inference (e.g. `colorScheme: .fromSeed(...)`, `mainAxisAlignment: .center` in `lib/main.dart`); this requires the context type to be visible, so don't "fix" these to fully-qualified forms unless a refactor breaks the inference.

## Commands

All commands run from the repo root and require the Flutter SDK on PATH.

- `flutter pub get` — fetch dependencies (run after editing `pubspec.yaml` or first checkout)
- `flutter run` — launch on the connected device/emulator with hot reload
- `flutter analyze` — static analysis using `analysis_options.yaml` (extends `package:flutter_lints/flutter.yaml`)
- `flutter test` — run all widget/unit tests in `test/`
- `flutter test test/widget_test.dart` — run a single test file
- `flutter test --plain-name "Counter increments"` — run a single test by name
- `flutter build apk` / `flutter build appbundle` — Android release artifacts
- `dart run flutter_launcher_icons` — regenerate Android/iOS launcher icons from `assets/icon/app_icon.png`

The project currently only configures the Android platform folder (`android/`). iOS/web/desktop platform folders would need `flutter create --platforms=...` to be added before building for those targets.
