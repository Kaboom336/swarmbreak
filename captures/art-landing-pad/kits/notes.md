# CC0 kit preview (2026-10-04)

Zion OK'd downloading the KayKit Space Base and Kenney Space Kit in the thread.

## Sources and licenses (both CC0, verified in each pack's license file)
- **KayKit Space Base Bits 1.0** by Kay Lousberg: github.com/KayKit-Game-Assets/KayKit-Space-Base-Bits-1.0. OBJ/glTF plus one 1024 texture atlas.
- **Kenney Space Kit 2.0**: kenney.nl/assets/space-kit. 153 models; OBJ uses MTL colours, no textures.
- Both packs contain models and textures only, no scripts.

## What was done
- Converted 30 KayKit and 19 Kenney OBJs to JSON (`game/assets/kits/json`) with `tools/obj2lua.py`.
- Built them in Studio Edit as EditableMesh MeshParts, with flat normals.
- KayKit uses the atlas uploaded as rbxassetid://79286790037338. Kenney uses per-face material colours.
- Rebuilt the Landing Pad dressing with kit pieces:
  - Base modules, garage and cargo depot in the NE.
  - Cargo stacks in the NW and in place of the old containers.
  - A landing pad and lander in the SE.
  - Kit structures sized to the TowerA and TowerB rects.
  - Light poles with sodium lights, generators, barrels, a dish, solar panels and wind turbines.

## Limits
- EditableMesh parts do not save or replicate. In Play they come up empty, so there is no play-mode or hero shot yet.
- To ship, the meshes must become real Roblox mesh assets. Options:
  - Studio's Import 3D, driven by computer use while the screen is unlocked.
  - An Open Cloud key, which Zion would paste.
  Either way the assets are created on Zion's account.

## Shots
kit-lineup, kit-wide and kit-ground (Edit camera, same sunset mood as round 2).
