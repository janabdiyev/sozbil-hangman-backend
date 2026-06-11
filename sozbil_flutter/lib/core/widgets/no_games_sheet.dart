import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/api_constants.dart';
import '../services/rewarded_ad_service.dart';
import '../services/storage_service.dart';

/// Shows a bottom sheet when the daily limit is hit.
/// Offers a rewarded ad for +10 credits.
/// Call [showNoGamesSheet] from any game screen.
Future<bool> showNoGamesSheet(
  BuildContext context, {
  required RewardedAdService adService,
  required StorageService storage,
  required void Function() onCreditsAdded,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    builder: (_) => _NoGamesSheet(
      adService: adService,
      storage: storage,
      onCreditsAdded: onCreditsAdded,
    ),
  );
  return result ?? false;
}

class _NoGamesSheet extends StatefulWidget {
  final RewardedAdService adService;
  final StorageService storage;
  final VoidCallback onCreditsAdded;

  const _NoGamesSheet({
    required this.adService,
    required this.storage,
    required this.onCreditsAdded,
  });

  @override
  State<_NoGamesSheet> createState() => _NoGamesSheetState();
}

class _NoGamesSheetState extends State<_NoGamesSheet> {
  bool _loading = false;

  void _watchAd() {
    setState(() => _loading = true);

    widget.adService.show(
      onRewarded: () {
        widget.storage.addRewardGames(
          ApiConstants.gamesPerAd,
          ApiConstants.gamesPerAd,
        );
        widget.onCreditsAdded();
        if (mounted) Navigator.pop(context, true);
      },
      onFailed: () {
        setState(() => _loading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reklama häzir ýok. Biraz soň synanyş.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, bottomPad + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          const Text('🎬', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 16),

          const Text(
            'Günlük oýun haky gutardy',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          Text(
            'Gysga reklama görüp +${ApiConstants.gamesPerAd} oýun al.\nErtir täzeden ${ApiConstants.dailyFreeGames} oýun berilýär.',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _watchAd,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Reklama gör',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
          const SizedBox(height: 12),

          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Yza',
              style: TextStyle(fontSize: 14, color: AppColors.textHint),
            ),
          ),
        ],
      ),
    );
  }
}
