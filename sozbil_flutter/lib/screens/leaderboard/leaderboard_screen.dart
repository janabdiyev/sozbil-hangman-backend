import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/leaderboard_entry.dart';
import '../../providers/app_providers.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  String _filter = 'alltime';

  @override
  Widget build(BuildContext context) {
    final leaderboardAsync = ref.watch(leaderboardProvider(_filter));
    final currentUuid = ref.read(storageServiceProvider).playerUuid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reýting'),
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                _FilterChip(label: 'Hemişelik', value: 'alltime', current: _filter,
                    onTap: (v) => setState(() => _filter = v)),
                const SizedBox(width: 8),
                _FilterChip(label: 'Bu hepde', value: 'weekly', current: _filter,
                    onTap: (v) => setState(() => _filter = v)),
              ],
            ),
          ),
        ),
      ),
      body: leaderboardAsync.when(
        data: (entries) => entries.isEmpty
            ? const _EmptyState()
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: entries.length,
                itemBuilder: (context, i) => _LeaderboardRow(
                  entry: entries[i],
                  isCurrentUser: entries[i].uuid == currentUuid,
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('😕', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 8),
              const Text('Ýüklenip bilmedi', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.refresh(leaderboardProvider(_filter)),
                child: const Text('Gaýtadan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isCurrentUser;
  const _LeaderboardRow({required this.entry, required this.isCurrentUser});

  @override
  Widget build(BuildContext context) {
    String rankLabel;
    Color rankColor = AppColors.textHint;
    if (entry.rank == 1) { rankLabel = '🥇'; }
    else if (entry.rank == 2) { rankLabel = '🥈'; }
    else if (entry.rank == 3) { rankLabel = '🥉'; }
    else { rankLabel = '${entry.rank}'; }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrentUser ? AppColors.primaryLight : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrentUser ? AppColors.primary.withOpacity(0.4) : AppColors.borderLight,
          width: isCurrentUser ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(rankLabel, style: TextStyle(fontSize: entry.rank <= 3 ? 20 : 14,
                fontWeight: FontWeight.w700, color: rankColor), textAlign: TextAlign.center),
          ),
          const SizedBox(width: 10),
          Text(entry.avatarEmoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(entry.displayName,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
                        child: const Text('Sen', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
                if (entry.location.isNotEmpty)
                  Text(entry.location, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${entry.totalScore}', style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary)),
              Text('${entry.gamesWon} ýeňiş', style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
            ],
          ),
          if (entry.streakDays > 0) ...[
            const SizedBox(width: 8),
            Column(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 14)),
                Text('${entry.streakDays}', style: const TextStyle(fontSize: 9, color: AppColors.textHint)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final void Function(String) onTap;
  const _FilterChip({required this.label, required this.value, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final selected = value == current;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.borderLight),
        ),
        child: Text(label, style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary)),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('🏆', style: TextStyle(fontSize: 48)),
        SizedBox(height: 12),
        Text('Heniz oýunçy ýok', style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
        SizedBox(height: 6),
        Text('Ilkinji bolan sen bol!', style: TextStyle(fontSize: 13, color: AppColors.textHint)),
      ],
    ),
  );
}
