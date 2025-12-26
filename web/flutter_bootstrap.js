{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();

    // Remove the loading indicator once the engine is ready
    const loader = document.getElementById('loading-container');
    if (loader) {
      loader.remove();
    }

    await appRunner.runApp();
  }
});
