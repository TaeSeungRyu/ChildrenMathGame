# ROADMAP

기능 추가 로드맵. 우선순위 순.

## 완료

- [x] **1. 효과음 + 햅틱** — `SfxService`, Kenney Interface Sounds (CC0), 홈 음소거 토글, 게임/복습 전 영역 훅 완료.
- [x] **2. 구구단 전용 연습 모드** *(2026-05-11)* — `ProblemGenerator.generateTimesTable`, `times_table_select` 모듈, `GameController`/`ResultController` `tableNumber` arg 분기, 홈 3분할 버튼 추가. 연습 결과는 기록/연속출석/배지에 영향 없음.
- [x] **3. 시간 무제한 "연습 모드"** *(2026-05-11)* — `LevelSelectView`에 도전/연습 세그먼트 토글, `GameController` `secondsLeft`(카운트다운) → `elapsed`(카운트업) 리팩터 + `isPractice` 플래그 분기, 연습 시 AppBar 타이머는 회색 경과시간 표시 + 프로그레스바는 문제 진행률로 전환, 구구단은 isPractice 자동 true 합류 (180s 카운트다운 제거). `flutter test` 27/27 통과.
- [x] **4. 약점 분석 & 추천** *(2026-05-12)* — `lib/app/shared/weakness.dart`로 순수 집계 모듈 분리 (`analyzeWeakness(records, recentN=10, threshold=0.6, minAttempts=5)`). 최근 N판 attempts를 (type×level)로 묶어 정답률·추천 버킷 산출 (동점 시 낮은 레벨 → enum 순). `StatsController`/`HomeController`가 공유; 통계 화면에 4×5 약점 그리드, 홈 상단에 추천 카드 (탭 시 해당 type+level 연습 모드로 직진). 구구단 placeholder인 `level == 0` 레코드는 분석에서 제외. `flutter test` 38/38 통과.
- [x] **5. 콤보 시스템 (연속 정답 보너스)** *(2026-05-12)* — `GameController.comboCount` Rx (정답 +1 / 오답 리셋), 마일스톤 `{3, 5, 7, 10}` 도달 시 `SfxService.combo()` (heavyImpact 햅틱). `GameView`의 캐릭터 영역 우상단에 `_ComboIndicator` 플로팅 (count<2 숨김, AnimatedSwitcher elastic scale, 마일스톤이면 금색 그라데이션). `GameRecord.maxCombo` 옵셔널 필드 추가 (fromJson 누락 시 0 폴백 → `_storageKey` 유지). 결과·기록 상세에 "최고 콤보 N" 표시 (≥2일 때만). 배지 `combo_5`/`combo_10` 추가 — 진행도는 `records.maxCombo`의 최댓값에서 산정, 연습 모드는 기록 미저장이라 자동으로 카운트 제외. `flutter test` 44/44 통과.

## 대기

- [ ] **6. 문장제 문제 (응용)**
  - 한 줄 스토리 + 사칙연산.
  - 한국어 템플릿 풀 (예: `{name}이/가 {a}개의 {item}을 가지고 있었는데 {b}개를 더 샀어요. 모두 몇 개?`).
  - 단위 매칭: 개/명/마리/원 등 → 명사 사전 + 조사 규칙(이/가, 을/를) 필요.
  - 가장 큰 작업량. 별도 게임 타입(`GameType.wordProblem`) 추가 또는 사칙연산 모드의 "응용 토글"로 처리 결정 필요.
  - 작업 분해 시 별도 분기 PR 권장.
