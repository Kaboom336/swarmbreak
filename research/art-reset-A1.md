# A1 art reset: Outpost 9 Landing Pad, built in Studio (2026-10-04)
Zion (10/04 13:36Z): "it just looks bad. I've seen so many good AI-made Roblox games on TikTok that look way better."
Diagnosis: the whole world is flat-coloured blocks made in code. Lighting is already Future, so lighting isn't the gap; models, materials and composition are.

## Rules
- No feature work until a Landing Pad screenshot matches Hunty Zombie side by side.
- **Stop rule:** at most 2 rounds. If round 2 still isn't "matches", Claude recommends to Zion that Roblox pauses until a money lane pays.

## Play thread (Studio, laptop), working on a copy of the place
1. **Base:**
   - Open Roblox's own free templates (File > New) and pick the best-looking one for a sci-fi or outpost feel. Templates are Roblox-made, so they're allowed. Note which one you picked.
   - Use its textured meshes, materials and lighting as the starting kit. Keep it out of the game loop: no template scripts in our place.
2. **Ground:**
   - Studio Terrain under and around the Landing Pad island: rock cliffs, grass or moss, and a mist and cloud sea below.
   - Pad floors keep our floor rects (same size and position) but use MaterialVariants or textured meshes (metal plate, concrete), not SmoothPlastic.
3. **Props:**
   - CC0 textured kits: Kenney, KayKit (Space Base, Sci-Fi), Quaternius. Import as FBX with their texture.
   - Place by eye: crates, antennas, pipes, lights, fences, foliage, and one landmark (a radio mast) visible from spawn.
   - Respect gate lanes and the floor rects. Keep each prop at or under 1.5k triangles.
4. **Mood:**
   - Atmosphere, Sky and ColorCorrection on our Station preset, tuned by eye.
   - Small PointLights only. No Neon slabs.
5. **Save** the result as Workspace/Arena/Art/LandingPad (a Model, no scripts) and export it as an .rbxm to game/assets/art/. Push it to the art/landing-pad branch.
6. **Judge:** 3 screenshots (spawn view, gameplay height, wide) beside matching Hunty Zombie shots. Self-score honestly: "matches", "close" or "worse". Iterate once if needed (2 rounds total; see the stop rule).

## Code side (Claude, after the art lands)
Rojo can't read the .rbxm, so the code side loads the art the same way as the rigs: a JSON or asset route. ArenaBuilder then stops building primitive props on the Landing Pad when Art/LandingPad is present.
