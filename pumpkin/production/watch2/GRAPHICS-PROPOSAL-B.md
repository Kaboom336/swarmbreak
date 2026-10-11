# GRAPHICS PROPOSAL B: "Stud Patch" (stud-block base + 4 Halloween keepers)

Proposer B, arena round 2. Plan for a new idempotent Edit-mode script `giant/scene/LaunchLook4.luau`, plus two small client changes.

## 0. Diagnosis (what "a little too much" is)

Evidence: our hub capture (`...-1791688884537-r91bz9.jpg`), our pen capture (`...-1791692064542-8ykgyr.jpg`), SAE `h_0018`, `h_1460`, GaG `f_062s`, and PS99 `f_012s`.

| Ours now | SAE / GaG / PS99 | Verdict |
|---|---|---|
| Golden hour (ClockTime 17.2), orange ColorShift_Top, purple ColorShift_Bottom, PhaseTint warm grade | High noon look: flat white sun, no grade, cyan sky | Cut. It makes the floor muddy and the shadows purple. |
| Atmosphere Density 0.34, Haze 2.0, Glare 0.4 (lilac fog) | A thin pale horizon haze only | Cut to a thin sky-blue haze. |
| Bloom 0.8 / 28 / 0.95, SunRays 0.06. Every neon cube becomes a glow blob | No visible bloom (SAE), only soft neon edges (PS99) | Very mild bloom. Remove sun rays. |
| Grass material (dark, noisy, reads olive). Ground material on soil | Flat bright Plastic with stud tops and a 2-tone checker | Cut Grass. Use stud Plastic everywhere you walk. |
| 160-stud lilac Neon "DaytimeMoon" | None (SAE night only darkens the sky) | Cut. |
| 5 string-light spans, 30+ neon wall-cap cubes, GlowPool, 20 lanterns | Few props, big and readable | Cut the strings, wall cubes and GlowPool. Lanterns go 20 to 8. |
| Dark aubergine/slate walls 453E69 and 4E4775 fill the top third of every frame | Mid-tone terracotta checker walls with a bright neon cap line | Lighten the walls, add a stud checker and a neon cap. |

What makes it ours and premium (keep): the voxel Pumpkin King on its dais, the orange pumpkin + hay beds, warm lanterns lining the paths, and the "PUMPKIN PATCH" gate arch. On a SAE-bright base these 4 carry the Halloween identity. Everything else goes.

## 1. Lighting (absolute values; write each as a property AND as a `Base<Key>` attribute on Lighting)

| Property | Value | Was |
|---|---|---|
| Technology | ShadowMap (set from the command bar; skip silently if it errors) | (Future?) |
| ClockTime | 14.0 | 17.2 |
| GeographicLatitude | 25 | 35 |
| Brightness | 2.8 | 2.4 |
| ExposureCompensation | 0.15 | 0 |
| Ambient | #7E8494 | #8C7AA8 |
| OutdoorAmbient | #A4AAB8 | #9D8DBF |
| ColorShift_Top | #FFF4E2 | #FFB86B |
| ColorShift_Bottom | #000000 | #6B4E8C |
| GlobalShadows | true | true |
| ShadowSoftness | 0.4 (softer, toy-like) | 0.2 |
| EnvironmentDiffuseScale | 0.55 | 0.4 |
| EnvironmentSpecularScale | 0.15 | 0.3 |

**PhaseTint (ColorCorrectionEffect, keep the instance and the name):** TintColor #FFFFFF, Brightness 0.02, Contrast 0.06, Saturation 0.10. Also write `BaseTintColor`, `BaseGradeBrightness`, `BaseContrast` and `BaseSaturation` (the client reads these, see section 6).

**Atmosphere (keep the instance so events can still tint it):** Density 0.22, Offset 0.0, Color #CFE6FF, Decay #9CC2EE, Glare 0, Haze 0.4.

**Bloom (`HarvestBloom`, keep the name):** Intensity 0.25, Size 12, Threshold 1.6. Neon still gets a thin halo but no blobs.

**SunRays (`HarvestSun`):** destroy it.

**Sky:** keep the existing cartoon Sky asset IDs. SunAngularSize 11, MoonAngularSize 6, CelestialBodiesShown true, StarCount 0. Write the matching `Base*` attributes.

**Blood Moon / Spooky:** these stay events. The client handles them (section 6). Do not bake them into the scene.

## 2. Materials (global rules for owned + map art)

- **Walkable floors** (hub Ground tiles, zone Ground, pen Soil, CleanPaths Ring/Spoke/DestinationPad/StationApron, Market.Plaza, dais Steps): `Enum.Material.Plastic`, `TopSurface = Studs`, BottomSurface Smooth. Studs only render on Plastic, so never SmoothPlastic or Grass here. Remove any Texture or Decal children.
- **Walls** (`Walls` Brick/Slab, LaunchWall*, buttresses, gate towers): Plastic, with `Front/Back/Left/RightSurface = Studs` on the slabs (SAE stud walls). Caps get a separate material (see below).
- **Wall cap line:** Neon, 1 stud tall (the SAE neon-top cue). With bloom threshold 1.6 this reads as a crisp line.
- **Props** (fences, lantern frames, posts, hay, pumpkins, King): Plastic or SmoothPlastic. Fabric for hay only. No Metal except the King's crown (y). Neon is allowed only on the 8 lantern cores, the King's face voxels (f), the wall cap line, and existing gameplay markers (pads, safe line, arrows; do not touch these).
- **Banned in owned art:** Grass, Ground, Brick, Wood, Slate, Cobblestone (all of them add noise and darken at distance). Fence Wood becomes Plastic in the same hex.
- **Fallback if Studs fail to render** (check in the capture): add one `Texture` per floor part using a free, script-free stud texture (search_asset, image only), StudsPerTileU/V = 4 and Transparency 0.6. Never import a model.

## 3. Per-zone hex (checker A / B = alternate 8x8-stud tiles by position parity, as LaunchLook v1 does)

Lightness steps are kept small (about 5%) so the checker reads like SAE and not like a chessboard.

| Zone | Floor A | Floor B | Wall lower / upper | Cap (Neon) | Gate wall (zone `GateWall`) |
|---|---|---|---|---|---|
| Hub (X 1320-1680, Z -80..150) | #8EE03C | #82D236 | #8A6CC8 / #9579D2 (light Halloween purple, stud) | #FF9A2E | n/a |
| Hub paths (Ring, Spoke, Pads, Apron, Plaza) | #E9DCC4 (warm cream) | | Curb / RingEdge #FFFFFF | | |
| Pen soil (Patches.Soil) | #9A6A44 | | Rail/Brace #8E4312, Post/Pole/Board #40303A (SAE plot colours) | | |
| Zone1 Meadow | #A8E04A | #9DD443 | #C9783E / #D4864A (terracotta) | #9BFF4A | #8E4312 |
| Zone2 Graveyard | #BFC3DE | #B3B7D4 | #6B6F94 / #777BA0 | #E8E4FF | #4E5278 |
| Zone3 Haunted Woods | #5FC24A | #56B443 | #6E4A32 / #7A5538 | #9BFF4A | #4A3022 |
| Zone4 Witch Swamp | #6FBFA0 | #64B294 | #5E3F94 / #6A4AA0 | #9BFF4A | #3F2A66 |
| Zone5 Castle | #C9CBE6 | #BCBEDC | #4F5D96 / #5B69A2 | #FFFFFF | #3A4578 |
| Zone6 Candy | #F7C8E8 | #EDBADC | #B57BD6 / #C08AE0 | #FFFFFF | #8E52B8 |
| Zone7 King | #F7A63C | #EC9832 | #3E2C5C / #4A3668 | #FFB347 | #2D1F43 |

The Zone `Spawn` parts take Floor A of their zone (as v1 does). Never change the safe line, pads, prompts or `Market` contract geometry; only change their Color and Material if v1/v2 already did.

## 4. Keep / cut list (scene-owned art only)

### KEEP (the 4 identity elements, toned down)
1. **Pumpkin King statue + dais** (`LaunchLook.ThroneKing`, `LaunchLook2.Throne` Step1-3/Trim1-3, `ThroneDetails.KingTitle`, `LaunchLook3.KingBackRib`, the `KingStatueVisibility` script).
   - Steps become Plastic studs: #B8A6E6 / #C6B6EE / #D4C8F4 (lighter lavender). Trims are #FFFFFF Plastic.
   - The King's face voxels (f) stay Neon #FFB347; everything else follows the LaunchLook3 palette. Do not rescale (it stays 1.4).
   - Cut: `GlowPool` (hide), `KingHeadGlow` + `KingWarmLight` (destroy the light).
2. **Pumpkin beds** (`LaunchLook2.PumpkinBeds`, the LaunchLook3 pumpkins/ribs/stems/hay).
   - Bed Soil becomes Plastic studs #9A6A44. Hide every bed `Furrow` (noise).
   - Pumpkins stay #F28C1A, ribs #D35208 SmoothPlastic, hay #E3B04B Fabric, HayBand and StrawTuft unchanged.
3. **Path lanterns, 20 cut to 8.** Keep only the row-1 pair on spokes 1-4 (the cores nearest each spoke start). Hide the other 12 whole fixtures (Post, Arm, Frame, Core, LanternCapBase within 5 studs of the core).
   - Kept cores: Neon #FFB347. Each kept PointLight: Brightness 1, Range 12, Shadows false.
   - Frames and posts: #2D1F43 Plastic.
4. **Haunted gate arch** (`LaunchLook2.HauntedGate`).
   - Towers become Plastic studs #8A6CC8, spires #FF9A2E, ArchBeam #2D1F43, banner #F28C1A (keep the "PUMPKIN PATCH" text).
   - Windows go from Neon #FDF301 to SmoothPlastic #FFD36B (no glow blobs by day).

### CUT (hide parts: Transparency 1, CanCollide/CanQuery/CastShadow false; disable or destroy owned lights)
- `LaunchLook2.DaytimeMoon` (hide).
- `LaunchLook2.StringLights`: every post, wire and bulb (hide the whole folder).
- `LaunchLook2.WallDetails`: hide `WallGlow` and `Bracket` and destroy their PointLights.
  - Keep `Buttress` (recolour to wall lower hex), `CapTrim` (#FFFFFF), and the small cap pumpkins (#F28C1A). They give the skyline its Halloween bumps without any light.
- LaunchLook v1 wall lanterns (the "thirty wall lanterns" fixtures, plus any v1 Neon cubes on the walls): hide them and set their PointLights `Enabled = false`. Do not destroy anything under `Walls` or `Market`.
- `LaunchLook.PenFurrows` (hide).
- `CleanPaths.InnerLawn`: change from Grass to Plastic studs #8EE03C (hub Floor A). Do not hide it, the dais needs a lawn.
- The hub Grass floor from LaunchLook2 section 3 becomes the stud checker from section 3 above. Drop the `9CC544` corner tone.
- Sun rays (destroy). PhaseTint warm tint (replaced by the neutral grade).
- All Neon on owned art except the allow-list in section 2 becomes SmoothPlastic of the same hex. This undoes the LaunchLook3 "warm all neon yellows" pass outside the allow-list.

Expected result: about -350 visible parts (the decorative count drops), and Garden PointLights go down to about 8 owned plus the protected game lights, well below the 40 cap.

## 5. LaunchLook4.luau structure (idempotent rules)

1. `assert(not RunService:IsRunning())`. Assert that LaunchLook, LaunchLook2 and LaunchLook3 exist under `Garden.Art`. Never assert on optional decor, use `FindFirstChild` and skip when missing.
2. Create `Garden.Art.LaunchLook4` (a Folder) for any new parts. A rerun destroys and rebuilds only this folder. The script should need almost no new parts: the cap line can reuse the existing v1 `Cap` parts (recolour + Neon); only build new caps where none exist.
3. **Record originals once:** before the first change to any instance, save `L4OrigColor`, `L4OrigMaterial` and `L4OrigTransparency` attributes on it, and only if they are absent. All writes are absolute values (never `*=` or `+=`), so a rerun gives the same result and a revert script can restore everything.
4. Section order: Lighting, then floors, walls, keepers, cuts, then a light audit.
   - Use `task.wait()` every 80 instances (the same `chunk` helper as LL3).
5. Write the `Base*` attributes for every Lighting, PhaseTint, Atmosphere, Bloom and Sky value in section 1.
6. Final print: parts visible before/after, PointLights before/after, how many floor parts got studded, kept lantern count (must be 8), and whether Studs rendered (a manual check flag).
7. No network, no asset insertion, no scripts created (the LL3 `KingStatueVisibility` script stays as is).

## 6. Required client day/night changes (Patch.client.luau, "Lighting by phase" ~L3445-3575)

The current client snapshots Lighting at start (fine), but on return to normal it resets PhaseTint to neutral (TintColor white, 0/0/0) and never restores Bloom or Haze. Codex makes these changes:

1. **Snapshot the grade too.** In `base`, add `TintColor`, `TintBrightness`, `TintSaturation` and `TintContrast` read from `correction` at start, falling back to `Lighting:GetAttribute("BaseTintColor")` and similar when it was just created. Add `ColorShift_Top`, `ExposureCompensation`, and `AtmosphereHaze` / `AtmosphereGlare`.
2. **Restore, don't neutralise.** In the `else` branch of `setLighting`, tween PhaseTint to the `base.Tint*` values instead of `Color3.new(1,1,1)`/0/0/0. Also tween `ColorShift_Top` and `ExposureCompensation` back to base, and the Atmosphere `Haze` and `Glare` back to base.
3. **Spooky Hour, lighter touch** (fits "not too much"): ambient lerp 0.35 to 0.25, TintColor #FFE2C2, Saturation 0.18, Contrast 0.06. Atmosphere Color #F2B07A, Decay #8A64C8, **Density = base (0.22) and Haze = base**, so the event tints the sky but does not fog the lane.
4. **Purge:** unchanged (already subtle).
5. **Blood Moon:** keep `Config.KingNight.look` (ClockTime 17, red-violet). On the transition into it, also set Bloom Intensity to 0.4 (lanterns and the King's face glow at dusk). Restore to `base.BloomIntensity` (0.25) on exit. This is the only time the scene is allowed to look "lit up".
6. **No real night and no day cycle.** The SAE-style night (dark sky, lit ground) is not worth it now, so ClockTime stays 14 outside Blood Moon.

## 7. Acceptance check (capture vs refs)

- Hub from spawn, same camera as `r91bz9`: floor reads bright lime with visible studs, no fog band before the far wall, the King is the clear focal point, and no white or yellow glow blobs. Compare with SAE `h_0018`.
- Pen close-up, same camera as `8ykgyr`: brown stud soil with SAE plum/brown fence colours on a lime stud floor, and a cyan sky (no purple).
- Blind judge question: "Which looks more like a top Roblox simulator: ours, SAE h_0018 or GaG f_062s?" Pass if ours is not picked as the odd one out for lighting or material. Halloween identity check: a viewer names "Halloween / pumpkin" within 3 s.
- Phone (Studio device emulator, 375 wide): the checker and studs must not moire. If they do, raise the tile size from 8 to 16 studs.
