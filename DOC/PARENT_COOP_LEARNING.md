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

**페어링 방향(제안)**: 아이 기기가 **advertise**("부모님과 함께하기" 대기),
부모 기기가 **discover**해서 아이를 찾아 연결. "찾아서 연결"이라는 조금 더 복잡한
단계를 조작이 능숙한 부모 쪽에 둔다. — *결정 필요*

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

- `minSdkVersion` 확인(`android/app/build.gradle.kts`). 21 미만이면 상향 검토.
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
| `coach_message` | parent → child | `{ kind: praise\|hint\|emoji, text }` | 아이 화면에 칭찬/격려/힌트 오버레이 표시. |
| `session_pause` / `session_resume` | parent → child | `{ }` | 부모가 잠깐 멈춤/재개. |
| `session_summary` | child → parent | `{ correct, wrong, elapsedMs }` | 세션 종료 요약. |
| `bye` | both | `{ reason }` | graceful disconnect. |

설계 원칙:
- **문제 생성은 아이 기기의 `ProblemGenerator`가 담당**(부모는 난이도만 지시).
  대전 모드와 반대 — 협동은 "공정한 동일 문제"가 목표가 아니라 "부모가 아이를
  코칭"이 목표이므로 아이 기기가 진실의 원천.
- `problem_state`는 입력이 바뀔 때마다 보내되 **디바운스(예: 200ms)**로 트래픽 억제.
- `coach_message`는 프리셋 위주(빠른 칭찬 버튼)로 아이에게 즉각 피드백. 자유 입력은
  선택(부모가 짧게 타이핑) — *결정 필요*.

---

## 6. 게임 / UX 설계 (부모 가이드형)

### 아이 화면 (`/coop-learn`)
- 기존 `GameView`의 슬림 버전. 상단에 "부모님과 연결됨 👨‍👩‍👧" 배지.
- 부모가 보낸 `coach_message`가 오버레이(말풍선/이모지 팝)로 잠깐 표시.
- 난이도가 원격 변경되면 다음 문제부터 반영("엄마가 난이도를 바꿨어요!" 토스트).
- 아이는 평소처럼 편하게 풀기만 하면 됨 — **조작 부담을 아이에게 주지 않는다.**

### 부모 화면 (`/coop-coach`)
- 실시간 대시보드:
  - 아이가 지금 보는 문제 + 입력 중인 답 미러(`problem_state`).
  - 누적 정답/오답/정답률·경과 시간(`attempt_result` 집계).
  - 최근 오답 몇 개(어디서 틀리는지 부모가 즉시 파악).
- 컨트롤:
  - 난이도 조절(연산 칩 + 레벨 1~5) → `set_difficulty`.
  - 빠른 칭찬/격려 버튼("잘했어! 👏", "천천히 해도 돼", "거의 다 왔어!") → `coach_message`.
  - 힌트 보내기(선택), 일시정지/재개, 세션 종료.

### 진입점 (홈)
- 학습 탭 "특별 모드" 행 또는 별도 카드에 **"부모와 함께"** 추가. 시각적 우선순위는
  *결정 필요*(대전 카드와의 관계 포함).
- `/coop-lobby`: "아이 기기(연결 대기)" / "부모 기기(아이 찾기)" 두 역할 선택.

---

## 7. 기록 / 배지 연동

- 부모 가이드 세션은 **연습 성격**(난이도가 중간에 바뀌고 부모가 개입) → 기본적으로
  **`GameRecord` 미저장**(연습 모드와 동일 원칙)으로 통계/배지 왜곡 방지. — *결정 필요*
- 대신 부모 화면의 `session_summary`는 그 자리에서 보여 주고, 원하면 주간 리포트에
  "부모와 함께한 학습 N회" 같은 가벼운 카운터만 별도 키로 집계(선택).
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
| **3** | `/coop-lobby` — 역할 선택 + 발견/연결 | 연결까지 |
| **4** | `CoopMessage` 프로토콜 + 핸드셰이크 + `session_config`/`session_start` | 세션 직전까지 |
| **5** | 아이 화면(`/coop-learn`) + `problem_state`/`attempt_result` 스트리밍 | 미러링 |
| **6** | 부모 대시보드(`/coop-coach`) + `set_difficulty`/`coach_message` | 코칭 컨트롤 |
| **7** | 끊김/에러/일시정지 + UX 다듬기 | 다이얼로그·복귀 |
| **8** | privacy-policy + Data Safety 갱신 | **출시 전 필수** |
| **9** | (옵션) 함께학습 카운터/배지 | 별도 PR |
| **10** | 수동 QA(2대) + ROADMAP 갱신 | |

---

## 결정 필요 항목 (체크리스트)

코드 진입 전 답해야 할 것:

- [x] 라이브러리: **Nearby Connections** 확정.
- [x] 게임 설계: **부모 가이드형** 확정.
- [x] 컴플라이언스: **근거리 권한 허용** 확정(privacy-policy/Data Safety 갱신 전제).
- [ ] 페어링 방향: **아이 advertise / 부모 discover** 제안 — 동의?
- [ ] `coach_message`: 프리셋 버튼만 vs 부모 자유 입력 허용?
- [ ] 난이도 변경 적용 시점: **다음 문제부터**(제안) vs 즉시?
- [ ] 기록 저장: **미저장(연습)**(제안) vs 가벼운 카운터만 집계 vs `GameRecord` 저장?
- [ ] 홈 진입점 위치·우선순위(대전 카드와의 관계 포함).
- [ ] 상대 이름/아바타: `ProfileService` 활성 프로필 그대로 송신?
- [ ] `minSdkVersion` 현재 값 확인 후 상향 필요 여부.

위 항목 확정되면 단계 1부터 PR 단위로 진행한다.
