import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../audio/sfx.dart';
import '../../../audio/sound_player.dart';
import '../../../state/providers.dart';

/// Lautsprecher-Knopf: Soundeffekte an/aus (wird gespeichert).
class SoundToggleButton extends ConsumerWidget {
  const SoundToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(soundEnabledProvider);
    return IconButton(
      tooltip: enabled ? 'Ton ausschalten' : 'Ton einschalten',
      onPressed: () {
        ref.read(soundEnabledProvider.notifier).set(!enabled);
        playSfx(ref, Sfx.tap); // nur hörbar, wenn gerade eingeschaltet wurde
      },
      icon: Icon(enabled ? Icons.volume_up_rounded : Icons.volume_off_rounded),
    );
  }
}
