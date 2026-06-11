import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/player.dart';
import '../../providers/app_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerAsync = ref.watch(playerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil'),
        automaticallyImplyLeading: false,
        actions: [
          if (playerAsync.valueOrNull != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _showEditDialog(context, ref, playerAsync.valueOrNull!),
            ),
        ],
      ),
      body: playerAsync.when(
        data: (player) => player == null
            ? const _NotRegistered()
            : _ProfileBody(player: player),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => const Center(child: Text('Ýüklenip bilmedi')),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, PlayerModel player) {
    final nameCtrl = TextEditingController(text: player.displayName);
    final locCtrl = TextEditingController(text: player.location);
    String avatar = player.avatarKey;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Profili üýtget', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Adyň'), maxLength: 30),
              const SizedBox(height: 12),
              TextField(controller: locCtrl, decoration: const InputDecoration(labelText: 'Nireden?'), maxLength: 60),
              const SizedBox(height: 16),
              const Text('Awatar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: avatarEmojis.entries.map((e) => GestureDetector(
                  onTap: () => setState(() => avatar = e.key),
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: avatar == e.key ? AppColors.primaryLight : AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: avatar == e.key ? AppColors.primary : AppColors.borderLight,
                          width: avatar == e.key ? 2 : 1),
                    ),
                    child: Center(child: Text(e.value, style: const TextStyle(fontSize: 22))),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await ref.read(playerProvider.notifier).update(
                      displayName: nameCtrl.text.trim(),
                      location: locCtrl.text.trim(),
                      avatarKey: avatar,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Ýatda sakla'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final PlayerModel player;
  const _ProfileBody({required this.player});

  @override
  Widget build(BuildContext context) {
    final xpForNextLevel = _xpForNext(player.level);
    final xpProgress = xpForNextLevel > 0 ? (player.xp / xpForNextLevel).clamp(0.0, 1.0) : 1.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        children: [
          // Avatar + name
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: [
                Text(player.avatarEmoji, style: const TextStyle(fontSize: 56)),
                const SizedBox(height: 8),
                Text(player.displayName,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                if (player.location.isNotEmpty)
                  Text('📍 ${player.location}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(20)),
                  child: Text(player.levelDisplay,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                ),
                const SizedBox(height: 14),
                // XP bar
                Row(
                  children: [
                    Text('${player.xp} XP', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const Spacer(),
                    Text('$xpForNextLevel XP', style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: xpProgress, minHeight: 8,
                    backgroundColor: AppColors.surfaceSecondary,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Stats row
          Row(
            children: [
              _StatCard(emoji: '🔥', label: 'Streak', value: '${player.streakDays} gün'),
              const SizedBox(width: 10),
              _StatCard(emoji: '🏅', label: 'Iň uzyn', value: '${player.longestStreak} gün'),
              const SizedBox(width: 10),
              _StatCard(emoji: '⭐', label: 'XP', value: '${player.xp}'),
            ],
          ),

          const SizedBox(height: 24),

          // Achievements
          if (player.achievements.isNotEmpty) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Üstünlikler', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.1,
              ),
              itemCount: player.achievements.length,
              itemBuilder: (_, i) {
                final ach = player.achievements[i];
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(ach.icon, style: const TextStyle(fontSize: 28)),
                      const SizedBox(height: 4),
                      Text(ach.nameTk.isNotEmpty ? ach.nameTk : ach.name,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          textAlign: TextAlign.center, maxLines: 2),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  int _xpForNext(String level) {
    const thresholds = {
      'baslangyc': 100, 'okuwcy': 300, 'oyuncy': 600,
      'ustat': 1000, 'meshur': 2000, 'legenda': 9999,
    };
    return thresholds[level] ?? 9999;
  }
}

class _StatCard extends StatelessWidget {
  final String emoji, label, value;
  const _StatCard({required this.emoji, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
        ],
      ),
    ),
  );
}

class _NotRegistered extends StatelessWidget {
  const _NotRegistered();
  @override
  Widget build(BuildContext context) => const Center(
    child: Text('Profil tapylmady', style: TextStyle(color: AppColors.textSecondary)),
  );
}
