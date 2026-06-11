class ChatMessageModel {
  final int id;
  final String displayName;
  final String avatarKey;
  final String avatarEmoji;
  final String message;
  final DateTime createdAt;

  const ChatMessageModel({
    required this.id,
    required this.displayName,
    required this.avatarKey,
    required this.avatarEmoji,
    required this.message,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> j) => ChatMessageModel(
        id: j['id'],
        displayName: j['display_name'] ?? '',
        avatarKey: j['avatar_key'] ?? 'eagle',
        avatarEmoji: j['avatar_emoji'] ?? '🦅',
        message: j['message'] ?? '',
        createdAt: DateTime.parse(j['created_at']).toLocal(),
      );
}
