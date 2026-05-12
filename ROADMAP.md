# ROADMAP

기능 추가 로드맵. 우선순위 순.

## 완료

- [x] **1. 효과음 + 햅틱** — `SfxService`, Kenney Interface Sounds (CC0), 홈 음소거 토글, 게임/복습 전 영역 훅 완료.
- [x] **2. 구구단 전용 연습 모드** *(2026-05-11)* — `ProblemGenerator.generateTimesTable`, `times_table_select` 모듈, `GameController`/`ResultController` `tableNumber` arg 분기, 홈 3분할 버튼 추가. 연습 결과는 기록/연속출석/배지에 영향 없음.
- [x] **3. 시간 무제한 "연습 모드"** *(2026-05-11)* — `LevelSelectView`에 도전/연습 세그먼트 토글, `GameController` `secondsLeft`(카운트다운) → `elapsed`(카운트업) 리팩터 + `isPractice` 플래그 분기, 연습 시 AppBar 타이머는 회색 경과시간 표시 + 프로그레스바는 문제 진행률로 전환, 구구단은 isPractice 자동 true 합류 (180s 카운트다운 제거). `flutter test` 27/27 통과.
- [x] **4. 약점 분석 & 추천** *(2026-05-12)* — `lib/app/shared/weakness.dart`로 순수 집계 모듈 분리 (`analyzeWeakness(records, recentN=10, threshold=0.6, minAttempts=5)`). 최근 N판 attempts를 (type×level)로 묶어 정답률·추천 버킷 산출 (동점 시 낮은 레벨 → enum 순). `StatsController`/`HomeController`가 공유; 통계 화면에 4×5 약점 그리드, 홈 상단에 추천 카드 (탭 시 해당 type+level 연습 모드로 직진). 구구단 placeholder인 `level == 0` 레코드는 분석에서 제외. `flutter test` 38/38 통과.
- [x] **5. 콤보 시스템 (연속 정답 보너스)** *(2026-05-12)* — `GameController.comboCount` Rx (정답 +1 / 오답 리셋), 마일스톤 `{3, 5, 7, 10}` 도달 시 `SfxService.combo()` (heavyImpact 햅틱). `GameView`의 캐릭터 영역 우상단에 `_ComboIndicator` 플로팅 (count<2 숨김, AnimatedSwitcher elastic scale, 마일스톤이면 금색 그라데이션). `GameRecord.maxCombo` 옵셔널 필드 추가 (fromJson 누락 시 0 폴백 → `_storageKey` 유지). 결과·기록 상세에 "최고 콤보 N" 표시 (≥2일 때만). 배지 `combo_5`/`combo_10` 추가 — 진행도는 `records.maxCombo`의 최댓값에서 산정, 연습 모드는 기록 미저장이라 자동으로 카운트 제외. `flutter test` 44/44 통과.
- [x] **7. 일일 미션 (3개/일)** *(2026-05-12)* — `lib/app/data/models/daily_mission.dart` (`DailyMission` + `DailyMissionStatus` + `DailyMissionType` enum: correctAnswers / perfectGames / achieveCombo / correctInType). `lib/app/shared/daily_missions.dart` 순수 모듈로 `generateDailyMissions(day)` (Y*10000+M*100+D 시드 deterministic shuffle + dedupeKey로 같은 shape 제외, 풀 11개 중 3개 픽) + `evaluateDailyMissions(records, now)` (오늘 날짜 레코드만 필터, 타입별 progress 계산). 진행 상태는 RecordService에서 derive — 별도 mutation/persistence 불필요 (연습 모드는 기록 미저장이라 자동 제외). `HomeController.missions` + `missionsCompleted`. 홈 배너 아래 `_DailyMissionCard` (체크 아이콘·취소선·진행도 `X / Y`·완료 시 primary 컬러 + Icons.celebration). `flutter test` 56/56 통과.

## 대기

- [ ] **6. 문장제 문제 (응용)**
  - 한 줄 스토리 + 사칙연산.
  - 한국어 템플릿 풀 (예: `{name}이/가 {a}개의 {item}을 가지고 있었는데 {b}개를 더 샀어요. 모두 몇 개?`).
  - 단위 매칭: 개/명/마리/원 등 → 명사 사전 + 조사 규칙(이/가, 을/를) 필요.
  - 가장 큰 작업량. 별도 게임 타입(`GameType.wordProblem`) 추가 또는 사칙연산 모드의 "응용 토글"로 처리 결정 필요.
  - 작업 분해 시 별도 분기 PR 권장.

- [ ] **8. 누적 오답 드릴 모드**
  - 전 기록의 `attempts` 중 `wrong`/`unsolved`만 풀(pool)로 모아 N개 무작위 출제.
  - 4번 약점 분석과 연결 — 추천 카드에 "같은 유형 연습" / "내가 틀린 문제만 풀기" 두 진입점.
  - `ProblemGenerator.generateFromAttempts(history, count)` 추가 (기존 review 모듈은 한 게임 단위라 별개 경로 필요).
  - 결과는 연습 모드처럼 기록 미저장 (오답을 다시 wrong 처리하면 통계가 왜곡됨).
  - 학습 효과 직접적. 작은~중간 작업량.

- [ ] **9. 타임어택 모드**
  - 60초 안에 무한 출제, 정답 수만 추적. 한 문제 풀면 즉시 다음 문제.
  - 별도 게임 모드 — 기존 `GameController`의 10문제 종료 조건 분기 또는 새 컨트롤러.
  - 메타: "오늘의 최고 기록" / "역대 최고" (type+level별로 저장).
  - 새 라우트 `/time-attack-select` + 결과 저장 키 별도 분리 (기존 `GameRecord`에 mode enum 추가 또는 새 모델).
  - 새로운 재미와 흥미. 중간 작업량 (새 모드 파이프라인).

- [ ] **10. 사용자 프로필 (아바타 + 이름)**
  - 첫 실행 시 이름 + 아바타(이모지 또는 아이콘) 선택 화면.
  - 홈/결과/기록 화면 상단에 표시.
  - 다중 프로필 지원 — 형제자매가 한 기기 공유 시 각자 기록 분리. 프로필 전환 셀렉터.
  - SharedPreferences 키 prefix를 `profile_<id>_` 형태로 변경 (기존 키는 default 프로필로 마이그레이션).
  - 어린이 친화 personalization. 작은~중간 작업량 (다중 프로필이 비용 큼; 단일 프로필만 하면 작음).

## 아이디어 풀 (브레인스토밍)

우선순위 미정, 작은 단위로 언제든 끼워 넣기 좋은 항목들.

**재미/시각**
- 결과 화면 콘페티/폭죽 — 만점 시 더 큰 셀러브레이션 (Lottie 또는 CustomPainter 파티클).
- 캐릭터 반응 애니메이션 — 정답/오답에 따라 `game_character.json` 다른 상태로 스위치 (또는 별도 lottie 풀).
- BGM — 배경 음악 트랙 + 토글 (`SfxService` 확장; loop player 분리).

**부모 친화**
- 부모 PIN 보호 — 기록 삭제/통계 접근 시 4자리 PIN. SharedPreferences 저장, 입력 화면 추가.
- 주간 학습 리포트 — 일주일 활동 요약 카드(게임 수·정답률·연속 출석). 공유/스크린샷 가능 형태.
- 다크 모드 — `ThemeMode` 토글 (시스템/라이트/다크). `main.dart` 테마 + 설정 화면.

**새 게임 모드**
- 혼합 사칙연산 — 한 게임에 4연산 무작위. `GameType.mixed` 또는 레벨 옵션. `ProblemGenerator.generateMixed`.
- 30문제 시험지 모드 — 시간 제한 없이 30문제 정답률만 평가. 시험 대비용.
- 카운트다운 라운드 — 문제당 5~10초 개별 제한. 빠른 판단 훈련.

**메타 진행감**
- XP / 사용자 레벨업 — 정답마다 XP 획득, 누적 시 메타 레벨업 + 폭죽. `UserProgressService`.
- 별 1~3개 평가 — 게임 결과에 정답률+시간 기준 별점. 결과 화면에 표시.
- 일일 챌린지 카드 — 매일 다른 type+level 추천 (약점과 별개; 변화·도전 목적).
