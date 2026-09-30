# 연산 히어로 (children_math_game)

초등학생용(6~9세) 수학 연산 게임 (Flutter, Android 전용). 완전 오프라인 · 계정/네트워크/광고 없음.

사칙연산(덧셈/뺄셈/곱셈/나눗셈)을 5단계 난이도로 풀고, 구구단·혼합·방정식·플래시·어림셈·부호 맞추기 등 특별 모드와 9종의 액션 미니게임(웨이브 생존형 **아레나**, 보드 완성형 **수학 빙고** 포함)을 제공합니다. 매 게임마다 점수·소요시간·콤보가 기록되고, 도장판/뱃지·오답노트·통계·복습으로 이어집니다. 두 기기를 근거리에서 연결해 부모가 옆에서 돕는 **함께 학습(Nearby Connections)** 모드도 있습니다.

> 패키지 이름은 `children_math_game`이지만 앱 표시 이름은 **연산 히어로**입니다. 현재 버전 `3.4.1+24` (`pubspec.yaml`의 `version:`이 단일 출처).

---

## 개발 환경 설정 (클론 후 첫 셋업)

이 저장소는 **개발·테스트에 필요한 모든 것이 커밋되어 있습니다.** 클론 → `flutter pub get` → `flutter test`/`flutter run`이 추가 파일 없이 바로 됩니다. 빠져 있는 것은 **릴리즈 서명 키**와 개인정보가 담긴 출시 문서뿐입니다.

### 1. 필요한 도구

| 도구 | 버전 | 확인 |
|---|---|---|
| Flutter SDK | **3.41.6 stable** (Dart 3.11.4) — `.metadata`의 revision `db50e201` 기준 | `flutter --version` |
| JDK | **17 이상** (Gradle이 Java 17 타깃으로 컴파일) | `java -version` |
| Android SDK | Android Studio 또는 cmdline-tools + platform-tools, 라이선스 동의 | `flutter doctor` |
| Gradle / AGP / Kotlin | **8.14 / 8.11.1 / 2.2.20** — 각각 `android/gradle/wrapper/gradle-wrapper.properties`, `android/settings.gradle.kts`에 고정 (별도 설치 불필요, 래퍼가 받아옴) | — |

`compileSdk`/`minSdk`/`targetSdk`는 Flutter 툴 기본값(`flutter.compileSdkVersion` 등)을 그대로 씁니다 — `build.gradle.kts`에 숫자가 박혀 있지 않으므로 Flutter 버전을 올리면 함께 올라갑니다.

### 2. 클론 후 실행

```bash
git clone <repo-url> children_math_game
cd children_math_game
flutter pub get
flutter analyze          # 경고 0이 정상
flutter test             # 187개 통과가 정상 (3.3.0+22 기준)
flutter run              # 실기기/에뮬레이터 연결 후 (세로 고정 앱)
```

`flutter doctor`가 Android toolchain에서 걸리면 **거기부터** 해결하세요. 이 프로젝트 고유의 설정은 없습니다.

### 3. 저장소에 **없는** 파일 (gitignore)

| 경로 | 정체 | 없으면 생기는 일 |
|---|---|---|
| `android/local.properties` | `sdk.dir`, `flutter.sdk` 경로 | 첫 Android 빌드 때 Flutter 툴이 **자동 생성**. `ANDROID_HOME`/`ANDROID_SDK_ROOT`가 잡혀 있어야 `sdk.dir`이 채워집니다. 원본 머신의 `gradle.user.home` 줄은 그 PC 전용이니 복사하지 마세요 |
| `android/gradlew`, `gradlew.bat`, `gradle/wrapper/gradle-wrapper.jar` | Gradle 래퍼 실행 파일 | 첫 Android 빌드 때 Flutter SDK에서 **자동 주입**. 커밋하지 마세요 |
| `android/key.properties`, `upload-keystore.jks` | 릴리즈 서명 정보 | **디버그 실행·테스트는 영향 없음.** `flutter build apk`/`appbundle`(릴리즈)만 서명 단계에서 실패 |
| `DOC/PLAY_STORE_LAUNCH.md` | Play Console 절차·테스터 명단(개인정보 포함) | `DOC/README.md` 색인에는 있지만 클론에는 없습니다. 정상입니다 |

### 4. 릴리즈 빌드를 해야 한다면

`android/app/build.gradle.kts`는 `android/key.properties`를 읽어 릴리즈 서명을 구성합니다. 파일이 없으면 빌드가 서명 단계에서 실패하므로, 키를 가진 사람에게 받아 아래 형식으로 만듭니다(**절대 커밋 금지** — `.gitignore`에 이미 등록):

```properties
storePassword=…
keyPassword=…
keyAlias=upload
storeFile=../upload-keystore.jks
```

`storeFile`은 `rootProject.file()` 기준, 즉 `android/`에서의 상대 경로입니다(저장소 루트의 `upload-keystore.jks`를 가리킴).

> ⚠️ **이미 Play Store에 올라간 앱을 업데이트하려면 원본 업로드 키스토어가 반드시 필요합니다.** 새로 만든 키스토어는 다른 앱으로 취급되어 업데이트가 거부됩니다(Play 앱 서명 키 재설정 절차를 밟기 전까지). 새 키가 필요한 별도 프로젝트라면:
> ```bash
> keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA \
>         -keysize 2048 -validity 10000 -alias upload
> ```

### 5. 하드웨어가 필요한 작업

- **일반 화면**: 에뮬레이터로 충분합니다(세로 고정).
- **함께 학습(Nearby Connections)**: **실기기 2대 필수.** 에뮬레이터는 Nearby를 지원하지 않고, 한 대로는 호스트/게스트 흐름을 재현할 수 없습니다. 두 기기 모두 블루투스 + 위치/근거리 기기 권한을 허용해야 하고, `MultiplayerService.serviceId`가 같아야 서로를 찾습니다.
- 연결 상태 머신·프로토콜 **로직**은 기기 없이 검증할 수 있습니다 — `test/support/fake_transport.dart`(인메모리 `MultiplayerTransport`)를 쓰는 `multiplayer_service_test.dart` / `coop_protocol_test.dart` 참고.

### 6. 부수 도구 (선택)

`tools/`·`marketing/`의 파이썬 스크립트는 빌드와 무관한 에셋 생성기입니다. 결과물(`assets/icon/`, `assets/store/`, `assets/audio/bgm.wav`)이 이미 커밋되어 있으므로 **빌드하려고 실행할 필요는 없습니다.**

- `tools/make_icon.py`, `tools/gen_feature_graphic.py`, `marketing/make_banner.py` — **Pillow** 필요 (`pip install pillow`)
- `marketing/make_bgm.py` — 표준 라이브러리만 사용 (BGM 재생성)
- `gen_feature_graphic.py`는 `C:/Windows/Fonts/arialbd.ttf`를 하드코딩해 두어 현재는 Windows 전용입니다

### 7. 자주 겪는 문제

| 증상 | 원인 / 해결 |
|---|---|
| `unable to find directory entry in pubspec.yaml: …/assets/images/` | `assets/images/`가 비어 있으면 git이 디렉터리를 추적하지 못해 클론에서 사라집니다. `assets/images/.gitkeep`이 그래서 있는 것이니 지우지 마세요(이미지를 실제로 넣으면 지워도 됨) |
| `flutter.sdk not set in local.properties` | `android/local.properties`가 없거나 `flutter.sdk`가 비어 있음 → 저장소 루트에서 `flutter build apk --debug`를 한 번 돌리면 Flutter 툴이 채워줍니다 |
| `SDK location not found` | `ANDROID_HOME`/`ANDROID_SDK_ROOT` 미설정 → 환경변수 설정 후 재시도 |
| 릴리즈 빌드만 서명 오류 | §4의 `key.properties`/키스토어 누락 |
| 테스트에서 `"XService" not found` | `setUp`에 해당 서비스 등록 누락 → 아래 "테스트 작성 시 주의" 참고 |
| 테스트에서 MissingPluginException (audioplayers) | `SfxService.audioBackendEnabled = false` 누락 |
| 함께 학습에서 상대가 안 보임 | 두 기기 권한 허용 여부, 블루투스/Wi-Fi ON, 거리, 그리고 **에뮬레이터가 아닌지** 확인 |

---

## 화면 흐름

```
Splash (2초) ──▶ 첫 실행이면 Onboarding(이름·아바타) ─▶ Tutorial ─▶ Home
                                            │        (4탭: 학습 / 게임 / 기록 / 함께)
   학습 탭 ── 기본연산 4 ─▶ Level Select ─▶ Game ─▶ Result ─▶ Records ─▶ Record Detail
          └─ 특별 모드 6 ─▶ (각 select) ──┘      (부호 맞추기는 /game을 거치지 않음)
   게임 탭 ── 액션 9종 ────▶ Action Select ─▶ 각 액션 게임 (최고 점수 저장)
   기록 탭 ── 도장판 / 오답노트 / 결과보기 / 통계 / 복습
   함께 탭 ── 연결하기 ─▶ Coop Lobby ─▶ 아이=Coop Learn / 부모=Coop Coach
          └─ 기록보기 ─▶ Coop Records ─▶ Coop Record Detail
```

| 라우트 | 역할 |
|---|---|
| `/splash` | 2초 후 홈으로 (첫 실행이면 온보딩 → 튜토리얼) |
| `/onboarding` | 첫 실행 시 이름 + 아바타 입력 (기본 프로필 채우기) |
| `/tutorial` | 사용법 안내 (첫 실행 1회 자동, 홈에서 재열람) |
| `/home` | 4탭 컨테이너(학습/게임/기록/함께), 공용 AppBar(프로필 전환·이름/아바타 편집·도움말·소리 설정) |
| `/level-select` | 1~5단계 + 모드 토글(도전/타임어택/연속/연습) |
| `/game` | 모든 학습 모드 공용 세션 화면 |
| `/result` | 정답·오답·미풀이·소요시간·최대콤보, 신기록 뱃지, 기록 저장 |
| `/records` · `/record-detail` | 과거 기록 리스트 / 문항별 상세 |
| `/badges` | 도장판 — 기본 뱃지 + 사용자 커스텀 도장 |
| `/stats` | 학습 통계 — 주간 리포트(최근 7일)·정답률·연산별·레벨별·약점 |
| `/wrong-notebook` | 오답노트 — 틀린/미풀이 문제 집계 |
| `/review-select` · `/review` | 날짜 선택 → 그날 오답 다시 풀기 |
| `/times-table-select` 외 4 | 구구단/혼합/방정식/플래시/어림셈 진입 화면 |
| `/sign-guess-select` · `/sign-guess` | 부호 맞추기 — 레벨 선택 후 숨겨진 연산자 채우기 (기록 저장 안 함) |
| `/action-select` → 9 게임 | 몬스터/풍선/타워/두더지/사다리/물고기/저울/아레나/수학 빙고 (9종 모두 플레이 가능, 컨셉별 최고 점수 표시) |
| `/coop-lobby` → `/coop-learn` · `/coop-coach` | 부모와 함께하는 학습 — 근거리 1:1 연결 후 역할별 화면 |
| `/coop-records` · `/coop-record-detail` | 함께 학습 세션 기록 / 상세 |

## 난이도 규칙

레벨별로 두 피연산자의 자릿수 쌍이 다릅니다:

| 레벨 | A 자릿수 | B 자릿수 | 표시 라벨 |
|---|---|---|---|
| 1 | 1 | 1 | 1자리수 |
| 2 | 2 | 1 | 2자리수+1자리수 |
| 3 | 2 | 2 | 2자리수+2자리수 |
| 4 | 3 | 2 | 3자리수+2자리수 |
| 5 | 3 | 3 | 3자리수+3자리수 |

연산별 세부 규칙:

- **덧셈/곱셈**: 위 표대로 A자리 × B자리 그대로
- **뺄셈**: 두 값 생성 후 큰 쪽이 앞에 오도록 swap (음수 방지)
- **나눗셈**: `피제수 = 몫 × 제수`로 구성해 항상 정수 결과. 1자리 제수는 2~9로 제한 (÷1 회피), 몫은 항상 ≥ 2 (`n÷n=1` 회피). 자릿수 조건이 안 맞는 제수는 while 루프로 재추첨

레벨 1 나눗셈은 의도적으로 가능 조합이 적습니다 (`4÷2`, `6÷2`, `8÷2`, `6÷3`, `9÷3`, `8÷4`).

규칙을 바꿀 때는 `lib/app/data/services/problem_generator.dart`의 `_digitsForLevel`과 `lib/app/modules/level_select/level_select_view.dart`의 `_levelLabel`을 함께 수정하세요. 액션 게임의 자릿수 선택지(`action_select_controller.dart`)도 같은 사다리를 따릅니다.

## 세션 모드

레벨 선택 화면의 세그먼트 토글로 고릅니다. 저장되는 `GameRecord.mode`는 `challenge`/`timeAttack`/`endless`:

- **도전 (challenge)** — 고정 10문제 / 180초 카운트다운. 기록 저장. "만점"·마스터 뱃지에 반영되는 유일한 모드
- **연습 (practice)** — 시간 제한·기록 없음 (구구단은 항상 연습)
- **타임어택 (timeAttack)** — 60초 카운트다운, 제출할 때마다 새 문제 추가. 기록 저장
- **연속 (endless)** — 타이머 없음, 정답이면 다음 문제 추가, **첫 오답에서 종료**. 기록 저장

신기록 비교는 모드별로 `(type, level)` 버킷 안에서: 도전은 만점 런 중 최소 소요시간, 타임어택/연속은 최대 정답 수.

### 특별 학습 모드

모두 `/game`을 거치지만 별도 플래그로 동작하며 기록의 `type`은 roll-up 라벨(mixed/equation/flash/estimation)로 기록됩니다:

- **구구단** — `N×1..N×9` 셔플 9문제, 연습 강제
- **혼합** — 2개 이상 연산을 하나의 복합식(`5 + 3 × 2 - 1 = ?`)으로 출제(정수·비음수 보장)
- **방정식** — `A op ? = C` 형태, 숨은 피연산자를 맞힘
- **플래시** — 문제를 잠깐(1.5/2/2.5초) 보여준 뒤 숨기고 암산으로 답
- **어림셈** — 피연산자를 반올림해 3지선다로 답 (÷ 제외)

**부호 맞추기**는 `/game`을 거치지 않는 독립 모드입니다(`/sign-guess-select` → `/sign-guess`). 식에서 연산자를 가리고 왼쪽부터 채우며, 레벨이 연산자 개수(1/2/3/3/5)와 후보 풀(L1–3은 `+ −`, L4–5는 `+ − × ÷`)을 결정합니다. 결과가 같아지는 **모든** 연산자 조합을 정답으로 인정하고, 기록은 저장하지 않습니다.

## 아레나 (게임 탭 — 웨이브 생존)

액션 게임 중 유일한 **누적형** 모드입니다. 다른 액션 게임이 한 판 단위로 끝나는 것과 달리 아레나는 웨이브를 하나씩 깨며 올라가고, 강화 효과·방어막·콤보 배수가 웨이브를 넘어 이어집니다. 끝내 지도록 설계돼 있고(적은 늘고 시간은 줄어듦), 목표는 클리어가 아니라 **최고 기록 갱신**입니다.

- **한 웨이브** = 제한시간 안에 적 N마리 처치. 문제 하나가 공격 한 번(객관식).
- **보스** = 3웨이브마다. 적은 한 마리지만 HP가 여러 칸이고 시간이 6초 더 주어집니다.
- **웨이브가 오르면 네 가지가 함께 조여집니다** — 적 수(2웨이브마다 +1, 최대 8), 제한시간(웨이브마다 −1초 → 12초, 이후 3웨이브마다 −1초 → 최종 10초), **자릿수**(3웨이브마다 사다리 한 칸 ↑), **보기 수**(11웨이브부터 3개 → 4개).
- 진입 화면에서 고른 자릿수는 **시작점**입니다. 1자리로 시작해도 4웨이브에 2자리×1자리, 13웨이브면 3자리×3자리가 됩니다. 올라가는 웨이브에는 배너가 "숫자가 커져요!"로 이유를 알려 줍니다.
- **강화 카드** = 웨이브 클리어마다 5종 중 3장을 무작위로 제시 → 1장 선택. 점수 2배 / 하트 회복 / 시간 +5초 / 방어막 / 보기 줄이기. 회복·방어막을 빼면 효과는 **다음 웨이브 한 판만** 갑니다.
- **점수** = 기본 10점 × 콤보 배수(5연속 ×2, 10연속 ×3) × 강화, 빠르게 맞히면 크리티컬 보너스. 보스 처치 시 추가 점수.
- **실패** = 오답은 하트 -1(방어막이 있으면 대신 소모, 적은 그대로), 시간 초과는 하트 -1 후 **같은 웨이브 재시작**. 하트 0이 유일한 종료 조건입니다.
- 정답 연출 중과 강화 선택 중에는 웨이브 시계가 멈춥니다 — 아이가 손쓸 수 없는 시간에 벌을 주지 않기 위해서입니다.
- **화면이 계속 움직입니다.** 풍선/물고기와 같은 `Ticker` 방식으로 뷰가 매 프레임 경과 ms를 만들고, 배경 흐름·적의 부유·보스의 호흡·히어로의 둥실거림이 전부 거기서 나옵니다.
- **적이 시간에 따라 아래로 내려옵니다** — 남은 시간 비율이 곧 적의 위치라, 숫자를 보지 않아도 압박이 느껴집니다. 5초 이하면 테두리와 시간이 붉게 두근거립니다.
- 정답을 맞히면 히어로가 ⚡를 쏘고 💥로 터지며, 오답이면 화면이 흔들립니다. 콤보 배수가 오를 때 칩이 튀고, 점수는 굴러가듯 올라가며, 강화 카드는 차례로 미끄러져 들어옵니다.
- 연출은 전부 뷰에 있고, 컨트롤러는 `gainTick`/`hitTick` 같은 카운터만 노출합니다(컨트롤러에 애니메이션 코드 없음).

## 부모와 함께하는 학습 (함께 탭)

두 기기를 근거리에서 1:1로 연결(**Nearby Connections** — 블루투스 + 로컬 Wi-Fi, 인터넷 전송 없음)해, 아이가 푸는 화면을 부모가 실시간으로 보며 난이도 조절·칭찬 이모지를 보내는 모드입니다.

- **연결**: `/coop-lobby`에서 한쪽이 방 만들기(호스트), 다른 쪽이 참여하기(게스트) → 연결은 자동 수락(아이가 승인 창을 만나지 않도록) → 각자 **역할**(아이/부모) 선택. 호스트/게스트(누가 방을 열었나)와 역할(부모/아이)은 서로 독립입니다.
- **진행**: 호스트가 세션 설정(연산·레벨)을 전송하고 시작 → `problem_state` / `attempt_result` / `coach_emoji` / 일시정지 / 종료 메시지가 오갑니다. 연결이 끊기면 `bye(connection_lost)`로 동일하게 처리됩니다.
- **기록**: 세션 요약은 `CoopRecordService`(`coop_records_v1`)에 별도 저장되며, 학습 통계·뱃지·연속일수에는 **영향을 주지 않습니다.**
- **권한**: API 레벨별로 분기(13+ 블루투스 3종 + 근거리 Wi-Fi, 12 블루투스 3종, 11 이하 위치). 위치 추론 용도가 아님을 매니페스트에 `neverForLocation`으로 명시합니다.
- 개발 시 **실기기 2대**가 필요합니다(위 "개발 환경 설정 §5"). 설계 근거는 `DOC/PARENT_COOP_LEARNING.md`.

## 게임 진행 룰

- 답안 입력은 숫자만, **빈 값 제출 차단** (빨간 스낵바 "값을 입력 해 주세요.")
- 타이머가 있는 모드는 종료 임박 시 효과음(tick)·색상 경고, 시간 초과 시 미응답 문제는 미풀이 처리
- 정답 콤보 3/5/7/10 도달 시 축하 햅틱
- 종료 시 `GameRecord`(`finishedAt`/`type`/`level`/correct/wrong/unsolved/elapsed/attempts/maxCombo/mode)가 `RecordService`로 저장 (연습·구구단 제외)

## 아키텍처

GetX 모듈 패턴:

```
lib/app/
  routes/
    app_routes.dart       # 라우트 이름 상수
    app_pages.dart        # GetPage 리스트
  data/
    models/               # game_type, session_mode, problem, problem_attempt,
                          # game_record, achievement_badge, custom_stamp,
                          # stamp_condition, daily_mission, wrong_notebook_entry,
                          # estimation_choices, action_concept
    services/
      problem_generator.dart   # 순수 함수 (Random)
      record_service.dart      # GetxService, SharedPreferences (기록 + 오답 dismissal + streak, 프로필별 스코프)
      profile_service.dart     # 다중 프로필(이름 + 아바타) + activeId + 튜토리얼 노출 플래그
      sfx_service.dart         # BGM/효과음 독립 채널(각 on/off + 볼륨) + 햅틱
      custom_stamp_service.dart# 사용자 커스텀 도장 CRUD (프로필별 스코프)
      action_score_service.dart# 액션 미니게임 최고 점수/플레이 횟수 (프로필별 스코프)
      coop_record_service.dart # 함께 학습 세션 기록 (프로필별 스코프, 학습 기록과 분리)
      theme_service.dart       # 라이트/다크/시스템 테마 모드 (앱 단위, 프로필 무관)
      coop_permissions.dart    # API 레벨별 Nearby 런타임 권한 분기 (정적 헬퍼)
      multiplayer/
        multiplayer_transport.dart # P2P 추상 인터페이스 + TransportEvent
        nearby_transport.dart      # nearby_connections 실제 구현
        multiplayer_service.dart   # 연결 상태 머신 (CoopLobbyBinding에서 put)
        coop_session.dart          # 함께 학습 프로토콜(핸드셰이크/설정/진행)
  modules/<feature>/
    <feature>_view.dart        # GetView<Controller> 위젯
    <feature>_controller.dart  # 상태 + 비즈니스 로직
    <feature>_binding.dart     # 컨트롤러 → 라우트 와이어링
  shared/                 # date_format, korean_particle, digit_ladder, badges, daily_missions,
                          # streak, weakness, wrong_notebook, weekly_report,
                          # action_record_line, 재사용 위젯 등
```

7개 서비스(`ProfileService`, `RecordService`, `SfxService`, `CustomStampService`, `ActionScoreService`, `CoopRecordService`, `ThemeService`)는 `main()`에서 `Get.putAsync`로 등록됩니다. `MultiplayerService`만 예외로 `CoopLobbyBinding`에서 등록합니다 — 사용자가 함께 탭에 들어갈 때만 P2P 스택(라디오)을 켜기 위해서입니다.

**다중 프로필**: `ProfileService`가 `profiles[]` + `activeId`를 관리합니다(형제자매용). primary 프로필(id 1)은 기존 무접미사 키를 그대로 쓰고, 추가 프로필은 `_p<id>` 접미사로 기록/도장/액션 점수 데이터를 분리합니다 — 기존 단일 사용자 설치는 마이그레이션이 필요 없습니다. 프로필 전환은 스코프 서비스 캐시를 reload한 뒤 `/home`을 리부트합니다.

**Lazy vs eager binding**: 기본 `Get.lazyPut`은 `Get.find<T>()` 가 처음 호출될 때 컨트롤러를 만듭니다. `GetView<T>.controller` 를 `build`에서 안 읽는 화면(예: `onReady`에서 타이머만 도는 스플래시)은 `Get.put(...)`을 써야 `onInit/onReady`가 실행됩니다 — `SplashBinding` 참고.

**기록 식별**: `RecordService`는 `finishedAt` (DateTime ms) 동등성으로 단일 기록을 식별합니다. 일괄 import / seeding을 도입한다면 명시적 `id` 필드가 필요해집니다. JSON 키는 `game_records_v4`, 스키마 변경 시 키 suffix를 올려 구버전 설치의 `fromJson` 충돌을 피하세요.

**액션 게임**은 `/game`·`RecordService`(`GameRecord`)를 거치지 않는 별도 아케이드 트랙입니다. 학습 기록에는 남지 않지만, 컨셉별 **최고 점수·플레이 횟수**는 `ActionScoreService`로 저장되어 진입 화면과 게임오버 오버레이(신기록 배지)에 표시됩니다.

## 기술 스택

- **Dart SDK**: `^3.11.4`
- **상태/내비게이션**: `get` ^4.7.3
- **저장소**: `shared_preferences` ^2.5.5
- **효과음**: `audioplayers` ^6.1.0
- **공유/파일**: `share_plus` ^10.1.4, `path_provider` ^2.1.4
- **애니메이션**: `lottie` ^3.3.1
- **함께 학습(P2P)**: `nearby_connections` ^4.3.0, `permission_handler` ^11.3.1, `device_info_plus` ^11.1.0 — 근거리 전용, 인터넷 통신 없음
- **타이포그래피**: 번들 TTF **Jua / 주아** (`assets/fonts/Jua-Regular.ttf`) — `google_fonts` 미사용(오프라인 준수). 날짜 포맷은 `intl` 대신 `shared/date_format.dart`
- **아이콘**: `flutter_launcher_icons` ^0.14.4 (dev), `flutter_lints` ^6.0.0 (dev)
- **타깃**: Android 전용 (iOS/web/desktop 의도적 비활성화, `ios: false`)

## 테마

- 시드 컬러: `Colors.blue` (light brightness), Material 3
- 스캐폴드 배경: 크림색 `#FFF8E7`
- AppBar: 연한 하늘색 `#4FC3F7` 배경 + 진한 파랑 `#0D47A1` 글씨
- 하단 NavigationBar: 따뜻한 베이지 팔레트
- 모든 텍스트: `ThemeData(fontFamily: 'Jua')` 상속 (개별 위젯에서 `fontFamily` 하드코딩 금지)
- **다크 테마**: `main.dart`에 `darkTheme`(스캐폴드 `#121417`, AppBar `#0D47A1`)이 함께 정의되어 있고, 적용 모드는 `ThemeService`(기본 `ThemeMode.system`)가 결정합니다. 새 화면은 라이트/다크 양쪽에서 확인하고 색상은 `Theme.of(context).colorScheme`에서 읽으세요

## 에셋 / 외부 자원

- `assets/images/` · `assets/lottie/` · `assets/audio/` — 디렉터리 단위로 등록 (파일을 넣으면 자동 인식)
- `assets/icon/app_icon.png` — 런처 아이콘 소스
- 효과음: `assets/audio/` (`correct.wav`, `wrong.wav`, `finish.wav`, `tick.wav` — CC0, Kenney Interface Sounds, `assets/audio/LICENSE.txt` 참고)

### Lottie 출처

다음 5개 파일은 [`xvrh/lottie-flutter`](https://github.com/xvrh/lottie-flutter) 예제 저장소(MIT)에서 가져왔습니다:

| 로컬 파일 | 원본 |
|---|---|
| `home_banner.json` | `books.json` |
| `level_banner.json` | `100_percent.json` |
| `game_character.json` | `dog.json` |
| `result_celebrate.json` | `happy birthday.json` |
| `empty_state.json` | `empty_status.json` |

## 명령어

저장소 루트에서 (Flutter SDK가 PATH에 있어야 함):

```bash
flutter pub get                 # 의존성 설치
flutter run                     # 연결된 디바이스/에뮬레이터 실행 (핫리로드)
flutter analyze                 # 정적 분석 (flutter_lints 기반)
flutter test                    # 위젯/유닛 테스트
flutter test test/widget_test.dart                       # 단일 파일
flutter test --plain-name "splash screen is shown"       # 단일 테스트 이름
flutter build apk               # 릴리즈 APK   (android/key.properties 필요 — 위 §4)
flutter build appbundle         # Play Store용 AAB (동일)
flutter build apk --debug       # 서명 없이 되는 빌드 (local.properties 자동 생성용으로도 유용)
dart run flutter_launcher_icons # 런처 아이콘 재생성 (icon 변경 시)
```

버전은 `pubspec.yaml`의 `version: 3.4.1+24` 한 곳만 고치면 됩니다(`android/local.properties`의 `flutter.versionName/Code`는 빌드 때 자동으로 갱신되는 사본이니 직접 수정하지 마세요).

## 테스트 작성 시 주의

`setUp`에서 반드시:

```dart
SharedPreferences.setMockInitialValues({});
SfxService.audioBackendEnabled = false;           // audioplayers MethodChannel 회피
await Get.putAsync<ProfileService>(() => ProfileService().init());
await Get.putAsync<RecordService>(() => RecordService().init());
await Get.putAsync<SfxService>(() => SfxService().init());
await Get.putAsync<ThemeService>(() => ThemeService().init());   // MyApp.build가 find함
```

그리고 `tearDown`에서 `Get.deleteAll(force: true)`. 커스텀 도장 화면을 띄운다면 `CustomStampService`, 액션 게임/진입 화면을 띄운다면 `ActionScoreService`, 함께 학습 기록 화면을 띄운다면 `CoopRecordService`도 등록하세요. `RecordService`/`CustomStampService`/`ActionScoreService`는 `ProfileService` 미등록 시 primary(빈 접미사) 스코프로 폴백하므로 서비스 단위 테스트에서는 `ProfileService` 없이도 동작합니다. 캐노니컬 패턴은 `test/widget_test.dart` 참조.

P2P(함께 학습) 테스트는 라디오를 쓰지 않습니다 — `test/support/fake_transport.dart`(인메모리 `MultiplayerTransport`)로 `MultiplayerService`/`CoopSession`을 구동합니다(`multiplayer_service_test.dart`, `coop_protocol_test.dart`). 새 연결/프로토콜 로직도 이 인터페이스 뒤에 두어야 기기 없이 검증할 수 있습니다.

현재 기준(3.3.0+22): `flutter test` → **187개 통과**. 클론 직후 이 숫자가 안 나오면 코드가 아니라 환경 문제일 가능성이 큽니다.

## 빌드 타깃 / 플랫폼

`android/` 폴더만 구성되어 있습니다. iOS/Web/Desktop이 필요하면 먼저 `flutter create --platforms=...`로 폴더를 추가하세요. 단, 코드에 플랫폼 분기를 넣지 않는 것이 현재 정책입니다. 개인정보 처리방침은 `privacy-policy.md`, 배포·기획 문서는 `DOC/` 참고.
