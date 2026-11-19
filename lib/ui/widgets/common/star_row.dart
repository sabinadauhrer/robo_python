import 'package:flutter/material.dart';

import '../../theme.dart';

/// Zeigt 0–3 Sterne.
class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.stars, this.size = 20, this.max = 3});

  final int stars;
  final double size;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$stars von $max Sternen',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < max; i++)
            Icon(
              i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
              color: i < stars ? AppColors.star : AppColors.cardBorder,
              size: size,
            ),
        ],
      ),
    );
  }
}
