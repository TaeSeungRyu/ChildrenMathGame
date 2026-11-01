import 'dart:math';

import '../data/models/game_type.dart';

class BilliardsValue implements Comparable<BilliardsValue> {
  const BilliardsValue(this.numerator, [this.denominator = 1]);

  final int numerator;
  final int denominator;

  BilliardsValue apply(GameType operation, int ball) => switch (operation) {
    GameType.addition => BilliardsValue(
      numerator + ball * denominator,
      denominator,
    ),
    GameType.subtraction => BilliardsValue(
      numerator - ball * denominator,
      denominator,
    ),
    GameType.multiplication => BilliardsValue(numerator * ball, denominator),
    GameType.division => BilliardsValue(numerator, denominator * ball),
    _ => throw ArgumentError.value(operation),
  };

  @override
  int compareTo(BilliardsValue other) =>
      (numerator * other.denominator).compareTo(other.numerator * denominator);

  String get label {
    if (numerator % denominator == 0) return '${numerator ~/ denominator}';
    return '${(numerator / denominator).toStringAsFixed(2)} ($numerator/$denominator)';
  }
}

class BilliardsBall {
  const BilliardsBall(this.id, this.number, this.x, this.y);
  final int id;
  final int number;
  final double x;
  final double y;
}

class BilliardsLayout {
  const BilliardsLayout(this.balls, this.starterIds);
  final List<BilliardsBall> balls;
  final Set<int> starterIds;
}

class BilliardsRules {
  static const radius = 0.038;
  static const _positions = <(double, double)>[
    (0.25, 0.75),
    (0.75, 0.75),
    (0.50, 0.50),
    (0.26, 0.25),
    (0.74, 0.25),
    (0.50, 0.12),
  ];

  static BilliardsLayout generate(
    GameType operation,
    int count, {
    Random? random,
  }) {
    if (count < 4 || count > 6) throw RangeError.range(count, 4, 6);
    if (!const [
      GameType.addition,
      GameType.subtraction,
      GameType.multiplication,
      GameType.division,
    ].contains(operation)) {
      throw ArgumentError.value(operation);
    }
    final rng = random ?? Random();
    final lowStart =
        operation == GameType.addition || operation == GameType.multiplication;
    final starter = lowStart
        ? 1 + rng.nextInt(3)
        : operation == GameType.subtraction
        ? 70 + rng.nextInt(30)
        : 60 + rng.nextInt(61);
    final values = <int>[starter, starter];
    for (var i = 2; i < count; i++) {
      values.add(
        operation == GameType.subtraction
            ? 2 + rng.nextInt(19)
            : operation == GameType.division
            ? 2 + rng.nextInt(8)
            : starter + 1 + rng.nextInt(9 - starter),
      );
    }
    return BilliardsLayout(
      [
        for (var i = 0; i < count; i++)
          BilliardsBall(i, values[i], _positions[i].$1, _positions[i].$2),
      ],
      {0, 1},
    );
  }

  static BilliardsValue result(
    GameType operation,
    int starter,
    Iterable<int> hits,
  ) {
    var value = BilliardsValue(starter);
    for (final hit in hits) {
      value = value.apply(operation, hit);
    }
    return value;
  }

  static String expression(
    GameType operation,
    int starter,
    Iterable<int> hits,
  ) {
    final values = hits.toList();
    return '$starter${values.map((n) => ' ${operation.symbol} $n').join()} = ${result(operation, starter, values).label}';
  }
}
