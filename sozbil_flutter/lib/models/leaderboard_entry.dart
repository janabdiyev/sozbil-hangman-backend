class LeaderboardEntry {
  final int rank;
  final String uuid;
  final String displayName;
  final String location;
  final String avatarKey;
  final String avatarEmoji;
  final int totalScore;
  final int gamesWon;
  final int streakDays;
  final String level;

  const LeaderboardEntry({
    required this.rank,
    required this.uuid,
    required this.displayName,
    required this.location,
    required this.avatarKey,
    required this.avatarEmoji,
    required this.totalScore,
    required this.gamesWon,
    required this.streakDays,
    required this.level,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) => LeaderboardEntry(
        rank: j['rank'] ?? 0,
        uuid: j['uuid'] ?? '',
        displayName: j['display_name'] ?? '',
        location: j['location'] ?? '',
        avatarKey: j['avatar_key'] ?? 'eagle',
        avatarEmoji: j['avatar_emoji'] ?? '🦅',
        totalScore: j['total_score'] ?? 0,
        gamesWon: j['games_won'] ?? 0,
        streakDays: j['streak_days'] ?? 0,
        level: j['level'] ?? 'Başlangyç',
      );
}
