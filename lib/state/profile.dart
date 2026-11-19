import '../exercises/outfits.dart';

/// Spielstand des Spielers (wird lokal gespeichert).
class Profile {
  const Profile({
    this.xp = 0,
    this.coins = 0,
    this.streak = 0,
    this.lastPlayed,
    this.lessonStars = const {},
    this.owned = const {Outfit.none},
    this.outfit = Outfit.none,
  });

  final int xp;
  final int coins;

  /// Tage in Folge gespielt.
  final int streak;
  final DateTime? lastPlayed;

  /// Beste Sterne je Lektion.
  final Map<String, int> lessonStars;
  final Set<Outfit> owned;
  final Outfit outfit;

  int get totalStars => lessonStars.values.fold(0, (a, b) => a + b);

  Profile copyWith({
    int? xp,
    int? coins,
    int? streak,
    DateTime? lastPlayed,
    Map<String, int>? lessonStars,
    Set<Outfit>? owned,
    Outfit? outfit,
  }) => Profile(
    xp: xp ?? this.xp,
    coins: coins ?? this.coins,
    streak: streak ?? this.streak,
    lastPlayed: lastPlayed ?? this.lastPlayed,
    lessonStars: lessonStars ?? this.lessonStars,
    owned: owned ?? this.owned,
    outfit: outfit ?? this.outfit,
  );

  Map<String, dynamic> toJson() => {
    'xp': xp,
    'coins': coins,
    'streak': streak,
    'lastPlayed': lastPlayed?.toIso8601String(),
    'lessonStars': lessonStars,
    'owned': [for (final o in owned) o.name],
    'outfit': outfit.name,
  };

  factory Profile.fromJson(Map<String, dynamic> json) {
    Outfit parse(Object? name) => Outfit.values.firstWhere((o) => o.name == name, orElse: () => Outfit.none);
    return Profile(
      xp: json['xp'] as int? ?? 0,
      coins: json['coins'] as int? ?? 0,
      streak: json['streak'] as int? ?? 0,
      lastPlayed: DateTime.tryParse(json['lastPlayed'] as String? ?? ''),
      lessonStars: (json['lessonStars'] as Map<String, dynamic>? ?? {}).map((k, v) => MapEntry(k, v as int)),
      owned: {Outfit.none, for (final o in json['owned'] as List? ?? []) parse(o)},
      outfit: parse(json['outfit']),
    );
  }
}
