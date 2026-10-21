# Wildfall Model Atelier

Inspect the **actual Blender-exported models rendered in Godot** at:

**https://maddoxmoye.github.io/Codex/models/**

Select any of five archers or three pets. Drag to orbit, use the mouse wheel or **+ / −** buttons to zoom, and **Reset camera** to resume the automatic turntable. Switch **Idle / Walk (or Trot / Hover) / Rest pose**. Touch dragging works on phones. The viewer opens into a full-window stage and shares the single-threaded Godot 4.6.3 web engine used by the Moonwell demo. It is an isolated asset viewer and never reads or changes Wildfall saves.

The page offers individual GLBs and a **Blender + GLB** ZIP with the editable library, build source, model exports, Godot project and lineup image. The original game and Moonwell demo remain at their existing URLs. This first pass does not migrate gameplay or establish full-game mobile performance.

## Native Godot inspection

Open `project.godot` in **Godot 4.6.3**, let GLBs import, and run the project. Left/right changes models; Space switches idle/movement; R resets the pose; A toggles auto rotation. Drag and wheel inspect the model. The base rigs and clips are initial motion studies; see `../art/blender/README.md` for design scope and limitations.

## Web build

From the repository root, with matching Godot web tools installed:

```sh
npm run build:godot
npm run build:models
PORT=3002 node server.mjs
```

Open `http://localhost:3002/dist/models/`. If using the downloaded official tools, set `GODOT_BIN="$PWD/.godot-tools/godot"` for both build commands. The web viewer uses `../godot-demo/engine.js` and `engine.wasm`, with its own `roster.pck`. Deploy both directories together; the build does not replace the current game's main page. Godot imported PNGs and per-asset import settings are checked in so resources stay reproducible.

Validation covers GLB structure, geometry/material budgets, finite mesh data, nonempty palette UVs, normalized weights, joint indices, texture sizes and distinct clip data. A headless Godot check imports all eight scenes and verifies both animation clips move their skeletons. The atelier build runs that check before exporting. Godot import generates display LODs; original source triangle counts are shown in the viewer.
