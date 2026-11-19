import 'dart:math';

import 'package:flutter/material.dart';

import '../../../exercises/checker.dart';
import '../../../exercises/exercise.dart';
import '../../../state/lesson_session.dart';
import '../../theme.dart';

/// Zeilen in die richtige Reihenfolge bringen: Bausteine antippen, um sie anzuhängen.
class OrderExerciseView extends StatefulWidget {
  const OrderExerciseView({
    super.key,
    required this.exercise,
    required this.status,
    required this.seed,
    required this.onChanged,
  });

  final OrderExercise exercise;
  final SessionStatus status;
  final int seed;
  final void Function(Answer answer, String? code) onChanged;

  @override
  State<OrderExerciseView> createState() => _OrderExerciseViewState();
}

class _OrderExerciseViewState extends State<OrderExerciseView> {
  late final List<int> _pool;
  final _placed = <int>[];

  @override
  void initState() {
    super.initState();
    final n = widget.exercise.lines.length;
    _pool = List.generate(n, (i) => i)..shuffle(Random(widget.seed));
    if (n > 1 && List.generate(n, (i) => i).every((i) => _pool[i] == i)) {
      _pool.add(_pool.removeAt(0)); // nie schon richtig sortiert anzeigen
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _notify());
  }

  @override
  void didUpdateWidget(OrderExerciseView old) {
    super.didUpdateWidget(old);
    if (widget.status == SessionStatus.revealed && old.status != SessionStatus.revealed) {
      setState(() {
        _placed
          ..clear()
          ..addAll(List.generate(widget.exercise.lines.length, (i) => i));
      });
    }
  }

  void _notify() {
    final complete = _placed.length == widget.exercise.lines.length;
    widget.onChanged(OrderAnswer(List.of(_placed)), complete ? widget.exercise.arrange(_placed) : null);
  }

  void _toggle(int line) {
    if (widget.status != SessionStatus.answering) return;
    setState(() => _placed.contains(line) ? _placed.remove(line) : _placed.add(line));
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final e = widget.exercise;
    final open = [for (final i in _pool) if (!_placed.contains(i)) i];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Dein Programm', style: theme.textTheme.titleSmall),
        const SizedBox(height: 6),
        Container(
          constraints: const BoxConstraints(minHeight: 90),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBFD),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.pink, width: 2),
          ),
          child: _placed.isEmpty
              ? Center(
                  child: Text('Tippe unten auf die Zeilen – in der Reihenfolge, in der sie laufen sollen.',
                      textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.inkSoft)),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var k = 0; k < _placed.length; k++)
                      _LineTile(
                        number: k + 1,
                        text: e.lines[_placed[k]],
                        color: AppColors.mint,
                        onTap: () => _toggle(_placed[k]),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 14),
        if (open.isNotEmpty) ...[
          Text('Bausteine', style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          for (final i in open)
            _LineTile(text: e.lines[i], color: AppColors.butter, onTap: () => _toggle(i)),
        ],
      ],
    );
  }
}

class _LineTile extends StatelessWidget {
  const _LineTile({required this.text, required this.color, required this.onTap, this.number});

  final String text;
  final Color color;
  final VoidCallback onTap;
  final int? number;

  @override
  Widget build(BuildContext context) {
    final indent = text.length - text.trimLeft().length;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: color.withValues(alpha: 0.35),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color, width: 2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                if (number != null)
                  SizedBox(
                    width: 26,
                    child: Text('$number', style: codeTextStyle.copyWith(fontSize: 13, color: AppColors.inkSoft)),
                  ),
                // Einrückung sichtbar machen
                for (var i = 0; i < indent ~/ 4; i++)
                  Container(
                    width: 30,
                    height: 20,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: AppColors.lavender.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.keyboard_tab_rounded, size: 14, color: AppColors.lavenderDeep),
                  ),
                Expanded(child: Text(text.trimLeft(), style: codeTextStyle)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
