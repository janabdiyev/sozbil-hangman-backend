class AchievementModel {
  final int id;
  final String name;
  final String nameTk;
  final String descriptionTk;
  final String icon;
  final String conditionType;
  final int conditionValue;
  final int xpReward;

  const AchievementModel({
    required this.id,
    required this.name,
    required this.nameTk,
    required this.descriptionTk,
    required this.icon,
    required this.conditionType,
    required this.conditionValue,
    required this.xpReward,
  });

  factory AchievementModel.fromJson(Map<String, dynamic> j) => AchievementModel(
        id: j['id'] ?? 0,
        name: j['name'] ?? '',
        nameTk: j['name_tk'] ?? '',
        descriptionTk: j['description_tk'] ?? '',
        icon: j['icon'] ?? '🏆',
        conditionType: j['condition_type'] ?? '',
        conditionValue: j['condition_value'] ?? 0,
        xpReward: j['xp_reward'] ?? 0,
      );
}
