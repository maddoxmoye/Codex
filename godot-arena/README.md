# First Hunt — playable Godot combat draft

Play: **https://maddoxmoye.github.io/Codex/arena-demo/**

A separate Godot 4.6.3 Compatibility project using the approved Blender-built Rowan, Forest Fox, Briarling, Sporecaller, Thornback and Briar King. The campaign, its shop, saves and previous model/animation previews are unchanged. This demo stores no persistent progress and needs no paid engine or plugin.

**Play the encounter** starts an eight-enemy woodland skirmish. Clearing it restores up to 35 health and gives a three-second breather before the Briar King. **Practice against the King** skips straight to the boss. The King uses the approved Thronebreaker and Briar Decree animations against the actual player; adds continue joining his fight, capped at three normal enemies alive. Victory and defeat offer clean restarts.

## Controls

- **WASD** moves relative to the camera; **right-drag** orbits and wheel zooms. Free orbit is available in the pause menu.
- **Auto-aim & fire** starts on. **F** toggles manual mode: mouse aims, hold left click to fire. Arrows visibly leave the animated bow and stop at the first enemy or solid obstacle.
- **Space / Windskip:** a 0.19s dash with 0.30s invulnerability, 2.6s cooldown. Move to choose the dash direction; otherwise it follows aim. Dash can interrupt a draw or salvo.
- **E / Flock & Awe:** eight arrows at 1.4× damage after the authored release marker, 11s cooldown.
- **0 / 1 / 2 / 3** selects physical / fire / ice / poison. The HUD also has element buttons.
- **P / Escape** pauses. Cooldowns, effects, projectiles, enemies and the pet freeze. Hiding the tab or losing window focus also pauses.
- On touch screens, use the movement stick and the two ability buttons. Automatic targeting avoids requiring a second stick. Fullscreen uses the browser API where supported; the game fills the available page without it.

## Element rules and combat

Base arrow damage is 22. A single shared **elemental power of 8** adds to any equipped elemental arrow. Fire burns for 3 damage every half-second for three seconds. Poison stacks up to four times, dealing 1.5 damage per stack every half-second for four seconds. Ice slows normal movement/attack animation by 35%, and the King by 15%, for 2.5 seconds. Affected models receive red, blue or purple tint. Selecting another element clears existing status effects and old player projectiles, preserving base elemental power. Plain arrows have no elemental bonus. There are no piercing or ricochet items in this initial draft.

The fox has its own proximity-based goals, stable trot/attack states and three physical darts per attack. Its damage and graphics are independent of the equipped element; it remains nearby and cannot be damaged in this draft.

Briarlings chase and telegraph claw attacks. Sporecallers lob at a locked location, leaving an outlined splash/pool that can be avoided. Thornbacks telegraph a straight charge. The King chooses close/ranged attacks by distance; a marked expanding slam and three salvos of three thorns test actual movement and dash invulnerability. Enemy health bars and fractional damage numbers expose hits and status ticks. Rowan has both an overhead health bar and the HUD bar, incoming damage numbers, hit flash and screen-edge feedback. Post-hit invulnerability prevents instant multi-hit deaths.

Gold and XP are temporary encounter pickups with a 2m collection radius. Level/XP and demo currency appear in the HUD. There are no level rewards, shop, progression saving or campaign migration yet. These initial damage/health values are for playtesting; a short demo does not establish full campaign difficulty.

## Implementation and limits

AnimationPlayer manually samples the existing baked clips, including RunShoot, Windskip and Salvo. Complete clips drive the current body; independent upper/lower-body animation blending is a later polish step. Player shooting cadence is 0.8s and movement is 5m/s. The camera smoothly follows the player through an open forest arena. Trees/rocks/markers use deterministic circle collisions on a flat floor; movement slides around obstacles and the arena boundary. This is a lightweight arena controller, without a general navigation mesh or vertical terrain system.

One directional shadow light, shared material/mesh caches, one MultiMesh grass scatter, bounded spawn counts and expiring projectiles/effects limit rendering cost. Balanced/light resolution options are available. Browser checks use desktop Chromium software rendering and a phone-size touch emulation; no physical iPhone or desktop GPU performance claim is made.

## Build and editable source

```sh
npm run build:godot
npm run build:arena
PORT=3002 node server.mjs
```

Open `http://localhost:3002/dist/arena-demo/`, or open `godot-arena/project.godot` in Godot 4.6.3. Native starts the skirmish automatically. The full web HUD lives in `web-shell.html`; native supports keyboard/mouse combat controls. The downloadable `first-hunt-source.zip` includes the complete Godot project and approved animated GLBs. Editable Blender sources remain under `art/blender/` and in the earlier character, monster and boss preview downloads.

`check_hunt.gd` runs gameplay regressions at 16ms/100ms: first-hit arrows, burn/poison ticks, single-element swaps, movement, dash/cast cooldowns, invulnerability, paused state, collisions, boss selection/releases/dodge safety, pet independence, pickups, phase transitions and victory/defeat/reset. Node tests verify that copied models match approved assets and contain required clips. Browser review exercises the gate, combat HUD, movement, both skills, element changes, real hits, the King, pause/restart and touch controls. Content-hashed packs prevent old cached gameplay after deployment.
