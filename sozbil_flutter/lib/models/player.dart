class PlayerModel {
  final String uuid;
  final String displayName;
  final String location;
  final String avatarKey;
  final String avatarEmoji;
  final int xp;
  final String level;
  final String levelDisplay;
  final int streakDays;
  final int longestStreak;
  final String? lastActive;
  final String? createdAt;
  final List<PlayerAchievementModel> achievements;

  const PlayerModel({
    required this.uuid,
    required this.displayName,
    required this.location,
    required this.avatarKey,
    required this.avatarEmoji,
    required this.xp,
    required this.level,
    required this.levelDisplay,
    required this.streakDays,
    required this.longestStreak,
    this.lastActive,
    this.createdAt,
    this.achievements = const [],
  });

  factory PlayerModel.fromJson(Map<String, dynamic> j) => PlayerModel(
        uuid: j['uuid'] ?? '',
        displayName: j['display_name'] ?? '',
        location: j['location'] ?? '',
        avatarKey: j['avatar_key'] ?? 'eagle',
        avatarEmoji: j['avatar_emoji'] ?? '🦅',
        xp: j['xp'] ?? 0,
        level: j['level'] ?? 'baslangyc',
        levelDisplay: j['level_display'] ?? 'Başlangyç',
        streakDays: j['streak_days'] ?? 0,
        longestStreak: j['longest_streak'] ?? 0,
        lastActive: j['last_active'],
        createdAt: j['created_at'],
        achievements: (j['achievements'] as List? ?? [])
            .map((e) => PlayerAchievementModel.fromJson(e))
            .toList(),
      );

  PlayerModel copyWith({
    String? displayName,
    String? location,
    String? avatarKey,
    String? avatarEmoji,
    int? xp,
    String? level,
    String? levelDisplay,
    int? streakDays,
    int? longestStreak,
  }) =>
      PlayerModel(
        uuid: uuid,
        displayName: displayName ?? this.displayName,
        location: location ?? this.location,
        avatarKey: avatarKey ?? this.avatarKey,
        avatarEmoji: avatarEmoji ?? this.avatarEmoji,
        xp: xp ?? this.xp,
        level: level ?? this.level,
        levelDisplay: levelDisplay ?? this.levelDisplay,
        streakDays: streakDays ?? this.streakDays,
        longestStreak: longestStreak ?? this.longestStreak,
        lastActive: lastActive,
        createdAt: createdAt,
        achievements: achievements,
      );
}

class PlayerAchievementModel {
  final String name;
  final String nameTk;
  final String descriptionTk;
  final String icon;
  final int xpReward;
  final String earnedAt;

  const PlayerAchievementModel({
    required this.name,
    required this.nameTk,
    required this.descriptionTk,
    required this.icon,
    required this.xpReward,
    required this.earnedAt,
  });

  factory PlayerAchievementModel.fromJson(Map<String, dynamic> j) {
    final ach = j['achievement'] as Map<String, dynamic>? ?? {};
    return PlayerAchievementModel(
      name: ach['name'] ?? '',
      nameTk: ach['name_tk'] ?? '',
      descriptionTk: ach['description_tk'] ?? '',
      icon: ach['icon'] ?? '🏆',
      xpReward: ach['xp_reward'] ?? 0,
      earnedAt: j['earned_at'] ?? '',
    );
  }
}

const Map<String, String> avatarEmojis = {
  'eagle': '🦅',
  'wolf': '🐺',
  'lion': '🦁',
  'horse': '🐎',
  'fox': '🦊',
  'owl': '🦉',
  'bear': '🐻',
  'tiger': '🐯',
  'dragon': '🐉',
  'star': '⭐',
};
