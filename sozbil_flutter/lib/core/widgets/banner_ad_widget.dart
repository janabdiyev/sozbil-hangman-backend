import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../constants/api_constants.dart';
import '../constants/app_colors.dart';
import '../../providers/app_providers.dart';

/// Displays a standard banner ad (320×50).
/// Returns SizedBox.shrink() for subscribers, or when the ad hasn't loaded yet.
class BannerAdWidget extends ConsumerStatefulWidget {
  const BannerAdWidget({super.key});

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  BannerAd? _ad;
  bool _loaded = false;

  String get _adUnitId {
    if (kDebugMode) return ApiConstants.testBannerId;
    if (Platform.isIOS) return ApiConstants.bannerAdUnitIdIos;
    return ApiConstants.bannerAdUnitIdAndroid;
  }

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _ad = BannerAd(
      adUnitId: _adUnitId,
      size: AdSize.banner, // 320×50
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _loaded = true),
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          _ad = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Never show ads for subscribers
    if (ref.read(storageServiceProvider).isSubscribed) return const SizedBox.shrink();
    if (!_loaded || _ad == null) return const SizedBox.shrink();

    return Container(
      color: AppColors.surface,
      width: double.infinity,
      height: _ad!.size.height.toDouble(),
      alignment: Alignment.center,
      child: AdWidget(ad: _ad!),
    );
  }
}
