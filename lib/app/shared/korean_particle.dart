/// Returns the Korean vocative particle for [name]: "야" if the last syllable
/// has no jongseong (받침), "아" if it does. Returns empty string for empty
/// names or names whose last character isn't a Hangul syllable (e.g. English
/// names) — leave them unaddressed rather than guessing.
String vocativeParticle(String name) {
  if (name.isEmpty) return '';
  final last = name.codeUnitAt(name.length - 1);
  // Hangul syllable block: AC00 (가) .. D7A3 (힣).
  if (last < 0xAC00 || last > 0xD7A3) return '';
  // Each syllable encodes (initial * 21 + medial) * 28 + final. `% 28 == 0`
  // means no final consonant, which takes "야"; otherwise "아".
  return (last - 0xAC00) % 28 == 0 ? '야' : '아';
}

/// "연수야" / "민준아" — the name with the right vocative attached.
String addressedName(String name) {
  return '$name${vocativeParticle(name)}';
}
