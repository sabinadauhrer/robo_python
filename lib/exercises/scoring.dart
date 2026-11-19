/// Spielregeln: Herzen, XP, Sterne, Münzen, Tages-Serie.
abstract final class Scoring {
  static const hearts = 3;
  static const baseXp = 10;

  /// XP für eine richtige Antwort; Serien (Combo) geben Bonus.
  static int xpFor(int combo) => baseXp + (combo - 1).clamp(0, 5) * 2;

  /// Sterne = übrige Herzen (mindestens 1, wenn geschafft).
  static int starsFor(int heartsLeft) => heartsLeft.clamp(1, 3);

  static int coinsFor(int stars) => 5 + stars * 5;

  /// Neue Tages-Serie nach dem Spielen an [today].
  static int nextStreak({required DateTime? lastPlayed, required DateTime today, required int streak}) {
    if (lastPlayed == null) return 1;
    final days = _day(today).difference(_day(lastPlayed)).inDays;
    if (days == 0) return streak == 0 ? 1 : streak;
    if (days == 1) return streak + 1;
    return 1;
  }

  /// Gilt die Serie heute noch (zuletzt heute oder gestern gespielt)?
  static int visibleStreak({required DateTime? lastPlayed, required DateTime today, required int streak}) {
    if (lastPlayed == null) return 0;
    return _day(today).difference(_day(lastPlayed)).inDays <= 1 ? streak : 0;
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
}
