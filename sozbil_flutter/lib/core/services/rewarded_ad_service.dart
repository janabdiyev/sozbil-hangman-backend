import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../constants/api_constants.dart';

/// Loads and shows a single rewarded ad.
/// Call [load] once (e.g. on game screen init), then [show] when needed.
class RewardedAdService {
  RewardedAd? _ad;
  bool _loading = false;

  String get _adUnitId {
    if (kDebugMode) return ApiConstants.testRewardedId;
    if (Platform.isIOS) return ApiConstants.rewardedAdUnitIdIos;
    return ApiConstants.rewardedAdUnitIdAndroid;
  }

  bool get isReady => _ad != null;

  void load() {
    if (_loading || _ad != null) return;
    _loading = true;
    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loading = false;
        },
        onAdFailedToLoad: (_) {
          _loading = false;
        },
      ),
    );
  }

  /// Shows the ad. Calls [onRewarded] if the user earns the reward.
  /// Calls [onFailed] if the ad isn't ready.
  void show({
    required void Function() onRewarded,
    required void Function() onFailed,
  }) {
    if (_ad == null) {
      onFailed();
      return;
    }

    _ad!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _ad = null;
        load(); // preload next ad
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _ad = null;
        onFailed();
        load();
      },
    );

    _ad!.show(
      onUserEarnedReward: (_, __) => onRewarded(),
    );
  }

  void dispose() {
    _ad?.dispose();
    _ad = null;
  }
}
