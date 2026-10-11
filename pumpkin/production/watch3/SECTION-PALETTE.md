# SECTION-PALETTE: one cohesive world palette

Source of truth read: scene\LaunchLook4.luau (latest; overrides LaunchLook 1-3 for everything it paints) and PatchConfig.luau Zones (HUD name colours, lines 333-438).
All hex are for `Color3.fromHex`. Materials: Plastic with Studs on floors/walls (as LaunchLook4 does), no Neon except the listed accents.

## 1. Flaws found (evidence)

1. Zone floors have no shared logic. LaunchLook4.luau:202-208 `palette`: Z1 lime A8E04A + orange walls C9783E; Z2 lavender-grey + indigo; Z3 green 5FC24A + brown; Z4 teal 6FBFA0 + deep purple 5E3F94; Z5 pale periwinkle C9CBE6 + blue 4F5D96; Z6 pink + violet; Z7 orange F7A63C + near-black purple. That is lime, orange, blue, teal, purple, pink in sequence: a rainbow, not a world. Blue (Z2, Z5) appears nowhere else and is not Halloween.
2. Hub floor (line 210) is saturated lime 8EE03C / 82D236 beside purple walls 8A6CC8 and orange cap FF9A2E: the worst triad clash (green + purple + orange all at full saturation). Same lime repeated in InnerLawn (line 283).
3. Neon cap colour index 5 is 9BFF4A (lime neon) in Z1, Z3, Z4 (lines 202-206) and FFB347/FFFFFF elsewhere: glowing acid green on walls looks radioactive, and no two zones share a rule.
4. Floor checker pairs differ too much (e.g. A8E04A vs 9DD443, 6FBFA0 vs 64B294 fine, but hub 8EE03C/82D236 plus tile moire on phone). Walls use a different pair per height (line 299), so every wall is a two-tone stripe of unrelated colours.
5. Trims mix pure FFFFFF (lines 284, 434, 510) with warm cream E9DCC4 paths: pure white looks cold and blown out next to cream.
6. Props are leftover brown and near-black purple: Post/Pole/Board 40303A (line 270), Rail/Brace 8E4312 (line 268), ArchBeam 2D1F43 (line 454). Dark and desaturated against the bright floors; reads as dirty, not friendly.
7. Lighting is cool grey-blue: Ambient 7E8494, OutdoorAmbient A4AAB8 (lines 144-145), Atmosphere CFE6FF/9CC2EE (lines 177-178). Cool ambient dulls every warm Halloween colour and makes the orange look brown. It is "daytime generic", not Halloween.
8. HUD zone colours in PatchConfig (lines 335-428) do not match the zone world colours: Z3 HUD is lime 9BEA3A while Z3 world is green+brown, Z5 HUD is red E02020 while the Z5 world is periwinkle, Z6 HUD hot pink, Z7 HUD yellow. The label colour you read at the gate sign contradicts the zone you walk into.
9. Value contrast is not designed: floor, wall and prop values sit within a narrow mid range in several zones (Z2, Z5 floors C9CBE6 vs walls 4F5D96 only because walls are dark blue), so nothing pops (pens, pumpkins, pets lose silhouette).

## 2. What top games do

- Steal an Egg / Grow a Garden / Pet Sim 99: ONE big family of 5-6 colours. Ground is a soft light tone (cream, grass, sand), structures are one saturated hue, and the "money" colour (gold, pink, orange) is reserved for things you interact with. Zones change hue by a single step along the wheel, not by jumping to a new colour family.
- Floors are lower saturation and higher value than the things standing on them, so pumpkins, pets and UI pop. Rule of thumb: floors S 35-50% / V 85-95%; walls S 45-65% / V 55-75%; accents S 85-100% / V 100%.
- Checker pairs differ by about 4-6% in value only (almost the same colour). Walls: base colour plus a lighter trim, not two unrelated hues.
- 60-30-10: 60% neutral/zone floor, 30% zone wall, 10% accent.

## 3. The palette

### 3a. Eight base colours (used everywhere, hub and all zones)

| Name | Hex | Role |
|---|---|---|
| Pumpkin Orange | FF8A1F | Hero accent: pumpkin, caps, banners, spires, interactables |
| Candy Corn Gold | FFC83D | Secondary accent, lanterns, windows, coins |
| Grape Purple | 7A4FD0 | Primary structure colour (walls, gate, buttresses) |
| Midnight Plum | 3B2766 | Darkest shade; shadows, beams, outlines, never larger than 5% of a view |
| Cream | F6E8CC | Neutral ground, paths, plaza |
| Bone | FFF8EC | Trim and curbs (replaces pure FFFFFF) |
| Leaf Green | 9ED66A | Only grass/lawn (hub lawn, Z1, Z3); one green only |
| Warm Wood | B07A4A | Posts, rails, stalls, pen fences |

Hard rule: no blue, no pure white, no lime above S 60%, no neon green, anywhere in the world.

### 3b. Hub

| Surface | Hex |
|---|---|
| Floor checker A / B | 8CC765 / 84BD5E (muted grass; Claude 2026-10-11: all-cream hub looked washed out) |
| InnerLawn | 9ED66A |
| Paths and Plaza | FBF1DC (lighter than floor so paths read) |
| Curb / RingEdge | FFF8EC |
| Hub walls (LaunchWall) low / high | 7A4FD0 / 8A63DE |
| Hub wall cap (Neon) | FF8A1F |
| WallDetails Buttress | 6A42BC |
| CapTrim / Throne Trim | FFF8EC |
| Throne steps 1/2/3 | C9B4F0 / D8C8F5 / E8DEFA (lilac gradient) |
| WallDetails Pumpkin | FF8A1F |
| Gate Tower / Spire / ArchBeam / Banner / Window | 7A4FD0 / FF8A1F / 3B2766 / FF8A1F / FFE08A (SmoothPlastic) |
| Lanterns (8 kept): core / cap base | FFC83D Neon / 3B2766 |

### 3c. Zones 1-7 (floor A/B, wall low/high, accent pair, HUD name colour)

Rule: floor pair is a pale tint of the zone hue; wall low/high are the same hue, 12% value apart; accent pair is {zone accent, Pumpkin Orange or Gold}; the Neon cap uses accent 1. Hues walk warm to cool to warm so each gate reads as a "next level" yet never leaves the orange-purple family.

| Zone | Floor A / B | Wall low / high | Accent 1 (cap, trims) | Accent 2 | HUD colour (PatchConfig.color) |
|---|---|---|---|---|---|
| Z1 Pumpkin Meadow | 9ED66A / 96CE62 | E8B87A / F0C88E (warm tan fence) | FF8A1F | FFF8EC | FFB347 -> FF9A2E |
| Z2 Graveyard | D7CDEB / CFC4E4 | 8E7FC4 / 9F92D2 | FFC83D | FFF8EC | C9B4F0 |
| Z3 Haunted Woods | 8FC87A / 86BF72 | A06A3C / B07A4A | FFC83D | 7A4FD0 | B8E070 -> A8DC6A |
| Z4 Witch Swamp | A8D8C0 / 9ED0B8 | 6A42BC / 7A4FD0 | 9EF0C8 | FF8A1F | 9A6BE8 |
| Z5 Vampire Castle | EAB8C8 / E2AEBF | A8406A / B8507A | FFC83D | FFF8EC | FF6B8E |
| Z6 Candy Kingdom | FAD0E6 / F4C4DE | C79BEA / D8B0F2 | FF5FA8 | 9EF0C8 | FF7EC0 |
| Z7 Pumpkin King's Throne | FFD98A / F8CE78 | 4A2D7A / 5A3A8E | FFC83D | FF8A1F | FFD23D |

Z4 and Z6 use mint (9EF0C8) as the ONLY cool accent, always paired with purple/pink, never with orange next to green floor.
GateWall (per-zone dark): Z1 7A4A2A, Z2 4E4380, Z3 5E3F24, Z4 3B2766, Z5 6A2444, Z6 7E55A8, Z7 2D1F43.

### 3d. Props, pens, stalls

| Item | Hex |
|---|---|
| Patch Soil / Bed Soil | A06A40 |
| Rail / Brace (patch frames) | B07A4A |
| Post / Pole / Board | 6B4430 (warm dark brown, not near-black) |
| Pen fence rails / posts | F6E8CC / 7A4FD0 (cream fence, grape posts) |
| Pen floor | F2DC9A straw |
| Stall body | B07A4A |
| Stall awning stripes | FF8A1F / FFF8EC |
| Stall sign board | 3B2766 with FFC83D text |
| Gravestones | D7CDEB with 8E7FC4 shade |
| Tree trunk / crown (where kept) | 8A5A34 / 9ED66A (Z3: 6FAE60) |
| Bushes, vines | 9ED66A, never darker than 6FAE60 |
| Pumpkin (wild) | FF8A1F body, 6FAE60 stem |

### 3e. Lighting colour

| Property | Now | New |
|---|---|---|
| Ambient | 7E8494 | 9A8DA8 |
| OutdoorAmbient | A4AAB8 | C2B2C8 |
| ColorShift_Top | FFF4E2 | FFE9C8 |
| Brightness | 2.8 | 3.0 |
| ClockTime | 14 | 16.5 (warm late-afternoon, gives orange cast without darkness) |
| Atmosphere Color / Decay | CFE6FF / 9CC2EE | F3D9F0 / FFC8A0 (pink-lavender haze, peach horizon); Density 0.22, Haze 0.4 unchanged |
| PhaseTint (ColorCorrection) | FFFFFF, Sat 0.10, Contrast 0.06 | FFF3E6, Sat 0.14, Contrast 0.08 |
| Bloom | 0.25 / 12 / 1.6 | unchanged |
| PointLights (lanterns) | FFB347 | FFC83D, Brightness 1, Range 12 |

Keep it bright: this is "sunset daylight", not night. Do not drop Brightness below 2.8.

## 4. Fix spec, ordered by impact

1. (S) Replace `palette` and `hub` tables in LaunchLook4.luau (lines 201-210) with the 3b/3c values; columns map as: [1] floor A, [2] floor B, [3] wall low, [4] wall high, [5] cap, [6] GateWall. Effort S, biggest visible change.
2. (S) Delete all 9BFF4A and acid caps; cap colour = Accent 1 of the zone. Replace every `FFFFFF` paint (lines 284, 434, 510, palette[5]/[6] whites) with FFF8EC.
3. (S) Lighting block (lines 138-181) -> 3e values.
4. (S) Props (lines 266-270, 443, 452-457, 393): apply 3d, 3b gate colours; lanterns FFC83D.
5. (M) Pens, stalls, signs, Throne trims built outside LaunchLook4: audit with the same hex table (find by name, paint). Pen fence cream/grape, stall awnings orange/bone stripes.
6. (S) PatchConfig.luau Zones[...].color (lines 335-428): set to the "HUD colour" column so the gate sign matches the world.
7. (S) Checker contrast: floor A/B delta about 4% value as listed; do not mix three tile colours.
8. (M) Pets/pumpkin type colours are out of scope here, but they must never reuse floor colours: pumpkins orange/yellow/pale pop against cream, lilac and pink floors by design.

## 5. Acceptance test

1. Screenshot hub centre and each gate: no blue, no neon green, no pure white; max 3 hues plus neutrals visible at once.
2. Walk Z1 to Z7: each zone's floor reads as a different pastel and its walls as one deeper hue of the same family; orange is visible in every frame (cap, banner, pumpkins).
3. Pumpkins, pets and UI pop: squinting (blur) test, the pumpkin silhouette is still the highest-saturation object in the frame.
4. Gate sign colour matches the colour of the zone behind it for all 7 zones.
5. Side-by-side with a Steal an Egg screenshot: overall brightness, saturation and warmth look comparable; checker is subtle and does not moire on phone.
