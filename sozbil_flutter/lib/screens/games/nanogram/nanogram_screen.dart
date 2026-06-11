import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/rewarded_ad_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/widgets/banner_ad_widget.dart';
import '../../../providers/app_providers.dart';

// ── Puzzle definitions ─────────────────────────────────────────────────────────

class _NanoPuzzle {
  final String title;
  final int size;
  final List<bool> grid; // row-major; true = must be filled
  final String difficulty;

  const _NanoPuzzle({
    required this.title,
    required this.size,
    required this.grid,
    required this.difficulty,
  });

  static List<int> _lineClues(List<bool> line) {
    final result = <int>[];
    int run = 0;
    for (final v in line) {
      if (v) {
        run++;
      } else if (run > 0) {
        result.add(run);
        run = 0;
      }
    }
    if (run > 0) result.add(run);
    return result.isEmpty ? [0] : result;
  }

  List<List<int>> get rowClues => List.generate(
      size, (r) => _lineClues(List.generate(size, (c) => grid[r * size + c])));

  List<List<int>> get colClues => List.generate(
      size, (c) => _lineClues(List.generate(size, (r) => grid[r * size + c])));
}

const _kPuzzles = <_NanoPuzzle>[
  // ── 5×5 easy ────────────────────────────────────────────────────────────────
  _NanoPuzzle(
    title: 'Ýürek',
    size: 5,
    difficulty: 'easy',
    grid: [
      false, true,  true,  false, false,
      true,  true,  true,  true,  false,
      true,  true,  true,  true,  true,
      false, true,  true,  true,  false,
      false, false, true,  false, false,
    ],
  ),
  _NanoPuzzle(
    title: 'Haç',
    size: 5,
    difficulty: 'easy',
    grid: [
      false, false, true,  false, false,
      false, false, true,  false, false,
      true,  true,  true,  true,  true,
      false, false, true,  false, false,
      false, false, true,  false, false,
    ],
  ),
  _NanoPuzzle(
    title: 'Almaz',
    size: 5,
    difficulty: 'easy',
    grid: [
      false, false, true,  false, false,
      false, true,  true,  true,  false,
      true,  true,  true,  true,  true,
      false, true,  true,  true,  false,
      false, false, true,  false, false,
    ],
  ),
  _NanoPuzzle(
    title: 'Ok',
    size: 5,
    difficulty: 'easy',
    grid: [
      false, false, false, false, true,
      false, false, false, true,  true,
      true,  true,  true,  true,  true,
      false, false, false, true,  true,
      false, false, false, false, true,
    ],
  ),
  _NanoPuzzle(
    title: 'Öý',
    size: 5,
    difficulty: 'easy',
    grid: [
      false, false, true,  false, false,
      false, true,  true,  true,  false,
      true,  true,  true,  true,  true,
      true,  false, true,  false, true,
      true,  true,  true,  true,  true,
    ],
  ),

  // ── 7×7 medium ──────────────────────────────────────────────────────────────
  _NanoPuzzle(
    title: 'Agaç',
    size: 7,
    difficulty: 'medium',
    grid: [
      false, false, false, true,  false, false, false,
      false, false, true,  true,  true,  false, false,
      false, true,  true,  true,  true,  true,  false,
      true,  true,  true,  true,  true,  true,  true,
      false, false, false, true,  false, false, false,
      false, false, false, true,  false, false, false,
      false, false, false, true,  false, false, false,
    ],
  ),
  _NanoPuzzle(
    title: 'Ýyldyz',
    size: 7,
    difficulty: 'medium',
    grid: [
      false, false, false, true,  false, false, false,
      false, true,  false, true,  false, true,  false,
      false, false, true,  true,  true,  false, false,
      true,  true,  true,  true,  true,  true,  true,
      false, false, true,  true,  true,  false, false,
      false, true,  false, true,  false, true,  false,
      false, false, false, true,  false, false, false,
    ],
  ),
  _NanoPuzzle(
    title: '"T" harpy',
    size: 7,
    difficulty: 'medium',
    grid: [
      true,  true,  true,  true,  true,  true,  true,
      false, false, false, true,  false, false, false,
      false, false, false, true,  false, false, false,
      false, false, false, true,  false, false, false,
      false, false, false, true,  false, false, false,
      false, false, false, true,  false, false, false,
      false, false, false, true,  false, false, false,
    ],
  ),
  _NanoPuzzle(
    title: 'Kebelek',
    size: 7,
    difficulty: 'medium',
    grid: [
      true,  false, false, false, false, false, true,
      true,  true,  false, false, false, true,  true,
      false, true,  true,  false, true,  true,  false,
      false, false, true,  true,  true,  false, false,
      false, true,  true,  false, true,  true,  false,
      true,  true,  false, false, false, true,  true,
      true,  false, false, false, false, false, true,
    ],
  ),
  _NanoPuzzle(
    title: '"H" harpy',
    size: 7,
    difficulty: 'medium',
    grid: [
      true,  false, false, false, false, false, true,
      true,  false, false, false, false, false, true,
      true,  false, false, false, false, false, true,
      true,  true,  true,  true,  true,  true,  true,
      true,  false, false, false, false, false, true,
      true,  false, false, false, false, false, true,
      true,  false, false, false, false, false, true,
    ],
  ),
];

// ── Cell state ─────────────────────────────────────────────────────────────────

enum _CellState { empty, filled, marked }

// ── Screen ─────────────────────────────────────────────────────────────────────

class NanogramScreen extends ConsumerStatefulWidget {
  const NanogramScreen({super.key});

  @override
  ConsumerState<NanogramScreen> createState() => _NanogramScreenState();
}

class _NanogramScreenState extends ConsumerState<NanogramScreen> {
  _NanoPuzzle? _puzzle;
  List<_CellState> _cells = [];
  int _errorCount = 0;
  bool _solved = false;
  bool _loading = true;

  final _rewardedAd = RewardedAdService();

  @override
  void initState() {
    super.initState();
    _rewardedAd.load();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startGame());
  }

  @override
  void dispose() {
    _rewardedAd.dispose();
    super.dispose();
  }

  // ── Setup ──────────────────────────────────────────────────────────────────

  void _startGame() {
    final storage = ref.read(storageServiceProvider);

    if (!storage.canPlay(storage.isSubscribed, ApiConstants.dailyFreeGames)) {
      _autoShowRewardedAd();
      return;
    }

    storage.consumeGame(storage.isSubscribed);
    ref.read(gameLimitProvider.notifier).refresh();

    final pool = List<_NanoPuzzle>.from(_kPuzzles)..shuffle();
    final next = pool.first;
    setState(() {
      _loading = false;
      _puzzle = next;
      _cells = List.filled(next.size * next.size, _CellState.empty);
      _errorCount = 0;
      _solved = false;
    });
  }

  // ── Interaction ────────────────────────────────────────────────────────────

  void _onTap(int idx) {
    final p = _puzzle;
    if (_solved || p == null) return;
    setState(() {
      if (_cells[idx] == _CellState.filled) {
        _cells[idx] = _CellState.empty;
      } else if (_cells[idx] == _CellState.empty) {
        _cells[idx] = _CellState.filled;
        if (!p.grid[idx]) _errorCount++;
        _checkWin(p);
      } else if (_cells[idx] == _CellState.marked) {
        _cells[idx] = _CellState.filled;
        if (!p.grid[idx]) _errorCount++;
        _checkWin(p);
      }
    });
  }

  void _onLongPress(int idx) {
    if (_solved || _puzzle == null) return;
    if (_cells[idx] == _CellState.filled) return;
    setState(() {
      _cells[idx] = _cells[idx] == _CellState.marked
          ? _CellState.empty
          : _CellState.marked;
    });
  }

  void _checkWin(_NanoPuzzle p) {
    for (int i = 0; i < _cells.length; i++) {
      if (p.grid[i] != (_cells[i] == _CellState.filled)) return;
    }
    _solved = true;
    _onSolved();
  }

  void _onSolved() {
    final storage = ref.read(storageServiceProvider);
    final uuid = storage.playerUuid;
    if (uuid != null) {
      ref.read(apiServiceProvider).submitScore(
        playerUuid: uuid,
        gameType: 'nanogram',
        won: true,
        wrongGuesses: _errorCount,
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
        _startGame();
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
            const Text('Gutlaýarys!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text(
              _errorCount == 0
                  ? 'Ýalňyşsyz çözdüň!'
                  : '$_errorCount ýalňyş bilen çözdüň',
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
                    onPressed: () { Navigator.pop(context); _startGame(); },
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
    final p = _puzzle;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          (!_loading && _solved && p != null) ? p.title : 'Nanogram',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_loading)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(child: _ErrorBadge(count: _errorCount)),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _buildBody(),
          ),
          const BannerAdWidget(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final p = _puzzle!;
    return LayoutBuilder(builder: (context, constraints) {
      final rowClues = p.rowClues;
      final colClues = p.colClues;

      final maxRowClueLen = rowClues.map((c) => c.length).reduce(max);
      final maxColClueLen = colClues.map((c) => c.length).reduce(max);

      final totalCols = maxRowClueLen + p.size;
      final totalRows = maxColClueLen + p.size;

      final availW = constraints.maxWidth - 32;
      final availH = constraints.maxHeight - 72;
      final cellSize = min(availW / totalCols, availH / totalRows)
          .clamp(24.0, 46.0);

      final clueW = maxRowClueLen * cellSize;
      final clueH = maxColClueLen * cellSize;
      final gridPx = p.size * cellSize;

      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Column(
          children: [
            const Text(
              'Bassaň dolar  •  Uzyn bassaň ✕',
              style: TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
            const SizedBox(height: 16),

            Center(
              child: SizedBox(
                width: clueW + gridPx,
                height: clueH + gridPx,
                child: Stack(
                  children: [
                    // Column clues (top-right quadrant)
                    Positioned(
                      left: clueW,
                      top: 0,
                      width: gridPx,
                      height: clueH,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(p.size, (c) {
                          return SizedBox(
                            width: cellSize,
                            height: clueH,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: colClues[c].map((n) => SizedBox(
                                width: cellSize,
                                height: cellSize * 0.75,
                                child: Center(
                                  child: Text('$n',
                                      style: TextStyle(
                                        fontSize: cellSize * 0.38,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      )),
                                ),
                              )).toList(),
                            ),
                          );
                        }),
                      ),
                    ),

                    // Row clues (bottom-left quadrant)
                    Positioned(
                      left: 0,
                      top: clueH,
                      width: clueW,
                      height: gridPx,
                      child: Column(
                        children: List.generate(p.size, (r) {
                          return SizedBox(
                            width: clueW,
                            height: cellSize,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: rowClues[r].map((n) => SizedBox(
                                width: cellSize * 0.85,
                                height: cellSize,
                                child: Center(
                                  child: Text('$n',
                                      style: TextStyle(
                                        fontSize: cellSize * 0.38,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      )),
                                ),
                              )).toList(),
                            ),
                          );
                        }),
                      ),
                    ),

                    // Grid (bottom-right quadrant)
                    Positioned(
                      left: clueW,
                      top: clueH,
                      width: gridPx,
                      height: gridPx,
                      child: _buildGrid(cellSize),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            _buildDifficultyBadge(),
          ],
        ),
      );
    });
  }

  Widget _buildGrid(double cellSize) {
    final n = _puzzle!.size;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.textPrimary, width: 2),
      ),
      child: Column(
        children: List.generate(n, (r) {
          return Row(
            children: List.generate(n, (c) {
              final idx = r * n + c;
              final state = _cells[idx];
              final solution = _puzzle!.grid[idx];

              Color bg;
              Widget? inner;

              switch (state) {
                case _CellState.filled:
                  bg = (!solution && !_solved)
                      ? AppColors.error
                      : AppColors.textPrimary;
                  break;
                case _CellState.marked:
                  bg = AppColors.surfaceSecondary;
                  inner = Center(
                    child: Text('✕',
                        style: TextStyle(
                          fontSize: cellSize * 0.42,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textHint,
                        )),
                  );
                  break;
                case _CellState.empty:
                  bg = AppColors.surface;
                  break;
              }

              // Thin interior lines, slightly thicker every 5
              final rightW = c == n - 1 ? 0.0 : ((c + 1) % 5 == 0 ? 1.5 : 0.5);
              final bottomW = r == n - 1 ? 0.0 : ((r + 1) % 5 == 0 ? 1.5 : 0.5);

              return GestureDetector(
                onTap: () => _onTap(idx),
                onLongPress: () => _onLongPress(idx),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 80),
                  width: cellSize,
                  height: cellSize,
                  decoration: BoxDecoration(
                    color: bg,
                    border: Border(
                      right: BorderSide(
                          color: AppColors.border, width: rightW),
                      bottom: BorderSide(
                          color: AppColors.border, width: bottomW),
                    ),
                  ),
                  child: inner,
                ),
              );
            }),
          );
        }),
      ),
    );
  }

  Widget _buildDifficultyBadge() {
    final p = _puzzle!;
    final d = p.difficulty;
    final color = d == 'easy' ? AppColors.success : AppColors.accent;
    final label = d == 'easy'
        ? 'Aňsat  •  ${p.size}×${p.size}'
        : 'Orta  •  ${p.size}×${p.size}';
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
}

// ── Error badge ────────────────────────────────────────────────────────────────

class _ErrorBadge extends StatelessWidget {
  final int count;
  const _ErrorBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('❌', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text('$count',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              )),
        ],
      ),
    );
  }
}
