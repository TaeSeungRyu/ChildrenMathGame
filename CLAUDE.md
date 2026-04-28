# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project status

This is a freshly scaffolded Flutter project (`flutter create` output). `lib/main.dart` is still the default counter demo and `test/widget_test.dart` only verifies the counter — none of the children's math-game features implied by the project name exist yet. Treat any feature work as greenfield: there is no established architecture, state-management choice, routing, theming, or asset pipeline to follow.

The Dart SDK constraint in `pubspec.yaml` is `^3.11.4`. Code uses Dart 3 enhanced enum/constructor inference (e.g. `colorScheme: .fromSeed(...)`, `mainAxisAlignment: .center` in `lib/main.dart`); this requires the context type to be visible, so don't "fix" these to fully-qualified forms unless a refactor breaks the inference.

## Commands

All commands run from the repo root and require the Flutter SDK on PATH.

- `flutter pub get` — fetch dependencies (run after editing `pubspec.yaml` or first checkout)
- `flutter run` — launch on the connected device/emulator with hot reload
- `flutter analyze` — static analysis using `analysis_options.yaml` (extends `package:flutter_lints/flutter.yaml`)
- `flutter test` — run all widget/unit tests in `test/`
- `flutter test test/widget_test.dart` — run a single test file
- `flutter test --plain-name "Counter increments"` — run a single test by name
- `flutter build apk` / `flutter build appbundle` — Android release artifacts

The project currently only configures the Android platform folder (`android/`). iOS/web/desktop platform folders would need `flutter create --platforms=...` to be added before building for those targets.
