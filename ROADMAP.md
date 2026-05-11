# ROADMAP

기능 추가 로드맵. 우선순위 순.

## 완료

- [x] **1. 효과음 + 햅틱** — `SfxService`, Kenney Interface Sounds (CC0), 홈 음소거 토글, 게임/복습 전 영역 훅 완료.
- [x] **2. 구구단 전용 연습 모드** *(2026-05-11)* — `ProblemGenerator.generateTimesTable`, `times_table_select` 모듈, `GameController`/`ResultController` `tableNumber` arg 분기, 홈 3분할 버튼 추가. 연습 결과는 기록/연속출석/배지에 영향 없음.

## 대기

- [ ] **3. 시간 무제한 "연습 모드"**
  - 시나리오: 게임 시작 전 "도전 / 연습" 토글. 연습은 타이머 없음, 결과는 저장 옵션.
  - 영향: `GameController.totalSeconds` 제거 가능성, `GameRecord`에 `mode` 필드 추가 또는 별도 키 분리.
  - 마이그레이션: `game_records_v4` → `v5` 키 bump 필요 (스키마 변경 시).
  - 고려: 연습 결과를 저장할지 여부 → 저장 시 통계/배지에서 분리할지 결정 필요.

- [ ] **4. 약점 분석 & 추천**
  - `RecordService.all()`의 attempts를 집계 → 연산 × 자리수 × 정답률 표.
  - "자주 틀린"의 정의: 최근 N판(예: 10) 중 정답률 < 임계(예: 60%).
  - 홈에 추천 카드: "오늘 X 연습 어때?" → 해당 type+level로 바로 진입.
  - 기존 `stats` 모듈을 확장하는 형태로 데이터 로직 공유.

- [ ] **5. 문장제 문제 (응용)**
  - 한 줄 스토리 + 사칙연산.
  - 한국어 템플릿 풀 (예: `{name}이/가 {a}개의 {item}을 가지고 있었는데 {b}개를 더 샀어요. 모두 몇 개?`).
  - 단위 매칭: 개/명/마리/원 등 → 명사 사전 + 조사 규칙(이/가, 을/를) 필요.
  - 가장 큰 작업량. 별도 게임 타입(`GameType.wordProblem`) 추가 또는 사칙연산 모드의 "응용 토글"로 처리 결정 필요.
  - 작업 분해 시 별도 분기 PR 권장.
