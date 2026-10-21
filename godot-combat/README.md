# Wildfall combat atelier

Play: **https://maddoxmoye.github.io/Codex/combat-preview/**

An isolated Blender → Godot 4.6.3 draft of all five playable characters and three companions, before boss-wave integration. Existing game saves, balance, models and earlier previews are preserved. No paid assets or animation packs are required.

Choose a character, then **Demo loop**, **Draw & fire**, their **Space** defense, or their **E** attack. Buttons replay a study; keyboard Space/E uses cooldowns. Character and bow views isolate the archer; Full range includes targets and the companion. Choose a pet and **Watch pet** for its close-up. Drag to orbit; hold draw, pause, slow motion and fullscreen are available. Download the editable Blender files, GLBs and Godot project from **Blender + Godot files**.

| Character | Space | E | Visual draft |
|---|---|---|---|
| Rowan | Windskip | Flock & Awe | Existing bow rig, wind dash and eight-arrow salvo |
| Ash | Hare Trigger | Arrowpalooza | Lean sprint, scarf follow-through and double-cadence shooting |
| Briar | Shell Yeah! | Quiverquake | Armored brace, golden shield ribs, blocked projectiles and twelve radial arrows |
| Nyx | Bramble Bouncer | Hunter’s Moon | Open-palm ward, thorn ring, target pushback, crescent and doubled arrow damage |
| Pip | Borrowed Time | Gear Expectations | Winding gesture, clock dial, slowed incoming shots and clockwork three-arrow fans |

The five archers use the same 22-bone bow/string/limb controls as Rowan. Each new character has its own editable `.blend` and GLB clips. Bow hands, string draw, limb flex and planted stance use Rowan's analytic IK helpers, evaluated and baked in Blender. The generator does not edit the approved roster exports. All supplied sources remain original procedural designs with stylized mitten hands and bone-driven cloth; facial/finger rigs and runtime animation layering are later work.

Wolf has planted paws, independent ears/tail, a new articulated jaw for bites, and a muzzle-up howl. Its movement uses fixed patrol destinations and separate approach, facing, bite, howl and rest states. Turns have a speed limit; complete attack clips and 0.14-second skeletal pose blends prevent the previous run/bite flickering at arrival thresholds. The preview shows bite contact numbers and a howl ring; final enemy slow integration comes with gameplay. Lantern Beetle has six-leg crawling, hinged shells, flapping wings, collection and delivery. It scouts demonstration gold/XP tokens, carries one back, and repeats; this preview awards no saved currency. Fox retains its three physical darts and earlier baked clips. Pet styles are independent of the selected character or element.

Godot manually samples the baked clips and launches mesh arrows at exported release markers. The normal arrow follows the bow/string direction; fans and radial specials use their authored target patterns. Segment/plane intersections stop arrows at the first target, update its demonstration health bar, show a damage number and leave a bounded set of embedded arrows. Timed effects, projectiles, cooldowns and pets share pause/slow motion. Transient objects expire and embedded arrows are capped at 24.

## Timing and scope

The existing character kits supply durations, cooldowns and damage multipliers. This is a readable choreography study: ordinary archery plays at 2× Rowan's original slow study (one draw in 1.6s); Ash doubles that cadence. Nyx retains normal cadence and doubles impact damage; Pip adds three-arrow fans every 0.6s. Gear fan release and Rowan's salvo include short visible windups instead of the current game's immediate casts. These preview timings are not a replacement for the game's fire-rate system. Continuous combat, upper/lower-body blending, controller locomotion, real enemies, boss fights and full-game migration remain separate integration steps.

The scene uses the existing low-poly woodland and shared Godot Compatibility web runtime, without external libraries, threaded workers or per-frame full-screen effects. It supports responsive portrait controls but has not been benchmarked on a physical iPhone. FPS describes this small study; it does not predict a full wave's performance. A capped timestep makes an overloaded software-rendering browser run slower than wall time.

## Rebuild

```sh
blender -b --factory-startup --python art/blender/animate_combat_roster.py
blender -b --factory-startup --python art/blender/animate_companions.py
npm run build:godot
npm run build:combat
PORT=3002 node server.mjs
```

Open `http://localhost:3002/dist/combat-preview/`. The Godot project can also be opened directly in Godot 4.6.3. Native Space/E/P and mouse/touch orbit work there. Web character/pet selection lives in the HTML shell; native defaults to Ash/Wolf. The content-hashed `.pck` avoids stale animation packs after publishing.

`check_combat.gd` verifies each kit's clips, actual string displacement, projectile/impact counts at 16ms and 100ms, Nyx's damage multiplier, defense expiry, cooldown/paused casting, all companion sequences and bounded effects over repeated casts. Asset tests compare the preview's skill identity/durations to game content and inspect GLB skin and animation data. Browser checks cover all character kits, pet close-ups, hold draw and phone layout.

`check_wolf.gd` runs 30-second movement regressions at 8/16/33/100ms and mixed frame intervals. It checks state stability, bounded root movement and turning, full bite/howl recovery, planted attacks, cooldowns, finite bone transforms, transition blending, paused/hidden views and companion switching.
