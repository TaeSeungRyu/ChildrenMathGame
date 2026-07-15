# 다음 단계 작업 리스트

> 현재 상태: 마켓 배포 진행(버전 `2.2.1+18`). 게임 탭 미니게임 6종 모두 플레이 가능(몬스터 처치 / 풍선 터뜨리기 / 타워 디펜스 / 두더지 잡기 / 숫자 사다리 / 물고기 잡기). 최근 반영: BGM/효과음 채널 분리, 미니게임 최고기록 저장, 부모 주간 리포트, 아바타+다중 프로필, **부모와 함께하는 학습(Nearby Connections 실시간 협동)**.

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

- [x] **부모와 함께하는 학습 모드 (Nearby Connections)** *(2026-07-15)* — 부모 가이드형 실시간 협동 학습 구현 완료. 계획: [PARENT_COOP_LEARNING.md](PARENT_COOP_LEARNING.md). 구성: `MultiplayerService`(전송 추상화 + 상태머신, `nearby_connections`) + `CoopSession`(hello 핸드셰이크 → config/start 프로토콜) + `CoopMessage` 프로토콜. 홈 4번째 "함께" 탭(연결하기/기록보기), 로비(방 개설/참여 + 역할 선택), 아이 화면(`/coop-learn`, 문제 풀이 + problem_state/attempt_result 스트리밍), 부모 대시보드(`/coop-coach`, 실시간 관찰 + 난이도 원격 변경 + 마리오파티식 이모지 + **선긋기/지우개 풀이 도와주기**). 세션 종료 시 양쪽 경량 `CoopSessionRecord` 저장 → 기록보기 상세 + 틀린 문제 다시풀기. 끊김/백그라운드 일시정지/종료 시 셋업 화면 자동 복귀. 단위 테스트: `multiplayer_service_test`/`coop_protocol_test`/`coop_record_service_test`. **남은 것: privacy-policy/Play Data Safety 갱신(근거리·위치 권한), 첫 실행 온보딩.**
- [ ] **다국어(i18n) 지원** — 영어 추가 (글로벌 출시 검토 시). `Jua` 폰트는 한글 전용이므로 영어 fallback 폰트 전략 필요
- [x] **부모 대시보드 강화 (주간 리포트)** *(2026-07-13)* — `lib/app/shared/weekly_report.dart` 순수 모듈(`computeWeeklyReport(records, now)` → 최근 7일 일별 버킷 + 학습일수/게임수/정답률 + `shareText`). 학습 결과(`stats`) 상단에 `_WeeklyReportCard`(7일 막대 그래프 + 헤드라인 지표 + `share_plus` 공유 버튼) 추가. `flutter test`에 `weekly_report_test.dart` 커버.
- [ ] **오답 노트(`wrong_notebook`) 복습 모드** — 오답만 모아 재출제하는 흐름 만들기. 모듈 존재 여부 대비 활용도 확인 필요
- [x] **아바타 + 다중 프로필** *(2026-07-13)* — `ProfileService`를 `profiles[]`+`activeId`로 확장(`Profile` 모델: id/name/avatar). primary(id 1)는 레거시 무접미사 키를 유지, 형제 프로필은 `_p<id>` 접미사로 `RecordService`/`CustomStampService`/`ActionScoreService` 데이터 스코프 분리(데이터 마이그레이션 0). 홈 AppBar에 아바타 버튼 → 프로필 시트(전환/추가/삭제), 이름 편집 다이얼로그에 아바타 픽커. 전환 시 스코프 서비스 reload + `/home` 리부트. 온보딩(첫 실행 프로필 선택)은 후속 작업. `flutter test`에 `profile_service_test.dart` 멀티프로필 그룹 커버.
- [x] **미니게임 점수/최고기록 저장** *(2026-07-13)* — 액션 6종(몬스터/풍선/타워/두더지/사다리/물고기)에 `ActionScoreService`(프로필 스코프, `action_scores_v1`, best+plays) 연결. 각 컨트롤러가 게임오버 시 `report(concept, score)` → `isNewBest`. action-select 상단 "🏆 최고 기록" 카드 + 게임오버 오버레이 공용 `ActionRecordLine`(신기록/최고 표시). `flutter test`에 `action_score_service_test.dart` 커버.
- [ ] **스탬프(`custom_stamp_service`) 보상 다양화** — 도장판 클리어 시 새 배지/테마 언락
- [x] **사운드 옵션 분리** *(2026-07-13)* — `SfxService`를 BGM/SFX 독립 채널로 확장(각 on/off + 0..1 볼륨, 키 `bgm_enabled_v1`/`bgm_volume_v1`/`sfx_enabled_v1`/`sfx_volume_v1`). 기존 `sfx_muted_v1` → `sfxEnabled` 마이그레이션. 별도 BGM 루프 플레이어(`ReleaseMode.loop`, `assets/audio/bgm.wav` — `marketing/make_bgm.py`로 오프라인 생성한 10초 루프), 홈 진입 시 `startBgm()`(idempotent). 홈 AppBar 음소거 아이콘 → "소리 설정" 바텀시트(BGM/효과음 스위치 + 볼륨 슬라이더). `flutter test` 126/126 통과.

## 콘텐츠 확장 (중기)

- [x] **`물고기 잡기` 게임 본편 구현** — 완료. 객관식 "움직이는 타겟" 모델(두더지 잡기 구조를 가로로 헤엄치는 물고기로 변형): 상단 문제 1개 + 정답/오답 물고기가 좌↔우로 헤엄치고 정답 물고기만 탭해 낚음. HP 3 / 60초 / 라운드=문제 1개, `GameRecord` 미저장(다른 액션 모드와 동일 — 단 최고 점수는 이후 `ActionScoreService`로 저장하도록 추가됨). 게임 탭 타일 `onTap`은 `controller.openActionSelect(ActionConcept.fishing)`로 연결됨.
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
