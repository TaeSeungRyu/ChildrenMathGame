# 블루투스 대전 모드 — 단계별 계획

두 대의 안드로이드 기기로 같은 문제를 동시에 풀어 점수를 겨루는 1:1 대전 모드. 본 문서는 구현 전 결정 사항과 단계별 작업 목록을 정리한 것이다. 코드 작성은 아래 **결정 필요 항목**이 확정된 후 시작한다.

---

## 0. 범위 / 가정

- **플랫폼**: 안드로이드 전용 (CLAUDE.md 정책과 동일). iOS/웹/데스크톱 분기 없음.
- **인원**: 1:1 (호스트 1 + 게스트 1). 향후 다인전은 별도 작업.
- **거리**: 두 기기가 블루투스/Wi-Fi Direct 사정거리 안 (~10m). 인터넷 비의존.
- **연령대**: 초등생이 사용. 페어링 단계는 어른 도움 없이 끝낼 수 있을 만큼 단순해야 함 (이게 라이브러리 선택의 핵심 기준).

---

## 1. 기술 선택

후보 비교:

| 옵션 | 장점 | 단점 |
|---|---|---|
| **Google Nearby Connections** (`nearby_connections` 패키지) | 사전 페어링 불필요. BT + Wi-Fi Direct 자동 폴백. 처리량 높음. 광고/탐색 API가 간단. | Google API 의존 (Android 전용이라 문제 없음). Play 서비스 필요. |
| **Bluetooth Classic** (`flutter_bluetooth_serial`) | 의존성 가벼움. RFCOMM 소켓 직접 다룸. | 시스템 설정에서 **사전 페어링이 필수** — 초등생에게 큰 진입 장벽. |
| **BLE** (`flutter_blue_plus`) | Wi-Fi Direct 없이 동작. | 처리량 낮고 GATT 모델이 무거움. 게임 트래픽엔 과한 복잡도. |

**제안: Nearby Connections.** 페어링 없이 "근처 기기 발견 → 탭 → 연결" 흐름이 가능해 본 게임의 대상 사용자에 가장 잘 맞는다. 한 번의 의존성 추가 비용에 비해 UX 이득이 크다.

---

## 2. 권한 / Manifest

`android/app/src/main/AndroidManifest.xml`에 추가:

```xml
<!-- Android 12+ BT 런타임 권한 -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"
    android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

<!-- Android 11 이하 BT 스캔에 필요 -->
<uses-permission android:name="android.permission.BLUETOOTH"
    android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN"
    android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"
    android:maxSdkVersion="30" />

<!-- Nearby Connections의 Wi-Fi Direct 폴백 (Android 13+) -->
<uses-permission android:name="android.permission.NEARBY_WIFI_DEVICES"
    android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.CHANGE_WIFI_STATE" />
```

- `minSdkVersion`을 확인 (`android/app/build.gradle.kts`). Nearby Connections는 16+면 동작하지만 권한 분기가 늘어남.
- 런타임 권한 요청은 별도 `PermissionsService` 또는 `MultiplayerService` 시작 단계에서 일괄 요청. 권한 거부 시 사용자에게 "설정 → 권한"으로 이동하는 안내 다이얼로그.

---

## 3. 서비스 레이어 — `MultiplayerService`

GetX 컨벤션에 따라 `Get.putAsync`로 `main()`에서 등록.

위치: `lib/app/data/services/multiplayer_service.dart`

상태 (Rx enum):

```dart
enum MultiplayerState {
  idle,
  permissionDenied,
  advertising,    // 호스트 대기 중
  discovering,    // 게스트 탐색 중
  connecting,
  connected,
  inGame,
  disconnected,
  error,
}
```

주요 API:

- `Future<void> startHosting({required String displayName})`
- `Future<void> startDiscovering({required String displayName})`
- `Stream<DiscoveredPeer>` — 발견된 호스트 목록 (Rx 또는 Stream)
- `Future<void> connectTo(peerId)` (게스트 측)
- `Future<void> sendMessage(VersusMessage msg)` (JSON 직렬화)
- `Stream<VersusMessage> get incoming`
- `Future<void> disconnect()`

**테스트 가능성**: 플러그인을 직접 호출하지 않고 얇은 `MultiplayerTransport` 인터페이스 뒤에 두면 페이크 트랜스포트로 서비스 로직(상태 머신, 메시지 라우팅)을 단위 테스트 가능. `SfxService.audioBackendEnabled` 패턴과 동일.

---

## 4. 프로토콜 (메시지 포맷)

JSON 한 줄을 Nearby `Payload.fromBytes`로 송신. `VersusMessage` sealed/abstract 클래스로 모델링.

| `type` | 방향 | 페이로드 |
|---|---|---|
| `hello` | both | `{ name, version }` — 연결 직후 핸드셰이크. 버전 불일치 시 즉시 끊고 사용자에게 안내. |
| `match_config` | host → guest | `{ gameType, level, problemCount, seed, problems[] }` — 호스트가 문제 미리 생성해 일괄 전송. |
| `ready` | guest → host | `{}` — 게스트가 화면 준비 완료. |
| `start` | host → guest | `{ startAtUnixMs }` — 양쪽이 같은 시각에 카운트다운 시작. |
| `progress` | both | `{ currentIndex, correctCount }` — 매 제출마다 송신. 상대 진행 표시용. |
| `finish` | both | `{ correctCount, wrongCount, elapsedMs }` — 게임 종료. |
| `rematch_request` / `rematch_accept` / `rematch_decline` | both | `{}` |
| `bye` | both | `{ reason }` — graceful disconnect. |

**문제 생성**: 호스트가 `ProblemGenerator`로 만들어 전체 리스트를 `match_config`에 담아 전송 → 양쪽이 100% 동일한 문제를 본다 (공정성 핵심). 게스트는 자체 생성하지 않는다.

---

## 5. 게임 규칙 (대전 모드 디자인)

세 가지 후보. **결정 필요 항목**으로 다시 정리:

| 모드 | 종료 조건 | 승자 결정 |
|---|---|---|
| **A. 고정 길이** (추천) | 10문제 다 풀면 끝 | 더 많이 맞춘 사람. 동률 시 빠른 사람. |
| **B. 타임어택형** | 60초 카운트다운 | 시간 내 더 많이 맞춘 사람. |
| **C. 선착순** | 누군가 N개(예: 7개) 먼저 맞히면 끝 | 먼저 도달한 사람. |

**제안: A.** 기존 챌린지 모드와 가장 자연스럽게 연결되고, 양쪽이 같은 문제 세트를 풀므로 "내가 빨랐는데도 졌네"가 분명히 드러나 학습 동기가 강해진다.

기타 결정 필요:
- 오답 처리: 다음 문제로 그냥 넘어감 vs 정답까지 못 풀게 막음. 본 게임의 단일 모드는 "넘어감" 패턴 → 동일하게 유지 권장.
- 시간 제한: 게임 전체 180s 캡(챌린지 기준) 적용 vs 해제. 1:1이면 캡 없어도 한 명이 끝나는 시점이 사실상 캡 역할.
- 상대 진행 시각화: 헤더에 상대 아바타 + "5 / 10 · ✓4" 같은 라이브 카운터.

---

## 6. UI 흐름

신규 라우트:

- `/versus-lobby` — 첫 진입. "방 만들기" / "참가하기" 두 큰 버튼.
  - "방 만들기" → 호스트 advertising 시작 → 게임 설정 화면.
  - "참가하기" → discovering 시작 → 발견된 호스트 리스트 → 탭 시 접속 요청.
- `/versus-config` (호스트만) — 게임 종류/레벨 선택. 확정 시 게스트에게 `match_config` 송신.
- 게스트는 호스트 설정을 그대로 받아 대기 화면 표시 ("호스트가 게임을 준비 중...").
- `/versus-game` — 양쪽 동시 시작. 기존 `GameView`의 슬림 버전 + 상단에 상대 진행도 헤더.
- `/versus-result` — 승/패/무 결과, 양쪽 점수, "다시 대결" 버튼 (재대결 협상).

홈 진입점: `_QuickAction` 한 칸을 `대전`(Icons.sports_kabaddi 등)으로 추가하거나, 기존 4분할 행을 5분할로 늘림. 또는 메인 게임 타일 옆에 별도 "대전" 카드 한 줄. **시각적 우선순위 결정 필요.**

---

## 7. 기록 / 배지 연동

- 대전 결과를 `GameRecord`에 섞는지 결정.
  - **권장: 별도 모델** (`VersusRecord` — 내 점수 + 상대 점수 + 결과 enum). 기존 통계/배지가 대전 결과로 왜곡되는 걸 막는다.
  - 약점 분석/일일 미션은 기본적으로 대전 제외 (혼합/구구단 처리와 동일 원칙).
- 신규 배지 후보 (별개 PR로 분리 가능):
  - `versus_first_win` — 첫 승
  - `versus_5_wins` / `versus_20_wins` — 누적 승수
  - `versus_streak_3` — 3연승
- `RecordService` 또는 새로운 `VersusRecordService` — 키는 `versus_records_v1`. 기존 키와 분리.

---

## 8. 에러 / 끊김 처리

- 게임 중 상대 disconnect → 현재 플레이어에게 "상대가 나갔어요" 다이얼로그 → 결과 미저장 → 로비/홈으로.
- 권한 거부 → 상태 `permissionDenied`, 안내 + 설정 이동 버튼.
- 블루투스/Wi-Fi 꺼짐 → 시스템 권한 화면 호출.
- 연결 시도 타임아웃 (예: 15초) → 자동 취소 + 재시도 버튼.
- 백그라운드 진입 → 일시정지 다이얼로그 + 일정 시간 후 자동 종료.

---

## 9. 테스트 전략

- **단위 테스트**: `MultiplayerService` 상태 머신을 `FakeMultiplayerTransport`로 검증 (메시지 순서, 잘못된 핸드셰이크, disconnect 도중 상태 전이).
- **위젯 테스트**: 로비/게임/결과 화면을 모킹된 서비스로 렌더. 실제 BT 호출은 하지 않음.
- **수동 QA 체크리스트** (실기기 2대 필수, 에뮬레이터는 Nearby Connections 미지원):
  - 호스트 advertise 시작 → 게스트 발견 후 연결까지 5초 이내.
  - 양쪽 화면이 같은 문제를 같은 순서로 표시.
  - 한쪽이 게임 중 강제 종료 → 다른 쪽이 60초 이내 끊김 감지.
  - 권한 거부 후 재진입 시 안내 흐름.
  - 재대결 후 새 시드의 문제가 표시되는지.
- `SharedPreferences.setMockInitialValues({})` + 신규 서비스 `Get.putAsync` 패턴은 기존 `widget_test.dart` 컨벤션 그대로.

---

## 10. 작업 단계 (단계별 PR 권장)

| 단계 | 산출물 | 비고 |
|---|---|---|
| **0** | 결정 사항 확정 | 본 문서 하단 체크리스트 |
| **1** | 의존성 + 매니페스트 + 권한 요청 흐름 | 빌드 통과만 확인 |
| **2** | `MultiplayerService` + 페이크 트랜스포트 + 단위 테스트 | UI 없이 로직만 |
| **3** | 로비 화면 (호스트/게스트 선택, 발견/연결) | 연결까지만 |
| **4** | `match_config` 동기화 + 카운트다운 | 게임 직전까지 |
| **5** | 대전 게임 화면 + 진행도 동기화 | `progress` 메시지 처리 |
| **6** | 결과 화면 + 재대결 협상 | `finish`/`rematch_*` |
| **7** | 끊김/에러 처리 + UX 다듬기 | 다이얼로그·복귀 흐름 |
| **8** | (옵션) `VersusRecord` 저장 + 배지 | 별도 PR 권장 |
| **9** | 수동 QA + ROADMAP 갱신 | 2대 실기기 |

---

## 결정 필요 항목 (체크리스트)

코드 진입 전 답해야 할 것:

- [ ] 라이브러리: **Nearby Connections** 채택 동의? 다른 후보 검토 필요?
- [ ] 게임 규칙: **A 고정 길이 / B 타임어택 / C 선착순** 중 어느 것? (기본 제안: A 10문제)
- [ ] 상대 진행 시각화 범위: "현재 문제 번호 + 정답수"까지? 아니면 정답수만?
- [ ] 오답 시 진행: 다음 문제로 넘김 (기존과 동일) vs 정답까지 막기?
- [ ] 홈 진입점: 5분할 / 별도 카드 / 메뉴 어디에?
- [ ] 기록 저장: **별도 `VersusRecord`** vs 기존 `GameRecord`에 mode 추가? (권장: 별도)
- [ ] 배지·도장 연동: 첫 PR에 포함 vs 후속 분리?
- [ ] 상대 이름 표시: `ProfileService.name` 그대로 송신 vs 별명 입력 UI 별도?
- [ ] `minSdkVersion`: 현재 값 확인 후 21(권한 분기 단순화) 미만이면 상향 검토.

위 항목 확정되면 단계 1부터 PR 단위로 진행한다.
