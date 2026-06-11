import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../../models/word.dart';
import '../../models/player.dart';
import '../../models/leaderboard_entry.dart';
import '../../models/external_app.dart';
import '../../models/puzzle_image.dart';
import '../../models/achievement.dart';
import '../../models/chat_message.dart';

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: false,
      error: true,
    ));
  }

  // ── Words ─────────────────────────────────────────────────────────────────
  Future<WordModel> getRandomWord() async {
    final res = await _dio.get(ApiConstants.word);
    return WordModel.fromJson(res.data);
  }

  Future<List<WordModel>> getAllWords() async {
    final res = await _dio.get(ApiConstants.allWords);
    return (res.data as List).map((e) => WordModel.fromJson(e)).toList();
  }

  Future<DailyWordResponse> getDailyWord() async {
    final res = await _dio.get(ApiConstants.dailyWord);
    return DailyWordResponse.fromJson(res.data);
  }

  // ── Player ────────────────────────────────────────────────────────────────
  Future<PlayerModel> registerPlayer({
    required String uuid,
    required String displayName,
    required String location,
    required String avatarKey,
  }) async {
    final res = await _dio.post(ApiConstants.playerRegister, data: {
      'uuid': uuid,
      'display_name': displayName,
      'location': location,
      'avatar_key': avatarKey,
    });
    return PlayerModel.fromJson(res.data);
  }

  Future<PlayerModel> getPlayer(String uuid) async {
    final res = await _dio.get(ApiConstants.playerDetail(uuid));
    return PlayerModel.fromJson(res.data);
  }

  Future<PlayerModel> updatePlayer(
    String uuid, {
    String? displayName,
    String? location,
    String? avatarKey,
  }) async {
    final data = <String, dynamic>{};
    if (displayName != null) data['display_name'] = displayName;
    if (location != null) data['location'] = location;
    if (avatarKey != null) data['avatar_key'] = avatarKey;
    final res = await _dio.put(ApiConstants.playerDetail(uuid), data: data);
    return PlayerModel.fromJson(res.data);
  }

  // ── Score ─────────────────────────────────────────────────────────────────
  Future<ScoreResponse> submitScore({
    required String playerUuid,
    required String gameType,
    int? wordId,
    required bool won,
    required int wrongGuesses,
  }) async {
    final res = await _dio.post(ApiConstants.submitScore, data: {
      'player_uuid': playerUuid,
      'game_type': gameType,
      if (wordId != null) 'word_id': wordId,
      'won': won,
      'wrong_guesses': wrongGuesses,
    });
    return ScoreResponse.fromJson(res.data);
  }

  // ── Leaderboard ───────────────────────────────────────────────────────────
  Future<List<LeaderboardEntry>> getLeaderboard({
    String filter = 'alltime',
    String? location,
  }) async {
    final params = <String, dynamic>{'filter': filter};
    if (location != null && location.isNotEmpty) params['location'] = location;
    final res = await _dio.get(ApiConstants.leaderboard, queryParameters: params);
    return (res.data as List).map((e) => LeaderboardEntry.fromJson(e)).toList();
  }

  // ── Content ───────────────────────────────────────────────────────────────
  Future<List<PuzzleImageModel>> getPuzzleImages(String gameType) async {
    final res = await _dio.get(ApiConstants.puzzleImages(gameType));
    return (res.data as List).map((e) => PuzzleImageModel.fromJson(e)).toList();
  }

  Future<List<ExternalAppModel>> getExternalApps() async {
    final res = await _dio.get(ApiConstants.externalApps);
    return (res.data as List).map((e) => ExternalAppModel.fromJson(e)).toList();
  }

  Future<List<AchievementModel>> getAchievements() async {
    final res = await _dio.get(ApiConstants.achievements);
    return (res.data as List).map((e) => AchievementModel.fromJson(e)).toList();
  }

  // ── Chat ──────────────────────────────────────────────────────────────────
  Future<List<ChatMessageModel>> getChatMessages({int? beforeId}) async {
    final params = <String, dynamic>{};
    if (beforeId != null) params['before_id'] = beforeId;
    final res = await _dio.get(ApiConstants.chat, queryParameters: params);
    return (res.data as List).map((e) => ChatMessageModel.fromJson(e)).toList();
  }

  Future<ChatMessageModel> sendChatMessage({
    required String playerUuid,
    required String message,
  }) async {
    final res = await _dio.post(ApiConstants.chat, data: {
      'player_uuid': playerUuid,
      'message': message,
    });
    return ChatMessageModel.fromJson(res.data);
  }
}

// ── Response models ────────────────────────────────────────────────────────

class DailyWordResponse {
  final String date;
  final WordModel word;
  DailyWordResponse({required this.date, required this.word});
  factory DailyWordResponse.fromJson(Map<String, dynamic> j) =>
      DailyWordResponse(date: j['date'], word: WordModel.fromJson(j['word']));
}

class ScoreResponse {
  final int score;
  final int xpGained;
  final int totalXp;
  final String level;
  final int streakDays;
  ScoreResponse({
    required this.score,
    required this.xpGained,
    required this.totalXp,
    required this.level,
    required this.streakDays,
  });
  factory ScoreResponse.fromJson(Map<String, dynamic> j) => ScoreResponse(
        score: j['score'],
        xpGained: j['xp_gained'],
        totalXp: j['total_xp'],
        level: j['level'],
        streakDays: j['streak_days'],
      );
}
