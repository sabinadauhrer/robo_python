import 'package:flutter/material.dart';

import '../../../exercises/exercise.dart';
import '../../../exercises/outfits.dart';
import '../../theme.dart';
import '../kawaii/kawaii_robot.dart';

/// Robo erklärt WÄHREND der Aufgabe: warum der Code so ist, einzelne Zeilen und einen Tipp.
class RoboExplainCard extends StatefulWidget {
  const RoboExplainCard({
    super.key,
    required this.exercise,
    required this.selectedLine,
    required this.onCloseNote,
    required this.outfit,
  });

  final Exercise exercise;
  final int? selectedLine;
  final VoidCallback onCloseNote;
  final Outfit outfit;

  @override
  State<RoboExplainCard> createState() => _RoboExplainCardState();
}

class _RoboExplainCardState extends State<RoboExplainCard> {
  bool _showHint = false;

  @override
  void didUpdateWidget(RoboExplainCard old) {
    super.didUpdateWidget(old);
    if (old.exercise != widget.exercise) _showHint = false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final e = widget.exercise;
    final line = widget.selectedLine;
    final note = line == null ? null : e.notes[line];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder, width: 2),
        boxShadow: softShadow(),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KawaiiRobot(size: 56, outfit: widget.outfit, mood: _showHint ? RobotMood.happy : RobotMood.normal),
          const SizedBox(width: 10),
          Expanded(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topCenter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (note != null) ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.lavender, borderRadius: BorderRadius.circular(8)),
                          child: Text('Zeile $line', style: theme.textTheme.labelLarge),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: widget.onCloseNote,
                          icon: const Icon(Icons.arrow_back_rounded, size: 16),
                          label: const Text('Erklärung'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(note, style: theme.textTheme.bodyLarge?.copyWith(height: 1.45)),
                  ] else ...[
                    Text('Robo erklärt', style: theme.textTheme.labelLarge?.copyWith(color: AppColors.pinkDeep)),
                    const SizedBox(height: 4),
                    Text(e.explain, style: theme.textTheme.bodyLarge?.copyWith(height: 1.45)),
                    if (e.notes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(children: [
                        Container(
                          width: 20,
                          height: 20,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(color: AppColors.lavender, shape: BoxShape.circle),
                          child: const Text('?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text('Tippe auf eine Zeile mit ?, um sie genauer erklärt zu bekommen.',
                              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.inkSoft)),
                        ),
                      ]),
                    ],
                  ],
                  if (e.hint.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    if (_showHint)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.butter.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.lightbulb_rounded, color: AppColors.coinDeep, size: 20),
                            const SizedBox(width: 6),
                            Expanded(child: Text(e.hint, style: theme.textTheme.bodyMedium)),
                          ],
                        ),
                      )
                    else
                      TextButton.icon(
                        onPressed: () => setState(() => _showHint = true),
                        icon: const Icon(Icons.lightbulb_outline_rounded),
                        label: const Text('Tipp anzeigen (kostenlos)'),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
