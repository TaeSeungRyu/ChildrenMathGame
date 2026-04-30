# children_math_game

초등학생용 수학 연습 게임 (Flutter, Android 전용).

사칙연산(덧셈/뺄셈/곱셈/나눗셈)을 5단계 난이도로 풀고, 매 게임마다 점수·소요시간이 기록됩니다.

## 화면 흐름

```
Splash (2초) → Home → Level Select → Game (10문제 / 180초) → Result
                ↓                                                ↓
              Records ←──────────────────────────────────────────┘
```

| 라우트 | 역할 |
|---|---|
| `/splash` | 2초 후 자동으로 홈으로 이동 |
| `/home` | 4개 연산 선택 + "결과보기" 진입 |
| `/level-select` | 1~5단계 선택 (자릿수 조합이 다름) |
| `/game` | 10문제 풀이, 180초 카운트다운 |
| `/result` | 정답·오답·소요시간 표시, 기록 자동 저장 |
| `/records` | 과거 기록 리스트 (개별 삭제 확인 다이얼로그) |

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

규칙을 바꿀 때는 `lib/app/data/services/problem_generator.dart`의 `_digitsForLevel`과 `lib/app/modules/level_select/level_select_view.dart`의 `_levelLabel`을 함께 수정하세요.

## 게임 진행 룰

- 한 게임 = 10문제, **180초 하드캡** (둘 중 빠른 쪽으로 종료)
- 답안 입력은 숫자만 (`FilteringTextInputFormatter.digitsOnly`)
- **빈 값 제출 차단**: 입력 없이 "확인" 누르면 빨간 스낵바 "값을 입력 해 주세요." 표시 후 머무름
- **타이머**: 10초 이하 남으면 글자색이 빨강으로 변경
- 시간 초과 시 미응답 문제는 모두 오답 처리
- 종료 시 `GameRecord`(`finishedAt`/`type`/`level`/correct/wrong/unsolved/elapsed) 가 `RecordService`로 저장되며 결과 화면 → 기록 화면으로 노출

## 아키텍처

GetX 모듈 패턴:

```
lib/app/
  routes/
    app_routes.dart       # 라우트 이름 상수
    app_pages.dart        # GetPage 리스트
  data/
    models/               # GameType, Problem, GameRecord
    services/
      problem_generator.dart   # 순수 함수 (Random)
      record_service.dart      # GetxService, SharedPreferences
  modules/<feature>/
    <feature>_view.dart        # GetView<Controller> 위젯
    <feature>_controller.dart  # 상태 + 비즈니스 로직
    <feature>_binding.dart     # 컨트롤러 → 라우트 와이어링
  shared/                 # date_format.dart 등 횡단 헬퍼
```

**Lazy vs eager binding**: 기본 `Get.lazyPut`은 `Get.find<T>()` 가 처음 호출될 때 컨트롤러를 만듭니다. `GetView<T>.controller` 를 `build`에서 안 읽는 화면(예: `onReady`에서 타이머만 도는 스플래시)은 `Get.put(...)`을 써야 `onInit/onReady`가 실행됩니다 — `SplashBinding` 참고.

**기록 식별**: `RecordService`는 `finishedAt` (DateTime ms) 동등성으로 단일 기록을 식별합니다. 일괄 import / seeding을 도입한다면 명시적 `id` 필드가 필요해집니다. JSON 키는 `game_records_v2`, 스키마 변경 시 키 suffix를 올려 구버전 설치의 `fromJson` 충돌을 피하세요.

## 기술 스택

- **Dart SDK**: `^3.11.4`
- **상태/내비게이션**: `get` ^4.7.3
- **저장소**: `shared_preferences` ^2.5.5
- **타이포그래피**: `google_fonts` ^8.1.0 (전체 텍스트 테마는 **Jua / 주아**)
- **애니메이션**: `lottie` ^3.3.1
- **아이콘**: `flutter_launcher_icons` ^0.14.4 (dev)
- **타깃**: Android 전용 (iOS/web/desktop 의도적 비활성화)

## 테마

- 시드 컬러: `Colors.blue` (light brightness)
- 스캐폴드 배경: 흰색
- AppBar: 파란 배경 + 흰 글씨
- 모든 텍스트: `GoogleFonts.juaTextTheme()` (개별 위젯에서 `fontFamily` 하드코딩 금지)

## 에셋 / 외부 자원

- `assets/images/` — 디렉터리 단위로 등록 (파일을 넣으면 자동 인식)
- `assets/lottie/` — Lottie JSON 5개 (홈 배너, 난이도 배너, 게임 캐릭터, 결과 축하, 빈 상태)
- `assets/icon/app_icon.png` — 런처 아이콘 소스

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

`RecordService`를 건드리는 화면을 띄울 때는 반드시 `setUp`에서:

```dart
SharedPreferences.setMockInitialValues({});
await Get.putAsync<RecordService>(() => RecordService().init());
```

그리고 `tearDown`에서 `Get.deleteAll(force: true)`. 캐노니컬 패턴은 `test/widget_test.dart` 참조.

## 빌드 타깃 / 플랫폼

`android/` 폴더만 구성되어 있습니다. iOS/Web/Desktop이 필요하면 먼저 `flutter create --platforms=...`로 폴더를 추가하세요. 단, 코드에 플랫폼 분기를 넣지 않는 것이 현재 정책입니다.
