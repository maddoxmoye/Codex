# Wildfall — base designs 01

Open `wildfall-roster.blend` in **Blender 4.3 or later**. The file contains editable mesh geometry, packed palette texture, eight named asset collections, armature rigs, NLA animation clips, a camera and a presentation studio. Each collection contains one joined skinned mesh and its armature. The studio is for presentation only and is excluded from all GLB exports.

The first pass establishes proportions, palette, silhouettes and equipment. It is deliberately **not a finished production character pack**: there is no facial rig, finger articulation, IK control rig, corrective deformation, lip sync, bow-draw/release animation, combat animation or full game migration. Hands are mitten forms. Clothes are skinned mesh geometry, not simulated cloth. The human rigs share a layout; pet rigs are species-specific. Idle and locomotion clips are simple loop studies so we can evaluate deformation and scale. Bow grip, shoulder/hip transitions, cloth clearance and quadruped foot contact should be refined after design review.

## Roster

- **Rowan / Wayfarer:** open forest hood, leaf clasp, layered trail leathers and recurve bow.
- **Ash / Cinder Scout:** russet scarf, swept hair, scout feather and lighter silhouette.
- **Briar / Ironwarden:** blue-steel cuirass, broad pauldrons, crested open-face helmet and knee armor.
- **Nyx / Moonstring:** pointed moon hood, crescent ornament, silver details and crystal bow tips.
- **Pip / Gearwing:** teal utility coat, brass goggles, visible clockwork backpack and mechanical bow fittings.
- **Forest Fox:** russet coat, cream muzzle, large ears and a smoothly weighted white-tipped tail.
- **Wild Wolf:** silver-blue coat, layered mane, strong paws, claws and a long brush tail.
- **Lantern Beetle:** split jade shell, six brass legs, petal wings and a luminous lantern abdomen.

## Godot-ready exports

The matching GLBs are under `godot-models/assets/archers` and `godot-models/assets/pets`. Everything uses meters, a sole/floor origin and unit object transforms. Blender authors face **-Y with Z up**; glTF converts to **+Z forward with Y up** in Godot. The human silhouette is about two meters including headwear. Pets are intentionally larger/stylized companions; final gameplay scale remains adjustable.

Every model has normalized weights with at most four bone influences per vertex, one mesh, 14–18 deform bones, and at most three material surfaces. Archers use 5,854–7,490 triangles; pets use 2,332–3,430. Exact statistics and animation names are in `godot-models/assets/manifest.json`. The range is a starting budget, not a mobile performance guarantee: enemy counts, draw calls, lights, shadows, physics and the rest of the game must still be profiled.

A single **256×256 palette** drives color. UVs are laid into color swatches; they are not full hand-painted skin/cloth UV islands. Cloth/fur, metal and beetle emission use separate shared shader categories. This keeps textures small while leaving the geometry and palette editable. GLBs embed their texture; no external texture download is required. Godot may extract an adjacent PNG during import.

Each archer exports **Idle / Walk**, the fox and wolf **Idle / Trot**, and the beetle **Idle / Hover**. Clips play in place. In the atelier, clips are explicitly set to loop; when using GLBs elsewhere, set animation import loop mode or configure an AnimationTree. A rest pose can be inspected with playback stopped and skeleton poses reset.

The `.blend` file stores muted NLA tracks so the saved lineup is neutral. The armatures are arranged across the presentation studio; before manually exporting one collection, reset that armature's location to `(0, 0, 0)` so its GLB keeps a floor-centered origin. To preview in Blender, isolate one character's collection, unmute the desired NLA track and leave the other track muted. To keep editing clean, turn off the `Studio / presentation only` collection as needed.

## Rebuild from source

From the repository root:

```sh
blender -b --factory-startup --python art/blender/build_roster.py
```

Use `-- --no-render` at the end to skip the approximately one-minute CPU presentation render. The script rebuilds **only these generated asset files**, the Blender library, manifest and lineup PNG; keep manual art revisions separately before regenerating. The source is procedural mesh modeling in Blender, not image-generated stand-ins. The GLB files, rigs and preview all come from the same scene.

All designs and meshes in this folder are original to this project; no stock models, paid assets, third-party character designs or external animation packs were used. Blender is a tool dependency, not a runtime dependency. Godot licensing is documented in `godot-demo/GODOT-LICENSE.txt` in the repository.
