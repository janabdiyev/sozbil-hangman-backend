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

// Sentinel value meaning "empty slot"
const _kEmpty = -1;

class SuysurmeScreen extends ConsumerStatefulWidget {
  const SuysurmeScreen({super.key});

  @override
  ConsumerState<SuysurmeScreen> createState() => _SuysurmeScreenState();
}

class _SuysurmeScreenState extends ConsumerState<SuysurmeScreen> {
  PuzzleImageModel? _puzzle;
  bool _loading = true;
  String? _error; // 'noImages' | 'error'

  // Board state: _board[slotIndex] = pieceIndex (0..n²-2) or _kEmpty
  late List<int> _board;
  late int _cols;
  int _moveCount = 0;
  bool _solved = false;
  bool _showHint = false;

  final _rewardedAd = RewardedAdService();

  @override
  void initState() {
    super.initState();
    _rewardedAd.load();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPuzzle());
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

    setState(() { _loading = true; _error = null; _solved = false; _showHint = false; });

    try {
      final images = await ref.read(apiServiceProvider).getPuzzleImages('puzzle');
      final valid = images.where((e) => e.imageUrl != null).toList();

      if (valid.isEmpty) {
        setState(() { _loading = false; _error = 'noImages'; });
        return;
      }

      final puzzle = valid[Random().nextInt(valid.length)];
      final cols = _gridSizeFor(puzzle.difficulty);

      storage.consumeGame(storage.isSubscribed);
      ref.read(gameLimitProvider.notifier).refresh();

      setState(() {
        _puzzle = puzzle;
        _cols = cols;
        _board = _buildSolvedBoard(cols);
        _moveCount = 0;
        _loading = false;
      });

      // Shuffle AFTER build so the widget renders first (avoids flash)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _shuffleBoard(_shuffleMovesFor(puzzle.difficulty)));
      });
    } catch (_) {
      setState(() { _loading = false; _error = 'error'; });
    }
  }

  int _gridSizeFor(String d) => d == 'easy' ? 3 : 4;

  int _shuffleMovesFor(String d) {
    switch (d) {
      case 'easy':  return 60;
      case 'hard':  return 300;
      default:      return 150; // medium
    }
  }

  // ── Board helpers ──────────────────────────────────────────────────────────

  List<int> _buildSolvedBoard(int cols) {
    final total = cols * cols;
    return List.generate(total, (i) => i < total - 1 ? i : _kEmpty);
  }

  /// Shuffle by making random valid moves from the solved state.
  /// This guarantees the board is always solvable.
  void _shuffleBoard(int moves) {
    final rng = Random();
    int emptyIdx = _board.indexOf(_kEmpty);
    int? lastEmpty; // prevent immediate undo

    for (int i = 0; i < moves; i++) {
      final candidates = _adjacentSlots(emptyIdx)
          .where((s) => s != lastEmpty)
          .toList();
      if (candidates.isEmpty) continue;
      final chosen = candidates[rng.nextInt(candidates.length)];
      _board[emptyIdx] = _board[chosen];
      _board[chosen] = _kEmpty;
      lastEmpty = emptyIdx;
      emptyIdx = chosen;
    }
  }

  List<int> _adjacentSlots(int idx) {
    final row = idx ~/ _cols;
    final col = idx % _cols;
    final result = <int>[];
    if (row > 0)        result.add(idx - _cols); // up
    if (row < _cols - 1) result.add(idx + _cols); // down
    if (col > 0)        result.add(idx - 1);      // left
    if (col < _cols - 1) result.add(idx + 1);     // right
    return result;
  }

  bool _isAdjacentToEmpty(int slotIdx, int emptyIdx) {
    final sRow = slotIdx ~/ _cols, sCol = slotIdx % _cols;
    final eRow = emptyIdx ~/ _cols, eCol = emptyIdx % _cols;
    return (sRow == eRow && (sCol - eCol).abs() == 1) ||
           (sCol == eCol && (sRow - eRow).abs() == 1);
  }

  bool _isSolved() {
    for (int i = 0; i < _board.length - 1; i++) {
      if (_board[i] != i) return false;
    }
    return _board.last == _kEmpty;
  }

  // ── Interaction ────────────────────────────────────────────────────────────

  void _onTileTap(int slotIdx) {
    if (_solved || _loading) return;
    final emptyIdx = _board.indexOf(_kEmpty);
    if (!_isAdjacentToEmpty(slotIdx, emptyIdx)) return;

    setState(() {
      _board[emptyIdx] = _board[slotIdx];
      _board[slotIdx] = _kEmpty;
      _moveCount++;
      if (_isSolved()) {
        _solved = true;
        _onSolved();
      }
    });
  }

  void _onSolved() {
    final storage = ref.read(storageServiceProvider);
    final uuid = storage.playerUuid;
    if (uuid != null) {
      ref.read(apiServiceProvider).submitScore(
        playerUuid: uuid,
        gameType: 'suysurme',
        won: true,
        wrongGuesses: _moveCount,
      ).then((_) => ref.read(playerProvider.notifier).refresh())
       .catchError((_) {});
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showWinDialog();
    });
  }

  void _autoShowRewardedAd() {
    _rewardedAd.show(
      onRewarded: () {
        final s = ref.read(storageServiceProvider);
        s.addRewardGames(ApiConstants.gamesPerAd, ApiConstants.gamesPerAd);
        ref.read(gameLimitProvider.notifier).refresh();
        _loadPuzzle();
      },
      onFailed: () { if (mounted) Navigator.pop(context); },
    );
  }

  // ── Win dialog ─────────────────────────────────────────────────────────────

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
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              '$_moveCount süýşürme bilen çözdüň',
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
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
                    onPressed: () { Navigator.pop(context); _loadPuzzle(); },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Täzeden',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _puzzle?.title ?? 'Süýşürme',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_loading && _puzzle?.imageUrl != null && !_solved)
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
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error == 'noImages') return _buildEmptyState();
    if (_error != null)       return _buildErrorState();

    return LayoutBuilder(builder: (context, constraints) {
      final side = min(constraints.maxWidth - 32,
                       constraints.maxHeight - 100).clamp(180.0, 420.0);
      final tileSize = side / _cols;

      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: [
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _showHint
                    ? _buildHintImage(side)
                    : _buildGrid(side, tileSize),
              ),
            ),
            const SizedBox(height: 20),
            _buildStatsBar(),
            if (_puzzle != null) ...[
              const SizedBox(height: 12),
              _buildDifficultyBadge(),
            ],
          ],
        ),
      );
    });
  }

  // ── Grid ───────────────────────────────────────────────────────────────────

  Widget _buildGrid(double size, double tileSize) {
    return Container(
      key: const ValueKey('grid'),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.background,
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
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _cols,
            mainAxisSpacing: 3,
            crossAxisSpacing: 3,
          ),
          itemCount: _board.length,
          itemBuilder: (context, slotIdx) {
            final piece = _board[slotIdx];
            if (piece == _kEmpty) return _buildEmptySlot();

            final emptyIdx = _board.indexOf(_kEmpty);
            final canSlide = _isAdjacentToEmpty(slotIdx, emptyIdx);

            return GestureDetector(
              onTap: () => _onTileTap(slotIdx),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 80),
                decoration: BoxDecoration(
                  boxShadow: canSlide
                      ? [BoxShadow(
                          color: AppColors.primary.withOpacity(0.25),
                          blurRadius: 6,
                        )]
                      : null,
                ),
                child: _SlidingTile(
                  imageUrl: _puzzle!.imageUrl!,
                  pieceIndex: piece,
                  cols: _cols,
                  tileSize: tileSize - 3,
                  canSlide: canSlide,
                  solved: _solved,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptySlot() {
    return Container(color: const Color(0xFF1A1A2E).withOpacity(0.08));
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
        border: Border.all(color: AppColors.accent, width: 2.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Image.network(
              _puzzle!.imageUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '💡 Görünýär…',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StatChip(
          icon: Icons.swap_vert_rounded,
          iconColor: AppColors.primary,
          label: '$_moveCount süýşürme',
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _showHint
              ? null
              : () {
                  setState(() => _showHint = true);
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) setState(() => _showHint = false);
                  });
                },
          child: _StatChip(
            icon: Icons.lightbulb_outline_rounded,
            iconColor: AppColors.accent,
            label: '💡 Görkezmek',
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultyBadge() {
    final d = _puzzle!.difficulty;
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
      child: Text(label,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🧩', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text('Entek surat ýüklenmedi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text('Admin panelinden sliding suratlaryny ýükläň',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                textAlign: TextAlign.center),
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
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
          const Icon(Icons.cloud_off_rounded, size: 48,
              color: AppColors.textHint),
          const SizedBox(height: 16),
          const Text('Ýüklenip bilinmedi',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
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

// ── Sliding tile widget ────────────────────────────────────────────────────────

class _SlidingTile extends StatelessWidget {
  final String imageUrl;
  final int pieceIndex;
  final int cols;
  final double tileSize;
  final bool canSlide;
  final bool solved;

  const _SlidingTile({
    required this.imageUrl,
    required this.pieceIndex,
    required this.cols,
    required this.tileSize,
    required this.canSlide,
    required this.solved,
  });

  @override
  Widget build(BuildContext context) {
    final col = pieceIndex % cols;
    final row = pieceIndex ~/ cols;
    final xAlign = cols == 1 ? 0.0 : (col / (cols - 1)) * 2 - 1;
    final yAlign = cols == 1 ? 0.0 : (row / (cols - 1)) * 2 - 1;

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRect(
          child: Align(
            alignment: Alignment(xAlign, yAlign),
            widthFactor: 1.0 / cols,
            heightFactor: 1.0 / cols,
            child: Image.network(
              imageUrl,
              width: tileSize * cols,
              height: tileSize * cols,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return ColoredBox(
                  color: AppColors.surfaceSecondary,
                  child: Center(
                    child: SizedBox(
                      width: 14,
                      height: 14,
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
                      color: AppColors.textHint, size: 18),
                ),
              ),
            ),
          ),
        ),
        // Subtle highlight on slideable tiles
        if (canSlide && !solved)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.5),
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Stat chip ──────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;

  const _StatChip({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
