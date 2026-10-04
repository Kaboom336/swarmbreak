# A1 art reset: Landing Pad, pass 1 (2026-10-04)

Built in Studio Edit on the 04126ba place.
- **No store models and no Roblox template.** File > New isn't reachable through MCP while the laptop screen is locked.
- Everything is Roblox built-in PBR materials (Concrete, Asphalt, DiamondPlate, Metal, CorrodedMetal, Fabric, WoodPlanks, Cardboard), Studio Terrain, and Studio generate_mesh props:
  - crate (6x3x3)
  - radio mast (scaled to about 36 studs)
  - floodlight tower
  - chain-link fence
  - generator
  - barrel cluster
- The pipe rack and jersey barrier generations failed (rate limit). Barriers and pipes are built from parts instead.
- 0 scripts. 606 parts.

## Files
- `game/assets/art/LandingPad.rbxm` (107 KB, SerializationService):
  - Model `LandingPad` (Floor / Perimeter / Structures / Props)
  - TerrainRegion `LandingPadTerrain` (paste at Region3int16 (-32,-20,-32)…(32,4,32), so voxel min corner (-128,-80,-128))
  - Configuration `LandingPadMood` (lighting attributes: ClockTime 16.6, Atmosphere, ColorCorrection)
  - Like the rigs, Rojo 7.4.4 can't parse it, so it needs the JSON/asset route.
- Footprint:
  - Floor rects match: 160x160 at y=0, top about 1.05–1.14, non-colliding overlays.
  - Perimeter is drawn at the wall rects, with 20-stud gate gaps on each lane.
  - TowerA, TowerB, GapPillar and Ledge get dressed shells at the same rects.
  - Gate lanes are kept clear.

## Shots (captures/art-landing-pad/)
- 01-spawn-view, 02-gameplay-height, 03-wide (Edit camera, art lighting).
- x-before-props-wide shows the pass before props.
- ref-hunty-*: Hunty Zombie gameplay frames, YouTube auto thumbnails (low-res).
- side-by-side-1 and side-by-side-2: ours | Hunty.

## Honest self-score: **worse** (closer to "close" on materials only)
- **Materials:** close. Everything is now textured PBR, with no flat SmoothPlastic slabs.
- **Density and composition:** worse.
  - Hunty frames are tight interiors (tiled floors, wainscot walls, doors, cabinets, extinguishers), so props fill the frame.
  - Our pad is a 160-stud open square. Even with about 160 props, it reads empty at gameplay height.
- **Mood:** worse.
  - Hunty is warm and contrasty indoor light with big saturated VFX.
  - Ours is a cool, slightly washed outdoor look; the haze and atmosphere flatten the depth.
- **Props:**
  - The generated crates and mast are decent.
  - The containers, sandbags and pallets are part-built and look blocky up close.

## What would close the gap (next pass)
1. Break the open square into sub-spaces: half-height walls, a covered hangar, catwalks and container alleys, so the camera always has mid-ground detail.
2. Warmer key light, lower haze, darker floor, and a few strong practical lights (sodium lamps) for contrast.
3. Real textured kit meshes for containers, pipes and barriers (Kenney/KayKit CC0 needs a download, which needs Zion's OK), or regenerate them via generate_mesh once the rate limit clears.
4. Decals and grime: no decal assets used yet.
