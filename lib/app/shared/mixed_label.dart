import '../data/models/game_record.dart';
import '../data/models/game_type.dart';

/// Returns the distinct operation types that appeared in [record]'s attempts,
/// sorted by enum order. Used to display "덧셈+뺄셈+곱셈 레벨 N" labels for
/// mixed-mode records. For non-mixed records returns just [record.type].
List<GameType> componentTypes(GameRecord record) {
  if (record.type != GameType.mixed) return [record.type];
  final set = <GameType>{for (final a in record.attempts) a.type};
  return set.toList()..sort((a, b) => a.index.compareTo(b.index));
}

/// "덧셈+뺄셈+곱셈" for a mixed record, or just "덧셈" for a single-op record.
String componentLabel(GameRecord record) {
  return componentTypes(record).map((t) => t.label).join('+');
}
