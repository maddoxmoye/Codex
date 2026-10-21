# The four guardians — Blender → Godot

Preview: **https://maddoxmoye.github.io/Codex/boss-preview/?boss=frost-oracle**

Four original Blender models with baked skeletal animation, rendered in Godot 4.6.3 Compatibility. This is a standalone combat/design study. The published campaign and saved progress are unchanged. Use the four boss buttons to compare the models and attack patterns; Briar King remains the default for existing links.

| Guardian | Wave | Proposed HP | Close attack | Ranged attack |
| --- | --- | --- | --- | --- |
| Briar King | 5 | 1,200 | Thronebreaker: 36 slam | Briar Decree: 3×3 thorns, 16 per hit |
| Frost Oracle | 10 | 2,100 | Crystal Prison: 52 rising ice + 26 detonation | Avalanche Heart: one 1.9m ice heart, 58 direct / 29 blast; eight 18-damage fragments |
| Hollow Monarch | 15 | 3,400 | Reaper’s Crossing: lunging 64 + 32 scythe combo | Widow’s Orbit: one large curved returning scythe, 46 outward / 23 return |
| Gilded Colossus | 20 | 5,200 | Iron Stampede: 88 charge + 44 ground rupture | Daybreak Engine: sweeping 1.9s sunbeam, 18 damage per contact tick |

These values demonstrate progression; they are not final campaign balance. Damage is applied to fixed demonstration posts, rather than a live player. Floor warnings precede attacks, and hit flashes/numbers show damage. Oracle raises a crescent of actual ice pillars with an escape opening, then detonates the interior; its huge ice heart breaks into outward-moving fragments. The trail frost is decorative. Monarch physically lunges through its attack corridor and throws a spinning scythe along separate outward/return lanes, with at most one hit per target per pass. Colossus physically charges through a narrow marked lane and then sweeps a continuous beam from its animated cannon socket. Beam damage has a 0.45s per-target cooldown and ends with its active window. These three attacks replace the previous shared slam/volley pattern; the approved Briar King is unchanged. Each new guardian has six clips: Idle, Run, Melee, Ranged, Hit and Death. Colossus additionally has Summon.

## Brood Furnace

The Colossus opens its two chest doors in a dedicated animation. Three release markers emit two enemies each from its animated hatch socket. The six skinned Briarlings visibly arc out, land, turn, approach nearby posts and attack with their approved attack animation. Each has 60 HP and deals 14 damage once per 1.35-second attack cycle. Stable movement, bounded turning, a short anchored lunge and explicit animation states avoid a physics-driven pileup.

The preview caps **living summons at six**. Further furnace cycles replenish defeated enemies. **Strike brood** deals 30 damage to the first living summon; two hits demonstrate recoil, health loss and death. Summons persist through other boss attacks, pause with the scene, and die when their boss is defeated. Reset and switching bosses remove the old encounter. Campaign navigation, player targeting and spawn-rate balance remain integration work.

## Review controls

Select a boss and choose an attack card; **3** selects Summon for Colossus. Keys **1/2** select close/ranged and **P** pauses. Demo loop cycles attacks; Colossus summons first and then fires its beam while the brood remains active. **Hold windup** freezes the last attack before release. Full model, Attack arena, Heart detail, drag/touch orbit, scroll zoom, slow motion, woodland/plain backdrop, fullscreen and Rowan for scale are available.

**Hit with arrow** triggers an actual projectile impact, health loss and authored recoil. **Defeat** plays the collapse and darkens the core. Reset restores the encounter. On native Godot builds, keyboard/orbit controls are available; the full review HUD belongs to the web shell.

## Editable art and budgets

Each guardian has a distinct silhouette, original geometry, 23 deform bones, three palette materials and fewer than 10,000 triangles. Oracle floats in a crystal gown beneath an orbiting halo; Monarch carries a crescent scythe beneath swept horns and a torn cloak; Colossus has piston arms, a sun cannon, hammer fist and hinged furnace doors. Briar King’s approved mesh/animations are preserved. All four use baked authored motion, normalized weights and embedded palette textures. The minions reuse the approved 2,156-triangle, 13-bone Briarling model.

The **Blender + Godot files** download includes all four editable `.blend` studios, generators, portraits/lineup, GLBs, timing/socket metadata and the Godot project. The legacy filename `briar-king-source.zip` is retained for existing links. No paid engine or plugin is required. The preview shares the existing Godot web engine and has a content-hashed project pack.

```sh
blender -b --factory-startup --python art/blender/build_briar_king.py
blender -b --factory-startup --python art/blender/build_guardians.py
blender -b --factory-startup --python art/blender/render_guardian_lineup.py
npm run build:godot
npm run build:boss
PORT=3002 node server.mjs
```

Open `http://localhost:3002/dist/boss-preview/` or `godot-boss/project.godot` in Godot 4.6.3. This small scene has not been benchmarked on a physical iPhone and does not establish full-wave performance.

`check_boss.gd` preserves the original King’s socket, planted-foot, warning, projectile, pause, interruption, defeat and camera checks. `check_guardians.gd` exercises the three new rigs, exact hit counts/damage at 16/100ms, one giant ice heart/eight fragments, return-hit limits, continuous beam ticks, safe areas outside attack geometry, root motion, held windups, mobile/desktop framing, autonomous summons, spawn cap, pause, death, replenishment and bounded effects across repeated playback. Node tests inspect exported geometry, skin, clips, metadata and editable source. Browser checks exercise selection, real attacks, hatch/minions, defeat/reset and portrait layout.

The five archer model heights are 1.98–2.155m. Boss heights are 3.82m (King), 4.16m (Oracle), 4.49m (Monarch) and 4.94m (Colossus), including their crowns/halos. Rowan for scale loads the actual archer at the same world scale. Final difficulty still needs testing with a playable character and live boss AI.
