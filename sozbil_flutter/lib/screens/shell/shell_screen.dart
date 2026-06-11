import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/banner_ad_widget.dart';

class ShellScreen extends StatelessWidget {
  final Widget child;
  const ShellScreen({super.key, required this.child});

  static const _tabs = [
    _Tab(icon: Icons.grid_view_rounded, label: 'Oýunlar', path: '/home'),
    _Tab(icon: Icons.leaderboard_rounded, label: 'Reýting', path: '/leaderboard'),
    _Tab(icon: Icons.chat_bubble_rounded, label: 'Söhbet', path: '/chat'),
    _Tab(icon: Icons.person_rounded, label: 'Profil', path: '/profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final currentIndex = _tabs.indexWhere((t) => t.path == location).clamp(0, 3);

    return Scaffold(
      body: child,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Banner ad — self-checks subscription; hides automatically for paid users
          const BannerAdWidget(),

          // Bottom nav
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.borderLight)),
              color: AppColors.surface,
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 56,
                child: Row(
                  children: List.generate(_tabs.length, (i) {
                    final selected = i == currentIndex;
                    return Expanded(
                      child: InkWell(
                        onTap: () => context.go(_tabs[i].path),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _tabs[i].icon,
                              size: 22,
                              color: selected ? AppColors.primary : AppColors.textHint,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _tabs[i].label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                                color: selected ? AppColors.primary : AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab {
  final IconData icon;
  final String label;
  final String path;
  const _Tab({required this.icon, required this.label, required this.path});
}
