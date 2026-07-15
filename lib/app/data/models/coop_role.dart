/// Who this device is in a "부모와 함께하는 학습" session. Chosen once, right
/// after the two devices connect. Independent of who hosted vs joined.
enum CoopRole {
  /// The child solves problems; their screen streams to the parent.
  child('아이'),

  /// The parent observes/coaches: sees the child's screen, adjusts difficulty,
  /// sends emoji reactions.
  parent('부모');

  const CoopRole(this.label);
  final String label;
}
