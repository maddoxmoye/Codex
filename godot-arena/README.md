# First Hunt — three-wave Godot run

Play: **https://maddoxmoye.github.io/Codex/arena-demo/**

A separate Godot 4.6.3 Compatibility project using the approved Blender-built Rowan, Forest Fox, Briarling, Sporecaller, Thornback and Briar King. The campaign, its shop, saves and previous model/animation previews are unchanged. This demo stores no persistent progress and needs no paid engine or plugin.

**Play the encounter** starts a three-wave run. Waves one and two last **45 seconds** each, with a camp between waves. Wave two brings tougher, faster enemies and more frequent reinforcements. Wave three lasts **75 seconds** and adds the Briar King, using his approved Thronebreaker and Briar Decree animations against the actual player. Killing him early does not end the wave; if he survives the timer, combat continues in overtime until he falls. The top-center timer shows time remaining.

**Try the shop & upgrades** opens a sample first camp with 60 gold and one earned level reward, then lets you continue into waves two and three. **Practice against the King** remains a separate, unscaled boss encounter without shops; defeating him ends that practice immediately. Victory and defeat offer clean restarts.

## Between waves: training and equipment

Experience requirements rise by level: reaching level two costs 60 XP, then the next level costs 120, then 180. Levels gained during combat queue rewards without interrupting the wave. At camp, a dedicated training screen presents **four random choices** from health, arrow damage, shared elemental power, armor and movement speed. Choose one for free for each earned level. The item shop opens after all queued choices are resolved.

The trader stocks **four illustrated items** at a time, with common, uncommon, rare and red-glowing mythic rarities. Buy any number you can afford; purchased slots stay sold until you reroll. The 27-item catalog includes equipment for arrow damage, attack speed, armor, health, movement, critical hits, regeneration, fox damage, cooldowns, pickup radius, gold income and Economy, plus fire/ice/poison equipment. Field Bandages heal immediately and cannot be purchased at full health. The mythic Heartwood Relic prevents one lethal hit per run and cannot appear again after purchase.

Rerolling replaces the four offers. The base cost starts at 5 gold in the first camp and 7 in the second; each reroll in the same visit adds 5. Economy discounts both items and rerolls, up to 50%. Further copies of an item cost 15% more per copy already purchased, before discounts. Reroll escalation resets at the next camp. The shop shows your level, wallet, current/base stats and all training and purchased items. The pause menu also shows stats and inventory; purchases are only available between waves.

Only the equipped element's gear appears in the shop. Switching elements discards every active item associated with the old element, including its damage multipliers and special bonuses. Shared elemental power, normal equipment and level rewards remain. Switching back does not restore discarded gear; inventory retains it as a discarded entry. The demo allows element selection from its HUD and camp so these build rules can be tested directly.

## Controls

- **WASD** moves relative to the camera; **right-drag** orbits and wheel zooms. Free orbit is available in the pause menu.
- **Auto-aim & fire** starts on. **F** toggles manual mode: mouse aims, hold left click to fire. Arrows visibly leave the animated bow and stop at the first enemy or solid obstacle.
- **Space / Windskip:** a 0.19s dash with 0.30s invulnerability, 2.6s cooldown. Move to choose the dash direction; otherwise it follows aim. Dash can interrupt a draw or salvo.
- **E / Flock & Awe:** eight arrows at 1.4× damage after the authored release marker, 11s cooldown.
- **0 / 1 / 2 / 3** selects physical / fire / ice / poison. The HUD also has element buttons.
- **P / Escape** pauses. Cooldowns, effects, projectiles, enemies and the pet freeze. Hiding the tab or losing window focus also pauses.
- On touch screens, use the movement stick and the two ability buttons. Automatic targeting avoids requiring a second stick. Fullscreen uses the browser API where supported; the game fills the available page without it.

## Element rules and combat

Base arrow damage is 22. A single shared **elemental power of 8** adds to any equipped elemental arrow. Before upgrades, fire burns for 3 damage every half-second for three seconds. Poison stacks up to four times, dealing 1.5 damage per stack every half-second for four seconds. Ice slows normal movement/attack animation by 35%, and the King by 15%, for 2.5 seconds. Equipment changes these values and the stats panel reports your current build. Affected models receive red, blue or purple tint. Selecting another element also clears existing status effects and old player projectiles. Plain arrows have no elemental bonus. There are no piercing or ricochet items in this draft.

The fox has its own proximity-based goals, stable trot/attack states and three physical darts per attack. Its damage and graphics are independent of the equipped element; it remains nearby and cannot be damaged in this draft.

Briarlings chase and telegraph claw attacks. Sporecallers lob at a locked location, leaving an outlined splash/pool that can be avoided. Thornbacks telegraph a straight charge. The King chooses close/ranged attacks by distance; a marked expanding slam and three salvos of three thorns test actual movement and dash invulnerability. Enemy health bars and fractional damage numbers expose hits and status ticks. Rowan has both an overhead health bar and the HUD bar, incoming damage numbers, hit flash and screen-edge feedback. Post-hit invulnerability prevents instant multi-hit deaths.

Gold and XP share pickups with a base **2m collection radius**, increased by the Gathering Compass. A normal kill drops 6 gold and 12 XP. At wave end, all leftover XP is absorbed and **50% of leftover ground gold** is recovered; the Salvage Satchel raises gold recovery to 75%. Camp also awards a wave bounty and restores up to 25 health. Gold-income equipment applies to pickups, recovered gold and bounties. Level/XP, pending free choices and currency appear in the HUD. This short run has no chest rewards, persistent progression saving or campaign migration yet; its balance is for playtesting.

## Implementation and limits

AnimationPlayer manually samples the existing baked clips, including RunShoot, Windskip and Salvo. Clip changes use an explicit 80ms local-bone blend driven by the simulation timestep. AnimationPlayer’s built-in transition blending is disabled because seeking alone does not advance its crossfade clock; leaving that enabled froze the original playable draft’s poses. Complete clips drive the current body; independent upper/lower-body animation blending is a later polish step. Player shooting cadence is 0.8s and movement is 5m/s. The camera smoothly follows the player through an open forest arena. Trees/rocks/markers use deterministic circle collisions on a flat floor; movement slides around obstacles and the arena boundary. This is a lightweight arena controller, without a general navigation mesh or vertical terrain system.

One directional shadow light, shared material/mesh caches, one MultiMesh grass scatter, bounded spawn counts and expiring projectiles/effects limit rendering cost. Balanced/light resolution options are available. Browser checks use desktop Chromium software rendering and a phone-size touch emulation; no physical iPhone or desktop GPU performance claim is made.

## Build and editable source

```sh
npm run build:godot
npm run build:arena
PORT=3002 node server.mjs
```

Open `http://localhost:3002/dist/arena-demo/`, or open `godot-arena/project.godot` in Godot 4.6.3 to inspect the scene. Native starts the first wave automatically and supports keyboard/mouse combat controls. The full HUD, training and shop interfaces live in `web-shell.html`; use the web export for the complete three-wave flow. The downloadable `first-hunt-source.zip` includes the Godot project, item catalog, test scripts, web shell and approved animated GLBs. Editable Blender sources remain under `art/blender/` and in the earlier character, monster and boss preview downloads.

`check_hunt.gd` runs gameplay regressions at 16ms/100ms: first-hit arrows, burn/poison ticks, single-element swaps, movement, dash/cast cooldowns, invulnerability, paused state, collisions, boss selection/releases/dodge safety, pet independence, pickups, phase transitions and victory/defeat/reset. `check_run.gd` checks timed waves, settlement, queued level choices, inventory effects, purchases, escalating/reset rerolls, element swaps, unique mythic ownership, frozen camp simulation and boss overtime. Node tests validate catalog data and verify copied models match approved assets and contain required clips. Browser review covers separate training/shop screens, purchases, rerolls, elemental stock, inventory, continuing the run and phone-size layouts alongside combat controls. Content-hashed packs prevent old cached gameplay after deployment.

`check_animation.gd` additionally measures actual local-bone transform changes for every actor and clip at 16ms/100ms, checks completed transitions against authored poses, verifies zero-delta pause stability, and tests running/shooting through the real gameplay controller. This catches frozen skeletons even when combat timers and clip names still update correctly.
