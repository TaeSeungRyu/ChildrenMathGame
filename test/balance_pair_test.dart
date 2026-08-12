import 'package:children_math_game/app/data/models/game_type.dart';
import 'package:children_math_game/app/data/services/problem_generator.dart';
import 'package:flutter_test/flutter_test.dart';

/// 저울 맞추기(비교) 라운드 생성 검증.
///
/// 이 모드는 "두 식의 대소 관계"가 곧 정답이라, 생성기가 만든 관계와 식이
/// 어긋나면 게임이 통째로 틀린다. 관계가 답에서 파생되는지, 난이도(차이 폭)가
/// 진행도에 따라 실제로 좁혀지는지를 확인한다.
void main() {
  const ops = [
    GameType.addition,
    GameType.subtraction,
    GameType.multiplication,
    GameType.division,
  ];
  const digitPairs = [(1, 1), (2, 1), (2, 2), (3, 2), (3, 3)];

  test('relation always matches the two answers', () {
    for (final op in ops) {
      for (final (a, b) in digitPairs) {
        for (var i = 0; i < 60; i++) {
          final pair = ProblemGenerator.balancePair(
            type: op,
            digitsA: a,
            digitsB: b,
            solved: i,
          );
          expect(
            pair.relation,
            pair.left.answer.compareTo(pair.right.answer),
            reason: '$op $a×$b',
          );
          expect(pair.gap, (pair.left.answer - pair.right.answer).abs());
        }
      }
    }
  });

  test('both sides are solvable problems with non-negative answers', () {
    for (final (a, b) in digitPairs) {
      for (var i = 0; i < 80; i++) {
        // type: null == 🎲 랜덤 — 좌우가 서로 다른 연산이어도 성립해야 한다.
        final pair = ProblemGenerator.balancePair(
          type: null,
          digitsA: a,
          digitsB: b,
          solved: i,
        );
        expect(pair.left.answer, greaterThanOrEqualTo(0));
        expect(pair.right.answer, greaterThanOrEqualTo(0));
        expect(pair.left.isCompound, isFalse);
        expect(pair.right.isCompound, isFalse);
      }
    }
  });

  test('an equal round never shows the very same expression twice', () {
    var equalRounds = 0;
    for (var i = 0; i < 400; i++) {
      final pair = ProblemGenerator.balancePair(
        type: GameType.addition,
        digitsA: 2,
        digitsB: 1,
        solved: 0,
      );
      if (pair.relation != 0) continue;
      equalRounds++;
      final same = pair.left.operandA == pair.right.operandA &&
          pair.left.operandB == pair.right.operandB &&
          pair.left.type == pair.right.type;
      expect(same, isFalse, reason: '좌우가 글자 그대로 같은 식이면 문제가 안 된다');
    }
    // balanceEqualChance 가 0.22 라 400판이면 평형 라운드가 충분히 나온다.
    expect(equalRounds, greaterThan(20));
  });

  test('the gap narrows as the player solves more', () {
    // 덧셈 2×1 은 합성 실패가 거의 없어 밴드가 그대로 관측된다.
    int meanGap(int solved) {
      var total = 0;
      var n = 0;
      for (var i = 0; i < 300; i++) {
        final pair = ProblemGenerator.balancePair(
          type: GameType.addition,
          digitsA: 2,
          digitsB: 1,
          solved: solved,
        );
        if (pair.relation == 0) continue; // 평형은 난이도 밴드 밖
        total += pair.gap;
        n++;
      }
      return total ~/ n;
    }

    final early = meanGap(0); // 밴드 5~12
    final mid = meanGap(6); // 밴드 2~6
    final late = meanGap(20); // 밴드 1~3
    expect(early, greaterThan(mid));
    expect(mid, greaterThan(late));
  });
}
