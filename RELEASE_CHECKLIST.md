# Play Store 출시 체크리스트

본 문서는 본 앱(어린이 수학 게임, 안드로이드 전용, 광고 없음, 외부 통신 없음)을 Google Play Console에 출시하기 위한 작업 목록이다. 항목은 **블로커(반드시)** → **권장 강화** → **콘솔 메타데이터** → **출시 후** 순으로 정리한다.

체크박스를 직접 채우면서 진행한다.

---

## 1. 빌드/코드 블로커 (반드시 해결)

업로드 자체가 막히거나 콘솔 검토를 통과하지 못하는 항목.

- [ ] **릴리즈 서명 키 생성**
  - 현재 `android/app/build.gradle.kts:37` 가 `signingConfig = signingConfigs.getByName("debug")`. 디버그 서명 AAB는 Play Console이 거부함.
  - 작업:
    1. `keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload` (저장소 바깥, 예: `~/keys/`).
    2. `android/key.properties` 생성 (gitignore 필수):
       ```
       storePassword=...
       keyPassword=...
       keyAlias=upload
       storeFile=/abs/path/to/upload-keystore.jks
       ```
    3. `build.gradle.kts`에 release signingConfig 추가 + buildTypes.release가 그걸 참조하도록 수정.
  - keystore 분실 시 앱 업데이트 영구 불가 → 안전한 곳 백업.

- [ ] **타겟 SDK 34+ 확인**
  - 2024-08부터 신규 앱은 API 34(Android 14) 이상 필수.
  - `flutter build appbundle` 후 `build/app/outputs/bundle/release/app-release.aab` 의 manifest에서 `targetSdkVersion` 확인 또는 `flutter doctor -v` 로 Flutter 버전 확인 (Flutter 3.24+ 이면 자동 34, 3.27+ 이면 35).
  - 35로 올리려면 `android/app/build.gradle.kts` 의 `targetSdk = flutter.targetSdkVersion` 를 명시값 35로 오버라이드 가능.

- [ ] **AAB로 빌드**
  - `flutter build appbundle --release`
  - APK 직접 업로드 불가 (대용량 앱). AAB만 허용.

- [ ] **applicationId 확정**
  - 현재 `com.rts.rys.ryy.children_math_game`. 일단 정해서 업로드하면 **변경 불가** (이름 바꾸려면 신규 앱으로 다시 출시). 사전 확정 필수.

- [ ] **앱 이름 (`android:label`) 확정**
  - 현재 매니페스트: `어린이의 수학`. 본인 자녀용이면 OK, 일반 공개면 일반 명칭 검토.
  - `AndroidManifest.xml:3` 한 줄.

- [ ] **버전 코드/이름 점검**
  - `pubspec.yaml:19` `version: 1.0.0+1`. `+1` 이 `versionCode`. 첫 출시는 1로 OK, 이후 업로드마다 단조 증가 필수.

---

## 2. 권장 강화 (어린이 앱 심사 통과율 ↑)

기술적으로 출시는 가능하지만, 어린이 타겟 심사를 매끄럽게 통과시키기 위해 정리하면 좋은 항목.

- [ ] **Jua 폰트 번들링 + 런타임 fetch 차단**
  - 현재 `google_fonts`가 첫 실행 시 Google CDN에서 폰트 다운로드. 어린이 앱은 외부 호출 0개가 가장 깔끔.
  - 작업:
    1. `assets/fonts/Jua-Regular.ttf` 다운로드 후 `pubspec.yaml`에 `fonts:` 항목 추가.
    2. `lib/main.dart` 초기화 코드에 `GoogleFonts.config.allowRuntimeFetching = false;` 추가.
    3. 데이터 안전성 양식에서 "전송 데이터 없음"으로 단순 신고 가능.
  - CLAUDE.md "Typography" 절에 이미 가이드 존재.

- [ ] **ProGuard/R8 minify 활성화 검토**
  - Flutter는 기본적으로 release 빌드에서 R8 활성. 그대로 두면 됨. 다만 커스텀 keep 규칙이 필요한 라이브러리가 없는지 확인 (audioplayers, lottie는 일반적으로 문제 없음).

- [ ] **앱 내 placeholder 텍스트 점검**
  - `pubspec.yaml:2` `description: "A new Flutter project."` → 의미 있는 한 줄로 교체 (콘솔 설명과는 별개지만 정리 차원).

- [ ] **권한 매니페스트 재확인**
  - 현재 매니페스트에 권한 선언 0개. 추가 라이브러리 도입 시 자동 병합되는 권한이 없는지 `flutter build apk --release` 후 merged manifest 확인 (`build/app/outputs/logs/` 또는 Android Studio Merged Manifest 뷰).

- [ ] **앱 아이콘 최종 적용**
  - `assets/icon/app_icon.png` → `dart run flutter_launcher_icons` 로 재생성됐는지 확인. 512×512 PNG는 콘솔용으로도 따로 필요.

---

## 3. Play Console 메타데이터/설문 (필수)

콘솔 화면에서 직접 작성. 누락 시 출시 차단.

- [ ] **개발자 계정 생성 + $25 결제 완료**
  - https://play.google.com/console — 1회성. 개인 계정이면 신분증 확인 + 주소 검증 절차 (며칠 소요).

- [ ] **개인정보처리방침 URL 준비**
  - 어린이 타겟 앱은 필수. 데이터를 수집/전송하지 않아도 그 사실을 명시한 정적 페이지 필요.
  - 무료 옵션: GitHub Pages, Notion 공개 페이지.
  - 최소 포함: 앱 이름, 운영자, "본 앱은 사용자 데이터를 외부로 수집/전송하지 않으며 모든 데이터는 기기 내부에만 저장됩니다." 한 문장, 연락처 이메일.

- [ ] **데이터 안전성 양식 (Data Safety)**
  - 모든 앱 의무.
  - google_fonts 런타임 fetch를 끈 경우 → "데이터 수집/공유 없음"으로 가장 단순.
  - 끄지 않은 경우 → "앱 기능을 위해 디스플레이 에셋 다운로드 (수집 안 함)" 신고.

- [ ] **콘텐츠 등급 (IARC) 설문**
  - 설문 응답만 하면 자동 등급 발급. 수학 게임은 대부분 "전체이용가/3+".

- [ ] **타겟 연령대 신고 (Target Audience and Content)**
  - "13세 미만 포함" / "13세 이상" / "모든 연령" 중 선택.
  - 본 앱은 초등학생 대상 → "5–8세" 또는 "9–12세" 선택 시 자동으로 "Designed for Families" 카테고리 후보.
  - **결정 필요**: Designed for Families 프로그램에 참가할지 (가시성 ↑, 광고 정책 엄격 ↔ 광고 없으므로 부담 적음).

- [ ] **광고 포함 여부 = "광고 없음"으로 신고**
  - 사용자 명시. 추후 광고 SDK 도입 시 변경 필요.

- [ ] **국가/지역 선택**
  - 한국 우선. 추후 확장 가능.

- [ ] **앱 카테고리 선택**
  - "교육" 또는 "게임 > 교육".

---

## 4. 스토어 등재 자료 (필수)

- [ ] **앱 이름** (50자 이내, 한국어 OK)
- [ ] **짧은 설명** (80자)
- [ ] **자세한 설명** (4000자)
- [ ] **앱 아이콘** — 512×512 PNG, 투명도 없음
- [ ] **피처 그래픽** — 1024×500 PNG/JPG (1개 필수)
- [ ] **스크린샷** — 폰: 최소 2장, 권장 4–8장 (16:9 또는 9:16 비율, 1080×1920 권장)
- [ ] **태블릿 스크린샷** (선택) — 7인치/10인치 각각
- [ ] **프로모션 동영상** (선택) — YouTube URL

스크린샷 후보 (현 기능 기준):
1. 홈 화면 (4가지 연산 타일 + 일일 미션 카드)
2. 게임 화면 (콤보 인디케이터 + 진행도)
3. 결과 화면 (만점 칭찬 메시지)
4. 도장판 (배지 + 커스텀 도장)
5. 통계 화면 (약점 그리드)
6. 구구단 또는 혼합 모드 선택 화면

---

## 5. 출시 직전 점검 (스모크)

- [ ] **실기기에서 릴리즈 빌드 직접 테스트**
  - `flutter install --release` 로 본인 단말에 설치 후 전체 흐름 1회 (홈 → 4연산 각각 1판 + 구구단 + 혼합 + 결과 + 도장판 + 통계 + 기록 삭제).
  - 폰트 fetch 끈 경우 비행기 모드에서 한 번 실행 → 폰트 정상 로딩 확인.

- [ ] **`flutter analyze` 0 경고, `flutter test` 전체 그린**

- [ ] **Pre-launch report 활용**
  - Play Console 내부 테스트 트랙에 1차 업로드 → 자동 크래시 스캔 결과 확인. 무료, 30분~수 시간 소요.

- [ ] **내부 테스트 → 비공개 테스트 → 프로덕션** 단계적 출시 권장
  - 첫 업로드는 "내부 테스트" 트랙으로 본인 계정 1–2개만 등록. 문제 없으면 프로덕션 전환.

---

## 6. 출시 후

- [ ] **Play Console 알림 모니터링** (정책 위반 통지)
- [ ] **사용자 리뷰 응대 계획** (콘솔에서 직접 답글 가능)
- [ ] **버전 1.0.1 빠른 패치 준비** — 첫 출시 후 흔히 발견되는 잔버그 대응
- [ ] **충돌/ANR 추적 도구 도입 검토** (Firebase Crashlytics — 다만 외부 통신 추가됨, 어린이 앱 정책상 신고 필요)

---

## 예상 일정

| 작업 | 소요 |
|---|---|
| 1번 빌드 블로커 해결 | 0.5일 |
| 2번 강화 작업 (폰트 번들링 등) | 0.5일 |
| 3번 콘솔 메타데이터 + 4번 등재 자료 준비 | 1–2일 |
| 개발자 계정 신원 확인 대기 | 2–7일 (Google측 처리) |
| 내부 테스트 → 프로덕션 검토 | 1–7일 (첫 앱은 보통 3–5일) |

**총 1~2주** 안에 실제 스토어 게재 가능.

---

## 미정 결정 사항

코드 진입 전 답해야 할 것:

- [ ] 앱 이름 최종 (`어린이의 수학` 유지 vs 일반 명칭).
- [ ] applicationId 최종 (`com.rts.rys.ryy.children_math_game` 유지 여부).
- [ ] "Designed for Families" 프로그램 참가 여부.
- [ ] google_fonts 런타임 fetch를 끄고 폰트 번들링할지.
- [ ] 개인정보처리방침을 어디에 호스팅할지 (GitHub Pages / Notion / 기타).
- [ ] 첫 출시 트랙 (내부 테스트로 시작 vs 바로 프로덕션).
