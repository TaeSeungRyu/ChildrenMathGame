enum GameType {
  addition('+', '덧셈'),
  subtraction('-', '뺄셈'),
  multiplication('×', '곱셈'),
  division('÷', '나눗셈');

  const GameType(this.symbol, this.label);
  final String symbol;
  final String label;
}
