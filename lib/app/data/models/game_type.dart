enum GameType {
  addition('+', '덧셈'),
  subtraction('-', '뺄셈'),
  multiplication('×', '곱셈'),
  division('÷', '나눗셈'),
  // Mixed-operation session — each Problem inside still carries its own real
  // type; only the `GameRecord.type` rolls up to `mixed`. Symbol is only used
  // at the record-level UI (record tiles, stats card).
  mixed('혼', '혼합'),
  // Equation session — "A op ? = C" where one operand is hidden. Like `mixed`,
  // this is a record-level roll-up: every Problem keeps its concrete op type;
  // only the GameRecord rolls up to `equation`.
  equation('?', '방정식'),
  // Flash (암산 플래시) session — the problem is shown for a brief window
  // (e.g., 1.5s) then hidden; the player answers from memory. Roll-up: each
  // Problem keeps a concrete op type, only the GameRecord rolls up to `flash`.
  flash('⚡', '플래시'),
  // Estimation (어림셈) session — problem operands are rounded to a level-
  // appropriate place; the player picks the rounded answer from three choices
  // instead of typing it. Roll-up: each Problem keeps a concrete op type (+,
  // −, ×; ÷ is excluded since clean-integer division leaves nothing to round);
  // only the GameRecord rolls up to `estimation`.
  estimation('≈', '어림셈');

  const GameType(this.symbol, this.label);
  final String symbol;
  final String label;

  /// True when this value is a roll-up label (record-level only) rather than a
  /// concrete arithmetic operation that can drive problem generation.
  bool get isRollup =>
      this == mixed ||
      this == equation ||
      this == flash ||
      this == estimation;
}
