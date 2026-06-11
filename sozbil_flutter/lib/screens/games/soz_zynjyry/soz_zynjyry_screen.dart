import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/rewarded_ad_service.dart';
import '../../../core/widgets/banner_ad_widget.dart';
import '../../../providers/app_providers.dart';


class SozZynjyryScreen extends ConsumerStatefulWidget {
  const SozZynjyryScreen({super.key});

  @override
  ConsumerState<SozZynjyryScreen> createState() => _SozZynjyryScreenState();
}

class _SozZynjyryScreenState extends ConsumerState<SozZynjyryScreen> {
  static const _turnSeconds = 30;
  static const _maxLives = 3;

  Set<String> _pool = {};
  final Set<String> _usedWords = {};
  final _rewardedAd = RewardedAdService();
  final List<String> _chain = [];
  String _currentInput = '';
  String _requiredLetter = '';
  int _lives = _maxLives;
  int _timeLeft = _turnSeconds;
  bool _gameStarted = false;
  bool _gameOver = false;
  String? _errorMsg;
  Timer? _timer;
  late final Future<Set<String>> _dictFuture;

  @override
  void initState() {
    super.initState();
    _rewardedAd.load();
    _dictFuture = _loadDictionary();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _rewardedAd.dispose();
    super.dispose();
  }

  void _startGame(Set<String> pool) {
    if (pool.isEmpty) return;
    _pool = pool;
    final wordList = pool.toList()..shuffle();
    final startWord = wordList.first;
    _usedWords.add(startWord);
    _chain.add(startWord);
    _requiredLetter = startWord[startWord.length - 1];
    _lives = _maxLives;
    _timeLeft = _turnSeconds;
    _gameStarted = true;
    _gameOver = false;
    _currentInput = '';
    _startTimer();
    setState(() {});
  }

  void _startTimer() {
    _timer?.cancel();
    _timeLeft = _turnSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _timeLeft--;
        if (_timeLeft <= 0) {
          t.cancel();
          _loseLife('Wagt geçdi!');
        }
      });
    });
  }

  void _loseLife(String reason) {
    HapticFeedback.mediumImpact();
    setState(() {
      _lives--;
      _errorMsg = reason;
      _currentInput = '';
    });
    if (_lives <= 0) {
      _endGame();
    } else {
      _startTimer();
    }
  }

  void _endGame() {
    _timer?.cancel();
    setState(() { _gameOver = true; });
    _submitScore();
  }

  Future<void> _submitScore() async {
    final uuid = ref.read(storageServiceProvider).playerUuid;
    if (uuid == null) return;
    try {
      await ref.read(apiServiceProvider).submitScore(
        playerUuid: uuid,
        gameType: 'soz_zynjyry',
        won: _chain.length > 3,
        wrongGuesses: _maxLives - _lives,
      );
      ref.read(playerProvider.notifier).refresh();
    } catch (_) {}
  }

  void _typeLetter(String letter) {
    if (_gameOver || !_gameStarted) return;
    setState(() {
      _errorMsg = null;
      _currentInput += letter;
    });
  }

  void _deleteLetter() {
    if (_currentInput.isEmpty) return;
    setState(() {
      _currentInput = _currentInput.substring(0, _currentInput.length - 1);
    });
  }

  void _submitWord() {
    final word = _currentInput.trim().toUpperCase();
    if (word.isEmpty) return;

    // must start with required letter
    if (word[0] != _requiredLetter) {
      HapticFeedback.lightImpact();
      setState(() { _errorMsg = '"$_requiredLetter" bilen başlamaly!'; _currentInput = ''; });
      return;
    }

    // must be in pool
    final match = _pool.contains(word);
    if (!match) {
      HapticFeedback.lightImpact();
      setState(() { _errorMsg = 'Söz tapylmady!'; _currentInput = ''; });
      return;
    }

    // must not be used
    if (_usedWords.contains(word)) {
      HapticFeedback.lightImpact();
      setState(() { _errorMsg = 'Bu söz eýýäm ulanyldı!'; _currentInput = ''; });
      return;
    }

    // valid!
    HapticFeedback.selectionClick();
    _timer?.cancel();
    _usedWords.add(word);
    _chain.add(word);
    final newRequired = word[word.length - 1];

    setState(() {
      _requiredLetter = newRequired;
      _currentInput = '';
      _errorMsg = null;
    });
    _startTimer();
  }

  Future<Set<String>> _loadDictionary() async {
    final text = await rootBundle.loadString('assets/words/turkmen_dict.txt');
    return text
        .split('\n')
        .map((w) => w.trim().toUpperCase())
        .where((w) => w.length >= 2)
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Söz Zynjyry'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          if (_gameStarted && !_gameOver)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: List.generate(_maxLives, (i) => Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    i < _lives ? Icons.favorite : Icons.favorite_border,
                    size: 18,
                    color: i < _lives ? AppColors.error : AppColors.borderLight,
                  ),
                )),
              ),
            ),
        ],
      ),
      body: FutureBuilder<Set<String>>(
        future: _dictFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final words = snap.data ?? {};
          if (_gameOver) {
            return _GameOverView(
              chain: _chain,
              onRestart: () {
                _usedWords.clear();
                _chain.clear();
                _startGame(words);
              },
            );
          }
          if (_gameStarted) return _buildGame();
          return _StartView(onStart: () {
            final storage = ref.read(storageServiceProvider);
            if (!storage.canPlay(storage.isSubscribed, ApiConstants.dailyFreeGames)) {
              _rewardedAd.show(
                onRewarded: () {
                  storage.addRewardGames(ApiConstants.gamesPerAd, ApiConstants.gamesPerAd);
                  storage.consumeGame(storage.isSubscribed);
                  ref.read(gameLimitProvider.notifier).refresh();
                  _startGame(words);
                },
                onFailed: () {
                  if (mounted) Navigator.pop(context);
                },
              );
              return;
            }
            storage.consumeGame(storage.isSubscribed);
            ref.read(gameLimitProvider.notifier).refresh();
            _startGame(words);
          });
        },
      ),
    );
  }

  Widget _buildGame() {
    final timerColor = _timeLeft <= 10 ? AppColors.error : AppColors.success;

    return Column(
      children: [
        // Timer bar
        LinearProgressIndicator(
          value: _timeLeft / _turnSeconds,
          backgroundColor: AppColors.surfaceSecondary,
          valueColor: AlwaysStoppedAnimation(timerColor),
          minHeight: 3,
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              children: [
                // Chain display
                Expanded(
                  child: _chain.length <= 1
                      ? Center(
                          child: Text(
                            'Taýýar!',
                            style: TextStyle(fontSize: 16, color: AppColors.textHint),
                          ),
                        )
                      : ListView.builder(
                          reverse: true,
                          itemCount: _chain.length - 1,
                          itemBuilder: (_, i) {
                            final word = _chain[_chain.length - 1 - i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.04),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      word,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${word[word.length - 1]} →',
                                    style: const TextStyle(fontSize: 13, color: AppColors.textHint),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),

                // Required letter + timer
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Text(
                        '"$_requiredLetter" bilen başla',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      // Current input display
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _currentInput.isNotEmpty
                                ? AppColors.primary
                                : AppColors.borderLight,
                            width: _currentInput.isNotEmpty ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              _currentInput.isEmpty ? '$_requiredLetter...' : _currentInput,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: _currentInput.isEmpty
                                    ? AppColors.textHint
                                    : AppColors.textPrimary,
                                letterSpacing: 2,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '$_timeLeft',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: timerColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_errorMsg != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _errorMsg!,
                          style: const TextStyle(fontSize: 13, color: AppColors.error, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Keyboard
        _WordKeyboard(
          onLetter: _typeLetter,
          onDelete: _deleteLetter,
          onSubmit: _submitWord,
        ),
        const BannerAdWidget(),
        SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
      ],
    );
  }
}

// ── Start view ─────────────────────────────────────────────────────────────────

class _StartView extends StatelessWidget {
  final VoidCallback onStart;
  const _StartView({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔗', style: TextStyle(fontSize: 72)),
          const SizedBox(height: 24),
          const Text(
            'Söz Zynjyry',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          const Text(
            'Her söz öňki sözüň\nsoňky harpy bilen başlamaly.',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            '3 ❤️ • 30 sekunt',
            style: TextStyle(fontSize: 14, color: AppColors.textHint, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onStart,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Başla', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Game over view ─────────────────────────────────────────────────────────────

class _GameOverView extends StatelessWidget {
  final List<String> chain;
  final VoidCallback onRestart;
  const _GameOverView({required this.chain, required this.onRestart});

  @override
  Widget build(BuildContext context) {
    final score = (chain.length - 1) * 10;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(chain.length > 4 ? '🏆' : '😔', style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 20),
          Text(
            chain.length > 4 ? 'Ajaýyp!' : 'Oýun gutardy',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Stat(label: 'Zynjyr', value: '${chain.length - 1}'),
              const SizedBox(width: 32),
              _Stat(label: 'Bal', value: '$score'),
            ],
          ),
          const SizedBox(height: 24),
          if (chain.length > 1) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: chain.skip(1).map((w) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(w, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                )).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onRestart,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Gaýtadan', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  const _Stat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.primary)),
      Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
    ],
  );
}

// ── Word keyboard ──────────────────────────────────────────────────────────────

class _WordKeyboard extends StatelessWidget {
  final void Function(String) onLetter;
  final VoidCallback onDelete;
  final VoidCallback onSubmit;

  const _WordKeyboard({required this.onLetter, required this.onDelete, required this.onSubmit});

  static const _rows = [
    ['Ä','W','E','R','T','Y','U','I','O','P'],
    ['Ö','A','S','D','F','G','H','J','K','L'],
    ['Ň','Ş','Z','Ü','Ç','Ý','B','N','M','Ž'],
    ['⌫','C','V','X','Q','✓'],
  ];

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final keyW = (screenW - 56) / 10;
    final keyH = keyW * 1.22;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _rows.map((row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.map((key) {
                final isDelete = key == '⌫';
                final isSubmit = key == '✓';
                final isSpecial = isDelete || isSubmit;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    if (isDelete) onDelete();
                    else if (isSubmit) onSubmit();
                    else onLetter(key);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 80),
                    width: isSpecial ? keyW * 1.5 : keyW,
                    height: keyH,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isSubmit
                          ? AppColors.primary
                          : isDelete
                              ? AppColors.surfaceSecondary
                              : AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        key,
                        style: TextStyle(
                          fontSize: isSpecial ? keyW * 0.42 : keyW * 0.38,
                          fontWeight: isSubmit ? FontWeight.w700 : FontWeight.w600,
                          color: isSubmit ? Colors.white : AppColors.textPrimary,
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
