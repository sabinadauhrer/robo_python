{{flutter_js}}
{{flutter_build_config}}

// Eigener Start: Nach dem Hochfahren von Flutter wird der Ladebildschirm ausgeblendet.
_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
    // Kurz warten, bis das erste Bild gezeichnet ist.
    setTimeout(function () {
      const el = document.getElementById('loading');
      if (!el) return;
      el.classList.add('hidden');
      setTimeout(function () { el.remove(); }, 500);
    }, 400);
  },
});
