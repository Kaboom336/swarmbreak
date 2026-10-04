# A1 art reset: Landing Pad, round 2 (2026-10-04)

Built in Studio Edit on the 04126ba place, on top of round 1. No store assets, no downloads, no CC0 kits (no OK line from Zion).
New generate_mesh props, made one at a time: pipe rack, jersey barrier, console terminal, gas cylinder rack.

## What changed
- **Pockets** (`LandingPad.Pockets`):
  - Hangar over the NE quarter (x 14..80, z -80..-20), open on the W and S sides. Columns with hazard sleeves, trusses, a corrugated roof with two skylight strips, cladding above the wall, and hanging sodium lamps.
  - Container alleys in the NW: 2-high stacks, re-tinted (rust, blue, ochre, green).
  - Catwalk along the W wall (z 24..72) plus an SW corner wrap. Rails, legs on the wall side, stairs down toward the west gate, post lamps.
  - Gates: angled jersey-barrier pairs in front of the round 1 sandbag half-walls.
  - TowerA and TowerB re-skinned as container modules: ribs, seams, lit window strips, rust streaks, a door with a lamp, a roof rail, an antenna and a roof unit.
- **Clusters:** 7 groups of 3–7 props (hangar bay, hangar cart, alley mouth, alley end, catwalk base, fuel depot, pad edge), with empty floor between them. Lone props in the lanes and the core were removed. The 20-stud core is clear.
- **Mood:** ClockTime 16.6 (17.2 put the whole pad in wall shadow, so it was pulled back), latitude 18, warm ColorShift, lower ambient, Atmosphere density 0.28, haze 0.7, warm colour and decay. Bloom 0.35, threshold 1.8. Contrast 0.22.
- **Practicals:** all lamps are sodium orange, Range 12–16.
- **Grime:** oil pools, skid-mark trails, dust drifts along the wall bases (thin parts, no decal assets), plus a hatched fuel zone.
- **Spawn check:** nothing collidable inside 10 studs of the 3 Landing spawn plates. Clear straight lines from each spawn to the centre.

## Files
- `game/assets/art/LandingPad.rbxm` (172 KB): Model LandingPad + TerrainRegion LandingPadTerrain + Configuration LandingPadMood. 0 scripts, 1,493 parts. Rojo still can't read it, as in round 1.

## Shots
- 01-spawn-view: Edit camera at player height, looking at the hangar.
- 02-gameplay-height: play mode with the HUD, wave 6.
- 02b-midfight-occluded and 02c-midfight-camera-in-container: the mid-fight attempts.
- 03-wide.
- side-by-side-1 and side-by-side-2: ours | Hunty.
- For the play-mode shots, the runtime ArenaBuilder primitives, PropScatter and crystal lights inside the pad were hidden client-side, and the mood was forced on the client (the game sets ClockTime 14.5 at runtime).

## Hero shot: not achieved
- I could not get live enemies and a kill burst in the open in one frame (5 waves tried).
- Enemies spawn at (-40,±72) and (-72,0) and walk behind the new container stacks. The camera sees them as outlines through containers, and auto-fire kills them before they clear the cover.
- The wave-5 brute intro took over the camera.
- So the new pockets also hide the fight. The art and the gameplay layout have to be designed together (spawn lanes, sight lines, camera occlusion).

## Honest score: **still not "matches"** (better than round 1: "closer")
- **Better:** warm sunset sky and horizon, readable silhouettes, the hangar and tower modules have real structure, there are colour accents, and the floor has grime.
- **Still short of Hunty:**
  - Hunty frames are dense, textured interiors with characters and big VFX filling the screen. Ours is still primitive-built: flat-faced containers, plain wall panels, and the H pad dominates the middle.
  - The props are sparse at gameplay height.
  - No mid-fight frame shows the fight.
  - The look only holds with the runtime arena hidden, so it isn't what a player sees today.

## Stop rule
Round 2 was the last round. Recommendation: pause Roblox art.
Possible paths if it resumes:
1. Real CC0 kit meshes (needs Zion's OK line).
2. Rebuild the arena so gameplay geometry *is* the art, with spawn lanes and sight lines designed first.
