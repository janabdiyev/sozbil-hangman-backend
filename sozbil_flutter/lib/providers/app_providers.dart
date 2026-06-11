import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_service.dart';
import '../core/services/storage_service.dart';
import '../core/constants/api_constants.dart';
import '../models/player.dart';
import '../models/leaderboard_entry.dart';
import '../models/word.dart';
import '../models/external_app.dart';

// ── Services ──────────────────────────────────────────────────────────────────

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('Override in main with initialized StorageService');
});

// ── Player ────────────────────────────────────────────────────────────────────

class PlayerNotifier extends StateNotifier<AsyncValue<PlayerModel?>> {
  final ApiService _api;
  final StorageService _storage;

  PlayerNotifier(this._api, this._storage) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    final uuid = _storage.playerUuid;
    if (uuid == null) {
      state = const AsyncValue.data(null);
      return;
    }
    try {
      final player = await _api.getPlayer(uuid);
      state = AsyncValue.data(player);
    } catch (_) {
      state = const AsyncValue.data(null);
    }
  }

  Future<PlayerModel> register({
    required String displayName,
    required String location,
    required String avatarKey,
  }) async {
    final uuid = _storage.getOrCreatePlayerUuid();
    final player = await _api.registerPlayer(
      uuid: uuid,
      displayName: displayName,
      location: location,
      avatarKey: avatarKey,
    );
    await _storage.setOnboarded();
    state = AsyncValue.data(player);
    return player;
  }

  Future<void> update({String? displayName, String? location, String? avatarKey}) async {
    final uuid = _storage.playerUuid;
    if (uuid == null) return;
    final player = await _api.updatePlayer(uuid,
        displayName: displayName, location: location, avatarKey: avatarKey);
    state = AsyncValue.data(player);
  }

  Future<void> refresh() => _load();
}

final playerProvider =
    StateNotifierProvider<PlayerNotifier, AsyncValue<PlayerModel?>>((ref) {
  return PlayerNotifier(
    ref.read(apiServiceProvider),
    ref.read(storageServiceProvider),
  );
});

// ── Game limits ───────────────────────────────────────────────────────────────

class GameLimitNotifier extends StateNotifier<int> {
  final StorageService _storage;
  final bool _isSubscribed;

  GameLimitNotifier(this._storage, this._isSubscribed)
      : super(_storage.getRemainingGames(_isSubscribed, ApiConstants.dailyFreeGames));

  void refresh() {
    state = _storage.getRemainingGames(_isSubscribed, ApiConstants.dailyFreeGames);
  }

  bool get canPlay => state > 0;

  void consume() {
    _storage.consumeGame(_isSubscribed);
    refresh();
  }

  void addRewardGames() {
    _storage.addRewardGames(ApiConstants.gamesPerAd, ApiConstants.gamesPerAd);
    refresh();
  }
}

final gameLimitProvider = StateNotifierProvider<GameLimitNotifier, int>((ref) {
  final storage = ref.read(storageServiceProvider);
  return GameLimitNotifier(storage, storage.isSubscribed);
});

// ── Leaderboard ───────────────────────────────────────────────────────────────

final leaderboardProvider =
    FutureProvider.family<List<LeaderboardEntry>, String>((ref, filter) async {
  return ref.read(apiServiceProvider).getLeaderboard(filter: filter);
});

// ── Daily word ────────────────────────────────────────────────────────────────

final dailyWordProvider = FutureProvider<WordModel?>((ref) async {
  try {
    final res = await ref.read(apiServiceProvider).getDailyWord();
    return res.word;
  } catch (_) {
    return null;
  }
});

// ── All words (for word-based games) ─────────────────────────────────────────

final allWordsProvider = FutureProvider<List<WordModel>>((ref) async {
  try {
    return ref.read(apiServiceProvider).getAllWords();
  } catch (_) {
    return [];
  }
});

// ── External apps ─────────────────────────────────────────────────────────────

final externalAppsProvider = FutureProvider<List<ExternalAppModel>>((ref) async {
  try {
    return ref.read(apiServiceProvider).getExternalApps();
  } catch (_) {
    return [];
  }
});
