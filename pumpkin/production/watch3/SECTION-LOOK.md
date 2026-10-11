# SECTION-LOOK: font, icons, pumpkin and candy models (round 3)

Owner quotes: "this font looks bad and low quality" (Z12), "the UI icons are terrible" (Z18), "the pumpkins have a block in them and the candy on top looks bad" (Z13), "the candy is just 3 coloured blocks" (Z10).
Evidence used: live play view `tool-results/mcp-Roblox_Studio-blob-1791730176676-paih14.jpg` (crops of the pumpkins), `refs/aspects/ui/v2/*` (SAE, PS99, GAG frames), `refs/aspects/ui/REFERENCES-2.md` §6, `UI-SPEC-V2` lines 108-113, `UI-SPEC-V3` lines 41-42. All paths below are relative to `pumpkin/giant/`. No game code was edited.

Impact order: P1 block (S), P2 candy emoji (S), P3 squash (S), F1 font swap (S), F2 fixed text sizes and stroke (M), I1 icon pipeline (M), I2 12 icons (L for art, M for the voxel fallback), C1 candy 3D model (M).

---

## 1. FONT

### 1.1 Which fonts the references use
| Game | Evidence | Family |
|---|---|---|
| Steal an Egg | `v2/01-sae-hud-clean.png`, `v2/04-sae-shop.png`: wide geometric caps, italic currency "$55.8Qa"; UI-SPEC-V2:54 "Montserrat/Gotham Black Italic" | Gotham Black (Heavy) / Montserrat Black Italic for numbers |
| Pet Sim 99 | `v2/05-ps99-collection.png`: round terminals, single heavy weight, thick dark stroke; BIBLE-PET-SIM-99:121 | Fredoka One / Lilita look |
| Grow a Garden | `v2/06-gag-hud-panels.jpg`: bold, slightly rounded, stroke on small text only; BIBLE-GROW-A-GARDEN:155 | Builder Sans Bold / Gotham-Black look |
| Pet Sim X, Steal a Brainrot, Plants vs Brainrots | BIBLE-PET-SIM-X:236, BIBLE-STEAL-A-BRAINROT:162, BIBLE-PLANTS-VS-BRAINROTS:237 | rounded heavy cartoon sans (Fredoka) |

4 of the 6 reference games are Fredoka-style rounded; only SAE is Gotham. The game's voxel-toy look (rounded pumpkins, chunky `chunky()` buttons) matches the rounded family.

### 1.2 Why ours looks low quality (each is a finding)
1. **One weight everywhere.** `PatchConfig.luau:10-14` sets title, number, button, small and shout all to GothamSSm Heavy, and `fontFace` (`Patch.client.luau:31-36`) lets `spec.weight` override the caller's weight. A 12 px caption is Black weight with a 2 px stroke, so the counters fill in. In the play shot the quest card ("Pumpkin Meadow / [ ] Smash 7/50 / Next gate -25%") and "2 new pets + New pets" are clotted blobs.
2. **Italic that probably does not exist.** `PatchConfig.luau:15` `numberStyle = "Italic"`, used at `Patch.client.luau:1233` (candy number) and `:1537` (ribbon, `fontFace("small","Heavy","Italic")`). GothamSSm.json normally ships upright faces only, so the engine falls back to upright or a faux slant. SAE's italic comes from Montserrat Black Italic (UI-SPEC-V2:110), which V3 dropped. Verify in Studio before the fix: `Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Heavy, Enum.FontStyle.Italic)` and look at the rendered slant.
3. **TextScaled plus a clamp.** `UI.fitText` (`Patch.client.luau:587-615`) sets `UITextSizeConstraint` min/max from fractions, so the same label class renders at different, fractional sizes and the glyph edges blur. Fixed integer TextSize is how PS99 and SAE read crisp.
4. **Stroke too thin for the weight.** `textLabel` (`:624-628`) uses `max(1.5, h*0.0028)`, about 2.4 px at 863 px high. Gotham Black needs 3.5-4 px (UI-SPEC-V3:42 asks for it, but fitText overwrites it at `:605`). Reference strokes are about 8-10% of text height.
5. **Mixed font paths.** `Giant.client.luau:97,164,784,860,981` use FredokaOne; `Patch.client.luau:6099` uses `Enum.Font.GothamBold`; `Patch.server.luau:5282` uses `GothamBlack`; billboards go through a second `Helpers.fontFace` (`Patch.server.luau:123-127`) that ignores style. So the same game shows 2-3 faces.
6. **Copy tells.** ASCII "[ ]" / "[x]" checkboxes and emoji (stripped by `Palette.uiText`, `:562-575`) leave gaps and odd spacing.

### 1.3 Pick (fix spec)
**F1 (S): one display family and one body family.**

| Role | Family | Weight | Used for |
|---|---|---|---|
| title, number, button, shout | `Font.fromEnum(Enum.Font.FredokaOne)` (`rbxasset://fonts/families/FredokaOne.json`) | Regular (it only has one weight; never ask for Bold, that is faux-bold) | every title, every number, buttons, banners, billboards, damage numbers |
| small (body) | `rbxasset://fonts/families/GothamSSm.json` | **Bold** (not Heavy) | quest text, card details, tooltips, captions, 11-16 px text |

Edits: `PatchConfig.luau:10-14` (title/number/button/shout = `Enum.Font.FredokaOne` name string, or `{family = ".../FredokaOne.json", weight = "Regular"}`; small = `{family = ".../GothamSSm.json", weight = "Bold"}`), `numberStyle = "Normal"`, remove the `"Italic"` argument at `Patch.client.luau:1537`. Replace `GothamBold` (`:6099`), `GothamBlack` (`Patch.server.luau:5282`) with `fontFace`/`Helpers.fontFace`. Leave `Giant.client.luau` alone (already Fredoka).
If Zion insists on the SAE italic look instead: numbers = `Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Black, Enum.FontStyle.Italic)`, titles stay Fredoka.

**F2 (M): sizes and stroke (all px at 1080 px viewport height h; multiply by h/1080).**
- Replace `TextScaled` + `UITextSizeConstraint` with `TextScaled = false`, `TextSize = math.floor(h * fraction + 0.5)`, `TextWrapped = true`, and recompute on `AbsoluteSize` change.
- Sizes: currency number 56 (0.052h), screen title 44, panel header 40, button label 30, objective/HUD line 30, card name 24, body 20, hard minimum 15 (14 on phones). Billboards: pet/name 28, damage 34-56 (existing).
- Stroke: pure black `Color3.new(0,0,0)`, `ApplyStrokeMode = Contextual`, `LineJoinMode = Round`, `Thickness = clamp(floor(TextSize * 0.09 + 0.5), 2, 6)` (56 px gives 5, 30 px gives 3, 20 px gives 2). Body Gotham Bold text: thickness 2 (1.5 under 16 px). Never tween Thickness.
- Number fill: white or token colour with a `UIGradient` rotation 90, top = colour, bottom = colour lerped 18% to black (candy: #FFD23A to #FFA21A). No italic; optional `Rotation = -3` on the big candy label for a lean.
- Remove "[ ]"/"[x]" from quest copy; show a 0.03h Frame-built checkbox or a ✓/o icon image instead.

---

## 2. ICONS

### 2.1 Why they are terrible
- `UI.icon` (`Patch.client.luau:894-989`) builds every symbol from rotated rectangles. Evidence: the HUD candy (`UI.candyGlyph`, `:990-1000`) is **3 coloured Frames** (a crown-like blob), King = 4 rectangles (`:957-961`), Carry/Sprint = 1-3 white sticks (`:962-970`), Shop and Pets fall into the same jack-o'-lantern fallback (`:971-986`) with a stripe or outline added, and **there is no Scythe id at all**.
- In the play shot the Shop button shows the jack-o'-lantern fallback face (it reads as a face, not a shop), and the other glyphs are flat rectangle stacks. Reference tiles (TE, SAE, PS99, REFERENCES-2 §2) use a real 3D-looking image filling about 80-85% of the tile.

### 2.2 Style rules (apply to both AI art and voxel fallback)
- Canvas 256x256 transparent PNG (also export 128). Subject fills 88%, centred, 3/4 view, tilted about 10 degrees. One object per icon, max 3 hues.
- **Outline**: pure black `#000000`, 8 px at 256 (3%), rounded joins, one continuous contour.
- **Two-tone shading** only: base colour, plus a shadow tone = base shifted toward purple (hue -15, value -30%) on the lower-right third. No gradients, no textures, no noise.
- **Highlight**: a lighter tint (value +25%) crescent on the upper-left edge, plus one white specular dot at 8% size.
- Palette limited to the UI tokens: orange `#FF8A1A`, purple `#A13BFF`, candy gold `#FFD23A`, lime `#5CFF1F`, red `#FF3B3B`, cyan `#3FD0FF`, steel `#C9D1DC`, brown `#9A6A35`.
- No text, no ground shadow. A 4 px black offset shadow bottom-right is allowed. Must pass two tests: still readable at 48 px, and recognisable as a flat black silhouette.
- Placement: tile icons 0.073h square at 80% of the tile; inline icons 0.058h (candy), 0.040h (carry, timer, king chips). An `ImageLabel`, `ScaleType = Fit`.

### 2.3 AI prompts (generator: any; paste, pick best of 4, remove the background, downsample)
Shared prefix: *"Game UI icon, chunky cartoon 3D toy style like Pet Simulator 99, thick pure black outline, two-tone cel shading, bright white highlight crescent upper left and one specular dot, darker purple-tinted shadow lower right, saturated colours, rounded forms, single centred object, slight 3/4 view tilted 10 degrees, solid flat magenta #FF00FF background, no text, no border, no ground shadow, 1024x1024."* Shared negative: *"realistic, photo, texture, noise, gradient background, text, watermark, thin lines, multiple objects."*

| # | Icon | Subject line appended to the prefix |
|---|---|---|
| 1 | shop | an orange paper shopping bag with a black handle and a big gold coin on the front |
| 2 | index | a closed purple storybook with a gold page edge and a small orange pumpkin on the cover |
| 3 | pets | a cute orange jack-o'-lantern pumpkin pup face with two little ears and triangle eyes |
| 4 | quests | a cream parchment quest sign in a brown frame with a big red exclamation mark |
| 5 | daily | a purple gift box with a gold ribbon and a gold bow |
| 6 | settings | a silver gear with a dark hub hole |
| 7 | candy | a red and white swirl wrapped candy with twisted red wrapper ends |
| 8 | scythe | a farmer's scythe with a curved steel blade and a dark brown wooden handle, blade up, diagonal |
| 9 | King | a gold royal crown with three points and one red gem |
| 10 | timer | a white stopwatch with a cyan rim, black hands and a small button on top |
| 11 | carry | a round orange pumpkin with a green stem, ribbed, seen slightly from above |
| 12 | sprint | a yellow lightning bolt with an orange shaded edge |

Keep the 12 as one batch with the same seed/style reference so outline weight and light direction match. Upload as Decals (Zion's account) and store ids in a new `Config.UI.Icons = { Shop = "rbxassetid://...", ... }`.

### 2.4 Code pipeline (M)
Replace the body of `UI.icon(parent, id)`: if `Config.UI.Icons[id]` exists, make an `ImageLabel` (square, `ScaleType Fit`, `BackgroundTransparency 1`); else if `ReplicatedStorage.UiIcons[id]` exists, `Palette.renderModel(parent, UiIcons[id], false, true)` (`Patch.client.luau:745`, already outlines with a 1.10x black clone); else the old frame fallback. Add the `Scythe` id. Notes: `renderModel` caps 40 live ViewportFrames and each outlined icon uses 2, so 12 voxel icons cost 24 of the budget; raise the cap to 60 or draw the AI PNG first. For icons change the pose at `:787-790` to `CFrame.Angles(math.rad(-12), math.rad(-25), 0)`.

### 2.5 Voxel fallback (build as Models in `ReplicatedStorage.UiIcons`, one per id)
Rules: 1 stud voxels, Material Plastic, `Anchored`, no collision. Each grid below is the FRONT face, row 1 top, column 1 left, 12x12, `.` empty. Extrude each filled cell 3 studs deep (z = -1, 0, +1) and merge each horizontal run of the same key into one Part (about 20-40 Parts per icon). Highlight keys (`h`, `Y`, `q`, `w`) only on the front layer. The renderer's outline pass provides the black contour. Camera: FOV 20, `renderModel` fit.

Palette keys: o `FF8A1A`, O `B8500A`, Y `FFD9A0`, y `FFD23A`, h `FFF3B0`, g `5CD13A`, G `2E7D1E`, p `A13BFF`, P `4E1A99`, q `D6A8FF`, r `FF3B3B`, R `9A1414`, w `FFFFFF`, s `C9D1DC`, S `6B7685`, b `9A6A35`, B `4A2E12`, k `1E1030`, c `3FD0FF`, C `147A9E`, n `F5E6C0`, N `B89A5E`.

```
-- shop
....BBBB....
...B....B...
...B....B...
.oooooooooo.
.YoooooooooO
.oooyyyyoooO
.ooyyhyyyooO
.ooyyyyyyooO
.oooyyyyoooO
.ooooooooooO
.OOOOOOOOOO.
............

-- index
............
.PPPPPPPPPP.
.PqpppgpppPy
.PqppgGgppPy
.Pqpooooopwy
.Pqpooooopwy
.Pqpoooooopw
.Pqppooooppw
.Pqpppppppwy
.PPPPPPPPPP.
..wwwwwwww..
............

-- pets
............
..OO....OO..
.OooO..OooO.
.OooooooooO.
OoYoooooooOO
OoookkookkoO
OooooooooooO
OooookkkkooO
OooookooykoO
.OooooooooO.
..OOOOOOOO..
............

-- quests
............
.bbbbbbbbbb.
.bnnnnnnnnbN
.bnnnrrnnnbN
.bnnnrrnnnbN
.bnnnrrnnnbN
.bnnnrrnnnbN
.bnnnnnnnnbN
.bnnnrrnnnbN
.bnnnrrnnnbN
.bbbbbbbbbb.
............

-- daily
............
...yy..yy...
..yyyyyyyy..
...yyyyyy...
.pppppyypppp
.qppppyyppPP
.pppppyyppPP
.pppppyyppPP
.pppppyyppPP
.pppppyyppPP
.PPPPPyyPPPP
............

-- settings
............
.....ss.....
..s.ssssss.s
..ssssSSsss.
...ssSSSSss.
.ssssSkkSsss
.ssssSkkSsss
...ssSSSSss.
..ssssSSsss.
..s.ssssss.s
.....ss.....
............

-- candy
............
............
....RRRR....
rr.RwwrrR.rr
rrrwwrrwRrrr
.rrwrrwwRrr.
.rrrrwwrRrr.
rrrrwwrrRrrr
rr.wwrrwR.rr
....RRRR....
............
............

-- scythe
..ssssssss..
.ssSSSSSSSs.
ssS.....SBS.
sS......BB..
s......BB...
......BB....
.....BB.....
....BB......
...BB.......
..BB........
.BB.........
.B..........

-- king
............
.y....y....y
.yy..yyy..yy
.yyyyyyyyyyy
.yyhyyrryyyy
.yyyyyyyyyyy
.yyyyyyyyyOy
.yOOOOOOOOOy
.yyyyyyyyyyy
............
............
............

-- timer
.....ss.....
....ssss....
......S.....
...CCCCCC...
..CwwwwwwC..
.CwwwwkwwwC.
.CwwwwkwwwC.
.CwwwwkkkwC.
.CwwwwwwwwC.
..CwwwwwwC..
...CCCCCC...
............

-- carry
.....gg.....
....gGg.....
..oooGoooo..
.oYooGooooO.
oYoooGoooooO
oYoooGoooooO
oooooGoooooO
oooooGoooooO
.oooooooooO.
.ooooGooooO.
..OOOOOOOO..
............

-- sprint
......hyyy..
.....hyyyo..
....hyyyo...
...hyyyyyyo.
..hyyyyyyo..
.....yyyo...
....yyyo....
...yyyo.....
..yyyo......
..yyo.......
..yo........
............
```
A preview PNG of these grids was rendered during research (`scratchpad/ic/prev.png`) and reads correctly; scythe, crown and bolt are the weakest. They are a stop-gap, the AI icons in §2.3 are the primary.

---

## 3. WILD PUMPKIN MODEL AND THE CANDY ABOVE IT

### 3.1 The block (P1, S)
Found: `Patch.server.luau:4253-4263` in `Wild.spawnOne`.
```
local stem = Instance.new("Part")            -- default Block shape
stem.Name, stem.Size = "PumpkinStem", Vector3.new(0.35, 0.8, 0.35) * sizeMult
stem.Color, stem.Material = Color3.fromRGB(76, 92, 32), Enum.Material.Wood
...
stem.CFrame = part.CFrame * CFrame.new(0, part.Size.Y / 2, 0) * CFrame.Angles(0, 0, 0.2)
```
Problems, confirmed in the play shot crops: (a) a hard-edged square Block, dark olive that reads near-black in the lime lighting; (b) centred exactly ON the top surface so half of it pokes up as a slab and half is buried; (c) the KayKit `pumpkin_orange` MeshPart (`PatchConfig.luau:183`, picked in `seedTemplate` `Patch.server.luau:1565-1592`) already has its own stem, and a grey lump of that stem is visible inside the block, so there are two stems;

**Fix, ordered:**
1. Delete lines 4253-4257 and 4261-4263 (the `PumpkinStem` Part and its weld). This is the whole fix if the mesh stem looks fine once the block is gone.
2. If the mesh stem renders grey or ugly after step 1, add a **proper stem** instead, built as a `Cylinder` Part (Shape Cylinder, which is X-axis, so rotate 90 degrees to stand it up): `W = part.Size.X`; diameter `0.11*W`, length `0.20*W`; colour `#5E8F2A`, Material SmoothPlastic; `CFrame = part.CFrame * CFrame.new(0, part.Size.Y/2 - 0.03*W, 0) * CFrame.Angles(0, 0, math.rad(90)) * CFrame.Angles(math.rad(12), 0, 0)` (the extra tilt is on the stem's own axis, so it follows the pumpkin's yaw); weld to `part`, `CanCollide/CanTouch/CanQuery = false`, `Massless = true`. Optional curl: one `Ball` Part Ø`0.13*W` at the stem tip, same colour.

### 3.2 Squashed body (P3, S)
`Patch.server.luau:4247-4252` multiplies the mesh by one of three non-uniform shapes (1,1.2,0.9) / (1.1,0.85,1.1) / (1,1,1) on top of `makePumpkin` (`:1595-1603`, uniform). The 0.85 variant plus the beige `pumpkin_yellow` (`PatchConfig.luau:192`) is what makes pumpkins read as flat "clouds" in the crops. Fix: uniform scale only, with a random Y factor in 0.95-1.08 (`part.Size *= Vector3.new(1, 0.95 + math.random() * 0.13, 1)`); give the yellow seed a saturated tint `#FFB520` instead of the beige texture so it separates from the lime ground.

### 3.3 The candy above the pumpkin (P2, S)
Found: `Patch.server.luau:4275-4287`, a BillboardGui `CandyIcon`, 40x40, StudsOffset Y = `part.Size.Y/2 + 2.4`, containing a TextLabel with the emoji "🍬" (no stroke, no font set). Problems: it is an emoji (the client strips emoji everywhere else via `Palette.uiText`, so this one clashes with the whole UI); it shows a red bow-tie sticker 2.4 studs above EVERY pumpkin (dozens on screen), unattached to any model, not facing the pumpkin's scale (same 40 px on a 2x big pumpkin); and the HP bar already sits on the same pumpkin, so the reward signal is duplicated noise.

**Decision: remove it** (default). Delete lines 4275-4287 (the whole `icon` BillboardGui). Reward information stays where players already look: the candy fly-up and the +N on pop. Keep the golden pumpkin's `Sparkles` (`:4270-4274`) as the only "this one is worth more" cue.
**Optional replacement (only for Golden and Big pumpkins, M):** a 3D candy per §4 at 0.6x scale, `Anchored = false` welded to the pumpkin top, hovering 1.4 studs above the stem, bobbing +-0.3 stud at 0.6 Hz and spinning 40 deg/s, never for plain pumpkins.

---

## 4. CANDY MODEL (C1, M) used as the HUD icon, world pickup and optional indicator

Replaces `UI.candyGlyph` (3 rectangles). 3D build, all Parts SmoothPlastic, unit = studs, name `Candy` in `ReplicatedStorage.UiIcons`:
- **Body**: `Ball` Part Ø1.2, `#FF3B3B`.
- **Stripes**: 2 thin `Cylinder` Parts (axis X) Ø1.24 x 0.14 thick, `#FFFFFF`, intersecting the ball centre, rotated 40 deg and -40 deg around Z so they read as swirl bands; 1 more at 90 deg optional.
- **Neck**: 2 `Cylinder` Parts Ø0.34 x 0.35, `#C42222`, at +-0.72 on X.
- **Wrapper ends**: per side 2 `Wedge` Parts 0.9 x 0.8 x 0.12, `#FF3B3B`, mirrored up/down and angled +-25 deg, centre at +-1.05 on X. Total about 11 Parts.
- Highlight: one `Ball` Ø0.22 `#FFFFFF`, Neon, on the body upper-left. Whole model tilted 15 deg on Z.
Render in the HUD with `Palette.renderModel(..., false, true)` at the 0.058h candy slot, or use the AI icon #7.

---

## 5. Acceptance test
1. In a 1080p play shot no pumpkin has a dark square block on top and no emoji candy floats over a plain pumpkin.
2. Pumpkins keep their round proportions; yellow/golden ones separate clearly from the lime floor.
3. Every label in HUD, shop, index, billboards and damage numbers is Fredoka (display) or Gotham Bold (body); no italic anywhere; the 12 px and 56 px texts are both clean, with no filled-in counters.
4. All 12 icons (shop, index, pets, quests, daily, settings, candy, scythe, King, timer, carry, sprint) are image-based (AI PNG or voxel render) with one consistent black outline and light direction; none is built from rotated Frames.
5. Shrink any icon to 48 px: it is still identifiable, and the candy counter icon is a wrapped candy, not 3 blocks.
