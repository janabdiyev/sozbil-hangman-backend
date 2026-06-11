class WordModel {
  final int id;
  final String word;
  final String hint;
  final String difficulty;

  const WordModel({
    required this.id,
    required this.word,
    required this.hint,
    required this.difficulty,
  });

  factory WordModel.fromJson(Map<String, dynamic> j) => WordModel(
        id: j['id'] ?? 0,
        word: (j['word'] as String).toUpperCase(),
        hint: j['hint'] ?? '',
        difficulty: j['difficulty'] ?? 'medium',
      );
}
