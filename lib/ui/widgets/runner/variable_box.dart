import 'package:flutter/material.dart';

import '../../theme.dart';

/// Pastell-Kästchen mit Namensschild; leuchtet auf, wenn sich der Wert ändert.
class VariableBox extends StatelessWidget {
  const VariableBox({
    super.key,
    required this.name,
    required this.value,
    required this.typeName,
    required this.changed,
  });

  final String name;
  final String value;
  final String typeName;
  final bool changed;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.pastelFor(name);
    return Semantics(
      label: 'Variable $name hat den Wert $value',
      child: AnimatedScale(
        scale: changed ? 1.06 : 1,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
              child: Text(name, style: codeTextStyle.copyWith(fontSize: 14, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              constraints: const BoxConstraints(minWidth: 64, minHeight: 46, maxWidth: 320),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: changed ? AppColors.currentLine : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: changed ? AppColors.currentLineMarker : color, width: 3),
              ),
              child: Center(
                widthFactor: 1,
                heightFactor: 1,
                child: Text(value, style: codeTextStyle.copyWith(fontSize: 17, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 2),
            Text(typeName, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.inkSoft)),
          ],
        ),
      ),
    );
  }
}
