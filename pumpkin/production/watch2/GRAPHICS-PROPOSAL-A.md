# Graphics proposal A: back to Steal an Egg studs, in our Halloween palette

Angle: stay close to Steal an Egg (SaE). That means bright flat daylight, a studded plastic floor with a two-tone checker, one plain wall style with a neon top line, and an open field. Halloween comes from colour (orange, purple, lime, bone) and the props, not from lighting.

Owner: "these graphics are a little too much, I thought we were sticking to steal an egg style with the stud block".

## 1. What went wrong (hub screenshot r91bz9 vs SaE refs)

| Ours now (LaunchLook 1-3) | SaE (ui/v2/01-sae-hud-clean, BIBLE-STEAL-AN-EGG section 7) |
|---|---|
| Grass material floor, textured, dull green | Lime Plastic **stud** floor, 8-stud low-contrast checker |
| Golden hour (ClockTime 17.2), peach ColorShift, lilac atmosphere with Haze 2 makes a pink-orange horizon | Midday, cyan sky #33BEF7, white clouds, no colour cast |
| Bloom 0.8 / size 28, SunRays, about 60 neon lantern cubes, 5 string-light runs, neon glow pool | Bloom only on a few neon parts |
| A huge white moon disc (160-stud Neon cylinder) in the sky | No sky props |
| Lavender paths, ring, curbs, 6 spokes, 20 path lanterns, beds, gravestones, trees | Open stud field; pens and giant landmarks are the only clutter |
| Dark purple smooth walls with wall glows | Terracotta stud checker walls with a 1-stud neon-lime cap |

## 2. LaunchLook4.luau: scene script

Run in Studio EDIT mode, after LaunchLook 1-3, and do not re-run 1-3 afterwards (LaunchLook3 asserts folders that v4 deletes).

Rules:
- Start with `assert(not RunService:IsRunning())`.
- **Idempotent:** use FindFirstChild before every destroy, set absolute values only (never relative), and keep owned output under `Garden.Art.LaunchLook4` (destroy it and rebuild it on each run).
- Yield every 80 descendants.
- Never touch contract instances: Market.*, Patches.*, Zones.* (Spawn, GateWall), SpawnLocation, prompts, `KingStatueVisibility`, or the legacy GiantJack/KingFace/KingGlow (recolour only).

### 2.1 Lighting (set the property AND `Lighting:SetAttribute("Base"..key, value)`)

| Key | Value | Why |
|---|---|---|
| ClockTime | 14 | High sun, short soft shadows |
| GeographicLatitude | 25 | |
| Brightness | 3 | |
| ExposureCompensation | 0 | |
| Ambient | #7F7F86 | Near-neutral, faint cool tone |
| OutdoorAmbient | #8C8C94 | No purple cast |
| ColorShift_Top | #000000 | No shift (remove the peach #FFB86B) |
| ColorShift_Bottom | #000000 | Remove the purple #6B4E8C |
| GlobalShadows | true | |
| ShadowSoftness | 0.25 | |
| EnvironmentDiffuseScale | 1 | |
| EnvironmentSpecularScale | 0 | Plastic should not shine |

### 2.2 Post effects

- Destroy every ColorCorrectionEffect, BloomEffect, SunRaysEffect, BlurEffect, DepthOfFieldEffect and Atmosphere under Lighting. Then create:
  - **One ColorCorrectionEffect named `PhaseTint`**:
    - Brightness 0, Contrast 0.05, Saturation 0.15, TintColor #FFFFFF.
    - Write `BaseGrade<Key>` on Lighting for all four keys, plus `Base<Key>` on the effect itself.
    - Do not write `BaseBrightness` from the grade; it means sun brightness.
  - **One BloomEffect `NeonBloom`**:
    - Intensity 0.5, Size 16, Threshold 1.2. Lit plastic stays under the threshold, so only Neon glows.
    - Write attributes `BaseBloomIntensity`, `BaseBloomSize` and `BaseBloomThreshold`.
  - **SunRays: none.** Clear the attributes: `SetAttribute("BaseSunRaysIntensity", nil)` and `SetAttribute("BaseSunRaysSpread", nil)`.
  - **One Atmosphere, kept only so the client's event tweens have a target.** It should be nearly invisible:
    - Density 0.2, Offset 0, Color #C8ECFF, Decay #6CC4F5, Glare 0, Haze 0.
    - Gives a slight blue fade at the far lane end, like SaE's "slight haze at corridor end only".
    - Write `BaseAtmosphere<Key>` for all six keys.

### 2.3 Sky

- Keep the existing Sky object and its asset IDs. Set:
  - SunAngularSize 11
  - MoonAngularSize 11
  - CelestialBodiesShown true
  - StarCount 0
- Write `BaseSunAngularSize = 11` and `BaseCelestialBodiesShown = true`.
- If the sky still reads grey or orange in capture, set its 6 Skybox* properties to Roblox's default bright sky: `rbxasset://textures/sky/sky512_*.tex` (built in, no upload).
- **Clouds:** `workspace.Terrain` gets one `Clouds` instance (create it if missing): Cover 0.55, Density 0.6, Color #FFFFFF. This is free, built-in and engine-rendered.

### 2.4 Floors: Plastic + studs + 8-stud low-contrast checker

**For every repainted floor part:**
- Material = `Plastic`
- TopSurface = `Studs`, BottomSurface = `Inlet`. Legacy surfaces render on Plastic; v1 already did this, and the stud pad in r91bz9 proves it renders.
- Destroy child Texture/Decal instances.

**Checker parity:**
- parity = `(floor((X-1330)/8) + floor((Z+80)/8)) % 2`, taken from the part centre.
- First measure the Ground tile size and log it. If tiles are 16 studs, use /16 (16-stud checker is acceptable). **Do not split parts.**

**Fallback, only if studs are invisible at 30-stud camera distance in screen_capture:**
- Add a top-face `Texture` using a free stud texture: `search_asset`, decal only, no scripts.
- Settings: StudsPerTileU/V 4, Transparency 0.75.

**Floor colours (A / B, about 5% luminance apart; deeper zones darker, as in SaE):**

| Area | A | B | Notes |
|---|---|---|---|
| Hub (X 1320-1680, Z -80 to 150) | #63C93C | #5BBE37 | Lime pumpkin-patch field (replaces the Grass material). Hub corners lose the #9CC544 gold patch |
| Z1 Pumpkin Meadow | #8FD43E | #86C938 | Yellow-lime |
| Z2 Graveyard | #B4B9C4 | #ABB0BB | Bone-grey stone |
| Z3 Haunted Woods | #4F9A3B | #489036 | Deep green |
| Z4 Witch Swamp | #7A5CA6 | #72559D | Purple bog |
| Z5 Vampire Castle | #4C4458 | #453E50 | Dark slate (SaE "Volcano" slot); red trim on gate |
| Z6 Candy Kingdom | #FF9FD0 | #F595C6 | Pink |
| Z7 King's Throne | #F29A38 | #E8902F | Harvest orange |

**Zone membership:**
- Same `zoneAt(z)` as v1: Spawn footprints, with a fallback of zMin/zMax from PatchConfig (150 + 160 per zone).
- Paint both Ground parts and zone `Spawn` parts.

**Pens and stations:**
- Pen Soil stays Ground #7A4E33; it is gameplay readability, unchanged.
- Pen rails: Plastic #E2621B (SaE orange-red rail).
- Pen posts: #3A2340, Plastic, TopSurface Studs.
- Station pads (SHOP/SELL/UPGRADES): material Neon -> **Plastic**, Transparency 0, same colours. They become solid coloured studded discs, like SaE's ring pads, with no bloom blob.

### 2.5 Walls: one style everywhere

**Slabs (all `Walls` slabs and bricks in hub and lane):**
- Plastic, Front/Back/Left/Right/Top surfaces = Studs.
- Two-band colour: lower #6B4AA3, upper #634498. A bright purple low-contrast pair, the Halloween stand-in for SaE terracotta.
- Lane walls get the same treatment; per-zone wall colour is dropped, so zone identity is the floor (as SaE).

**Neon cap (in LaunchLook4):**
- For each wall segment, one `WallCap` Neon strip, 1 stud tall, the wall's full length, colour **#FF8C1A**, sitting on the wall top.
- This is the only big neon line in the scene, the SaE lime-cap equivalent.
- Repaint existing `Cap` parts to #FF8C1A Neon instead of adding new ones where they exist.

**Gates:** GateWall keeps its zone accent colour in Plastic.

### 2.6 Keep / remove

**KEEP:**
- ThroneKing statue (v1) and `KingStatueVisibility` (v3).
- Throne Step1-3 and Trim1-3, recoloured:
  - Steps: Plastic + Studs, #8F8DC0 / #A3A3D1 / #B8BADD
  - Trims: #FF8C1A Plastic
- Station SHOP/SELL/UPGRADES titles and models.
- SellCauldron. Its CauldronGoo stays Neon; it is the one sell landmark glow, and its PointLight stays.
- HauntedGate, at the lane mouth, as a landmark. Windows switch Neon -> Plastic #FFB347.
- v1 WallProps corner clusters (6 pumpkin+hay groups): low, chunky, on-theme.
- All contract PointLights.

**REMOVE (destroy whole folders if present):**
- v1 `WallLanterns` (30 neon cubes + lights)
- v1 `StringLights`
- v2 `StringLights`, `PathLanterns`, `WallDetails`, `CleanPaths` (ring, inner lawn, spokes, curbs, destination pads)
- v2 `PumpkinBeds`, and the hub-interior gravestones/trees that v2 placed (inside the hub rectangle only)
- `DaytimeMoon`
- v3 `GlowPool`, and the `KingWarmLight` PointLight

**TONE DOWN:**
- Any remaining owned Neon (v1/v2/v3 folders) that is not the cauldron goo, wall cap, MeterRing or King face: set it to Plastic, same colour.
- The `Plaza` stays flat #A9ABD3 Plastic + Studs, as the dais base only.

**Budgets and report:**
- Assert PointLights <= 40 and part delta < +300; v4 should be strongly negative.
- Print a report: parts before/after, lights, folders removed, and the measured floor tile size.

## 3. Client day/night code (Patch.client.luau, "Lighting by phase", about lines 3446-3570)

Today the client snapshots Lighting **properties** (it reads no `Base*` attribute; grep confirms only BaseSize/BaseHold are read). That part is fine, because the edit-time values become the base. The problem is that the **no-event reset tweens PhaseTint to neutral** (TintColor 1,1,1; Saturation 0; Contrast 0). That wipes the +0.15 saturation every Day.

Required changes:
1. **Build `base` from attributes, falling back to properties.**
   - `ClockTime`, `Brightness`, `Ambient` and `OutdoorAmbient` come from `Lighting:GetAttribute("Base"..k) or Lighting[k]`.
   - The atmosphere values come from `BaseAtmosphereColor`, `BaseAtmosphereDecay` and `BaseAtmosphereDensity`.
   - Add `tint = { TintColor, Brightness, Saturation, Contrast }` from `BaseGrade*`, with defaults #FFFFFF / 0 / 0.15 / 0.05.
2. **The reset branch tweens PhaseTint to `base.tint`**, not to neutral.
3. **Purge tint becomes relative:** Saturation `base.tint.Saturation`, Contrast `base.tint.Contrast`, TintColor #FFF0FC, Brightness 0.02. Purge is a light pink wash. Spooky and BloodMoon stay as they are; they are timed events, and SaE recolours the map for events too.
4. **Set ColorShift_Top/Bottom to #000000 in the reset tween too**, so an event can never leave a cast behind.
5. If Atmosphere is missing at startup, create one with the base values, so event tweens always have a target.

Out of scope, noted: Patch.server's GiantJack reset re-shows the legacy King parts. It is not a lighting issue.

## 4. Acceptance (screen_capture from spawn, same camera as r91bz9)

- Sky reads cyan-blue with white clouds, with no orange or pink horizon band.
- Studs are visible on the floor within 40 studs of the camera. The checker is barely visible, low contrast.
- Glow is only on the wall cap line, the cauldron goo and the King. No yellow dots line the wall tops.
- No moon disc, string lights or path lantern posts.
- A blind side-by-side with ui/v2/01-sae-hud-clean reads as "same family, Halloween colours".
