import '../data/models/game_record.dart';
import '../data/models/game_type.dart';

/// Returns the distinct operation types that appeared in [record]'s attempts,
/// sorted by enum order. Used to display "덧셈+뺄셈+곱셈 레벨 N" labels for
/// roll-up records (혼합/방정식). For single-op records returns just
/// [record.type].
List<GameType> componentTypes(GameRecord record) {
  if (!record.type.isRollup) return [record.type];
  final set = <GameType>{for (final a in record.attempts) a.type};
  return set.toList()..sort((a, b) => a.index.compareTo(b.index));
}

/// "덧셈+뺄셈+곱셈" for a roll-up record, or just "덧셈" for a single-op record.
/// Equation records always yield a single label (one underlying op).
String componentLabel(GameRecord record) {
  return componentTypes(record).map((t) => t.label).join('+');
}
