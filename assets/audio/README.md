# 효과음 (Sound Effects)

| 파일명         | 원본 (Kenney Interface Sounds)   | 트리거                                |
|----------------|----------------------------------|---------------------------------------|
| `correct.wav`  | `confirmation_001.wav`           | 정답 입력 / 복습 중 정답              |
| `wrong.wav`    | `error_006.wav`                  | 오답 입력 / 복습 중 오답              |
| `finish.wav`   | `maximize_001.wav`               | 게임 종료, 복습 완료                  |
| `tick.wav`     | `tick_002.wav`                   | 게임 마지막 5초 타이머 경고 (초당 1회) |

## 라이선스

[Kenney Interface Sounds 1.0](https://kenney.nl/assets/interface-sounds), **CC0 1.0 Universal** (Public Domain). 상업적 사용 가능, 크레딧 의무 없음 (자발적 표기는 환영). 원본 LICENSE는 `LICENSE.txt` 참고.

## 사운드 교체 방법

원하는 사운드로 바꾸려면 같은 파일명(`correct.wav`, `wrong.wav`, `finish.wav`, `tick.wav`)으로 덮어쓰기 하면 됩니다. `.mp3` 등 다른 확장자를 쓰려면 `lib/app/data/services/sfx_service.dart` 상단의 `_correctAsset` 등 상수도 함께 수정.

파일 교체 후엔 **핫리로드 대신 전체 리스타트** (R) — asset 변경은 핫리로드로 반영되지 않음.
