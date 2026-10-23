# Wildfall — The Emberwood

A standalone native Godot twenty-wave survival campaign for Mac. The download includes the game engine; Godot does not need to be installed to play.

## Open on your Mac

1. Download `Wildfall-Emberwood-macOS.zip` and double-click it to extract the folder.
2. Move **Wildfall Emberwood.app** to Applications, or keep it in the extracted folder while testing.
3. Double-click the app. This early test build is ad-hoc signed, rather than Apple-notarized. If macOS blocks it, open **System Settings → Privacy & Security**, find the message about **Wildfall Emberwood**, choose **Open Anyway**, and confirm **Open**. Only approve the build you downloaded from this project's link.

The app contains both Apple Silicon and Intel executables in one universal binary. The default Metal renderer is configured for your **M1 MacBook Pro with 8 GB of memory and macOS Sequoia 15.3.2**. The app bundle allows macOS 11 or later, but rendering support varies by Mac and OS; the Compatibility launcher is available for older graphics configurations.

## Graphics and controls

Start with the game's **Balanced** graphics preset. It limits 3D rendering resolution independently of the crisp interface, including on Retina displays. **High** increases lighting and effects; **Performance** reduces rendering work. Fullscreen is the default; use the onscreen fullscreen button or **F11** to switch to a window. On a Mac keyboard, **Fn–F11** may be needed if the function key is assigned to a system shortcut. If the standard renderer cannot open on an older GPU, keep the app in the extracted folder and open **Launch in Compatibility Mode.command**. That launcher uses Godot's simpler renderer for this app only and does not alter Mac security settings.

Use **WASD** to move, **Space** for your archer’s defensive ability, **E** for their offensive ability, **F** to toggle automatic targeting/fire, and **P / Escape** to pause. Right-drag to orbit the camera. The menus include graphics settings, fullscreen, a free-camera toggle and a return to the title screen. Free camera lets ordinary mouse/trackpad movement orbit the view; pause to release the cursor.

If movement keys are inconvenient on your keyboard, macOS input still uses physical WASD positions. A mouse is useful for camera movement; a trackpad with secondary click enabled also works.

## Help tune the next build

After trying the twenty-wave campaign, note the graphics preset and whether movement stays smooth during his attacks. A short recording is useful for animation feedback. Performance must be measured on your Mac; Linux build checks and software-rendered previews cannot establish Mac frame rate.

## Editable project

`Wildfall-Emberwood-source.zip` contains the Godot project and its assets. Import `project.godot` in Godot **4.6.3** to edit it. Use `bash scripts/install-godot-native.sh` and `node scripts/build-native-demo.mjs` in the full repository to rebuild the Mac download.

Godot is free software under the MIT license. Engine and third-party notices are included in the **Licenses** folder. This game does not require an account, microphone or camera access.

## Campaign build 0.2.0

All five archers are unlocked. Select one and choose **Start Run**. Everyone starts with basic arrows and no companion. Buy elemental quivers, pets and their upgrades at the trader. Each wave lasts 45 seconds; guardian waves 5, 10, 15 and 20 last 75 seconds. Killing a guardian earns a Mythic chest; surviving its timer does not. The Colossus must die for campaign victory.

Earned chests automatically collect at wave end and open before level rewards and the trader. Take the item, pay for a chest-specific reroll, or sell it. Defensive investment becomes essential in later waves. Pause to inspect your build or restart. Returning to the title discards the current run; this version does not save unfinished runs. Graphics/audio settings are saved.
