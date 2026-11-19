import 'package:flutter/material.dart';

import '../../theme.dart';

enum BlankState { open, correct, wrong, revealed }

/// Ein Eingabefeld für eine Lücke im Code, so breit wie die erwartete Antwort.
class BlankField extends StatelessWidget {
  const BlankField({
    super.key,
    required this.controller,
    required this.expectedLength,
    required this.state,
    required this.index,
    this.focusNode,
    this.autofocus = false,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final int expectedLength;
  final BlankState state;
  final int index;
  final FocusNode? focusNode;
  final bool autofocus;
  final VoidCallback? onSubmitted;

  static double _charWidth = 0;

  static double charWidth() {
    if (_charWidth == 0) {
      final tp = TextPainter(
        text: const TextSpan(text: 'MMMMMMMMMM', style: codeTextStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      _charWidth = tp.width / 10;
      tp.dispose();
    }
    return _charWidth;
  }

  @override
  Widget build(BuildContext context) {
    final (Color fillColor, Color border) = switch (state) {
      BlankState.open => (AppColors.butter.withValues(alpha: 0.35), AppColors.currentLineMarker),
      BlankState.correct => (AppColors.mint.withValues(alpha: 0.45), AppColors.mintDeep),
      BlankState.wrong => (AppColors.errorLine, AppColors.error),
      BlankState.revealed => (AppColors.lavender.withValues(alpha: 0.4), AppColors.lavenderDeep),
    };
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final chars = [expectedLength, value.text.length, 3].reduce((a, b) => a > b ? a : b) + 1;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: SizedBox(
            width: chars * charWidth() + 16,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: autofocus,
              readOnly: state != BlankState.open,
              style: codeTextStyle.copyWith(fontWeight: FontWeight.bold, height: 1.2),
              autocorrect: false,
              enableSuggestions: false,
              smartQuotesType: SmartQuotesType.disabled,
              smartDashesType: SmartDashesType.disabled,
              textCapitalization: TextCapitalization.none,
              onSubmitted: (_) => onSubmitted?.call(),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: fillColor,
                hintText: '…',
                semanticCounterText: 'Lücke ${index + 1}',
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: border, width: 2, style: BorderStyle.solid),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.pinkDeep, width: 2.5),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
