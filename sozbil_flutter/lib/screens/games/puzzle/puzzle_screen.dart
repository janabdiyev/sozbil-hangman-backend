import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/rewarded_ad_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/widgets/banner_ad_widget.dart';
import '../../../models/puzzle_image.dart';
import '../../../providers/app_providers.dart';

class PuzzleScreen extends ConsumerStatefulWidget {
  const PuzzleScreen({super.key});

  @override
  ConsumerState<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends ConsumerState<PuzzleScreen> {
  PuzzleImageModel? _puzzleImage;
  bool _loading = true;
  String? _errorMessage; // 'noImages' | other error text

  // Puzzle state
  int _cols = 4;
  int _rows = 4;
  List<int> _pieces = []; // _pieces[slotIndex] = pieceIndex (original position)
  int? _selected;         // currently selected slot
  int _swaps = 0;
  bool _solved = false;
  bool _showHint = false;

  final _rewardedAd = RewardedAdService();

  @override
  void initState() {
    super.initState();
    _rewardedAd.load();
    _loadPuzzle();
  }

  @override
  void dispose() {
    _rewardedAd.dispose();
    super.dispose();
  }

  // ── Loading ────────────────────────────────────────────────────────────────

  Future<void> _loadPuzzle() async {
    final storage = ref.read(storageServiceProvider);

    if (!storage.canPlay(storage.isSubscribed, ApiConstants.dailyFreeGames)) {
      _autoShowRewardedAd();
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
      _solved = false;
      _selected = null;
      _showHint = false;
    });

    try {
      final api = ref.read(apiServiceProvider);
      final images = await api.getPuzzleImages('puzzle');
      final valid = images.where((e) => e.imageUrl != null).toList();

      if (valid.isEmpty) {
        setState(() { _loading = false; _errorMessage = 'noImages'; });
        return;
      }

      final puzzle = valid[Random().nextInt(valid.length)];
      final gridSize = _gridSizeFor(puzzle.difficulty);
      final count = gridSize * gridSize;
      final pieces = List.generate(count, (i) => i);
      // Ensure the shuffle is never already solved
      do { pieces.shuffle(); } while (_checkSolved(pieces));

      storage.consumeGame(storage.isSubscribed);
      ref.read(gameLimitProvider.notifier).refresh();

      setState(() {
        _puzzleImage = puzzle;
        _cols = gridSize;
        _rows = gridSize;
        _pieces = pieces;
        _swaps = 0;
        _loading = false;
      });
    } catch (_) {
      setState(() { _loading = false; _errorMessage = 'error'; });
    }
  }

  int _gridSizeFor(String difficulty) {
    switch (difficulty) {
      case 'easy':   return 3;
      case 'hard':   return 5;
      default:       return 4; // medium
    }
  }

  // ── Game logic ─────────────────────────────────────────────────────────────

  bool _checkSolved(List<int> pieces) {
    for (int i = 0; i < pieces.length; i++) {
      if (pieces[i] != i) return false;
    }
    return true;
  }

  void _onTileTap(int slotIndex) {
    if (_solved) return;

    if (_selected == null) {
      setState(() => _selected = slotIndex);
      return;
    }

    if (_selected == slotIndex) {
      setState(() => _selected = null);
      return;
    }

    // Swap the two pieces
    setState(() {
      final tmp = _pieces[_selected!];
      _pieces[_selected!] = _pieces[slotIndex];
      _pieces[slotIndex] = tmp;
      _swaps++;
      _selected = null;

      if (_checkSolved(_pieces)) {
        _solved = true;
        _onPuzzleSolved();
      }
    });
  }

  void _onPuzzleSolved() {
    final storage = ref.read(storageServiceProvider);
    final uuid = storage.playerUuid;
    if (uuid != null) {
      ref.read(apiServiceProvider).submitScore(
        playerUuid: uuid,
        gameType: 'puzzle',
        won: true,
        wrongGuesses: _swaps,
      ).then((_) {
        ref.read(playerProvider.notifier).refresh();
      }).catchError((_) {});
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showWinDialog();
    });
  }

  void _autoShowRewardedAd() {
    _rewardedAd.show(
      onRewarded: () {
        final storage = ref.read(storageServiceProvider);
        storage.addRewardGames(ApiConstants.gamesPerAd, ApiConstants.gamesPerAd);
        ref.read(gameLimitProvider.notifier).refresh();
        _loadPuzzle();
      },
      onFailed: () { if (mounted) Navigator.pop(context); },
    );
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 12),
            const Text(
              'Gutlaýarys!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$_swaps süýşürme bilen çözdüň',
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context); // dialog
                      Navigator.pop(context); // screen
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: const Text('Çyk',
                        style: TextStyle(color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // dialog
                      _loadPuzzle();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Täzeden',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _puzzleImage?.title ?? 'Puzzle',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_loading && _puzzleImage?.imageUrl != null && !_solved)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: const Icon(Icons.lightbulb_outline_rounded,
                    color: AppColors.accent),
                tooltip: 'Surat görkezmek',
                onPressed: _showHint
                    ? null
                    : () {
                        setState(() => _showHint = true);
                        Future.delayed(const Duration(seconds: 2), () {
                          if (mounted) setState(() => _showHint = false);
                        });
                      },
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildBody()),
          const BannerAdWidget(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errorMessage == 'noImages') {
      return _buildEmptyState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Grid takes up most of the available height, leave room for stats bar
        final maxSide = min(
          constraints.maxWidth - 32,
          constraints.maxHeight - 100,
        ).clamp(180.0, 420.0);

        final tileSize = maxSide / _cols;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            children: [
              // ── Puzzle grid / hint image ──────────────────────────────────
              Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _showHint
                      ? _buildHintImage(maxSide)
                      : _buildGrid(maxSide, tileSize),
                ),
              ),

              const SizedBox(height: 20),

              // ── Stats bar ─────────────────────────────────────────────────
              _buildStatsBar(),

              const SizedBox(height: 12),

              // ── Difficulty badge ──────────────────────────────────────────
              if (_puzzleImage != null) _buildDifficultyBadge(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHintImage(double size) {
    return Container(
      key: const ValueKey('hint'),
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Image.network(
              _puzzleImage!.imageUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.accent, width: 2.5),
                ),
                child: const Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: _HintLabel(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(double size, double tileSize) {
    return Container(
      key: const ValueKey('grid'),
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _cols,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
          ),
          itemCount: _cols * _rows,
          itemBuilder: (context, slotIndex) {
            final pieceIndex = _pieces[slotIndex];
            final isSelected = _selected == slotIndex;
            final inPlace = pieceIndex == slotIndex;

            return GestureDetector(
              onTap: () => _onTileTap(slotIndex),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                foregroundDecoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : (_solved && inPlace)
                            ? AppColors.success
                            : Colors.transparent,
                    width: isSelected ? 2.5 : 2,
                  ),
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.15)
                      : Colors.transparent,
                ),
                child: _PuzzleTile(
                  imageUrl: _puzzleImage!.imageUrl!,
                  pieceIndex: pieceIndex,
                  cols: _cols,
                  rows: _rows,
                  tileSize: tileSize,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatsBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StatChip(
          icon: Icons.swap_horiz_rounded,
          iconColor: AppColors.primary,
          label: '$_swaps süýşürme',
        ),
        const SizedBox(width: 10),
        _StatChip(
          icon: Icons.lightbulb_outline_rounded,
          iconColor: AppColors.accent,
          label: '💡 Görkezmek',
          onTap: _showHint
              ? null
              : () {
                  setState(() => _showHint = true);
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) setState(() => _showHint = false);
                  });
                },
        ),
      ],
    );
  }

  Widget _buildDifficultyBadge() {
    final d = _puzzleImage!.difficulty;
    final color = d == 'easy'
        ? AppColors.success
        : d == 'hard'
            ? AppColors.error
            : AppColors.accent;
    final label = d == 'easy'
        ? 'Aňsat  •  ${_cols}×$_cols'
        : d == 'hard'
            ? 'Kyn  •  ${_cols}×$_cols'
            : 'Orta  •  ${_cols}×$_cols';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎭', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text(
              'Entek surat ýüklenmedi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Admin panelinden jigsaw suratlaryny ýükläň',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _loadPuzzle,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Täzeden synanyş',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.textHint),
          const SizedBox(height: 16),
          const Text('Ýüklenip bilinmedi',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadPuzzle,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Täzeden',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Puzzle tile ────────────────────────────────────────────────────────────────

class _PuzzleTile extends StatelessWidget {
  final String imageUrl;
  final int pieceIndex;
  final int cols;
  final int rows;
  final double tileSize;

  const _PuzzleTile({
    required this.imageUrl,
    required this.pieceIndex,
    required this.cols,
    required this.rows,
    required this.tileSize,
  });

  @override
  Widget build(BuildContext context) {
    final col = pieceIndex % cols;
    final row = pieceIndex ~/ cols;

    // Map (col, row) to Alignment(-1..1, -1..1)
    final xAlign = cols == 1 ? 0.0 : (col / (cols - 1)) * 2 - 1;
    final yAlign = rows == 1 ? 0.0 : (row / (rows - 1)) * 2 - 1;

    return ClipRect(
      child: Align(
        alignment: Alignment(xAlign, yAlign),
        widthFactor: 1.0 / cols,
        heightFactor: 1.0 / rows,
        child: Image.network(
          imageUrl,
          width: tileSize * cols,
          height: tileSize * rows,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return ColoredBox(
              color: AppColors.surfaceSecondary,
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded /
                            progress.expectedTotalBytes!
                        : null,
                    color: AppColors.primary,
                  ),
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) => const ColoredBox(
            color: AppColors.surfaceSecondary,
            child: Center(
              child: Icon(Icons.broken_image_rounded,
                  color: AppColors.textHint, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Hint label overlay ─────────────────────────────────────────────────────────

class _HintLabel extends StatelessWidget {
  const _HintLabel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        '💡 Görünýär…',
        style: TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── Stat chip ──────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback? onTap;

  const _StatChip({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
