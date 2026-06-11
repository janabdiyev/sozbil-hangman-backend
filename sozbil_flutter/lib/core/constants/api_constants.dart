class ApiConstants {
  ApiConstants._();

  static const baseUrl = 'https://sozbil-hangman-backend.onrender.com';

  static const word = '/api/word/';
  static const allWords = '/api/words/';
  static const dailyWord = '/api/daily/';
  static const playerRegister = '/api/player/register/';
  static String playerDetail(String uuid) => '/api/player/$uuid/';
  static const submitScore = '/api/score/';
  static const leaderboard = '/api/leaderboard/';
  static String puzzleImages(String gameType) => '/api/puzzles/$gameType/';
  static const externalApps = '/api/apps/';
  static const achievements = '/api/achievements/';
  static const chat = '/api/chat/';
  static const health = '/health/';

  // AdMob IDs
  static const bannerAdUnitIdAndroid = 'ca-app-pub-7668467791782601/XXXXXXXX';
  static const rewardedAdUnitIdAndroid = 'ca-app-pub-7668467791782601/5377390036';
  static const bannerAdUnitIdIos = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const rewardedAdUnitIdIos = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';

  // Test IDs (use during development)
  static const testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const testRewardedId = 'ca-app-pub-3940256099942544/5224354917';

  // In-App Purchase IDs
  static const monthlySubId = 'sozbil_premium_monthly';
  static const yearlySubId = 'sozbil_premium_yearly';

  // Game limits
  static const dailyFreeGames = 20;
  static const gamesPerAd = 10;
}
