# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Product

**연산 히어로** — a children's math game (초등학생용, target 6–9세). The app display title is `연산 히어로`; the Flutter package is still `children_math_game`. Fully offline, Android-only, no accounts, no network, no ads (Play Store children's-app compliance).

High-level flow:

1. **Splash** (`/splash`) — 2s, then routes to **Home** normally, or to **Tutorial** on first launch (`ProfileService.tutorialSeen == false`).
2. **Tutorial** (`/tutorial`) — onboarding walkthrough. Auto-shown once on first run (marks `tutorialSeen` on entry so a force-quit still counts). Re-openable from the Home AppBar help button.
3. **Home** (`/home`) — a 3-tab container (`IndexedStack`), driven by `HomeController.tabIndex`:
   - **학습 (Learn)** — Lottie banner + streak badge, daily-mission card, weakness recommendation card, the four basic-operation tiles (덧셈/뺄셈/곱셈/나눗셈 → level select), and a "특별 모드" row (구구단 / 혼합 / 방정식 / 플래시 / 어림셈).
   - **게임 (Games)** — six action mini-games (몬스터 처치 / 풍선 터뜨리기 / 타워 디펜스 / 두더지 잡기 / 숫자 사다리 / 물고기 잡기). Each tile opens the shared action-select screen; 물고기 잡기 is still a "coming soon" shell.
   - **기록 (Records)** — meta-tool hub: 도장판(badges) / 오답 노트(wrong notebook) / 결과 보기(records) / 학습 통계(stats) / 복습하기(review-select).
   The shared AppBar (editable name `"{name} 히어로!"`, tutorial button, mute toggle) stays across all tabs.
4. **Game** (`/game`) — the universal session screen for all learning modes. See "Session modes" and "Learning game types" below.
5. **Result** (`/result`) — correct/wrong/unsolved counts, elapsed time, max combo, and a "신기록" badge when applicable. Persists a `GameRecord` via `RecordService` (unless practice/구구단).
6. **Records** (`/records`) — past records newest-first; row → **Record detail** (`/record-detail`) showing every attempt. Delete opens an `AlertDialog`; only **확인** removes via `RecordService.delete`.

The six **action mini-games** (`/monster-game`, `/balloon-game`, `/tower-defense`, `/mole-game`, `/ladder-game`, `/fishing-game`) are a separate arcade track — they do **not** go through `/game`, `/result`, or `RecordService` (MVP stage, no record persistence yet).

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

If you change these rules, update **both** the `_digitsForLevel` table here and `_levelLabel` in `level_select_view.dart`. Level 1 division is intentionally a small set (e.g. `4÷2`, `6÷2`, `8÷2`, `6÷3`, `9÷3`, `8÷4`). The action-select screen (`action_select_controller.dart`) deliberately mirrors this same digit ladder as its `digitChoices`, and generates via `ProblemGenerator.generateOneForDigits(...)` which bypasses the level→digits table.

### `GameType` — concrete ops vs roll-up labels

`GameType` (`lib/app/data/models/game_type.dart`) has eight values with a `symbol` + `label`:

- **Concrete ops** (drive problem generation): `addition` (+), `subtraction` (−), `multiplication` (×), `division` (÷).
- **Roll-up labels** (`isRollup == true`, record-level only — never generate problems directly): `mixed` (혼), `equation` (?), `flash` (⚡), `estimation` (≈).

A roll-up record's `type` is the label, but each `Problem`/`ProblemAttempt` inside still carries its own concrete op. `_oneForDigits` throws if asked to generate a roll-up type directly; `mixed` dispatches through `generateMixed`, while `equation`/`flash`/`estimation` reuse `generate` with the chosen concrete sub-op and only roll up at the record level.

### Session modes

A `/game` run is one of these shapes, encoded as **independent boolean flags** on `GameController` (read from `Get.arguments` in `onInit`) rather than a single enum, because times-table/mixed/equation/flash/estimation already have their own toggles. The persisted `GameRecord.mode` (`SessionMode`) is `challenge`, `timeAttack`, or `endless`:

- **Challenge** (default) — fixed 10 problems, 180s countdown (`challengeSeconds`). Persists a record with `mode = challenge`. The only mode that contributes to "만점"/master-badge unlocks.
- **Practice** (`isPractice == true`) — no timer limit, **not persisted**. Auto-true for times-table runs. Keeps streak/badges/stats free of casual-practice noise.
- **Time attack** (`isTimeAttack == true`) — 60s countdown (`timeAttackSeconds`), open-ended: each submit appends one freshly generated problem; the timer is the only thing that ends it. Persists `mode = timeAttack`.
- **Endless / 연속도전** (`isEndless == true`) — no timer, no problem cap; a new problem appends after every correct answer, and the session ends on the **first wrong** submission (the wrong attempt is preserved in the record). Persists `mode = endless`. `correctCount` = longest streak achieved.

Challenge / time-attack / endless / practice are chosen from the **level-select segmented toggle** (`LevelSelectMode`: `challenge`/`timeAttack`/`endless`/`practice`). Time-attack and endless are **not offered** for times-table, mixed, equation, flash, or estimation sessions.

**Shared timer infra**: a single `elapsed` Rx counts up every second. Challenge/time-attack derive `remainingSeconds = totalSeconds - elapsed` (with `totalSeconds` per-mode) and `_finish` at zero; practice/endless let `elapsed` count up forever and never auto-finish. Don't reintroduce a `secondsLeft` countdown Rx — derive from `elapsed`. `GameView` swaps the AppBar timer, title, and progress bar based on the active mode.

**"신기록" comparison** (in `ResultController`) is per-mode within the same `(type, level)` bucket:
- Challenge: min `elapsedSeconds` among perfect (no-wrong) runs (`isNewPerfectBest`).
- Time attack: max `correctCount` (`isNewTimeAttackBest`).
- Endless: max `correctCount` (= longest streak; `isNewEndlessBest`).
Practice and all roll-up types (mixed/equation/flash/estimation) are excluded from perfect-best because their `(type, level)` buckets span multiple sub-ops/windows and aren't apples-to-apples.

Time attack and endless are **excluded** from perfect-style rewards (master badges, "사칙연산 정복", perfect-games daily mission) — those measure challenge runs only. Cumulative counts (correct totals, combos, streak) include all persisted runs.

### Learning game types (special modes)

All run through `/game` but flip an extra flag and roll up to a roll-up `GameType`:

- **Times-table / 구구단** (`tableNumber` non-null → `GameType.multiplication`, `level = 0`, `isPractice` forced true): `generateTimesTable(N)` returns the 9 problems `N×1..N×9` (shuffled, `N` always the left operand). Result renders "X단 연습" and never shows 신기록.
- **Mixed / 혼합** (`mixedTypes` non-null → `GameType.mixed`): `generateMixed(allowedTypes, level)`. With one op it falls through to single-op; with 2+ ops every problem is a single **compound expression** using each selected op exactly once (e.g. `5 + 3 × 2 - 1 = ?`), with standard precedence and guaranteed non-negative integer intermediates. Compound divisors are clamped to 2..9. Answer width can exceed the default 6 digits, so `maxAnswerLength` widens to 10 for mixed.
- **Equation / 방정식** (`isEquation`, generated for a concrete `equationType` → rolls up to `GameType.equation`): presented as "A op ? = C"; the player solves for `operandB`. Expected answer is `current.operandB`, not `current.answer`.
- **Flash / 플래시** (`isFlash`, concrete `flashType`, `flashDisplayMs` window → `GameType.flash`): the problem is visible for `flashDisplayMs` (picker offers 1.5s/2s/2.5s) then hidden via `_flashTimer` (`flashVisible` Rx); the player answers from memory. `_startFlashWindow` re-fires on each advance.
- **Estimation / 어림셈** (`isEstimation`, concrete `estimationType` ∈ {+,−,×}; ÷ excluded → `GameType.estimation`): operands are rounded to a level-appropriate unit (`_estimationUnit`: L1→5, L2–4→10, L5→100); the player taps one of **3 choices** via `submitChoice(int)` instead of the keypad. Choice sets are precomputed once in `onInit` (`estimationChoices`) so they don't reshuffle on rebuild. Distractors are drawn from correct ± unit / ± 2·unit (positive only).

## Architecture

GetX module pattern under `lib/app/`:

```
lib/app/
  routes/      app_routes.dart (route name constants), app_pages.dart (GetPage list)
  data/
    models/    game_type, session_mode, problem, problem_attempt, game_record,
               achievement_badge, custom_stamp, stamp_condition, daily_mission,
               wrong_notebook_entry, estimation_choices, action_concept
    services/  problem_generator (pure), record_service, sfx_service,
               profile_service, custom_stamp_service  (last four are GetxService)
  modules/<feature>/
    <feature>_view.dart        widgets (extends GetView<...>)
    <feature>_controller.dart  GetxController — state + business logic
    <feature>_binding.dart     Bindings — wires the controller to the route
  shared/      cross-cutting helpers + reusable widgets
```

### Routes (`app_routes.dart` / `app_pages.dart`)

Learning + meta: `/splash`, `/home`, `/tutorial`, `/level-select`, `/game`, `/result`, `/records`, `/record-detail`, `/badges`, `/stats`, `/wrong-notebook`, `/review-select`, `/review`.
Special-mode entry screens: `/times-table-select`, `/mixed-select`, `/equation-select`, `/flash-select`, `/estimation-select`.
Action games: `/action-select` (shared entry) → `/monster-game`, `/balloon-game`, `/tower-defense`, `/mole-game`, `/ladder-game`, `/fishing-game`.

### Data models

- `game_type.dart` — `GameType` enum (see above).
- `session_mode.dart` — `SessionMode` { challenge, timeAttack, endless } with `fromName`.
- `problem.dart` — `Problem` (single op) + `Problem.compound` (chained expression: `operands[]`, `operations[]`, precomputed `answer`; `isCompound`).
- `problem_attempt.dart` — one logged attempt: operands/type/correctAnswer/userAnswer/status (`AttemptStatus` correct/wrong/unsolved) + compound fields + `isEquation`/`isEstimation` flags for rendering.
- `game_record.dart` — persisted result: `finishedAt`, `type`, `level`, `correctCount`, `wrongCount`, `unsolvedCount`, `elapsedSeconds`, `attempts[]`, `maxCombo`, `mode`. Helpers `solvedCount`/`totalCount`/`isTimeAttack`. `fromJson` reads `maxCombo`/`mode` with null fallbacks for old records.
- `achievement_badge.dart` — `AchievementBadge` (built-in) + `BadgeStatus` (unlock + optional progress).
- `custom_stamp.dart` / `stamp_condition.dart` — user-created stamps with optional auto-earn `StampCondition` (operation/level/targetCount/requirePerfect/maxSeconds).
- `daily_mission.dart` — `DailyMission` + `DailyMissionStatus`; types: correctAnswers, perfectGames, achieveCombo, correctInType.
- `wrong_notebook_entry.dart` — aggregated wrong/unsolved entry (sample attempt + count + lastWrongAt + bucket).
- `estimation_choices.dart` — 3 `choices` + the `correct` value (a value, not an index).
- `action_concept.dart` — `ActionConcept` { monster, balloon, tower, mole, ladder, fishing } with `title` + `gameRoute`.

### Services (all registered in `main()` via `Get.putAsync`)

- `ProfileService` — display name (max 3 chars, key `profile_name_v1`, default `어린이`) + `tutorialSeen` flag (`tutorial_seen_v1`). Reactive `name`/`tutorialSeen`.
- `RecordService` — single source of truth for records (`shared_preferences`, JSON list under key **`game_records_v4`**). Delete matches by `finishedAt` equality (ms precision unique enough — bulk-import/seeding would break this; add an explicit `id` then). Bump the key suffix if you change the JSON shape. Also owns wrong-notebook **dismissals** (`wrong_notebook_dismissed_v1`, signature→timestamp) and `currentStreak()`.
- `SfxService` — single channel for SFX + haptics. Haptics always fire; sound respects the persisted mute toggle (`sfx_muted_v1`). Assets in `assets/audio/` (`correct.wav`, `wrong.wav`, `finish.wav`, `tick.wav` — CC0 Kenney Interface Sounds, see `assets/audio/LICENSE.txt`); `_play` swallows errors. Use `_sfx.click()/correct()/wrong()/finish()/tick()/combo()` — don't call `HapticFeedback` directly elsewhere. `combo()` is haptic-only (audio would double up with `correct()`).
- `CustomStampService` — CRUD for user-defined stamps (`custom_stamps_v1`); reactive `RxList<CustomStamp>` so the badges grid rebuilds on change.

### Conventions to keep

- Each feature owns view + controller + binding; the binding is referenced from `app_pages.dart` via `GetPage(binding: ...)`. New screens should follow the same triplet.
- **Lazy vs eager binding**: bindings default to `Get.lazyPut`, which only instantiates on first `Get.find<T>()` (`GetView<T>.controller` triggers this on first read in `build`). A side-effect-only screen that never reads `controller` in `build` (e.g. splash kicking off a Timer in `onReady`) must use `Get.put(...)` or `onInit`/`onReady` never fire. `SplashBinding` is the canonical example.
- Controllers receive screen arguments via `Get.arguments` in `onInit` (typed cast). Cross-screen data uses `Get.toNamed(route, arguments: ...)`, never globals.
- Don't introduce another state-management or navigation library (Navigator 2.0, go_router, Riverpod, Bloc, Provider) — GetX is the chosen stack.
- Date formatting uses `lib/app/shared/date_format.dart` to avoid pulling `intl`. Keep using that helper.
- `main.dart` locks portrait orientation and force-returns to `/splash` if the app was backgrounded for ≥ 5 minutes (`_resetAfter`) — every screen assumes a portrait layout.

### Shared helpers (`lib/app/shared/`)

Logic: `date_format.dart`, `korean_particle.dart`, `mixed_label.dart` (roll-up component labels), `badges.dart` (built-in badge defs + unlock logic), `daily_missions.dart` (day-seeded pool of 3), `streak.dart` (`computeStreak`), `weakness.dart` (`WeaknessBucket`/`WeaknessAnalysis`), `stamp_evaluation.dart` (auto-earn check), `wrong_notebook.dart` (aggregate/dedupe by signature, group-by-day).
Reusable widgets: `op_tile.dart`, `answer_pad.dart`, `attempt_tile.dart`, `action_intro_scaffold.dart` (shared layout for action-game intro screens).

## Stack & assets

- **Target platform**: Android only. Don't add iOS/web/desktop platform folders or platform-specific code paths. `flutter_launcher_icons` is configured with `ios: false` for the same reason.
- **Dart SDK**: `^3.11.4`. Code uses Dart 3 enhanced constructor inference (`colorScheme: .fromSeed(...)`, etc.) — don't "fix" those to fully-qualified forms.
- **Dependencies of note**: `get` (navigation + state), `shared_preferences` (records, mute toggle, profile, custom stamps, last-action-select choices), `audioplayers` (SFX), `lottie` (home/game animations, e.g. `assets/lottie/home_banner.json`), `flutter_launcher_icons` (dev). Typography is a bundled TTF — no `google_fonts`.
- **Typography**: app-wide font is **Jua** (주아), bundled as `assets/fonts/Jua-Regular.ttf` and declared in `pubspec.yaml`'s `fonts:` section. `lib/main.dart` sets `ThemeData(fontFamily: 'Jua', ...)` so every `TextStyle` inherits it. Don't hard-code `fontFamily` on individual `TextStyle`s — read from `Theme.of(context).textTheme.<style>.fontFamily` if you need to mix sizes (see `splash_view.dart`). No runtime network fetch; works offline from first launch (intentional for children's-app compliance — don't reintroduce `google_fonts`).
- **Theme**: cream scaffold (`#FFF8E7`) + light-sky AppBar (`#4FC3F7` bg, `#0D47A1` fg), Material 3. The bottom NavigationBar uses a warm beige palette (see `home_view.dart`).
- **Assets**: `assets/images/` and `assets/lottie/` are wired as directory entries in `pubspec.yaml` — drop files in and they're picked up (no per-file listing). App launcher source: `assets/icon/app_icon.png`.

## Commands

All commands run from the repo root and require the Flutter SDK on PATH.

- `flutter pub get` — fetch dependencies
- `flutter run` — launch on the connected device/emulator with hot reload
- `flutter analyze` — static analysis (extends `package:flutter_lints/flutter.yaml`)
- `flutter test` — run all widget/unit tests
- `flutter test test/widget_test.dart` — single file
- `flutter test --plain-name "splash screen is shown"` — single test by name
- `flutter build apk` / `flutter build appbundle` — Android release artifacts
- `dart run flutter_launcher_icons` — regenerate Android launcher icons from `assets/icon/app_icon.png`

The project currently only configures the Android platform folder (`android/`). iOS/web/desktop folders need `flutter create --platforms=...` before building for those targets.

## Tests

Tests must call `SharedPreferences.setMockInitialValues({})` and set `SfxService.audioBackendEnabled = false` in `setUp` (so the audioplayers MethodChannel, unregistered in widget-test isolates, isn't touched), then register the services the screen under test needs via `Get.putAsync` and `Get.deleteAll(force: true)` in `tearDown`. The canonical widget-test setup (`test/widget_test.dart`) registers `ProfileService`, `RecordService`, and `SfxService` before pumping `MyApp`. Screens that touch custom stamps additionally need `CustomStampService`. Service-only unit tests (`profile_service_test.dart`, `custom_stamp_test.dart`) construct+`init()` the service directly. Without the right registrations, any screen that calls `Get.find<T>()` on a missing service will throw.

## Documentation (`DOC/`)

Planning/reference docs live in `DOC/` (see `DOC/README.md` for the index): `ROADMAP.md` and `NEXT_STEPS.md` (what's done / queued — authoritative), `GAME_MODE_PLAN.md` / `HOME_REDESIGN_PLAN.md` / `LEARNING_FEATURES_ANALYSIS.md` / `BLUETOOTH_VERSUS.md` (design, mostly pre-implementation), and `RELEASE_CHECKLIST.md` / `PLAY_STORE_LAUNCH.md` / `TESTER_GUIDE.md` (launch/operations). Root also has `README.md` and `privacy-policy.md` (COPPA-style, zero-data-collection).
