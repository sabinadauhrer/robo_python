import 'package:flutter/material.dart';

import '../../../exercises/checker.dart';
import '../../../exercises/exercise.dart';
import '../../../state/lesson_session.dart';
import '../../theme.dart';
import 'code_view.dart';

/// Auswahl: Code ansehen und die richtige Antwort antippen.
class ChoiceExerciseView extends StatefulWidget {
  const ChoiceExerciseView({
    super.key,
    required this.exercise,
    required this.status,
    required this.selectedLine,
    required this.onLineTap,
    required this.onChanged,
  });

  final ChoiceExercise exercise;
  final SessionStatus status;
  final int? selectedLine;
  final ValueChanged<int> onLineTap;
  final void Function(Answer? answer, String? code) onChanged;

  @override
  State<ChoiceExerciseView> createState() => _ChoiceExerciseViewState();
}

class _ChoiceExerciseViewState extends State<ChoiceExerciseView> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final e = widget.exercise;
    final answering = widget.status == SessionStatus.answering;
    final showResult = !answering;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CodeView(code: e.code, notes: e.notes, selectedLine: widget.selectedLine, onLineTap: widget.onLineTap),
        const SizedBox(height: 14),
        for (var i = 0; i < e.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _OptionTile(
              text: e.options[i],
              letter: String.fromCharCode(65 + i),
              selected: _selected == i,
              state: !showResult
                  ? _Opt.open
                  : i == e.correct && (widget.status != SessionStatus.wrong)
                  ? _Opt.correct
                  : i == _selected && widget.status == SessionStatus.wrong
                  ? _Opt.wrong
                  : _Opt.dimmed,
              onTap: answering
                  ? () {
                      setState(() => _selected = i);
                      widget.onChanged(ChoiceAnswer(i), e.code);
                    }
                  : null,
            ),
          ),
      ],
    );
  }
}

enum _Opt { open, correct, wrong, dimmed }

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.text,
    required this.letter,
    required this.selected,
    required this.state,
    required this.onTap,
  });

  final String text;
  final String letter;
  final bool selected;
  final _Opt state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color border, IconData? icon) = switch (state) {
      _Opt.open => (selected ? AppColors.pink.withValues(alpha: 0.25) : Colors.white, selected ? AppColors.pinkDeep : AppColors.cardBorder, null),
      _Opt.correct => (AppColors.mint.withValues(alpha: 0.45), AppColors.mintDeep, Icons.check_circle_rounded),
      _Opt.wrong => (AppColors.errorLine, AppColors.error, Icons.cancel_rounded),
      _Opt.dimmed => (Colors.white, AppColors.cardBorder, null),
    };
    final looksLikeCode = text.contains('\n') || RegExp(r"[\[\]{}()<>'=]|^\S+$").hasMatch(text);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: border, width: selected || state != _Opt.open ? 2.5 : 2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: selected ? AppColors.pinkDeep : AppColors.cardBorder,
                  child: Text(letter, style: TextStyle(fontSize: 13, color: selected ? Colors.white : AppColors.ink)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: looksLikeCode ? codeTextStyle.copyWith(fontSize: 15, height: 1.35) : const TextStyle(fontSize: 16, height: 1.35),
                  ),
                ),
                if (icon != null) Icon(icon, color: border),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
