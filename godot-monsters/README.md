# Woodland bestiary — four monster motion studies

**[Open the animated bestiary](https://maddoxmoye.github.io/Codex/monster-preview/)** · [Original Blender lineup render](https://maddoxmoye.github.io/Codex/monster-preview/lineup.png)

All four original monster designs now have Blender-authored Idle, Run, Attack, Hit and Death clips, played in an isolated Godot 4.6.3 preview. The woodland, approved static models, original Blender library, existing game, Rowan/fox preview and saved game progress are preserved. The base static library is still available for design comparison. This scene demonstrates animation, telegraphs and target feedback; it is not the campaign, enemy AI or a finished combat system.

| Monster | Movement and attack | Hit/defeat feedback | Motion rig |
| --- | --- | --- | --- |
| Briarling | Quick scurry, raised-claw windup, lunge and swipe | Bark chips, leaf shake, recoil and collapse | 13 bones / 2,156 triangles |
| Sporecaller | Waddle, squashing cap, swinging pods, brightening gills and a lobbed spore | Cap/pendant wobble, harmless loose spores, soft collapse | 9 bones / 3,714 triangles |
| Thornback | Planted quadruped trot, braced hooves, lowered tusks and a heavy charge | Dust, slate-colored armor chips, shoulder recoil and side topple | 17 bones / 4,542 triangles |
| Hollowhart | Heavy steps, raised root hammers, crouching slam and expanding shockwave | Torso stagger, swaying antlers, pulsing seed-heart and buckled defeat pose | 18 bones / 3,166 triangles |

These are species-specific deform rigs and authored clips, not copies of the human archer animation. Additional hoof/toe controls keep feet flat during the analytical IK cycles. Bone transforms and scale are baked in Blender and exported in GLB; the source libraries are editable but do not contain finished animator-facing IK control panels, facial/finger articulation, ragdolls or cloth simulation.

## Preview controls

Select a monster to start its **Demo loop**: idle, movement, attack, three incoming arrows, defeated pose and reset. Movement and attack buttons play individual examples. **Hold windup** seeks to an authored preparation pose and pauses; **Resume** then carries the attack through its release/contact and recovery. **Test arrow** fires a single projectile at a stationary target. Three hits defeat each preview target; **Reset health** brings it back. Pause and ½× / ¼× speed affect the animation, root motion, projectiles, telegraphs, damage numbers and effects together.

**Attack view** frames more of the ground/flight path, with extra room for the charge and shockwave. **Close detail** returns to the model framing. Drag to orbit, use + / − or the wheel to zoom, Turntable to orbit automatically, and Reset view to reset the camera. Woodland toggles the environment. Fullscreen is offered on supporting browsers. The controls scroll horizontally on narrow screens. **Full lineup** shows all four motion variants in their original rest poses at their real proportions, without attack props or health bars. Native keys 1–5 select the lineup/monsters; web selection uses the visible buttons.

## Timing and feedback

- **Briarling:** 1.2s attack; contact at 0.56s. A practice post is positioned from its authored claw socket. Windup interruption cancels the contact event. Its 60 HP target takes 20 damage per test arrow.
- **Sporecaller:** 2.2s attack; release at 0.72s. A visible spore leaves an animated head socket, follows a 1.05s parabola and lands in a purple warning circle, producing a puff and ring. One release produces one landing. A launched spore continues if the caster recoils; an interrupted pre-release windup does not spawn it. The 90 HP target takes 30 damage per arrow.
- **Thornback:** 2.65s attack; charge begins at 0.78s, advances 1.65m and reaches the contact marker at 1.23s. An amber lane and chevrons precede the burst; dust follows the hooves. It brakes, holds briefly and returns to its start during recovery. The 120 HP target takes 40 damage per arrow.
- **Hollowhart:** 3.1s attack; slam at 1.42s. Both fists move from overhead toward the ground while its legs brace and chest leans. A red warning circle precedes the expanding shockwave. The 180 HP target takes 60 damage per arrow; recoil scales/pulses the seed-heart and briefly brightens the luminous surface (including the eyes).

Incoming arrows use swept tip segments against upright body capsules. A confirmed impact updates the health bar, emits the matching damage number, flashes the body while retaining the original luminous surface, scatters species-specific debris and starts recoil or defeat. Arrow damage values are illustrative preview values, chosen for a three-hit review cycle; they do **not** change campaign balance. Body capsules are a simple target test, not per-limb armor or weak-point collision. Thornback's armor chips and the guardian's seed-heart feedback are visual studies, not implemented armor/weak-point modifiers.

The small practice markers show example damage values (12 / 14 / 24 / 36). Melee contact markers and the slam ring demonstrate authored timing; they do **not** physically hit a player, damage scenery or run full-game area-of-effect collision. The spore's path/ground landing is simulated to its training marker. Root movement is a small inspection patrol or authored charge/recovery path, not pathfinding. Effects expire, only one incoming arrow is allowed at a time, and each attack has a once-only release/contact guard.

## Source and downloads

**Blender files** downloads both static and animated editable libraries, packed palettes, generators, the original lineup render, all GLBs/metadata and the Godot project. Design notes downloads the selected animated GLB. Static GLBs remain under `assets/<id>.glb`; motion variants are `assets/<id>-motion.glb` with matching JSON metadata.

- `art/blender/wildfall-monsters.blend`: approved static monster lineup and woodland.
- `art/blender/briarling-motion.blend`, generated by `animate_briarling.py`.
- `art/blender/sporecaller-motion.blend`, `thornback-motion.blend`, `hollowhart-motion.blend`, generated by `animate_monsters.py`.
- `briarling_motion.gd`: shared lifecycle, health, arrow target test, pause/demo and material feedback; retains Briarling's original contact study.
- `monster_motion.gd`: spore flight, charge lane/dust, slam warning/shockwave and species-specific effects.

Source files open with the Attack action active at a windup pose; other actions are saved as muted NLA tracks. Select the desired action, or unmute/isolate its NLA track, to inspect in Blender. The static GLBs and `.blend` library are never overwritten by animation generators. All use meters, Blender Z-up / −Y forward, exported Godot Y-up / +Z forward. The Briarling is about 1.35m tall and Hollowhart about 3.03m including antlers.

The shared environment is a single merged static mesh with one material and 11,116 triangles: opaque tree crowns, roots, a path, rocks, ferns, fallen log, fungi and broken waystones. It has no navigation/collision data, baked lighting, LOD system or foliage wind. Godot uses one shadow-casting directional light and simple fill lights. This is a small animation scene; FPS is not a full-game, late-wave or physical iPhone performance benchmark.

## Rebuild and validation

```sh
blender -b --factory-startup --python art/blender/build_monsters.py
blender -b --factory-startup --python art/blender/animate_briarling.py
blender -b --factory-startup --python art/blender/animate_monsters.py
npm test
npm run build:godot
npm run build:monsters
PORT=3002 node server.mjs
```

Open `/dist/monster-preview/`. The first command renders the static lineup; append `-- --no-render` to skip that render. To rebuild one new species, append e.g. `-- sporecaller` to the `animate_monsters.py` command. Blender 4.3+ and Godot 4.6.3 are used here. The build shares the existing single-threaded web engine, exports a content-versioned project pack to avoid stale browser caches, runs all Godot checks and packages the source.

Node tests validate the approved/static and animated GLBs, finite geometry, triangle/material/joint budgets, normalized skin weights, palette UVs, embedded texture sizes, distinct clips and timing metadata. Godot tests validate imported bone motion, desktop/portrait framing, forward claw travel, raised-to-ground guardian hands, single contacts at 16ms/100ms steps, spore launch/flight/pause/landing and post-launch recoil, interruption before release, charge displacement, physical incoming arrow hits, three-hit defeat/reset, held-windup/resume and repeated effect cleanup. Browser tests exercise actual Godot WebGL playback, each attack, target damage, inspection controls, cameras, downloads, scenery toggles and portrait layout.
