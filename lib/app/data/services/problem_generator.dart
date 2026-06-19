import 'dart:math';

import '../models/estimation_choices.dart';
import '../models/game_type.dart';
import '../models/problem.dart';

class ProblemGenerator {
  static const totalProblems = 10;
  static const timesTableProblems = 9;
  static final _random = Random();

  static List<Problem> generate({required GameType type, required int level}) {
    return List.generate(totalProblems, (_) => _one(type, level));
  }

  /// Single-problem generator for open-ended modes (e.g. time-attack) that
  /// need to lazily append problems as the player advances. Same difficulty
  /// rules as [generate].
  static Problem generateOne({required GameType type, required int level}) {
    return _one(type, level);
  }

  /// Single problem with the operand digit counts ([digitsA], [digitsB])
  /// given directly. Bypasses the level→digits table so the action-mode
  /// entry-select screen can present digit pairs to the player as a first-
  /// class choice rather than as a level number.
  ///
  /// - [type] == null → 매 호출마다 4개 연산(+,-,×,÷) 중 하나를 무작위로 골라
  ///   같은 자릿수 조합으로 출제. action 모드의 "🎲 랜덤" 옵션이 이 경로를 탄다.
  /// - 그 외에는 [generate]/[generateOne]과 동일한 규칙으로 한 문제 생성.
  static Problem generateOneForDigits({
    required GameType? type,
    required int digitsA,
    required int digitsB,
  }) {
    final concrete = type ?? _randomConcreteType();
    return _oneForDigits(concrete, digitsA, digitsB);
  }

  /// Construct a single problem with the given (type, digitsA, digitsB)
  /// whose answer equals [target]. Used by balloon mode to spawn multiple
  /// "matching" balloons that share the same answer.
  ///
  /// Returns null when no operand combination in the digit ranges can hit
  /// [target] (e.g., target outside the natural answer range of the op).
  /// When [type] is null, tries one random concrete op — caller may retry.
  static Problem? synthesizeForAnswer({
    required GameType? type,
    required int digitsA,
    required int digitsB,
    required int target,
  }) {
    final concrete = type ?? _randomConcreteType();
    return _synthesize(concrete, digitsA, digitsB, target);
  }

  static Problem? _synthesize(
    GameType type,
    int digitsA,
    int digitsB,
    int target,
  ) {
    final lowA = digitsA == 1 ? 1 : _pow10(digitsA - 1);
    final highA = _pow10(digitsA) - 1;
    final lowB = digitsB == 1 ? 1 : _pow10(digitsB - 1);
    final highB = _pow10(digitsB) - 1;

    switch (type) {
      case GameType.addition:
        // a + b == target. a ∈ [lowA, highA], b = target - a ∈ [lowB, highB].
        final aMin = (target - highB).clamp(lowA, highA);
        final aMax = (target - lowB).clamp(lowA, highA);
        if (aMin > aMax) return null;
        final a = aMin + _random.nextInt(aMax - aMin + 1);
        final b = target - a;
        return Problem(operandA: a, operandB: b, type: type);

      case GameType.subtraction:
        // a - b == target (a >= b). a ∈ [lowA, highA], b ∈ [lowB, highB], b = a - target.
        final aMin = (target + lowB).clamp(lowA, highA);
        final aMax = (target + highB).clamp(lowA, highA);
        if (aMin > aMax || target < 0) return null;
        final a = aMin + _random.nextInt(aMax - aMin + 1);
        final b = a - target;
        if (b < lowB || b > highB) return null;
        return Problem(operandA: a, operandB: b, type: type);

      case GameType.multiplication:
        // a * b == target. Find divisor a of target in [lowA, highA] with
        // b = target/a in [lowB, highB].
        if (target < 0) return null;
        if (target == 0) {
          // Either operand may be 0 — but _nDigit never produces 0, so reject.
          return null;
        }
        final candidates = <int>[
          for (var a = lowA; a <= highA; a++)
            if (target % a == 0 &&
                target ~/ a >= lowB &&
                target ~/ a <= highB)
              a,
        ];
        if (candidates.isEmpty) return null;
        final a = candidates[_random.nextInt(candidates.length)];
        return Problem(operandA: a, operandB: target ~/ a, type: type);

      case GameType.division:
        // a / b == target (a == target * b). Same constraints as _oneForDigits:
        // - if digitsB == 1, divisor b ∈ [2, 9]
        // - quotient (== target) must be >= 2 (skip trivial n÷n=1)
        // - a == target * b must be in [lowA, highA]
        if (target < 2) return null;
        final bLo = digitsB == 1 ? 2 : lowB;
        final bHi = digitsB == 1 ? 9 : highB;
        final candidates = <int>[
          for (var b = bLo; b <= bHi; b++)
            if (target * b >= lowA && target * b <= highA) b,
        ];
        if (candidates.isEmpty) return null;
        final b = candidates[_random.nextInt(candidates.length)];
        return Problem(operandA: target * b, operandB: b, type: type);

      case GameType.mixed:
      case GameType.equation:
      case GameType.flash:
      case GameType.estimation:
        // Roll-up labels never carry a problem of their own.
        return null;
    }
  }

  static GameType _randomConcreteType() {
    const concrete = [
      GameType.addition,
      GameType.subtraction,
      GameType.multiplication,
      GameType.division,
    ];
    return concrete[_random.nextInt(concrete.length)];
  }

  /// 1×N .. 9×N for the given [table] (2..9), shuffled. The table number is
  /// always the left operand so the question reads as "N × k = ?".
  static List<Problem> generateTimesTable(int table) {
    final problems = List.generate(
      timesTableProblems,
      (i) => Problem(
        operandA: table,
        operandB: i + 1,
        type: GameType.multiplication,
      ),
    )..shuffle(_random);
    return problems;
  }

  static Problem _one(GameType type, int level) {
    final (aDigits, bDigits) = _digitsForLevel(level);
    return _oneForDigits(type, aDigits, bDigits);
  }

  static Problem _oneForDigits(GameType type, int aDigits, int bDigits) {
    switch (type) {
      case GameType.addition:
        return Problem(
          operandA: _nDigit(aDigits),
          operandB: _nDigit(bDigits),
          type: type,
        );
      case GameType.subtraction:
        // Keep larger first so the result never goes negative.
        var a = _nDigit(aDigits);
        var b = _nDigit(bDigits);
        if (a < b) {
          final tmp = a;
          a = b;
          b = tmp;
        }
        return Problem(operandA: a, operandB: b, type: type);
      case GameType.multiplication:
        return Problem(
          operandA: _nDigit(aDigits),
          operandB: _nDigit(bDigits),
          type: type,
        );
      case GameType.division:
        // Build dividend = quotient * divisor so the result is always integer.
        // Reject q < 2 (avoids trivial n÷n=1) and divisors that can't reach the
        // dividend digit range; retry until a valid combo lands.
        while (true) {
          final divisor = bDigits == 1
              ? _random.nextInt(8) + 2
              : _nDigit(bDigits);
          final low = aDigits == 1 ? 1 : _pow10(aDigits - 1);
          final high = _pow10(aDigits) - 1;
          var qMin = (low + divisor - 1) ~/ divisor;
          if (qMin < 2) qMin = 2;
          final qMax = high ~/ divisor;
          if (qMax < qMin) continue;
          final quotient = qMin + _random.nextInt(qMax - qMin + 1);
          return Problem(
            operandA: quotient * divisor,
            operandB: divisor,
            type: type,
          );
        }
      case GameType.mixed:
      case GameType.equation:
      case GameType.flash:
      case GameType.estimation:
        // Roll-up labels never drive problem generation directly. `mixed`
        // dispatches through [generateMixed]; `equation`/`flash`/`estimation`
        // reuse [generate] with the chosen sub-op before rolling up at the
        // record level.
        throw ArgumentError('Roll-up GameType cannot generate problems');
    }
  }

  /// Builds [totalProblems] problems whose operations come from [allowedTypes].
  /// `mixed` itself must not appear in [allowedTypes]. Each chosen operation is
  /// generated at the given [level] difficulty.
  ///
  /// **Compound form**: when [allowedTypes].length is > 1, every problem is a
  /// single chained expression (e.g. `5 + 3 × 2 - 1 = ?`) that uses **every**
  /// selected operation exactly once, in a freshly shuffled order. Standard
  /// operator precedence (×/÷ before +/−) applies during evaluation, and the
  /// generator guarantees every intermediate term and the running +/− total
  /// stays a non-negative integer (division is clean, subtraction never goes
  /// negative). To keep division solvable inside a chain, divisors are clamped
  /// to single digits (2..9) regardless of level.
  ///
  /// When [allowedTypes].length is 1, this falls through to single-operation
  /// problems (same shape as [generate]).
  static List<Problem> generateMixed(
    List<GameType> allowedTypes,
    int level,
  ) {
    if (allowedTypes.isEmpty) {
      throw ArgumentError('allowedTypes must contain at least one operation');
    }
    if (allowedTypes.contains(GameType.mixed)) {
      throw ArgumentError(
        'allowedTypes cannot contain GameType.mixed itself',
      );
    }
    if (allowedTypes.length == 1) {
      return generate(type: allowedTypes.single, level: level);
    }
    return List.generate(
      totalProblems,
      (_) => _compoundOne(allowedTypes, level),
    );
  }

  /// One compound problem using every op in [allowedTypes] exactly once.
  ///
  /// Strategy: shuffle ops, then build operands left-to-right while tracking
  /// the running ×/÷ term value and the partial +/− sum. ÷ picks a divisor of
  /// the current term; − is rejected if it would drive the running sum
  /// negative. On failure we retry the shuffle/build; after `_maxRetries` we
  /// fall back to a small all-addition expression (theoretically reachable
  /// only with extreme bad luck — kept as a safety net).
  static const _maxRetries = 200;

  static Problem _compoundOne(List<GameType> allowedTypes, int level) {
    final (aDigits, bDigits) = _digitsForLevel(level);
    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      final ops = [...allowedTypes]..shuffle(_random);
      final built = _tryBuildCompound(ops, aDigits, bDigits);
      if (built != null) return built;
    }
    return _compoundFallback(allowedTypes);
  }

  static Problem? _tryBuildCompound(
    List<GameType> ops,
    int aDigits,
    int bDigits,
  ) {
    final operands = <int>[_nDigit(aDigits)];
    var currentTerm = operands[0];
    final terms = <int>[];
    final betweens = <GameType>[];

    for (final op in ops) {
      switch (op) {
        case GameType.multiplication:
          final b = _nDigit(bDigits);
          operands.add(b);
          currentTerm *= b;
        case GameType.division:
          final d = _pickCompoundDivisor(currentTerm);
          if (d == null) return null;
          operands.add(d);
          currentTerm ~/= d;
        case GameType.addition:
        case GameType.subtraction:
          // Finalize the current ×/÷ term; the next operand starts a new term.
          terms.add(currentTerm);
          betweens.add(op);
          final next = _nDigit(bDigits);
          operands.add(next);
          currentTerm = next;
        case GameType.mixed:
        case GameType.equation:
        case GameType.flash:
        case GameType.estimation:
          // Roll-up labels are guarded against at their respective entry
          // points (generateMixed / equation / flash / estimation); reaching
          // any of them inside compound-build is a bug.
          return null;
      }
    }
    terms.add(currentTerm);

    var sum = terms[0];
    for (var i = 0; i < betweens.length; i++) {
      final next = terms[i + 1];
      if (betweens[i] == GameType.addition) {
        sum += next;
      } else {
        sum -= next;
        if (sum < 0) return null;
      }
    }
    return Problem.compound(
      operands: operands,
      operations: ops,
      answer: sum,
    );
  }

  /// Picks a 2..9 divisor that cleanly divides [value]. Returns null when
  /// [value] has no such divisor (e.g., value is 1 or a prime ≥ 11) — caller
  /// must retry the whole expression in that case.
  static int? _pickCompoundDivisor(int value) {
    if (value < 2) return null;
    final candidates = <int>[
      for (var d = 2; d <= 9; d++)
        if (value % d == 0) d,
    ];
    if (candidates.isEmpty) return null;
    return candidates[_random.nextInt(candidates.length)];
  }

  static Problem _compoundFallback(List<GameType> allowedTypes) {
    // Last-resort small-addition expression that always validates: 1 + 1 + ...
    // The shape still satisfies the "every selected op appears" contract by
    // substituting the canonical safe op into each slot.
    final operands = List<int>.filled(allowedTypes.length + 1, 1);
    final ops = List<GameType>.filled(
      allowedTypes.length,
      GameType.addition,
    );
    return Problem.compound(
      operands: operands,
      operations: ops,
      answer: operands.length,
    );
  }

  /// 어림셈 모드용 보기 3개를 만든다.
  ///
  /// 한국 초등 교과의 "어림하기" 접근을 따른다 — 피연산자를 레벨에 맞는 자리에서
  /// 반올림한 뒤 그 둘로 계산한 값이 정답. 예: `47 + 28` (L3, 10단위 반올림)
  /// → `50 + 30 = 80`. 정답은 항상 반올림 단위의 배수가 되도록 만들어, 보기
  /// 버튼에 깔끔하게 보이는 숫자만 등장하게 한다.
  ///
  /// 헷갈리는 오답(distractors)은 정답 ± 단위, ± 2단위 후보 중에서 양수만 골라
  /// 2개 뽑는다. 정답에 너무 붙은 ±단위 1개 + 멀찍이 ±2단위 1개를 섞어
  /// "딱 옆에 붙은 함정 + 명백히 틀린 후보" 구도를 만든다 — 단순히 ±1만 두면
  /// 정확히 계산한 아이가 항상 가운데 값을 고르게 되어 어림 감각이 측정되지
  /// 않는다.
  ///
  /// 입력 [p]는 일반 [generate]/[generateOne]으로 만든 단일 연산 Problem이어야
  /// 한다(나눗셈 제외). compound는 어림셈 모드의 출제 범위에 포함되지 않는다.
  static EstimationChoices estimationChoicesFor(Problem p, int level) {
    final unit = _estimationUnit(level);
    final aR = _roundTo(p.operandA, unit);
    final bR = _roundTo(p.operandB, unit);
    int correct;
    switch (p.type) {
      case GameType.addition:
        correct = aR + bR;
      case GameType.subtraction:
        correct = aR - bR;
        if (correct < 0) correct = 0;
      case GameType.multiplication:
        correct = aR * bR;
      case GameType.division:
      case GameType.mixed:
      case GameType.equation:
      case GameType.flash:
      case GameType.estimation:
        // 어림셈은 +/−/× 셋에만 의미가 있다(÷는 출제기가 정수 몫만 만들어
        // 반올림할 거리가 없음). 호출자가 셀렉트 화면에서 이미 막아두지만,
        // 안전망으로 정답값은 반올림 단위에 맞춘 exact answer를 쓴다.
        correct = _roundTo(p.answer, unit);
    }
    final distractors = _estimationDistractors(correct, unit);
    final choices = <int>[correct, ...distractors]..shuffle(_random);
    return EstimationChoices(choices: choices, correct: correct);
  }

  /// 레벨별 반올림 단위. 한 자리 연산은 5의 배수로 가깝게, 백 단위가 의미
  /// 있어지는 L5(3+3자리)에서만 100으로 키운다.
  static int _estimationUnit(int level) {
    switch (level) {
      case 1:
        return 5;
      case 2:
      case 3:
      case 4:
        return 10;
      case 5:
        return 100;
      default:
        return 10;
    }
  }

  static int _roundTo(int n, int unit) {
    if (unit <= 1) return n;
    final sign = n < 0 ? -1 : 1;
    final abs = n.abs();
    return sign * ((abs + unit ~/ 2) ~/ unit) * unit;
  }

  /// correct 주변의 ±unit, ±2*unit 중 양수이고 correct와 겹치지 않는 후보들에서
  /// 2개를 골라 셔플한다. 후보가 부족하면(예: 정답이 작아 음수가 다수) 더 먼
  /// 양의 거리(±3*unit)로 확장.
  static List<int> _estimationDistractors(int correct, int unit) {
    final pool = <int>{};
    for (final k in const [1, -1, 2, -2, 3]) {
      final v = correct + k * unit;
      if (v >= 0 && v != correct) pool.add(v);
    }
    final list = pool.toList()..shuffle(_random);
    if (list.length < 2) {
      // 거의 발생하지 않는 경계 케이스(correct=0, unit=5): 5, 10을 보내자.
      return [correct + unit, correct + unit * 2];
    }
    return list.sublist(0, 2);
  }

  static (int, int) _digitsForLevel(int level) {
    switch (level) {
      case 1:
        return (1, 1);
      case 2:
        return (2, 1);
      case 3:
        return (2, 2);
      case 4:
        return (3, 2);
      case 5:
        return (3, 3);
      default:
        return (1, 1);
    }
  }

  static int _nDigit(int n) {
    if (n <= 1) return _random.nextInt(9) + 1;
    final low = _pow10(n - 1);
    final high = _pow10(n) - 1;
    return low + _random.nextInt(high - low + 1);
  }

  static int _pow10(int n) {
    var v = 1;
    for (var i = 0; i < n; i++) {
      v *= 10;
    }
    return v;
  }
}
