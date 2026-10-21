# Wildfall — The Ranger's Journey

A browser survival adventure in a continuous 4,800 × 4,000-unit world. A low perspective camera follows your animated 3D archer through the Whispering Woods, Frostveil Ruins, Ember Highlands, and Venom Marsh. Choose an unlockable archer, collect enemy-dropped ability chests, build elemental arrows and companion pets, and defeat four guardians.

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
| 1 / 2 / 3 or element icons | Show a reminder to buy a quiver at the next wave break |
| B / Inventory button | Pause and inspect stats, equipment and training; no purchases |
| Escape / Run menu | Pause, resume, Save & quit, or Leave run |

The bow automatically aims at and shoots nearby enemies. The character turns to shoot, draws its bow, walks with animated legs, and carries a quiver. Arrows have shafts, arrowheads, fletching, and colored elemental tips. Camera-turn buttons, element buttons, and touch movement/ability controls support smaller screens.

The minimap shows your position, biome colors, dropped chests, and bosses. There are no pre-placed chests. Trees, rocks, camp structures, pillars, and the brazier have solid collision in both views; dropped chests are collectible and do not obstruct movement. Walking, dashing, enemies, and companions respect the same geometry. Tall obstacles block arrows and line of sight. The map is bounded, with no jumping or climbing mechanics. The central 3,600 × 2,800-unit combat area is free of trees and rocks. Groves and boulders fit entirely inside the outer 600-unit band, including tree canopies. The camp, sector landmarks, biome ground colors and connecting trails remain in place. Trees stay opaque; the camera pulls closer when scenery would obstruct it.

## Pre-game skills and fullscreen

Each new run (including retries) opens a loadout screen before combat. Each character has a fixed, unique **Space** defense/movement skill and **E** offensive skill. Their selection card previews both skills and cooldowns. Choose an unlocked character and enter the wild; the preset is available immediately. Cooldowns and active durations freeze while paused or shopping.

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
| Space | Borrowed Time | 4s clock field: +25% speed, slow nearby enemies/projectiles 65%, first second invulnerable | 12s |
| E | Gear Expectations | 4s empowered three-arrow fans every 0.6s | 13s |

**Resonance Lens** replaces the former burst unlock in the shop. Each rank (maximum 5) adds 25% offensive skill power and 10% duration to timed offensive skills. Arrowpalooza’s rate multiplier and Hunter’s Moon’s impact multiplier increase by 0.25 per rank. Quiverquake and Flock & Awe scale their skill damage by 25% per rank. It never replaces your chosen skill. Offensive buffs do not empower pet attacks. HUD, sidebar, and touch controls reflect the selected skills.

Use **Fullscreen** inside the game to expand the entire stage, including menus and HUD. The button also exits fullscreen; browsers support Escape to exit native fullscreen. If the native API is unavailable or rejected, the button expands the stage to fill the browser viewport, with the same exit control. Resizing updates the 3D camera aspect and drawing size.

## Build sheet beside the shop

The shop, chest-reward and level-reward screens include **Stats & inventory**. Desktop displays the sheet beside the four offers; small screens use **Shop offers / Level choices / Chest reward** and **Stats & inventory** tabs. Reviewing stats never advances the wave, rerolls offers, or consumes a reward.

The table compares the selected character’s starting and current permanent maximum health, physical damage, shared elemental damage, armor, movement speed, bow shots per second, pickup range, and regeneration. A separate combat readout shows current arrow impact, active elemental impact, armor reduction, movement speed, and firing cadence, including temporary buffs. The chosen loadout is included with descriptions.

Every successful level choice, chest power and shop purchase is recorded, including repeat upgrades (grouped with counts), pets, abilities, healing consumables, and elemental quivers. Elemental ranks and elemental quivers removed by a swap remain visible as **REPLACED**, while permanent shared elemental damage remains active. The record resets each run.

## Exclusive elemental builds

Rowan, Ash and Briar start with physical arrows; Nyx starts with ice. The shop offers an Ember, Glacier, or Venom Quiver for 25 gold. You can own only one element at a time. Swapping removes all previous elemental ranks, active debuffs, and in-flight player arrows (pet darts are independent). Returning to a previous element starts its specialization from zero. Quiver shortcuts remind you to visit the merchant at the next wave break; they never open a mid-wave shop or provide free swaps.

**Prism Core** increases the shared elemental-damage stat by 25%. This stat persists through swaps and adds damage to whichever element is active. General bow damage, health, speed, burst, companion, and other general upgrades also persist. The shop shows shared damage and current elemental ranks separately.

Every element has three ranked specializations:

| Element | Power (max 5) | Duration (max 5) | Ability (max 3) |
| --- | --- | --- | --- |
| Fire | +35% elemental multiplier per rank | +1 second burn per rank | Explosive embers: impact splash damage |
| Ice | +35% elemental multiplier per rank | Longer, stronger chill | Shatter: bonus damage to chilled targets |
| Poison | +35% elemental multiplier per rank | +1.5 seconds poison per rank | Contagion: poisoned deaths spread venom |

Power is available at level 1, duration at level 2, and abilities at level 3. These ranks apply only to the current element and are erased on a swap. Shared base elemental damage starts at 12; physical bow damage starts at 18. Elemental hit damage is physical bow damage plus shared elemental damage times the active power multiplier. Each shop roll draws four distinct eligible offers from general upgrades, active-element upgrades, other elemental quivers, companions, and unique abilities. Buying another elemental quiver can invalidate a remaining specialization offer; it stays in its slot until rerolled.

## Companions and unique abilities

All companions roam, choose their own nearby targets, navigate solid scenery, and return when the ranger moves away. Their attacks and appearance are independent of the equipped element. Combat pet damage scales with physical damage, never elemental damage or elemental ranks.

| Companion | Unlock | Quirk |
| --- | --- | --- |
| Foxcall Whistle | Level 2 · 40 gold | Fans three physical darts every 1.1 seconds |
| Wolfbone Whistle | Level 3 · 70 gold | Runs into bite range; howls every 6 seconds to slow nearby enemies by 30% for 2 seconds |
| Lantern Beetle Brooch | Level 1 · 35 gold | Scouts coins and XP within 300 units of the ranger and credits them immediately; leaves healing pickups for the player |

Unique abilities are one-time purchases in the four-offer shop pool:

- **Trailrunner Greaves** (level 2): moving builds up to +35% speed over two seconds; stopping resets the bonus.
- **Needlepoint Broadheads** (level 2): arrows can pierce two additional targets. Each subsequent hit deals 75% of the previous hit’s damage.
- **Echo Crystal Nocks** (level 3): player arrows bounce once to another visible enemy within 210 units, dealing 65% damage. Piercing and ricochet are mutually exclusive across shop offers and chest rewards. Pet darts inherit neither effect.
- **Thunderstone Soles** (level 2): using your selected Space skill releases a 145-unit physical shockwave for 150% physical damage and a brief 30% slow.
- **Gale boots** (level 2): reduces the selected Space skill’s cooldown by 38% (Windskip: 2.6 → 1.6 seconds).
- **Reaper’s Fang** (level 3): restores 6 health every fifth kill, capped at maximum health.

Armor reduces incoming damage using `100 / (100 + 6 × armor)`. Armor starts at zero; Bark mail adds 3 and a level-up Ironbark choice adds 2. There is no negative armor. The shop and sidebar show armor and movement speed.

## Level rewards and four-offer shop

Each level requires `floor(20 × 1.35^(level - 1))` XP. Overflow carries forward. Leveling during combat queues a reward without interrupting the wave. After the wave, each earned level presents **four distinct stat choices**; pick one before proceeding. Each draft draws four of six categories: +5 Economy, +15 maximum health (and heal 15), +15% physical damage, +20% shared elemental damage, +2 armor, or +7% movement speed. Multiple levels mean multiple sequential drafts. These rewards cost no gold and are separate from item purchases.

After stat drafts and chest rewards, the shop draws and displays **four eligible offers** for the updated build. Powers just taken from a chest are filtered before shop inventory is generated. Buy any subset or all four. A purchased slot stays marked SOLD until you reroll; buying cannot silently refill it. Only items in the current four slots can be purchased. Existing level gates, ownership checks, elemental exclusivity, and rank caps apply. Coins, XP, stat rewards, and acquired items reset each run.

Rerolling replaces all four slots and is available with a partial or empty shop. Before Economy and Loaded Dice discounts, the first roll costs 5 gold early on, then 10, 15, and so on (+5 per roll). After a newly completed wave, the reroll counter resets. The base price rises by 2 gold every two completed waves, starting after wave 3. The merchant opens automatically after wave rewards and cannot be opened during combat. Pausing the merchant and resuming preserves its offers and reroll price. B opens a read-only inventory instead. Purchases never consume queued level rewards.

## Economy shop items

Five economy items join the normal four-offer shop pool. They do not appear in ability or mythical chests. Purchases are listed in build history, and the stat sheet compares combat gold bonus, shop discount, reroll discount and wave interest against their starting values.

| Item | Shop level / base price | Effect |
| --- | --- | --- |
| Pocket Mint | 1 / 35 gold per rank | +20% combat gold per rank, maximum 3 ranks |
| Silver Merchant’s Seal | 1 / 45 gold | +15 Economy: discounts purchases and rerolls |
| Merchant’s Ledger | 1 / 30 gold per rank | +5 Economy |
| Loaded Dice | 2 / 40 gold | 30% off both shop and chest rerolls |
| Gilded Savings Tin | 2 / 55 gold | After each completed wave, earn 10% of saved gold, rounded down and capped at 20 gold |

**Economy** is a dedicated stat: each point saves 1% on purchases and all rerolls, capped at 50%. Merchant’s Ledger grants +5 Economy per rank (30 base gold); level rewards can offer +5 Economy too. Silver Merchant’s Seal grants +15 Economy. Loaded Dice multiplies reroll prices by 0.7 after Economy savings. Prices round up to a minimum of one gold; displayed prices are the charged prices.

Pocket Mint and Lead-Lined Coinpurse add their bonuses: three Mint ranks plus Lead-Lined Coinpurse give +110% combat gold. The bonus applies to coin pickups and guardian bounties. Fractional bonuses carry between combat payouts while the wallet remains an integer, avoiding per-drop rounding inflation or loss. Chest sale proceeds and interest are not multiplied.

Silver Merchant’s Seal applies immediately to remaining offers and ranked elemental upgrade prices. Cards show the original price struck through beside the actual discounted charge. It does not discount its own purchase retroactively. Loaded Dice discounts each reroll’s escalating base price, with shop and individual chest counters still separate. Discounted costs round up to whole gold with a minimum of one gold; discounts never make a purchase or roll free.

Gilded Savings Tin pays once per completed wave, before chest sales and reward choices. Opening or reopening the shop cannot earn additional interest. Buying it during an intermission starts earning interest after the next completed wave. Economy upgrades and fractional gold carry reset with each run; character unlock progress remains persistent.

## Enemy-dropped chests and mythical powers

Ordinary enemies have a 3% chance to drop an ability chest. Each guardian guarantees a mythical chest. Walk within 40 units or press F within 90 units to secure a drop. Any remaining dropped chests are automatically secured when the wave ends, including the final guardian’s chest. Nothing is applied during combat.

Intermission order is **level stat drafts → queued chests → four-offer shop**. For each chest, take the offered item for free, reroll only that chest, or sell it. Normal rewards draw from eligible equipment, companion charms and whistles, rare gear, quiver racks, medical wraps and focusing lenses, including the new equipment catalog. Chest rewards can grant an item before its shop level gate, while ownership, rank caps and piercing/ricochet exclusivity still apply.

| Chest | Sell value | First reroll | Increase per reroll |
| --- | --- | --- | --- |
| Ability | 20 gold | 5 gold | +5 gold |
| Mythical | 90 gold | 15 gold | +10 gold |

The table lists base costs before Economy and Loaded Dice discounts. Each chest has its own reroll counter. Chest rerolls do not change shop offers or the shop reroll counter; mythical rerolls always remain in the mythical pool. A reroll selects a different eligible power. When no alternatives remain, reroll is disabled; when all powers are owned, the chest can still be sold. Taking a power records it in the build sheet.

Mythical powers appear in guardian chests and very rare shop offers:

- **Phoenix Feather:** one fatal-hit revival per run at 50% health, two seconds of protection and a nearby fiery blast.
- **Stormglass Crown:** every fifth automatic bow volley strikes its target with lightning, damaging enemies within 115 units.
- **Worldroot Reliquary:** +60 maximum health, heal 60, +6 armor; using Space briefly roots and slows enemies within 230 units.
- **Dawn Orrery:** three orbiting suns damage enemies within 115 units every 0.7 seconds for 70% physical damage.

## Rare upgrades and character unlocks

Rare shop items use one quarter of the selection weight of ordinary items and also appear in ability chests. Each is a one-time upgrade with a visible rare border:

- **Glass Quiver:** +60% physical damage, −25 maximum health (minimum 25).
- **Lead-Lined Coinpurse:** +50% gold from combat drops and guardian bounties, −12% speed. It does not increase chest sale values.
- **Featherweave Cloak:** +30% speed, −15 maximum health (minimum 25).
- **Thornwake Mantle:** taking damage releases a 135-unit thorn nova dealing 150% physical damage.

Choose an archer in the pre-run roster before picking your skills. All use a bow and have distinct clothing colors. Starting stat comparisons use that character’s baseline.

| Archer | Unlock milestone | Starting differences |
| --- | --- | --- |
| Rowan · Wayfarer | Always available | Original balanced stats |
| Ash · Cinder Scout | 50 total kills | 85 health, 22 physical damage, 235 speed |
| Briar · Ironwarden | First guardian kill | 140 health, 4 armor, 16 physical damage, 190 speed |
| Pip · Gearwing | Defeat 250 enemies across runs | 95 health, 20 damage, 10 starting Economy |
| Nyx · Moonstring | Complete the 20-wave campaign | 90 health, 15 physical damage, 24 shared elemental damage, starts with ice |

Kills, guardian kills and wins persist in `wildfall-unlocks` in this browser’s local storage; unlocks earned in a failed run remain available. Runs reset gold, abilities and build history. There is no account or cross-device synchronization, and clearing site storage clears unlock progress.

## Enemy variety, telegraphs and skill graphics

Crawlers, wisps and brutes are joined by **archers** (aimed arrows after a 0.7s lane warning), **boars** (a charge after a 0.7s windup), **bomb lobbers** (a marked 90-unit blast at the ranger’s cast-time position after 1.15s), and **shamans** (a 150-unit pulse after 1.15s that damages the player and heals/guards nearby allies). Killing a caster cancels its pending attack. Boss radial volleys have a 0.65s warning; charge lanes show the upcoming path. Red ground outlines show blast bounds and fill toward impact. Hostile shots and impact splash effects are visible in both renderers.

Ordinary player and pet arrows stop at their **first** target. Swept segment/circle collision resolves targets and terrain in travel order, so fast arrows cannot skip a nearer enemy. Only the piercing or ricochet upgrades change player-arrow travel. Elemental splash, skill blasts and mythical area attacks are separate unlocked effects.

All ten active skills have distinct art, including Pip’s ticking turquoise field and clockwork arrows: cyan Windskip feathers, golden Shell Yeah panels, green Hare Trigger ribbons, a Bramble Bouncer thorn crown, Arrowpalooza’s orbiting arrows, Quiverquake’s crystal shock rings, Flock & Awe’s winged projectiles, and Hunter’s Moon’s overhead crescent. Pets have claw/howl effects, ricochets leave echo sparks, piercing arrows have cyan trails, and mythical effects include phoenix wings, lightning, roots and orbiting suns. Shared geometry and materials are reused for these procedural effects; there are no downloaded art assets. The 2D fallback uses matching colors, telegraphs and distinct skill marks, and resizes with fullscreen.

## Boss progression

Survive **20 campaign waves**, then choose **Continue endless** at the victory checkpoint to retain the same character, stats, pets and inventory. Regular waves last 25 seconds; guardian waves last 55 seconds. Kill the guardian before that deadline and survive until time runs out; an early kill does not end the wave. A living guardian at the deadline fails the run. Resolve level-up choices, then chests, then the shop after each wave. Continue to begin the next wave and heal 8 health.

- **Wave 5 — Briar King:** charging attacks.
- **Wave 10 — Frost Oracle:** radial barrages.
- **Wave 15 — Hollow Monarch:** barrages and summoned minions.
- **Wave 20 — Gilded Colossus:** overlapping targeted explosions and radial barrages.

Bosses recur every five waves in endless, cycling all four designs with increasing health and damage. Population and spawn frequency rise with waves, with a 140-enemy cap. Shamans and bombers enter the random pool at wave 6, stalkers at 11, and juggernauts at 16. Juggernauts resist arrow impacts by 25% and warn a heavy close-range slam. Gold-armored elite variants begin at wave 11. Enemy health and damage continue scaling.

At every wave clear, all remaining XP is absorbed **in full**, including XP from the final boss. **50% of remaining ground gold** is recovered, with combat-gold bonuses applied and fractional gold carried forward. Already-collected drops cannot pay twice. Recovery happens before level-up choices and interest, and its receipt appears in intermission screens. Pick up gold during combat to receive its full value. Leftover healing drops are discarded.

Each boss has an entrance banner, health bar, distinct 3D model and minimap marker. Campaign completion records one win and unlocks Nyx; endless continuation cannot duplicate the win. Coins and upgrades reset on a new run; best defeat count and character unlock milestones persist in browser storage.

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

### Character presets and designs

| Archer | Space | E | Distinct model |
| --- | --- | --- | --- |
| Rowan | Windskip | Flock & Awe | Leaf hood and forest cloak |
| Ash | Hare Trigger | Arrowpalooza | Red trailing scarf and feather |
| Briar | Shell Yeah! | Quiverquake | Broad shoulders, helmet and back shield |
| Nyx | Bramble Bouncer | Hunter’s Moon | Long robe, crystal shoulders and crescent |
| Pip | Borrowed Time | Gear Expectations | Teal top hat, goggles and golden gear pack |

Borrowed Time grants 25% speed for 4 seconds, slows enemies and their shots within 240 units by 65%, and blocks damage for its first second (12s cooldown). Gear Expectations adds an empowered three-arrow fan every 0.6s for 4s (13s cooldown); amplification extends and strengthens it. Clockwork arrows obey the same first-hit, piercing and ricochet rules as normal player arrows.

Element colors are fire red, ice blue and poison purple across arrows, effects, status rings and HUD. Affected enemies receive a matching body tint that disappears when the effect expires or the element is swapped. Each enemy owns its tint materials; removing enemies disposes those materials without affecting other enemies or scenery.

### Illustrated upgrades and rarity

Every shop offer has an inline vector illustration matched to its effect, a written rarity label, and a matching border. The same illustrations appear on chest rewards and acquired-upgrade history. Examples include a coin-carrying beetle, fox and wolf faces, reroll dice, piercing and ricochet paths, a thorn mantle, and a phoenix. Element upgrades use red fire, blue ice or purple poison art with distinct power, duration or special-effect marks. Icons remain visible on mobile and work offline in the standalone build.

Shop rarity weights, per eligible item: Common 1.0, Uncommon 0.65, Rare 0.25, Epic 0.12, Mythic 0.012. These are relative weights, not fixed percentages; the current eligible pool determines the odds. Examples: tonic and ordinary stat boosts are Common; fox, beetle and utility upgrades are Uncommon; piercing, ricochet and wolf are Rare; Forked Quiver and Livingroot Bandage are Epic. Existing prices, rank caps and level requirements still apply.

Mythic powers can appear very rarely in the four-offer shop (180 base gold) and have equal selection weight within guardian chests. Owned Mythics are removed from both shop and chest pools for the rest of that run, including a spent Phoenix Feather. Their reward cards, history icons and dropped chests glow crimson red. Phoenix, Stormglass lightning, Worldroot effects and Orbit suns also use a red signature while retaining their distinct shapes. Enemy warning markers continue to indicate danger through their outlines and filling ground areas.

### Save, resume and leave a run

Open **Run menu** inside the stage (also available in fullscreen), or press Escape during combat. **Save & quit** stores the current run in this browser and returns to the title screen; **Continue saved run** restores it safely paused. **Leave run** discards the active run and its save while keeping character unlock progress. Starting a new run replaces the save only when you launch that run.

Saves preserve the current wave and timer, health/currency/stats, cooldowns, enemies and pending attacks, projectiles and their previously hit targets, pets, ground loot, chests, shop offers and sold slots, reroll prices, pending level choices, history, and endless state. The run menu also works from shop and reward screens and returns to the same screen. It includes read-only stats and inventory, with tabs on mobile. It cannot open a shop during a live wave. Autosaves run every 10 seconds and when the page is hidden or closed; manual Save & quit reports storage failures without leaving the run. Saves live in local browser storage (`wildfall-run`), so use the same browser/site/device. Corrupt or incompatible saves are rejected without changing a live run.

### Pickup radius and harder survival

Gold and XP credit immediately when they enter the player's visible 75-unit pickup ring; touching each drop is unnecessary. **Gathering Compass** is an Uncommon level-1 shop item (35 base gold) granting +30 pickup radius per rank, up to five ranks / 225 radius. The HUD and stat sheet show the radius. Healing still requires approaching the drop. Every dropped chest is collected automatically at wave clear; walking nearby or pressing F can secure it earlier. Previous end-of-wave recovery remains 100% XP and 50% ground gold.

Ordinary enemy health is now `1.25 × (base health + 7 × wave)`, with base health 22 or 40 before type/elite modifiers; contact damage is `12 + 1.4 × wave`. Boss health starts at `580 × guardian number`, with further endless scaling. Regular spawn intervals decrease from `0.78 − 0.022 × wave` to a floor of 0.12 seconds; spawn groups rise by one every seven waves, capped at four. Active enemy limits rise from `55 + 4 × wave` to 140, including summoned minions. Ordinary kills drop 2 gold; guardians drop 10 plus a 35-gold bounty. New-wave healing is 8 health and ordinary chest drop chance is 3%. Countdown HUDs distinguish a live guardian from the post-kill survival period. Bosses remain on waves 5/10/15/20 and every fifth endless wave.

## Physical equipment and expanded merchant catalog

The merchant has **77 physical items**, including **32 new items**. Item cards show object illustrations, equipment type, rarity, name, mechanical description, price and owned-copy limit. Equipment is automatically equipped on purchase; tonic bottles are consumed. Elemental items are quivers, arrowheads, coatings and attachments; changing quivers removes only the old element's fittings. Renamed stable IDs migrate existing save descriptions without removing owned items or changing their existing effects. Free level rewards remain clearly labeled **training** and are separate from purchased or looted gear.

The merchant opens only after each wave's training and chest rewards. B and the Inventory button open paused stats and the equipment/training log, never a live shop. Space/E and the simulation freeze while inspecting inventory. The log combines copies of the same item across shops and chests, marks equipped/consumed/removed items, and preserves the separate training record. New stats include crit chance (capped at 75%), 1.75× critical impact, lifesteal, dodge (capped at 50%), XP bonus, range, projectile speed, knockback, skill cooldown reduction (capped at 60%), companion modifiers, and gold recovery.

Negative armor increases damage taken (bounded at −10 armor). Critical hits, guardian bonuses, repeated-hit marks and lifesteal apply to player-arrow impacts; pet darts do not inherit them. A Voltaic Spool's secondary shock cannot trigger further crit chains. Skill-cooldown items multiply with Gale Boots. Pet equipment requires its corresponding companion. A spent Phoenix Feather remains excluded from future offers for that run. Saved old manual-shop screens resume safely paused in the live wave under the new access rules.

### New equipment

| Item | Type / rarity | Base gold | Effect |
| --- | --- | ---: | --- |
| Rivet Pouch | Arrow supplies / common | 22 | A pouch of steel rivets. +2 physical damage per copy. Maximum 5 copies. |
| Padded Vest | Armor / common | 25 | A quilted vest. +12 maximum health and heal 12, but −3% movement speed. Maximum 3 copies. |
| Wool Wrap | Bandage / common | 28 | A clean wool dressing. Regenerate an additional 0.4 health per second per copy. Maximum 4 copies. |
| Tin Badge | Armor / common | 18 | A reinforced breastplate badge. +1 armor per copy. Maximum 5 copies. |
| Field Journal | Book / common | 26 | Notes on the local monsters. +8% XP gain, but −4% physical damage. Maximum 3 copies. |
| Copper Coinpurse | Coin container / common | 25 | A charmed purse. +8% combat gold, but −5 pickup radius. Maximum 3 copies. |
| Archery Glove | Gloves / common | 28 | A supple drawing glove. Attack interval −8%, but −1 armor. Maximum 3 copies. |
| Copper Ring | Jewelry / common | 30 | A ring etched with a bullseye. +6 percentage points of critical-hit chance per copy. Maximum 5 copies. |
| Trail Socks | Boot lining / common | 26 | Thick traveling socks. +5% movement speed and +15 pickup radius. Maximum 3 copies. |
| Brass Spyglass | Optics / common | 32 | A bow-mounted sight. +90 targeting and arrow range, but attack interval +6%. Maximum 2 copies. |
| Barbed Arrowheads | Arrowheads / uncommon | 42 | Hooked steel tips. +10% physical damage and +20 arrow knockback. Maximum 3 copies. |
| Vampire Fang | Amulet / uncommon | 48 | A blood-drinking pendant. Heal for 3% of direct player-arrow damage, but −10 maximum health. Maximum 3 copies. |
| Lucky Button | Charm / uncommon | 35 | A button sewn into your sleeve. +4 percentage points of dodge chance, but −1 armor. Maximum 3 copies. |
| Iron Buckle | Armor / uncommon | 40 | A weighty belt buckle. +4 armor, but −8% movement speed. Maximum 2 copies. |
| Etched Runestone | Focus / uncommon | 42 | A rune cut into a bow weight. +5 shared elemental damage, but −8% physical damage. Maximum 3 copies. |
| Wind Chime | Charm / uncommon | 45 | A little silver chime. −8% cooldown on both character skills, but −5% physical damage. Maximum 3 copies. |
| Pocket Clock | Clock / uncommon | 48 | A pocket watch with a soothing tick. +12% XP gain and +0.3 health regeneration per second. Maximum 2 copies. |
| Beetle Backpack | Pet equipment / uncommon | 42 | A tiny beetle pack. +60 collector scouting/leash radius per copy. Requires the Lantern Beetle Brooch. Maximum 2 copies. |
| Studded Pet Collar | Pet equipment / uncommon | 45 | A spiked collar for your companions. +25% pet damage, but −5% player physical damage. Requires a fox or wolf. Maximum 2 copies. |
| Silver Pet Bell | Pet equipment / uncommon | 48 | A bell that quickens companions. Fox and wolf attack cooldowns −15%. Requires a fox or wolf. Maximum 2 copies. |
| Flask Harness | Medical equipment / uncommon | 45 | A padded harness keeps medicine fresh. Healing pickups restore 50% more health. |
| Fletching Kit | Arrow supplies / uncommon | 40 | Balanced arrow feathers. +25% projectile speed, with unchanged arrow range. Maximum 2 copies. |
| Guardian’s Monocle | Optics / rare | 65 | An etched targeting lens. +30% arrow damage against guardians, but −8% physical damage. |
| Notched Hunting Token | Charm / rare | 70 | A tally token marks each enemy you hit. Repeated player-arrow hits gain +5% damage per prior hit, up to +25%. |
| Sparkplug Spurs | Boot attachment / rare | 65 | Charged spurs prime your next player arrow after using Space to deal double damage. |
| Emergency Locket | Jewelry / rare | 60 | Once per wave, surviving a hit at 25% health or less grants +35% speed for 3s and blocks damage for 1s. |
| Mercury Hourglass | Clock / rare | 68 | A quicksilver timer. −18% cooldown on both skills, but −15 maximum health. |
| Obsidian Broadheads | Arrowheads / rare | 65 | Heavy volcanic tips. +30% physical damage, but attack interval +18%. Maximum 2 copies. |
| Salvager’s Satchel | Satchel / rare | 65 | A scavenger’s bag. Recover 75% of leftover ground gold instead of 50%, but −8% movement speed. |
| Weathered Buckler | Shield / rare | 65 | A battered little shield. The first damaging hit of each wave deals 50% less damage. |
| Voltaic Spool | Bow attachment / epic | 90 | A coil wired to your bow. Critical player-arrow hits shock one other enemy within 140 units for 40% physical damage. |
| Crimson Thimble | Jewelry / epic | 85 | A thimble threaded with red silk. Each enemy defeated restores 1 health, but −15 maximum health. |
