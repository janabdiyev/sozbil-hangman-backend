import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/rewarded_ad_service.dart';
import '../../../core/widgets/banner_ad_widget.dart';
import '../../../providers/app_providers.dart';

// ── All pairs (12 pairs = 24 cards = 6 rows × 4) ──────────────────────────────
const _allPairs = [
  ('🦅', 'BÜRGÜT'),
  ('☀️', 'GÜN'),
  ('🏔️', 'DAG'),
  ('🌹', 'GÜL'),
  ('🌊', 'TOLKUN'),
  ('⭐', 'ÝYLDYZ'),
  ('💧', 'SUW'),
  ('🏠', 'ÖÝ'),
  ('🦁', 'ARYSLAN'),
  ('🌲', 'AGAÇ'),
  ('🐟', 'BALYK'),
  ('🔥', 'ALAW'),
];

class YatkeslikScreen extends ConsumerStatefulWidget {
  const YatkeslikScreen({super.key});

  @override
  ConsumerState<YatkeslikScreen> createState() => _YatkeslikScreenState();
}

class _YatkeslikScreenState extends ConsumerState<YatkeslikScreen> {
  late List<_Card> _cards;
  List<int> _flipped = [];
  Set<int> _matched = {};
  bool _checking = false;
  int _moves = 0;
  int _seconds = 0;
  Timer? _timer;
  bool _gameStarted = false;
  bool _gameOver = false;
  bool _awaitingAdGate = false;
  final _rewardedAd = RewardedAdService();

  @override
  void initState() {
    super.initState();
    _rewardedAd.load();
    _checkAndInit();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _rewardedAd.dispose();
    super.dispose();
  }

  void _checkAndInit() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final storage = ref.read(storageServiceProvider);
      if (!storage.canPlay(storage.isSubscribed, ApiConstants.dailyFreeGames)) {
        _rewardedAd.show(
          onRewarded: () {
            storage.addRewardGames(ApiConstants.gamesPerAd, ApiConstants.gamesPerAd);
            storage.consumeGame(storage.isSubscribed);
            ref.read(gameLimitProvider.notifier).refresh();
            setState(() => _awaitingAdGate = false);
            _initGame();
          },
          onFailed: () {
            if (mounted) Navigator.pop(context);
          },
        );
        return;
      }
      storage.consumeGame(storage.isSubscribed);
      ref.read(gameLimitProvider.notifier).refresh();
      _initGame();
    });
  }

  void _initGame() {
    // Use all 12 pairs
    final pairs = List.of(_allPairs)..shuffle();
    final cards = <_Card>[];
    for (int i = 0; i < pairs.length; i++) {
      cards.add(_Card(id: i * 2,     pairId: i, isEmoji: true,  emoji: pairs[i].$1, word: pairs[i].$2));
      cards.add(_Card(id: i * 2 + 1, pairId: i, isEmoji: false, emoji: pairs[i].$1, word: pairs[i].$2));
    }
    cards.shuffle();

    setState(() {
      _cards = cards;
      _flipped = [];
      _matched = {};
      _checking = false;
      _moves = 0;
      _seconds = 0;
      _gameStarted = false;
      _gameOver = false;
    });
    _timer?.cancel();
  }

  void _startTimerIfNeeded() {
    if (_gameStarted) return;
    _gameStarted = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  void _flipCard(int index) {
    if (_checking) return;
    if (_matched.contains(index)) return;
    if (_flipped.contains(index)) return;
    if (_flipped.length >= 2) return;

    HapticFeedback.selectionClick();
    _startTimerIfNeeded();

    setState(() {
      _flipped = [..._flipped, index];
      _moves++;
    });

    if (_flipped.length == 2) {
      _checking = true;
      final a = _cards[_flipped[0]];
      final b = _cards[_flipped[1]];

      Future.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        if (a.pairId == b.pairId) {
          HapticFeedback.mediumImpact();
          final newMatched = {..._matched, _flipped[0], _flipped[1]};
          setState(() {
            _matched = newMatched;
            _flipped = [];
            _checking = false;
          });
          if (newMatched.length == _cards.length) {
            _timer?.cancel();
            setState(() => _gameOver = true);
            _submitScore();
          }
        } else {
          setState(() {
            _flipped = [];
            _checking = false;
          });
        }
      });
    }
  }

  Future<void> _submitScore() async {
    final uuid = ref.read(storageServiceProvider).playerUuid;
    if (uuid == null) return;
    try {
      await ref.read(apiServiceProvider).submitScore(
        playerUuid: uuid,
        gameType: 'yatkeslik',
        won: true,
        wrongGuesses: (_moves - _allPairs.length).clamp(0, 99),
      );
      ref.read(playerProvider.notifier).refresh();
    } catch (_) {}
  }

  String get _timeStr {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return m > 0 ? '${m}m ${s}s' : '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ýatkeşlik'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          if (_gameStarted && !_gameOver)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  _timeStr,
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
      body: Column(
        children: [
          Expanded(child: _gameOver ? _buildWin() : _buildBoard()),
          const BannerAdWidget(),
        ],
      ),
    );
  }

  Widget _buildBoard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenW = constraints.maxWidth;
        final isTablet = screenW > 600;

        // Responsive columns: 4 phone, 5 tablet, 6 large tablet
        final cols = screenW > 900 ? 6 : isTablet ? 5 : 4;

        // Card size: fill width with small gaps
        const gap = 8.0;
        const hPad = 12.0;
        final cardW = (screenW - hPad * 2 - gap * (cols - 1)) / cols;
        final cardH = cardW * 1.15; // slightly taller than wide

        return Column(
          children: [
            // Stats bar
            if (_gameStarted)
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    Text(
                      '${_matched.length ~/ 2} / ${_allPairs.length} jübüt',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$_moves hereket',
                      style: const TextStyle(fontSize: 13, color: AppColors.textHint),
                    ),
                  ],
                ),
              ),

            // Scrollable grid
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(hPad),
                child: Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: List.generate(_cards.length, (i) {
                    final isFlipped = _flipped.contains(i) || _matched.contains(i);
                    final isMatched = _matched.contains(i);
                    return SizedBox(
                      width: cardW,
                      height: cardH,
                      child: _CardWidget(
                        card: _cards[i],
                        isFlipped: isFlipped,
                        isMatched: isMatched,
                        cardSize: cardW,
                        onTap: () => _flipCard(i),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWin() {
    final score = (_allPairs.length * 100 - _moves * 2).clamp(0, 1200);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 72)),
          const SizedBox(height: 20),
          const Text(
            'Tapawutly!',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Stat(label: 'Hereket', value: '$_moves'),
              const SizedBox(width: 32),
              _Stat(label: 'Wagt', value: _timeStr),
              const SizedBox(width: 32),
              _Stat(label: 'Bal', value: '$score'),
            ],
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _initGame,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                'Gaýtadan',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Card widget ────────────────────────────────────────────────────────────────

class _CardWidget extends StatelessWidget {
  final _Card card;
  final bool isFlipped;
  final bool isMatched;
  final double cardSize;
  final VoidCallback onTap;

  const _CardWidget({
    required this.card,
    required this.isFlipped,
    required this.isMatched,
    required this.cardSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Scale emoji/text relative to card size
    final emojiFontSize = cardSize * 0.42;
    final wordFontSize = card.word.length > 6
        ? cardSize * 0.18
        : cardSize * 0.22;

    return GestureDetector(
      onTap: isFlipped ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isMatched
              ? AppColors.successLight
              : isFlipped
                  ? AppColors.surface
                  : AppColors.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isFlipped ? 0.06 : 0.14),
              blurRadius: isFlipped ? 8 : 4,
              offset: const Offset(0, 3),
            ),
          ],
          border: isMatched
              ? Border.all(color: AppColors.success.withOpacity(0.35), width: 1.5)
              : null,
        ),
        child: Center(
          child: isFlipped
              ? (card.isEmoji
                  ? Text(card.emoji, style: TextStyle(fontSize: emojiFontSize))
                  : Padding(
                      padding: const EdgeInsets.all(4),
                      child: Text(
                        card.word,
                        style: TextStyle(
                          fontSize: wordFontSize,
                          fontWeight: FontWeight.w800,
                          color: isMatched ? AppColors.success : AppColors.textPrimary,
                          height: 1.1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ))
              : Text(
                  '?',
                  style: TextStyle(
                    fontSize: cardSize * 0.36,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}

// ── Data ───────────────────────────────────────────────────────────────────────

class _Card {
  final int id;
  final int pairId;
  final bool isEmoji;
  final String emoji;
  final String word;
  const _Card({
    required this.id,
    required this.pairId,
    required this.isEmoji,
    required this.emoji,
    required this.word,
  });
}

class _Stat extends StatelessWidget {
  final String label, value;
  const _Stat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          )),
      Text(label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
    ],
  );
}
