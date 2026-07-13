# 연산 히어로 (children_math_game)

초등학생용(6~9세) 수학 연산 게임 (Flutter, Android 전용). 완전 오프라인 · 계정/네트워크/광고 없음.

사칙연산(덧셈/뺄셈/곱셈/나눗셈)을 5단계 난이도로 풀고, 구구단·혼합·방정식·플래시·어림셈 등 특별 모드와 6종의 액션 미니게임을 제공합니다. 매 게임마다 점수·소요시간·콤보가 기록되고, 도장판/뱃지·오답노트·통계·복습으로 이어집니다.

> 패키지 이름은 `children_math_game`이지만 앱 표시 이름은 **연산 히어로**입니다. 현재 버전 `2.2.1+17`.

## 화면 흐름

```
Splash (2초) ──▶ 첫 실행이면 Tutorial ──▶ Home (3탭: 학습 / 게임 / 기록)
                                            │
   학습 탭 ── 기본연산 4 ─▶ Level Select ─▶ Game ─▶ Result ─▶ Records ─▶ Record Detail
          └─ 특별 모드 5 ─▶ (각 select) ──┘
   게임 탭 ── 액션 6종 ────▶ Action Select ─▶ 각 액션 게임 (최고 점수 저장)
   기록 탭 ── 도장판 / 오답노트 / 결과보기 / 통계 / 복습
```

| 라우트 | 역할 |
|---|---|
| `/splash` | 2초 후 홈으로 (첫 실행이면 튜토리얼로) |
| `/tutorial` | 온보딩 안내 (첫 실행 1회 자동, 홈에서 재열람) |
| `/home` | 3탭 컨테이너(학습/게임/기록), 공용 AppBar(프로필 전환·이름/아바타 편집·도움말·소리 설정) |
| `/level-select` | 1~5단계 + 모드 토글(도전/타임어택/연속/연습) |
| `/game` | 모든 학습 모드 공용 세션 화면 |
| `/result` | 정답·오답·미풀이·소요시간·최대콤보, 신기록 뱃지, 기록 저장 |
| `/records` · `/record-detail` | 과거 기록 리스트 / 문항별 상세 |
| `/badges` | 도장판 — 기본 뱃지 + 사용자 커스텀 도장 |
| `/stats` | 학습 통계 — 주간 리포트(최근 7일)·정답률·연산별·레벨별·약점 |
| `/wrong-notebook` | 오답노트 — 틀린/미풀이 문제 집계 |
| `/review-select` · `/review` | 날짜 선택 → 그날 오답 다시 풀기 |
| `/times-table-select` 외 4 | 구구단/혼합/방정식/플래시/어림셈 진입 화면 |
| `/action-select` → 6 게임 | 몬스터/풍선/타워/두더지/사다리/물고기 (6종 모두 플레이 가능, 컨셉별 최고 점수 표시) |

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
  modules/<feature>/
    <feature>_view.dart        # GetView<Controller> 위젯
    <feature>_controller.dart  # 상태 + 비즈니스 로직
    <feature>_binding.dart     # 컨트롤러 → 라우트 와이어링
  shared/                 # date_format, korean_particle, badges, daily_missions,
                          # streak, weakness, wrong_notebook, weekly_report,
                          # action_record_line, 재사용 위젯 등
```

5개 서비스(`ProfileService`, `RecordService`, `SfxService`, `CustomStampService`, `ActionScoreService`)는 `main()`에서 `Get.putAsync`로 등록됩니다.

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
- **타이포그래피**: 번들 TTF **Jua / 주아** (`assets/fonts/Jua-Regular.ttf`) — `google_fonts` 미사용(오프라인 준수). 날짜 포맷은 `intl` 대신 `shared/date_format.dart`
- **아이콘**: `flutter_launcher_icons` ^0.14.4 (dev), `flutter_lints` ^6.0.0 (dev)
- **타깃**: Android 전용 (iOS/web/desktop 의도적 비활성화, `ios: false`)

## 테마

- 시드 컬러: `Colors.blue` (light brightness), Material 3
- 스캐폴드 배경: 크림색 `#FFF8E7`
- AppBar: 연한 하늘색 `#4FC3F7` 배경 + 진한 파랑 `#0D47A1` 글씨
- 하단 NavigationBar: 따뜻한 베이지 팔레트
- 모든 텍스트: `ThemeData(fontFamily: 'Jua')` 상속 (개별 위젯에서 `fontFamily` 하드코딩 금지)

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
flutter build apk               # 릴리즈 APK
flutter build appbundle         # Play Store용 AAB
dart run flutter_launcher_icons # 런처 아이콘 재생성 (icon 변경 시)
```

## 테스트 작성 시 주의

`setUp`에서 반드시:

```dart
SharedPreferences.setMockInitialValues({});
SfxService.audioBackendEnabled = false;           // audioplayers MethodChannel 회피
await Get.putAsync<ProfileService>(() => ProfileService().init());
await Get.putAsync<RecordService>(() => RecordService().init());
await Get.putAsync<SfxService>(() => SfxService().init());
```

그리고 `tearDown`에서 `Get.deleteAll(force: true)`. 커스텀 도장 화면을 띄운다면 `CustomStampService`, 액션 게임/진입 화면을 띄운다면 `ActionScoreService`도 등록하세요. `RecordService`/`CustomStampService`/`ActionScoreService`는 `ProfileService` 미등록 시 primary(빈 접미사) 스코프로 폴백하므로 서비스 단위 테스트에서는 `ProfileService` 없이도 동작합니다. 캐노니컬 패턴은 `test/widget_test.dart` 참조.

## 빌드 타깃 / 플랫폼

`android/` 폴더만 구성되어 있습니다. iOS/Web/Desktop이 필요하면 먼저 `flutter create --platforms=...`로 폴더를 추가하세요. 단, 코드에 플랫폼 분기를 넣지 않는 것이 현재 정책입니다. 개인정보 처리방침은 `privacy-policy.md`, 배포·기획 문서는 `DOC/` 참고.
