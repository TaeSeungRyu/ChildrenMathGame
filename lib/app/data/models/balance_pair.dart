import 'problem.dart';

/// 저울 맞추기 한 라운드 — 좌/우 접시에 오르는 식 두 개.
///
/// 대소 관계는 두 식의 답에서 파생시킨다(필드로 들고 있지 않는다). 생성기가
/// 관계를 따로 계산해 넘기면 식과 어긋날 여지가 생기는데, 이 모드는 그 관계
/// 자체가 정답이라 어긋나면 곧바로 오답 판정이 된다.
class BalancePair {
  const BalancePair({required this.left, required this.right});

  final Problem left;
  final Problem right;

  /// `1` = 왼쪽이 큼(`>`), `0` = 같음(`=`), `-1` = 오른쪽이 큼(`<`).
  /// [BalanceGameController.onChoiceTap]에 넘어오는 값과 같은 코드 체계.
  int get relation => left.answer.compareTo(right.answer);

  /// 두 답의 차이. 0이면 평형. 난이도(어림으로 판별 가능한 정도)의 지표.
  int get gap => (left.answer - right.answer).abs();
}
