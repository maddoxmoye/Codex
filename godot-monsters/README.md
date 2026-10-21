# Woodland monster designs 01

**[Open the monster lineup](https://maddoxmoye.github.io/Codex/monster-preview/)** · [Blender lineup render](https://maddoxmoye.github.io/Codex/monster-preview/lineup.png)

Four original, editable Blender models in an isolated Godot 4.6.3 inspection scene. This pass establishes silhouettes, scale, colors and animation-friendly parts. **The base model library stays static; Briarling now has a separate first motion study.** Sporecaller, Thornback and Hollowhart are still static. Enemy AI and full-game integration are deferred. The woodland is a small visual backdrop, not a performance benchmark or finished arena.

| Design | Proposed role | Visual identity | Proposed damage reaction |
| --- | --- | --- | --- |
| Briarling | Swarm / melee | Seed mask, crooked root limbs, fern collar, hooked thorn fingers | Chest recoil, leaf shake, bark chips |
| Sporecaller | Ranged / area denial | Plum mushroom cap, luminous gills, hanging spore pods | Cap wobble, squash, harmless spore puff |
| Thornback | Heavy / charging | Stocky boar, slate-bark plates, curved ivory tusks | Weighty shoulder jolt; different chips/feedback on armor and exposed areas |
| Hollowhart | Guardian / boss concept | Branch antlers, open ribs, seed-heart, root hammer arms | Bark impact feedback; heart pulse and body recoil on a clean hit |

The table records the original proposals. The Briarling study below implements its first motions and target feedback; the other three rows remain proposals, with no new combat mechanics or animation. The Design notes panel labels them as next steps. After model review, attacks can get readable anticipation and contact/recovery timing; damage reactions can be authored around the rigs rather than simply tinting whole meshes.

## Viewing

Open **Full lineup** to compare real proportions, then select a monster for a closer view. Drag to orbit, use + / − or the wheel to zoom, or enable Turntable to orbit automatically. Woodland switches between the scenery and plain studio. Reset view restores the camera; Fullscreen is available on supporting browsers. Selecting a monster hides the others and recenters it without changing its scale. Camera fitting includes the antlers, tusks and mushroom cap in both desktop and portrait layouts. Native keys 1–5 select the lineup and four models. This is a full-window 3D viewer with overlays, separate from the existing game, Rowan animation study and original roster atelier. It now opens on the Briarling animation study; Full lineup keeps all four designs in rest pose.

## Assets and budgets

The static base models use the existing Wildfall palette-based art style, an embedded 256×256 palette and two material surfaces each. They range from roughly 2,100–4,600 triangles and 9–16 deform bones. They are exported as skinned GLBs in rest pose, without animation clips. Parts are weighted to species-specific bones for the head, cap, hanging pods, limbs, tusked jaw, antlers and seed-heart. These are base deform skeletons, not finished animator-facing IK control rigs, corrective skinning or simulated foliage.

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

## First animation pass: Briarling

`art/blender/animate_briarling.py` derives a separate motion variant from the approved Briarling geometry, adding shin and foot controls for a 13-bone deform rig. It exports **Idle (2.4s), Run (0.72s), Attack (1.2s), Hit (0.55s), and Death (1.4s)** to `assets/briarling-motion.glb` and saves the editable `art/blender/briarling-motion.blend`. The static GLB, source library and the other monsters are unchanged. Bones are baked from Blender poses and analytical leg IK; this is not motion capture, runtime IK or a finished animator control rig.

Selecting Briarling starts a **Demo loop**: breathe, scurry, claw attack, three arrow impacts, defeat, reset. Individual controls let you inspect Scurry, Claw swipe, Test arrow and Idle. Pause and ½× / ¼× speed affect the animation, arrows, health feedback and particles together. The scurry is a baked gait with a small sideways inspection patrol, not navigation AI or a finished root-motion controller. The attack has a crouch/raised-claw windup, lunge, contact marker at **0.56s**, and recovery. The practice post is placed from an exported claw socket at the authored contact pose, then flashes and shows a sample 12-damage label at that marker. This is an authored contact/timing demonstration, **not physical melee collision or player damage**. Getting hit before contact cancels that attack event.

**Test arrow** starts a single physical projectile toward the stationary target. Its swept tip segment is tested against an upright body capsule; a confirmed impact removes **20 HP** from a **60 HP** target, updates the overhead health bar, spawns a matching damage number and bark chips, and plays a recoil. A short body flash leaves the luminous eyes on their original material. Three hits trigger the defeated animation and falling leaf fragments; further arrows are rejected. Reset health restores the target. The demo resets after the defeated pose; there is no campaign loot, experience or persistence here. Effects expire and are bounded by the single-arrow/recovery gating.

The standalone motion controller is `briarling_motion.gd`; `bestiary.gd` handles its stage selection, camera and simulation stepping. It uses the existing woodland backdrop and no additional engine dependency. The source ZIP includes both static and animated Blender studies. In Design notes, Briarling downloads the animated GLB; the base static GLB remains available under `assets/briarling.glb`.

```sh
blender -b --factory-startup --python art/blender/animate_briarling.py
npm run build:monsters
```

The added Node asset test checks the unchanged triangle count, 13-joint normalized skin, five distinct animated clips and release timing. `check_motion.gd` checks actual imported bone motion, forward claw travel from windup to strike, once-only attack contact at 16ms and 100ms steps, interruption before contact, swept arrow impacts, three-hit defeat/reset, pause, repeated demo cycles and effect cleanup. Browser checks cover real WebGL playback, health changes, attack contact, defeat/reset, slow motion/pause, other model views and portrait controls. This small prototype is still not a late-wave or physical iPhone performance benchmark.

Suggested order after Briarling timing review: Sporecaller (cap/pendant follow-through and a lobbed spore), Thornback (weight shift and a telegraphed charge), then Hollowhart (slow slam and seed-heart reaction). Only after these readable motions are approved should a small Rowan/fox combat encounter exercise the Godot gameplay integration.
