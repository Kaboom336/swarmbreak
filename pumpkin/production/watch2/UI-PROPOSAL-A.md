# UI Proposal A: copy Steal an Egg's UI grammar, recoloured for Halloween

**Angle:** copy SAE closely. That means its layout, flat rectangle buttons with image icons, counters, panel frames, fonts and strokes. Only the hue changes, to Halloween: pumpkin orange, witch purple and slime lime on a near-black purple body. SAE's red X, green price bar and purple-to-magenta card stay as they are, because they already read as Halloween.

**Evidence compared side by side**
- **Ours** (1509x863, folder `tool-results/`):
  - HUD `...1791690404161`
  - Shop `...1791690430678`
  - Index `...1791690085124`
  - Hatch card `...1791699643555`
  - Pen and HUD `...1791692064542`
- **SAE** (854x480, folder `refs/aspects/ui/v2/`):
  - R1 `01-sae-hud-clean`
  - R2 `02-sae-index`
  - R3 `03-sae-index-claimall`
  - R4 `04-sae-shop`
- **GAG**: R6 `06-gag-hud-panels`.

**Units**
- All values are screen Scale unless they say "of panel".
- Stroke px are at 1080p.
- Fonts:
  - `F_LABEL` = GothamSSm Heavy (already in `Config.Fonts`).
  - `F_NUM` = `Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Black, Enum.FontStyle.Italic)`.

## Halloween token sheet

These replace `Config.UI` and `Palette`. Each SAE colour is listed with the Halloween colour that replaces it.

| Token | SAE | Ours (new) | Stroke |
|---|---|---|---|
| SHOP button | lime #44FF00 | pumpkin #FF8A00 | #6B3000, 2.5 px |
| INDEX button | cyan #0EF3FF | witch purple #A13BFF | #3D0A73, 2.5 px |
| BODY (panel) | #1D1B29 | #1E1530 | #000000, 3 px |
| WELL | #10111A | #110C1C | #2E2340, 2 px |
| CARD | #343440 | #2E2640 | #8A7AA8, 2 px |
| Shop header strip | #5EFE41→#30F01E | #FFA31A→#FF6A00 | none (body stroke covers it) |
| Close X | #FF0201→#D50A0D | unchanged | inner #FFFFFF 2 px, outer #000 2 px |
| Price / CLAIM | #58FF00 / #08E80B | slime #5CFF1F / #08E80B | #1F5A00, 2.5 px |
| Shop card | #4C26B3→#E02AE4 | unchanged | #6858EE, 2.5 px |
| CANDY number | (money green #44FF2F) | #FFB21A | #000000, 3.5 px |
| BADGE | #FF1E1E | unchanged | #FFFFFF, 2 px |
| Right tiles | egg red #FF0606, paw #FF8817, trophy gold | pets #FF8817, quests #FFC21A, daily #A13BFF | #000000, 2.5 px |

Every piece of text is white or a token above, with a **pure black** `UIStroke`. Today's stroke is `Color3.fromRGB(20,10,30)` in `stroke()`. Change it to #000000.

## 1. The 20 most visible differences, worst first

### 1. Icons are invisible Roblox core-UI glyphs, not chunky 3D icons
- **Ours:** `Config.UI.icons` points at `rbxasset://textures/ui/TopBar/inventoryOff.png`, `PlayersTab.png` and `StarIcon.png`. These are thin, grey line art at about 0.02h, so the Index button has no visible icon at all.
- **SAE:** a fat white-and-colour 3D cart or book with a dark outline baked in, about 0.045h, filling the left 30% of the button (R1, R4).
- **Fix:** make 10 PNG icons at 256x256 with a transparent background and a 6 px dark outline baked in, in a chunky 3D-render style. Use `generate_texture`, or snapshot our own models in a ViewportFrame, then `upload_image`. The icons are:
  - cart (Shop)
  - spellbook (Index)
  - gift (Daily)
  - paw (Pets)
  - scroll (Quests)
  - candy (currency)
  - moon (timer)
  - crown (King)
  - bat (Spooky)
  - gear (Settings)
- Each icon is an `ImageLabel` with `UIAspectRatioConstraint` 1 and `ScaleType = Fit`.
- No emoji anywhere. The `"🔊"` in the shop mute button and `" 🍬/s"` in `countHit` both go.

### 2. The left buttons are 60% too big and 3 deep
- **Ours:** Shop, Index and Daily. Each is 0.152w x 0.064h with a 0.05h label. The stack covers x 0.011-0.163, y 0.40-0.62.
- **SAE (R1):** 2 buttons, x 0.012-0.108 (0.096w x 0.0625h), a label about 0.032h tall, then a small toggle row.
- **Fix:**
  - `leftBar`: Position (0.012, 0.40), Size (0.096, 0.15).
  - Buttons are 1 x 0.42 of the bar, at y 0 and 0.50, with `UIAspectRatioConstraint` 1.55 (SAE is 82x30 px, which is 2.73 in screen px because the screen is 16:9).
  - Icon: Pos (0.04, 0.08), Size (0.30, 0.84).
  - Label: Pos (0.36, 0.14), Size (0.60, 0.72), `F_LABEL` white, black stroke 2.
  - **Daily leaves the left bar** and becomes a right-column tile (#4).

### 3. Button faces are gradient pills with large text, not SAE flat rectangles
- **Ours:** the gradient runs `fill:Lerp(white, 0.18)` → fill, so they read glossy. The corners are about 0.12, but the stroke is a dark ink, not a shade of the fill.
- **SAE:** flat fill, a 1.5-2 px stroke in a darker shade of the same hue, and corners of about 4 px at 480p (0.10).
- **Fix** in `chunky()`:
  - Change the gradient to `fill:Lerp(white, 0.08)` → fill. That is almost flat.
  - `UICorner` `UDim.new(0.10, 0)`.
  - Outline 2.5 px, `fill:Lerp(black, 0.55)`.
  - Add a 1 px inner highlight: a child Frame (1, 0.12) at the top, white, `BackgroundTransparency` 0.75.
  - Keep the `UIScale` squash.

### 4. There is no right icon column
- **Ours:** none. Settings and ADMIN float at the top-right.
- **SAE (R1):** 3 square single-colour tiles at x 0.948-0.990, y 0.36 / 0.46 / 0.565, each 0.075h with no text.
- **Fix:** add a `RightColumn` Frame:
  - AnchorPoint (1, 0), Pos (0.992, 0.36), Size (0.05, 0.30). `UIListLayout` vertical, Padding (0, 0.025).
  - Each tile is `UDim2.fromScale(1, 1)` with `SizeConstraint` RelativeXX, corner 0.14, stroke 2.5 #000.
  - The icon fills 78% of the tile.
  - Tiles: **Pets** #FF8817 (paw), **Quests** #FFC21A (scroll, replaces the "Zone quests" pill), **Daily** #A13BFF (gift).
  - Each tile gets a count badge.

### 5. The panel skin is white, but SAE is dark with studs
- **Ours:** white body, orange rim, gradient header bar, title inside it, grey cards.
- **SAE (R2, R4):** near-black body #1D1B29 with a faint stud pattern, a 3 px black outer stroke, a corner of about 0.03, and darker inset wells.
- **Fix** in `panel()`:
  - Body #1E1530, `UICorner` 0.03, `UIStroke` 3 #000.
  - Add a tiled `ImageLabel` stud texture: a 64x64 stud PNG from `generate_texture`, `ScaleType = Tile`, `TileSize` (0, 48, 0, 48), `ImageTransparency` 0.88, `ImageColor3` #FFFFFF. This is the "stud block" style Zion asked for.
  - Delete the orange rim.
  - Inner groups use WELL #110C1C with corner 0.04.

### 6. Panel titles sit inside a coloured header, but SAE hangs the title over the frame edge
- **Ours:** "Shop!" and "Index" sit inside an orange or purple 0.075h header strip, with a faint icon.
- **SAE Index (R2, R3):** a big white "Pet Index" with a black 3.5 px stroke, overhanging the top-left edge by about half its height and placed outside the frame. The Shop alone has a lime striped strip with the title inside it (R4).
- **Fix:**
  - **Index and Settings:** no header. The title `TextLabel` uses AnchorPoint (0, 0.5), Pos (0.0, 0.0) of panel, Size (0.40, 0.13), `F_LABEL` white, stroke 3.5 #000, `TextXAlignment Left`.
  - **Shop:** header strip (1, 0.13) with gradient #FFA31A→#FF6A00 at Rotation 90. A child stripes Frame has a `UIGradient` with transparency keypoints 0.85/1 alternating every 0.08, Rotation 60.
  - The title "Shop" (no "!") sits at Pos (0.02, 0.065) with AnchorPoint (0, 0.5), white, stroke 3.
  - Remove the header icon.

### 7. The close button is a red circle, but SAE uses a red square
- **Ours:** a red circle with a black "X".
- **SAE:** a 0.0625h square, gradient #FF0201→#D50A0D, a white 2 px inner stroke plus a black 2 px outer stroke, and a white "X" with a black stroke. It overlaps the top-right corner at panel (0.985, 0.02).
- **Fix:** `closeButton()`:
  - Corner `UDim.new(0.12, 0)`, `SizeConstraint` RelativeYY, Size (0.11, 0.11) of panel, AnchorPoint (0.5, 0.5), Pos (0.985, 0.02).
  - Wrap it in a Frame that carries the black stroke.
  - Text "X" in `F_LABEL`, white.

### 8. The currency counter is tiny and weak
- **Ours:** "406" is about 0.04h, the candy glyph is about 0.025h and blurry, and "+27/s" sits under it in orange.
- **SAE (R1):** "$55.8Qa" is about 0.055h in heavy italic with a thick black stroke, next to a 0.055h 3D cash icon. The rate is never on the HUD.
- **Fix:** H3 stack:
  - AnchorPoint (0, 1), Pos (0.006, 0.985), Size (0.30, 0.13). `UIListLayout` vertical, bottom-aligned.
  - **Candy row:** 0.058h. The candy PNG icon is 0.058h square. The number is `F_NUM` #FFB21A, stroke 3.5 #000, `TextXAlignment Left`. It rolls up with a NumberValue tween, and the icon pops through `UIScale` 1→1.25→1.
  - **Carry row** sits above it at 0.04h: a scythe icon plus "0/3" in white `F_NUM`, stroke 2.
  - **Delete** the "+X/s" line.

### 9. The scythe name is always shown as text ("Rusty Scythe | Carry 0/3")
- **SAE:** item names live in the hotbar slot or in the shop. They are never a HUD sentence.
- **Fix:** keep only the carry icon and "0/3" (#8). Show the scythe as the icon only. Its name appears on hover or tap as a tooltip, or in the hotbar if one is added.

### 10. The objective is a 3-line block with a dark box at the top centre
- **Ours:** "Steal a Pumpkin!" in a navy pill, plus a "Hold E at the nest" subline, plus "Safe Zone" in green, at y 0.08-0.18. In the Index capture a second, wide 0.40w bar appears.
- **SAE (R1):** a single line of floating white text, "You earn $180B/Day offline!", at y 0.02-0.065, about 0.045h, black stroke 3, **no background**. The key value is in a token colour.
- **Fix:**
  - One `TextLabel`: AnchorPoint (0.5, 0), Pos (0.5, 0.015), Size (0.55, 0.048), `F_LABEL` white, stroke 3 #000, `BackgroundTransparency` 1, `RichText` (key word in #FFB21A).
  - The subline is dropped. Use the world arrow and prompt instead.
  - The zone name only shows on change (#14).
  - Hide the objective while a panel is open.

### 11. The timer is a purple box in the bottom-right ("Nests refill 2:24")
- **Ours:** a 0.22w x 0.047h solid purple chip with a sentence.
- **SAE (R1):** no box. A moon icon of 0.05h plus "in 3m 19s" in white italic, 0.035h, stroke 2.5, at x 0.84-0.985, y 0.935-0.98.
- **Fix:**
  - AnchorPoint (1, 1), Pos (0.99, 0.985), Size (0.17, 0.045), `BackgroundTransparency` 1.
  - A moon ImageLabel 0.045h on the left, then "Refill 2:24" in `F_NUM` white, stroke 2.5.
  - In the last 10 s the text turns #FF2A2A and pulses with `UIScale` 1↔1.08.

### 12. The Shop body is a white grid of grey text cards
- **Ours (Shop capture):** grey #C8C8D0 cards, a 0.035h tiny scythe line drawing, and 3 lines of text (name, damage, price) in a dark price box. Equipped is shown as a lime fill.
- **SAE (R4):** big purple-to-magenta gradient cards, a hero 3D render filling 65% of the card, the name over the render bottom in white with a stroke, and a full-width green price bar with a currency icon.
- **Fix:**
  - `UIGridLayout` 3 columns, `CellSize` (0.31, 0), `CellPadding` (0.025, 0.04), `UIAspectRatioConstraint` 0.95.
  - **Card:** gradient #4C26B3→#E02AE4 at Rotation 90, corner 0.06, stroke 2.5 #6858EE.
  - **Render:** ViewportFrame of the scythe at Pos (0.05, 0.04), Size (0.9, 0.62), yaw -30, tilted 20 degrees. Use `Palette.renderModel`.
  - **Name:** at (0.05, 0.56) Size (0.9, 0.14), `F_LABEL` white, stroke 2.5.
  - **Stat:** "+15 dmg", 0.07 of the card, #FFD84A, stroke 2. Use short text, not "15 damage per swing".
  - **Price bar:** Pos (0.06, 0.78), Size (0.88, 0.17). `makeButton(#5CFF1F)` with the candy icon on the left and `F_NUM` "150".
  - **Equipped card:** the price bar becomes grey #3A3A3A "EQUIPPED" with #D0D0D0 text, and a 3 px #5CFF1F card stroke.
  - **Best-value tag:** an angled yellow #FFD400 tag at the top-right, rotated 12 degrees, "BEST!" in black text.

### 13. Shop tabs and the mute button are big text slabs
- **Ours:** "Scythes" and "Upgrades" are 0.06h tabs with huge text, plus a mute speaker button inside the shop.
- **SAE (R4):** the category list is a column of **image icons with a small label under each** (Stars, Featured, Speed, Money). It sits *outside* the panel on the right, at x 0.83-0.90, y 0.30-0.70.
- **Fix:**
  - Tabs become an outside column: AnchorPoint (0, 0), Pos (1.015, 0.05) of panel, Size (0.10, 0.8).
  - Each tab is a 0.075h icon (scythe, up-arrow) with a 0.022h label under it, white, stroke 2.
  - The selected tab gets `UIScale` 1.12 and a #FFD400 label.
  - The section title is printed in the body as "-- SCYTHES --" in #E02AE4, stroke 2.5, 0.06 of panel.
  - **Remove the mute button** from the Shop. It belongs in Settings.

### 14. The zone line "Safe Zone" is always on
- **SAE:** the zone name appears only on change.
- **Fix:**
  - At Pos (0.5, 0.075), AnchorPoint (0.5, 0), Size (0.40, 0.045).
  - Text in the zone colour, stroke 3 #000, over a horizontal black band with a `UIGradient` transparency of 1 → 0.55 → 1.
  - Fade and scale 0.8→1 Back over 0.25 s, hold 2.5 s, fade out over 0.4 s.

### 15. The Index layout is a plain pastel grid, not SAE's zone, grid, detail and rewards layout
- **Ours:** a white body, a "Discovered 0/15" bar, 4 grey milestone buttons as text ("25% Candy"...), and 8x2 pastel cards with a black silhouette and "???".
- **SAE (R2, R3):**
  - Left zone art tile, then a 4x2 grid of saturated tiles in a dark well.
  - Right: a detail card (big render, name, rarity, green "$1/s").
  - A "Rewards:" box with chips and a CLAIM!/CLAIMED! button.
  - A green progress bar with a book icon and "3/86".
  - CLAIM ALL with a red count badge.
- **Fix:** follow UI-SPEC-V2 §6.1 exactly, on the dark body from #5:
  - Grid well at (0.205, 0.08) / (0.48, 0.74) of panel.
  - Detail card (0.705, 0.08) / (0.27, 0.50).
  - Rewards box (0.705, 0.61) / (0.27, 0.21) with stroke 2.5 #1FCF3A.
  - Progress bar (0.205, 0.855) / (0.48, 0.09), BAR_FILL #00FD31 on track #0E0F16, with the spellbook icon overlapping its left end.
  - CLAIM ALL (0.705, 0.855) / (0.27, 0.09).
  - The milestone text buttons become **gift pips on the bar**.

### 16. Index tiles are pale pastels
- **Ours:** pastel grey, sky blue, lilac, cream and salmon tiles with a 2 px coloured border.
- **SAE:** saturated tiles: Common #ADAFAF, Rare #004AFE, Epic #FE48FD, Legendary #FEFD00, Mythic #8600B6. Each has a **2.5 px black stroke** and a white name with a black stroke on top. A locked tile shows a silhouette tinted dark in the rarity colour.
- **Fix:**
  - Use the §6.5 rarity hexes, corner 0.12, `UIStroke` 2.5 #000.
  - Locked tiles set `ViewportFrame.ImageColor3 = rarity:Lerp(black, 0.8)`.
  - The name sits at the top: (0.04, 0.02) / (0.92, 0.18), `F_LABEL` white, stroke 1.5.

### 17. The hatch card is a flat grey-blue box with a confetti storm and a heavy blur
- **Ours:** a #6E7A8A card with a navy 4 px rim, a faint sunburst, about 60 confetti pieces across the whole screen, and a background blur of about 16 that also blurs the HUD.
- **SAE style:** the reveal sits on the same dark body. The rarity colour drives the glow, and the HUD stays crisp.
- **Fix:**
  - **Card:** 0.30h x 0.42h, centred at (0.5, 0.44). Body #1E1530, corner 0.06, stroke 3 #000, and an inner 3 px stroke in the rarity colour.
  - **Sunburst:** an ImageLabel of rays tinted in the rarity colour, rotating 20 deg/s, `ImageTransparency` 0.35.
  - **Rarity word:** in the rarity colour, `F_LABEL` 0.045h, stroke 3 #000.
  - **Name:** white `F_LABEL` 0.06h, stroke 3.5.
  - **Income:** "+69/s" in #5CFF1F `F_NUM`, stroke 3. Put the weight on a separate small grey line, #C8C8D0 at 0.03h.
  - **NEW! tag:** keep it, `F_SHOUT`, fill #5CFF1F, stroke 3 #000, rotated 12 degrees.
  - **Confetti:** cap it at 24 pieces inside a 0.6w x 0.6h box around the card.
  - **Blur:** `BlurEffect.Size` 6. Raise the HUD DisplayOrder above the reveal blur, or skip the blur while the HUD is visible.

### 18. Text strokes are thin and dark purple, not thick pure black
- **Ours:** `stroke()` uses (20, 10, 30). `makeButton` labels use a 2 px stroke. The candy "0" stroke is about 2 px.
- **SAE:** pure #000 at 2.5-3.5 px on everything.
- **Fix:**
  - `Config.UI.ink` is already black. Also set `stroke()` to #000000 and `LineJoinMode = Round`.
  - Thickness 3.5 for text 0.05h and up, 2.5 for 0.03-0.05h, 1.5 below that.

### 19. There is no boost tray
- **Ours:** boosts are sentences, or missing.
- **SAE (R1):** 5 boost icons, each 0.06h, at x 0.76-0.98, y 0.73-0.80, each with an "x2" badge and an mm:ss timer under it.
- **Fix:**
  - Tray: AnchorPoint (1, 1), Pos (0.99, 0.925), Size (0.30, 0.075), horizontal right-aligned list, Padding 0.008.
  - Each tile is 0.055h. Fill #000 at 0.45 transparency, corner 0.2.
  - The icon fills 85% of the tile.
  - Badge: "x2" in `F_NUM` #FFE14A, stroke 2, at the top-right.
  - Timer under the tile: 0.022h, white, stroke 1.5.
  - Use crown for King, bat for Spooky Hour, and the pass icons from `Config.UI.boosts`.

### 20. Settings and ADMIN are floating boxes at the top-right, and the gear is duplicated
- **Ours:** a 0.05h square gear at (0.955, 0.08), an "ADMIN" grey chip under it, and in the Index capture **two gears** stacked.
- **SAE (R1):** the gear is a small round dark icon in the **top bar**, right of the Roblox menu buttons, at x 0.13, y 0.03. Nothing else is at the top-right.
- **Fix:**
  - The gear moves to a `TopIcons` ScreenGui with `ScreenInsets = TopbarSafeInsets`, Pos (0, 0.5) from the left, Size (0, 32, 0, 32) in offset, a #000 circle at 0.4 transparency, and a white gear PNG.
  - Remove the duplicate gear.
  - ADMIN is only created when `player.UserId == Config.Admin.userId` and is only reachable from inside Settings, never on the HUD.

## 2. What to REMOVE from our HUD

1. **The Daily button** in the left stack. It becomes a gift tile in the right column (#4).
2. **The "Rusty Scythe | Carry 0/3" sentence.** Only the icon and "0/3" stay (#8, #9).
3. **The "+27/s" rate line** and the floating "+27" / "+171" text left over above it. Gain pops fly to the candy icon instead.
4. **The "Graveyard 16%" label and its 0.29w progress bar** under the currency. That progress belongs in the Index (one bar per zone, as SAE) and in the zone-change banner.
5. **The objective subline** ("Hold E at the nest" / "Swing your scythe") and the box behind the objective.
6. **The always-on "Safe Zone" line.** It shows on change only.
7. **The purple "Nests refill" box.** It becomes an icon plus text with no box.
8. **The ADMIN chip and the duplicate gear** at the top-right.
9. **The "Zone quests" text pill.** It becomes the Quests tile.
10. **The shop mute button** (the speaker) and every emoji glyph.
11. **The header icons** on panel title bars, and the "!" in "Shop!".
12. **The white panel bodies, orange rims, cobweb and tilt.**
13. **The full-screen confetti flood and the strong blur** on the hatch card.
14. Not HUD, but it competes with the HUD: the giant world "SHOP" / "SELL" sign letters that clip into the top-left and top-right corners. Set the billboard `MaxDistance` to about 60 studs, or move the signs lower so they never sit behind HUD corners.

The target always-on count is **9**, matching SAE: Shop, Index, 3 right tiles, carry, candy, timer, and the gear in the top bar. The boost tray and objective only show when they are active.

## 3. Mock layout

### Desktop (16:9). Each cell is about 0.0125w by 0.04h.

```
y   x 0.0                                  0.5                                     1.0
0.00 [R][=][gear]          "Steal pumpkins for 50 candy!"   (white, no box)
0.04
0.075                         ~~ GRAVEYARD ~~  (on zone change only)
0.10
...
0.36                                                                        +------+
0.40 +--------+                                                             | PAW  | Pets  #FF8817
     |[cart] Shop|  #FF8A00                                                 +------+
0.47 +--------+                                                             +------+
0.48 +--------+                                                             |SCROLL| Quests #FFC21A (badge)
     |[book] Index|(7) #A13BFF                                             +------+
0.55 +--------+                                                             +------+
                                                                            | GIFT | Daily #A13BFF
0.65                                                                        +------+
...
0.73                                                     [crown x2][bat x2][pot x2]
0.80                                                      4:12      0:55     9:30
0.87 [scythe] 0/3                     [ trash  DROP ]  (carrying only)
0.92 [CANDY]  989M   (#FFB21A, black 3.5)
0.985                                                              [moon] Refill 2:24
```

### Phone (touch, 19.5:9). Keep x > 0.72, y > 0.62 clear for the jump button, and x < 0.30, y > 0.65 clear for the thumbstick.

```
y   x 0.0                         0.5                          1.0
0.00 [R][=][gear]   "Steal pumpkins!" (0.04h)      [moon] 2:24
0.06 [CANDY] 989M  (0.07h)                         [crown][bat]   boost tray
0.13 [scythe] 0/3                                   4:12  0:55
...
0.30 +----+                                                 +----+
     |cart|  Shop (icon only, 0.09h square)                 |PAW |
0.40 +----+                                                 +----+
     |book|(7) Index                                        |SCRL|
0.50 +----+                                                 +----+
                                                            |GIFT|
0.60                                                        +----+
...
0.80              [ trash DROP ]  (0.5, 0.80), 0.15w, between the thumbstick and jump
0.95  (thumbstick zone)                         (jump zone)
```

**Phone rules**
- Root `UIScale = clamp(vpY/720, 0.75, 1.15)`.
- Left buttons are icon-only squares (the existing `mobile()` branch), Size (0, 0.09) with `SizeConstraint` RelativeYY.
- Right tiles are 0.09h.
- On touch the currency moves to the top-left, AnchorPoint (0, 0), Pos (0.012, 0.06), and the timer moves to the top-right, AnchorPoint (1, 0), Pos (0.99, 0.01).
- Panels use Size (0.86, 0.80) with the same internal fractions, and the shop's outside tab column folds inside as a top row.
