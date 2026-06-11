import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/app_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _games = [
    _GameInfo('jellad', AppStrings.jellad, '🪢', '/game/jellad', true),
    _GameInfo('gunluk_soz', AppStrings.gunlukSoz, '📅', '/game/gunluk-soz', true),
    _GameInfo('soz_zynjyry', AppStrings.sozZynjyry, '🔗', '/game/soz-zynjyry', true),
    _GameInfo('yatkeslik', AppStrings.yatkeslik, '🃏', '/game/yatkeslik', true),
    _GameInfo('krosword', AppStrings.krosword, '🔠', '/game/krosword', true),
    _GameInfo('suysurme', AppStrings.suysurme, '🧩', '/game/suysurme', true),
    _GameInfo('nanogram', AppStrings.nanogram, '🖼️', '/game/nanogram', true),
    _GameInfo('zehin', AppStrings.zehinOyunlary, '🧠', '/game/zehin', true),
    _GameInfo('puzzle', AppStrings.puzzle, '🎭', '/game/puzzle', true),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerAsync = ref.watch(playerProvider);
    final storage = ref.read(storageServiceProvider);
    final isSubscribed = storage.isSubscribed;
    final externalAppsAsync = ref.watch(externalAppsProvider);
    final isTablet = MediaQuery.of(context).size.width > 600;
    final crossCount = isTablet ? 4 : 3;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: playerAsync.when(
                        data: (p) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p != null ? 'Salam, ${p.displayName.split(' ').first}' : AppStrings.appName,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.8,
                                height: 1.1,
                              ),
                            ),
                            if (isSubscribed) ...[
                              const SizedBox(height: 2),
                              const Text(
                                'Premium • Çäksiz oýun',
                                style: TextStyle(fontSize: 13, color: AppColors.success, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ],
                        ),
                        loading: () => const Text(AppStrings.appName,
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                        error: (_, __) => const Text(AppStrings.appName,
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                      ),
                    ),
                    // streak badge
                    playerAsync.when(
                      data: (p) {
                        if (p == null || p.streakDays == 0) return const SizedBox.shrink();
                        return _StreakBadge(days: p.streakDays);
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ── Games grid ──────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _GameCard(game: _games[i]),
                  childCount: _games.length,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossCount,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.88,
                ),
              ),
            ),

            // ── Partner apps ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: externalAppsAsync.when(
                data: (apps) {
                  if (apps.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 12),
                          child: Text(
                            'HYZMATDAŞLAR',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textHint,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        Row(
                          children: apps.map((app) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: _ExternalAppCard(app: app),
                            ),
                          )).toList(),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

// ── Streak badge ───────────────────────────────────────────────────────────────

class _StreakBadge extends StatelessWidget {
  final int days;
  const _StreakBadge({required this.days});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0E8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text(
            '$days',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.streak,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Game card ──────────────────────────────────────────────────────────────────

class _GameCard extends StatefulWidget {
  final _GameInfo game;
  const _GameCard({required this.game});

  @override
  State<_GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<_GameCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.game.isActive;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        context.push(widget.game.route);
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            color: isActive ? AppColors.surface : AppColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(18),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.game.emoji,
                  style: TextStyle(fontSize: isActive ? 36 : 28),
                ),
                const Spacer(),
                Text(
                  widget.game.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!isActive) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Ýakynda',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── External app card ──────────────────────────────────────────────────────────

class _ExternalAppCard extends StatelessWidget {
  final dynamic app;
  const _ExternalAppCard({required this.app});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final isIos = Theme.of(context).platform == TargetPlatform.iOS;
        final url = isIos ? app.iosUrl : app.androidUrl;
        if (url.isNotEmpty) launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            if (app.logoUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(app.logoUrl!, width: 36, height: 36, fit: BoxFit.cover),
              )
            else
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.apps, color: Colors.white, size: 20),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(app.name,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  if (app.description.isNotEmpty)
                    Text(app.description,
                        style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 11, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

class _GameInfo {
  final String key;
  final String name;
  final String emoji;
  final String route;
  final bool isActive;
  const _GameInfo(this.key, this.name, this.emoji, this.route, this.isActive);
}
