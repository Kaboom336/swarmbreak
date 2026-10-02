# Laptop setup (Claude's steps, Windows, after Zion installs Studio)

Repo copy: `C:\dev\swarmbreak` (copy `roblox/game/` there; keep this cloud folder as the source of truth until
the laptop copy is a git repo, then the laptop wins).

1. Install Rokit (tool manager): `winget install --id rojo-rbx.rokit` or the release installer.
   Then in `C:\dev\swarmbreak`: `rokit install` (reads rokit.toml: rojo, selene, stylua, lune).
2. `rojo plugin install` (Studio plugin). Restart Studio if open.
3. Switch selene to the full std: in selene.toml set `std = "roblox"` (it downloads the API dump once).
4. Checks: `stylua --check src tests && selene src && lune run tests/run.luau && rojo build default.project.json -o out.rbxl`.
5. `rojo serve`; in Studio: new Baseplate place, Plugins > Rojo > Connect. Delete the default Baseplate part.
6. Press Play. Smoke test list:
   - Spawn, HUD shows "WAVE 1", "Get ready 3".
   - Shift dashes; jump twice in the air double-jumps.
   - Click fires; damage numbers pop; enemies die and coins go up.
   - Wave 5: letterbox intro, "THE BRUTE" card, boss HP bar at the top.
   - B opens the shop; buying Damage lowers coins and raises the level.
   - Die during a wave: "REVIVE NOW" button appears (says "Not for sale yet" until IDs are set).
   - Leaderboard wall reads "No runs yet" (or names after the first publish + API access).
   - Enemies are rigged monsters that walk/flap (not blocks); dying enemies burst into particles.
   - Weapon shows in the right hand; 1-9 switches; melee swings, orbitals circle, the beam sweeps.
   - Output window: no "rbxasset" sound warnings (else swap that entry in Shared/Sounds.luau).
   - Arena has neon grid, portals, boss gate, props; check frame rate with 30 enemies on screen.
7. Fix anything found, run the checks, then ask Zion to Publish (PUBLISH-GUIDE.md).
8. Test on a phone once public: DASH touch button, tap-to-shoot.

Codex tasks for this repo (send via Iris): `testcmd: cd game && stylua --check src tests && selene src && lune run tests/run.luau && rojo build default.project.json -o out.rbxl`.

## Mesh import (after the smoke test works with the part-built fallbacks)
Models are in `assets/models/<group>/<Name>.fbx` (also `.glb`). Sizes in studs are in `assets/models/manifest.json`.
1. Studio: File > Import 3D. Select all FBX files of one group (multi-select works). In the importer panel set
   Scale Unit = Studs; keep Rig Type = No Rig for enemies (we use our own Motor6D rig). Import as one Model per file.
2. Check one: the Walker should be about 5 studs tall (manifest `size_studs`). If it is 100x off, re-import with
   Scale Unit = Centimeters.
3. Each imported Model has one MeshPart per part (Torso, Head, Leg_1...). Give every part whose name ends in
   `_Glow` the Neon material; parts with a Transparency note in the manifest (wings) get Transparency 0.4.
4. Upload: select the imported Models, right-click > Save to Roblox (or the Asset Manager > Bulk Import). Copy each
   MeshPart's MeshId into `src/ReplicatedStorage/Shared/Meshes.luau` (or drop the whole Model into
   ServerStorage/Meshes/<group>/<Name> and let the builders clone it, whichever is faster).
5. Rojo keeps the scripts in sync; the mesh Models can live in the place file (they are not code).
6. If a model faces backward in game, rotate its root 180 degrees once in the builder (front = +Y in Blender = -Z in Studio).
