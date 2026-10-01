# Assets and licenses

## 3D models: made by us, in Blender, by script (no license needed)
Every enemy, weapon and arena piece is built by the scripts in `tools/blender/` (Blender 5.0 as a Python module,
`pip install bpy`). Rebuild any time:

    cd game/tools/blender
    python3 enemies.py        # 8 enemies  -> ../../../assets/models/enemies/*.fbx + .glb, renders in assets/renders/enemies/
    python3 weapons.py        # 15 weapons -> assets/models/weapons/
    python3 arena.py          # 12 kit pieces + a lineup render -> assets/models/arena/
    python3 sheet.py          # contact sheets: assets/renders/{enemies,weapons,arena}-sheet.png

Rules baked into the scripts: 1 unit = 1 stud; front = +Y; parts named after the Motor6D rig
(Torso, Head, Jaw, Arm_L/R, Leg_n, Wing_n); parts ending `_Glow` get the Neon material in Studio; vertex colors,
no textures; under 10k triangles per part. `assets/models/manifest.json` lists parts, triangle counts and sizes.

Until the FBX files are imported on the laptop, the game still uses the part-built fallbacks in
`src/ServerStorage/EnemyBuilder.luau`, `WeaponModels.luau` and `ArenaBuilder.server.luau`.
`src/ReplicatedStorage/Shared/Meshes.luau` maps model names to uploaded mesh ids (0 = use the fallback).

## Roblox built-in sounds (ship with the client, no upload, no license check)
`src/ReplicatedStorage/Shared/Sounds.luau` uses `rbxasset://sounds/...` files that are part of the Roblox install.
Verify on the laptop: Studio's Output window warns for any path that doesn't exist. Replace a missing one with a
Creator Store sound after checking its license page.

## Music: none yet
`Sounds.Music.Id` is empty. Zion wants a familiar or unique track, not stock Roblox loop music. Chart songs cannot be
licensed by us; pick a distinctive track from the Creator Store audio library (licensed for use inside Roblox) on the
laptop, paste its id, and note it here.

## Optional extras (laptop, later)
Free CC0 packs if we want more props than the kit: KayKit Dungeon Remastered (CC0, github KayKit-Game-Assets),
Kenney (kenney.nl), Quaternius (quaternius.com). Log each import here: name | source URL | license | used for.
