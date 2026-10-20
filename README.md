# Wildfall — The Ranger's Journey

A browser survival adventure in a continuous 4,800 × 4,000-unit world. A low perspective camera follows your animated 3D archer through the Whispering Woods, Frostveil Ruins, Ember Highlands, and Venom Marsh. Choose an unlockable archer, collect enemy-dropped ability chests, build elemental arrows and companion pets, and defeat three guardians.

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
| Space | Activate your pre-game defensive / movement skill |
| E | Activate your pre-game offensive skill |
| F | Secure a nearby enemy-dropped chest (also collected by walking close) |
| 1 / 2 / 3 or element icons | Open the shop; attunements appear among rotating offers |
| B | Shop; time pauses while shopping |
| Escape | Pause / resume |

The bow automatically aims at and shoots nearby enemies. The character turns to shoot, draws its bow, walks with animated legs, and carries a quiver. Arrows have shafts, arrowheads, fletching, and colored elemental tips. Camera-turn buttons, element buttons, and touch movement/ability controls support smaller screens.

The minimap shows your position, biome colors, dropped chests, and bosses. There are no pre-placed chests. Trees, rocks, camp structures, pillars, and the brazier have solid collision in both views; dropped chests are collectible and do not obstruct movement. Walking, dashing, enemies, and companions respect the same geometry. Tall obstacles block arrows and line of sight. The map is bounded, with no jumping or climbing mechanics. The central 3,600 × 2,800-unit combat area is free of trees and rocks. Groves and boulders fit entirely inside the outer 600-unit band, including tree canopies. The camp, sector landmarks, biome ground colors and connecting trails remain in place. Trees stay opaque; the camera pulls closer when scenery would obstruct it.

## Pre-game skills and fullscreen

Each new run (including retries) opens a loadout screen before combat. Each slot offers three distinct random choices drawn from a four-skill pool. Choose one **Space** skill and one **E** skill, then enter the wild. Both are available immediately and remain fixed for that run; no gold or level gate is required. Cooldowns and active durations freeze while paused or shopping.

| Slot | Skill | Effect | Base cooldown |
| --- | --- | --- | --- |
| Space | Windskip | Directional dash, brief invulnerability | 2.6s |
| Space | Shell Yeah! | Block all incoming damage for 3s | 12s |
| Space | Hare Trigger | +70% movement speed for 4s; invulnerability for the first 0.8s | 10s |
| Space | Bramble Bouncer | Shove nearby enemies around solid scenery, clear nearby hostile shots, block damage for 1.5s | 9s |
| E | Arrowpalooza | Double bow attack speed for 5s | 14s |
| E | Quiverquake | Close-range elemental blast and 12 radial arrows | 8s |
| E | Flock & Awe | Eight empowered arrows aimed at nearby visible targets; an aimed fan if none are present | 11s |
| E | Hunter’s Moon | Double player arrow impact damage for 4s | 14s |

**Wild amplification** replaces the former burst unlock in the shop. Each rank (maximum 5) adds 25% offensive skill power and 10% duration to timed offensive skills. Arrowpalooza’s rate multiplier and Hunter’s Moon’s impact multiplier increase by 0.25 per rank. Quiverquake and Flock & Awe scale their skill damage by 25% per rank. It never replaces your chosen skill. Offensive buffs do not empower pet attacks. HUD, sidebar, and touch controls reflect the selected skills.

Use **Fullscreen** inside the game to expand the entire stage, including menus and HUD. The button also exits fullscreen; browsers support Escape to exit native fullscreen. If the native API is unavailable or rejected, the button expands the stage to fill the browser viewport, with the same exit control. Resizing updates the 3D camera aspect and drawing size.

## Build sheet beside the shop

The shop, chest-reward and level-reward screens include **Stats & upgrades**. Desktop displays the sheet beside the four offers; small screens use **Shop offers / Level choices / Chest reward** and **Stats & upgrades** tabs. Reviewing stats never advances the wave, rerolls offers, or consumes a reward.

The table compares the selected character’s starting and current permanent maximum health, physical damage, shared elemental damage, armor, movement speed, bow shots per second, pickup range, and regeneration. A separate combat readout shows current arrow impact, active elemental impact, armor reduction, movement speed, and firing cadence, including temporary buffs. The chosen loadout is included with descriptions.

Every successful level choice, chest power and shop purchase is recorded, including repeat upgrades (grouped with counts), pets, abilities, healing consumables, and attunements. Elemental ranks and attunements removed by a swap remain visible as **REPLACED**, while permanent shared elemental damage remains active. The record resets each run.

## Exclusive elemental builds

Rowan, Ash and Briar start with physical arrows; Nyx starts with ice. The shop offers Fire, Ice, or Poison attunement for 25 gold. You can own only one element at a time. Swapping removes all previous elemental ranks, active debuffs, and in-flight player arrows (pet darts are independent). Returning to a previous element starts its specialization from zero. The HUD shortcuts open the shop; they do not provide free instant swaps.

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
- **Thread the Needle** (level 2): arrows can pierce two additional targets. Each subsequent hit deals 75% of the previous hit’s damage.
- **Echo arrows** (level 3): player arrows bounce once to another visible enemy within 210 units, dealing 65% damage. Piercing and ricochet are mutually exclusive across shop offers and chest rewards. Pet darts inherit neither effect.
- **Thunderstep** (level 2): using your selected Space skill releases a 145-unit physical shockwave for 150% physical damage and a brief 30% slow.
- **Gale boots** (level 2): reduces the selected Space skill’s cooldown by 38% (Windskip: 2.6 → 1.6 seconds).
- **Harvest pact** (level 3): restores 6 health every fifth kill, capped at maximum health.

Armor reduces incoming damage using `100 / (100 + 6 × armor)`. Armor starts at zero; Bark mail adds 3 and a level-up Ironbark choice adds 2. There is no negative armor. The shop and sidebar show armor and movement speed.

## Level rewards and four-offer shop

Each level requires `floor(20 × 1.35^(level - 1))` XP. Overflow carries forward. Leveling during combat queues a reward without interrupting the wave. After the wave, each earned level presents **four distinct stat choices**; pick one before proceeding. Each draft draws four of five categories: +15 maximum health (and heal 15), +15% physical damage, +20% shared elemental damage, +2 armor, or +7% movement speed. Multiple levels mean multiple sequential drafts. These rewards cost no gold and are separate from item purchases.

After stat drafts and chest rewards, the shop draws and displays **four eligible offers** for the updated build. Powers just taken from a chest are filtered before shop inventory is generated. Buy any subset or all four. A purchased slot stays marked SOLD until you reroll; buying cannot silently refill it. Only items in the current four slots can be purchased. Existing level gates, ownership checks, elemental exclusivity, and rank caps apply. Coins, XP, stat rewards, and acquired items reset each run.

Rerolling replaces all four slots and is available with a partial or empty shop. Before Loaded Dice discounts, the first roll costs 5 gold early on, then 10, 15, and so on (+5 per roll). After a newly completed wave, the reroll counter resets. The base price rises by 2 gold every two completed waves, starting after wave 3. Closing/reopening with B, or entering the next wave and immediately opening the shop, preserves the current offers and reroll price. Purchases never consume queued level rewards.

## Economy shop items

Four economy items join the normal four-offer shop pool. They do not appear in ability or mythical chests. Purchases are listed in build history, and the stat sheet compares combat gold bonus, shop discount, reroll discount and wave interest against their starting values.

| Item | Shop level / base price | Effect |
| --- | --- | --- |
| Pocket Mint | 1 / 35 gold per rank | +20% combat gold per rank, maximum 3 ranks |
| Silver Tongue | 1 / 45 gold | 15% off shop item prices |
| Loaded Dice | 2 / 40 gold | 30% off both shop and chest rerolls |
| Nest Egg | 2 / 55 gold | After each completed wave, earn 10% of saved gold, rounded down and capped at 20 gold |

Pocket Mint and Heavy Pockets add their bonuses: three Mint ranks plus Heavy Pockets give +110% combat gold. The bonus applies to coin pickups and guardian bounties. Fractional bonuses carry between combat payouts while the wallet remains an integer, avoiding per-drop rounding inflation or loss. Chest sale proceeds and interest are not multiplied.

Silver Tongue applies immediately to remaining offers and ranked elemental upgrade prices. Cards show the original price struck through beside the actual discounted charge. It does not discount its own purchase retroactively. Loaded Dice discounts each reroll’s escalating base price, with shop and individual chest counters still separate. Discounted costs round up to whole gold with a minimum of one gold; discounts never make a purchase or roll free.

Nest Egg pays once per completed wave, before chest sales and reward choices. Opening or reopening the shop cannot earn additional interest. Buying it during an intermission starts earning interest after the next completed wave. Economy upgrades and fractional gold carry reset with each run; character unlock progress remains persistent.

## Enemy-dropped chests and mythical powers

Ordinary enemies have a 4.5% chance to drop an ability chest. Each guardian guarantees a mythical chest. Walk within 40 units or press F within 90 units to secure a drop. Any remaining dropped chests are automatically secured when the wave ends, including the final guardian’s chest. Nothing is applied during combat.

Intermission order is **level stat drafts → queued chests → four-offer shop**. For each chest, take the offered power for free, reroll only that chest, or sell it. Normal rewards draw from eligible abilities, pets, rare items, multishot, regeneration and offensive amplification. Chest rewards can grant an ability before its shop level gate, while ownership, rank caps and piercing/ricochet exclusivity still apply.

| Chest | Sell value | First reroll | Increase per reroll |
| --- | --- | --- | --- |
| Ability | 20 gold | 5 gold | +5 gold |
| Mythical | 90 gold | 15 gold | +10 gold |

The table lists base costs before Loaded Dice discounts. Each chest has its own reroll counter. Chest rerolls do not change shop offers or the shop reroll counter; mythical rerolls always remain in the mythical pool. A reroll selects a different eligible power. When no alternatives remain, reroll is disabled; when all powers are owned, the chest can still be sold. Taking a power records it in the build sheet.

Mythical powers appear only in guardian chests:

- **Phoenix IOU:** one fatal-hit revival per run at 50% health, two seconds of protection and a nearby fiery blast.
- **Stormglass Crown:** every fifth automatic bow volley strikes its target with lightning, damaging enemies within 115 units.
- **Worldroot Covenant:** +60 maximum health, heal 60, +6 armor; using Space briefly roots and slows enemies within 230 units.
- **Orbit of Dawn:** three orbiting suns damage enemies within 115 units every 0.7 seconds for 70% physical damage.

## Rare upgrades and character unlocks

Rare shop items use one quarter of the selection weight of ordinary items and also appear in ability chests. Each is a one-time upgrade with a visible rare border:

- **Glass Quiver:** +60% physical damage, −25 maximum health (minimum 25).
- **Heavy Pockets:** +50% gold from combat drops and guardian bounties, −12% speed. It does not increase chest sale values.
- **Featherweight Vow:** +30% speed, −15 maximum health (minimum 25).
- **Thornwake Mantle:** taking damage releases a 135-unit thorn nova dealing 150% physical damage.

Choose an archer in the pre-run roster before picking your skills. All use a bow and have distinct clothing colors. Starting stat comparisons use that character’s baseline.

| Archer | Unlock milestone | Starting differences |
| --- | --- | --- |
| Rowan · Wayfarer | Always available | Original balanced stats |
| Ash · Cinder Scout | 50 total kills | 85 health, 22 physical damage, 235 speed |
| Briar · Ironwarden | First guardian kill | 140 health, 4 armor, 16 physical damage, 190 speed |
| Nyx · Moonstring | Win a nine-wave run | 90 health, 15 physical damage, 24 shared elemental damage, starts with ice |

Kills, guardian kills and wins persist in `wildfall-unlocks` in this browser’s local storage; unlocks earned in a failed run remain available. Runs reset gold, abilities and build history. There is no account or cross-device synchronization, and clearing site storage clears unlock progress.

## Enemy variety, telegraphs and skill graphics

Crawlers, wisps and brutes are joined by **archers** (aimed arrows after a 0.7s lane warning), **boars** (a charge after a 0.7s windup), **bomb lobbers** (a marked 90-unit blast at the ranger’s cast-time position after 1.15s), and **shamans** (a 150-unit pulse after 1.15s that damages the player and heals/guards nearby allies). Killing a caster cancels its pending attack. Boss radial volleys have a 0.65s warning; charge lanes show the upcoming path. Red ground outlines show blast bounds and fill toward impact. Hostile shots and impact splash effects are visible in both renderers.

Ordinary player and pet arrows stop at their **first** target. Swept segment/circle collision resolves targets and terrain in travel order, so fast arrows cannot skip a nearer enemy. Only the piercing or ricochet upgrades change player-arrow travel. Elemental splash, skill blasts and mythical area attacks are separate unlocked effects.

All eight active skills have distinct art: cyan Windskip feathers, golden Shell Yeah panels, green Hare Trigger ribbons, a Bramble Bouncer thorn crown, Arrowpalooza’s orbiting arrows, Quiverquake’s crystal shock rings, Flock & Awe’s winged projectiles, and Hunter’s Moon’s overhead crescent. Pets have claw/howl effects, ricochets leave echo sparks, piercing arrows have cyan trails, and mythical effects include phoenix wings, lightning, roots and orbiting suns. Shared geometry and materials are reused for these procedural effects; there are no downloaded art assets. The 2D fallback uses matching colors, telegraphs and distinct skill marks, and resizes with fullscreen.

## Boss progression

Survive nine waves as you explore. Regular waves last 25 seconds; boss waves last until their guardian falls. New enemy groups spawn near the player as they travel. After each non-final wave, the shop opens and gameplay pauses. Resolve queued stat drafts and chest rewards, then spend gold or skip purchases with **Begin wave N**. The next wave starts only when you continue; then you heal 15 health. A level-up on the final tick is included in that wave’s reward drafts. The final guardian ends the run in victory after stat drafts and the final mythical chest are resolved.

- **Wave 3 — Briar King:** telegraphed charging attacks.
- **Wave 6 — Frost Oracle:** radial frozen barrages.
- **Wave 9 — Hollow Monarch:** spiraling projectiles and summoned minions.

Each boss has an entrance banner, health bar, distinct 3D model, and minimap marker. Defeat all three to win. Coins, abilities, and chest state reset each run; best defeat count and character unlock milestones persist in browser local storage.

3D is attempted on every page load and never restores an old saved 2D preference. The header allows switching views during a run. Browsers without WebGL2 fall back to a following 2D world view; browser blur also pauses gameplay.

## Development files

- `src/content.js`: character definitions, persistent milestone validation, rare upgrades and mythical powers.
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

The in-game HUD shows health and XP progress bars with numeric values, player level, gold coins, equipped element, elemental shop shortcuts and queued stat-choice count, selected skill names, active durations and recharge bars, defeat count, and companion count. The minimap and location remain available during exploration. The sidebar provides the same detailed character information.

**Camera: Free** lets mouse or trackpad pointer movement over the game orbit and tilt the following camera without holding a button. **Camera: Locked** requires right-drag. Looking stops over menus or outside the game. The C key toggles modes; this preference persists between visits. Q/R and on-screen arrows remain available.

**Detail: Low** disables dynamic shadows and caps rendering to one physical pixel per CSS pixel. High detail uses 512-pixel shadow maps and a 1.25 pixel-ratio cap. Small screens default to Low; the setting is saved. HUD/minimap updates run at 10 Hz independently from rendering.

Elapsed simulation time is consumed in steps no larger than 1/60 second, capped at 0.25 seconds of catch-up after a stall. This fixes the previous slow-motion behavior below 20 rendering FPS. Walking speed is now 210 units/second (previously 165), and the base bow fires every 0.42 seconds (previously 0.52).

The rendering library is **Three.js** (MIT); gameplay uses custom JavaScript. Free engine alternatives include **Babylon.js** (Apache-2.0, browser-oriented engine with more built-in systems) and **Godot** (MIT, full editor, animation, physics, and web export). Moving to either requires porting the renderer and/or gameplay and validating its web deployment; an engine change alone does not establish a performance improvement.
