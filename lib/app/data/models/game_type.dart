enum GameType {
  addition('+', '덧셈'),
  subtraction('-', '뺄셈'),
  multiplication('×', '곱셈'),
  division('÷', '나눗셈'),
  // Mixed-operation session — each Problem inside still carries its own real
  // type; only the `GameRecord.type` rolls up to `mixed`. Symbol is only used
  // at the record-level UI (record tiles, stats card).
  mixed('혼', '혼합');

  const GameType(this.symbol, this.label);
  final String symbol;
  final String label;
}
