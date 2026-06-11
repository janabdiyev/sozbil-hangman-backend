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
const _kGS = 15; // grid size (15×15)
const _kCS = 36.0; // cell size px
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

    // raw[r][c] = letter placed there (null = empty/black)
    final raw = List.generate(_kGS, (_) => List<String?>.filled(_kGS, null));
    // Track which direction(s) occupy each cell — prevents parallel word overlap
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

  /// Standard crossword placement rules:
  /// 1. Word must fit within the grid bounds.
  /// 2. No letter immediately before the start or after the end (no extensions).
  /// 3. Every occupied cell either matches the existing letter exactly (intersection)
  ///    OR is empty with no adjacent parallel letters (no touching parallel words).
  /// 4. An intersection is only valid if the existing letter was placed by a word
  ///    going in the OPPOSITE direction — two parallel words may never share a cell,
  ///    even when letters match.
  /// 5. Must have at least one intersection with an existing word.
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

    // ── Bounds ────────────────────────────────────────────────────────────────
    if (across) {
      if (r0 < 0 || r0 >= _kGS || c0 < 0 || c0 + len > _kGS) return false;
      // No extension: cells immediately before/after must be empty
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
        // Cell already has a letter — must be an exact match
        if (ex != word[i]) return false;

        // ── Rule 4: parallel overlap is illegal ──────────────────────────────
        // The existing letter must have been placed by a word going the OTHER
        // direction. If a same-direction word already owns this cell, reject.
        if (across && acrossSet.contains((r, c))) return false;
        if (!across && downSet.contains((r, c))) return false;

        intersections++;
      } else {
        // ── Rule 3: no adjacent parallel words touching ──────────────────────
        // For a horizontal word, the cells directly above and below each
        // non-intersection cell must be empty (otherwise we'd create two
        // parallel horizontal words that share a row without crossing).
        // For a vertical word, check left and right.
        if (across) {
          if (r > 0 && raw[r - 1][c] != null) return false;
          if (r + 1 < _kGS && raw[r + 1][c] != null) return false;
        } else {
          if (c > 0 && raw[r][c - 1] != null) return false;
          if (c + 1 < _kGS && raw[r][c + 1] != null) return false;
        }
      }
    }

    // Must cross at least one existing word
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
          onFailed: () {
            if (mounted) Navigator.pop(context);
          },
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

  void _fitGrid() {
    if (!mounted) return;
    // Use more margin so the grid edges don't touch the screen
    final availW = MediaQuery.of(context).size.width - 64;
    final scale = (availW / (_kGS * _kCS)).clamp(0.4, 1.2);
    _transformCtrl.value = Matrix4.identity()..scale(scale);
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

  void _onTap(TapUpDetails d) {
    final p = _puzzle;
    if (p == null) return;
    final r = (d.localPosition.dy / _kCS).floor();
    final c = (d.localPosition.dx / _kCS).floor();
    if (r < 0 || r >= _kGS || c < 0 || c >= _kGS) return;
    if (!p.letters.containsKey((r, c))) return;

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
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
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
    final w = _selectedWord;
    final ac = _activeCell;

    return Column(
      children: [
        // ── Grid ──────────────────────────────────────────────────────────────
        Expanded(
          child: Container(
            color: AppColors.background,
            child: InteractiveViewer(
              transformationController: _transformCtrl,
              minScale: 0.3,
              maxScale: 3.0,
              boundaryMargin: const EdgeInsets.all(80),
              child: Center(
                child: GestureDetector(
                  onTapUp: _onTap,
                  child: CustomPaint(
                    size: const Size(_kGS * _kCS, _kGS * _kCS),
                    painter: _GridPainter(
                      puzzle: _puzzle!,
                      guesses: Map.of(_guesses),
                      selectedCells: w?.cells.toSet() ?? {},
                      activeCell: ac,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── Clue bar ───────────────────────────────────────────────────────────
        if (w != null)
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
                // Colored left accent strip
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
                    '${w.num}${w.across ? 'A' : 'D'}',
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
                    w.hint.isNotEmpty ? w.hint : '— — —',
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

        // ── Keyboard ──────────────────────────────────────────────────────────
        if (w != null)
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
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
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

// ── Grid painter ───────────────────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  final _Puzzle puzzle;
  final Map<(int, int), String> guesses;
  final Set<(int, int)> selectedCells;
  final (int, int)? activeCell;

  const _GridPainter({
    required this.puzzle,
    required this.guesses,
    required this.selectedCells,
    this.activeCell,
  });

  // Deep purple for black (blocked) cells — matches app primary colour family
  static const _kBlack = Color(0xFF2A2850);
  // Grid line colour — subtle warm grey
  static const _kGrid = Color(0xFFD3D1C7);

  @override
  void paint(Canvas canvas, Size size) {
    const cs = _kCS;
    final fill = Paint();
    final stroke = Paint()
      ..color = _kGrid
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;

    for (int r = 0; r < _kGS; r++) {
      for (int c = 0; c < _kGS; c++) {
        final pos = (r, c);
        final rect = Rect.fromLTWH(c * cs, r * cs, cs, cs);

        if (!puzzle.letters.containsKey(pos)) {
          fill.color = _kBlack;
          canvas.drawRect(rect, fill);
          continue;
        }

        final guess = guesses[pos] ?? '';
        final correct = puzzle.letters[pos]!;

        Color bg;
        if (pos == activeCell) {
          bg = AppColors.primary.withOpacity(0.40);
        } else if (selectedCells.contains(pos)) {
          bg = const Color(0xFFEEEDFE); // primaryLight
        } else if (guess.isNotEmpty && guess == correct) {
          bg = AppColors.successLight;
        } else {
          bg = Colors.white;
        }

        fill.color = bg;
        canvas.drawRect(rect, fill);
        canvas.drawRect(rect, stroke);

        // Clue number — purple for visibility
        final num = puzzle.numbers[pos];
        if (num != null) {
          _text(canvas, '$num', Offset(c * cs + 2.5, r * cs + 1.5), 9,
              AppColors.primary, FontWeight.w700);
        }

        // Guessed letter
        if (guess.isNotEmpty) {
          _text(
            canvas,
            guess,
            Offset(c * cs + cs / 2, r * cs + cs / 2 + 1),
            cs * 0.50,
            guess == correct ? AppColors.success : AppColors.textPrimary,
            FontWeight.w800,
            center: true,
          );
        }
      }
    }

    // Outer border — matches the deep purple theme
    final outerPaint = Paint()
      ..color = _kBlack
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, _kGS * cs, _kGS * cs),
      outerPaint,
    );
  }

  void _text(Canvas canvas, String s, Offset pos, double size, Color color,
      FontWeight weight, {bool center = false}) {
    final tp = TextPainter(
      text: TextSpan(
          text: s,
          style: TextStyle(fontSize: size, color: color, fontWeight: weight)),
      textDirection: TextDirection.ltr,
    )..layout();
    final p = center
        ? Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2)
        : pos;
    tp.paint(canvas, p);
  }

  @override
  bool shouldRepaint(_GridPainter old) =>
      old.guesses != guesses ||
      old.selectedCells != selectedCells ||
      old.activeCell != activeCell;
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
              onPressed: onRetry, child: const Text('Gaýtadan synanyş')),
        ],
      ),
    );
  }
}
