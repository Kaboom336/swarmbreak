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

## Round 1 verdict (2958921, Claude): worse, but the right direction
- **Better:** real materials, terrain and readable lanes. A big step up from the flat blocks.
- **Worse:**
  - The 160-stud square reads as an empty parking lot.
  - Props are scattered evenly instead of clustered.
  - The cool cyan sky and haze flatten everything.
  - No focal point at gameplay height.
  - Hunty's frame is mostly effects and an enclosed, warm-lit room. Ours has neither.

## Round 2 (last round before the stop rule)
1. **Space:** split the square into 3-4 readable pockets:
   - a hangar with a roof over 1/3 of the pad, open on 2 sides
   - container alleys of 2-high stacks
   - a raised catwalk ring along 2 walls
   - half-walls with sandbags at the gates

   Keep the floor rects, the gate lanes and a 20-stud clear arena core.
2. **Clusters:** props in tight clusters of 3-7 (crates, barrels and cables together) with empty floor between them, not sprinkled.
3. **Mood:**
   - Late golden hour: ClockTime about 17.2, warm key light, deeper shadows.
   - Lower Atmosphere Haze/Density, so the sky reads as warm-to-teal and not cyan.
   - Sodium practicals: small orange PointLights or SpotLights on the hangar and the masts, Range ≤ 16.
   - Floor decals: oil stains, skid marks and grime.
4. **Kits:**
   - If Zion has typed the download OK in Play, use KayKit "Space Base" and Kenney "Space Kit" (CC0, textured) for the hangar, pipes, barriers and consoles.
   - Otherwise, use generate_mesh in smaller batches to avoid the "Too Many Requests" error.
5. **Hero shot:** retake 02 gameplay-height with live enemies, mid-fight, the kill burst visible and the HUD on, to match how Hunty's reference is framed.
6. **Score again** with 3 shots plus the side-by-side. If it's still not "matches", stop and report. Claude then recommends pausing Roblox.
