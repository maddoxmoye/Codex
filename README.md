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
| Space | Dash with brief invulnerability; 2.6-second cooldown (1.6 with Gale boots) |
| E | Elemental burst once unlocked; radial arrows and nearby area damage |
| F | Open a glowing treasure chest within reach |
| 1 / 2 / 3 or element icons | Open the shop; attunements appear among rotating offers |
| B | Shop; time pauses while shopping |
| Escape | Pause / resume |

The bow automatically aims at and shoots nearby enemies. The character turns to shoot, draws its bow, walks with animated legs, and carries a quiver. Arrows have shafts, arrowheads, fletching, and colored elemental tips. Camera-turn buttons, element buttons, and touch movement/ability controls support smaller screens.

The minimap shows your position, biome colors, unopened caches, and bosses. There are 24 caches, each awarding 25 coins and 10 XP once per run. Trees, rocks, camp structures, pillars, the brazier, and chests have solid collision in both views. Walking, dashing, enemies, and companions respect the same geometry. Tall obstacles block arrows and line of sight. The map is bounded, with no jumping or climbing mechanics. Wider trails and fewer, more widely spaced groves keep routes open. Trees stay opaque; the camera pulls closer when scenery would obstruct it.

## Exclusive elemental builds

You start with physical arrows. The Elements shop offers Fire, Ice, or Poison attunement for 25 gold or one free pick. You can own only one element at a time. Swapping removes all previous elemental ranks, active debuffs, and in-flight player/pet arrows. Returning to a previous element starts its specialization from zero. The HUD shortcuts open the shop; they do not provide free instant swaps.

**Elemental foundation** increases the shared elemental-damage stat by 25%. This stat persists through swaps and adds damage to whichever element is active. General bow damage, health, speed, burst, companion, and other general upgrades also persist. The shop shows shared damage and current elemental ranks separately.

Every element has three ranked specializations:

| Element | Power (max 5) | Duration (max 5) | Ability (max 3) |
| --- | --- | --- | --- |
| Fire | +35% elemental multiplier per rank | +1 second burn per rank | Explosive embers: impact splash damage |
| Ice | +35% elemental multiplier per rank | Longer, stronger chill | Shatter: bonus damage to chilled targets |
| Poison | +35% elemental multiplier per rank | +1.5 seconds poison per rank | Contagion: poisoned deaths spread venom |

Power is available at level 1, duration at level 2, and abilities at level 3. These ranks apply only to the current element and are erased on a swap. Shared base elemental damage starts at 12; physical bow damage starts at 18. Elemental hit damage is physical bow damage plus shared elemental damage times the active power multiplier. Each shop roll draws four distinct eligible offers from general upgrades, active-element upgrades, other attunements, companions, and unique abilities. Buying another attunement can invalidate a remaining specialization offer; it stays in its slot until rerolled.

## Companions and unique abilities

All companions roam, choose their own nearby targets, navigate solid scenery, and return when the ranger moves away. Their attacks and appearance are independent of the equipped element. Combat pet damage scales with physical damage, never elemental damage or elemental ranks.

| Companion | Unlock | Quirk |
| --- | --- | --- |
| Forest fox | Level 2 · 40 gold | Fans three physical darts every 1.1 seconds |
| Wild wolf | Level 3 · 70 gold | Runs into bite range; howls every 6 seconds to slow nearby enemies by 30% for 2 seconds |
| Lantern beetle | Level 1 · 35 gold | Scouts coins and XP within 300 units of the ranger and credits them immediately; leaves healing pickups for the player |

Unique abilities are one-time purchases in the four-offer shop pool:

- **Trailrunner** (level 2): moving builds up to +35% speed over two seconds; stopping resets the bonus.
- **Echo arrows** (level 3): player arrows bounce once to another visible enemy within 210 units, dealing 65% damage. Pet darts do not bounce.
- **Thunderstep** (level 2): dashing releases a 145-unit physical shockwave for 150% physical damage and a brief 30% slow.
- **Gale boots** (level 2): reduces dash cooldown to 1.6 seconds.
- **Harvest pact** (level 3): restores 6 health every fifth kill, capped at maximum health.

Armor reduces incoming damage using `100 / (100 + 6 × armor)`. Armor starts at zero; Bark mail adds 3 and a level-up Ironbark choice adds 2. There is no negative armor. The shop and sidebar show armor and movement speed.

## Level rewards and four-offer shop

Each level requires `floor(20 × 1.35^(level - 1))` XP. Overflow carries forward. Leveling during combat queues a reward without interrupting the wave. After the wave, each earned level presents **four distinct stat choices**; pick one before proceeding. Each draft draws four of five categories: +15 maximum health (and heal 15), +15% physical damage, +20% shared elemental damage, +2 armor, or +7% movement speed. Multiple levels mean multiple sequential drafts. These rewards cost no gold and are separate from item purchases.

The shop then displays **four offers**. Buy any subset or all four. A purchased slot stays marked SOLD until you reroll; buying cannot silently refill it. Only items in the current four slots can be purchased. Existing level gates, ownership checks, elemental exclusivity, and rank caps apply. Coins, XP, stat rewards, and acquired items reset each run.

Rerolling replaces all four slots and is available with a partial or empty shop. The first roll costs 5 gold early on, then 10, 15, and so on (+5 per roll). After a newly completed wave, the reroll counter resets. The base price rises by 2 gold every two completed waves, starting after wave 3. Closing/reopening with B, or entering the next wave and immediately opening the shop, preserves the current offers and reroll price. Purchases never consume queued level rewards.

## Boss progression

Survive nine waves as you explore. Regular waves last 25 seconds; boss waves last until their guardian falls. New enemy groups spawn near the player as they travel. After each non-final wave, the shop opens and gameplay pauses. Resolve any queued stat drafts, then spend gold or skip purchases with **Begin wave N**. The next wave starts only when you continue; then you heal 15 health. A level-up on the final tick is included in that wave’s reward drafts. The final guardian ends the run in victory after any already-earned stat drafts.

- **Wave 3 — Briar King:** telegraphed charging attacks.
- **Wave 6 — Frost Oracle:** radial frozen barrages.
- **Wave 9 — Hollow Monarch:** spiraling projectiles and summoned minions.

Each boss has an entrance banner, health bar, distinct 3D model, and minimap marker. Defeat all three to win. Coins, abilities, and chest state reset each run; best defeat count persists in browser local storage.

3D is attempted on every page load and never restores an old saved 2D preference. The header allows switching views during a run. Browsers without WebGL2 fall back to a following 2D world view; browser blur also pauses gameplay.

## Development files

- `src/world.js`: deterministic shared scenery, solid colliders, spatial lookup, movement, steering, clear spawning, and projectile obstruction.
- `src/game.js`: combat, scaling progression, exclusive elemental builds, companions, chests, and wave intermissions.
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

The in-game HUD shows health and XP progress bars with numeric values, player level, gold coins, equipped element, elemental shop shortcuts and queued stat-choice count, dash/burst recharge bars, defeat count, and companion count. The minimap and location remain available during exploration. The sidebar provides the same detailed character information.

**Camera: Free** lets mouse or trackpad pointer movement over the game orbit and tilt the following camera without holding a button. **Camera: Locked** requires right-drag. Looking stops over menus or outside the game. The C key toggles modes; this preference persists between visits. Q/R and on-screen arrows remain available.

**Detail: Low** disables dynamic shadows and caps rendering to one physical pixel per CSS pixel. High detail uses 512-pixel shadow maps and a 1.25 pixel-ratio cap. Small screens default to Low; the setting is saved. HUD/minimap updates run at 10 Hz independently from rendering.

Elapsed simulation time is consumed in steps no larger than 1/60 second, capped at 0.25 seconds of catch-up after a stall. This fixes the previous slow-motion behavior below 20 rendering FPS. Walking speed is now 210 units/second (previously 165), and the base bow fires every 0.42 seconds (previously 0.52).

The rendering library is **Three.js** (MIT); gameplay uses custom JavaScript. Free engine alternatives include **Babylon.js** (Apache-2.0, browser-oriented engine with more built-in systems) and **Godot** (MIT, full editor, animation, physics, and web export). Moving to either requires porting the renderer and/or gameplay and validating its web deployment; an engine change alone does not establish a performance improvement.
