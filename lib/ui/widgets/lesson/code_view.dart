import 'package:flutter/material.dart';

import '../../theme.dart';

/// Baut den Inhalt einer Codezeile (z. B. mit Lücken-Feldern). Standard: reiner Text.
typedef LineBuilder = Widget Function(BuildContext context, int line, String text);

/// Code mit Zeilennummern. Zeilen mit Erklärung bekommen ein "?" und sind antippbar.
class CodeView extends StatelessWidget {
  const CodeView({
    super.key,
    required this.code,
    this.notes = const {},
    this.selectedLine,
    this.currentLine,
    this.errorLine,
    this.onLineTap,
    this.lineBuilder,
  });

  final String code;
  final Map<int, String> notes;

  /// Vom Spieler angetippte Zeile (lila).
  final int? selectedLine;

  /// Gerade ausgeführte Zeile im Probelauf (gelb).
  final int? currentLine;
  final int? errorLine;
  final ValueChanged<int>? onLineTap;
  final LineBuilder? lineBuilder;

  static double get lineHeight => codeTextStyle.fontSize! * codeTextStyle.height! + 8;

  @override
  Widget build(BuildContext context) {
    final lines = code.split('\n');
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder, width: 2),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      // Alle Zeilen gleich breit (mindestens so breit wie der Kasten), damit Markierungen durchgehen.
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: IntrinsicWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < lines.length; i++) _line(context, i + 1, lines[i]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _line(BuildContext context, int n, String text) {
    final hasNote = notes.containsKey(n);
    final Color? background = n == errorLine
        ? AppColors.errorLine
        : n == currentLine
        ? AppColors.currentLine
        : n == selectedLine
        ? AppColors.lavender.withValues(alpha: 0.35)
        : null;
    final row = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      constraints: BoxConstraints(minHeight: lineHeight),
      padding: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: background,
        border: Border(
          left: BorderSide(
            color: n == currentLine ? AppColors.currentLineMarker : (n == errorLine ? AppColors.error : Colors.transparent),
            width: 4,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 34,
            child: Text('$n',
                textAlign: TextAlign.right,
                style: codeTextStyle.copyWith(fontSize: 13, color: AppColors.inkSoft)),
          ),
          const SizedBox(width: 12),
          lineBuilder?.call(context, n, text) ?? Text(text, style: codeTextStyle),
          if (hasNote) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: 'Erklärung zu Zeile $n',
              child: Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: n == selectedLine ? AppColors.lavenderDeep : AppColors.lavender,
                  shape: BoxShape.circle,
                ),
                child: Text('?',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: n == selectedLine ? Colors.white : AppColors.ink)),
              ),
            ),
          ],
        ],
      ),
    );
    if (!hasNote || onLineTap == null) return row;
    return Semantics(
      button: true,
      label: 'Erklärung zu Zeile $n anzeigen',
      child: InkWell(onTap: () => onLineTap!(n), child: row),
    );
  }
}
