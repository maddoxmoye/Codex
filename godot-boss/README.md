# The Briar King — first boss animation study

Preview: **https://maddoxmoye.github.io/Codex/boss-preview/**

An original Blender model and Godot 4.6.3 attack study for the first of Wildfall's four guardians, **The Briar King** (wave 5). This is an isolated design review; the current game, campaign AI, balance, saved progress, monster studies and character/pet preview remain unchanged.

The king has a five-point thorn crown, a carved wooden mask, split trunk armor, an amber seed-heart, an overlapping leaf mantle, a massive right root gauntlet and a living seed cannon on his left arm. His crown reaches about **3.82 meters**, versus Rowan's roughly 2.1-meter silhouette at the same world scale. **Rowan for scale** brings the actual approved archer GLB into the model view. The king is a new mesh and rig, rather than a scaled copy of Hollowhart.

## Two attacks

- **Thronebreaker / close:** a deliberate overhead raise and crouching ground slam. A full-size ground circle warns before the 1.55-second contact. The actual authored knuckle lands about 0.08m above the floor while the feet stay planted. A ring then expands across the marked area over 0.6s, hitting the nearby demonstration target once as it reaches that target. The king recovers his weight before the next attack.
- **Briar Decree / ranged:** the left seed cannon rises and charges. Its shoulder pods open and the heart/muzzle brighten, while three floor lanes identify the fixed target directions. Salvos at 1.20, 1.55 and 1.90 seconds each launch **three visible thorn spears**. Each spear launches from the exported cannon socket, travels straight at 8m/s, tests its swept segment against a target and stops on impact. No homing or invisible instant damage is used. Damage numbers, target flashes, bark chips and embedded thorns show the impacts.

Both attacks use complete baked body poses with separate windup, impact/release and recovery. The spear release samples the authored socket at its release marker even when a slow frame skips across that instant. The scene advances in substeps, and tests also exercise large frame skips directly. Attacks repeat in their individual review tabs; **Demo loop** alternates both attacks, a heavy stride and an incoming-arrow hit reaction.

## Controls and scope

Choose an attack card, or let Demo loop run. Auto camera pulls back to show attacks and returns to the model between them. Full model, Attack arena and Heart detail are separate framing choices. Drag/touch to orbit, scroll to zoom, or reset the view. **Hold windup** freezes the last chosen attack before release; Resume plays it out. Pause, ½×/¼× speed, woodland/plain studio and fullscreen are available. Native keys 1/2 select attacks; P pauses.

**Hit with arrow** sends a visible arrow into the core, reduces the demonstration boss health, flashes the bark and triggers an authored recoil. **Defeat** plays a kneeling collapse and fades the heart; Reset boss restores him. The 1,200 HP and attack damage values are presentation values, not a balance proposal or integration into the existing game's difficulty.

The preview uses three fixed target posts and one nearby post to make timing clear. Enemy decision-making, chasing a live player, navigation/collision, distance-based attack selection, invulnerability rules, rewards, campaign replacement and the other three bosses are later integration work. Rowan is only a scale reference, not an active combatant in this scene.

## Art and performance

The delivery has **6,092 triangles, 23 deform bones and three shared-palette materials**. The 256×256 palette is embedded in the GLB; all skin weights are normalized, with at most four influences per vertex. The six clips are Idle, Run, Melee, Ranged, Hit and Death. Analytic limb IK, planted feet, secondary mantle/pod/crown motion and hand placement are evaluated in Blender and baked into skeletal animation. The hands are stylized; there is no facial rig, physics cloth or third-party motion capture. Thorn flight, warnings, shockwaves, impacts and heart brightness run in Godot.

The existing low-poly woodland is one merged static backdrop; the web project shares the existing Godot Compatibility engine. No threaded export or paid engine/plugin is required. Projectiles expire, embedded thorns are capped at 18, and effects are checked over repeated sequences. This small scene has not been benchmarked on a physical iPhone and does not predict the cost of a full boss wave. Software-rendering browser checks can run slower than wall time because the simulation caps frame deltas.

## Editable delivery and rebuilding

Download **Blender + Godot files** for `briar-king.blend`, the geometry/animation generator, palette, rendered portrait, animated GLB, timing/socket metadata and the complete Godot project. The source includes a lit Blender studio and camera. Model, animation, materials and accessories are original procedural assets built for Wildfall.

```sh
blender -b --factory-startup --python art/blender/build_briar_king.py
npm run build:godot
npm run build:boss
PORT=3002 node server.mjs
```

Open `http://localhost:3002/dist/boss-preview/`, or open `godot-boss/project.godot` in Godot 4.6.3. Web controls live in the HTML shell; the native project starts its demo automatically and supports the keyboard/orbit controls above. Content-hashed project packs prevent browsers reusing an older boss animation after a deployment.

`check_boss.gd` validates rig/clip budgets, actual raised/ground-contact socket heights, planted feet, warning-before-contact order, one slam hit, three salvos/nine thorns and nine real target impacts at 16ms/100ms/600ms. It checks paused held windups, arrow impacts, attack interruption, defeat and bounded effects across 90 seconds of repeat playback. Asset tests inspect GLB geometry, palette UVs, normalized skin, distinct animation tracks and source presence. Browser review covers model/attack views, both held windups and impacts, damage, defeat, Rowan scale and portrait layout.
