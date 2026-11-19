import 'package:flutter/material.dart';

/// Kawaii-Pastellpalette – weich, freundlich, aber mit gut lesbarem Text.
abstract final class AppColors {
  // Grundfarben
  static const seed = Color(0xFFE77FAE); // Bonbon-Rosa
  static const pink = Color(0xFFF7A8C8);
  static const pinkDeep = Color(0xFFE0609A);
  static const mint = Color(0xFF9EE6CF);
  static const mintDeep = Color(0xFF3FB58F);
  static const lavender = Color(0xFFC9B6F2);
  static const lavenderDeep = Color(0xFF8C6FD6);
  static const butter = Color(0xFFFFE08A);
  static const sky = Color(0xFFBDE3FF);
  static const peach = Color(0xFFFFCBA8);

  /// Dunkles Pflaume für Text und Konturen (statt hartem Schwarz).
  static const ink = Color(0xFF4A3B52);
  static const inkSoft = Color(0xFF8A7A92);

  static const background = Color(0xFFFFF6FA);
  static const card = Colors.white;
  static const cardBorder = Color(0xFFF6DCE8);

  // Spielfeld
  static const floor = Color(0xFFFFFDF7);
  static const floorAlt = Color(0xFFFFF0F6);
  static const floorBorder = Color(0xFFF6DCE8);
  static const wallTop = Color(0xFFDCCFF8);
  static const wall = Color(0xFFB9A5EC);
  static const wallShadow = Color(0xFF9C86DE);
  static const coin = Color(0xFFFFCF4D);
  static const coinDeep = Color(0xFFE5A21A);
  static const goal = pinkDeep;
  static const robot = mint;

  // Code-Hervorhebung
  static const currentLine = Color(0xFFFFF1B8);
  static const currentLineMarker = Color(0xFFFFB938);
  static const nextLine = Color(0xFFE3F1FF);
  static const errorLine = Color(0xFFFFDDE4);

  static const success = mintDeep;
  static const error = Color(0xFFE0507A);
  static const star = Color(0xFFFFC233);

  /// Wechselnde Pastelltöne, z. B. für Levelkacheln und Variablen.
  static const pastels = [pink, mint, lavender, butter, sky, peach];

  static Color pastelFor(String key) => pastels[key.hashCode.abs() % pastels.length];
}

const appFontFamily = 'VarelaRound';

/// Monospace-Schrift für Code (mitgeliefert, damit Web und Android gleich aussehen).
const codeTextStyle = TextStyle(
  fontFamily: 'JetBrainsMono',
  fontSize: 16,
  height: 1.5,
  color: AppColors.ink,
);

/// Weicher, farbiger Schatten im Kawaii-Stil.
List<BoxShadow> softShadow([Color color = AppColors.pink]) => [
  BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6)),
];

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.seed,
    primary: AppColors.pinkDeep,
    secondary: AppColors.mintDeep,
    tertiary: AppColors.lavenderDeep,
    surface: AppColors.background,
    onSurface: AppColors.ink,
  );
  final base = ThemeData(colorScheme: scheme, fontFamily: appFontFamily);
  const pill = StadiumBorder();
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    textTheme: base.textTheme.apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.ink,
      centerTitle: false,
      titleTextStyle: TextStyle(fontFamily: appFontFamily, fontSize: 22, color: AppColors.ink),
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.cardBorder, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: pill,
        backgroundColor: AppColors.pinkDeep,
        textStyle: const TextStyle(fontFamily: appFontFamily, fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: pill,
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.pink, width: 2),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: AppColors.ink),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: const StadiumBorder(side: BorderSide(color: AppColors.pink, width: 1.5)),
      backgroundColor: Colors.white,
    ),
    sliderTheme: base.sliderTheme.copyWith(
      activeTrackColor: AppColors.pink,
      inactiveTrackColor: AppColors.cardBorder,
      thumbColor: AppColors.pinkDeep,
      trackHeight: 8,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.mintDeep),
  );
}
