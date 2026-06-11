import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';

enum LetterState { idle, correct, wrong }

class TurkmenKeyboard extends StatelessWidget {
  final Map<String, LetterState> letterStates;
  final void Function(String letter) onLetterTap;
  final bool disabled;

  const TurkmenKeyboard({
    super.key,
    required this.letterStates,
    required this.onLetterTap,
    this.disabled = false,
  });

  static const _rows = [
    'ÄWERTYUIOP',
    'ÖASDFGHJKL',
    'ŇŞZÜÇÝBNMŽ',
    'CVXQ',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _rows.map((row) {
        final letters = row.split('');
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: letters.map((letter) {
              return _KeyButton(
                letter: letter,
                state: letterStates[letter] ?? LetterState.idle,
                onTap: disabled ? null : () {
                  HapticFeedback.lightImpact();
                  onLetterTap(letter);
                },
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String letter;
  final LetterState state;
  final VoidCallback? onTap;

  const _KeyButton({required this.letter, required this.state, this.onTap});

  @override
  Widget build(BuildContext context) {
    // available width = screen - jellad horizontal padding (16) - 10 key margins (4px each = 40)
    final screenW = MediaQuery.of(context).size.width;
    final keyW = (screenW - 56) / 10;
    final keyH = keyW * 1.25;

    Color bg;
    Color textColor;
    Color border;

    switch (state) {
      case LetterState.correct:
        bg = AppColors.success;
        textColor = Colors.white;
        border = AppColors.success;
      case LetterState.wrong:
        bg = AppColors.surfaceSecondary;
        textColor = AppColors.textHint;
        border = AppColors.borderLight;
      case LetterState.idle:
        bg = AppColors.surface;
        textColor = AppColors.textPrimary;
        border = AppColors.border;
    }

    final isUsed = state != LetterState.idle;

    return GestureDetector(
      onTap: isUsed ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: keyW,
        height: keyH,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border, width: state == LetterState.correct ? 0 : 1),
        ),
        child: Center(
          child: Text(
            letter,
            style: TextStyle(
              fontSize: keyW * 0.38,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
