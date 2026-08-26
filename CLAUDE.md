# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Product

**연산 히어로** — a children's math game (초등학생용, target 6–9세). The app display title is `연산 히어로`; the Flutter package is still `children_math_game`. Fully offline, Android-only, no accounts, no network, no ads (Play Store children's-app compliance).

High-level flow:

1. **Splash** (`/splash`) — 2s, then routes to **Home** normally. On a first launch it chains **Onboarding** (`/onboarding` — name + avatar for the primary profile) → **Tutorial** → Home; `ProfileService.onboardingSeen` / `tutorialSeen` gate each step independently.
2. **Tutorial** (`/tutorial`) — onboarding walkthrough. Auto-shown once on first run (marks `tutorialSeen` on entry so a force-quit still counts). Re-openable from the Home AppBar help button.
3. **Home** (`/home`) — a 4-tab container (`IndexedStack`), driven by `HomeController.tabIndex`:
   - **학습 (Learn)** — Lottie banner + streak badge, daily-mission card, weakness recommendation card, the four basic-operation tiles (덧셈/뺄셈/곱셈/나눗셈 → level select), and a "특별 모드" grid (2 rows × 3: 구구단 / 혼합 / 방정식 / 플래시 / 어림셈 / 부호 맞추기).
   - **게임 (Games)** — eight action mini-games (몬스터 처치 / 풍선 터뜨리기 / 타워 디펜스 / 두더지 잡기 / 숫자 사다리 / 물고기 잡기 / 저울 맞추기 / 아레나). Each tile opens the shared action-select screen; all eight are playable. The tab is driven by `_GameSpec.all` in `games_tab.dart`; the 2-column grid takes an even number of tiles and, when the count is odd, the last spec is rendered below it as a full-width horizontal card (`_WideGameModeTile`) instead of leaving a hole.
   - **기록 (Records)** — meta-tool hub: 도장판(badges) / 오답 노트(wrong notebook) / 결과 보기(records) / 학습 통계(stats) / 복습하기(review-select).
   - **함께 (Coop)** — 부모와 함께하는 학습 hub: 연결하기 (`/coop-lobby`) / 기록보기 (`/coop-records`). See "부모와 함께하는 학습" below.
   The shared AppBar (leading **profile-switcher** avatar button, editable name+avatar `"{name} 히어로!"`, tutorial button, **sound-settings** button) stays across all tabs. The sound button opens a bottom sheet with independent BGM/SFX toggles + volume sliders; the profile button opens a sheet to switch/add/delete profiles.
4. **Game** (`/game`) — the universal session screen for all learning modes. See "Session modes" and "Learning game types" below.
5. **Result** (`/result`) — correct/wrong/unsolved counts, elapsed time, max combo, and a "신기록" badge when applicable. Persists a `GameRecord` via `RecordService` (unless practice/구구단).
6. **Records** (`/records`) — past records newest-first; row → **Record detail** (`/record-detail`) showing every attempt. Delete opens an `AlertDialog`; only **확인** removes via `RecordService.delete`.

The eight **action mini-games** (`/monster-game`, `/balloon-game`, `/tower-defense`, `/mole-game`, `/ladder-game`, `/fishing-game`, `/balance-game`, `/arena-game`) are a separate arcade track — they do **not** go through `/game`, `/result`, or `RecordService`/`GameRecord`. They **do** persist a per-concept **best score + play count** via `ActionScoreService` (see Services), surfaced on the shared action-select screen (top "🏆 최고 기록" card) and in each game-over overlay (shared `ActionRecordLine` shows a 신기록 badge or the running best). Each controller exposes a concept constant + `isNewBest` Rx and calls `_scores.report(concept, score)` in `_gameOver`.

**저울 맞추기 (balance)** is the odd one out among the eight: every other action game is `식 하나 → 답 하나` (typed on the keypad or tapped among candidates), while this one asks only for the **relation** between two expressions — `>` / `=` / `<` — so it can be answered by estimation without computing either side exactly. Rounds come from `ProblemGenerator.balancePair(type, digitsA, digitsB, solved)`: the left expression is generated normally, then the right one is **back-synthesized** via `synthesizeForAnswer` to land on `left.answer ± gap`, so the gap (and therefore the difficulty) is controlled. The gap band narrows with `solved` (`<4` → 5–12, `<10` → 2–6, else 1–3), and `balanceEqualChance` (0.22) deliberately forces `=` rounds that random generation would almost never produce. When no gap in the band is reachable for a given (op, digits) combo — e.g. 1-digit division only yields answers 2–4 — it widens, then falls back to generating the right side independently. Right/wrong both reveal by tilting the beam toward the true answer; a wrong pick does **not** replay the same round, because with three choices a retry is just a guess.

**아레나 (arena)** is the other structural outlier: the other seven are flat 60-second runs, while this one is **wave-based survival** (서바이버라이크) with state that carries across waves. A wave = clear N enemies before the wave timer runs out; every `bossEvery` (3) waves is a **boss** — one enemy with multi-hit HP and `bossExtraSeconds` more time. The score to beat is how deep you got, not whether you "finished".

**Four axes scale with the wave** — the first two run out early, so the last two exist to keep the curve from flattening:

| Axis | Rule | Caps at |
|---|---|---|
| 적 수 | +1 every 2 waves | 8 (wave 11) |
| 제한시간 | −1s per wave to `softFloorSeconds` (12s), then −1s every `floorStepEvery` (3) waves | `hardFloorSeconds` 10s (wave 17) |
| **자릿수** | start rung from action-select, +1 rung every `digitStepEvery` (3) waves | top of `digitLadder` (3×3, wave 13 from a 1×1 start) |
| **보기 수** | `baseChoiceCount` 3 → `lateChoiceCount` 4 at `lateGameWave` (11) | 4 |

The digit ramp is the important one: without it the arithmetic never got harder (a 1-digit-addition run stayed 1-digit forever) and only the clock moved. The action-select digit choice is now the **starting rung**, not the fixed difficulty. `digitsForWave` reads `lib/app/shared/digit_ladder.dart`, which is also what `ActionSelectController.digitChoices` points at — don't reintroduce a second copy of the ladder. When a wave raises the rung, `raisedDigits` flips and the banner says "숫자가 커져요!" so a sudden jump in operand size is never unexplained.

- **Wave clear → one of three 강화 cards** (`ArenaUpgrade`, `lib/app/data/models/arena_upgrade.dart`): 점수 2배 / 하트 회복 / 시간 +5초 / 방어막 / 보기 줄이기 (removes one choice from whatever the wave offers — 3→2 early, 4→3 late; that's why its text says "하나 줄어요" rather than naming a number). Three are drawn at random from the five each time so runs diverge; `heal` is filtered out at full HP and `shield` while one is held, so a card is never a dud. Everything except `heal` (instant) and `shield` (held until it eats a wrong answer) lasts **one wave only** — permanent buffs flatten the late-game curve.
- **Scoring**: `baseScore` × combo multiplier (×2 at 5 combo, ×3 at 10) × 2 if 점수 2배 is active, plus `critBonus` when answered within `critMs`. Boss kills add `bossBonus`. `ActionScoreService` stores the accumulated score.
- **Failure**: a wrong answer costs a heart (shield absorbs the first) but leaves the enemy standing; a wave timeout costs a heart and **restarts the same wave** rather than demoting — losing wave progress reads as too harsh at this age. HP 0 is the only end condition, so there's no global timer.
- The wave clock **pauses during answer reveals and the upgrade overlay** (`_locked` / `isChoosingUpgrade` guards in the tick). Without that, time can expire while the correct answer is being shown, which is a penalty the player can't act on.
- **The arena is frame-driven.** `ArenaGameView` is a `StatefulWidget` holding a `Ticker` that feeds an `elapsedMs` down the tree — the same shape as `balloon_game_view.dart` / `fishing_game_view.dart` (ticker stops on game over, epoch resets on restart). Everything continuous derives from that one number: the scrolling starfield (`_StarfieldPainter`, positions seeded from the index so they don't jitter per frame), per-enemy bobbing at different phases, the boss's breathing/sway (faster and wider as its HP drops), the hero's idle float, and the urgent border/timer pulse under 5 seconds.
- **Enemies advance with the clock**: `approach = 1 - waveRemaining / waveTotalSeconds` slides the enemy formation from the top of the stage down toward the hero, so time pressure is visible without reading the number. `waveTotalSeconds` exists on the controller purely to make that ratio available.
- Discrete effects are driven by **controller tick counters, never by animation state in the controller**: `gainTick` fires the hero's attack punch, the ⚡ projectile → 💥 impact, and the floating `+N` / 퍼펙트! popup; `hitTick` fires the damped-sine screen shake (`_Shake`). `_ArenaStageState` watches those with `ever` workers and records the frame time the effect started; the controller stays free of `Duration`s and curves.
- Widget tests drive this fine — `tester.pump(duration)` advances the ticker. Don't add `pumpAndSettle` to arena tests: the background animation never settles.

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

If you change these rules, update **both** the `_digitsForLevel` table here and `_levelLabel` in `level_select_view.dart`. Level 1 division is intentionally a small set (e.g. `4÷2`, `6÷2`, `8÷2`, `6÷3`, `9÷3`, `8÷4`). The action-select screen (`action_select_controller.dart`) deliberately mirrors this same digit ladder as its `digitChoices` — the shared definition lives in `lib/app/shared/digit_ladder.dart` (also used by the 아레나 wave ramp) — and generates via `ProblemGenerator.generateOneForDigits(...)` which bypasses the level→digits table.

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

**부호 맞추기 (sign-guess)** is a **standalone special mode** (not a `/game` roll-up): `/sign-guess-select` (level picker) → `/sign-guess` (`SignGuessController`/`View`). The operators in an expression are hidden and the child fills each blank left-to-right from an operator palette. Levels drive **operator count** ({1:1, 2:2, 3:3, 4:3, 5:5}) and **pool** (L1–3 = {+,−}; L4–5 = {+,−,×,÷}) via `ProblemGenerator.generateSignGuess/signGuessOpCount/signGuessPool` (compound `Problem`s built by reusing `_tryBuildCompound` with 1-digit operands). Answer check accepts **any** operator combo that evaluates (standard precedence, via `ProblemGenerator.evaluateChain`) to the shown result — non-clean ÷ yields a non-integer and is naturally rejected. Practice-style: **not persisted** (no `GameRecord`), self-contained result overlay like the action games.

### 부모와 함께하는 학습 (coop, Nearby Connections)

A third track next to learning and action games: two devices in the same room pair over **Nearby Connections** (Bluetooth + local Wi-Fi, no internet, no accounts) so a parent can watch and coach while the child solves. Flow: 함께 탭 → `/coop-lobby` (host "방 만들기" / guest "참여하기", then each picks a **role**) → `/coop-learn` (child) or `/coop-coach` (parent) → summary saved to `/coop-records` → `/coop-record-detail`.

Layering — each level is only allowed to know about the one below it:

- `MultiplayerTransport` (`data/services/multiplayer/multiplayer_transport.dart`) — plugin-agnostic interface + sealed `TransportEvent`s. `NearbyTransport` is the real `nearby_connections` implementation; `test/support/fake_transport.dart` is the in-memory one used by tests.
- `MultiplayerService` — connection state machine (`MultiplayerState`: idle → advertising/discovering → connecting → connected → inSession) over raw UTF-8 strings. Connections are **auto-accepted** on both sides (no kid-facing approval dialog). Incoming payloads that arrive before anyone subscribes are **buffered and replayed** to the first listener — the two devices pick roles at different moments, and dropping an early `hello` was the infinite-loading bug fixed in 1d5465f. Don't turn `incoming` back into a plain broadcast stream.
- `CoopSession` — the protocol layer: `hello` handshake → host pushes `session_config` → `session_start`, then `problem_state` / `attempt_result` / `coach_emoji` / pause / resume / `bye`. `CoopPhase`: handshaking → ready → running → paused → ended. A transport-level disconnect is surfaced as a synthetic `ByeMessage(reason: 'connection_lost')` so screens handle graceful and ungraceful exits identically.
- **Host vs guest** (who opened the room) is orthogonal to **role** (parent vs child, `CoopRole`) — don't conflate them.

`MultiplayerService` is **not** registered in `main()`; `CoopLobbyBinding` `Get.put`s it (with the real `NearbyTransport`) so the radios only spin up when the user enters the coop flow, and it stays alive while the lobby is in the stack. Coop sessions persist through `CoopRecordService`, never `RecordService` — they must not move learning stats, badges, or streaks.

Runtime permissions are branched by API level in `CoopPermissions` (13+ → BLUETOOTH_SCAN/ADVERTISE/CONNECT + NEARBY_WIFI_DEVICES; 12 → the three BLUETOOTH_*; ≤11 → fine location). Keep the manifest declarations and that branch in sync, and keep `neverForLocation` on the scan/Wi-Fi permissions — the Play listing claims no location use. Details: `DOC/PARENT_COOP_LEARNING.md`.

## Architecture

GetX module pattern under `lib/app/`:

```
lib/app/
  routes/      app_routes.dart (route name constants), app_pages.dart (GetPage list)
  data/
    models/    game_type, session_mode, problem, problem_attempt, game_record,
               achievement_badge, custom_stamp, stamp_condition, daily_mission,
               wrong_notebook_entry, estimation_choices, action_concept, profile,
               balance_pair, coop_message, coop_role, coop_session_record
    services/  problem_generator (pure), coop_permissions (static, platform-only),
               record_service, sfx_service, profile_service, custom_stamp_service,
               action_score_service, coop_record_service, theme_service
               (those seven are GetxService, all registered in main())
               multiplayer/  multiplayer_transport (interface) + nearby_transport,
                             multiplayer_service (GetxService, put by CoopLobbyBinding),
                             coop_session (protocol layer, plain class)
  modules/<feature>/
    <feature>_view.dart        widgets (extends GetView<...>)
    <feature>_controller.dart  GetxController — state + business logic
    <feature>_binding.dart     Bindings — wires the controller to the route
  shared/      cross-cutting helpers + reusable widgets
```

### Routes (`app_routes.dart` / `app_pages.dart`)

Learning + meta: `/splash`, `/onboarding`, `/home`, `/tutorial`, `/level-select`, `/game`, `/result`, `/records`, `/record-detail`, `/badges`, `/stats`, `/wrong-notebook`, `/review-select`, `/review`.
Special-mode entry screens: `/times-table-select`, `/mixed-select`, `/equation-select`, `/flash-select`, `/estimation-select`, `/sign-guess-select` → `/sign-guess`.
Action games: `/action-select` (shared entry) → `/monster-game`, `/balloon-game`, `/tower-defense`, `/mole-game`, `/ladder-game`, `/fishing-game`, `/balance-game`, `/arena-game`.
Coop (부모와 함께하는 학습): `/coop-lobby` → `/coop-learn` (child) or `/coop-coach` (parent), plus `/coop-records` → `/coop-record-detail`.

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
- `action_concept.dart` — `ActionConcept` { monster, balloon, tower, mole, ladder, fishing, balance, arena } with `title` + `gameRoute`.
- `arena_upgrade.dart` — `ArenaUpgrade` (아레나 wave-clear reward cards) with emoji/title/description. Effect durations differ per card — see the 아레나 notes above before adding one.
- `balance_pair.dart` — `BalancePair` for 저울 맞추기: two `Problem`s (좌/우 접시) whose `relation` (`1`/`0`/`-1`) and `gap` are **derived** from the answers, never stored — the relation is the answer, so a stored copy could contradict the expressions.
- `profile.dart` — `Profile` { `id`, `name`, `avatar` } for multi-profile support. `id == Profile.primaryId` (1) is the migrated/default profile; `scopeSuffix` returns `''` for the primary (legacy keys) and `_p<id>` for siblings. `avatarChoices` is the emoji picker pool.

### Services (all registered in `main()` via `Get.putAsync`)

- `ProfileService` — **multi-profile** store: `profiles` (RxList<Profile>) + `activeId`, keys `profiles_v1`/`active_profile_v1`. Legacy single-name key `profile_name_v1` migrates into the primary profile on first run. Reactive `name`/`avatar` **mirror the active profile** (so existing `Obx(() => ...name.value)` call sites are unchanged). Names max 3 chars; `scopeSuffix` (from the active profile) is what the scoped services key off. `switchTo`/`addProfile`/`deleteProfile` (primary is protected, last profile can't be deleted). Also owns `tutorialSeen` (`tutorial_seen_v1`, app-level, **not** per-profile).
- `RecordService` — single source of truth for records (`shared_preferences`, JSON list under key **`game_records_v4`**). Keys are **profile-scoped**: the base key gets the active profile's `scopeSuffix` appended (primary → `game_records_v4`, sibling → `game_records_v4_p<id>`). Delete matches by `finishedAt` equality (ms precision unique enough — bulk-import/seeding would break this; add an explicit `id` then). Bump the key base if you change the JSON shape. Also owns wrong-notebook **dismissals** (`wrong_notebook_dismissed_v1` + scope) and `currentStreak()`. Falls back to the empty (primary) scope when `ProfileService` isn't registered (service-only unit tests).
- `SfxService` — audio (BGM + SFX) + haptics. **Two independent channels**, each with an on/off flag + 0..1 volume: `bgmEnabled`/`bgmVolume` (`bgm_enabled_v1`/`bgm_volume_v1`) and `sfxEnabled`/`sfxVolume` (`sfx_enabled_v1`/`sfx_volume_v1`). The legacy single mute key `sfx_muted_v1` migrates into `sfxEnabled` (muted → disabled). Haptics always fire regardless. SFX assets in `assets/audio/` (`correct.wav`, `wrong.wav`, `finish.wav`, `tick.wav` — CC0 Kenney Interface Sounds); the looping BGM is `assets/audio/bgm.wav` (generated offline by `marketing/make_bgm.py`), played on a separate `ReleaseMode.loop` player. `startBgm()` is idempotent and fired from `HomeController.onReady`. `_play` swallows errors. Use `_sfx.click()/correct()/wrong()/finish()/tick()/combo()` — don't call `HapticFeedback` directly elsewhere. `combo()` is haptic-only (audio would double up with `correct()`).
- `CustomStampService` — CRUD for user-defined stamps (`custom_stamps_v1` + profile scope); reactive `RxList<CustomStamp>` so the badges grid rebuilds on change. `reload()` re-reads after a profile switch.
- `ActionScoreService` — best score + play count per `ActionConcept` for the eight action mini-games (`action_scores_v1` + profile scope, JSON `{concept.name: {best, plays}}`). Reactive `best`/`plays` RxMaps. `report(concept, score)` bumps plays, updates best, returns whether it was a new record (a 0 score never counts). `reload()` after a profile switch.
- `CoopRecordService` — 부모와 함께하는 학습 session summaries (`coop_records_v1` + profile scope, newest-first `RxList<CoopSessionRecord>`). Deliberately separate from `RecordService` so coop sessions never touch learning stats/badges. Same `finishedAt`-equality delete + `reload()` contract as the other stores.
- `ThemeService` — persisted `ThemeMode` (`theme_mode_v1`, system/light/dark) as an `Rx<ThemeMode>`; `main.dart` wraps `GetMaterialApp` in an `Obx` reading `mode`, so `setMode` repaints instantly. App-level, **not** profile-scoped. Any new screen must look acceptable in both `theme` and `darkTheme` — don't hard-code light-only colors; read from `Theme.of(context).colorScheme`.

`MultiplayerService` (`data/services/multiplayer/`) is also a `GetxService` but is registered by `CoopLobbyBinding` instead of `main()` — see "부모와 함께하는 학습" above.

### Conventions to keep

- Each feature owns view + controller + binding; the binding is referenced from `app_pages.dart` via `GetPage(binding: ...)`. New screens should follow the same triplet.
- **Lazy vs eager binding**: bindings default to `Get.lazyPut`, which only instantiates on first `Get.find<T>()` (`GetView<T>.controller` triggers this on first read in `build`). A side-effect-only screen that never reads `controller` in `build` (e.g. splash kicking off a Timer in `onReady`) must use `Get.put(...)` or `onInit`/`onReady` never fire. `SplashBinding` is the canonical example.
- Controllers receive screen arguments via `Get.arguments` in `onInit` (typed cast). Cross-screen data uses `Get.toNamed(route, arguments: ...)`, never globals.
- Don't introduce another state-management or navigation library (Navigator 2.0, go_router, Riverpod, Bloc, Provider) — GetX is the chosen stack.
- Date formatting uses `lib/app/shared/date_format.dart` to avoid pulling `intl`. Keep using that helper.
- `main.dart` locks portrait orientation and force-returns to `/splash` if the app was backgrounded for ≥ 5 minutes (`_resetAfter`) — every screen assumes a portrait layout.

### Shared helpers (`lib/app/shared/`)

Logic: `date_format.dart`, `korean_particle.dart`, `digit_ladder.dart` (the shared (A,B) digit rungs — action-select choices + 아레나 wave ramp), `mixed_label.dart` (roll-up component labels), `badges.dart` (built-in badge defs + unlock logic), `daily_missions.dart` (day-seeded pool of 3), `streak.dart` (`computeStreak`), `weakness.dart` (`WeaknessBucket`/`WeaknessAnalysis`), `stamp_evaluation.dart` (auto-earn check), `wrong_notebook.dart` (aggregate/dedupe by signature, group-by-day), `weekly_report.dart` (`computeWeeklyReport` → last-7-days buckets for the parent report card).
Reusable widgets: `op_tile.dart`, `answer_pad.dart`, `attempt_tile.dart`, `action_intro_scaffold.dart` (shared layout for action-game intro screens), `action_record_line.dart` (shared 신기록/best line for action game-over overlays).

## Stack & assets

- **Target platform**: Android only. Don't add iOS/web/desktop platform folders or platform-specific code paths. `flutter_launcher_icons` is configured with `ios: false` for the same reason.
- **Dart SDK**: `^3.11.4`. Code uses Dart 3 enhanced constructor inference (`colorScheme: .fromSeed(...)`, etc.) — don't "fix" those to fully-qualified forms.
- **Dependencies of note**: `get` (navigation + state), `shared_preferences` (records, audio + theme settings, profiles, custom stamps, action scores, coop records, last-action-select choices), `audioplayers` (SFX + looping BGM), `share_plus` (weekly parent-report share), `path_provider`, `lottie` (home/game animations, e.g. `assets/lottie/home_banner.json`), `nearby_connections` + `permission_handler` + `device_info_plus` (coop mode only — P2P transport and API-level-branched runtime permissions), `flutter_launcher_icons` (dev). Typography is a bundled TTF — no `google_fonts`. Nothing here talks to the network: the P2P plugin is local-radio only, which is what keeps the zero-data-collection claim true.
- **Typography**: app-wide font is **Jua** (주아), bundled as `assets/fonts/Jua-Regular.ttf` and declared in `pubspec.yaml`'s `fonts:` section. `lib/main.dart` sets `ThemeData(fontFamily: 'Jua', ...)` so every `TextStyle` inherits it. Don't hard-code `fontFamily` on individual `TextStyle`s — read from `Theme.of(context).textTheme.<style>.fontFamily` if you need to mix sizes (see `splash_view.dart`). No runtime network fetch; works offline from first launch (intentional for children's-app compliance — don't reintroduce `google_fonts`).
- **Theme**: cream scaffold (`#FFF8E7`) + light-sky AppBar (`#4FC3F7` bg, `#0D47A1` fg), Material 3. The bottom NavigationBar uses a warm beige palette (see `home_view.dart`). A **dark theme** (`#121417` scaffold, `#0D47A1` AppBar) is defined alongside it in `main.dart`; the active mode comes from `ThemeService` and defaults to `ThemeMode.system`.
- **Assets**: `assets/images/` and `assets/lottie/` are wired as directory entries in `pubspec.yaml` — drop files in and they're picked up (no per-file listing). App launcher source: `assets/icon/app_icon.png`. `assets/images/` is currently empty and holds a `.gitkeep`: git can't track an empty directory, and a pubspec directory entry whose folder is missing makes the **build fail** (`unable to find directory entry in pubspec.yaml`) — that's what a fresh clone hits. Keep the placeholder until real images land, and do the same for any future empty asset directory.

## Local setup (fresh clone)

The repo is self-contained for **development**: `git clone` → `flutter pub get` → `flutter test` / `flutter run` works with no extra files. Only **release signing** and the private launch doc are missing by design. Full step-by-step (Korean, with troubleshooting) lives in `README.md` → "개발 환경 설정"; the essentials an agent needs:

**Toolchain** — Flutter **3.41.6 stable** (Dart 3.11.4; pinned by `.metadata` revision `db50e201`), **JDK 17+** (`build.gradle.kts` compiles to Java 17), Android SDK + platform-tools. Gradle **8.14** and AGP **8.11.1** / Kotlin **2.2.20** come from `android/gradle/wrapper/gradle-wrapper.properties` and `android/settings.gradle.kts` — don't bump them casually. `minSdk`/`targetSdk`/`compileSdk` are inherited from the Flutter tool (`flutter.minSdkVersion`, …), so there's no hard-coded number to keep in sync.

**Files that are gitignored and therefore absent after a clone:**

| Path | What it is | Consequence |
|---|---|---|
| `android/local.properties` | `sdk.dir` / `flutter.sdk` + version echo | Regenerated by the Flutter tool on the first Android build; needs `ANDROID_HOME`/`ANDROID_SDK_ROOT` set (or Android Studio's SDK) to resolve `sdk.dir`. The `gradle.user.home` line on the original machine is machine-specific — don't copy it. |
| `android/gradlew`, `gradlew.bat`, `gradle/wrapper/gradle-wrapper.jar` | Gradle wrapper binaries | Injected automatically from the Flutter SDK on the first Android build. Don't commit them. |
| `android/key.properties` + `upload-keystore.jks` | Release signing | **Debug builds and all tests work without them.** `flutter build apk/appbundle` (release) fails at the `signingConfig` step. Any store update requires the *original* upload keystore — a regenerated one is a different app identity. |
| `DOC/PLAY_STORE_LAUNCH.md` | Play Console procedure, tester list | Referenced from `DOC/README.md` but never committed (may contain personal data). Its absence is expected, not a broken link. |

`android/key.properties` format (values from the keystore holder, never in git):

```properties
storePassword=…
keyPassword=…
keyAlias=upload
storeFile=../upload-keystore.jks   # resolved via rootProject.file(), i.e. relative to android/
```

**Verify a clone**: `flutter pub get` → `flutter analyze` (clean) → `flutter test` (187 passing). Everything up to here is host-only. Anything beyond needs hardware: the game is portrait-locked Android (`flutter run` on a device/emulator), and **coop mode needs two physical devices** — Nearby Connections has no emulator support and the flow can't be exercised on one machine. Use the fake transport for logic work instead.

**Optional Python tooling** (`tools/`, `marketing/`) is not part of the build: `make_icon.py`, `gen_feature_graphic.py`, `make_banner.py` need **Pillow**; `marketing/make_bgm.py` is stdlib-only (it generated `assets/audio/bgm.wav`). `gen_feature_graphic.py` hard-codes `C:/Windows/Fonts/arialbd.ttf` and is Windows-only as written. Their outputs (`assets/icon/`, `assets/store/`, `assets/audio/bgm.wav`) are committed, so you never need to run them just to build.

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

Tests must call `SharedPreferences.setMockInitialValues({})` and set `SfxService.audioBackendEnabled = false` in `setUp` (so the audioplayers MethodChannel, unregistered in widget-test isolates, isn't touched), then register the services the screen under test needs via `Get.putAsync` and `Get.deleteAll(force: true)` in `tearDown`. The canonical widget-test setup (`test/widget_test.dart`) registers `ProfileService`, `RecordService`, `SfxService`, and `ThemeService` before pumping `MyApp` (`MyApp.build` calls `Get.find<ThemeService>()`, so it throws without it). Screens that touch custom stamps additionally need `CustomStampService`; action-game / action-select screens need `ActionScoreService`. Service-only unit tests (`profile_service_test.dart`, `custom_stamp_test.dart`, `action_score_service_test.dart`, `sfx_service_test.dart`, `theme_service_test.dart`, `coop_record_service_test.dart`) construct+`init()` the service directly — `RecordService`/`CustomStampService`/`ActionScoreService`/`CoopRecordService` fall back to the primary (empty) scope when `ProfileService` isn't registered, so they work standalone. Without the right registrations, any screen that calls `Get.find<T>()` on a missing service will throw.

**Coop tests never touch radios**: `multiplayer_service_test.dart` / `coop_protocol_test.dart` drive `MultiplayerService`/`CoopSession` through `test/support/fake_transport.dart` (an in-memory `MultiplayerTransport` pair). Any new connection/protocol logic belongs behind that interface so it stays testable without two physical devices — the plugin itself has no test double.

The whole suite is host-only (no emulator, no device) and currently green: `flutter test` → **187 passing** as of 3.3.0+22. A fresh clone that can't reach 187 has an environment problem, not a code problem.

## Documentation (`DOC/`)

Planning/reference docs live in `DOC/` (see `DOC/README.md` for the index): `ROADMAP.md` and `NEXT_STEPS.md` (what's done / queued — authoritative), `GAME_MODE_PLAN.md` / `HOME_REDESIGN_PLAN.md` / `LEARNING_FEATURES_ANALYSIS.md` / `BLUETOOTH_VERSUS.md` (design, mostly pre-implementation), `PARENT_COOP_LEARNING.md` (the coop mode's design + the permission rationale behind the manifest), and `RELEASE_CHECKLIST.md` / `TESTER_GUIDE.md` (launch/operations). `PLAY_STORE_LAUNCH.md` is indexed but **gitignored** — it won't exist in a clone. Root also has `README.md` and `privacy-policy.md` (COPPA-style, zero-data-collection).
