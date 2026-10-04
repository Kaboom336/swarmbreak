# Kit import (2026-10-04)

Zion OK'd Studio's Import 3D in the thread. Both packs are CC0; licences are in game/assets/kits/.

## What was imported
- **swarmbreak_kit.obj**: 49 objects, built with tools/merge_obj.py. The KayKit pieces came through with texture atlas rbxassetid://97781040058806.
- **swarmbreak_kenney.obj**: 19 Kenney objects, built with tools/kenney_palette.py. Kenney's MTL colours were baked into a 64x32 palette PNG, uploaded as rbxassetid://72266639201085.
  - The first import of the Kenney pieces came out grey (OBJ colours are dropped on import), so those duplicates are not used.
- Every mesh was uploaded to Zion's account by the importer. There are no scripts in either import.

## Landing Pad dressing
- 44 kit MeshParts in LandingPad.Kit, 33 unique mesh ids across the whole manifest.
- Layout checks, all passing:
  - No collidable parts within 6 studs of the lines from each spawn plate (-40,±72), (-72,0) and each art gate to the core.
  - No collidable parts inside 20 studs of the centre.
  - No collidable piece taller than 4 studs in the 20–45 stud ring. The light poles are CanCollide false.
  - 950 parts in the model; 745 visible parts exported.
  - Largest kit prop: lander_A, 1,464 triangles.

## Files
- **game/assets/art/LandingPad.rbxm** (232 KB): source model + TerrainRegion + LandingPadMood.
- **game/assets/art/LandingPad.json**: 745 parts with Kind (Floor 199, Wall 176, Cover 134, Prop 213, Light 23).
  - Each part has Name, ClassName, MeshId, TextureID, Size, CFrame, Color, Material, Transparency, CanCollide, Anchored and CastShadow.
  - Parts may also carry Shape, SurfaceAppearance and Lights[].
- **game/assets/art/LandingPadMood.json**: Lighting, Atmosphere, ColorCorrection, Bloom and Sky.
- Compact copies of both JSONs are in game/src/ReplicatedStorage/Shared/Art/.
- The terrain under the pad is only in the .rbxm (TerrainRegion, pasted at (-32,-20,-32)..(32,4,32)).
- Terrain is not code-managed: Rojo does not touch `Workspace.Terrain`. Import the
  `LandingPadTerrain` TerrainRegion from the `.rbxm` in Studio; the runtime art loader
  neither creates nor clears Terrain.
