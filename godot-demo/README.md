# The Moonwell — Godot iPhone graphics study

Open **https://maddoxmoye.github.io/Codex/godot-demo/** directly in iPhone Safari, tap **Enter the grove**, and watch. No movement controls, app installation, Apple developer account, or Wildfall save access are required. First load transfers approximately 37 MB uncompressed; Safari may receive a compressed response. Landscape shows more of the clearing; portrait reframes the camera automatically.

This is an actual **Godot 4.6.3** single-threaded WebAssembly / WebGL 2 export, using the Compatibility renderer. It works on ordinary static hosting without cross-origin-isolation headers or SharedArrayBuffer. It is a browser graphics sample, **not a native iOS performance benchmark**, a full game, or an indication of how many enemies a phone will handle. A native Godot app can perform differently, and this light scene has no combat simulation, physics workload, or large crowds. Test on your real phone; desktop software rendering and a resized browser cannot establish iPhone frame rates.

The original procedural diorama includes a floating clearing, instanced foliage and stonework, directional shadows, an orbiting camera, a bobbing crystal and rings, fireflies, an animated patrol/shooting archer, visible arrows and a floating fox familiar. The archer is a simple articulated procedural model, not a Blender/skeletal animation showcase. All geometry, materials and animation are generated locally; no external asset downloads or paid assets.

**Balanced** starts at 75% 3D resolution with 2× MSAA and shadows. **Light** uses 60% with no MSAA or shadows. **High detail** uses 100% with 2× MSAA and shadows. The 3D pixel ratio is capped at 1.5 before those multipliers to avoid rendering every Retina pixel on phones. HTML UI remains at native display resolution. The FPS overlay reports current Godot FPS, average rendered-frame rate after a five-second warmup, draw calls and triangles. Changing detail resets the average. Pause stops animation and pauses measurement; it does not stop rendering. Switching away pauses the animation; tap Resume on return. There is no audio. Fullscreen is optional where the browser supports it; the canvas always fills the window.

## Build locally

Install Node and Python/unzip/curl, then from the repository root:

```sh
bash scripts/install-godot-web.sh
GODOT_BIN="$PWD/.godot-tools/godot" npm run build:godot
PORT=3001 node server.mjs
```

Open `http://localhost:3001/dist/godot-demo/`. If Godot 4.6.3 is already on PATH, only the matching web template is needed at `godot-demo/.templates/web_nothreads_release.zip`; `npm run build:godot` then uses `godot` directly. Godot's editor can also open `project.godot`. Generated output lives under ignored `dist/`; editor caches and downloaded templates are ignored. GitHub Actions installs/caches the pinned official tools and rebuilds the demo alongside the existing game on each deployment.

Godot Engine is MIT-licensed; see [GODOT-LICENSE.txt](GODOT-LICENSE.txt). The complete engine and bundled dependencies' license notices are exported with the demo.
