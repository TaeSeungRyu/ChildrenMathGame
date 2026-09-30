# 다음 단계 작업 리스트

> 현재 상태: 마켓 배포 진행(버전 `3.4.1+24`). 게임 탭 미니게임 9종 모두 플레이 가능(몬스터 처치 / 풍선 터뜨리기 / 타워 디펜스 / 두더지 잡기 / 숫자 사다리 / 물고기 잡기 / 저울 맞추기 / 아레나 / 수학 빙고). 최근 반영: 오늘의 5문제 도전, **수학 빙고**, 부모와 함께하는 학습(Nearby Connections 실시간 협동).

## 출시 직후 (단기, 1주 이내)

- [ ] **크래시/ANR 모니터링 후속 대응** — Play Console Vitals 확인, 첫 사용자 리포트에 대한 핫픽스(2.0.1) 준비
- [ ] **첫 평점·리뷰 대응** — 1성 리뷰 패턴 분석 후 다음 패치 반영 항목 추출
- [ ] **스토어 메타데이터 A/B 테스트** — `assets/store/feature_graphic.png`, 스크린샷(`Screenshot_20260514_*.png`) 교체 후보 비교
- [ ] **버전 태그 정리** — `git tag v2.0.0` 추가 후 푸시 (현재 태그 없이 커밋만 존재)

## 품질·안정성 (단기~중기)

- [ ] **위젯 테스트 확대** — 신규 모듈 4종(balloon / mole / monster / tower_defense) 컨트롤러 단위 테스트 추가. `CLAUDE.md`의 SfxService 테스트 패턴 따라갈 것
- [x] **`flutter analyze` 워닝 정리** — 분석 경고 0 유지 중 (`No issues found`). 신규 작업 시 0 유지할 것
- [ ] **Dart SDK·의존성 업그레이드 체크** — `flutter pub outdated`로 lottie / audioplayers 등 메이저 점검

## 기능 개선 (중기)

- [x] **부모와 함께하는 학습 모드 (Nearby Connections)** *(2026-07-15)* — 부모 가이드형 실시간 협동 학습 구현 완료. 계획: [PARENT_COOP_LEARNING.md](PARENT_COOP_LEARNING.md). 구성: `MultiplayerService`(전송 추상화 + 상태머신, `nearby_connections`) + `CoopSession`(hello 핸드셰이크 → config/start 프로토콜) + `CoopMessage` 프로토콜. 홈 4번째 "함께" 탭(연결하기/기록보기), 로비(방 개설/참여 + 역할 선택), 아이 화면(`/coop-learn`, 문제 풀이 + problem_state/attempt_result 스트리밍), 부모 대시보드(`/coop-coach`, 실시간 관찰 + 난이도 원격 변경 + 마리오파티식 이모지 + **선긋기/지우개 풀이 도와주기**). 세션 종료 시 양쪽 경량 `CoopSessionRecord` 저장 → 기록보기 상세 + 틀린 문제 다시풀기. 끊김/백그라운드 일시정지/종료 시 셋업 화면 자동 복귀. 단위 테스트: `multiplayer_service_test`/`coop_protocol_test`/`coop_record_service_test`. `privacy-policy.md`에 근거리 연결 조항 반영 완료, `RELEASE_CHECKLIST`/`PLAY_STORE_LAUNCH`에 Data Safety·권한 신고 가이드 갱신 완료. **남은 것: Play Console에서 실제 Data Safety 양식 제출(콘솔 작업), 첫 실행 온보딩.**
- [ ] **다국어(i18n) 지원** — 영어 추가 (글로벌 출시 검토 시). `Jua` 폰트는 한글 전용이므로 영어 fallback 폰트 전략 필요
- [x] **부모 대시보드 강화 (주간 리포트)** *(2026-07-13)* — `lib/app/shared/weekly_report.dart` 순수 모듈(`computeWeeklyReport(records, now)` → 최근 7일 일별 버킷 + 학습일수/게임수/정답률 + `shareText`). 학습 결과(`stats`) 상단에 `_WeeklyReportCard`(7일 막대 그래프 + 헤드라인 지표 + `share_plus` 공유 버튼) 추가. `flutter test`에 `weekly_report_test.dart` 커버.
- [ ] **오답 노트(`wrong_notebook`) 복습 모드** — 오답만 모아 재출제하는 흐름 만들기. 모듈 존재 여부 대비 활용도 확인 필요
- [x] **아바타 + 다중 프로필** *(2026-07-13)* — `ProfileService`를 `profiles[]`+`activeId`로 확장(`Profile` 모델: id/name/avatar). primary(id 1)는 레거시 무접미사 키를 유지, 형제 프로필은 `_p<id>` 접미사로 `RecordService`/`CustomStampService`/`ActionScoreService` 데이터 스코프 분리(데이터 마이그레이션 0). 홈 AppBar에 아바타 버튼 → 프로필 시트(전환/추가/삭제), 이름 편집 다이얼로그에 아바타 픽커. 전환 시 스코프 서비스 reload + `/home` 리부트. 온보딩(첫 실행 프로필 선택)은 후속 작업. `flutter test`에 `profile_service_test.dart` 멀티프로필 그룹 커버.
- [x] **미니게임 점수/최고기록 저장** *(2026-07-13)* — 액션 6종(몬스터/풍선/타워/두더지/사다리/물고기)에 `ActionScoreService`(프로필 스코프, `action_scores_v1`, best+plays) 연결. 각 컨트롤러가 게임오버 시 `report(concept, score)` → `isNewBest`. action-select 상단 "🏆 최고 기록" 카드 + 게임오버 오버레이 공용 `ActionRecordLine`(신기록/최고 표시). `flutter test`에 `action_score_service_test.dart` 커버.
- [ ] **스탬프(`custom_stamp_service`) 보상 다양화** — 도장판 클리어 시 새 배지/테마 언락
- [x] **사운드 옵션 분리** *(2026-07-13)* — `SfxService`를 BGM/SFX 독립 채널로 확장(각 on/off + 0..1 볼륨, 키 `bgm_enabled_v1`/`bgm_volume_v1`/`sfx_enabled_v1`/`sfx_volume_v1`). 기존 `sfx_muted_v1` → `sfxEnabled` 마이그레이션. 별도 BGM 루프 플레이어(`ReleaseMode.loop`, `assets/audio/bgm.wav` — `marketing/make_bgm.py`로 오프라인 생성한 10초 루프), 홈 진입 시 `startBgm()`(idempotent). 홈 AppBar 음소거 아이콘 → "소리 설정" 바텀시트(BGM/효과음 스위치 + 볼륨 슬라이더). `flutter test` 126/126 통과.

## 콘텐츠 확장 (중기)

- [x] **`수학 빙고` 게임 추가** *(2026-10-01)* — 3×3 답판에서 현재 식의 답을 찾아 표시하고 한 줄을 완성하는 액션 9번째 컨셉. 같은 답이 여러 칸이면 원하는 칸을 골라 빙고 줄을 계획할 수 있다. 하트 3 / 90초, 가로·세로·대각선 한 줄 완성 시 승리. 공통 연산·자릿수 선택과 `ActionScoreService` 최고점수 저장을 재사용하며 `bingo_game_test.dart` 4개 테스트를 추가했다.
- [x] **`물고기 잡기` 게임 본편 구현** — 완료. 객관식 "움직이는 타겟" 모델(두더지 잡기 구조를 가로로 헤엄치는 물고기로 변형): 상단 문제 1개 + 정답/오답 물고기가 좌↔우로 헤엄치고 정답 물고기만 탭해 낚음. HP 3 / 60초 / 라운드=문제 1개, `GameRecord` 미저장(다른 액션 모드와 동일 — 단 최고 점수는 이후 `ActionScoreService`로 저장하도록 추가됨). 게임 탭 타일 `onTap`은 `controller.openActionSelect(ActionConcept.fishing)`로 연결됨.
- [x] **`저울 맞추기` 게임 추가** *(2026-08-12)* — 액션 7번째 컨셉. 기존 6종이 전부 `식 → 답` 단방향이라 **비교(대소)** 라는 새 인지 축을 여는 모드로 선택. 좌우 접시에 식이 하나씩 올라가고 `>` / `=` / `<` 중 하나만 고르면 돼 정확한 계산 없이 어림으로도 풀 수 있다(어림셈 모드와 시너지). 라운드 생성은 `ProblemGenerator.balancePair` — 왼쪽을 뽑고 오른쪽은 `synthesizeForAnswer`로 `왼쪽 답 ± 목표 차이`를 역합성해 차이 폭(난이도)을 통제하고, 맞힌 수가 늘수록 밴드를 5~12 → 2~6 → 1~3 으로 좁힌다. 평형(`=`)은 무작위로는 거의 안 나와 `balanceEqualChance`(0.22)로 강제. HP 3 / 60초, `GameRecord` 미저장 + `ActionScoreService`에 best/plays 기록(다른 액션 모드와 동일). 정오답 모두 저울이 정답 방향으로 기울어 확인시키고, 오답 시 같은 라운드 재도전은 없음(3지선다라 재도전 = 찍기). 홈 게임 탭은 홀수 개일 때 마지막 한 종을 가로형 카드(`_WideGameModeTile`)로 눕혀 빈 칸을 없앰. `flutter test`에 `balance_pair_test.dart`(관계 일관성 / 난이도 밴드 축소) + `balance_game_test.dart`(폰 크기 렌더링 / 점수·HP / 게임오버) 커버.
- [x] **`아레나` 게임 추가** *(2026-08-26)* — 액션 8번째 컨셉이자 유일한 **웨이브 생존형("서바이버라이크")**. 기존 7종이 전부 "60초 한 판"의 평평한 구조라 *얼마나 오래 버텼나* 라는 축이 없었고, 판 사이에 이어지는 상태(성장)도 없었다. 아레나는 웨이브마다 적이 늘고(2웨이브당 +1, 최대 8) 제한시간이 줄어(웨이브당 -1초, 하한 12초) **반드시 지도록** 설계했다 — 목표는 클리어가 아니라 최고 기록. 3웨이브마다 보스(적 1마리 + 다중 HP + 시간 +6초). 웨이브 클리어 시 `ArenaUpgrade` 5종 중 무작위 3장을 제시하고 1장을 고른다(점수 2배 / 하트 회복 / 시간 +5초 / 방어막 / 보기 줄이기) — 회복은 즉시, 방어막은 소모될 때까지, 나머지는 다음 웨이브 한 판만 적용해 후반 난이도 붕괴를 막았다. 하트가 가득이면 회복 카드를, 방어막 보유 중이면 방어막 카드를 후보에서 빼 "꽝"을 없앴다. 점수 = 기본 10 × 콤보 배수(5연속 ×2 / 10연속 ×3) × 강화 + 크리티컬(2초 내 정답) 보너스, 보스 처치 +50. 오답은 하트 -1(방어막 우선 소모, 적은 그대로), 시간 초과는 하트 -1 + **같은 웨이브 재시작**(웨이브를 되돌리면 6~9세에겐 벌이 과하다). 정답 연출 중·강화 선택 중에는 웨이브 시계를 세워, 손쓸 수 없는 시간에 지는 일이 없게 했다. 재미 요소는 전부 뷰에 두고 컨트롤러는 tick 카운터만 노출 — 뷰가 `Ticker`로 매 프레임 경과 ms를 만들어(풍선/물고기와 동일한 구조) 배경 스크롤·적 부유·보스 호흡(체력 낮을수록 빠르고 크게 떨림)·히어로 둥실거림을 파생시키고, `waveTotalSeconds` 대비 남은 시간으로 **적이 히어로 쪽으로 내려오게** 해 시간 압박을 위치로 보여 준다(5초 이하면 테두리·시간 붉은 두근거림). 정답 시 히어로 반동 + ⚡ 투사체 → 💥 명중, 오답 시 감쇠 진동 흔들림, 콤보 배수 칩 펀치, 점수 롤업, 강화 카드 순차 등장. **난이도 곡선 보강**(초기 구현은 웨이브 11에서 곡선이 멈추고 산수 난이도는 아예 안 올랐다): ① 자릿수 램프 — 진입 화면 선택값이 *시작 칸*이 되고 3웨이브마다 `shared/digit_ladder.dart`(액션 진입 화면 `digitChoices`와 공유하는 단일 정의)를 한 칸 올린다(1×1 시작 → 4웨이브 2×1 → 13웨이브 3×3에서 상한). 올라간 웨이브에는 배너가 "숫자가 커져요!"로 이유를 알린다. ② 상한 이후 압박 유지 — 제한시간 하한을 12초에서 3웨이브마다 1초씩 더 깎아 최종 10초까지, 11웨이브부터 보기를 3개 → 4개로 늘려 찍기 확률을 1/4로 낮춘다("보기 줄이기" 카드는 그 시점 보기에서 하나를 빼므로 문구를 "하나 줄어요"로 수정). `GameRecord` 미저장 + `ActionScoreService`에 누적 점수 best/plays 기록. `flutter test`에 `arena_game_test.dart`(웨이브 규칙 순수 계산 / 정오답 / 웨이브 클리어→카드→다음 웨이브 / 방어막 / 보기 줄이기 / 타임아웃 / 게임오버) 12개 커버.
- [ ] **`숫자 사다리` 정답 보너스 시간(선택)** — 현재 60초 고정(다른 액션 모드와 동일). 사다리 컨셉상 "정답마다 +N초"로 잘 풀수록 오래 버티는 보상형 검토 가능. 도입 시 사다리 모드만 규칙이 달라짐에 유의.
- [ ] **난이도 레벨 6 추가** — 4자리×3자리 등 상위 난이도 검토 (`_digitsForLevel` 확장)
- [ ] **혼합 연산 모드 강화** — `mixed_select` / `equation_select` / `action_select` 흐름 점검

## 운영·마케팅 (중기)

- [ ] **소개 영상 / Lottie 트레일러** — 스토어 등록용 30초 프리뷰 영상
- [ ] **온보딩 튜토리얼 개선** — `tutorial` 모듈 첫 실행 이탈률 측정 후 단계 축소
- [ ] **분석 도구 도입 검토** — Firebase Analytics 등. 단 아동 앱 컴플라이언스(COPPA / 개인정보 처리방침) 주의

---

### 추천 진행 순서

출시 직후이므로 **모니터링 / 핫픽스(1~3번)** → **테스트 보강(5번)** → **다음 콘텐츠/기능** 순이 안전합니다.
