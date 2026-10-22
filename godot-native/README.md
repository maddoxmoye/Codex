# The Emberwood — native Godot study

A separate, playable Mac graphics and combat trial. It uses Godot 4.6.3 Forward+ with Metal on macOS, the approved Rowan/Forest Fox/Briar King rigs, an original Blender ruin, textured slate/bark/soil, local brazier light, environment-only baked reflections, bounded particles and original synthesized sound. No browser runtime is involved. The default is fullscreen with a native in-game interface.

The title opens four modes: Briar King practice, a three-wave hunt, peaceful exploration, and a funded trader visit. The hunt retains 45-second ordinary waves and a 75-second final wave, separate four-choice level rewards, four-item shop stock, increasing within-visit rerolls, equipment stats, mutually exclusive elements, gold recovery and complete XP recovery. This focused study contains Rowan and Forest Fox; the full campaign, all characters/bosses/pets, chest rewards, persistent campaign saves and redesigned item illustrations remain future integration work.

## Run and build

Install Godot 4.6.3. Open `project.godot` in the editor or run `godot --path godot-native` from the repository root. Blender is only needed to edit/re-author the supplied models; `.gdignore` keeps the editable `.blend` source out of Godot imports.

From the repository root:

```sh
npm run check:native
bash scripts/install-godot-native.sh
npm run build:native
```

Set `GODOT_BIN` if Godot is not on PATH. On Linux the repository's `scripts/install-godot-web.sh` installs the matching editor binary; the native installer fetches and verifies the official universal macOS export template. Outputs appear in `dist/native-demo/`. The builder checks both CPU architectures, ad-hoc executable signature hashes, the game pack, archive integrity and executable permissions. It does not notarize the app or run macOS.

`npm run build:native:page` builds only the Pages download page from committed `release-info.json`, linking versioned GitHub Release assets. Changing a released app requires a new version/tag and updated metadata; the browser game deployment never replaces native downloads silently.

## Rendering and motion

Balanced limits the 3D buffer to 1.44 million pixels, High to 2.304 million and Performance to 0.8 million, independently of the full-resolution interface. The scale updates on window/fullscreen changes; a 16:10 Retina screen therefore does not force a 2560×1600 scene. Balanced uses 2×MSAA, ambient occlusion and glow. High adds screen-space reflections and volumetric fog; Performance reduces effects and disables MSAA. Six local fire lights are shadowless; only the sun casts directional shadows. Reflection capture excludes moving actors. F11 or the fullscreen button switches window mode. macOS may require Fn–F11.

Rowan's lower-body stride advances from actual travel while the upper body keeps its authored bow draw and release. Shooting does not restart the stride; backwards movement reverses it and strafing turns the hips. Forest Fox keeps its authored trot with bounded tail follow-through. The motion layer never moves collision bodies. All other approved attack clips and release timings are preserved.

## Validation

Six headless suites exercise movement/collision, first-hit projectiles, elemental ticks/swaps, boss/pet attacks, damage/pause/restart, timed progression, rewards/purchases/rerolls/economy, all skeletal clips, continuous aim/gait and native mode/menu/input flows. The HUD suite drives actual button callbacks and checks desktop layout bounds. Rendered scene and menu screenshots are reviewed separately using Forward+ and Compatibility on Linux. Those software-rendered previews are visual checks, not Mac performance measurements.

`MAC_README.md` contains player setup and controls. Native settings are saved under Godot's application user-data directory; run progress in this trial resets on leaving/restarting a hunt.
