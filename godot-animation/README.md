# Rowan / motion study 01

**https://maddoxmoye.github.io/Codex/animation-preview/**

This is an isolated, real Godot 4.6.3 preview of Rowan's Blender-authored animation. Open the preview, select a motion and camera, and use **½× / ¼× speed** or **Pause** to inspect it. The archer's source, exported GLB and Godot project can be downloaded as a ZIP. The approved base model collection and existing game are preserved.

## Examples

- **Demo loop:** idle, a moving running lap, standing shot, in-place running shot, sidestep and recovery.
- **Run:** a 0.8-second baked cycle with analytical leg IK, planted stance feet and raised swing feet, on a small moving practice lap. The lap is a preview path, not a game controller.
- **Draw & fire:** raise, nock, draw, anchor, release, follow-through and lower. Baked hand and bowstring movement share authored positions. The limbs flex during the draw and briefly settle after release.
- **Run + fire:** a combined in-place body-motion example. This is a **baked combined clip**, not runtime AnimationTree upper/lower-body filtering. Gameplay aiming, movement and procedural animation layering remain a later integration step.
- **Sidestep:** a brief crouch/weight shift with Godot root displacement and recovery. It is not a roll or a finished defensive ability.

**Archer** shows the full character; **Bow detail** frames the upper body; **Full range** shows the target. **Hold draw** pauses at the authored anchor pose with the nocked arrow visible; Resume then releases it. Dragging orbits the camera; Reset view clears that offset. The native project supports 1–5 for modes, Space for pause, and Tab for archer/range camera. There is no player movement input, physics simulation, damage system or gameplay migration.

## Rig and timing

The study is built from the same Rowan geometry and palette as the base collection. It adds four deform controls: `bow`, `bowstring`, `bow_upper`, and `bow_lower`, bringing the skin to **22 bones**. There is still no facial/finger articulation or production IK control UI; the hands remain stylized mittens. Analytical IK is evaluated in Blender and baked into exported bone transforms. Clothes use bone deformation rather than cloth simulation. The source script creates the motions, so no third-party animation pack or paid motion capture is involved.

The **1.82-second release marker** starts a Godot projectile. Just before creating it, Godot samples the exported anchor pose at 1.75s; that avoids incorrect aim if a slow frame skips across the fast string snap. The arrow rests above the grip, follows the nocked position before release, flies along that direction, and tests its segment against the target plane. A confirmed hit leaves the arrow in the target and produces a flash/sparks. It does not home toward the target. The preview target is initially placed from the exported aim pose, as a range setup rather than a gameplay auto-aim system.

Playback crossfades between clips using AnimationPlayer; loop and release management is in `motion_lab.gd`. Slow motion affects the character, root movement, projectile and impact effects together. Pause freezes those simulation updates. A capped simulation timestep prevents large jumps after stalls; it can make playback run slower than wall time on a heavily overloaded browser. FPS is a live observation of this small scene, not a full-game/mobile benchmark. Native builds can perform differently.

## Source and validation

Editable source: `../art/blender/rowan-motion.blend`.

```sh
blender -b --factory-startup --python art/blender/animate_rowan.py
npm run build:godot
npm run build:animation
PORT=3002 node server.mjs
```

Use `-- --no-render` on the Blender command to skip the draw-pose render. The animation script imports the shared geometry builder but writes only the study GLB, metadata, study Blender file and draw image; it never re-exports the base roster. When editing in Blender, the Shoot action is active and a drawn pose is selected. Other exported actions are saved as muted NLA tracks; unmute/isolate the desired track or set its action before playing.

The web build imports assets, runs `check_motion.gd`, then exports the study. The check verifies joint and clip availability, a visible draw, a nocked arrow before release, exactly one projectile per shot, real target intersections at 16ms and 100ms steps, a closed running path and actual sidestep root movement. Open `project.godot` in Godot 4.6.3 to inspect natively. All original art remains editable; the web version shares the Moonwell single-threaded engine and has its own project pack.

Once this motion is approved, its body timing and shared rig layout can be applied to the other archers with equipment/hand placement checks. Pets need their own quadruped or flying animation work; the human run/shoot skeleton should not be copied onto them.
