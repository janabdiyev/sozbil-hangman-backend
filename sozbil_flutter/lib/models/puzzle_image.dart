class PuzzleImageModel {
  final int id;
  final String title;
  final String? imageUrl;
  final String gameType;
  final String difficulty;

  const PuzzleImageModel({
    required this.id,
    required this.title,
    this.imageUrl,
    required this.gameType,
    required this.difficulty,
  });

  factory PuzzleImageModel.fromJson(Map<String, dynamic> j) => PuzzleImageModel(
        id: j['id'] ?? 0,
        title: j['title'] ?? '',
        imageUrl: j['image_url'],
        gameType: j['game_type'] ?? '',
        difficulty: j['difficulty'] ?? 'medium',
      );
}
