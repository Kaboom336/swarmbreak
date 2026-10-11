# UI-SPEC V2: Steal a Pumpkin HUD, panels and Index

This spec replaces `UI-SPEC.md` where the two conflict. The target is the **current Steal an Egg (SAE) look**, with the Index borrowing from Pet Simulator 99 (PS99) and Steal a Brainrot (SAB). The code lives in `giant/src/StarterPlayerScripts/Patch.client.luau`.

**Conventions**
- All sizes and positions are **Scale** values (fractions of the screen). Y is measured from the top.
- Hex values marked **(s)** were sampled from 854x480 frames. All other hex values are estimates.
- Stroke thickness is in px at 1080p. Multiply by `viewport.Y/1080` if you build at another size.

## 0. Evidence

**Our HUD** (1509x863 Studio captures, folder `C:\Users\zerha\.claude\projects\C--dev\3b669d3e-727c-490d-b688-33d8f465dd30\tool-results\`):
- **OURS-1**: `mcp-Roblox_Studio-blob-1791683584333-atdpei.jpg`, carrying, red alarm.
- **OURS-2**: `...-1791683605120-8n8bny.jpg`, normal, Pumpkin Meadow.
- **OURS-3**: `...-1791683631029-z1115f.jpg`, carrying.

**Saved reference frames** (in `C:\dev\codex-lab\refs\aspects\ui\v2\`):

| # | File | What it shows | Source sheet |
|---|---|---|---|
| R1 | `01-sae-hud-clean.png` | SAE HUD with no panel open (854x480) | `refs/videos/v2-sae-guide-sheets/s052.jpg` (15:30) |
| R2 | `02-sae-index.png` | SAE Pet Index: zone tile, 4x2 rarity grid, detail card, rewards box | `refs/videos/v2-sae-everypet-sheets/s007.jpg` (2:02) |
| R3 | `03-sae-index-claimall.png` | SAE Index, newer layout: progress bar per zone, CLAIM ALL with a red count badge, Index button badge "7" | `v2-sae-everypet-sheets/s025.jpg` (7:24) |
| R4 | `04-sae-shop.png` | SAE Shop: lime striped header, charcoal studded body, 3D-render cards, green price bars, red X | `v2-sae-guide-sheets/s040.jpg` (11:54) |
| R5 | `05-ps99-collection.png` | PS99 Collection (3x crop): black silhouette + "?", star badges, tab column, "Collected 190/549" | `v2-ps99-index-sheets/s006.jpg` (1:34) |
| R6 | `06-gag-hud-panels.jpg` | Grow a Garden: 4 wide left buttons, SEEDS / GARDEN / SELL tabs, wood panels, red X | `v2-gag-fairy-sheets/s001.jpg`, `s027.jpg` |

**Other frames used** (in `C:\dev\codex-lab\refs\videos\v2-frames\`):
- `sae_leftbtn_crop.png` and `sae_currency_crop.png`: 4x crops of R1.
- `sae_index_crop.png`: 2x crop of R2.
- `saee_0450.png`: SAE tile close-up showing the black outline around the pet render and the red selected border.
- `ps99_000024.png`: PS99 Rank Rewards claim grid, sheet `v2-ps99-index-sheets/s002.jpg`.
- `sab_pick.jpg`: SAB Index silhouettes and the Normal / Gold / Diamond / Rainbow tabs, the "Collect Normal Brainrots for +0.5x Base Multi 49/145" bar, and the flat SAB HUD. Sheets `v2-sab-every-sheets/s001.jpg`, `s005.jpg`, `s014.jpg`.
- `saeg_001016.png`: SAE event shop, sheet `v2-sae-guide-sheets/s057.jpg`.

**Videos**, all downloaded 2026-10-10 from the newest-first search, then deleted (sheets kept):
- SAE "FULL GUIDE for NEW UPDATE" (gnKALvoe7Kg)
- SAE "I Got Every Pet in 10 Hours" (F9OqWihF_LQ)
- PS99 "COMPLETING THE ENTIRE INDEX" (uNvY9lWZz2s)
- GAG "NEW FAIRY UPDATE PETS ARE BROKEN" (D4Vn2jNX0vw)
- SAB "I Got Every Brainrot in 10 Hours" (Mx3nb5geAfg)

## 1. Top 15 differences, worst first

1. **The Index has no pictures.**
   - **Ours:** rows of text names plus coloured squares holding "?" or "✓" (`Patch.client.luau` ~L1629).
   - **References:** a grid of **pet renders** on rarity-coloured square tiles, with undiscovered pets as a **dark silhouette** of the real pet shape and the name "???", plus a large detail card and a rewards box (R2, R5, `sab_pick.jpg`).
   - This is the single biggest "not comparable".
2. **The red alarm vignette paints over the HUD.**
   - `alarmGui.DisplayOrder = 3` is above the HUD (`gui.DisplayOrder = 1`). While carrying, Shop, Index, the candy count and the timers all turn washed-out pink (OURS-1, OURS-3).
   - In SAE the HUD stays crisp and saturated above every effect (R1).
3. **The currency is small, pale and unanchored.**
   - **Ours:** "176" is about 0.04h, salmon or green, with a blurry candy glyph and a "+4/s" crammed against it (OURS-2, OURS-3).
   - **SAE:** "$55.8Qa" is about **0.055h**, Montserrat/Gotham Black Italic in saturated green #44FF2F with a thick **black** stroke, next to a real 3D cash-stack icon. A cyan speed line sits above it, and the rate is never on the HUD (R1, `sae_currency_crop.png`).
4. **The Shop and Index buttons look different.**
   - **Ours:** glossy pills, Fredoka text, and icons that are barely visible (the Index icon is missing in OURS-1).
   - **SAE:** **flat rectangles** with a radius of about 12%. Fills are saturated lime #44FF00 (s) and cyan #0EF3FF (s) with a darker 1.5-2 px stroke, a crisp white 3D-style icon on the left 30%, and a white Gotham-Black label with a black stroke (`sae_leftbtn_crop.png`). GAG uses the same rectangle (R6).
5. **The objective is a dark navy box at the top centre, 2 lines plus a zone line** (all OURS).
   - SAE shows the objective as **floating text with no box**, and the zone name only when it changes (R1 and REFERENCES.md h_0346).
   - Nothing permanent sits at the top centre.
6. **There are too many always-on elements.**
   - **Ours: 14.** Shop, Index, Home, Settings, objective title, objective subline, zone line, scythe line, carry line, candy, rate, King timer, Spooky timer, Midnight timer. Plus "Zone quests", and RUN!! / Drop while carrying.
   - **SAE: 9.** Shop, Index, toggle, 3 right icons, speed, money, moon timer. GAG has 7 (R6). SAB has 4 (`sab_pick.jpg`).
7. **Ours has 3 coloured timer lines at the bottom-right** (King orange, Spooky purple, Midnight white).
   - SAE has **one** line: a moon icon plus "in 2m 29s" (R1).
   - Events show in SAE as **icons with timers** in a boost tray, not as sentences.
8. **Ours has no right icon column.**
   - SAE has 3 square, single-colour icon tiles (egg red #FF0606 (s), paw orange #FF8817 (s), trophy gold) at x 0.948-0.99 (R1).
   - Our "Zone quests" text pill plays this role but is text-first and sits in the mobile thumb zone (OURS-2).
9. **The panel skin is different.**
   - **Ours:** charcoal body, orange rim, cobweb, tilted title, purple X.
   - **SAE:**
     - Near-black navy body #1D1B29 (s) with darker inset wells #10111A (s).
     - A **straight white Gotham-Black title overlapping the top-left edge**.
     - A **red square X** #E90006 (s) with a white inner border, overlapping the top-right corner (R2, R3).
     - The Shop alone adds a lime striped header strip (R4).
10. **RUN!! and Drop sit side by side at mid-screen** (y 0.70-0.76, OURS-1), and RUN!! looks like a button.
    - SAE puts RUN!! as a **status pill at the top centre** (y 0.01-0.08) and Drop alone at the bottom centre (y 0.82-0.90) (REFERENCES.md h_1036).
11. **Ours has no claim badges.**
    - SAE shows a red circle with a **count** on Index ("7") and on CLAIM ALL whenever rewards wait (R3).
    - Ours has only a "!" on Shop (OURS-3).
12. **Text colour and stroke differ.**
    - **Ours:** pastel fills (salmon "Rusty Scythe", lilac "Spooky Hour") with a thin dark-purple 2.5 px stroke. On the bright green ground this reads as muddy (OURS-1, OURS-2).
    - **References:** white or **fully saturated** fills, always with a **pure black** stroke of 2.5-3.5 px (R1, R5, R6).
13. **The Shop has a different look.**
    - SAE Shop cards are **big 3D renders on purple-to-magenta gradient cards** with a full-width green price bar (#58FF00 (s)) and a "BEST VALUE!" tag (R4). Event shops use the same 3x2 card grid (`saeg_001016.png`).
    - Our shop cards (per REFERENCES-2) are text-led.
14. **Ours has no boost tray.**
    - SAE shows each active boost as a 0.04w icon with an "x2" badge and an mm:ss timer under it, at bottom-right above the moon timer (R1).
    - Our Spooky x2 exists only as a sentence.
15. **Ours has no hotbar or quick-equip strip.**
    - SAE keeps a slim bottom-centre hotbar of dark translucent squares, 0.032w each (R1).
    - Lowest priority: only add one if we have tools to switch. Otherwise leave the bottom centre empty for Drop and toasts.

## 2. Global rules

1. **ScreenGuis and DisplayOrder.**

   | ScreenGui | DisplayOrder | Notes |
   |---|---|---|
   | `AlarmFX` (vignette and flash) | 2 | `ScreenInsets = None` |
   | `HUD` | 10 | `ScreenInsets = CoreUISafeInsets` |
   | `Panels` | 11 | |
   | `Toasts` | 12 | |
   | `Reveal` / `Hatch` | 13 | |

   Nothing that tints the screen may sit above `HUD`.
2. **Font tokens.**
   - `F_LABEL = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Heavy)` for every label and button.
   - `F_NUM = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Black, Enum.FontStyle.Italic)` for every number (currency, timers, counts). This matches SAE's italic numbers.
   - `F_SHOUT = Enum.Font.LuckiestGuy` only for RUN!!, NEW!, and the hatch name.
   - **Drop FredokaOne.** The SAE, GAG and SAB references all use a Gotham/Montserrat-style heavy sans. Only PS99 is Fredoka-like.
3. **Text stroke.** `UIStroke` with `ApplyStrokeMode = Contextual`, `Color = #000000`, `LineJoinMode = Round`.
   - Thickness 3 on text 0.04h or taller, 2 on text 0.025-0.04h, 1.5 below that.
   - **Never use pastel text.** Text is white or a token from item 4.
4. **Colour tokens.**

   | Token | Hex | Use |
   |---|---|---|
   | SHOP | #44FF00 (s) | Shop button. Stroke #1F5A00 |
   | INDEX | #0EF3FF (s) | Index button. Stroke #00626B |
   | RED | #E90006 (s) | Close button, Drop |
   | RED_DARK | #7D0002 | RUN!! pill |
   | CLAIM | #08E80B (s) | Claim buttons. Stroke #00590A |
   | CANDY | #FFB21A | Candy number |
   | SPEED | #00FFCE (s) | |
   | BODY | #1D1B29 (s) | Panel body |
   | WELL | #10111A (s) | Inset wells |
   | CARD | #343440 (s) | Cards |
   | BAR_FILL | #00FD31 (s) | Progress bar fill |
   | BAR_TRACK | #0E0F16 (s) | Progress bar track |
   | BADGE | #FF1E1E | Notification badges |

   - **Why CANDY is orange-gold:** our ground is lime, so a green number would vanish. SAE gets away with green money only because its number is very large and has a black stroke.
5. **Icons.** Use **ImageLabel art only. No emoji anywhere** on the HUD or in panels.
   - Style: chunky 3D-render icons (cart, book, paw, trophy, candy, moon, crown, bat, house, gear) with a 2-3 px dark outline baked into the PNG.
   - Make them with `generate_texture`, or by snapshotting our own models in a ViewportFrame and uploading the result.
   - Every icon has a `UIAspectRatioConstraint` of 1.
6. **Buttons.** All buttons share one build, `makeButton(fill)`:
   - **Fill:** `BackgroundColor3 = fill`, `AutoButtonColor = false`.
   - **Shape and stroke:** `UICorner.CornerRadius = UDim.new(0.12, 0)`. `UIStroke` with `ApplyStrokeMode = Border`, `Thickness = 2.5`, `Color = fill:Lerp(black, 0.6)`.
   - **Gradient:** a `UIGradient` with `Rotation = 90` and `Color = ColorSequence.new(fill:Lerp(white, 0.18), fill)`. **No gloss overlay and no 4 px drop base.** SAE is flat.
   - **Press feel:** a `UIScale` child for squash: hover 1.06, down 0.92, up 1.0 Back 0.15 s (HOWTO §3).
7. **Mobile.**
   - Keep x > 0.72 and y > 0.62 clear.
   - Under touch, the left buttons become icon-only squares (the existing `mobile()` logic).
   - A root `UIScale = clamp(vpY/720, 0.75, 1.15)` applies only to Offset leftovers.

## 3. Always-on HUD (target: 9 elements)

All items below are children of `HUD`.

| # | Element | AnchorPoint | Position | Size | Build |
|---|---|---|---|---|---|
| H1 | **LeftMenu** Frame | (0,0) | (0.010, 0.395) | (0.10, 0.20) | `UIListLayout`, vertical, Padding `UDim.new(0.06,0)`, transparent |
| H1a | **Shop** button | n/a | LayoutOrder 1 | (1, 0.34) + `UIAspectRatioConstraint` 2.6 | `makeButton(SHOP)`. Icon `ImageLabel` Pos (0.05,0.12) Size (0.28,0.76). Label Pos (0.36,0.1) Size (0.60,0.80), `F_LABEL`, white, `TextScaled`, stroke 2.5. |
| H1b | **Index** button | n/a | LayoutOrder 2 | same as H1a | `makeButton(INDEX)` with a book icon, and a **count badge** (§3.1) = number of claimable Index rewards. |
| H1c | **Base** (home) | n/a | LayoutOrder 3 | (0.62, 0.22), aspect 2.6 | Smaller purple #8A3CF0 button with a house icon and "Base". This is the SAE slot that holds the Slow-Mode toggle. |
| H2 | **RightColumn** Frame | (1,0) | (0.992, 0.36) | (0.05, 0.20) | Vertical list, Padding `UDim.new(0.04,0)`. |
| H2a | **Pets** tile | n/a | n/a | `Size = UDim2.fromScale(1,1)`, `SizeConstraint = RelativeYY` → 0.073h square, aspect 1 | Fill paw-orange #FF8817 (s), stroke 2.5 #000, corner 0.14. Paw icon fills 80%. No label (SAE). Opens the equipped-pets list. |
| H2b | **Quests** tile | n/a | n/a | same as H2a | Fill gold #FFC21A, scroll/trophy icon. Replaces the "Zone quests" pill. Count badge when a quest is done. |
| H3 | **Currency** stack | (0,1) | (0.006, 0.985) | (0.30, 0.13) | Vertical list, bottom-aligned (rows below). |
| H3a | Carry row | n/a | n/a | height 0.30 of the stack (about 0.04h) | Scythe icon (0.04h) + "1/2" in white `F_NUM`, stroke 2. Shows the scythe name only on hover or tap, never always on. |
| H3b | **Candy** row | n/a | n/a | height 0.45 (about **0.058h**) | 3D candy icon (0.058h square) + `F_NUM` CANDY #FFB21A, stroke 3.5 #000, `TextXAlignment Left`. Rolls up with a `NumberValue` tween of 0.5 s Quad. The icon pops via `UIScale` 1→1.25→1 on gain. **Remove the "+4/s" rate from the HUD.** |
| H4 | **Phase timer** | (1,1) | (0.990, 0.985) | (0.20, 0.045) | Moon (or sun) ImageLabel 0.045h + "Midnight 1:08" in white `F_NUM`, stroke 2.5. Turns RED #FF2A2A and pulses during the last 10 s. **This is the only timer line.** |
| H5 | **Boost tray** | (1,1) | (0.990, 0.925) | (0.30, 0.075) | Horizontal list, right-aligned, Padding 0.01. Each boost (§3.2) is an icon tile 0.055h with an "x2" badge and an mm:ss timer under it. **King countdown** = crown icon. **Spooky Hour** = bat icon. Potions = potion icons. |

**Removed from the always-on HUD**

| Removed | What happens to it |
|---|---|
| Objective box | Goes to §4.1 floating text. |
| Zone line | Goes to §4.2, shown on change only. |
| Settings gear | Becomes a 0.045h dark circle in a `TopIcons` ScreenGui with `ScreenInsets = TopbarSafeInsets`, right of the Roblox buttons, as SAE has it (R1 top-left). |
| "+X/s" rate, King line, Spooky line, "Zone quests" pill | Removed. |
| Scythe-name line | Becomes the H3a carry row. |

**3.1 Count badge** (shared by Index, Quests and CLAIM ALL)
- Frame with `AnchorPoint` (0.5,0.5) at `Position` (1, 0.05) of its parent.
- `Size = UDim2.fromScale(0.42,0.42)`, `SizeConstraint = RelativeYY`.
- `BADGE` fill, `UICorner` (1,0), `UIStroke` 2 white.
- Text: white `F_NUM` count, or "!".
- Hidden at 0. On increment, bounce with `UIScale` 1.3→1 Back 0.25 s.

**3.2 Boost tile**
- Tile: 0.055h square, dark fill #000000 at `BackgroundTransparency` 0.45, corner 0.2, stroke 1.5 #000.
- Icon fills 85% of the tile.
- Multiplier badge "x2": top-right, `F_NUM` #FFE14A, stroke 2.
- Timer: under the tile, `F_NUM` white 0.022h, stroke 1.5.
- When 10 s remain, blink the tile at 2 Hz.

## 4. Transient HUD

1. **Objective.**
   - `TextLabel` with `AnchorPoint` (0.5,0) at (0.5, 0.085), Size (0.55, 0.050).
   - White `F_LABEL` with stroke 3 #000. **No background.**
   - An optional sub line ("40 studs") at 0.028h in white at 80%.
   - Hide while a panel is open.
2. **Zone name.**
   - At (0.5, 0.145), Size (0.40, 0.045), shown on zone change only.
   - Enter: fade and scale 0.8→1 (0.25 s Back). Hold 2.5 s, then fade out 0.4 s.
   - Text in the zone colour with stroke 3 #000, over a horizontal black gradient band (`UIGradient` transparency 1 → 0.55 → 1) of size (0.5, 0.05).
3. **RUN!!**
   - Pill with `AnchorPoint` (0.5,0) at (0.5, 0.012), Size (0.20, 0.065).
   - Fill RED_DARK #7D0002, `UIStroke` 3 #C0101A, corner 0.5.
   - Text: white `F_SHOUT`, stroke 3 #000.
   - Pulse `UIScale` 1↔1.06 (0.4 s Sine, repeats). It is a status, so make it non-clickable.
4. **Drop.**
   - `AnchorPoint` (0.5,1) at (0.5, 0.905), Size (0.13, 0.072), aspect 2.6.
   - `makeButton(RED)` with a trash icon and "Drop".
   - Shown only while carrying.
5. **Toasts.**
   - Bottom centre. The first toast sits with `AnchorPoint` (0.5,1) at (0.5, 0.815). Each new toast pushes older ones up by 0.045. At most 3.
   - Text only: white `F_LABEL` 0.034h, stroke 2.5 #000. The key word is in a token colour (pet name in its rarity colour, failures in #FF3030).
   - In: slide up 0.02 and scale 0.85→1 (0.2 s Back). Hold 2.5 s, then fade out 0.3 s.
6. **"+X candy" pop.**
   - Spawns at the world pickup's screen point.
   - `F_NUM` CANDY 0.04h, stroke 2.5.
   - Tweens to the H3b icon (0.45 s Quad In), then pulses the counter.
7. **Big-moment banner.** "ALL PUMPKINS RESET!" and "NEW PET!" sit at (0.5, 0.22), size 0.07h, in `F_SHOUT` white with stroke 4. This is unchanged and already correct per REFERENCES-2 §4.

## 5. Panel template (SAE)

`makePanel(title, w, h, opts)`:

1. **Root.**
   - Frame with `AnchorPoint` (0.5,0.5) at (0.5, 0.52), Size (w, h), plus `UIAspectRatioConstraint` w·16/(h·9).
   - Body: `BackgroundColor3 = BODY #1D1B29`, `UICorner` 0.035, `UIStroke` Border 3 #000.
   - **Remove** the orange rim, the cobweb and the tilt.
2. **Title.**
   - `TextLabel` with `AnchorPoint` (0,0.5) at (0.02, 0.0), Size (0.45, 0.13).
   - White `F_LABEL`, `TextXAlignment Left`, stroke 3.5 #000.
   - It sits **on** the top edge, half outside the body (R2 "Pet Index").
3. **Close.**
   - `TextButton` with `AnchorPoint` (0.5,0.5) at (0.985, 0.02), `Size = UDim2.fromScale(0.10,0.10)`, `SizeConstraint = RelativeYY`, aspect 1.
   - Fill: `UIGradient` 90° from #FF0201 to #D50A0D (s). Corner 0.12.
   - Strokes: an inner `UIStroke` 2 #FFFFFF, and an outer black stroke 2 on a wrapper frame.
   - Text "X" in white `F_LABEL`, stroke 2 #000.
4. **Header strip** (Shop only, R4).
   - Frame Size (1, 0.13) at the top. `UIGradient` from #5EFE41 to #30F01E (s).
   - Diagonal shine: a child frame with a `UIGradient` of white transparency stripes at Rotation 60.
   - With a strip, the title sits inside it at (0.02, 0.065).
5. **Wells.** Inner group boxes use `WELL #10111A`, corner 0.04, stroke 2 #2B2B37.
6. **Open and close.**
   - Open: `UIScale` 0.85→1, 0.2 s Back Out. Close: 0.12 s Quad In, then hide.
   - No dim (SAE and GAG have none).
   - While a panel is open, hide H3, H4, H5 and the objective. Keep H1 and H2 so players can switch panels.
7. **Sizes.**
   - Index (0.58, 0.66)
   - Shop (0.56, 0.62)
   - Pets list (0.24, 0.50), docked right with `AnchorPoint` (1,0.5) at (0.94, 0.5), the SAE "Growing Eggs" style
   - Settings (0.36, 0.55)

**Shop cards** (R4, `saeg_001016.png`):
- Grid of 3 columns, `CellSize` (0.31, 0.62) of the well.
- Card: purple gradient #4C26B3 → #E02AE4, stroke 2.5 #6858EE, corner 0.06.
- A big 3D render (ViewportFrame of the item, or an image) fills the top 65%.
- Name: white `F_LABEL` over the render.
- Price bar: full width at the bottom, `makeButton(#58FF00)` with a Robux or candy icon + `F_NUM` price.
- Section headings in a saturated colour with a stroke ("-- SCYTHES --" in #E02AE4 (s)).

## 6. Index (the big one)

### 6.1 Layout

The panel is `makePanel("Pet Index", 0.58, 0.66)`. Positions are fractions of the panel.

| Part | Position / Size | Build |
|---|---|---|
| **Finish tabs** (left column) | (0.025, 0.08) / (0.16, 0.74) | Vertical list of 5 buttons, one per finish: Plain, Glowing, Ghostly, Candy, Cursed. This mirrors SAB's Normal / Gold / Diamond / Rainbow tabs. Each is `makeButton(#5A5A6A)`; the selected tab uses the finish colour, locked ones are greyed and show a lock icon until brewing is unlocked. Each tab shows a small "7/15" under its name. |
| **Grid well** | (0.205, 0.08) / (0.48, 0.74) | `ScrollingFrame` in WELL. `UIGridLayout`: `CellSize = UDim2.fromScale(0.225, 0)`, `CellPadding = UDim2.fromScale(0.03, 0.03)`, 4 columns, `SortOrder = LayoutOrder` (by rarity, then income). Put a `UIAspectRatioConstraint` 1 under the `UIGridLayout`. `AutomaticCanvasSize = Y`, `ScrollBarThickness` 6, scroll bar colour #5A5A6A. |
| **Detail card** | (0.705, 0.08) / (0.27, 0.50) | CARD #343440, corner 0.06, stroke 2 #8A8A99. Contents: a big rotating ViewportFrame (0.9 × 0.62), the name (white `F_LABEL`), the rarity word in the rarity colour, and "+X candy/s" in #2EE84A. |
| **Rewards box** | (0.705, 0.61) / (0.27, 0.21) | WELL with stroke 2.5 #1FCF3A. Holds "Rewards:", 2 reward chips (icon + amount, with a green check once claimed) and a button: **CLAIM!** `makeButton(CLAIM)`, **CLAIMED!** grey #3A3A3A with #D0D0D0 text, or **LOCKED** grey #3A3A3A with a lock icon. |
| **Progress bar** | (0.205, 0.855) / (0.48, 0.09) | Track BAR_TRACK, corner 0.5, stroke 2 #000. Fill BAR_FILL with a `UIGradient` 90° lighter top. Book icon overlapping the left end (as SAE). Centred text "Unlocked 5/15" in `F_NUM` white, stroke 2.5. **Milestone pips** sit on the bar at each milestone (§6.4): small gift icons, coloured once reached, with a badge when claimable. |
| **CLAIM ALL** | (0.705, 0.855) / (0.27, 0.09) | `makeButton(CLAIM)` "CLAIM ALL" with a count badge (R3). Hidden when there is nothing to claim. |

### 6.2 Tile

A Frame named `Tile_<petId>`.

1. **Base.**
   - `BackgroundColor3` = rarity colour (§6.5).
   - `UICorner` 0.12. `UIStroke` Border 2.5 #000.
   - A `UIGradient` at Rotation 90 that lightens the top (transparency 0.0 → 0.25, with `Color` white → rarity).
2. **Render.** `ViewportFrame` at Position (0.06, 0.16), Size (0.88, 0.80), `BackgroundTransparency` 1.
3. **Name.** At (0.04, 0.02), Size (0.92, 0.18). White `F_LABEL` with stroke 1.5. Shows the pet name, or **"???"** when locked.
4. **Locked state (SAE look, R2).**
   - Keep the rarity tile colour.
   - Set `ViewportFrame.ImageColor3 = rarity:Lerp(Color3.new(0,0,0), 0.8)`. This gives a dark tinted silhouette of the real model.
   - For the PS99 look (R5), use pure black `Color3.new(0,0,0)` and add a white "?" label (`F_LABEL`, stroke 2, 0.4 of the tile) at the centre.
   - Pick one look and use it everywhere. **Recommendation: SAE tinted**, because it keeps the rarity readable.
5. **Discovered, not claimed.** A count badge "!" at the top-right. The `UIStroke` becomes white #FFFFFF and pulses `Transparency` 0↔0.5 every 0.8 s.
6. **Selected.** `UIStroke` #FF2A2A with Thickness 3.5 (SAE red outline, `saee_0450.png`). This fills the detail card.
7. **Outline around the pet** (optional, SAE look in `saee_0450.png`). A second ViewportFrame behind the first, holding the same model clone, `ImageColor3` #000000, Size ×1.07, centred. It reads as a 2 px black outline. Use it on discovered tiles only.
8. **Finish tabs.** When a finish tab other than Plain is selected, tint the discovered render with the finish's colour by setting `ViewportFrame.ImageColor3 = finishColor`, and add a small finish icon at the bottom-right.

### 6.3 ViewportFrame setup

1. **Model access.** The client cannot read `ServerStorage.PetModels`.
   - At server start, clone each model into `ReplicatedStorage.IndexModels`.
   - In each clone: strip scripts, sounds and particles, set `Anchored = true` and `CanCollide = false`, and set `PrimaryPart`.
2. **Code.**

   ```lua
   local function frameModel(vpf: ViewportFrame, model: Model, yaw: number)
       local m = model:Clone(); m.Parent = vpf
       local cam = Instance.new("Camera"); cam.FieldOfView = 30; cam.Parent = vpf; vpf.CurrentCamera = cam
       vpf.Ambient = Color3.fromRGB(170, 170, 170); vpf.LightColor = Color3.new(1, 1, 1)
       vpf.LightDirection = Vector3.new(-1, -1.5, -1)
       local cf, size = m:GetBoundingBox()
       m:PivotTo(CFrame.Angles(0, math.rad(yaw), 0) * (cf:Inverse() * m:GetPivot())) -- box centre to origin, then yaw
       m:SetAttribute("BasePivot", m:GetPivot())
       local r = size.Magnitude / 2
       local dist = r / math.tan(math.rad(cam.FieldOfView / 2)) * 1.08   -- 8% margin; small voxel pets fill the tile
       cam.CFrame = CFrame.lookAt(Vector3.new(0, r * 0.35, dist), Vector3.new(0, -size.Y * 0.03, 0))
       return m
   end
   ```

3. **Grid tiles are static.** They use `yaw = -25` (three-quarter view facing the camera). **Do not rotate the grid tiles**, because many viewports updating every frame is costly.
4. **Detail card rotates.** It turns once per 8 s: on `RenderStepped`, call `m:PivotTo(CFrame.Angles(0, os.clock() * math.pi / 4, 0) * m:GetAttribute("BasePivot"))`. Disconnect when the panel closes.
5. **Hover.** Optionally rotate a grid tile only while it is hovered.
6. **Build lazily.** Create the viewports for a tab the first time it is shown. `Destroy` clones when the tab changes.
7. **Tiny pets.** For pets with a bounding radius under 1.5 studs, scale the model first with `m:ScaleTo(1.5 / r)` so the lighting matches.

### 6.4 Rewards

These are tunable. Run them through `giant/scene/econ-sim.luau` before shipping.

**The references:**
- **SAE:** every pet has its own Rewards box (cash plus permanent +speed) with a CLAIM! button. Each zone page has a progress bar that unlocks an item when complete (the bat icon in R2/R3). A global CLAIM ALL carries a count badge, and the Index button shows the same count (R3).
- **SAB:** each mutation tab has one milestone bar, "Collect Normal Brainrots for +0.5x Base Multi" (`sab_pick.jpg`).
- **PS99:** a "Collected 190/549" counter (R5). Rewards are claimed from a grid of tiles marked Claimed! / Claim! / Locked (`ps99_000024.png`, the Rank Rewards pattern).

**Proposal** (15 pet types × 5 finishes):

| Trigger | Reward | Claim |
|---|---|---|
| First discovery of a pet type (Plain) | Candy = 600 × that pet's income (10 min of it), min 250 | Per-tile CLAIM!, or CLAIM ALL |
| Discovery of a finish variant | Candy = 300 × income × finish multiplier | Same |
| 3 / 15 types | +5% candy, permanent | Milestone pip on the bar |
| 6 / 15 | Exclusive "Ghost Pup" trail (cosmetic) | Pip |
| 10 / 15 | +10% candy (+15% total) | Pip |
| 15 / 15 | "Pumpkin Master" overhead title + +10% (total +25%) | Pip, with a big-moment banner |
| All 15 of one finish (a finish tab) | +0.25x candy multi, SAB-style. Shown as that tab's own bar: "Collect Glowing pets for +0.25x Candy 4/15" | Tab bar |
| All 5 finishes of one type | +10% on that type's income (already in code, keep it) | Automatic. Show "+10%" on the tile |

**Flow on discovery:**
1. A toast: "NEW PET! **Ghosty** added to your Index" (the name in its rarity colour).
2. The Index button badge increments, and the Index button bounces once.
3. On claim: the reward chips fly to the counter (§4.6), the tile stroke returns to black, and the button reads CLAIMED!.

### 6.5 Rarity colours

These are tile backgrounds, saturated like SAE (R2: Common #ADAFAF (s), Rare blue #004AFE (s), Epic magenta #FE48FD (s), Legendary yellow #FEFD00 (s), Mythic purple #8600B6 (s)).

| Rarity | Tile colour | Text colour (rarity word, toasts) |
|---|---|---|
| Common | #ADAFAF | #E6E6EE |
| Uncommon | #2EE84A | #5CFF6E |
| Rare | #1E6BFF | #4AA8FF |
| Epic | #C33CFF | #D86BFF |
| Legendary | #FFD400 | #FFD84A |
| Mythic | #FF2E63, plus a rainbow `UIGradient` on the stroke rotating once per 3 s (HOWTO §2) | #FF5A86 |

- Replace the colours in `Config.Rarities` (`PatchConfig.luau` ~L402) with these. Today's (200,200,210) / (90,220,90) / ... are too pale to read as tiles.

## 7. Build order (what to do first)

1. §2.1: move the alarm vignette under the HUD. This is 1 line and removes a huge amount of mush.
2. §6 Index with ViewportFrame tiles, silhouettes, the detail card and claim rewards.
3. §3 H3: the big candy counter, plus deleting the rate, King and Spooky lines. §3 H4/H5: one timer plus the boost tray.
4. §2.6 `makeButton` flat style plus real icons, then the Shop and Index buttons, then the right column.
5. §5 panel template: rebuild Shop on the card grid (R4).
6. §4 transient layout: objective with no box, RUN!! at the top, Drop at the bottom, toasts above Drop.

**Done means:** a capture of our HUD placed next to R1, and of our Index next to R2, at the same size. A blind judge should not be able to say which one is the "cheap" game.
