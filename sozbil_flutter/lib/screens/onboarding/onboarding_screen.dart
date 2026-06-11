import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../models/player.dart';
import '../../providers/app_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  String _selectedAvatar = 'eagle';
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final location = _locationController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Adyňy ýaz');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(playerProvider.notifier).register(
        displayName: name,
        location: location,
        avatarKey: _selectedAvatar,
      );
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() { _error = 'Näsazlyk boldy. Gaýtadan synanyş.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text('🎮', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              const Text(
                'Sözbil-e\nhoş geldiňiz!',
                style: TextStyle(
                  fontSize: 32, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary, height: 1.2, letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Türkmen dilinde oýna, dünýä bilen bäsleş.',
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 40),

              // Name field
              const Text('Adyň', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: 'Mysal: Merdan, Aýgül...'),
                textCapitalization: TextCapitalization.words,
                maxLength: 30,
              ),
              const SizedBox(height: 20),

              // Location field
              const Text('Nireden?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(hintText: 'Aşgabat, Istanbul, Berlin...'),
                maxLength: 60,
              ),
              const SizedBox(height: 28),

              // Avatar picker
              const Text('Awataryňy saýla', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: avatarEmojis.entries.map((e) {
                  final selected = _selectedAvatar == e.key;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedAvatar = e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primaryLight : AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected ? AppColors.primary : AppColors.borderLight,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Center(child: Text(e.value, style: const TextStyle(fontSize: 26))),
                    ),
                  );
                }).toList(),
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
              ],

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Oýuna başla →'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
