import 'stamp_condition.dart';

/// A user-created stamp on the 도장판 — alongside the built-in achievement
/// badges. Two modes:
///   - **manual** ([condition] is `null`): user toggles [earned] by tapping
///   - **auto** ([condition] is set): earned state is derived from records;
///     stored [earned] is ignored
class CustomStamp {
  const CustomStamp({
    required this.id,
    required this.title,
    required this.emoji,
    required this.colorValue,
    required this.earned,
    required this.createdAt,
    this.condition,
  });

  factory CustomStamp.fromJson(Map<String, dynamic> json) => CustomStamp(
    id: json['id'] as String,
    title: json['title'] as String,
    emoji: json['emoji'] as String,
    colorValue: json['colorValue'] as int,
    earned: json['earned'] as bool,
    createdAt: DateTime.parse(json['createdAt'] as String),
    // Back-compat: stamps saved before conditions existed have no key.
    condition: json['condition'] == null
        ? null
        : StampCondition.fromJson(
            json['condition'] as Map<String, dynamic>,
          ),
  );

  final String id;
  final String title;
  final String emoji;
  final int colorValue;
  // For auto stamps this field is ignored at display time — the BadgesController
  // re-derives earnedness from records on each rebuild. It's still persisted
  // so that toggling a stamp's condition off later preserves a sensible value.
  final bool earned;
  final DateTime createdAt;
  final StampCondition? condition;

  bool get isAuto => condition != null;

  CustomStamp copyWith({
    String? title,
    String? emoji,
    int? colorValue,
    bool? earned,
    // Sentinel pattern lets callers explicitly set `condition: null` to clear.
    Object? condition = _sentinel,
  }) {
    return CustomStamp(
      id: id,
      title: title ?? this.title,
      emoji: emoji ?? this.emoji,
      colorValue: colorValue ?? this.colorValue,
      earned: earned ?? this.earned,
      createdAt: createdAt,
      condition: identical(condition, _sentinel)
          ? this.condition
          : condition as StampCondition?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'emoji': emoji,
    'colorValue': colorValue,
    'earned': earned,
    'createdAt': createdAt.toIso8601String(),
    if (condition != null) 'condition': condition!.toJson(),
  };
}

const Object _sentinel = Object();
