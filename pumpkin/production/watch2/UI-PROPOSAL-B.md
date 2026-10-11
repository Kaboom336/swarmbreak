# UI Proposal B: "pleasant and premium" (SAE stud style, PS99/GAG/SAB polish)

Arena round 2, proposer B. This is a design document only; Codex implements it in `giant/src/StarterPlayerScripts/Patch.client.luau` (plus tokens in `PatchConfig.luau`).

**Evidence I looked at**
- Ours: HUD `...-1791690404161-l4zrjk.jpg`, Shop `...-1791690430678-5366te.jpg`, Index `...-1791690085124-6omzvb.jpg`, pen+HUD `...-1791692064542-8ykgyr.jpg`, hatch card `...-1791699643555-76dq86.jpg`.
- References: `refs/aspects/ui/v2/01..06` (SAE HUD, SAE Index in two layouts, SAE Shop, PS99 Collection, GAG HUD panels).
- I fetched no new footage. The six frames already show every pattern this proposal uses.
- `UI-SPEC-V2.md` is still the base. This proposal adds the polish layer on top of it and settles its open choices.

## 0. Diagnosis: why ours feels "unpleasant"

1. **Too many words, too few pictures.**
   - Text is doing work that icons should do: "Rusty Scythe | Carry 0/3", "5 damage per swing", "25% Candy / 50% Candy / 75% Candy / 100% Candy + title", "Hold E at the nest", "Safe Zone", "Nests refill 2:24", "+0/s", "Graveyard 16%".
   - In SAE, the HUD holds 2 labelled buttons, 2 numbers, 3 icon squares and a timer chip. That's all.
2. **No colour system.**
   - Shop and Daily are both orange. Index is purple.
   - Headers are orange or purple, panel bodies white, cards light grey, and price bars dark grey.
   - Each element picks its own colour, so nothing reads as "this is the buy button".
3. **The icons are invisible.**
   - Shop shows a faint backpack outline, Index has no icon, and Daily has a megaphone.
   - The shop scythes fill about 15% of their tiles (the thin model is fitted by its bounding-box diagonal).
   - Index silhouettes are flat black blobs on flat tiles.
4. **The panels look like web forms.**
   - Bodies are white, with no stud texture, no depth (no lip or offset shadow) and no outline on the cards.
   - SAE uses a charcoal studded body with a coloured studded header, a red square X and saturated cards.
5. **The hatch card is overloaded.**
   - Heavy full-screen blur, about 80 confetti pieces in 6 colours, and a grey card.
   - Zion called it "a little too much". The reward should feel snappy, not noisy.
6. **There's no motion language.**
   - Things appear and vanish. Top games bounce every press, count numbers up, and pulse badges.

## 1. Design system (tokens)

All sizes are fractions of **screen height (h)**, so phone and desktop match. Put the tokens in `Config.UI.Tokens` and nowhere else.

### 1.1 Colour (the button system is 3 colours plus grey)

| Token | Hex | Use |
|---|---|---|
| `go` (green) | `#3FD93A` fill, `#1E7A1B` stroke/lip | Every "do it" action: Buy, Claim, Equip, Open, Shop button |
| `info` (blue) | `#22B8FF` fill, `#0B5E8C` stroke/lip | Navigate/view: Index button, active tab, "Equipped" |
| `stop` (red) | `#FF3B3B` fill, `#8A1010` stroke/lip | Close X, danger, error toast text, notification badges |
| `off` (grey) | `#4A4458` fill, `#2A2533` stroke/lip | Disabled, owned, inactive tab, locked |
| `brand` (pumpkin) | `#FF8A1A` fill, `#9A4300` stroke | Panel header strip, Daily square, the logo. **Never** a button. |
| `candy` (gold) | `#FFC933` text, `#000000` stroke | The currency number and price text |
| `panel` | `#2B2433` body, `#1A1520` stud shade | Every panel body (charcoal with a hint of purple, Halloween) |
| `card` | `#3A3247` | Neutral card fill inside panels |
| `ink` | `#000000` | All text strokes and card outlines |
| `white` | `#FFFFFF` | All label text |

**Rarity**: tile fill, stroke, and the hatch-card ribbon.

| Rarity | Hex |
|---|---|
| Common | `#B9C2CF` |
| Uncommon | `#5BE35B` |
| Rare | `#35A8FF` |
| Epic | `#B45CFF` |
| Legendary | `#FFC21A` |
| Mythic | `#FF4D6D` |
| Secret | rainbow `UIGradient`, rotating 60 deg/s |

Rarity colours appear **only** on pet/scythe tiles and the hatch card, never on buttons. Then a colour always means the same thing.

### 1.2 Type
- **Font:** Gotham SSm. Zion's 2026-10-11 pick stays.
  - Heavy for labels, titles and numbers.
  - **Heavy Italic** for the currency number and the "NEW!" / "BEST VALUE" stickers only.
  - LuckiestGuy is retired; one family looks calmer.
- **Text** is white with a black `UIStroke`. `LineJoinMode = Round` on all text.
- **Sizes**, as a fraction of h:

| Role | Size (h) |
|---|---|
| Currency number | 0.058 |
| Panel title | 0.052 |
| HUD button label | 0.030 |
| Objective line | 0.032 |
| Card name | 0.026 |
| Price / chip | 0.026 |
| Toast | 0.030 |
| Badge digit | 0.022 |
| Small caption | 0.022 |

- **Floor:** never smaller than 0.022h. On a phone in landscape (about 390 pt tall) that is about 9 pt.
- **Implementation:** use `TextScaled` inside a box of exactly that height, with a `UITextSizeConstraint` of MinTextSize 11 and MaxTextSize = round(size × h × 1.1).

### 1.3 Shape and depth (the "chunky" look)

- **Text stroke:** `max(1.5, 0.0028h)` px. That is 3 px at 1080p, 2 px at 720p and 1.5 px on a phone.
- **Container stroke:**
  - Buttons: `0.0024h`, in the button's own dark shade (`go` uses `#1E7A1B`).
  - Cards and panels: `0.0030h`, black.
- **Corner radius** (`UICorner` scale, relative to the short side):

| Element | Radius |
|---|---|
| HUD button | 0.18 |
| Icon square | 0.22 |
| Card | 0.12 |
| Panel | 0.05 |
| Chip / toast pill | 0.5 |
| Badge | 0.5 |

- **Lip (the 3D press base):** every button is two frames.
  - A `Lip` frame in the dark shade, at the full size.
  - A `Face` frame on top in the fill colour, with height 88% of the lip, sitting at the top.
  - Pressing moves the face down by 8% so it sits flush.
  - This is the PS99/SAE "chunky" feel, and the existing `chunky()` helper already half-does it. Standardise it.
- **Gradient:** one `UIGradient` on every Face.
  - Rotation 90.
  - Color from `(1,1,1)` at 0 to `(0.80,0.80,0.80)` at 1. This multiplies the fill, giving a lighter top and a darker bottom.
  - Plus a **gloss strip**: a white frame over the top 38% of the face, `BackgroundTransparency 0.82`, with matching corner radius.
  - Nothing else. No rainbow gradients except Secret rarity.
- **Shadow:** a hard offset shadow, not blur. It fits the stud/cartoon style and needs no image.
  - Panels and cards get a black frame behind them, offset `(0, 0.006h)`, `BackgroundTransparency 0.55`, with the same corner radius.
  - HUD buttons get their lip instead.
- **Stud texture** on panel headers and bodies. This is what makes it "Steal an Egg".
  - It is a tiled image at `ImageTransparency 0.85`, `TileSize = 0.035h`. See §3 for how to make it.

### 1.4 Motion (tween timings)

Everything goes through one `UI.tween(obj, kind, props)` helper with these presets:

| Interaction | Tween |
|---|---|
| Hover in (mouse) | `UIScale` 1 to 1.06, 0.12 s, Back Out |
| Hover out | to 1.0, 0.12 s, Quad Out |
| Press down | `UIScale` 0.92 + face drops 8%, 0.06 s, Quad Out |
| Release | to 1.0, 0.20 s, Back Out (overshoot 1.7) |
| Click sound | the existing `Config.Sounds.Click`, played on press, not release |
| Panel open | dim 0 to 0.45 in 0.18 s; panel `UIScale` 0.7 to 1.0, 0.26 s, Back Out; panel `GroupTransparency` 1 to 0 (`CanvasGroup` panel) in 0.12 s |
| Panel close | `UIScale` to 0.85 and transparency to 1, 0.14 s, Quad In |
| Card stagger on open | each card from scale 0.6, 0.22 s Back Out, delay 0.018 s × index (cap at 0.25 s total) |
| Currency count-up | number tweens old to new over 0.35 s (Quad Out); label `UIScale` pulses 1.0 to 1.12 to 1.0 (0.08 s up, 0.18 s Back down) |
| Badge | pops in 0 to 1, 0.25 s Back Out, then pulses 1.0 to 1.15 to 1.0 every 2.0 s while unread |
| Toast | in: from y+0.02h and transparency 1, 0.22 s Back Out. Hold 2.2 s. Out: transparency 1 in 0.25 s |
| Error | target button shakes x ±0.006h, 4 cycles in 0.24 s; red toast |
| Hatch card | see §2.5 |
| Idle | nothing on the HUD moves at rest except badges, so the screen is calm |

### 1.5 Number formatting (one function, used everywhere)

`fmt(n)`:
- Below 10,000, use commas: `1,393`.
- Above that, use suffixes K, M, B, T, Qa, Qi with **3 significant figures**: `12.3K`, `989M`, `1.20B`, `55.8Qa`.
- Strip trailing ".0" only when the result has 3 digits before the point.
- Rates: `+170/s`. Time: `2m 24s`, then `24s`. Never `2:24`, because SAE shows "in 3m 19s".
- Prices show the candy icon followed by `fmt(n)`. Drop the word "candy" everywhere.

## 2. Screen by screen

### 2.1 HUD (rest state)

Target: about 6 elements on screen. Layout as in SAE R1.

**Left column** (labelled, primary). Two buttons only, anchored left at x = 0.014h.
- **Shop** (`go`), y = 0.40h.
- **Index** (`info`), y = 0.47h.
- Size: 0.062h tall × 0.20h wide (aspect about 3.2), with a 0.010h gap.
- An icon sits in the left 32%, a ViewportFrame (§3).
- The label is left-aligned after the icon.
- Badge: a red circle 0.030h, at the top-right corner offset (+35%, -35%), with a white count. Show it on Shop when an affordable upgrade exists, and on Index when there are unclaimed rewards.

**Right column** (icon-only squares, secondary), as in SAE's egg/paw/trophy column.
- Anchored right at x = 0.014h, starting y = 0.36h.
- Squares are 0.070h with a 0.012h gap. Each is a lip button in `brand`, `stop` or `off` with a ViewportFrame icon filling 78%.
- **Daily**: a gift-box icon on `brand` orange. The badge shows "!" when claimable.
- **Settings**: a gear on `off` grey. This replaces the separate top-right gear.

**Currency** (bottom-left; SAE puts its money here):
- A candy ViewportFrame icon at 0.060h, then the number in Heavy Italic, `candy` gold, 0.058h, with a black stroke of 0.0035h.
- No rate line and no "per second" on the HUD. The rate lives in the Index detail and in toasts.
- Income ticks: a small `+27` floats up from the number, 0.024h gold, rise 0.03h over 0.5 s, then fade. At most 1 on screen; merge new ticks into it.
- On touch devices (`TouchEnabled` and not `KeyboardEnabled`), lift the block to y = 0.60h so the thumbstick doesn't cover it.

**Objective** (top centre):
- One line of floating text, no box (SAE "You earn $180B/Day offline!").
- y = 0.020h, 0.032h, white with a black stroke.
- A 0.034h icon goes in front: a pumpkin, a scythe or a nest, depending on the step.
- The keyword is coloured with RichText. For example: "Smash pumpkins for <gold>50</gold> 🍬". The emoji is replaced by the candy icon, so no emoji glyph is rendered.
- When the step completes: a green tick appears, the line scales 1.1 and fades, and the next line fades in. Hide the line entirely after the tutorial steps are done.

**Zone** ("Safe Zone"):
- Not permanent. Only on change, as a centred banner at y = 0.12h: white text 0.036h, with a green (safe) or red (danger) zone word.
- Fade in 0.2 s, hold 1.5 s, fade out.

**Nest refill timer** (bottom-right):
- An SAE-style chip: a clock icon at 0.036h plus "in 2m 24s", white 0.030h with a stroke, and **no purple bar**.
- At 10 s or less, the text turns `go` green and pulses.

**Carry**:
- Remove the text line. While carrying, show **3 pumpkin pips** (0.034h ViewportFrame pumpkins) centred above the hotbar, at y = 0.86h.
- Filled pips are coloured. Empty pips are the same render with `ImageColor3` black at `ImageTransparency 0.6`.
- When carry is 0, the pips are hidden.

**Equipped scythe**: shown by the Roblox hotbar slot already, so no extra text.

**Zone progress** ("Graveyard 16%"):
- Remove it from the HUD. It lives in the Index zone tab (§2.3) and shows as a toast at 25/50/75/100%.

### 2.2 Shop

**Frame:**
- The panel is 0.64h tall, aspect 1.45, centred.
- `CanvasGroup` + `UIScale` for the open tween, with the shadow from §1.3.

**Header:**
- A strip 0.095h tall in `brand` orange with the stud tile and gloss.
- The title "Shop" sits left at 0.052h, after a 0.060h bag icon. The icon pokes 25% above the strip (SAE "Pet Index" title overhang).

**Close:**
- A `stop` red lip square, 0.062h, with a white "X" (0.040h, stroked).
- Anchored to the panel's top-right corner, overlapping it by 30% (SAE R3/R4).

**Body:**
- `panel` charcoal with studs and a 0.016h inner padding.

**Tabs:**
- Pills 0.050h tall: "Scythes" (scythe icon) and "Upgrades" (up-arrow icon).
- Active is `info` blue; inactive is `off` grey.
- Remove the speaker button; sound lives in Settings.

**Cards:**
- 3 per row, aspect 0.78, `card` fill with a 0.003h black stroke and a hard shadow.
- The background is a vertical gradient of the item's **tier colour** (scythe tier maps to rarity colour, from 0% at the top to 35% at the bottom), as SAE's purple Mount Stars cards do.
- **Top 62%**: the scythe ViewportFrame. Rotate it −35° so the blade and handle span the diagonal, and fit by projected width and height, not the diagonal (§3). This should fill about 80% of the area instead of 15%.
- **Name**: 0.026h, white.
- **Stat chip**: a dark pill with a sword icon and "15". Replaces "15 damage per swing".
- **Price bar**: the full card width, 0.050h, a `go` lip button with the candy icon and "150".
  - If the player can't afford it, the face is `off` grey and the price text is `#FF6B6B`.
  - If owned, it is `off` grey with "Owned".
  - If equipped, it is `info` blue with a check and "Equipped". No tilted green "Equipped!" text.
- **Stickers**:
  - The cheapest affordable unowned card gets a yellow "NEXT" ribbon sticker at the top-right, rotated 12°.
  - The top tier gets "BEST", Heavy Italic, rotated 12° (SAE "BEST VALUE!").

**Scroll:**
- `ScrollingFrame` with a 0.008h scrollbar in `off`.
- Size it so a whole number of rows shows, with a peek of the next row, so it's obvious it scrolls. Rows should never cut through names, as they do now.

**Buy feedback:**
- The card scales 1.08 and back.
- 6 candy icons fly from the price to the currency counter (0.35 s), the counter counts down, and the price bar turns blue "Equipped".

### 2.3 Index (SAE R2 layout plus PS99 silhouettes)

**Frame:** the same panel frame as the Shop, with title "Index" and a book icon.

**Left rail:**
- Zone tabs (Patch / Woods / Castle / Graveyard), each a 0.11h tall tile with a mini scene render (ViewportFrame of the zone's signature prop) and the zone name in stroked text.
- The active tab has a white 0.004h stroke.

**Centre:**
- **Zone progress bar**: `go` green fill on `off` track, 0.050h tall, "2/8" centred.
- **Reward pip** at the bar end: a gift icon. When it is claimable it bounces and gets the badge.
- **Grid**: 4 × 2 rarity tiles (size each zone's pets so they fit without scrolling).
  - **Discovered**: the rarity-colour tile, a pet ViewportFrame with the black outline trick (§3), and the name in 0.022h white.
  - **Undiscovered**: the same tile in a darker rarity shade (×0.45), with the same ViewportFrame at `ImageColor3 = #000000` and `ImageTransparency 0.15`. That gives a real shape silhouette, plus a white "?" in 0.040h stroked text centred on it, and the name "???".
  - Ours already has silhouettes. The win is the outline, the darker tile and the "?".

**Right detail card:**
- The selected pet, rendered large (0.20h) and rotating slowly (20°/s).
- Its name, its rarity word in the rarity colour, and a "🍬 +69/s" chip (with the candy icon).

**Rewards box** (under the detail card):
- The zone reward icons with green checks once claimed.
- One `go` "CLAIM" button with a red count badge.
- This replaces the 4 grey "25% Candy…" buttons and the "Discovered 0/15" bar.

**Bottom strip:** "Unlocked 3/86" with a book icon and a thin bar (SAE R2). That is the only global counter.

**Interaction:**
- Hover or tap on a tile scales it to 1.06 and selects it into the detail card.
- Newly discovered pets get a pulsing white stroke until viewed.

### 2.4 Daily

**Frame:** a smaller panel, 0.46h tall, aspect 1.9, with a `brand` header, the title "Daily" and a gift icon.

**Day tiles:**
- 7 tiles in a row, aspect 0.8. Day 7 is 1.3× wide, with a gold gradient and a "BIG" sticker.
- Each tile shows a "Day N" caption (0.022h), a reward icon render (a candy pile ViewportFrame, or a pet egg/pumpkin for day 7) and the amount via `fmt`.

**Tile states:**
- **Claimed**: dimmed to `ImageTransparency`/`BackgroundTransparency` 0.5, with a big green check (Frame-vector, §3) overlaid.
- **Today**: a white stroke of 0.004h pulsing 1.0 to 1.04, and a `go` "CLAIM" button under the row (0.060h).
- **Future**: `off` tile with the reward visible but desaturated.

**After claiming:**
- The check stamps in (scale 1.6 to 1.0, 0.2 s Back), the candy flies to the counter, and the "!" badge on the HUD square disappears.

**Footer:** a clock icon and "Next in 13h 20m", 0.024h.

### 2.5 Hatch / new-pet card (tone it down: fast, clean, one hero moment)

**Background:**
- No full-screen blur: `BlurEffect.Size` 6, not 18.
- Dim 0.35, and the HUD stays visible behind the dim.

**Card:**
- 0.42h tall, aspect 0.78, in `panel` charcoal with studs.
- A 0.005h stroke in the **rarity colour**, and a rarity-colour ribbon across the top 0.07h carrying the rarity word (RARE) in white Heavy, 0.034h.

**Hero:**
- The pet ViewportFrame at 0.22h, rotating 25°/s, with the outline trick.
- Behind it, one ray burst in the rarity colour at transparency 0.6, rotating 15°/s (§3).

**Text and stickers:**
- The name in 0.044h white.
- Chips below: "🍬 +69/s" and a weight icon with "44 kg" (`fmt`).
- A "NEW!" sticker in `go` green, Heavy Italic, rotated 12°, popping in 0.1 s after the card.

**Entrance:** the card scales 0 to 1.12 to 1.0 (0.30 s Back Out), and the pet does one 360° spin in 0.5 s.

**Confetti:** 20 pieces, not about 80, in only 2 colours (the rarity colour and white). One burst from behind the card, falling for 1.2 s. Legendary and above get 40 pieces plus gold.

**Exit:**
- It auto-closes after 2.0 s, or on a tap anywhere.
- The card **shrinks to 0.15 and flies to the Index button** (0.35 s Quad In), then the Index badge increments with a pop. This ties the reward to the collection and is the biggest "premium" tell.

### 2.6 Toasts (one system for everything transient)

**Where:** top centre at y = 0.10h, under the objective. They stack downward, with at most 3; the oldest is pushed out.

**Style:**
- Floating stroked text, **no box** (SAE/GAG style), 0.030h white.
- A 0.034h icon goes in front.
- Keywords are coloured with RichText: gold for candy, rarity colour for pets, red for danger.

**Kinds:**
- **Reward**: "+150 🍬". Also triggers the fly-to-counter.
- **Info**: "Nests refilled!".
- **Steal / alarm**: "<red>Thief</red> in your pen!". Shakes once and plays the alarm sound.
- **Error**: "<red>Not enough candy</red>". Also shakes the source button.
- **Milestone**: "Graveyard <gold>50%</gold>".

**Merging:** identical toasts within 1 s merge with an "x2" counter instead of stacking.

### 2.7 Objective
See §2.1. One line, an icon, no box, and gone after the tutorial. There is no subtitle line: "Hold E at the nest" becomes the in-world `ProximityPrompt`, which already shows the key.

## 3. Making icons without uploading images

**Rule:** if it exists as an object in the game, **render it in a ViewportFrame**. If it is a UI glyph, **build it from Frames**. Only textures and glow need an uploaded image.

### 3.1 ViewportFrame renders (no uploads)

Use the existing `Palette.renderModel`, with these fixes:

1. **Fit by projected box, not the diagonal.**
   - Rotate the model to its icon pose first.
   - Read `GetBoundingBox` in camera space and compute `distance = max(sizeX / aspect, sizeY) * 0.5 / tan(FOV/2) + sizeZ/2`.
   - Set FOV to 20 for a near-orthographic, "icon" look.
   - The current `size.Magnitude * 0.55` is why the scythes are tiny.
2. **Icon pose per type:**

   | Type | Pose |
   |---|---|
   | Scythes | Z −35°, Y 20° |
   | Pets | Y −25° (front three-quarter) |
   | Pumpkins | Y 15° |

3. **Outline:**
   - Clone the finished ViewportFrame and parent it **behind** the original.
   - Set the clone to `Size` 1.10, `ImageColor3 = #000000`, centred.
   - That gives a cheap black cartoon outline (SAE tiles have it), at one extra viewport per icon.
4. **Lighting:**
   - `Ambient #C8C8D2`, `LightColor` white, `LightDirection (-1,-1.5,-1)`.
   - Recolour `SmoothPlastic` parts brighter by 8% in the clone. Viewports render darker than the world.
5. **Silhouette:** the same viewport with `ImageColor3` black (Index undiscovered, empty carry pips).
6. **Performance:**
   - Build static icons once and cache them by id: candy, HUD icons and shop scythes on first shop open.
   - Use a `WorldModel` only for icons that rotate (the hatch card, the Index detail). Parent static models directly to the viewport.
   - Index tiles are built lazily per zone tab.
   - Budget: 40 or fewer live viewports.

**Icons to build as small Part models** (make them in a `UIIconModels` folder in ReplicatedStorage; 3 to 8 parts each, SmoothPlastic, saturated):

| Icon | Parts |
|---|---|
| **Candy** | Exists. Make it plumper and add a white highlight ball. |
| **Gift box** (Daily) | Cube in `brand`, 2 thin cross bars and a 2-ball bow in `stop` red |
| **Book** (Index) | Slab cover in `info` blue, white page slab inset, small gold clasp |
| **Bag / basket** (Shop) | A candy bucket: pumpkin-orange cylinder, black handle (torus mesh or 3 blocks), candies peeking out |
| **Gear** (Settings) | Cylinder plus 8 small blocks around it, grey |
| **Clock** (timer) | White cylinder face, 2 black block hands, red rim |
| **Sword** (damage chip) | Use the actual equipped scythe, tiny |
| **Pumpkin** (carry pips, objective) | Clone the real pumpkin model |
| **Nest** (objective) | Clone the real nest model |
| **Up arrow** (Upgrades tab) | Green wedge plus a block |
| **Zone tab minis** | Each zone's signature prop: patch pumpkin, tree, castle tower, gravestone |

### 3.2 Frame-vector glyphs (no uploads; crisp at any size)

| Glyph | How to build it |
|---|---|
| **Close X** | Stroked Gotham "X" text. Fine as-is. |
| **Check** | Two rotated white frames (short arm 45°, long arm −45°), with a black `UIStroke` of 0.003h on each |
| **Badge** | Red circle (`UICorner` 0.5), white 0.003h stroke, white digit |
| **Plus / minus** | Two crossed rounded frames |
| **Lock** | Rounded-rect body plus a circle frame with only a `UIStroke` (the shackle), clipped by a frame over its lower half |
| **Progress bar** | Track and fill frames, with the §1.3 gradient and gloss on the fill |
| **Ray burst** | 12 thin rotated frames (0.02 × 0.5 of the burst size) from the centre, each with a `UIGradient` transparency 0 to 1 outward. Rotate the parent. |
| **Radial glow** (optional) | 4 concentric circles at transparency 0.85 / 0.9 / 0.94 / 0.97 |
| **Sticker ribbon** | Rotated rounded frame plus stroked text |

### 3.3 What genuinely needs an uploaded or generated image

Keep this to 3 or fewer. These are not Creator Store items with scripts, so they're within the free-assets rule.

1. **Stud tile** (must have). A 64×64 PNG of one Lego-style stud: a light top-left highlight and a dark bottom-right shade on transparent. Tile it with `ScaleType.Tile`. It is the single biggest "SAE" signal on panels.
   - Make it with `generate_texture` or draw it as a PNG and upload it via Studio `upload_image`.
   - **Fallback with no upload:** a `UIGridLayout` of circle frames (about 200 per panel), lighter shade at 0.8 transparency. It works, but it's heavier.
2. **Soft glow / ray burst image** (optional). Only if the frame ray burst looks too hard-edged in a test capture.
3. **Hero HUD icons** (optional, phase 2): bag, book and gift as clean 3D-rendered PNGs, *only if* the ViewportFrame versions fail the blind judge against SAE's cart and book icons.
   - Render them from the same Part models in Studio, then upload. That way the style stays identical whichever path ships.

Everything else (pets, scythes, pumpkins, candy, rarity art) stays a live ViewportFrame of the real in-game model. Shop and Index always match the game, and nothing needs uploading.

## 4. Remove (less on screen)

| Remove | Replace with |
|---|---|
| **ADMIN** button | Show only for admin UserIds, behind the Settings menu |
| Duplicate top-right **gear** (2 visible in the Index shot) | One Settings square in the right column |
| **Speaker** button inside the Shop | Settings has the audio toggles |
| "**Rusty Scythe \| Carry 0/3**" text line | Hotbar slot plus 3 carry pips while carrying |
| "**+0/s**" rate under the currency | Nothing on the HUD; Index detail and toasts |
| "**Graveyard 16%**" plus its long bar | Index zone tab plus milestone toasts |
| Permanent "**Safe Zone**" line | A zone-change banner for 1.5 s |
| Objective **subtitle** "Hold E at the nest" / "Swing your scythe" | `ProximityPrompt` / tool hint; one-line objective, hidden after the tutorial |
| Purple "**Nests refill 2:24**" bar | Clock icon plus "in 2m 24s" floating chip |
| The "**Daily**" labelled orange button (same colour as Shop) | Gift icon square in the right column |
| Index "**Discovered 0/15**" bar and **four grey "% Candy" buttons** | Per-zone progress bar with reward pip, one CLAIM button, global "Unlocked" strip |
| "**5 damage per swing**" sentences | Sword icon plus number chip |
| Tilted green "**Equipped!**" text | Blue "Equipped" price-bar state |
| The words "**candy**" in prices | Candy icon |
| Stacked "**+171 / +27**" floaters at the left edge | One merged income tick above the number plus fly-to-counter |
| Hatch card **heavy blur and about 80 confetti pieces in 6 colours** | Blur 6, 20 pieces in 2 colours, auto-close and fly to Index |
| Fredoka/LuckiestGuy leftovers | Gotham only |
| White panel bodies, grey cards | Charcoal studded body, tier-tinted cards |
| (World, not UI, but it is screen noise) The **chain of 3 big red floor arrows plus a red triangle** | One subtle animated guide beam |

**Net result:** at rest the HUD shows 2 labelled buttons, 2 icon squares, 1 currency number, 1 timer chip and, during the tutorial, 1 objective line. That matches SAE R1's density.

## 5. Build order for Codex (smallest change with the biggest win first)

1. Add the tokens, `fmt()` and the `UI.tween` presets, plus the lip/gradient/gloss button builder. Re-skin every existing button through it.
2. Strip the HUD per §4. Add the right icon column and the floating timer chip.
3. Fix the viewport fit (§3.1 point 1) and add the outline clone. This fixes the scythes and makes the Index pop immediately.
4. Panel shell: studded header, charcoal body, overhanging red X, `CanvasGroup` open tween. Then Shop cards.
5. Index re-layout (zone rail, progress plus reward, detail card).
6. Hatch card tone-down plus fly-to-Index.
7. Daily strip, the toast system, and the stud tile upload.

**Check after each step:**
- Take a 1509×863 Studio capture, and a capture at phone size (844×390).
- Compare side by side against `refs/aspects/ui/v2/01`, `02` and `04`.
