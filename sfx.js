// Soundeffekte über die Web-Audio-API.
//
// Warum nicht einfach <audio>? Browser (vor allem Safari auf dem iPhone/iPad) spielen
// Ton nur ab, wenn er direkt durch einen Tipp ausgelöst wurde. Die Soundeffekte
// kommen aber oft kurz NACH dem Tipp (z. B. nach dem Prüfen einer Antwort) und
// wurden deshalb blockiert. Hier wird der Audio-Kontext beim ersten Tippen einmal
// freigeschaltet – danach funktionieren alle Effekte.
(function () {
  var NAMES = ['move', 'coin', 'error', 'success', 'correct', 'wrong', 'tap'];
  var AC = window.AudioContext || window.webkitAudioContext;
  var ctx = null;
  var buffers = {};
  var loading = null;

  // iOS 17+: Ton auch bei eingeschaltetem Stumm-Schalter abspielen.
  try {
    if (navigator.audioSession) navigator.audioSession.type = 'playback';
  } catch (e) {}

  function context() {
    if (!ctx && AC) {
      try { ctx = new AC(); } catch (e) { ctx = null; }
    }
    return ctx;
  }

  function decode(c, data) {
    return new Promise(function (resolve, reject) {
      // Ältere Safari-Versionen kennen nur die Callback-Variante.
      var p = c.decodeAudioData(data, resolve, reject);
      if (p && p.then) p.then(resolve, reject);
    });
  }

  function load() {
    var c = context();
    if (!c || loading) return loading;
    loading = Promise.all(NAMES.map(function (name) {
      return fetch('assets/assets/sounds/' + name + '.wav')
        .then(function (r) { return r.arrayBuffer(); })
        .then(function (data) { return decode(c, data); })
        .then(function (buffer) { buffers[name] = buffer; })
        .catch(function () {});
    }));
    return loading;
  }

  function unlock() {
    var c = context();
    if (!c) return;
    if (c.state !== 'running') c.resume().catch(function () {});
    // Ein stiller Mini-Ton im Tipp selbst schaltet Safari frei.
    try {
      var src = c.createBufferSource();
      src.buffer = c.createBuffer(1, 1, 22050);
      src.connect(c.destination);
      src.start(0);
    } catch (e) {}
    load();
  }

  ['pointerdown', 'pointerup', 'touchstart', 'touchend', 'mousedown', 'click', 'keydown'].forEach(function (type) {
    window.addEventListener(type, unlock, { capture: true, passive: true });
  });
  document.addEventListener('visibilitychange', function () {
    if (!document.hidden && ctx && ctx.state !== 'running') ctx.resume().catch(function () {});
  });

  function play(name) {
    var c = context();
    if (!c) return;
    if (c.state !== 'running') c.resume().catch(function () {});
    var buffer = buffers[name];
    if (!buffer) {
      // Noch nicht geladen: laden und dann abspielen.
      var p = load();
      if (p) p.then(function () { if (buffers[name]) start(c, buffers[name]); });
      return;
    }
    start(c, buffer);
  }

  function start(c, buffer) {
    try {
      var src = c.createBufferSource();
      src.buffer = buffer;
      src.connect(c.destination);
      src.start(0);
    } catch (e) {}
  }

  window.roboSfx = { play: play };
})();
