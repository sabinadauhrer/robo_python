import 'package:flutter/material.dart';

import '../../../exercises/scoring.dart';
import '../../theme.dart';
import '../common/sound_toggle_button.dart';

/// Schließen, Fortschrittsbalken und Herzen.
class LessonTopBar extends StatelessWidget {
  const LessonTopBar({super.key, required this.progress, required this.hearts, required this.combo, required this.onClose});

  final double progress;
  final int hearts;
  final int combo;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
      child: Row(
        children: [
          IconButton(tooltip: 'Lektion verlassen', onPressed: onClose, icon: const Icon(Icons.close_rounded)),
          Expanded(
            child: Semantics(
              label: 'Fortschritt ${(progress * 100).round()} Prozent',
              child: Container(
                height: 18,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder, width: 2),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedFractionallySizedBox(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutBack,
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.mint, AppColors.mintDeep]),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (combo >= 2) ...[
            const SizedBox(width: 10),
            Tooltip(
              message: '$combo richtige Antworten in Folge – Bonus-XP!',
              child: Row(children: [
                const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF8A3D)),
                Text('$combo', style: const TextStyle(fontWeight: FontWeight.bold)),
              ]),
            ),
          ],
          const SizedBox(width: 10),
          Semantics(
            label: '$hearts von ${Scoring.hearts} Herzen',
            child: Row(
              children: [
                for (var i = 0; i < Scoring.hearts; i++)
                  AnimatedScale(
                    scale: i < hearts ? 1 : 0.8,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      i < hearts ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: i < hearts ? AppColors.pinkDeep : AppColors.cardBorder,
                      size: 26,
                    ),
                  ),
              ],
            ),
          ),
          const SoundToggleButton(),
        ],
      ),
    );
  }
}
