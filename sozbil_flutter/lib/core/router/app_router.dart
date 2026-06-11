import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/leaderboard/leaderboard_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/games/jellad/jellad_screen.dart';
import '../../screens/games/gunluk_soz/gunluk_soz_screen.dart';
import '../../screens/games/krosword/krosword_screen.dart';
import '../../screens/games/suysurme/suysurme_screen.dart';
import '../../screens/games/yatkeslik/yatkeslik_screen.dart';
import '../../screens/games/nanogram/nanogram_screen.dart';
import '../../screens/games/zehin/zehin_screen.dart';
import '../../screens/games/puzzle/puzzle_screen.dart';
import '../../screens/games/soz_zynjyry/soz_zynjyry_screen.dart';
import '../../screens/chat/chat_screen.dart';
import '../../screens/shell/shell_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final storage = ref.read(storageServiceProvider);

  return GoRouter(
    initialLocation: storage.isOnboarded ? '/home' : '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/leaderboard', builder: (_, __) => const LeaderboardScreen()),
          GoRoute(path: '/chat', builder: (_, __) => const ChatScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),
      GoRoute(path: '/game/jellad', builder: (_, __) => const JelladScreen()),
      GoRoute(path: '/game/gunluk-soz', builder: (_, __) => const GunlukSozScreen()),
      GoRoute(path: '/game/krosword', builder: (_, __) => const KroswordScreen()),
      GoRoute(path: '/game/suysurme', builder: (_, __) => const SuysurmeScreen()),
      GoRoute(path: '/game/yatkeslik', builder: (_, __) => const YatkeslikScreen()),
      GoRoute(path: '/game/nanogram', builder: (_, __) => const NanogramScreen()),
      GoRoute(path: '/game/zehin', builder: (_, __) => const ZehinScreen()),
      GoRoute(path: '/game/puzzle', builder: (_, __) => const PuzzleScreen()),
      GoRoute(path: '/game/soz-zynjyry', builder: (_, __) => const SozZynjyryScreen()),
    ],
  );
});
