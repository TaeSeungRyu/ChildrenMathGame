import 'package:children_math_game/app/data/models/game_type.dart';
import 'package:children_math_game/app/data/services/problem_generator.dart';
import 'package:flutter_test/flutter_test.dart';

/// `synthesizeForAnswer`는 풍선 게임에서 같은 답을 가지는 정답 풍선 N개를
/// 만들어 내기 위한 핵심 빌딩블록이다. 각 연산/자릿수 조합에서 임의의 target
/// 값을 받았을 때 (a) 답이 정확히 target인 문제를 만들거나, (b) 해당 자릿수
/// 조합 안에서 구성 불가능한 경우 null을 반환해야 한다.
void main() {
  group('ProblemGenerator.synthesizeForAnswer', () {
    test('addition: synthesizes a problem whose answer equals target', () {
      for (var d = 1; d <= 3; d++) {
        for (var i = 0; i < 50; i++) {
          // 자릿수 d 두 번 더하면 답 범위는 [2 .. 2*(10^d - 1)].
          // 그 안에서 임의 target을 골라 합성 가능한지 확인.
          final target = 2 + (i * 7) % (2 * (_pow10(d) - 1) - 1);
          final p = ProblemGenerator.synthesizeForAnswer(
            type: GameType.addition,
            digitsA: d,
            digitsB: d,
            target: target,
          );
          if (p == null) continue; // 자릿수 경계에서는 일부 target이 합성 불가.
          expect(p.answer, target);
          expect(p.type, GameType.addition);
        }
      }
    });

    test('subtraction: a - b == target with a >= b', () {
      for (var i = 0; i < 50; i++) {
        final target = i; // 0..49
        final p = ProblemGenerator.synthesizeForAnswer(
          type: GameType.subtraction,
          digitsA: 2,
          digitsB: 1,
          target: target,
        );
        if (p == null) continue;
        expect(p.answer, target);
        expect(p.operandA, greaterThanOrEqualTo(p.operandB));
      }
    });

    test('multiplication: target must be product of in-range operands', () {
      // target = 24 — 다양한 분해 가능 (3×8, 4×6, 6×4, 8×3, ...).
      final p = ProblemGenerator.synthesizeForAnswer(
        type: GameType.multiplication,
        digitsA: 1,
        digitsB: 1,
        target: 24,
      );
      expect(p, isNotNull);
      expect(p!.answer, 24);
      expect(p.operandA * p.operandB, 24);
    });

    test('multiplication: returns null when target is unreachable', () {
      // 1자리 × 1자리는 1..81 범위만 가능. 81을 넘는 target은 불가.
      final p = ProblemGenerator.synthesizeForAnswer(
        type: GameType.multiplication,
        digitsA: 1,
        digitsB: 1,
        target: 100,
      );
      expect(p, isNull);
    });

    test('multiplication: returns null for prime targets that exceed range',
        () {
      // 1자리 × 1자리에서 소수 target 11은 합성 불가(1×11 불가, 11×1 불가).
      final p = ProblemGenerator.synthesizeForAnswer(
        type: GameType.multiplication,
        digitsA: 1,
        digitsB: 1,
        target: 11,
      );
      expect(p, isNull);
    });

    test('division: a / b == target, divisor in op-rules range', () {
      // target = 7 (몫). 자릿수 2×1: 나누는 수 2..9, 나누는 수 × 7 ∈ [10..99].
      // 즉 b ∈ {2,3,...,9} 중 7*b 가 두 자리인 것만 가능 → b ≥ 2 (14)부터 OK,
      // b=14? no, b는 한 자리니까 b ∈ [2..9], 7*b ∈ [14..63] 모두 두 자리.
      final p = ProblemGenerator.synthesizeForAnswer(
        type: GameType.division,
        digitsA: 2,
        digitsB: 1,
        target: 7,
      );
      expect(p, isNotNull);
      expect(p!.operandB, inInclusiveRange(2, 9));
      expect(p.operandA, p.operandB * 7);
      expect(p.answer, 7);
    });

    test('division: rejects trivial target < 2', () {
      // target = 1 (n÷n = 1) 은 사소한 케이스 — 합성 거부.
      final p = ProblemGenerator.synthesizeForAnswer(
        type: GameType.division,
        digitsA: 2,
        digitsB: 1,
        target: 1,
      );
      expect(p, isNull);
    });
  });
}

int _pow10(int n) {
  var v = 1;
  for (var i = 0; i < n; i++) {
    v *= 10;
  }
  return v;
}
