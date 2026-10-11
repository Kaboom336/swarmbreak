# LOOK CRITIC 1: hub after the recolour pass (blind, hostile)

Evidence judged:
- NEW-A, overview from spawn: `tool-results\mcp-Roblox_Studio-blob-1791687505032-xcfr3i.jpg`
- NEW-B, player height near the King: `...-1791687511248-35w9rw.jpg`
- OLD-A `...-1791683631029-z1115f.jpg` and OLD-B `...-1791684201110-xqymoc.jpg`

The bar:
- AUDIT-LOBBY-MAP.md §4, "Pumpkin Patch at Golden Hour".
- Lobby and map REFERENCES. Frames viewed: TE t_0494 and SAE h_0018.
- ui/v2/06 (GAG world shots).

Hub centre = (1500, 0, 40), hub 340 x 220. In the offsets below, X is across the hub and +Z points toward the lane / safe line (Z 150 = centre +110). The spawn is on the −Z side.

---

## 1. Verdict

A kid would call it **"cheap"**. Yes, still.

It is better than before. The old version had a neon lime checker floor, terracotta checker walls, purple cobble paths with orange outlines and a red screen wash: a 2/10 eyesore. The purple walls and lilac paths finally form a family.

But NEW-A is still mostly one colour:
- About 45% of the frame is flat, saturated stud-lime with nothing on it.
- The hero is a small box seen from the back.
- The sky is noon blue, not golden hour.
- Everything that should feel premium (lanterns, stalls, gravestones, pumpkins) is the size of a thumbnail.

TE t_0494 has something every 3-4 character heights. Ours has something about every 30 studs. Even SAE, which is nearly empty, has a glowing Rift and giant pets for mass. We have neither.

| Axis | Old | New | TE / SAE refs | Why the new score |
|---|---|---|---|---|
| Premium feel | 2 | 3.5 | 8 / 6 | Clean recolour, but bare primitives at default scale. Nothing glows or moves. |
| Palette harmony | 2 | 5 | 8 / 7 | Purple walls and lilac paving agree. The grass (#7FD62E-ish lime) fights both and is the loudest colour on screen. There is no warm orange or yellow mass anywhere. |
| Centrepiece | 3 | 3 | 8 (portal, KotH) / 7 (Rift) | It faces away from spawn, so you see a purple box back. The head is about 12 studs wide at 120+ studs from the camera. There is no face glow, no light pool and no title. The plinth is a plain lavender cylinder. |
| Prop density | 3 | 2 | 8 / 4 | The foreground is empty. 3 pumpkins and 4 gravestones sit on the ring. The stalls are pushed 100+ studs away against the back wall. |
| Lighting mood | 1 (red wash) | 3 | 7 / 6 | Flat noon light, cyan sky and weak shadows. The far lane has a lilac haze, but the hub has none. No warm key and no point lights. |
| Readability | 4 | 5 | 9 / 7 | The radial spokes do say "centre". But the spokes lead nowhere, the stalls have no titles readable from spawn, and the navy slab on the right wall is a blank rectangle. |
| **Overall** | **2.5** | **3.5** | 8 / 6 | |

What reads as cheap, in the order a kid notices:
1. Billboard lime studs everywhere.
2. The King's back.
3. Sawtooth paving: the ring is a polygon of overlapping wedges, and triangular grass teeth poke through at every spoke joint (NEW-A centre, NEW-B foreground).
4. Pin-head lanterns on the wall cap.
5. Empty field.

---

## 2. Ten fixes for the scene script, most impactful first

### 1. Turn and enlarge the King (hero)
- **Facing:**
  - Set `King:PivotTo(CFrame.lookAt(kingPos, Vector3.new(spawn.X, kingPos.Y, spawn.Z)))` so the face looks at the SpawnLocation.
  - Then verify in a spawn-camera capture that the face, not the purple back, is visible.
- **Scale:** whole model 2.2x. The pumpkin head is 26 wide and its centre sits about 30 studs above the ground. Body and crown scale with it.
- **Face:** Neon parts #FFB347: two triangle eyes 5 x 5 and a zig-zag mouth 14 x 4. Recess them 0.5 into the head.
  - Inside the head add a PointLight: Color #FF9A3C, Brightness 3, Range 40, Shadows false.
- **Crown:** #FFC83D, Material Metal, 5 points of 2 x 4 x 2 on a 20 x 2 x 20 band. The tips are Neon #FFE58A at 0.3 transparency.
- **Body:** recolour from flat #5A2BC8 to #7A52BF Plastic. Add an aubergine #2D1F43 belt (1-stud band) and a cape (wedges #D35208, 0.4 thick) so the back is not a box.
- **Title:** BillboardGui 40 x 10 studs at Y +48: "PUMPKIN KING" in FredokaOne, #FFC83D with a #2D1F43 stroke of 3. MaxDistance 400.

### 2. Rebuild the dais as the "Throne" (centre 1500, 0, 40)
Replace the plain cylinder with three stepped Cylinder parts (axis Y):

| Step | Diameter | Height | Top at Y | Colour | Material |
|---|---|---|---|---|---|
| 1 | 44 | 1.5 | 1.5 | #A9ABD3 | SmoothPlastic |
| 2 | 36 | 1.5 | 3.0 | #B8BADD | SmoothPlastic |
| 3 | 28 | 1.5 | 4.5 | #B8BADD | SmoothPlastic |

- Each step gets a trim ring 0.5 wider and 0.3 tall, #E8E4D0.
- Replace the yellow disc with a Neon glow pool: Cylinder D 26 x 0.1, #FFB347, Transparency 0.35, on top of step 3.
- **Hay ring:** 12 hay bales, 5 x 3 x 3, Fabric #E3B04B, two 0.4 bands #B5832E. Place them at radius 25 from centre at 30° steps, rotated tangent, with 3 of them stacked two high.
- **Pumpkins:** 8 pumpkins (#F28C1A, shade #D35208) of 3-5 studs between the bales.

### 3. Kill the stud grass and desaturate it
- On every hub floor part set Material **Grass** and remove the Studs surface: TopSurface = Smooth and **remove** any stud texture decals.
- Two-tone 16 x 16 checker:
  - #6BAA3E / #639F39
  - Darker and less yellow than the current lime, about −25% saturation.
- Alternative: Terrain Grass. Fill a 340 x 4 x 220 block at Y −2, set `Terrain:SetMaterialColor(Enum.Material.Grass, Color3.fromHex("6BAA3E"))` and `Terrain.Decoration = true`, and keep the part floor collision-only and invisible. Only do this if raycasts tolerate it.
- **Meadow tint:** in the four outer corners (beyond ±120 X, beyond −70 Z) use #9CC544 so the floor is not one flat colour.

### 4. Golden-hour lighting (the §4 values; currently noon)
- **Lighting:** ClockTime 15.6, Brightness 2.4, GeographicLatitude 30, ExposureCompensation 0, GlobalShadows true, ShadowSoftness 0.2.
- **Ambient and environment:** Ambient #8C7AA8, OutdoorAmbient #9D8DBF, ColorShift_Top #FFD9A8, ColorShift_Bottom #6B4E8C, EnvironmentDiffuseScale 0.4, EnvironmentSpecularScale 0.3.
- **ColorCorrection:** exactly one, with Brightness 0.02, Contrast 0.12, Saturation 0.08, TintColor #FFF1E6. Delete any others.
- **Atmosphere:** Density 0.28, Offset 0.12, Color #E7C8E8, Decay #B07ACF, Glare 0.15, Haze 1.2.
- **Bloom:** Intensity 0.8, Size 28, Threshold 0.95.
- **SunRays:** Intensity 0.06, Spread 0.6.
- **Sky:** keep the cartoon skybox but set SunAngularSize 14.
- **Daytime moon:** a Neon disc D 160, #E9DDF5, Transparency 0.2, at (1500, 120, 40+420), facing spawn. It sits low over the lane mouth and is visible from spawn.

### 5. Replace the jagged paving with clean solid shapes
- Delete all wedge segments of the ring and spokes.
- **Ring:** Cylinder D 84 x 0.4, top at Y 0.25, #B8BADD SmoothPlastic. Under it, an edge cylinder D 86 x 0.35, #E8E4D0.
- **Inner lawn:** grass Cylinder D 52 x 0.45 laid over the ring's centre, #6BAA3E Grass.
- **Spokes:** cut from 8 to 6.

| Spoke | Direction | Width |
|---|---|---|
| Spawn → King | −Z | 16 |
| King → lane | +Z | 16 |
| West pens | −X | 12 |
| East pens | +X | 12 |
| Stalls | 2 diagonals at ±40° toward +Z | 12 |

- Each spoke is a single Part, 0.4 thick, #A9ABD3. It starts at radius 38, so it tucks under the ring with no gap.
- Each spoke has 1-stud #E8E4D0 curbs both sides, 0.5 tall.
- No path ends in open grass: every spoke ends at a pad (stall, gate, pen).

### 6. Real lanterns
- **Path lanterns:** 20 in total, in pairs along each spoke every 18 studs, offset 2 studs outside the curb.
  - Post: 0.8 x 12 x 0.8, #2D1F43.
  - Arm: 3 x 0.6 x 0.6.
  - Lantern box: 2.4 x 3 x 2.4, frame #2D1F43 with a Neon #FFB347 core of 1.8 x 2.4 x 1.8.
  - PointLight: Color #FFB347, Range 16, Brightness 1.5.
- **Wall-cap lanterns:**
  - Replace the 1-stud dots with Neon cubes 3 x 3 x 3, #FFB347, on 1 x 3 x 1 brackets.
  - Spacing: every 24 studs (14 per long wall, 9 per short wall).
  - PointLight every second one: Range 14, Brightness 1.

### 7. String lights down the main axis (spawn → King → lane)
- 5 pairs of posts, 0.8 x 16 x 0.8, #2D1F43, at Z offsets −90, −60, −30, +50, +80, X = ±11 from the centre line.
- Bulbs: 2 sagging rows per span, spheres 1.0, Neon, alternating #FFB347 and #FFC83D, every 3 studs. Sag 3 studs at mid-span (parabola).
- 4 PointLights per span: Range 10, Brightness 0.8.
- These are the same lights as in the lane (NEW-B right side), so the hub and lane become one street.

### 8. Fill the empty field with pumpkin-patch beds
In the four quadrants between spokes, keep 10 studs clear of any path or pen fence. Place 6 beds:

| Bed | Relative position (X, Z) | Size (X x Z) |
|---|---|---|
| 1 | (−48, −62) | 30 x 18 |
| 2 | (+48, −62) | 30 x 18 |
| 3 | (−100, −40) | 28 x 16 |
| 4 | (+100, −40) | 28 x 16 |
| 5 | (−70, +60) | 24 x 14 |
| 6 | (+70, +60) | 24 x 14 |

- **Soil:** #7A4E33, Material Ground, raised 0.6. Furrow strips are 1 x 0.2 x length, #5E3A26, every 4 studs.
- **Pumpkins per bed:** 10, sized at random from 2.5 to 7 studs (#F28C1A / #D35208, stems #4E7A2A), plus green leaf wedges #4E8F34.
- **Each bed:** 1 lit jack (Neon face, PointLight Range 10) and 1 scarecrow, or a 3-bale hay stack.
- **Gravestones:** pull the 4 scattered ones into 2 clusters of 5 by the back walls. Scale them 1.6x (about 3 x 4 x 1), colour #8E8AA8.

### 9. Haunted Gate at the lane mouth (centre +110 Z)
- **Twin towers** at X ±40:
  - Body 12 x 42 x 12, #4E4775 Plastic.
  - Stacked-cube purple spire #7A52BF: 8, 6 and 4 cubes, top at Y 58.
  - 2 Neon windows each, 3 x 4, #FDF301.
- **Arch beam** between them: 80 x 4 x 4 at Y 34, #2D1F43.
- **Banner:** 40 x 8, #F28C1A, with SurfaceGui text "PUMPKIN PATCH →" in #FFFFFF with a #2D1F43 stroke.
- This frames the lane gap, which currently reads as a hole in the wall.

### 10. Make the walls and stations read from spawn
- **Wall buttresses:** every 40 studs, 6 x 34 x 4, #453E69, each topped with a 4-stud pumpkin finial. Cap trim: 2 x 1.5, #E8E4D0.
- **Trees:** 6 orange/red kit trees at 1.8x scale in the back corners (±150, ±90).
- **Stalls:**
  - Scale 1.5x and pull them 25 studs inward from the back wall.
  - Each stands on a Neon pad D 18 x 0.2 at 0.4 transparency: SELL cyan #39D8F0, SHOP #FFC83D, UPGRADES #7A52BF.
  - Each has a 3D or billboard title 6 studs tall, readable from spawn (MaxDistance 350).
- **Cauldron Sell:** replace the plain SELL with the Cauldron. Cauldron D 10, #2D1F43. Goo disc Neon #78E580. Green PointLight Range 14. Bubble ParticleEmitter Rate 6.
- **Leaderboard:** fill the blank navy slab on the right wall with a SurfaceGui, or delete it.

---

## 3. Recapture checklist
Do not call this done until a spawn-camera capture shows all of the following:
- the King's lit face filling at least 15% of frame height
- warm low sun, with a lilac horizon
- no stud texture on the grass
- no sawtooth in the paving
- every 1/3 of the foreground holding at least one lit object
