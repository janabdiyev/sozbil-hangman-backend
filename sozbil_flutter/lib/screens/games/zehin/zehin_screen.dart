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

// ── Question bank ──────────────────────────────────────────────────────────────

enum _QType { sequence, oddOne, math, analogy }

class _Question {
  final String question;
  final List<String> choices; // always 4
  final int answer;           // index into choices
  final _QType type;
  final String? explanation;  // shown after answering (optional)

  const _Question({
    required this.question,
    required this.choices,
    required this.answer,
    required this.type,
    this.explanation,
  });
}

const _kAllQuestions = <_Question>[
  // ── Number sequences ────────────────────────────────────────────────────────
  _Question(
    question: '2,  4,  6,  8,  ?',
    choices: ['9', '10', '11', '12'],
    answer: 1,
    type: _QType.sequence,
    explanation: 'Her gezek +2',
  ),
  _Question(
    question: '1,  4,  9,  16,  ?',
    choices: ['20', '24', '25', '30'],
    answer: 2,
    type: _QType.sequence,
    explanation: '1², 2², 3², 4², 5²',
  ),
  _Question(
    question: '3,  6,  12,  24,  ?',
    choices: ['36', '42', '48', '54'],
    answer: 2,
    type: _QType.sequence,
    explanation: 'Her gezek ×2',
  ),
  _Question(
    question: '1,  1,  2,  3,  5,  ?',
    choices: ['6', '7', '8', '9'],
    answer: 2,
    type: _QType.sequence,
    explanation: 'Fibonacci: her san öňküki ikisiniň jemi',
  ),
  _Question(
    question: '2,  3,  5,  7,  11,  ?',
    choices: ['12', '13', '14', '15'],
    answer: 1,
    type: _QType.sequence,
    explanation: 'Goşa bolunmaýan sanlar (prima)',
  ),
  _Question(
    question: '100,  90,  81,  73,  66,  ?',
    choices: ['58', '59', '60', '61'],
    answer: 2,
    type: _QType.sequence,
    explanation: 'Aýyrylýan: 10, 9, 8, 7, 6...',
  ),
  _Question(
    question: '1,  8,  27,  64,  ?',
    choices: ['100', '112', '121', '125'],
    answer: 3,
    type: _QType.sequence,
    explanation: '1³, 2³, 3³, 4³, 5³',
  ),
  _Question(
    question: '0,  1,  3,  6,  10,  ?',
    choices: ['13', '14', '15', '16'],
    answer: 2,
    type: _QType.sequence,
    explanation: 'Her gezek +1, +2, +3, +4, +5…',
  ),
  _Question(
    question: '5,  10,  20,  40,  ?',
    choices: ['60', '70', '80', '90'],
    answer: 2,
    type: _QType.sequence,
    explanation: 'Her gezek ×2',
  ),
  _Question(
    question: '7,  14,  21,  28,  ?',
    choices: ['32', '35', '38', '42'],
    answer: 1,
    type: _QType.sequence,
    explanation: '7-niň köpeltme tablisasy',
  ),

  // ── Odd one out ─────────────────────────────────────────────────────────────
  _Question(
    question: 'Haýsy beýlekilerden tapawutly?\n4,  9,  16,  25,  35',
    choices: ['4', '16', '25', '35'],
    answer: 3,
    type: _QType.oddOne,
    explanation: '35 — doly kwadrat däl (1²=1, 2²=4…)',
  ),
  _Question(
    question: 'Haýsy beýlekilerden tapawutly?\n3,  7,  11,  14,  19',
    choices: ['3', '7', '14', '19'],
    answer: 2,
    type: _QType.oddOne,
    explanation: '14 — ýeke-täk täk bolmadyk san',
  ),
  _Question(
    question: 'Haýsy beýlekilerden tapawutly?\n2,  4,  6,  9,  10',
    choices: ['2', '4', '9', '10'],
    answer: 2,
    type: _QType.oddOne,
    explanation: '9 — ýeke-täk jüft bolmadyk san',
  ),
  _Question(
    question: 'Haýsy jandar däl?\nARYSLAN,  BÜRGÜT,  GÜL,  MÖJEK',
    choices: ['ARYSLAN', 'BÜRGÜT', 'GÜL', 'MÖJEK'],
    answer: 2,
    type: _QType.oddOne,
    explanation: 'GÜL — ösümlik, beýlekiler jandar',
  ),
  _Question(
    question: 'Haýsy reňk däl?\nGYZYL,  SARY,  ÝAŞYL,  TEGELEK',
    choices: ['GYZYL', 'SARY', 'ÝAŞYL', 'TEGELEK'],
    answer: 3,
    type: _QType.oddOne,
    explanation: 'TEGELEK — geometrik şekil',
  ),
  _Question(
    question: 'Haýsy Türkmenistanda ýok?\nAşgabat,  Mary,  Balkanabat,  Ankara',
    choices: ['Aşgabat', 'Mary', 'Balkanabat', 'Ankara'],
    answer: 3,
    type: _QType.oddOne,
    explanation: 'Ankara — Türkiýäniň paýtagty',
  ),
  _Question(
    question: 'Haýsy beýlekilerden tapawutly?\n12,  24,  36,  45,  48',
    choices: ['12', '36', '45', '48'],
    answer: 2,
    type: _QType.oddOne,
    explanation: '45 — 12-niň köplügi däl',
  ),

  // ── Math / logic ────────────────────────────────────────────────────────────
  _Question(
    question: '3 × 4 + 2 = ?',
    choices: ['12', '13', '14', '18'],
    answer: 2,
    type: _QType.math,
  ),
  _Question(
    question: '15 − 7 + 3 = ?',
    choices: ['9', '10', '11', '12'],
    answer: 2,
    type: _QType.math,
  ),
  _Question(
    question: '6 × 6 = ?',
    choices: ['30', '34', '36', '42'],
    answer: 2,
    type: _QType.math,
  ),
  _Question(
    question: '12 ÷ 4 × 3 = ?',
    choices: ['6', '8', '9', '12'],
    answer: 2,
    type: _QType.math,
  ),
  _Question(
    question: '2⁵ = ?',
    choices: ['16', '24', '32', '64'],
    answer: 2,
    type: _QType.math,
    explanation: '2×2×2×2×2 = 32',
  ),
  _Question(
    question: 'Bir günde näçe sagat bar?',
    choices: ['12', '20', '24', '48'],
    answer: 2,
    type: _QType.math,
  ),
  _Question(
    question: 'Üçburçlugyň ähli burçlarynyň jemi näçe dereje?',
    choices: ['90°', '120°', '180°', '360°'],
    answer: 2,
    type: _QType.math,
  ),
  _Question(
    question: '10-dan kiçi prima sanlar näçe sany?',
    choices: ['3', '4', '5', '6'],
    answer: 1,
    type: _QType.math,
    explanation: '2, 3, 5, 7 — 4 sany',
  ),
  _Question(
    question: 'Kwadratyň gyralarynyň sany?',
    choices: ['3', '4', '5', '6'],
    answer: 1,
    type: _QType.math,
  ),

  // ── Analogies ───────────────────────────────────────────────────────────────
  _Question(
    question: '3 : 9  =  4 : ?',
    choices: ['12', '14', '16', '18'],
    answer: 2,
    type: _QType.analogy,
    explanation: 'San kwadrat edilýär: 3²=9, 4²=16',
  ),
  _Question(
    question: '2 : 8  =  3 : ?',
    choices: ['9', '18', '24', '27'],
    answer: 3,
    type: _QType.analogy,
    explanation: 'San kübe edilýär: 2³=8, 3³=27',
  ),
  _Question(
    question: '10 : 5  =  20 : ?',
    choices: ['8', '10', '15', '40'],
    answer: 1,
    type: _QType.analogy,
    explanation: 'Iki bölen: 10÷2=5, 20÷2=10',
  ),
  _Question(
    question: '5 + 3 = 8\n7 + 4 = ?',
    choices: ['10', '11', '12', '13'],
    answer: 1,
    type: _QType.analogy,
  ),
  _Question(
    question: '100 − 40 = 60\n 80 − 30 = ?',
    choices: ['40', '45', '50', '55'],
    answer: 2,
    type: _QType.analogy,
  ),
];

const _kQuestionsPerRound = 10;

// ── Screen ─────────────────────────────────────────────────────────────────────

enum _GameState { loading, playing, revealing, finished }

class ZehinScreen extends ConsumerStatefulWidget {
  const ZehinScreen({super.key});

  @override
  ConsumerState<ZehinScreen> createState() => _ZehinScreenState();
}

class _ZehinScreenState extends ConsumerState<ZehinScreen>
    with SingleTickerProviderStateMixin {
  _GameState _gameState = _GameState.loading;

  late List<_Question> _questions;
  int _current = 0;
  int _correctCount = 0;

  int? _tappedIndex;   // which button was tapped (for reveal colour)
  bool _wasCorrect = false;

  late AnimationController _progressController;

  final _rewardedAd = RewardedAdService();

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _rewardedAd.load();
    _startRound();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _rewardedAd.dispose();
    super.dispose();
  }

  // ── Round setup ─────────────────────────────────────────────────────────────

  void _startRound() {
    final storage = ref.read(storageServiceProvider);

    if (!storage.canPlay(storage.isSubscribed, ApiConstants.dailyFreeGames)) {
      _autoShowRewardedAd();
      return;
    }

    storage.consumeGame(storage.isSubscribed);
    ref.read(gameLimitProvider.notifier).refresh();

    final pool = List<_Question>.from(_kAllQuestions)..shuffle();
    setState(() {
      _questions = pool.take(_kQuestionsPerRound).toList();
      _current = 0;
      _correctCount = 0;
      _tappedIndex = null;
      _gameState = _GameState.playing;
    });
    _progressController.animateTo(1 / _kQuestionsPerRound);
  }

  // ── Answer handling ─────────────────────────────────────────────────────────

  void _onAnswer(int choiceIndex) {
    if (_gameState != _GameState.playing) return;

    final correct = choiceIndex == _questions[_current].answer;
    setState(() {
      _tappedIndex = choiceIndex;
      _wasCorrect = correct;
      if (correct) _correctCount++;
      _gameState = _GameState.revealing;
    });

    Future.delayed(const Duration(milliseconds: 900), _advance);
  }

  void _advance() {
    if (!mounted) return;
    final next = _current + 1;
    if (next >= _kQuestionsPerRound) {
      setState(() { _gameState = _GameState.finished; });
      _submitScore();
      return;
    }
    setState(() {
      _current = next;
      _tappedIndex = null;
      _gameState = _GameState.playing;
    });
    _progressController.animateTo((next + 1) / _kQuestionsPerRound);
  }

  // ── Score submission ─────────────────────────────────────────────────────────

  void _submitScore() {
    final storage = ref.read(storageServiceProvider);
    final uuid = storage.playerUuid;
    if (uuid == null) return;
    final wrong = _kQuestionsPerRound - _correctCount;
    ref.read(apiServiceProvider).submitScore(
      playerUuid: uuid,
      gameType: 'zehin',
      won: _correctCount >= 6,
      wrongGuesses: wrong,
    ).then((_) => ref.read(playerProvider.notifier).refresh())
     .catchError((_) {});
  }

  void _autoShowRewardedAd() {
    _rewardedAd.show(
      onRewarded: () {
        final storage = ref.read(storageServiceProvider);
        storage.addRewardGames(ApiConstants.gamesPerAd, ApiConstants.gamesPerAd);
        ref.read(gameLimitProvider.notifier).refresh();
        _startRound();
      },
      onFailed: () { if (mounted) Navigator.pop(context); },
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Zehin Oýunlary',
          style: TextStyle(
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
        bottom: _gameState == _GameState.playing ||
                _gameState == _GameState.revealing
            ? PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: _ProgressBar(
                  controller: _progressController,
                  current: _current,
                  total: _kQuestionsPerRound,
                ),
              )
            : null,
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
    switch (_gameState) {
      case _GameState.loading:
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      case _GameState.playing:
      case _GameState.revealing:
        return _buildQuestion();
      case _GameState.finished:
        return _buildResults();
    }
  }

  // ── Question view ───────────────────────────────────────────────────────────

  Widget _buildQuestion() {
    final q = _questions[_current];
    final revealing = _gameState == _GameState.revealing;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Counter
            Text(
              '${_current + 1} / $_kQuestionsPerRound',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textHint,
              ),
            ),

            const SizedBox(height: 20),

            // Question card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Type badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _typeColor(q.type).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _typeLabel(q.type),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _typeColor(q.type),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    q.question,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.4,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Answer choices — 2×2 grid
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.6,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(4, (i) {
                  Color bg = AppColors.surface;
                  Color textColor = AppColors.textPrimary;
                  Color borderColor = Colors.transparent;

                  if (revealing) {
                    if (i == q.answer) {
                      bg = AppColors.successLight;
                      textColor = AppColors.success;
                      borderColor = AppColors.success;
                    } else if (i == _tappedIndex && i != q.answer) {
                      bg = AppColors.errorLight;
                      textColor = AppColors.error;
                      borderColor = AppColors.error;
                    }
                  }

                  return GestureDetector(
                    onTap: revealing ? null : () => _onAnswer(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor, width: 2),
                        boxShadow: revealing
                            ? null
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        q.choices[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Explanation (shown during reveal)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: revealing && q.explanation != null
                  ? Container(
                      key: const ValueKey('exp'),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: _wasCorrect
                            ? AppColors.successLight
                            : AppColors.errorLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _wasCorrect ? '✅' : '❌',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              q.explanation!,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _wasCorrect
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(key: ValueKey('empty'), height: 0),
            ),
          ],
        ),
      ),
    );
  }

  // ── Results view ─────────────────────────────────────────────────────────────

  Widget _buildResults() {
    final pct = _correctCount / _kQuestionsPerRound;
    final emoji = pct >= 0.9
        ? '🏆'
        : pct >= 0.7
            ? '🎉'
            : pct >= 0.5
                ? '👍'
                : '💪';
    final message = pct >= 0.9
        ? 'Ajaýyp netije!'
        : pct >= 0.7
            ? 'Gaty gowy!'
            : pct >= 0.5
                ? 'Erbet däl!'
                : 'Gaýtadan synanyş!';
    final scoreColor = pct >= 0.7
        ? AppColors.success
        : pct >= 0.5
            ? AppColors.accent
            : AppColors.error;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(emoji,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 72)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 28),

            // Score card
            Container(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ScoreStat(
                    label: 'Dogry',
                    value: '$_correctCount',
                    color: AppColors.success,
                  ),
                  Container(
                      width: 1, height: 40, color: AppColors.border),
                  _ScoreStat(
                    label: 'Nädogry',
                    value: '${_kQuestionsPerRound - _correctCount}',
                    color: AppColors.error,
                  ),
                  Container(
                      width: 1, height: 40, color: AppColors.border),
                  _ScoreStat(
                    label: 'Netije',
                    value: '${(_correctCount * 10)}%',
                    color: scoreColor,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _startRound,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text(
                'Täzeden oýna',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Çyk',
                style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String _typeLabel(_QType t) {
    switch (t) {
      case _QType.sequence: return 'YZYGIDERLILIK';
      case _QType.oddOne:   return 'TAPAWUTLY';
      case _QType.math:     return 'HASAP';
      case _QType.analogy:  return 'MEŇZEŞLIK';
    }
  }

  Color _typeColor(_QType t) {
    switch (t) {
      case _QType.sequence: return AppColors.primary;
      case _QType.oddOne:   return AppColors.accent;
      case _QType.math:     return AppColors.success;
      case _QType.analogy:  return const Color(0xFFD44AD4);
    }
  }
}

// ── Progress bar ───────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final AnimationController controller;
  final int current;
  final int total;

  const _ProgressBar({
    required this.controller,
    required this.current,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => LinearProgressIndicator(
        value: controller.value,
        backgroundColor: AppColors.surfaceSecondary,
        valueColor: const AlwaysStoppedAnimation(AppColors.primary),
        minHeight: 4,
      ),
    );
  }
}

// ── Score stat cell ────────────────────────────────────────────────────────────

class _ScoreStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ScoreStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textHint,
          ),
        ),
      ],
    );
  }
}
