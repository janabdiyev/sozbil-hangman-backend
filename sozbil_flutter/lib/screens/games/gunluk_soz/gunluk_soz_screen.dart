import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/app_providers.dart';
import '../jellad/turkmen_keyboard.dart';
import '../jellad/hangman_painter.dart';

class GunlukSozScreen extends ConsumerStatefulWidget {
  const GunlukSozScreen({super.key});

  @override
  ConsumerState<GunlukSozScreen> createState() => _GunlukSozScreenState();
}

class _GunlukSozScreenState extends ConsumerState<GunlukSozScreen> {
  final Map<String, LetterState> _letterStates = {};
  int _wrongGuesses = 0;
  bool _gameOver = false;
  bool _won = false;

  static const _maxWrong = 6;

  void _guessLetter(String letter) {
    final word = ref.read(dailyWordProvider).value;
    if (word == null || _gameOver) return;
    final isCorrect = word.word.contains(letter);
    setState(() {
      _letterStates[letter] = isCorrect ? LetterState.correct : LetterState.wrong;
      if (!isCorrect) _wrongGuesses++;
    });
    final won = word.word.split('').every(
      (c) => c == ' ' || c == '-' || _letterStates[c] == LetterState.correct,
    );
    if (won || _wrongGuesses >= _maxWrong) {
      setState(() { _gameOver = true; _won = won; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dailyAsync = ref.watch(dailyWordProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Günlük Söz')),
      body: dailyAsync.when(
        data: (word) {
          if (word == null) {
            return const Center(child: Text('Günlük söz tapylmady', style: TextStyle(color: AppColors.textSecondary)));
          }
          final screenH = MediaQuery.of(context).size.height;
          return Column(
            children: [
              Container(
                height: screenH * 0.30,
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
              const SizedBox(height: 16),
              Text(
                word.word.split('').map((c) =>
                  _letterStates[c] == LetterState.correct || _gameOver ? c : '_'
                ).join(' '),
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700,
                    letterSpacing: 4, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text('Ýardam: ${word.hint}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              if (_gameOver)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _won ? '🎉 Günüň sözüni bildiňiz!' : '☠️ Söz: ${word.word}',
                    style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600,
                      color: _won ? AppColors.success : AppColors.error,
                    ),
                  ),
                ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                child: TurkmenKeyboard(
                  letterStates: _letterStates,
                  onLetterTap: _guessLetter,
                  disabled: _gameOver,
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => const Center(child: Text('Ýüklenip bilmedi')),
      ),
    );
  }
}
