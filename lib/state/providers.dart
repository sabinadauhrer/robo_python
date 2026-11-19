import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/lesson_repository.dart';
import '../data/profile_repository.dart';
import '../exercises/exercise.dart';
import '../exercises/outfits.dart';
import '../exercises/scoring.dart';
import 'profile.dart';

/// Wird in `main()` mit der geladenen Instanz überschrieben.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider muss in main() überschrieben werden'),
);

/// Aktuelle Zeit – in Tests überschreibbar.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(sharedPreferencesProvider)),
);

final lessonRepositoryProvider = Provider<LessonRepository>((ref) => LessonRepository(rootBundle));

final lessonsProvider = FutureProvider<List<Lesson>>((ref) => ref.watch(lessonRepositoryProvider).loadAll());

/// Belohnung nach einer geschafften Lektion.
class LessonReward {
  const LessonReward({
    required this.stars,
    required this.xp,
    required this.coins,
    required this.streak,
    required this.newBest,
  });

  final int stars;
  final int xp;
  final int coins;
  final int streak;
  final bool newBest;
}

class ProfileNotifier extends Notifier<Profile> {
  @override
  Profile build() => ref.watch(profileRepositoryProvider).load();

  void _save(Profile p) {
    state = p;
    ref.read(profileRepositoryProvider).save(p);
  }

  LessonReward completeLesson({required String lessonId, required int stars, required int xp}) {
    final today = ref.read(clockProvider)();
    final coins = Scoring.coinsFor(stars);
    final streak = Scoring.nextStreak(lastPlayed: state.lastPlayed, today: today, streak: state.streak);
    final best = state.lessonStars[lessonId] ?? 0;
    _save(state.copyWith(
      xp: state.xp + xp,
      coins: state.coins + coins,
      streak: streak,
      lastPlayed: today,
      lessonStars: {...state.lessonStars, lessonId: stars > best ? stars : best},
    ));
    return LessonReward(stars: stars, xp: xp, coins: coins, streak: streak, newBest: stars > best);
  }

  /// Kauft ein Outfit; false, wenn die Münzen nicht reichen.
  bool buy(Outfit outfit) {
    if (state.owned.contains(outfit)) return true;
    if (state.coins < outfit.price) return false;
    _save(state.copyWith(coins: state.coins - outfit.price, owned: {...state.owned, outfit}, outfit: outfit));
    return true;
  }

  void wear(Outfit outfit) {
    if (state.owned.contains(outfit)) _save(state.copyWith(outfit: outfit));
  }

  /// Die erste Insel ist immer offen, jede weitere nach dem Schaffen der vorherigen.
  bool isUnlocked(List<Lesson> lessons, int index) =>
      index == 0 || (state.lessonStars[lessons[index - 1].id] ?? 0) > 0;

  /// Sichtbare Serie (0, wenn gestern nicht gespielt wurde).
  int get visibleStreak =>
      Scoring.visibleStreak(lastPlayed: state.lastPlayed, today: ref.read(clockProvider)(), streak: state.streak);
}

final profileProvider = NotifierProvider<ProfileNotifier, Profile>(ProfileNotifier.new);

// ---------- Einstellungen ----------

class SoundSetting extends Notifier<bool> {
  @override
  bool build() => ref.watch(profileRepositoryProvider).loadSoundEnabled();

  void set(bool value) {
    state = value;
    ref.read(profileRepositoryProvider).saveSoundEnabled(value);
  }
}

final soundEnabledProvider = NotifierProvider<SoundSetting, bool>(SoundSetting.new);
