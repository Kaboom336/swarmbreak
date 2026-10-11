# SCYTHE PROPOSAL A: Models (7 blocky tiers that escalate)

Proposer A, arena round 2. Scope: the scythe models, plus the grip and the model-side hooks the swing uses (trail and glow). No game code was edited. Codex implements this in `buildScythe` (Patch.server.luau ~6984).

## 1. What is wrong now (from the code and the swing screenshot)

- **Built from thin metal, not blocks.** The shaft is 0.32 x 5.4 Wood, the blade is five 0.14-thick `Metal` slabs in cool silver (Reflectance 0.15), and the collar and pommel are `Metal`. That is a realistic material ladder. It clashes with our SmoothPlastic voxel pets and the stud ground (HOWTO models §1: "Never use Metal ... on pets").
- **Every tier has the same silhouette.** The only differences are a 6%-per-tier scale (`k`), the collar and pommel colour, and a neon edge from tier 4 up. In the shop grid (icons reuse this builder), Rusty and Candy are the same grey crescent with a different coloured knob. Nothing escalates in shape, size, glow or trail.
- **It does not read at chase-camera distance.** In the swing capture, the blade is a 0.14-stud grey sliver yawed 40° and the shaft is a near-black stick. Both disappear against dark posts and orange pumpkins.
- **The reference games do the opposite.** The PvB bat (refs/videos/plants-vs-brainrots-sheets/s028) is one chunky light block about 0.5 thick, read from silhouette and value contrast alone. The impact star does the rest. Steal an Egg's props and pets are flat-colour SmoothPlastic blocks on stud ground. PS99, GAG and BSS tools escalate the same way: each tier is bigger, more saturated, gets a new shape feature, and the top tiers glow and trail.

## 2. Style rules for every tier

| Rule | Value |
|---|---|
| Material | `SmoothPlastic` on every part. `Neon` only for glow pieces (edges, gems, eyes). No Metal, Wood or Foil. Reflectance 0. |
| Voxel blade | The blade is a stepped pixel crescent: one part per column, snapped to a per-tier voxel `V`. No rotated slabs. |
| Thickness | Blade body is 0.3 thick (Z). The cutting edge is 0.36 thick, so it sits proud and catches light. Shaft is square, 0.4 to 0.55 wide. |
| Colour | 2 main flat colours plus 1 accent per tier. The shade block is 15% darker. Edge colour is always lighter than the body (a white or neon "shine" line), which is the PvB and SAE value trick. |
| Plane | The blade lies in the hold frame's X-Y plane: it extends +X (character right), with its face normal +Z toward the chase camera. Yaw it 25° about Y (tip forward) so the broad face still shows from behind. That is less than today's 40°, which turns the face edge-on. Tune 15-35° on a Studio capture. |
| Part budget | ≤ 30 parts for tiers 1-5, ≤ 45 for tier 7. Each column is 2 parts (body + edge). |
| Escalation ladder | Size: the shaft grows 4.2 → 6.4 and the blade 1.7 → 5.1 studs. Silhouette: each tier adds one feature. Glow: none (T1-3), then neon edge + light (T4), + particles (T5-6), + outline + fire (T7). Trail: white thin → tier colour wide. |

## 3. Shared geometry (Codex: one builder, data-driven)

Frame: the `Handle` is the shaft, centred on the origin. Y runs along the shaft, X is character right, and +Z faces the camera.

- **Shaft:** `Handle` Size `(W, L, W)`.
- **Collar** (blade mount): centred at `y = L/2 - C/2`, size `(C, C, C)` with `C = W + 0.3`. A tier may replace it with a feature (skull, gem, pumpkin).
- **Blade origin** `B` = `CFrame.new(W/2, L/2 - 0.1, 0) * CFrame.Angles(0, rad(25), 0)`.
- **Blade column i** (1-based) with entry `{top, h}` in voxels:
  - body: Size `(V, h*V, 0.3)`, centre `B * (x = (i-0.5)*V, y = (top - h/2)*V, 0)`
  - edge: Size `(V + 0.02, 0.5*V, 0.36)`, centre `B * (x = (i-0.5)*V, y = (top - h - 0.25)*V, 0)`, in edge colour (Neon from T4)
  - Columns overlap by 0.01 in X to hide seams.
- **Trail attachments:** `TrailRoot` = column 1 body centre. `TrailTip` = the last column's edge centre. The swing trail therefore follows the real tip at every size.
- **Grip wrap:** a part `(W+0.1, 0.8, W+0.1)` at handle-local `y = -grip.up` in the tier's grip colour. It marks where the hand closes.

Blade column tables (top, h), generated as a stepped crescent that hooks down:

| Tier | V | Columns `{top,h}` | Blade length |
|---|---|---|---|
| T1 | 0.34 | {1,3},{0,2},{0,2},{-1,1},{-2,1} | 1.7 |
| T2 | 0.36 | {1,3},{0,3},{0,2},{-1,2},{-2,1},{-3,1} | 2.2 |
| T3 | 0.38 | {1,4},{0,4},{0,3},{-1,3},{-1,2},{-2,2},{-3,1} | 2.7 |
| T4 | 0.40 | {1,4},{0,4},{0,3},{-1,3},{-1,2},{-2,2},{-3,2},{-4,1} | 3.2 |
| T5 | 0.42 | {1,4},{0,4},{0,3},{-1,3},{-1,3},{-2,2},{-3,2},{-4,2},{-5,1} | 3.8 |
| T6 | 0.44 | {1,5},{0,5},{0,4},{-1,4},{-1,3},{-2,3},{-3,2},{-4,2},{-5,2} | 4.0 |
| T7 | 0.46 | {1,5},{0,5},{0,4},{-1,4},{-1,4},{-2,3},{-2,3},{-3,3},{-4,2},{-5,2},{-6,2} | 5.1 |

## 4. The 7 tiers

Colours are hex. Every part is SmoothPlastic unless it is marked N (Neon).

### T1 Rusty Scythe (RustySickle): a beat-up farm sickle
- Shaft L 4.2, W 0.40, #8B5A2B. Grip wrap #D9C9A3 (cloth tape). A second tape band 0.25 tall at y = +0.6.
- Collar: plain block C 0.7, #5A3A22.
- Blade body #B5653A (rust), edge #E8A878 (dull shine). Column 3 is chipped: its edge part is #8C4A28, so the blade looks notched.
- Pommel: 0.5 cube #5A3A22.
- Glow: none. Trail: white, width 0.6, Lifetime 0.15.
- Parts: about 15. Read: small, brown, humble. "Upgrade me."

### T2 Iron Scythe (WoodenScythe): clean grey steel, first real tool
- Shaft L 4.6, W 0.42, #9C6A3A, with 2 iron bands `(W+0.08, 0.2, W+0.08)` #5C6370 at y = ±1.0. Grip wrap #3A3F4A.
- Collar: iron block C 0.72, #5C6370, with 2 rivets `0.14` cube #2E323A on its +Z face.
- Blade body #C9D1DC, edge #FFFFFF. Shade: column 1 top voxel is #A9B1BE.
- Pommel: 0.5 iron cube #5C6370.
- Glow: none. Trail: #E6F0FF, width 0.7.
- Read: brighter, bigger, white shine line. Contrast jump from T1.

### T3 Bone Scythe (BoneScythe): first new silhouette (skull)
- Shaft: 4 knuckle segments stacked over L 5.0. Each segment is a 1.1-tall block `(W, 1.1, W)` with W 0.45, alternating #FFF6E0 and #E8DCC0. The joints between segments are `(W+0.14, 0.22, W+0.14)` #E8DCC0.
- Collar becomes a **skull**: a 0.95 cube #FFF6E0. Its +Z face has 2 eye blocks `(0.24, 0.24, 0.05)` #2A2238 at (±0.2, 0.08), a nose `(0.12, 0.12, 0.05)` #2A2238 at (0, -0.15), and a jaw `(0.7, 0.2, 0.7)` #E8DCC0 under it.
- Blade body #FFF6E0, edge #BFC4D6 (pale). Shade: the top voxel of columns 1-2 is #E8DCC0.
- Pommel: bone knob, a 0.55 cube + a 0.35 cube under it, #FFF6E0.
- Glow: none. Trail: #FFF6E0, width 0.8.
- Read: a face on the tool. Kids recognise it in the shop grid instantly.

### T4 Hex Scythe (CursedScythe, display name "Witch Scythe"): first glow tier
- Shaft L 5.3, W 0.46, #3B2160. A **spiral**: 4 small blocks `0.22` cube #8A3FFC hug the shaft at y = -1.5, -0.5, +0.5, +1.5, stepping round the 4 faces (+X, +Z, -X, -Z).
- Collar becomes a **gem**: a 0.7 cube **N #B266FF**, rotated 45° on Z (diamond), in a #3B2160 cradle block `(0.9, 0.3, 0.9)` under it. PointLight #B266FF, Brightness 1.2, Range 7.
- Blade body #8A3FFC, edge **N #D49BFF**. Shade: the top voxel of all columns is #6A22D0.
- Pommel: a small N #B266FF diamond, 0.4.
- Particles at TrailTip: sparkle, #E2C2FF, Rate 3, Lifetime 0.6, Size 0.15→0, LightEmission 1.
- Trail: #B266FF → #6A22D0, width 1.0, LightEmission 1.
- Read: the first scythe that **glows**. That is the hook to grind to 9K.

### T5 Vampire Scythe (MoonScythe): bat wings, crimson
- Recommend changing `Config.Tools[5].color` from moon blue (110,170,255) to crimson (220,40,70) so the name, card and model agree. If the blue is kept, swap the palette below to #6EAAFF / #1E2A55 / N #BFE4FF.
- Shaft L 5.6, W 0.48, #2A2238. Grip wrap #7F1A33. Bands #C8102E.
- Collar: C 0.8, #7F1A33, plus **bat wings** off its ±X sides. Each wing is 3 stepped blocks, 0.2 thick: (0.5, 0.6) at an x offset of 0.6, (0.45, 0.45) at 1.0 raised 0.25, and (0.4, 0.3) at 1.35 raised 0.45. Colours #2A2238, with an inner #7F1A33 voxel on the first block. Two **fangs** `(0.12, 0.28, 0.12)` #FFFFFF hang under the collar's +Z face.
- Blade body #C8102E. **Spine row:** the top voxel of every column is #2A2238, giving a two-tone blade. Edge **N #FF4D6D**.
- Pommel: a 0.5 cube #2A2238 with a N #FF4D6D 0.2 cube on its tip.
- PointLight #FF4D6D, Brightness 1.2, Range 8. Particles: dark red wisps, #7F1A33, Rate 4, upward drift 1.
- Trail: #FF4D6D → #2A2238, width 1.15.

### T6 Candy Scythe (CandyScythe): peppermint and pinwheel
- Shaft L 5.9, W 0.5, white #FFFFFF, with 5 red bands `(W+0.04, 0.4, W+0.04)` #FF3B5C evenly spaced (6 parts total).
- Collar becomes a **pinwheel lollipop** that faces +Z. It is 3 flat squares (thickness 0.25), each rotated 45° from the last on Z: 1.1 #FF6EC7, 0.75 #FFFFFF, 0.4 #FF6EC7.
- Blade body #FF6EC7, edge **N #FFFFFF**. **Sprinkles:** 5 cubes `0.13`, 0.03 proud of the +Z face on random columns, in #FFD606, #7CFC3A, #4FC3FF, #FFFFFF and #8A3FFC.
- Pommel: a wrapped sweet. A 0.5 cube #FF3B5C plus 2 wedges 0.3 #FFFFFF on ±X.
- PointLight #FF9AD8, Brightness 1, Range 8. Particles: confetti cubes, 5 colours, Rate 4.
- Trail: a pastel rainbow ColorSequence (#FF6EC7, #FFD606, #7CFC3A, #4FC3FF), width 1.25, LightEmission 0.8.

### T7 King Scythe (PumpkinKingCleaver): double blade, pumpkin crown, fire
- Shaft L 6.4, W 0.55, #4B1F6F, with 3 gold bands #FFD606. Grip wrap #C8102E (royal velvet).
- **Back spike:** a mirrored mini blade on -X, columns {1,3},{0,2},{-1,1} at V 0.46. Body only, gold. This makes a double-bladed silhouette, unique in the set.
- Collar becomes a **jack-o-lantern king**. A 1.15 cube #FF8A1F (shade #E06A00 on its bottom 0.25 slab). On its +Z face: 2 triangle-ish eyes, each a 0.28 cube **N #FFD606**, and a mouth `(0.6, 0.18)` **N #FFD606**. A stem `(0.25, 0.4, 0.25)` #3DBA3A sits on top. A **crown** sits on the stem: a band `(1.25, 0.25, 1.25)` #FFD606 and 4 corner spikes `(0.25, 0.45, 0.25)` #FFD606.
- Blade body #FFD606, edge **N #FFF3A0**. Spine: the top voxel of every column is #E0A800.
- Pommel: a 0.6 gold cube with a 0.3 ruby #C8102E inset on +Z.
- PointLight #FF9A2E, Brightness 2, Range 10. Fire particles at the pumpkin: orange #FF8A1F → #FFD606, Rate 6, Lifetime 0.5, upward 2. Gold sparkle at TrailTip, Rate 4.
- `Highlight` parented to the tool: FillTransparency 1, OutlineColor #FFF3A0, OutlineTransparency 0.4, DepthMode Occluded. Only one per character, so it stays far under the 255 limit.
- Trail: #FFD606 → #FF8A1F, width 1.4, LightEmission 1, Lifetime 0.25.
- Parts: about 43.

## 5. Grip (hand-held offset)

Keep the existing math (`tool.Grip = hold:Inverse()`). Make `ScytheHold` per tier, derived from L, so the hand always closes on the grip wrap about a quarter of the way up the shaft. Longer tiers then rise higher over the head, which is the size escalation players see.

```lua
-- per tier, L = shaft length
hold = { right = 0.05, forward = 0.1, lean = 8, up = 0.25 * L }
-- T1 up 1.05 | T2 1.15 | T3 1.25 | T4 1.33 | T5 1.40 | T6 1.48 | T7 1.60
-- grip wrap part centred at handle-local y = -hold.up (exactly in the fist)
```

- `lean` 8° (up from 6) tips the blade slightly over the head, toward the target, so it frames the character from the chase camera.
- `forward` 0.1 stops the thicker 0.55 shaft clipping the forearm on R15.
- The blade top clears the head on every tier: (L/2 + up) ≥ 3.1 studs above the hand.

## 6. Data for Codex (drop-in table, keyed by tool id)

```lua
ScytheStyles = {
  RustySickle   = { L=4.2, W=0.40, V=0.34, shaft="8B5A2B", body="B5653A", edge="E8A878", neon=false, trail={"FFFFFF","FFFFFF"}, tw=0.6,  feature="tape" },
  WoodenScythe  = { L=4.6, W=0.42, V=0.36, shaft="9C6A3A", body="C9D1DC", edge="FFFFFF", neon=false, trail={"E6F0FF","E6F0FF"}, tw=0.7,  feature="iron" },
  BoneScythe    = { L=5.0, W=0.45, V=0.38, shaft="FFF6E0", body="FFF6E0", edge="BFC4D6", neon=false, trail={"FFF6E0","FFF6E0"}, tw=0.8,  feature="skull" },
  CursedScythe  = { L=5.3, W=0.46, V=0.40, shaft="3B2160", body="8A3FFC", edge="D49BFF", neon=true,  trail={"B266FF","6A22D0"}, tw=1.0,  feature="gem",      light="B266FF" },
  MoonScythe    = { L=5.6, W=0.48, V=0.42, shaft="2A2238", body="C8102E", edge="FF4D6D", neon=true,  trail={"FF4D6D","2A2238"}, tw=1.15, feature="batwings", light="FF4D6D", spine="2A2238" },
  CandyScythe   = { L=5.9, W=0.50, V=0.44, shaft="FFFFFF", body="FF6EC7", edge="FFFFFF", neon=true,  trail="rainbow",          tw=1.25, feature="pinwheel", light="FF9AD8" },
  PumpkinKingCleaver = { L=6.4, W=0.55, V=0.46, shaft="4B1F6F", body="FFD606", edge="FFF3A0", neon=true, trail={"FFD606","FF8A1F"}, tw=1.4, feature="kingpumpkin", light="FF9A2E", spine="E0A800", backSpike=true, outline=true },
}
-- blade columns: section 3 table. Feature builders: one small function each (section 4).
-- KingSkin (server ~7182 sets visual.order = KingSkin.shapeTier): pick the style by the
-- visual def's id so skins still map to one of these 7 looks.
```

## 7. Mesh fallback (generate_mesh), only if a tier's parts look weak in capture

Parts are the recommended path: they match the voxel pets exactly and need no moderation or upload. If a hero piece needs a mesh, generate only that **collar ornament**, never the whole scythe (meshes come out smooth and break the stud-block look). Use SuggestedSize `Vector3.new(1.2, 1.2, 1.2)`, generate 2-3 candidates and keep the blockiest, then set Material SmoothPlastic and scale to C. Keep prompts short and literal. Do not use the restricted words.

- T3: `"small cartoon skull, blocky voxel toy style, low poly, flat cream white, big black square eyes"`
- T4: `"purple crystal gem, blocky voxel style, low poly, glowing violet, diamond shape"`
- T5: `"tiny bat with spread wings, blocky voxel toy style, low poly, black and dark red"`
- T6: `"swirl lollipop, blocky voxel toy style, low poly, pink and white stripes"`
- T7: `"jack-o-lantern wearing a small gold crown, blocky voxel toy style, low poly, bright orange, glowing yellow face"`

## 8. Model-side hooks for the swing (for whoever wins Angle B)

- The trail follows the real tip (section 3), so the arc is longer on bigger tiers with no extra animation code.
- Bigger tiers can play the same keyframes slightly heavier: scale the wind-up key time by `1 + 0.03*(order-1)` and keep the hit frame. Lower the whoosh pitch by about 0.04 per tier. That makes the T7 slash feel weighty, not slow.
- On a tier upgrade (purchase toast), scale-pop the new tool: Model scale 0.6 → 1.1 → 1.0 over 0.25 s, Back easing, plus `Center.purchaseBurst()`. That way the escalation is felt in the hand, not just in the shop.

## 9. Acceptance (blind-judge checks in Studio)

1. Shop grid capture: all 7 icons are distinguishable **in greyscale** (silhouette alone: sickle, banded, skull, diamond, wings, pinwheel, double blade + crown).
2. Chase-camera capture at 10 studs: the blade reads as a solid shape (≥ 3 voxel columns visible), not a sliver, on the Grass hub and in front of an orange pumpkin.
3. Side by side with the PvB bat frame (s028) and an SAE pet: same material family (flat SmoothPlastic + neon), with no metal sheen.
4. Part counts: T1-5 ≤ 30, T7 ≤ 45. No CanCollide parts. Everything Massless and welded to Handle.
5. Phone: the blade top stays inside the frame above the head with the default camera zoom.
