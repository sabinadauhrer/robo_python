import 'package:flutter/material.dart';

import '../../../exercises/outfits.dart';
import '../../theme.dart';
import 'kawaii_robot.dart';

/// Der Roboter mit einer Sprechblase daneben.
class MascotBubble extends StatelessWidget {
  const MascotBubble({
    super.key,
    required this.text,
    this.mood = RobotMood.normal,
    this.robotSize = 72,
    this.outfit = Outfit.none,
  });

  final Outfit outfit;

  final String text;
  final RobotMood mood;
  final double robotSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        KawaiiRobot(mood: mood, size: robotSize, outfit: outfit),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(22),
                bottomLeft: Radius.circular(22),
                bottomRight: Radius.circular(22),
              ),
              border: Border.all(color: AppColors.cardBorder, width: 2),
              boxShadow: softShadow(),
            ),
            child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ),
      ],
    );
  }
}
