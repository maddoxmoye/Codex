# Wildfall — The Ranger's Journey

A browser survival adventure in a continuous 4,800 × 4,000-unit world. A low perspective camera follows your animated 3D archer through the Whispering Woods, Frostveil Ruins, Ember Highlands, and Venom Marsh. Explore, open treasure caches, unlock elemental arrows and companion pets, and defeat three guardians.

Play the deployed game at **https://maddoxmoye.github.io/Codex/**.

## Run locally

Requires Node.js 20 or newer (validated with Node.js 24).

```sh
npm ci
npm run dev
```

The server listens on all interfaces on port 3000. Set `PORT` to choose another port. `npm run dev` builds before starting; after editing source files, run `npm run build` and refresh. There is no file watcher.

```sh
npm test
npm run build
```

The build produces `dist/index.html` and `wildfall.html`, with all game code, Three.js, styles, and both renderers embedded. Serve `dist/` with any static host, or open the standalone HTML locally. Gameplay needs no backend, accounts, API keys, or external asset requests. Three.js and esbuild are installed from the committed lockfile for development and CI.

## Controls

| Control | Action |
| --- | --- |
| WASD / arrows | Move relative to the current camera |
| C / Camera button | Toggle Free mouse look / Locked right-drag look |
| Q / R | Turn the camera left / right |
| Pointer movement in Free mode | Orbit and tilt without holding a mouse button; active only over the game |
| Right-mouse drag in Locked mode | Orbit and tilt while holding right click |
| Space | Dash with brief invulnerability; 2.6-second cooldown |
| E | Elemental burst once unlocked; radial arrows and nearby area damage |
| F | Open a glowing treasure chest within reach |
| 0 / 1 / 2 / 3 | Equip physical / unlocked fire / ice / poison arrows |
| B | Shop; time pauses while shopping |
| Escape | Pause / resume |

The bow automatically aims at and shoots nearby enemies. The character turns to shoot, draws its bow, walks with animated legs, and carries a quiver. Arrows have shafts, arrowheads, fletching, and colored elemental tips. Camera-turn buttons, element buttons, and touch movement/ability controls support smaller screens.

The minimap shows your position, biome colors, unopened caches, and bosses. There are 24 caches, each awarding 25 coins and 10 XP once per run. The map is bounded; its terrain is decorative and traversable, with no jumping or climbing mechanics.

## Elements and companions

Unlocks are available through level-up reward cards and the coin shop. Choosing or buying an elemental upgrade equips it. Physical arrows are the starting weapon.

- **Fire:** burns for three seconds. Shop unlock: level 1, 25 coins.
- **Ice:** slows enemies by 45% for 2.5 seconds. Shop unlock: level 3, 55 coins.
- **Poison:** damage over four seconds, stacking up to five times. Shop unlock: level 3, 45 coins.
- **Foxfire companion:** follows the ranger and fires damaging fire projectiles. Shop unlock: level 2, 40 coins; also available as a level-up gift.
- **Frost wolf:** a second following companion that fires slowing ice projectiles. Shop unlock: level 4, 80 coins.
- **Triple shot:** shoots three arrows of the equipped element.
- **Elemental burst:** level-up or shop unlock; E unleashes a ring of arrows, damages nearby enemies, and clears nearby hostile projectiles.

The shop also sells healing, arrow damage, and regeneration. Pickups grant coins, XP, and occasional health. Level-up effects stack; elemental and pet unlock cards disappear once owned.

## Boss progression

Survive nine waves as you explore. Regular waves last 25 seconds; boss waves last until their guardian falls. New enemy groups spawn near the player as they travel. Between waves you heal 15 health.

- **Wave 3 — Briar King:** telegraphed charging attacks.
- **Wave 6 — Frost Oracle:** radial frozen barrages.
- **Wave 9 — Hollow Monarch:** spiraling projectiles and summoned minions.

Each boss has an entrance banner, health bar, distinct 3D model, and minimap marker. Defeat all three to win. Coins, abilities, and chest state reset each run; best defeat count persists in browser local storage.

3D is attempted on every page load and never restores an old saved 2D preference. The header allows switching views during a run. Browsers without WebGL2 fall back to a following 2D world view; browser blur also pauses gameplay.

## Development files

- `src/game.js`: world, combat, progression, elemental status effects, companions, and chests.
- `src/render3d.js`: perspective follow camera, procedural world and characters, animations, projectiles, and effects. Repeated scenery uses instancing and shared geometry/materials.
- `src/render2d.js`: following 2D fallback for the same world.
- `src/main.js`: controls, camera-relative movement, minimap, shop, sound, and HUD.
- `build.mjs`: bundled standalone website output.
- `server.mjs`: local development server.
- `test/game.test.js`: gameplay and progression tests.

Use the existing checkout; cloud tasks are isolated and need no separate worktree.

## GitHub Pages

`.github/workflows/pages.yml` installs locked dependencies, tests and builds, then deploys only `dist/`. Pushes to `main` redeploy automatically. Pages must use **Settings → Pages → Source: GitHub Actions**. A manual run is also available under **Actions → Publish Wildfall to GitHub Pages**. The output works under the `/Codex/` project path. No custom domain or extra credentials are required.

## HUD, camera preferences, and performance

The in-game HUD shows health and XP progress bars with numeric values, player level, gold coins, equipped element, selectable elemental arrow slots, dash/burst recharge bars, defeat count, and companion count. The minimap and location remain available during exploration. The sidebar provides the same detailed character information.

**Camera: Free** lets mouse or trackpad pointer movement over the game orbit and tilt the following camera without holding a button. **Camera: Locked** requires right-drag. Looking stops over menus or outside the game. The C key toggles modes; this preference persists between visits. Q/R and on-screen arrows remain available.

**Detail: Low** disables dynamic shadows and caps rendering to one physical pixel per CSS pixel. High detail uses 512-pixel shadow maps and a 1.25 pixel-ratio cap. Small screens default to Low; the setting is saved. HUD/minimap updates run at 10 Hz independently from rendering.

Elapsed simulation time is consumed in steps no larger than 1/60 second, capped at 0.25 seconds of catch-up after a stall. This fixes the previous slow-motion behavior below 20 rendering FPS. Walking speed is now 210 units/second (previously 165), and the base bow fires every 0.42 seconds (previously 0.52).

The rendering library is **Three.js** (MIT); gameplay uses custom JavaScript. Free engine alternatives include **Babylon.js** (Apache-2.0, browser-oriented engine with more built-in systems) and **Godot** (MIT, full editor, animation, physics, and web export). Moving to either requires porting the renderer and/or gameplay and validating its web deployment; an engine change alone does not establish a performance improvement.
