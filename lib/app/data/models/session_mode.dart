/// How a single game session is run.
///
/// `challenge` is the canonical 10-problem / 180s race — the only mode that
/// contributes to "만점" and master-badge unlocks.
/// `timeAttack` is a 60s open-ended race where problems keep coming until the
/// timer runs out; correctCount is the score.
/// Practice runs aren't persisted, so they aren't a mode here — they're just
/// `isPractice == true` on a controller-only session.
enum SessionMode {
  challenge,
  timeAttack;

  static SessionMode fromName(String? name) {
    if (name == null) return SessionMode.challenge;
    for (final m in SessionMode.values) {
      if (m.name == name) return m;
    }
    return SessionMode.challenge;
  }
}
