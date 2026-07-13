/// A single child profile. Multiple profiles let siblings share one device
/// while keeping their records, stamps and stats separate.
///
/// [id] is a stable integer. The very first (migrated) profile always has
/// id == [Profile.primaryId]; its per-profile data lives under the original,
/// un-suffixed SharedPreferences keys so existing single-user installs need
/// no data migration. Additional profiles namespace their keys with the id.
class Profile {
  const Profile({
    required this.id,
    required this.name,
    required this.avatar,
  });

  /// The first profile's id. Never deleted so its legacy (un-suffixed) data
  /// stays reachable.
  static const int primaryId = 1;

  final int id;
  final String name;

  /// An emoji chosen from [Profile.avatarChoices].
  final String avatar;

  /// SharedPreferences key suffix for this profile's scoped data. The primary
  /// profile uses an empty suffix so pre-existing keys keep working.
  String get scopeSuffix => id == primaryId ? '' : '_p$id';

  static const String defaultAvatar = '🦸';

  /// Kid-friendly emoji pool for the avatar picker.
  static const List<String> avatarChoices = [
    '🦸', '🦖', '🐱', '🐶', '🦄', '🐼',
    '🦊', '🐵', '🐯', '🐸', '🐧', '🚀',
  ];

  Profile copyWith({String? name, String? avatar}) => Profile(
        id: id,
        name: name ?? this.name,
        avatar: avatar ?? this.avatar,
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'avatar': avatar};

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as int,
        name: json['name'] as String,
        avatar: (json['avatar'] as String?) ?? defaultAvatar,
      );
}
