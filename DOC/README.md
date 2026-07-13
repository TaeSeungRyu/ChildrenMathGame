# DOC — 작업 문서 모음

프로젝트의 기획·계획·출시·운영 문서를 한곳에 모은 디렉토리. 코드와 무관한
"작업 문서"는 모두 여기에 둔다. (루트에는 기능적 파일만 유지: `CLAUDE.md`,
`README.md`, `privacy-policy.md`.)

## 현재 진행 / 할 일

| 문서 | 내용 |
|------|------|
| [NEXT_STEPS.md](NEXT_STEPS.md) | 다음 단계 작업 리스트 — **TODO의 단일 출처**. 남은 항목: 다국어(i18n), 오답노트 복습 모드, 난이도 레벨 6, 온보딩 프로필 선택 등 |
| [ROADMAP.md](ROADMAP.md) | 기능 추가 로드맵(우선순위 순). 채택 확정 기능의 상위 목록 |

## 기획안 (구현 전/진행 계획)

| 문서 | 내용 |
|------|------|
| [GAME_MODE_PLAN.md](GAME_MODE_PLAN.md) | 게임모드(액션) 기획안 — "연산 히어로" 액션 미니게임 설계 |
| [HOME_REDESIGN_PLAN.md](HOME_REDESIGN_PLAN.md) | 홈 화면 개편안 — 게임모드 추가 대비 레이아웃 재배치 |
| [LEARNING_FEATURES_ANALYSIS.md](LEARNING_FEATURES_ANALYSIS.md) | 학습 효과 강화("가르치기" 레이어) 기능 후보 분석. 채택 항목은 ROADMAP으로 이관 |
| [BLUETOOTH_VERSUS.md](BLUETOOTH_VERSUS.md) | 블루투스 1:1 대전 모드 단계별 계획(구현 전 결정 사항 포함) |

## 출시 · 운영

| 문서 | 내용 |
|------|------|
| [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md) | Play Store 출시 체크리스트 — "무엇을" (블로커 → 권장 → 메타데이터 → 출시 후) |
| [PLAY_STORE_LAUNCH.md](PLAY_STORE_LAUNCH.md) | Play Store 출시 절차 — "어떻게/언제". **`.gitignore` 등록(미커밋), 개인정보 포함 가능** |
| [TESTER_GUIDE.md](TESTER_GUIDE.md) | 비공개 테스트 참여 안내(테스터 배포용) |

---

문서 추가 시 위 표에 한 줄로 등재하고, 코드와 무관한 작업 문서는 루트가 아닌
이 디렉토리에 둔다.
