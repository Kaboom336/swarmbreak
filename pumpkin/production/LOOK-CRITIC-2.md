# LOOK CRITIC 2: hub after the LaunchLook2 pass (blind, hostile)

## Evidence judged
| Tag | File (`tool-results\mcp-Roblox_Studio-blob-…`) | What it shows |
|---|---|---|
| NEW-A | `1791688246251-niset6.jpg` | Overview |
| NEW-B | `1791688255400-zn9ewr.jpg` | Player height near the King |
| PLAY | `1791688157063-qwineq.jpg` | Spawn view in Play mode |
| PREV | `1791687505032-xcfr3i.jpg` | Round 1 overview |

I also inspected the scene **read-only** in Studio. Nothing was edited.

The bar:
- AUDIT-LOBBY-MAP.md §4, "Pumpkin Patch at Golden Hour"
- refs: lobby, map, ui/v2

Offsets below are (dX, Y, dZ) from the hub centre (1500, 0, 40).

### Correction to Critic 1
- `Garden.SpawnLocation` is at **(0, 0.3, +90)**, the lane/gate side, not −Z.
- The King's face points **+Z, toward spawn**.
- So NEW-A and NEW-B were both shot from **−Z, behind the King**. They show his back.
- The back still matters: it is what every player sees while walking from the pens toward the lane. Both sides must look finished.

---

## 1. Verdict

**Overall: 4.5 / 10** (round 1: 3.5). **Centrepiece: 2 / 10, worse than before.**

Would a kid still call it cheap? **Yes, and now also "broken".**

### What improved
The field reads as a place now:
- Grass is smooth two-tone, no more studs.
- The paving ring is clean.
- Lantern rows, string lights, the gate towers with spires, striped stalls and stall titles are all in.

### What is broken
The hero is two Kings and a moon fused together. In the scene there are:
1. **Legacy voxel King:** `Garden.Art.LaunchLook.ThroneKing`. About 230 voxels, bounding box 26 x 33 x 19, spanning Y 4.5 to 37.
2. **New head kit:** `Garden.Art.LaunchLook2.ThroneDetails`. Its pieces:
   - `HeadBack`: a Ball 26 x 22 x 17. Roblox draws a Ball at its **smallest** axis, so it renders as a **17-stud sphere**. That is the "yellow sphere".
   - An open box frame: HeadTop, HeadBottom and 2 HeadSide pieces.
   - `FaceInterior` and the face: a flat 0.2-thick panel on the +Z face.
   - Ribs floating 0.6 behind the sphere.
   - Belt and Cape, which clip into the voxel body.
3. **Moon:** `LaunchLook2.DaytimeMoon`. A Neon disc 160 wide at (0, 120, +420). From the −Z camera it sits exactly behind the head. It is the "white disc / halo" in the screenshots.

What the screenshots show:
- **From behind:** an orange lantern cage around a sphere, with a dark panel showing through, voxel orange poking out underneath, and green voxel leaves stuck on the side.
- **At player height (NEW-B):** it reads as a broken sign. The single yellow triangle eye is the only face cue.
- **Title:** the crown tips cut through the "PUMPKIN KING" title.

The ironic part: the PLAY frame shows the **legacy voxel King alone** on the old dais. Its lit face reads cleanly from spawn. It was the better hero, and the new kit buried it.

### Runtime landmine
`ServerScriptService.Patch` line 7127, in `endBloodMoon`, does this:

```lua
giantJack.Transparency = 0
giantJack.CanCollide = true
```

So after the first Blood Moon, the legacy `Market.GiantJack` mesh appears **inside** the throne and is solid:
- Size 20 x 14 x 20, at (0, 11, 0).
- It carries a PointLight.

`Market.KingFace` also turns visible at the same spot during the Blood Moon. Either part means a third King clipping into the art.

### Scores
| Axis | R1 | R2 | Refs TE / SAE | Why |
|---|---|---|---|---|
| Premium feel | 3.5 | 4.5 | 8 / 6 | Real props now. But primitives are all the same scale and the hero is visibly broken. |
| Palette harmony | 5 | 6 | 8 / 7 | Lilac paving, aubergine posts and orange work together. Two things fight it: #FFFF00-ish lamp cores and the white moon blowout. |
| Centrepiece | 3 | **2** | 8 / 7 | Two models plus a halo disc are overlapping. No readable silhouette from the back, no clean face from the side. |
| Prop density | 2 | 6 | 8 / 4 | Good near the throne. The pumpkins read as **oranges** (smooth balls with leaves), and the hay reads as cardboard boxes. |
| Lighting mood | 3 | 3.5 | 7 / 6 | The Lighting values match §4, but the frame still reads noon: cyan skybox, high sun, short shadows. PLAY is cold noon. |
| Readability | 5 | 6 | 9 / 7 | Gate, stall titles and the axis path work. Posts and string-light poles screen the King from the path. |

---

## 2. The 8 most impactful fixes

### 1. One King only: keep the voxel King and strip the new head kit
- **Hide** these parts: set Transparency 1, CanCollide false and CastShadow false, or move them to ServerStorage.
  - `LaunchLook2.ThroneDetails`: HeadBack, HeadTop, HeadBottom, HeadSide (x2), HeadNose, FaceInterior, TriangleEye (x2), ZigzagMouth (x7), PumpkinRib (x5), Belt, Cape (x2), CrownBand, CrownTip (x5).
  - Keep only `KingTitle`.
- **Scale and seat the King:**
  - `ThroneKing:ScaleTo(1.4)`. The bounding box becomes about 36 x 46 x 27.
  - Re-pivot so the bounding-box bottom sits at Y 4.65 on Step3, centred (0, —, 0).
  - Keep the face toward +Z / spawn: `CFrame.lookAt(pos, Vector3.new(1500, pos.Y, 130))`.
- **Face glow:**
  - Set the 19 `f` voxels (#FFB21A) to Material Neon, Color #FFB347.
  - Set the 3 `k` voxels (#141414) to #2D1F43.
  - Add a PointLight in the head centre, about (0, 38, +4) after scaling: Color #FF9A3C, Brightness 2.5, Range 34, Shadows false.
- **Fix the back:** the back must not be a flat orange slab. Add 4 vertical rib strips (#D35208, 1 x 18 x 0.6) on the head's −Z face, flush (no gap), at dX −9, −3, +3, +9.
- **Alternative:** if you insist on the new kit instead, delete ThroneKing completely, and replace HeadBack with a **Part Block + SpecialMesh Sphere** of Scale (26, 22, 20), not a Ball. It must also close the frame so nothing shows through.

### 2. Stop the legacy parts reappearing (`ServerScriptService.Patch`)
- **Line 7127:** change `giantJack.Transparency = 0` to `1`.
- **Line 7128:** change `giantJack.CanCollide = true` to `false`.
  - Or delete `Market.GiantJack` visually and keep it only as an anchor.
- **Blood Moon (line 7449, where KingFace becomes visible):**
  - Hide ThroneKing at the same moment: set LocalTransparencyModifier 1 on the client, or reparent to ServerStorage on the server.
  - Restore ThroneKing in `endBloodMoon`.
  - That way the boss replaces the statue instead of overlapping it.
- **`Market.SignJack`:** BillboardGui at (0, 22, 0). Disable it if it shows any text. It sits inside the King.

### 3. Move the moon off the King's axis
`DaytimeMoon` currently sits at (0, 120, +420). From spawn it is behind the camera, and from the hub interior it haloes the head.
- **Move it** to **(−170, 150, −430)**, which is world (1330, 150, −390).
- **Size:** 0.2 x 130 x 130 Cylinder.
- **Facing:** `CFrame.lookAt(moonPos, Vector3.new(1500, 10, 130)) * CFrame.Angles(0, math.rad(90), 0)`, so the disc faces spawn.
- **Colour and material:** #D9C8F0, Neon, Transparency **0.45**. At 0.2 the Neon blows out to pure white under Bloom threshold 0.95.
- **Result:** from spawn it sits upper-left of the King, and never directly behind the head.

### 4. Title and crown clearance
- Put `KingTitle` at Y = King bounding-box top + 9, which is about **Y 60** after the 1.4 scale.
- BillboardGui size 34 x 8 studs. LightInfluence 0, MaxDistance 400.
- Nothing may cross the text: crown tips must end at least 4 studs below the label's bottom edge.

### 5. Actually look like golden hour, not noon
The values are set, but the cartoon skybox and high sun keep the frame cyan. Change these:

| Setting | Value |
|---|---|
| ClockTime | **17.2** (low sun, long shadows) |
| GeographicLatitude | 35 |
| ColorShift_Top | **#FFB86B** |
| Atmosphere | Density **0.34**, Offset 0.1, Color **#F4C9A8**, Decay **#9A6FC4**, Glare **0.4**, Haze **2.0** |
| PhaseTint (ColorCorrection) | TintColor **#FFE6CC**, Saturation 0.12 |
| Sky | SunAngularSize 18, CelestialBodiesShown true |

- **Verify in Play.** The PLAY frame is cold. Check that the PhaseTint client logic (Patch.client ~3066–3170) reads these base values and does not reset them.

### 6. Lights that glow warm, not lemon
- **Lamp-post cores:** #FFB347 Neon, size 1.8 x 2.4 x 1.8. They are currently flat #FFFF00-ish blocks.
  - Add a cap and base, each 2.8 x 0.4 x 2.8, #2D1F43, so they read as lanterns.
- **String bulbs:**
  - Diameter **0.7** (currently about 1.0, and they read as tennis balls in NEW-B).
  - Neon, alternating **#FFB347 / #FF8A3D / #C79BFF**. The purple matches the lane lights in PLAY.
  - Spacing 3, sag 3.
- **Clear the sightline:** move the string-light and lamp posts nearest the throne out to radius **≥ 46**, outside the ring edge at 43. That way nothing taller than 2 studs sits between the spawn path and the King inside radius 46.

### 7. Pumpkins that are pumpkins, hay that is hay
- **Pumpkins:** the patch "pumpkins" are smooth Balls with leaf wedges, and from spawn they read as **oranges**.
  - Replace them with the KitSource pumpkin models at 1.5–2.5x.
  - Or, if they stay primitives: a Block with SpecialMesh Sphere Scale (1, 0.72, 1) x size, #F28C1A, plus 6 vertical rib strips #D35208 (0.4 wide), plus a stem cylinder 0.8 x 1.6, #4E7A2A.
  - Ground them: centre Y = 0.36 x height.
- **Hay bales:**
  - Lay them flat at 5 x 3 x 3, Fabric #E3B04B.
  - Two bands 0.4 wide, #9C6B22, wrapping all 4 long faces.
  - Remove the "crate lid" seams.
  - Add 2 straw tufts per bale: wedges 1 x 0.6 x 0.6, #E8C36A.
  - As built, they read as cardboard boxes.

### 8. Give the dais contrast and size it to the King
- **Steps** (after the King scale):

| Step | Diameter | Colour |
|---|---|---|
| Step1 | 52 | **#8F8DC0** |
| Step2 | 44 | **#A3A3D1** |
| Step3 | 36 | #B8BADD |

  - Each step 1.5 tall. Trims stay #E8E4D0, 0.5 wider.
- **GlowPool:** diameter 34, Transparency **0.6**, #FFB347. It currently blooms into a flat yellow pancake.
- **Bale ring:** move it out to radius **30**. Bales sit on Step1's outer lip at Y 1.5, not on the lawn.

---

## 3. Recapture rules (round 3)

### Required shots, all in **Play mode**
1. The spawn camera at (0, 6, +90) looking at the King.
2. The reverse view from (0, 6, −90).
3. The same shot after a forced Blood Moon end, which proves fix 2.

### Pass criteria
- **Spawn shot:**
  - The King's lit face is at least 15% of frame height.
  - Exactly one King silhouette.
  - Nothing round or white behind the head.
- **Reverse shot:** a finished back. No see-through frame.
- **All shots:**
  - No lemon-yellow #FFFF00 anywhere.
  - Shadows longer than the objects that cast them, which proves the low sun.
  - No prop a kid could call an orange or a cardboard box.
