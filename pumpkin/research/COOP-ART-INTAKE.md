# Cooperative valley art intake — 2026-10-06

The scene reuses the existing bundled, generated mesh artwork; no purchase, Creator Store insertion, source require, or external asset acquisition occurred. Existing `PumpkinMap.rbxm` and `PetModels.rbxm` remain unchanged. `assets/MAP.md` records the original Studio-generated meshes and their upload to the owner's account; that is repository provenance, not an independent license audit.

## Inspected source evidence

Lune 0.10.5 `@lune/roblox.deserializeModel` read both binary files directly. The inspected descendant class census was:

```text
pumpkin/assets/PumpkinMap.rbxm
BillboardGui=4 Folder=3 MeshPart=820 Model=445 Part=290
PointLight=80 SpawnLocation=1 SurfaceGui=48 TextLabel=52 WedgePart=30
LuaSourceContainer=0

pumpkin/assets/PetModels.rbxm
MeshPart=15 Model=15 LuaSourceContainer=0
```

Reproduce the census with this Lune source (read-only):

```luau
local roblox = require("@lune/roblox")
local fs = require("@lune/fs")
for _, path in { "pumpkin/assets/PumpkinMap.rbxm", "pumpkin/assets/PetModels.rbxm" } do
    local root = roblox.deserializeModel(fs.readFile(path))[1]
    local counts, executables = {}, 0
    for _, descendant in root:GetDescendants() do
        counts[descendant.ClassName] = (counts[descendant.ClassName] or 0) + 1
        if descendant:IsA("LuaSourceContainer") then executables += 1 end
    end
    print(path, counts, "LuaSourceContainer=" .. executables)
end
```

Exact inspected template inventory used by `CoopScene`:

| Binary source path | Inspected geometry | Authored use |
| --- | --- | --- |
| PumpkinMap.Zone_PumpkinPatch.Pumpkin | Nested body_geom MeshPart, 4.162 × 3.935 × 4.186 | Nine harvestable roots and hero companion |
| PumpkinMap.Zone_PumpkinPatch.JackOLantern | Nested body_geom MeshPart, 4.488 × 4.160 × 4.500 | Hero landmark, path lanterns, launcher emblems, shop display |
| PumpkinMap.Zone_PumpkinPatch.Scarecrow | body_geom MeshPart, 4.890 × 7.132 × 4.036 | Patch keeper |
| PumpkinMap.Zone_PumpkinPatch.LampPost | body_geom MeshPart, 4.800 × 8.607 × 1.600; Glow Part and light | Four plaza lamps |
| PumpkinMap.Trees.AutumnTree | MeshPart, 14.476 × 17.073 × 13.869 | Four warm canopy framing trees |
| PumpkinMap.Zone_HauntedForest.DeadTree | body_geom MeshPart, 14.860 × 18.676 × 10.316 | Fourteen valley edge silhouettes |
| PumpkinMap.Zone_Graveyard.Gravestone | body_geom MeshPart, 2.679 × 2.864 × 1.642 | Ghost grave markers |
| PetModels.Gummy Ghost | Single Body MeshPart, 2.968 × 3.000 × 2.194 | Shared wave targets |
| PetModels.Misty Ghost | Single Body MeshPart, 3.000 × 2.816 × 2.371 | Alternating shared wave targets |

No fence or catapult mesh was found in the inspected asset hierarchy. Launcher mechanisms and the stall are deliberately authored timber/material primitives with mesh pumpkin decorations; they are not imported mesh mechanisms. Ground uses continuous sculpted Roblox Terrain, with shallow dirt beds, gravel plaza and terrace, rather than a world built from visible block buildings. Art copies are scrubbed by a local class allowlist before entering the DataModel; GUI/code/constraints or unexpected descendants from the source are excluded. No source code is required or executed.

## Composition and integration

The preserved old world stays at its original coordinates. The new arena origin is `(10000,50,0)`. A warm harvest plaza and patch sit behind three independent catapults, looking downhill toward a cooler haunted valley along negative Z. The play route is spawn → pick pumpkin → nearby catapult → nearby upgrades. The giant jack-o-lantern, autumn canopies and readable two-sided signs frame the entry; sparse dead trees occupy valley edges, leaving the launch sightlines open.

`build()` returns `spawn`, nine mesh-root `patches`, three BasePart `launchers`, fifteen direct MeshPart `targets`, `shop`, and `progress`, plus the owned `model`. Spawn is `(10008,54,25)`. Launcher roots are `(9982/10000/10018,54,-10)` and face negative Z. Ghost centers at Z −60/−90/−120/−145 follow `Y = 57 + min(0,(Z+18)*0.065)`, with width/height around 7–8.5. Target art is the returned mesh itself, so transparency changes apply to the entire ghost. `ProgressBoard` has Front and Back SurfaceGui children, each with `ProgressText`; gameplay should update both. The new invisible neutral SpawnLocation supports respawning at the scene. The scene caches repeat builds and only replaces a model bearing its ownership attribute. Terrain writes occupy this remote arena's fixed bounds and do not touch the original map.

## Verification and limitations

StyLua 2.0.2 formatting and Selene 0.31.0 passed with 0 errors, 0 warnings, 0 parse errors. Binary source inspection verifies the stated hierarchy and absence of LuaSourceContainers. This is **source and static evidence**, not a Studio visual acceptance claim. Mesh availability/textures, terrain voxel alignment, signs at the real player camera, exact orientation, collisions, aimability, mobile readability and multiplayer play still require an in-engine run. There is no claim of screenshots or playtest footage from this scene.
