import 'package:flutter/material.dart';

import '../../../exercises/checker.dart';
import '../../../exercises/exercise.dart';
import '../../../state/lesson_session.dart';
import '../../theme.dart';
import 'blank_field.dart';
import 'code_view.dart';

/// Lückentext: Code mit Eingabefeldern an den Stellen von ___.
class FillExerciseView extends StatefulWidget {
  const FillExerciseView({
    super.key,
    required this.exercise,
    required this.status,
    required this.selectedLine,
    required this.onLineTap,
    required this.onChanged,
    required this.onSubmit,
  });

  final FillExercise exercise;
  final SessionStatus status;
  final int? selectedLine;
  final ValueChanged<int> onLineTap;

  /// Meldet die aktuelle Antwort und – falls alle Lücken gefüllt sind – den ausführbaren Code.
  final void Function(Answer answer, String? code) onChanged;
  final VoidCallback onSubmit;

  @override
  State<FillExerciseView> createState() => _FillExerciseViewState();
}

class _FillExerciseViewState extends State<FillExerciseView> {
  late final List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.exercise.blankCount, (_) => TextEditingController());
    for (final c in _controllers) {
      c.addListener(_notify);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _notify());
  }

  @override
  void didUpdateWidget(FillExerciseView old) {
    super.didUpdateWidget(old);
    if (widget.status == SessionStatus.revealed && old.status != SessionStatus.revealed) {
      // Nach dem Frame setzen – sonst würde der Eltern-Widget während des Builds neu gebaut.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final solution = widget.exercise.solution;
        for (var i = 0; i < _controllers.length; i++) {
          _controllers[i].text = solution[i];
        }
      });
    }
  }

  void _notify() {
    final inputs = [for (final c in _controllers) c.text];
    final complete = inputs.every((i) => i.trim().isNotEmpty);
    widget.onChanged(FillAnswer(inputs), complete ? widget.exercise.fill(inputs.map((i) => i.trim()).toList()) : null);
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  BlankState get _state => switch (widget.status) {
    SessionStatus.correct || SessionStatus.finished => BlankState.correct,
    SessionStatus.wrong || SessionStatus.failed => BlankState.wrong,
    SessionStatus.revealed => BlankState.revealed,
    SessionStatus.answering => BlankState.open,
  };

  @override
  Widget build(BuildContext context) {
    final lines = widget.exercise.code.split('\n');
    final firstBlank = <int>[];
    var count = 0;
    for (final l in lines) {
      firstBlank.add(count);
      count += blankMarker.allMatches(l).length;
    }
    return CodeView(
      code: widget.exercise.code,
      notes: widget.exercise.notes,
      selectedLine: widget.selectedLine,
      onLineTap: widget.onLineTap,
      lineBuilder: (context, n, text) {
        final parts = text.split(blankMarker);
        if (parts.length == 1) return Text(text, style: codeTextStyle);
        var index = firstBlank[n - 1];
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < parts.length; i++) ...[
              if (parts[i].isNotEmpty) Text(parts[i], style: codeTextStyle),
              if (i < parts.length - 1)
                Builder(builder: (context) {
                  final b = index++;
                  return BlankField(
                    controller: _controllers[b],
                    expectedLength: widget.exercise.solution[b].length,
                    state: _state,
                    index: b,
                    autofocus: b == 0,
                    onSubmitted: widget.onSubmit,
                  );
                }),
            ],
          ],
        );
      },
    );
  }
}
