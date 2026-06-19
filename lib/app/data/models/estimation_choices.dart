/// 어림셈 모드의 한 문제에 딸린 3지선다 보기.
///
/// [choices]는 정답 1개 + 헷갈리는 오답 2개의 섞인 리스트(길이 3).
/// [correct]는 [choices] 안에 들어있는 "정답"의 값(인덱스가 아니라 값 자체).
/// 인덱스를 따로 들고 다니지 않는 이유: choices가 셔플되어도 정답값은 불변이라
/// 비교가 직관적이고, 보기 버튼 위치 변경에 영향을 받지 않는다.
class EstimationChoices {
  const EstimationChoices({required this.choices, required this.correct});

  final List<int> choices;
  final int correct;
}
