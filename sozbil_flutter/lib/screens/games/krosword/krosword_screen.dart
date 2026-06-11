import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/rewarded_ad_service.dart';
import '../../../core/widgets/banner_ad_widget.dart';
import '../../../models/word.dart';
import '../../../providers/app_providers.dart';

// ── Grid constants ─────────────────────────────────────────────────────────────
const _kGS = 15;    // grid size (15×15)
const _kCS = 40.0;  // cell slot size px (tile visual = _kCS - 4)
const _kMinWords = 6;
const _kMaxWords = 14;

// ── Data ───────────────────────────────────────────────────────────────────────

class _Word {
  final String text;
  final String hint;
  final int row, col;
  final bool across;
  int num = 0;

  _Word({
    required this.text,
    required this.hint,
    required this.row,
    required this.col,
    required this.across,
  });

  List<(int, int)> get cells => List.generate(
    text.length,
    (i) => across ? (row, col + i) : (row + i, col),
  );

  bool contains(int r, int c) => across
      ? r == row && c >= col && c < col + text.length
      : c == col && r >= row && r < row + text.length;

  int indexAt(int r, int c) => across ? c - col : r - row;
}

class _Puzzle {
  final Map<(int, int), String> letters;
  final Map<(int, int), int> numbers;
  final List<_Word> words;

  const _Puzzle({required this.letters, required this.numbers, required this.words});

  static _Puzzle? generate(List<WordModel> pool) {
    for (int attempt = 0; attempt < 10; attempt++) {
      final shuffled = List.of(pool)..shuffle();
      final result = _tryBuild(shuffled);
      if (result != null) return result;
    }
    return null;
  }

  static _Puzzle? _tryBuild(List<WordModel> pool) {
    final candidates = pool
        .where((w) => w.word.length >= 3 && w.word.length <= 11)
        .toList();
    if (candidates.isEmpty) return null;

    final raw = List.generate(_kGS, (_) => List<String?>.filled(_kGS, null));
    final acrossSet = <(int, int)>{};
    final downSet = <(int, int)>{};
    final placed = <_Word>[];

    final w0 = candidates.first;
    final r0 = _kGS ~/ 2;
    final c0 = (_kGS - w0.word.length) ~/ 2;
    _doPlace(raw, acrossSet, downSet, w0.word, r0, c0, true);
    placed.add(_Word(text: w0.word, hint: w0.hint, row: r0, col: c0, across: true));

    for (final wm in candidates.skip(1)) {
      if (placed.length >= _kMaxWords) break;
      _tryAdd(raw, acrossSet, downSet, placed, wm);
    }

    if (placed.length < _kMinWords) return null;

    final letters = <(int, int), String>{};
    for (int r = 0; r < _kGS; r++) {
      for (int c = 0; c < _kGS; c++) {
        if (raw[r][c] != null) letters[(r, c)] = raw[r][c]!;
      }
    }

    int n = 1;
    final numbers = <(int, int), int>{};
    for (int r = 0; r < _kGS; r++) {
      for (int c = 0; c < _kGS; c++) {
        if (raw[r][c] == null) continue;
        final sA = (c == 0 || raw[r][c - 1] == null) && c + 1 < _kGS && raw[r][c + 1] != null;
        final sD = (r == 0 || raw[r - 1][c] == null) && r + 1 < _kGS && raw[r + 1][c] != null;
        if (sA || sD) {
          numbers[(r, c)] = n;
          for (final w in placed) {
            if (w.row == r && w.col == c) w.num = n;
          }
          n++;
        }
      }
    }

    placed.sort((a, b) {
      final nc = a.num.compareTo(b.num);
      if (nc != 0) return nc;
      return a.across ? -1 : 1;
    });

    return _Puzzle(letters: letters, numbers: numbers, words: placed);
  }

  static bool _tryAdd(
    List<List<String?>> raw,
    Set<(int, int)> acrossSet,
    Set<(int, int)> downSet,
    List<_Word> placed,
    WordModel wm,
  ) {
    final shuffled = List.of(placed)..shuffle();
    for (final ex in shuffled) {
      for (int j = 0; j < wm.word.length; j++) {
        for (int k = 0; k < ex.text.length; k++) {
          if (ex.text[k] != wm.word[j]) continue;
          final er = ex.across ? ex.row : ex.row + k;
          final ec = ex.across ? ex.col + k : ex.col;
          final na = !ex.across;
          final nr = na ? er : er - j;
          final nc = na ? ec - j : ec;
          if (_canPlace(raw, acrossSet, downSet, wm.word, nr, nc, na)) {
            _doPlace(raw, acrossSet, downSet, wm.word, nr, nc, na);
            placed.add(_Word(text: wm.word, hint: wm.hint, row: nr, col: nc, across: na));
            return true;
          }
        }
      }
    }
    return false;
  }

  static bool _canPlace(
    List<List<String?>> raw,
    Set<(int, int)> acrossSet,
    Set<(int, int)> downSet,
    String word,
    int r0,
    int c0,
    bool across,
  ) {
    final len = word.length;

    if (across) {
      if (r0 < 0 || r0 >= _kGS || c0 < 0 || c0 + len > _kGS) return false;
      if (c0 > 0 && raw[r0][c0 - 1] != null) return false;
      if (c0 + len < _kGS && raw[r0][c0 + len] != null) return false;
    } else {
      if (c0 < 0 || c0 >= _kGS || r0 < 0 || r0 + len > _kGS) return false;
      if (r0 > 0 && raw[r0 - 1][c0] != null) return false;
      if (r0 + len < _kGS && raw[r0 + len][c0] != null) return false;
    }

    int intersections = 0;
    for (int i = 0; i < len; i++) {
      final r = across ? r0 : r0 + i;
      final c = across ? c0 + i : c0;
      final ex = raw[r][c];

      if (ex != null) {
        if (ex != word[i]) return false;
        if (across && acrossSet.contains((r, c))) return false;
        if (!across && downSet.contains((r, c))) return false;
        intersections++;
      } else {
        if (across) {
          if (r > 0 && raw[r - 1][c] != null) return false;
          if (r + 1 < _kGS && raw[r + 1][c] != null) return false;
        } else {
          if (c > 0 && raw[r][c - 1] != null) return false;
          if (c + 1 < _kGS && raw[r][c + 1] != null) return false;
        }
      }
    }

    return intersections >= 1;
  }

  static void _doPlace(
    List<List<String?>> raw,
    Set<(int, int)> acrossSet,
    Set<(int, int)> downSet,
    String word,
    int row,
    int col,
    bool across,
  ) {
    for (int i = 0; i < word.length; i++) {
      final r = across ? row : row + i;
      final c = across ? col + i : col;
      raw[r][c] = word[i];
      if (across) acrossSet.add((r, c));
      else downSet.add((r, c));
    }
  }
}

// ── Screen ─────────────────────────────────────────────────────────────────────

class KroswordScreen extends ConsumerStatefulWidget {
  const KroswordScreen({super.key});

  @override
  ConsumerState<KroswordScreen> createState() => _KroswordScreenState();
}

class _KroswordScreenState extends ConsumerState<KroswordScreen> {
  _Puzzle? _puzzle;
  final Map<(int, int), String> _guesses = {};
  int _selectedWordIdx = -1;
  int _cursorInWord = 0;
  bool _complete = false;
  bool _started = false;
  bool _puzzleBuilt = false;
  Size _viewportSize = Size.zero;
  final _transformCtrl = TransformationController();
  final _rewardedAd = RewardedAdService();

  @override
  void initState() {
    super.initState();
    _rewardedAd.load();
    _checkCredits();
  }

  @override
  void dispose() {
    _transformCtrl.dispose();
    _rewardedAd.dispose();
    super.dispose();
  }

  void _checkCredits() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final storage = ref.read(storageServiceProvider);
      if (!storage.canPlay(storage.isSubscribed, ApiConstants.dailyFreeGames)) {
        _rewardedAd.show(
          onRewarded: () {
            storage.addRewardGames(ApiConstants.gamesPerAd, ApiConstants.gamesPerAd);
            storage.consumeGame(storage.isSubscribed);
            ref.read(gameLimitProvider.notifier).refresh();
            setState(() => _started = true);
          },
          onFailed: () { if (mounted) Navigator.pop(context); },
        );
        return;
      }
      storage.consumeGame(storage.isSubscribed);
      ref.read(gameLimitProvider.notifier).refresh();
      setState(() => _started = true);
    });
  }

  void _buildPuzzle(List<WordModel> words) {
    if (_puzzleBuilt) return;
    _puzzleBuilt = true;
    final puzzle = _Puzzle.generate(words);
    setState(() => _puzzle = puzzle);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitGrid());
  }

  // Fit the ACTUAL bounding box of letter cells to the viewport — nothing cut off.
  void _fitGrid() {
    if (!mounted || _puzzle == null || _puzzle!.letters.isEmpty) return;
    final p = _puzzle!;

    int minR = _kGS, maxR = 0, minC = _kGS, maxC = 0;
    for (final pos in p.letters.keys) {
      final r = pos.$1; final c = pos.$2;
      if (r < minR) minR = r;
      if (r > maxR) maxR = r;
      if (c < minC) minC = c;
      if (c > maxC) maxC = c;
    }

    final contentCols = (maxC - minC + 1).toDouble();
    final contentRows = (maxR - minR + 1).toDouble();

    final vw = _viewportSize.width > 0 ? _viewportSize.width : MediaQuery.of(context).size.width;
    final vh = _viewportSize.height > 0 ? _viewportSize.height : 520.0;

    const padding = 24.0;
    final scaleX = (vw - padding * 2) / (contentCols * _kCS);
    final scaleY = (vh - padding * 2) / (contentRows * _kCS);
    final scale = min(scaleX, scaleY).clamp(0.4, 2.0);

    // Center the content bounding box in the viewport
    final scaledW = contentCols * _kCS * scale;
    final scaledH = contentRows * _kCS * scale;
    final tx = (vw - scaledW) / 2 - minC * _kCS * scale;
    final ty = (vh - scaledH) / 2 - minR * _kCS * scale;

    _transformCtrl.value = Matrix4.identity()
      ..translate(tx, ty)
      ..scale(scale);
  }

  void _newGame(List<WordModel> words) {
    setState(() {
      _puzzle = null;
      _guesses.clear();
      _selectedWordIdx = -1;
      _cursorInWord = 0;
      _complete = false;
      _puzzleBuilt = false;
    });
    final puzzle = _Puzzle.generate(words);
    setState(() {
      _puzzle = puzzle;
      _puzzleBuilt = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitGrid());
  }

  // ── Interaction ──────────────────────────────────────────────────────────────

  void _onCellTap(int r, int c) {
    final p = _puzzle;
    if (p == null) return;

    HapticFeedback.selectionClick();
    final wordsHere = [
      for (int i = 0; i < p.words.length; i++)
        if (p.words[i].contains(r, c)) i,
    ];
    if (wordsHere.isEmpty) return;

    if (wordsHere.length == 1 || !wordsHere.contains(_selectedWordIdx)) {
      _selectWord(wordsHere.first, r, c);
    } else {
      final other = wordsHere.firstWhere((i) => i != _selectedWordIdx);
      _selectWord(other, r, c);
    }
  }

  void _selectWord(int idx, int r, int c) {
    final w = _puzzle!.words[idx];
    setState(() {
      _selectedWordIdx = idx;
      _cursorInWord = w.indexAt(r, c);
    });
  }

  void _onLetter(String letter) {
    final p = _puzzle;
    final w = _selectedWord;
    if (p == null || w == null || _complete) return;

    final ci = _cursorInWord.clamp(0, w.text.length - 1);
    setState(() {
      _guesses[w.cells[ci]] = letter;
      if (ci < w.text.length - 1) _cursorInWord = ci + 1;
    });
    _checkComplete();
  }

  void _onDelete() {
    final w = _selectedWord;
    if (w == null) return;
    final ci = _cursorInWord.clamp(0, w.text.length - 1);
    setState(() {
      if (_guesses.containsKey(w.cells[ci])) {
        _guesses.remove(w.cells[ci]);
      } else if (ci > 0) {
        _cursorInWord = ci - 1;
        _guesses.remove(w.cells[_cursorInWord]);
      }
    });
  }

  void _checkComplete() {
    final p = _puzzle;
    if (p == null) return;
    if (p.letters.entries.every((e) => _guesses[e.key] == e.value)) {
      setState(() => _complete = true);
      HapticFeedback.mediumImpact();
      _submitScore();
    }
  }

  _Word? get _selectedWord => _selectedWordIdx >= 0 && _puzzle != null
      ? _puzzle!.words[_selectedWordIdx]
      : null;

  (int, int)? get _activeCell {
    final w = _selectedWord;
    if (w == null) return null;
    return w.cells[_cursorInWord.clamp(0, w.text.length - 1)];
  }

  int get _correctWordCount {
    final p = _puzzle;
    if (p == null) return 0;
    return p.words
        .where((w) => w.cells.every((c) => _guesses[c] == p.letters[c]))
        .length;
  }

  Future<void> _submitScore() async {
    final uuid = ref.read(storageServiceProvider).playerUuid;
    if (uuid == null) return;
    try {
      await ref.read(apiServiceProvider).submitScore(
        playerUuid: uuid,
        gameType: 'krosword',
        won: true,
        wrongGuesses: 0,
      );
      ref.read(playerProvider.notifier).refresh();
    } catch (_) {}
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final wordsAsync = ref.watch(allWordsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Krosword'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_puzzle != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '$_correctWordCount / ${_puzzle!.words.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: wordsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) =>
            _ErrorView(onRetry: () => ref.invalidate(allWordsProvider)),
        data: (words) {
          if (!_started) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (!_puzzleBuilt) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _buildPuzzle(words));
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (_puzzle == null) {
            return _ErrorView(onRetry: () => _newGame(words));
          }
          if (_complete) return _buildComplete(words);
          return _buildGame(words);
        },
      ),
    );
  }

  Widget _buildGame(List<WordModel> words) {
    final p = _puzzle!;
    final selWord = _selectedWord;
    final ac = _activeCell;
    final selectedCells = selWord?.cells.toSet() ?? <(int, int)>{};

    return Column(
      children: [
        // ── Grid ────────────────────────────────────────────────────────────
        Expanded(
          child: LayoutBuilder(
            builder: (_, box) {
              _viewportSize = box.biggest;
              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2A2850), Color(0xFF3F3C92)],
                  ),
                ),
                child: InteractiveViewer(
                  transformationController: _transformCtrl,
                  constrained: false,
                  minScale: 0.3,
                  maxScale: 3.5,
                  boundaryMargin: const EdgeInsets.all(double.infinity),
                  child: SizedBox(
                    width: _kGS * _kCS,
                    height: _kGS * _kCS,
                    child: Stack(
                      children: [
                        // Background tap → deselect word / dismiss keyboard
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () =>
                              setState(() => _selectedWordIdx = -1),
                          child: const SizedBox.expand(),
                        ),
                        // Letter cells
                        for (final entry in p.letters.entries)
                          Positioned(
                            left: entry.key.$2 * _kCS + 2,
                            top: entry.key.$1 * _kCS + 2,
                            width: _kCS - 4,
                            height: _kCS - 4,
                            child: _LetterCell(
                              clueNum: p.numbers[entry.key],
                              guess: _guesses[entry.key] ?? '',
                              correct: entry.value,
                              isActive: entry.key == ac,
                              isSelected: selectedCells.contains(entry.key),
                              onTap: () =>
                                  _onCellTap(entry.key.$1, entry.key.$2),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // ── Clue bar ──────────────────────────────────────────────────────
        if (selWord != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: const Border(
                  top: BorderSide(color: AppColors.border, width: 1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(2),
                      bottomRight: Radius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${selWord.num}${selWord.across ? 'A' : 'D'}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selWord.hint.isNotEmpty ? selWord.hint : '— — —',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

        // ── Keyboard ────────────────────────────────────────────────────────
        if (selWord != null)
          _CrosswordKeyboard(onLetter: _onLetter, onDelete: _onDelete),

        const BannerAdWidget(),
        SizedBox(height: MediaQuery.of(context).padding.bottom),
      ],
    );
  }

  Widget _buildComplete(List<WordModel> words) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 80)),
          const SizedBox(height: 20),
          const Text(
            'Krosword çözüldi!',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_puzzle!.words.length} söz',
            style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _newGame(words),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text(
                'Täze krosword',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Letter cell tile (Dilbil-inspired) ─────────────────────────────────────────

class _LetterCell extends StatelessWidget {
  final int? clueNum;
  final String guess;
  final String correct;
  final bool isActive;
  final bool isSelected;
  final VoidCallback onTap;

  const _LetterCell({
    required this.clueNum,
    required this.guess,
    required this.correct,
    required this.isActive,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCorrect = guess.isNotEmpty && guess == correct;

    // Colors inspired by Dilbil: warm yellows for correct, white for empty
    Color bg;
    Color textColor;
    Color numColor;
    List<BoxShadow> shadows;

    if (isActive) {
      bg = AppColors.primary;
      textColor = Colors.white;
      numColor = Colors.white.withOpacity(0.65);
      shadows = [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.45),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];
    } else if (isSelected) {
      bg = const Color(0xFFEEEDFE); // light purple
      textColor = const Color(0xFF2A2850);
      numColor = AppColors.primary;
      shadows = [
        BoxShadow(
          color: Colors.black.withOpacity(0.12),
          blurRadius: 3,
          offset: const Offset(0, 1.5),
        ),
      ];
    } else if (isCorrect) {
      bg = const Color(0xFFFFF3C0); // warm yellow like Dilbil correct
      textColor = const Color(0xFF7A5C00);
      numColor = const Color(0xFFB88000).withOpacity(0.8);
      shadows = [
        BoxShadow(
          color: Colors.black.withOpacity(0.10),
          blurRadius: 3,
          offset: const Offset(0, 1.5),
        ),
      ];
    } else {
      bg = Colors.white.withOpacity(0.93);
      textColor = const Color(0xFF2A2850);
      numColor = AppColors.primary;
      shadows = [
        BoxShadow(
          color: Colors.black.withOpacity(0.18),
          blurRadius: 3,
          offset: const Offset(0, 1.5),
        ),
      ];
    }

    const tileSize = _kCS - 4;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(7),
          boxShadow: shadows,
        ),
        child: Stack(
          children: [
            // Clue number — top-left; hidden once a letter is guessed
            if (clueNum != null && guess.isEmpty)
              Positioned(
                left: 2,
                top: 2,
                right: 2,
                child: Text(
                  '$clueNum',
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.w900,
                    color: numColor,
                    height: 1.0,
                  ),
                ),
              ),
            // Guessed letter — centered
            if (guess.isNotEmpty)
              Center(
                child: Text(
                  guess,
                  style: TextStyle(
                    fontSize: tileSize * 0.52,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    height: 1.0,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Keyboard ───────────────────────────────────────────────────────────────────

class _CrosswordKeyboard extends StatelessWidget {
  final void Function(String) onLetter;
  final VoidCallback onDelete;

  const _CrosswordKeyboard({required this.onLetter, required this.onDelete});

  static const _rows = [
    ['Ä', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
    ['Ö', 'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
    ['Ň', 'Ş', 'Z', 'Ü', 'Ç', 'Ý', 'B', 'N', 'M', 'Ž'],
    ['C', 'V', 'X', 'Q', '⌫'],
  ];

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final keyW = (screenW - 56) / 10;
    final keyH = keyW * 1.22;

    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _rows.map((row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.map((key) {
                final isDel = key == '⌫';
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    isDel ? onDelete() : onLetter(key);
                  },
                  child: Container(
                    width: isDel ? keyW * 2.0 : keyW,
                    height: keyH,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isDel
                          ? AppColors.surfaceSecondary
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        key,
                        style: TextStyle(
                          fontSize: isDel ? keyW * 0.44 : keyW * 0.38,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Error view ─────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('😕', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          const Text('Krosword düzülmedi',
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Gaýtadan synanyş',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
