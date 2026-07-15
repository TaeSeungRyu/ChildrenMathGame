# 부모와 함께하는 학습 모드 (Nearby Connections) — 단계별 계획

부모 기기와 아이 기기를 1:1로 연결해, 아이가 문제를 푸는 동안 부모가 **실시간으로
지켜보고 도와주는** 협동 학습 모드. 경쟁(대전)이 아니라 **부모 가이드형**이다.
본 문서는 구현 전 결정 사항과 단계별 작업 목록을 정리한 것이며, 코드는 아래
**결정 필요 항목**이 확정된 뒤 단계별 PR로 진행한다.

> 관련 문서: [BLUETOOTH_VERSUS.md](BLUETOOTH_VERSUS.md) — 1:1 **대전** 모드 계획.
> 두 모드는 **연결/서비스/프로토콜 전송 레이어(`MultiplayerService` + 트랜스포트
> 인터페이스)를 공유**하고, 프로토콜 메시지·게임 설계·역할만 다르다. 대전 문서에서
> 확정된 라이브러리·권한·서비스·테스트 전략을 그대로 재사용한다.

---

## 0. 범위 / 가정 (확정)

- **플랫폼**: 안드로이드 전용 (CLAUDE.md 정책과 동일).
- **기기 지원(확정)**: 저사양·구형 기기까지 넓게 지원한다. `minSdk`를 권한 단순화
  목적으로 올리지 않고 낮게 유지하며(§3), 그 대가로 늘어나는 권한 분기(특히 구형
  Android의 위치 권한)를 수용한다.
- **인원**: 1:1 — **부모(코치)** 1 + **아이(학습자)** 1.
- **거리**: 두 기기가 근거리(~10m), 인터넷 비의존.
- **연결 방식**: **Google Nearby Connections** (`nearby_connections`). 내부적으로
  Wi-Fi Direct/핫스팟을 사용하되 사전 페어링이 필요 없어 아이도 쉽게 연결한다.
  전략은 `P2P_POINT_TO_POINT`(1:1 최고 대역폭).
- **컴플라이언스(확정)**: 근거리 권한 추가를 허용한다. 단 **로컬 P2P 전용, 인터넷
  전송 없음, 개인정보 미수집** 원칙은 유지하고 privacy-policy / Play Data Safety를
  갱신한다 (§8 참고).
- **게임 설계(확정)**: **부모 가이드형** — 아이는 평소처럼 풀고, 부모는 아이 화면을
  실시간으로 미러링해 보며 난이도 조절·힌트·칭찬을 원격으로 보낸다.

---

## 1. 역할 모델

| 역할 | 기기 | 하는 일 |
|---|---|---|
| **아이 (학습자, learner)** | 아이 태블릿/폰 | 문제를 푼다. 화면 상태(현재 문제·입력·정오)를 부모에게 스트리밍. 부모가 보낸 칭찬/힌트 오버레이를 본다. |
| **부모 (코치, coach)** | 부모 폰 | 아이 화면을 실시간 대시보드로 관찰. 난이도(연산·레벨) 원격 변경, 빠른 칭찬/힌트 전송, 세션 종료. |

**페어링 방향(확정)**: 연결하기 화면에서 **어느 기기든 방을 열거나(방 개설=advertise)
참여(참여=discover)** 할 수 있다. **방을 연 기기가 학습 내용(연산·레벨)을 고르고**
호스트가 된다. 역할(부모/아이)은 연결 직후 각 기기에서 한 번 고른다("나는 부모예요 /
나는 아이예요") — 이 역할이 아이 화면(풀이) vs 부모 화면(대시보드)을 결정한다.
호스트/게스트(연결 담당)와 부모/아이(역할)는 분리돼 있어, 아이가 방을 열고 부모가
참여하는 흐름도, 그 반대도 모두 가능하다.

---

## 2. 기술 선택 (확정: Nearby Connections)

- 패키지: `nearby_connections` (Android 전용, Play 서비스 필요 — 우리 앱은 Android
  전용이라 무방).
- 전략: `Strategy.P2P_POINT_TO_POINT`.
- 대전 문서 §1 비교표의 결론과 동일. 사전 페어링 없이 "발견 → 탭 → 연결".

---

## 3. 권한 / Manifest

대전 문서 §2와 동일 세트를 `android/app/src/main/AndroidManifest.xml`에 추가:

```xml
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"
    android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.NEARBY_WIFI_DEVICES"
    android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.CHANGE_WIFI_STATE" />
```

- **`minSdkVersion`(확정): 저사양·구형 기기 지원을 위해 낮게 유지한다. 권한 분기를
  단순화할 목적으로 minSdk를 올리지 않는다.** 현재 Flutter 기본값 `24`(Android 7.0)을
  그대로 사용 — 이미 현역 기기 ≈99%+를 포함한다. (Android 6.0/5.0까지 넓히려면
  `build.gradle.kts`에 `minSdk = 21`을 명시할 수 있으나, 늘어나는 대상은 1% 미만이고
  권한/QA 비용이 커 ROI가 낮다. 필요하면 그때 낮춘다.)
- **권한 정책 변경 수용(확정)**: 낮은 minSdk를 유지하는 대가로 **API 레벨별 전 권한
  분기를 모두 구현**한다 — 특히 **Android 11 이하에서는 Nearby 스캔에
  `ACCESS_FINE_LOCATION` 런타임 권한이 필요**하다(§상단 매니페스트의 `maxSdkVersion=30`
  분기). privacy-policy/Data Safety에 이 위치 권한 사용 목적(근거리 연결 전용, 위치
  수집 아님)을 명시한다(§8).
- **주의(Play 서비스)**: Nearby Connections는 Google Play services에 의존한다. Play
  서비스가 없는 초저가/AOSP 기기는 minSdk와 무관하게 이 모드가 동작하지 않는다 —
  진입 시 미지원 안내로 우아하게 처리한다.
- 런타임 권한은 모드 진입 시 일괄 요청. 거부 시 상태 `permissionDenied` + 설정 이동 안내.
- **아이 화면에서는 권한 프롬프트를 최소화** — 가능하면 부모 기기(discover) 쪽에
  스캔 권한이 몰리도록 역할을 배치(§1 페어링 방향 근거).

---

## 4. 서비스 레이어 — `MultiplayerService` (대전과 공유)

위치: `lib/app/data/services/multiplayer_service.dart` — 대전 문서 §3과 동일한
얇은 `MultiplayerTransport` 인터페이스 뒤에 `nearby_connections`를 둔다. 협동 모드는
같은 서비스를 쓰되 프로토콜 메시지(§5)와 역할(`CoopRole`)만 추가한다.

상태(Rx enum)는 대전과 공유: `idle / permissionDenied / advertising / discovering /
connecting / connected / inSession / disconnected / error`.

주요 API(대전과 동일 골격):
- `startAdvertising({name, role})` / `startDiscovering({name, role})`
- 발견된 피어 리스트(Rx), `connectTo(peerId)`
- `sendMessage(CoopMessage)` (JSON 직렬화) / `Stream<CoopMessage> incoming`
- `disconnect()`

**테스트 가능성**: `FakeMultiplayerTransport`로 상태 머신·메시지 라우팅을 실제 무선
호출 없이 단위 테스트. `SfxService.audioBackendEnabled` 패턴과 동일.

---

## 5. 프로토콜 (메시지 포맷)

JSON 한 줄을 Nearby `Payload.fromBytes`로 송신. `CoopMessage` sealed 클래스로 모델링.

| `type` | 방향 | 페이로드 | 용도 |
|---|---|---|---|
| `hello` | both | `{ name, avatar, role, version }` | 연결 직후 핸드셰이크. 버전 불일치 시 끊고 안내. |
| `session_config` | parent → child | `{ gameType, level }` | 부모가 아이가 풀 연산·레벨을 지정(또는 확인). |
| `session_start` | parent → child | `{ }` | 부모가 시작 신호. 아이 화면이 문제 풀이로 전환. |
| `problem_state` | child → parent | `{ index, operands, op, typedAnswer }` | 아이가 **지금 보는 문제 + 입력 중인 답**을 실시간 미러링. |
| `attempt_result` | child → parent | `{ index, correct, correctAnswer, userAnswer }` | 제출마다 정오 결과. 부모 대시보드 누적 집계. |
| `set_difficulty` | parent → child | `{ gameType?, level? }` | 부모가 난이도를 원격 변경. **다음 문제부터** 적용. |
| `coach_emoji` | parent → child | `{ emoji, id }` | 부모가 이모지 버튼을 탭하면 아이 화면에 **마리오파티식** 큰 이모지 리액션이 팝업. `id`는 중복 재생 방지용. |
| `session_pause` / `session_resume` | parent → child | `{ }` | 부모가 잠깐 멈춤/재개. |
| `session_summary` | child → parent | `{ correct, wrong, elapsedMs }` | 세션 종료 요약. |
| `bye` | both | `{ reason }` | graceful disconnect. |

설계 원칙:
- **문제 생성은 아이 기기의 `ProblemGenerator`가 담당**(부모는 난이도만 지시).
  대전 모드와 반대 — 협동은 "공정한 동일 문제"가 목표가 아니라 "부모가 아이를
  코칭"이 목표이므로 아이 기기가 진실의 원천.
- `problem_state`는 입력이 바뀔 때마다 보내되 **디바운스(예: 200ms)**로 트래픽 억제.
- **칭찬은 이모지 리액션(확정)** — 자유 텍스트 입력 없음. 부모 화면 하단의 이모지
  팔레트(👍 👏 🎉 ❤️ 🔥 😆 💯 등)를 탭하면 `coach_emoji`가 전송되고, 아이 화면
  중앙~상단에 **마리오파티 이모트처럼 큰 이모지가 튀어오르며 잠깐 떠 있다 사라진다**
  (scale-in + float-up + fade-out, 1~1.5초). 여러 개 연타 시 겹쳐 떠도 무방.
  힌트 텍스트 전송은 범위에서 제외(아이의 학습 집중 유지 + UI 단순).

---

## 6. 게임 / UX 설계 (부모 가이드형)

### 진입점 — 홈 하단 네비게이션 4번째 탭 (확정)
- 홈은 현재 3탭(학습/게임/기록). **4번째 탭 "함께"**(예: `Icons.family_restroom`
  또는 `Icons.groups`)를 신설한다.
  - `HomeController.tabIndex`가 0..3으로 확장, `home_view.dart`의 `NavigationBar`
    destination 4개로 확장, `IndexedStack`에 `CoopTab` 추가.
- **함께 탭(허브)**: 두 개의 큰 메뉴 카드.
  - **연결하기** → `/coop-lobby`
  - **기록보기** → `/coop-records`

### 연결하기 (`/coop-lobby`) — 확정 구성
1. **학습 선택 영역** — 연산(➕➖✖️➗🎲) + 레벨(1~5) 선택. (기존 action-select 톤 재사용)
2. **방 개설** 버튼 — 이 기기가 호스트가 되어 위 학습 설정으로 advertise. 상대의
   참여를 대기.
3. **참여** 버튼 — discover 시작 → 발견된 방 리스트 → 탭해서 접속(학습 설정은
   호스트 것을 그대로 받음).
- 연결 성립 직후 각 기기에서 **역할 선택**("나는 부모예요 / 나는 아이예요") 1회 →
  아이 화면(`/coop-learn`) 또는 부모 화면(`/coop-coach`)으로 분기.

### 아이 화면 (`/coop-learn`)
- 기존 `GameView`의 슬림 버전. 상단에 "함께 연결됨 👨‍👩‍👧" 배지.
- 부모가 보낸 `coach_emoji`가 **마리오파티식 큰 이모지 리액션**으로 팝업(§5).
- 난이도가 원격 변경되면 다음 문제부터 반영("난이도가 바뀌었어요!" 토스트).
- 아이는 평소처럼 편하게 풀기만 하면 됨 — **조작 부담을 아이에게 주지 않는다.**

### 부모 화면 (`/coop-coach`)
- 실시간 대시보드:
  - 아이가 지금 보는 문제 + 입력 중인 답 미러(`problem_state`).
  - 누적 정답/오답/정답률·경과 시간(`attempt_result` 집계).
  - 최근 오답 몇 개(어디서 틀리는지 부모가 즉시 파악).
- 컨트롤:
  - 난이도 조절(연산 칩 + 레벨 1~5) → `set_difficulty`.
  - **이모지 팔레트**(👍 👏 🎉 ❤️ 🔥 😆 💯 …) → 탭하면 `coach_emoji` 전송.
  - 일시정지/재개, 세션 종료.

### 기록보기 (`/coop-records`)
- 지난 **함께학습 세션 요약** 목록(최신순): 날짜, 함께한 상대 이름/아바타, 연산·레벨,
  정답/오답·정답률, 소요 시간. 탭하면 상세(문항별)까지 볼지는 선택.
- 데이터 출처는 §7의 경량 `CoopSessionRecord`(학습 통계/배지와 분리).

---

## 7. 기록 / 배지 연동

- 부모 가이드 세션은 **연습 성격**(난이도가 중간에 바뀌고 부모가 개입) → **기존
  `GameRecord`에는 저장하지 않는다**(학습 통계·약점·배지·연속출석 왜곡 방지, 연습
  모드와 동일 원칙).
- **대신 경량 `CoopSessionRecord`를 별도 저장**해 함께 탭의 **기록보기**에서 보여
  준다(확정, "기록보기" 메뉴 근거):
  - 필드: `finishedAt`, `partnerName`, `partnerAvatar`, `gameType`, `level`(마지막
    난이도), `correct`, `wrong`, `elapsedSeconds`.
  - 신규 `CoopRecordService`(GetxService), 키 `coop_records_v1` + **프로필 스코프**
    (`RecordService`/`ActionScoreService`와 동일한 `scopeSuffix` 규칙). `main()`에서
    `Get.putAsync` 등록, 프로필 전환 시 `reload()`.
  - `session_summary` 수신 시 부모 기기에서 저장(양쪽 저장 시 중복되므로 저장 주체
    1곳으로 고정 — 기본: 각 기기가 자기 관점으로 저장하되 상대 이름만 교차 기록).
- 신규 배지(선택, 후속 PR): `coop_first`(첫 함께학습), `coop_5`(5회) 등.

---

## 8. 컴플라이언스 (근거리 권한 허용 — 필수 후속)

권한을 추가하므로 아래를 **반드시** 갱신한다:

- `privacy-policy.md` — "근거리 기기 연결(Nearby Connections)로 부모/아이 기기가
  **로컬에서만** 연결되며, 학습 진행 데이터는 **인터넷으로 전송·저장되지 않는다**"를
  명시. 수집 항목 없음 유지.
- **Play Console Data Safety** — 근거리 권한(및 필요한 위치/블루투스) 사용 목적을
  "앱 기능(로컬 P2P 학습)"으로 신고. 데이터 수집/공유 없음 유지.
- **Families 정책** — 근거리 연결이 광고·외부 통신이 아님을 확인. 권한은 기능에
  실제로 쓰이는 것만(최소 권한).
- 마케팅 문구의 "완전 오프라인/무권한" 표현을 "인터넷 불필요(근거리 연결만)"로 조정.

---

## 9. 에러 / 끊김 처리

- 세션 중 상대 disconnect → 양측에 "연결이 끊겼어요" 안내 → 아이는 로컬 연습으로
  계속하거나 홈으로, 부모는 로비로.
- 권한 거부 → `permissionDenied` + 설정 이동 버튼.
- Wi-Fi/블루투스 꺼짐 → 시스템 설정 유도.
- 연결 타임아웃(예: 15초) → 취소 + 재시도.
- 백그라운드 진입 → 자동 일시정지(`session_pause`) + 일정 시간 후 종료.

---

## 10. 테스트 전략

- **단위 테스트**: `MultiplayerService` 상태 머신 + `CoopMessage` 직렬화를
  `FakeMultiplayerTransport`로 검증(핸드셰이크, 난이도 변경 라우팅, disconnect 전이).
- **위젯 테스트**: 로비/아이/부모 화면을 모킹 서비스로 렌더. 실제 무선 호출 없음.
- **수동 QA(실기기 2대 필수, 에뮬레이터는 Nearby 미지원)**:
  - 아이 대기 → 부모 발견·연결 5초 이내.
  - 아이 입력이 부모 대시보드에 200ms 내 반영.
  - 부모 난이도 변경이 다음 문제에 반영.
  - 칭찬 메시지가 아이 화면 오버레이로 표시.
  - 한쪽 강제 종료 시 다른 쪽 60초 내 끊김 감지.
  - 권한 거부 후 재진입 안내.

---

## 11. 작업 단계 (단계별 PR 권장)

| 단계 | 산출물 | 비고 |
|---|---|---|
| **0** | 결정 사항 확정(§결정 필요) | 본 문서 하단 체크리스트 |
| **1** | `nearby_connections` 의존성 + 매니페스트 + 권한 요청 흐름 | 빌드 통과 |
| **2** | `MultiplayerService` + `MultiplayerTransport` + `FakeTransport` + 단위 테스트 | UI 없이 로직 (대전과 공유) |
| **3** | 홈 **4번째 "함께" 탭(허브)** — 연결하기/기록보기 메뉴 | `tabIndex` 0..3 확장 |
| **4** | `/coop-lobby` — 학습 선택 + 방 개설/참여 + 발견/연결 + 역할 선택 | 연결까지 |
| **5** | `CoopMessage` 프로토콜 + 핸드셰이크 + `session_config`/`session_start` | 세션 직전까지 |
| **6** | 아이 화면(`/coop-learn`) + `problem_state`/`attempt_result` 스트리밍 | 미러링 |
| **7** | 부모 대시보드(`/coop-coach`) + `set_difficulty` + **이모지 리액션(`coach_emoji`)** | 코칭 컨트롤 |
| **8** | `CoopRecordService` + `session_summary` 저장 + 기록보기(`/coop-records`) | 경량 기록 |
| **9** | 끊김/에러/일시정지 + UX 다듬기 | 다이얼로그·복귀 |
| **10** | privacy-policy + Data Safety 갱신 | **출시 전 필수** |
| **11** | (옵션) 함께학습 배지 + 수동 QA(2대) + ROADMAP 갱신 | 별도 PR 가능 |

---

## 결정 필요 항목 (체크리스트)

코드 진입 전 답해야 할 것:

- [x] 라이브러리: **Nearby Connections** 확정.
- [x] 게임 설계: **부모 가이드형** 확정.
- [x] 컴플라이언스: **근거리 권한 허용** 확정(privacy-policy/Data Safety 갱신 전제).
- [x] 페어링/역할: 연결하기 화면에 **방 개설 / 참여** 둘 다, 연결 후 **부모/아이 역할 선택**.
- [x] 칭찬: **이모지 리액션(마리오파티식)** — 자유 텍스트 없음.
- [x] 난이도 변경 적용 시점: **다음 문제부터**.
- [x] 기록 저장: `GameRecord` 미저장 + **경량 `CoopSessionRecord`**로 기록보기 제공.
- [x] 홈 진입점: **하단 네비 4번째 "함께" 탭 → 연결하기/기록보기 허브**.
- [x] 상대 이름/아바타: `ProfileService` 활성 프로필 그대로 송신(`hello`).
- [x] `minSdkVersion`: **낮게 유지(현재 Flutter 기본 24)**, 권한 단순화 목적 상향 없음.
  API별 전 권한 분기(특히 ≤API30 위치 권한)를 구현하고 policy/Data Safety에 반영.

**모든 결정 항목 확정 완료.** 단계 1(의존성+매니페스트+권한 요청 흐름)부터 PR 단위로
바로 진행 가능하다.
