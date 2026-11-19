import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../exercises/exercise.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/common/backup_dialog.dart';
import '../widgets/common/sound_toggle_button.dart';
import '../widgets/kawaii/kawaii_robot.dart';
import '../widgets/kawaii/mascot_bubble.dart';
import '../widgets/map/lesson_intro_sheet.dart';
import '../widgets/map/lesson_map.dart';
import '../widgets/map/stats_bar.dart';
import 'lesson_screen.dart';
import 'shop_screen.dart';

/// Startbildschirm: die Abenteuer-Karte mit allen Inseln.
class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessons = ref.watch(lessonsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [
          KawaiiHeart(size: 26),
          SizedBox(width: 8),
          Flexible(child: Text('Robo Python', overflow: TextOverflow.ellipsis)),
        ]),
        actions: [
          IconButton(
            tooltip: 'Robos Shop',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ShopScreen())),
            icon: const Icon(Icons.checkroom_rounded),
          ),
          const BackupButton(),
          const SoundToggleButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: lessons.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Die Inseln konnten nicht geladen werden:\n$e', textAlign: TextAlign.center)),
          data: (lessons) => _MapBody(lessons: lessons),
        ),
      ),
    );
  }
}

class _MapBody extends ConsumerWidget {
  const _MapBody({required this.lessons});

  final List<Lesson> lessons;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final notifier = ref.read(profileProvider.notifier);
    final allUnlocked = ref.watch(allUnlockedProvider);
    final next = lessons.where((l) => (profile.lessonStars[l.id] ?? 0) == 0).firstOrNull;
    final greeting = profile.lessonStars.isEmpty
        ? 'Hallo, ich bin Robo! Gemeinsam lernen wir Python – Insel für Insel. Tippe auf die erste Insel!'
        : next == null
        ? 'Wow, du hast alle Inseln geschafft! Hol dir überall 3 Sterne oder kauf mir ein neues Outfit.'
        : 'Schön, dass du da bist! Als Nächstes wartet: ${next.title}.';

    Future<void> open(Lesson lesson) async {
      final start = await showLessonIntro(context, lesson, profile.outfit, profile.lessonStars[lesson.id] ?? 0);
      if ((start ?? false) && context.mounted) {
        await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LessonScreen(lesson: lesson)));
      }
    }

    /// Gesperrte Insel angetippt: trotzdem starten oder alle freischalten.
    Future<void> locked(Lesson lesson) async {
      final choice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(lesson.title),
          content: const Text('Diese Insel ist noch gesperrt. Du kannst sie trotzdem spielen – '
              'oder gleich alle Inseln freischalten und starten, wo du willst.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Abbrechen')),
            OutlinedButton(
              key: const Key('unlock-all'),
              onPressed: () => Navigator.of(context).pop('all'),
              child: const Text('Alle freischalten'),
            ),
            FilledButton(
              key: const Key('start-anyway'),
              onPressed: () => Navigator.of(context).pop('once'),
              child: const Text('Trotzdem starten'),
            ),
          ],
        ),
      );
      if (choice == 'all') ref.read(allUnlockedProvider.notifier).set(true);
      if (choice != null && context.mounted) await open(lesson);
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const StatsBar(),
                    const SizedBox(height: 12),
                    MascotBubble(text: greeting, robotSize: 84, outfit: profile.outfit),
                    const SizedBox(height: 8),
                    Text('${profile.lessonStars.length} von ${lessons.length} Inseln geschafft · '
                        '${profile.totalStars} von ${lessons.length * 3} Sternen',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.inkSoft)),
                    SwitchListTile(
                      key: const Key('all-unlocked'),
                      contentPadding: EdgeInsets.zero,
                      value: allUnlocked,
                      onChanged: ref.read(allUnlockedProvider.notifier).set,
                      title: const Text('Alle Inseln frei wählen'),
                      subtitle: const Text('Starte, wo du willst – ohne die Reihenfolge'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: LessonMap(
            lessons: lessons,
            stars: profile.lessonStars,
            isUnlocked: (i) => allUnlocked || notifier.isUnlocked(lessons, i),
            onOpen: open,
            onLocked: locked,
          ),
        ),
      ],
    );
  }
}
