/// 액션 모드가 공유하는 (피연산자 A 자릿수, B 자릿수) 사다리.
///
/// challenge 모드의 레벨 1~5(`ProblemGenerator._digitsForLevel`)와 **의도적으로
/// 동일한** 단계다. 액션 진입 화면은 이걸 "자릿수 고르기"로 노출하고, 아레나는
/// 고른 칸을 *시작점*으로 삼아 웨이브가 오를수록 한 칸씩 위로 밀어 올린다.
///
/// 두 곳이 각자 상수를 들고 있으면 한쪽만 바뀌었을 때 조용히 어긋나므로 여기
/// 한 곳에서만 정의한다. 단계를 바꾸면 `_digitsForLevel`과
/// `level_select_view.dart`의 `_levelLabel`도 함께 맞춰야 한다.
const List<(int, int)> digitLadder = [
  (1, 1),
  (2, 1),
  (2, 2),
  (3, 2),
  (3, 3),
];

/// [digits] 가 사다리의 몇 번째 칸인지. 목록에 없으면 0(가장 쉬운 칸).
int digitRungOf((int, int) digits) {
  final i = digitLadder.indexOf(digits);
  return i < 0 ? 0 : i;
}
