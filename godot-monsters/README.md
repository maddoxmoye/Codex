# Woodland monster designs 01

**[Open the monster lineup](https://maddoxmoye.github.io/Codex/monster-preview/)** · [Blender lineup render](https://maddoxmoye.github.io/Codex/monster-preview/lineup.png)

Four original, editable Blender models in an isolated Godot 4.6.3 inspection scene. This pass establishes silhouettes, scale, colors and animation-friendly parts. **The models are static.** Attack animations, animated hit reactions, enemy AI, gameplay collision and full-game integration are deferred until design review. The woodland is a small visual backdrop, not a performance benchmark or finished arena.

| Design | Proposed role | Visual identity | Proposed damage reaction |
| --- | --- | --- | --- |
| Briarling | Swarm / melee | Seed mask, crooked root limbs, fern collar, hooked thorn fingers | Chest recoil, leaf shake, bark chips |
| Sporecaller | Ranged / area denial | Plum mushroom cap, luminous gills, hanging spore pods | Cap wobble, squash, harmless spore puff |
| Thornback | Heavy / charging | Stocky boar, slate-bark plates, curved ivory tusks | Weighty shoulder jolt; different chips/feedback on armor and exposed areas |
| Hollowhart | Guardian / boss concept | Branch antlers, open ribs, seed-heart, root hammer arms | Bark impact feedback; heart pulse and body recoil on a clean hit |

The ideas above are **proposals**, not implemented combat behavior, weak-point mechanics, shaders or animation. The Design notes panel labels them as next steps. After model review, attacks can get readable anticipation and contact/recovery timing; damage reactions can be authored around the rigs rather than simply tinting whole meshes.

## Viewing

Open **Full lineup** to compare real proportions, then select a monster for a closer view. Drag to orbit, use + / − or the wheel to zoom, or enable Turntable to orbit automatically. Woodland switches between the scenery and plain studio. Reset view restores the camera; Fullscreen is available on supporting browsers. Selecting a monster hides the others and recenters it without changing its scale. Camera fitting includes the antlers, tusks and mushroom cap in both desktop and portrait layouts. Native keys 1–5 select the lineup and four models. This is a full-window 3D viewer with overlays, separate from the existing game, Rowan animation study and original roster atelier.

## Assets and budgets

The models use the existing Wildfall palette-based art style, an embedded 256×256 palette and two material surfaces each. They range from roughly 2,100–4,600 triangles and 9–16 deform bones. They are exported as skinned GLBs in rest pose, without animation clips. Parts are weighted to species-specific bones for the head, cap, hanging pods, limbs, tusked jaw, antlers and seed-heart. These are base deform skeletons, not finished animator-facing IK control rigs, corrective skinning or simulated foliage.

`assets/woodland.glb` contains 11,116 triangles in one merged static mesh with one material: opaque tree crowns, roots, a pale path, rocks, ferns, fallen log, fungi and broken waystones. Scenery is kept around the edges of the clearing. This deliberately small scene has no collision/navigation data, baked lighting, LOD system, foliage wind or enemy horde. It uses simple Godot lighting with one shadow-casting directional light. FPS shown by the viewer measures this static scene only; smoothness under actual late-wave gameplay still needs device testing.

The editable library is `art/blender/wildfall-monsters.blend`. It contains four separately rigged monster collections, one environment collection, packed palette and a presentation camera/light setup. Each GLB is exported at the origin, in meters. The .blend stages their rigs at lineup positions for review. Blender is Z-up / −Y forward; Godot receives Y-up / +Z forward. The small Briarling is approximately 1.35m tall; Hollowhart reaches approximately 3.03m including antlers. Scale remains adjustable during gameplay integration.

**Blender files** downloads the source `.blend`, palette, generator, shared geometry helpers, render, GLBs, manifest and Godot project. Individual monster GLBs are available in Design notes. The previous roster and animation source archives remain separate.

## Rebuild and validate

```sh
blender -b --factory-startup --python art/blender/build_monsters.py
npm test
npm run build:godot
npm run build:monsters
PORT=3002 node server.mjs
```

Then open `/dist/monster-preview/`. Add `-- --no-render` to skip the Cycles lineup render. Blender 4.3+ and Godot 4.6.3 are used here. The build shares the existing single-threaded web engine but exports a separate project pack, runs `check_assets.gd` and packages the source ZIP.

Node checks verify GLB bounds/indices, finite vertices, palette UVs, normalized skin weights and valid joints, material/triangle budgets, embedded palette sizes, absence of animations and opaque static scenery. Godot checks verify importable skeletons and skin surfaces, selection/lineup spacing, scenery toggles and camera fitting at front/side/back angles on desktop and portrait viewports. Browser checks cover actual Godot web rendering, selecting all designs, drag orbit, turntable, scenery toggles, design notes/download links and portrait layout. No physical iPhone performance claim is made.
