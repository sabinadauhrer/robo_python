import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';
import 'sfx.dart';
import 'web_sfx_stub.dart' if (dart.library.js_interop) 'web_sfx_web.dart';

/// Spielt Soundeffekte ab. Austauschbar, damit Tests stumm laufen.
abstract interface class SoundPlayer {
  void play(Sfx sfx);
  void dispose();
}

/// Echte Wiedergabe mit `audioplayers` – ein Player pro Effekt.
class AudioSoundPlayer implements SoundPlayer {
  final _players = <Sfx, AudioPlayer>{};

  @override
  void play(Sfx sfx) {
    final player = _players.putIfAbsent(sfx, () {
      final p = AudioPlayer();
      if (!kIsWeb) p.setPlayerMode(PlayerMode.lowLatency).ignore();
      p.setReleaseMode(ReleaseMode.stop).ignore();
      return p;
    });
    // Fehler beim Abspielen (z. B. Browser blockiert Audio) sollen das Spiel nie stören.
    player.stop().then((_) => player.play(AssetSource('sounds/${sfx.name}.wav'))).catchError((_) {});
  }

  @override
  void dispose() {
    for (final p in _players.values) {
      p.dispose().ignore();
    }
    _players.clear();
  }
}

/// Im Browser: Wiedergabe über `web/sfx.js` (Web Audio). Das funktioniert auch auf
/// dem iPhone, wo `audioplayers` Töne blockiert, die nicht direkt im Tipp starten.
class WebSoundPlayer implements SoundPlayer {
  @override
  void play(Sfx sfx) => webPlaySfx(sfx.name);

  @override
  void dispose() {}
}

/// Stumm – für Tests.
class SilentSoundPlayer implements SoundPlayer {
  final played = <Sfx>[];

  @override
  void play(Sfx sfx) => played.add(sfx);

  @override
  void dispose() {}
}

final soundPlayerProvider = Provider<SoundPlayer>((ref) {
  if (kIsWeb && webSfxAvailable) return WebSoundPlayer();
  final player = AudioSoundPlayer();
  ref.onDispose(player.dispose);
  return player;
});

/// Spielt einen Effekt, falls Sound in den Einstellungen eingeschaltet ist.
void playSfx(WidgetRef ref, Sfx? sfx) {
  if (sfx == null || !ref.read(soundEnabledProvider)) return;
  ref.read(soundPlayerProvider).play(sfx);
}
