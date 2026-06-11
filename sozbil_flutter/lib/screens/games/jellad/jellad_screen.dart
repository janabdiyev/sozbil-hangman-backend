import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/rewarded_ad_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/widgets/banner_ad_widget.dart';
import '../../../models/word.dart';
import '../../../providers/app_providers.dart';
import 'hangman_painter.dart';
import 'turkmen_keyboard.dart';

class JelladScreen extends ConsumerStatefulWidget {
  const JelladScreen({super.key});

  @override
  ConsumerState<JelladScreen> createState() => _JelladScreenState();
}

class _JelladScreenState extends ConsumerState<JelladScreen>
    with SingleTickerProviderStateMixin {
  WordModel? _word;
  final Map<String, LetterState> _letterStates = {};
  int _wrongGuesses = 0;
  bool _gameOver = false;
  bool _won = false;
  bool _loading = true;
  String? _errorMessage;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  final _rewardedAd = RewardedAdService();

  static const _maxWrong = 6;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnimation = Tween(begin: 0.0, end: 8.0)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);
    _rewardedAd.load();
    _loadWord();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _rewardedAd.dispose();
    super.dispose();
  }

  Future<void> _loadWord() async {
    final storage = ref.read(storageServiceProvider);
    final api = ref.read(apiServiceProvider);

    if (!storage.canPlay(storage.isSubscribed, ApiConstants.dailyFreeGames)) {
      _autoShowRewardedAd();
      return;
    }

    setState(() { _loading = true; _errorMessage = null; });

    try {
      WordModel word;
      final usedWords = storage.getUsedWords();
      int retries = 0;

      do {
        word = await api.getRandomWord();
        retries++;
        if (retries > 40) { storage.clearUsedWords(); break; }
      } while (usedWords.contains(word.word.toLowerCase()));

      storage.addUsedWord(word.word);
      storage.consumeGame(storage.isSubscribed);
      ref.read(gameLimitProvider.notifier).refresh();

      setState(() {
        _word = word;
        _letterStates.clear();
        _wrongGuesses = 0;
        _gameOver = false;
        _won = false;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Internet ýok. Gaýtadan synanyş.';
        _loading = false;
      });
    }
  }

  void _guessLetter(String letter) {
    if (_gameOver || _letterStates.containsKey(letter)) return;
    final word = _word!.word;
    final isCorrect = word.contains(letter);

    setState(() {
      _letterStates[letter] = isCorrect ? LetterState.correct : LetterState.wrong;
      if (!isCorrect) {
        _wrongGuesses++;
        _shakeController.forward(from: 0);
      }
    });

    _checkGameOver();
  }

  void _checkGameOver() {
    final word = _word!.word;
    final won = word.split('').every(
      (c) => c == ' ' || c == '-' || c == "'" || _letterStates[c] == LetterState.correct,
    );
    final lost = _wrongGuesses >= _maxWrong;

    if (won || lost) {
      setState(() { _gameOver = true; _won = won; });
      _submitScore();
    }
  }

  Future<void> _submitScore() async {
    final uuid = ref.read(storageServiceProvider).playerUuid;
    if (uuid == null) return;
    try {
      final result = await ref.read(apiServiceProvider).submitScore(
        playerUuid: uuid,
        gameType: 'jellad',
        wordId: _word?.id,
        won: _won,
        wrongGuesses: _wrongGuesses,
      );
      if (_won) {
        await ref.read(playerProvider.notifier).refresh();
        if (mounted) _showWinDialog(result.score, result.xpGained);
      }
    } catch (_) {}
  }

  void _showWinDialog(int score, int xp) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ResultDialog(
        won: true,
        word: _word!.word,
        score: score,
        xpGained: xp,
        wrongGuesses: _wrongGuesses,
        onPlayAgain: () { Navigator.pop(context); _loadWord(); },
        onShare: _shareResult,
      ),
    );
  }

  void _shareResult() {
    final word = _word?.word ?? '';
    final attempts = _wrongGuesses;
    final blocks = List.generate(6, (i) => i < (_maxWrong - attempts) ? '🟩' : '⬛').join();
    Share.share(
      'Sözbil — Jellad\n$blocks\n$attempts ýalňyş bilen "$word" bildim!\nSiz hem oýnaň 🎮',
    );
  }

  void _autoShowRewardedAd() {
    _rewardedAd.show(
      onRewarded: () {
        final storage = ref.read(storageServiceProvider);
        storage.addRewardGames(ApiConstants.gamesPerAd, ApiConstants.gamesPerAd);
        ref.read(gameLimitProvider.notifier).refresh();
        _loadWord();
      },
      onFailed: () {
        if (mounted) Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Jellad'),
        backgroundColor: AppColors.surface,
        actions: [
          if (!_loading && !_gameOver)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  '${_maxWrong - _wrongGuesses}/$_maxWrong',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _wrongGuesses >= 4 ? AppColors.error : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMessage != null
              ? _ErrorView(message: _errorMessage!, onRetry: _loadWord)
              : _buildGame(isTablet),
    );
  }

  Widget _buildGame(bool isTablet) {
    final screenH = MediaQuery.of(context).size.height;
    final hangmanH = isTablet ? screenH * 0.4 : screenH * 0.32;

    return Column(
      children: [
        // Hangman drawing
        AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (_, child) => Transform.translate(
            offset: Offset(_shakeAnimation.value * (_wrongGuesses.isEven ? 1 : -1), 0),
            child: child,
          ),
          child: Container(
            height: hangmanH,
            margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: CustomPaint(
              painter: HangmanPainter(wrongGuesses: _wrongGuesses),
              child: Container(),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Word display
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _WordDisplay(word: _word!.word, letterStates: _letterStates, revealed: _gameOver),
        ),

        const SizedBox(height: 8),

        // Hint
        if (_word!.hint.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Ýardam: ${_word!.hint}',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),

        const Spacer(),

        // Game over banner
        if (_gameOver)
          _GameOverBanner(
            won: _won,
            word: _word!.word,
            onPlayAgain: _loadWord,
            onShare: _won ? _shareResult : null,
          ),

        if (!_gameOver) const SizedBox(height: 4),

        // Keyboard
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          child: TurkmenKeyboard(
            letterStates: _letterStates,
            onLetterTap: _guessLetter,
            disabled: _gameOver,
          ),
        ),

        // Banner ad
        const BannerAdWidget(),
        SizedBox(height: MediaQuery.of(context).padding.bottom),
      ],
    );
  }
}

// ── Word display ───────────────────────────────────────────────────────────────

class _WordDisplay extends StatelessWidget {
  final String word;
  final Map<String, LetterState> letterStates;
  final bool revealed;

  const _WordDisplay({required this.word, required this.letterStates, required this.revealed});

  @override
  Widget build(BuildContext context) {
    final letters = word.split('');
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 4,
      runSpacing: 6,
      children: letters.map((c) {
        if (c == ' ') return const SizedBox(width: 16);
        final isRevealed = c == '-' || c == "'" ||
            letterStates[c] == LetterState.correct || revealed;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isRevealed ? c : ' ',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: revealed && letterStates[c] != LetterState.correct && c != '-' && c != "'"
                    ? AppColors.error
                    : AppColors.textPrimary,
              ),
            ),
            Container(height: 2, width: 20,
                color: isRevealed ? AppColors.primary : AppColors.border),
          ],
        );
      }).toList(),
    );
  }
}

// ── Game over banner ───────────────────────────────────────────────────────────

class _GameOverBanner extends StatelessWidget {
  final bool won;
  final String word;
  final VoidCallback onPlayAgain;
  final VoidCallback? onShare;

  const _GameOverBanner({
    required this.won, required this.word,
    required this.onPlayAgain, this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: won ? AppColors.successLight : AppColors.errorLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: won ? AppColors.success : AppColors.error, width: 0.5),
      ),
      child: Row(
        children: [
          Text(won ? '🎉' : '☠️', style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  won ? 'Bildiň! Berekella!' : 'Bilmediň!',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                      color: won ? AppColors.success : AppColors.error),
                ),
                if (!won)
                  Text('Söz: $word',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (won && onShare != null)
            IconButton(
              onPressed: onShare,
              icon: const Icon(Icons.share_outlined, size: 20, color: AppColors.success),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          const SizedBox(width: 6),
          ElevatedButton(
            onPressed: onPlayAgain,
            style: ElevatedButton.styleFrom(
              backgroundColor: won ? AppColors.success : AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            child: const Text('Gaýtadan'),
          ),
        ],
      ),
    );
  }
}

// ── Result dialog ──────────────────────────────────────────────────────────────

class _ResultDialog extends StatelessWidget {
  final bool won;
  final String word;
  final int score;
  final int xpGained;
  final int wrongGuesses;
  final VoidCallback onPlayAgain;
  final VoidCallback onShare;

  const _ResultDialog({
    required this.won, required this.word, required this.score,
    required this.xpGained, required this.wrongGuesses,
    required this.onPlayAgain, required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(won ? '🎉 Bildiň!' : '☠️ Bilmediň!',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Söz: $word', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatChip(label: 'Bal', value: '$score'),
              _StatChip(label: 'XP', value: '+$xpGained'),
              _StatChip(label: 'Ýalňyş', value: '$wrongGuesses'),
            ],
          ),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: onShare,
          icon: const Icon(Icons.share_outlined, size: 18),
          label: const Text('Paýlaş'),
        ),
        ElevatedButton(
          onPressed: onPlayAgain,
          child: const Text('Gaýtadan oýna'),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('😕', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: onRetry, child: const Text('Gaýtadan synanyş')),
        ],
      ),
    );
  }
}
