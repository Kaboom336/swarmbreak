# Pumpkin map (Studio operator pass, 2026-10-05)

- `assets/PumpkinMap.rbxm` is the hand-built map. Rojo puts it in `Workspace.PumpkinMap` (see `default.project.json`).
  - It was serialized in Studio, then the `Tags` property was stripped with `tools/rbxm_strip.py`, because Rojo 7.4.4 can't read it.
- **Part names**, as MapFallback, Game and Pets expect:
  - `ZoneStart_<Zone>`;
  - `Track_<Zone>` with `Wall_1..Wall_10` (Health attribute = 10 × 1.6^(n-1), shown on each wall);
  - `ZoneGate_<Zone>`;
  - `Egg_CandyEgg`, `Egg_SpookyEgg`, `Egg_BoneEgg`;
  - `Leaderboard_Wins` and `Leaderboard_Size` (lobby, facing +X);
  - `PumpkinSpawn`.
- **Layout:** 4 zones 110 studs apart along Z:
  - Pumpkin Patch (orange walls);
  - Haunted Forest (lime);
  - Graveyard (cyan);
  - Witch Castle (purple and pink).

  Each zone is a 0.12-slope hill track, 550 studs long. Gate arches carry the zone name and its unlock cost, the start pads have "ROLL!" signs, there are lamp posts with glow at every wall and a FINISH arch, and a zone landmark sits past the finish.
- **Props:** Studio generate_mesh (pumpkin, jack-o-lantern, dead tree, gravestone, castle tower, scarecrow, egg, lamp post, fence), uploaded to Zion's account. 582 parts, 218 MeshParts.
- **Lighting:** night sky with a moon, teal/purple atmosphere, saturation +0.3. Set in `default.project.json` under Lighting.
- **Pumpkin on the head:** it's still a sphere SpecialMesh. To use the real pumpkin mesh, set `MeshType = FileMesh`, `MeshId = rbxassetid://139105509213577` and `TextureId = rbxassetid://78839540616611`. Same IDs for the roll pumpkin in Roll.client.
- **Art:** `art/thumbnail-1920x1080.png`, `art/icon-512.png`. Screenshots are `art/map-*.jpg` and `art/play-*.jpg`.

## Q1-B daylight pass (2026-10-05)
- **Walls** are themed MeshParts, keeping the `Wall_n` names, Health attributes and SurfaceGui labels:
  - Patch alternates hay bales and pumpkin stacks;
  - Forest is log piles, Graveyard is tombstone walls, Castle is candy-brick walls.
  - Each wall is a single BasePart, 34 × 11 × 6 studs, so `LocalTransparencyModifier` still hides it in Roll.client.
- **Ground:** `Valley` is now `Ground`, a 4000 × 4000 grass plate, so MapFallback skips its own.
- **Scenery:** `BackHills` holds 46 grass domes ringing the map. `Trees` holds about 490 generated autumn trees along the tracks, around the edge and down the lobby.
- **Gates:** gate pillars and finish posts are wood.
- **Pets:** `assets/PetModels.rbxm` maps to `ServerStorage.PetModels`.
  - There are 15 Models named as in Config.Eggs. Each has one MeshPart `Body` (about 3 studs, unanchored, massless) as its PrimaryPart.
  - The front faces −Z.
  - Preview: `art/pets-15.jpg`.
- **Icons:** `art/icons/*.png` are uploaded, and their IDs are in `Config.Icons`.
- **Not done:** the track slope is still 0.12. Steepening it would mean re-placing every track prop.
