import 'dart:js_interop';

@JS('roboSfx')
external JSObject? get _roboSfx;

@JS('roboSfx.play')
external void _play(JSString name);

/// Ist `web/sfx.js` geladen?
bool get webSfxAvailable => _roboSfx != null;

void webPlaySfx(String name) {
  try {
    _play(name.toJS);
  } catch (_) {
    // Ton darf das Spiel nie stören.
  }
}
