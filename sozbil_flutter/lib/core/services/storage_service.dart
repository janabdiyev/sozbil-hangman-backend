import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  static const _keyPlayerUuid = 'player_uuid';
  static const _keyOnboarded = 'onboarded';
  static const _keyDailyGamesPlayed = 'daily_games_played';
  static const _keyRewardGamesRemaining = 'reward_games_remaining';
  static const _keyRewardAdsWatched = 'reward_ads_watched';
  static const _keyLastPlayDate = 'last_play_date';
  static const _keyUsedWords = 'used_words';
  static const _keyIsSubscribed = 'is_subscribed';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Player UUID ──────────────────────────────────────────────────────────
  String getOrCreatePlayerUuid() {
    String? uuid = _prefs.getString(_keyPlayerUuid);
    if (uuid == null) {
      uuid = const Uuid().v4();
      _prefs.setString(_keyPlayerUuid, uuid);
    }
    return uuid;
  }

  String? get playerUuid => _prefs.getString(_keyPlayerUuid);

  // ── Onboarding ───────────────────────────────────────────────────────────
  bool get isOnboarded => _prefs.getBool(_keyOnboarded) ?? false;
  Future<void> setOnboarded() => _prefs.setBool(_keyOnboarded, true);

  // ── Game limits ──────────────────────────────────────────────────────────
  void _resetDailyIfNeeded() {
    final today = _todayString();
    final lastDate = _prefs.getString(_keyLastPlayDate) ?? '';
    if (lastDate != today) {
      _prefs.setInt(_keyDailyGamesPlayed, 0);
      _prefs.setInt(_keyRewardAdsWatched, 0);
      _prefs.setInt(_keyRewardGamesRemaining, 0);
      _prefs.setString(_keyLastPlayDate, today);
    }
  }

  int getDailyGamesPlayed() {
    _resetDailyIfNeeded();
    return _prefs.getInt(_keyDailyGamesPlayed) ?? 0;
  }

  int getRewardGamesRemaining() {
    _resetDailyIfNeeded();
    return _prefs.getInt(_keyRewardGamesRemaining) ?? 0;
  }

  int getRewardAdsWatched() {
    _resetDailyIfNeeded();
    return _prefs.getInt(_keyRewardAdsWatched) ?? 0;
  }

  int getRemainingGames(bool isSubscribed, int dailyLimit) {
    if (isSubscribed || kDebugMode) return 999999;
    _resetDailyIfNeeded();
    final played = _prefs.getInt(_keyDailyGamesPlayed) ?? 0;
    final reward = _prefs.getInt(_keyRewardGamesRemaining) ?? 0;
    return (dailyLimit - played).clamp(0, dailyLimit) + reward;
  }

  bool canPlay(bool isSubscribed, int dailyLimit) =>
      getRemainingGames(isSubscribed, dailyLimit) > 0;

  void consumeGame(bool isSubscribed) {
    if (isSubscribed) return;
    _resetDailyIfNeeded();
    final reward = _prefs.getInt(_keyRewardGamesRemaining) ?? 0;
    if (reward > 0) {
      _prefs.setInt(_keyRewardGamesRemaining, reward - 1);
    } else {
      final played = _prefs.getInt(_keyDailyGamesPlayed) ?? 0;
      _prefs.setInt(_keyDailyGamesPlayed, played + 1);
    }
  }

  void addRewardGames(int count, int gamesPerAd) {
    _resetDailyIfNeeded();
    final ads = _prefs.getInt(_keyRewardAdsWatched) ?? 0;
    final reward = _prefs.getInt(_keyRewardGamesRemaining) ?? 0;
    _prefs.setInt(_keyRewardAdsWatched, ads + 1);
    _prefs.setInt(_keyRewardGamesRemaining, reward + gamesPerAd);
  }

  // ── Used words (no-repeat) ───────────────────────────────────────────────
  Set<String> getUsedWords() =>
      (_prefs.getStringList(_keyUsedWords) ?? []).toSet();

  void addUsedWord(String word) {
    final used = getUsedWords();
    used.add(word.toLowerCase().trim());
    _prefs.setStringList(_keyUsedWords, used.toList());
  }

  void clearUsedWords() => _prefs.remove(_keyUsedWords);

  // ── Subscription ─────────────────────────────────────────────────────────
  bool get isSubscribed => _prefs.getBool(_keyIsSubscribed) ?? false;
  Future<void> setSubscribed(bool value) => _prefs.setBool(_keyIsSubscribed, value);

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }
}
