# SECTION-UI: HUD + panels + toasts (everything 2D)

Evidence base: play view (blob-1791730176676-paih14.jpg, 1509x863, call it "PV"), UI-DIFF.md, and code in
`giant\src\StarterPlayerScripts\Patch.client.luau` (PC), `ServerScriptService\Patch.server.luau` (PS), `ReplicatedStorage\PatchConfig.luau` (CFG).
Units: h = screen height in px at the unscaled gui (use `gui.AbsoluteSize.Y / uiScale.Scale`, as the file already does). "0.006h" = 6.5 px at 1080p.
Several UI-DIFF items are ALREADY half-done in code (button outline 2.5, Back overshoot, press squash, gloss). Do not redo those; the list below is only what is still wrong.

## 1. Flaws found

### A. Visible bugs in PV (fix first)
1. **Quest panel sits on the gate sign.** PC:6068-6074: `questPanel` anchored (1,0) at x 0.67w, so it spans 0.39-0.67w (centre 0.53w, NOT centred under the objective bar) at y 0.09-0.21h. The world gate billboard "Graveyard / 2 new pets + New pets / 2,500 candy" is drawn at y 0.27-0.37h and the panel bottom (y 226 px in PV) touches its first line. Two overlapping text blocks with the same white stroked font read as garbage.
2. **Garbled gate-sign copy.** PS:4618 builds `def.title .. "\n2 new pets + " .. def.unlock`; `def.unlock` is `ladder[i][3]` from CFG:1390-1398 = designer notes ("New pets", "R20 tutorial", "Pen slots 9-10 + Fuse", "Witch Merchant", "Gold mutation", "Rebirth"). So Zone2 prints "2 new pets + New pets". The title is TextScaled in a 56%-height box, so two lines shrink and the stroke (4px) fills the glyphs.
3. **"Next gate -25%".** PC:6065 formats `Next gate -%d%%` with `gateDiscount*100`; the sign reads as a negative stat. It is a discount: write "Next gate 25% off".
4. **Quest list is an ASCII debug string.** `[ ] Smash 7/50 / [x] Steal [x] Own pet` in ONE TextLabel (no icons, no per-row progress, no tick graphic, `Config.UI.body` box at 0.1 transparency, 10 px corner, no outline). Compare SaE/PS99 quests: one row per task with a progress bar and a coin/gift reward.
5. **Toast holder collides with the objective bar.** PC:1061 puts `Toasts` at y `CFG.UI.toastY = 0.10`, width 0.76w, height 0.14h: exactly the objective bar (PV y 68-104 = 0.08-0.12h) and quest panel zone. The code comment says "bottom centre" but it is placed top. Any hint will draw over "Unlock the Graveyard!".
6. **Objective bar is a boxed debug pill.** PC:5994-6003: 0.30-transparent #160E20 pill with a pumpkin glyph. UI-DIFF #22: SaE uses unboxed stroked text.
7. **Currency counter is weak and clipped.** PV: icon at x 5-55 px is three rotated Frames (`UI.candyGlyph`, PC:990, orange/yellow/orange bars at -30/0/+30 deg), reads as a crown not candy, and the left bar bleeds off screen; "0/3" carry sits above in a dark pill with a scythe glyph; "50.7K" is italic gold at about 0.055h but the whole block starts at the edge (x 0.012w minus the rotated frame's overhang). No "+" shop chip, income `+X/s` label is hidden (`incomeLabel.Visible=false`).
8. **Gain float "+16" (PV x 225, y 752) is tiny** (about 0.02h) with a 2.5 px dark-purple stroke; PC:222 `floatText` is the 200x46 billboard, TextScaled, so it renders small. It is the main feedback loop of the game and it is the weakest text on screen.
9. **Quests tile is permanently hidden** (`questToggle.Visible = false`, PC:6034, 6054) but the right column still reserves slot 2 (`UI.tile`, PC:2700), so Pets (PV y 345-400) and Daily (y 515-570) have a 115 px hole between them and the column looks broken.
10. **Icons are programmer art.** `UI.icon` (PC:894-990) draws each icon from 3-12 coloured Frames: pumpkin = rounded rect + two rotated squares as eyes; Quests = scroll of rectangles; Daily = box of rects; clock = rect hands; crown = rects. No volume, no highlight, no consistent outline. PV Pets/Daily/Shop/Index icons look like stickers from different games.
11. **Bottom-right chips**: 0.30 transparency dark pills, text right aligned at ~0.030h, tiny clock/crown glyph; 355x42 px; they sit on the lime floor with low contrast against the grid. White text for "King in 10m 24s" even when the event is near.
12. **Settings gear** (PV 1475,25) is a 36 px black circle at 0.4 alpha, smaller than all other buttons; top-right is empty otherwise.

### B. Style gaps vs top games (measured in UI-DIFF; only still-open ones)
13. Text stroke is `max(1.5, 0.0028h)` (PC:631, fitText PC:603) = 2.9 px at 1080p; SaE/PS99 ~ 0.006h = 6.5 px. Button label strokes are a flat 2 px (PC:731). Currency stroke 3.5 px fixed.
14. Right tiles carry captions ("Pets", "Daily") 0.022h under the tile (PC:2701-2711): clutter; SaE tiles are icon-only.
15. Panel header: title anchored left at x 0.05, lacks dark lip under header, no diagonal shine, no stud texture, body is purple #1E1530 (CFG:21) which makes every panel look like the same dark card as the HUD pills.
16. Close X: 0.062h red square overlapping the corner at AnchorPoint (0.7, 0.3) (PC:1603); X is `makeButton` text at `type.hud` 0.030h with the 2 px stroke; glyph reads thin. SaE keeps the X fully inside the header.
17. Price buttons: grey `off` bar when unaffordable (looks disabled/dead) and no distinction between "cannot afford" and "equipped".
18. Sound: click plays at volume 0.35 x UI group 0.5 = 0.175 effective, fixed pitch (PC:699, 1562, 1808, 2960). No hover tick, no panel open/close whoosh (open handler PC:1751-1780 has no `play`), `Config.Sounds.Whoosh` exists (CFG:1152) and is only used for swings.
19. Panel open: scale 0.7 -> 1 over 0.26 s Back is OK but there is no HUD slide-out, and the close is 0.7 scale / 0.14 s with no ease-in of the dim (fine, but also silent).
20. Spacing inconsistent: left bar 0.012w from the edge, right tiles 0.992w, chips 0.99w, stats 0.012w, gear -16 px: five different margins.

## 2. What top games do (short)
- Steal an Egg / PS99 / Grow a Garden HUD: ONE job per screen zone. Top-left or bottom-left = currency stack; left column = 2-4 chunky coloured buttons; right column = 3 icon-only tiles; top centre = one line of unboxed stroked text; bottom-right = event timers as unboxed stroked text. World billboards are always smaller than HUD text and are hidden when a HUD element covers their area.
- Every text is white/colour with a ~0.006h black round stroke; numbers coloured by currency; icons are 3D renders with black outline.
- Quests: a collapsible list under the objective, one row per task, icon + progress bar + reward, ticks turn green.
- Every control: hover brighten, press squash, 80 ms click, open whoosh up, close whoosh down, buy "ka-ching".

## 3. Fix spec, ordered by impact

### 3.1 [S] Delete the zone quest TextLabel-panel overlap and gate-sign garble
(a) **Gate sign** PS:4618: replace the title with two labels. Line 1 = `def.title` (single line, Heavy, TextScaled in 0.46 of the sign height, stroke 5 px #000 round). Line 2 (new small label, 0.22 height, #FFE9A8, stroke 3 px) = `Config.gateBenefits(zoneId)`. Delete the "2 new pets + " prefix. Pill stays, but also add `def.title` zone colour as a 4 px top stripe. Add a display-only field in CFG ladder: `{ "Ghost","Shadow","New pets" }` third value is a dev note; create `Config.gateBenefit[zoneId]` with player copy: Zone2 "New pets", Zone3 "+2 pen slots, new pets", Zone4 "Witch Merchant", Zone5 "+2 pen slots, new pets", Zone6 "Gold mutation", Zone7 "Rebirth". Never print `z.unlock`.
(b) BillboardGui Size 300x120 -> 280x110; `MaxDistance` 60 -> 48; add `MinDistance`-style fade: client loop sets `bb.Size` scale by `1.0` at 20 studs, `0.7` at 48 (or `GroupTransparency` via a CanvasGroup). Set `StudsOffsetWorldSpace = (0, 2, 0)`. `AlwaysOnTop=false` (so it does not draw over HUD panels), keep `LightInfluence=0`.
(c) **Quest panel relocation** (PC:6068): never draw while a gate sign is within 48 studs of the camera (compare `workspace.CurrentCamera.CFrame.Position` to each `GateGui` parent, hide quest panel and re-show when farther). Simpler and also fixes overlap on every resolution: dock the panel to the LEFT column under the Shop/Index buttons, see 3.6.

### 3.2 [S] Rewrite quest copy and row layout
Replace the single `questPanel.Text` with 3 rows built once (Frame 100% x 0.31h of the panel each):
- Row = 0.04h tick box (green #5CFF1F filled with a white check when done, dark #2A2533 with 2 px #000 stroke when not) + label 0.026h Heavy white 3 px stroke + right-aligned progress "7/50" (candy gold #FFC933 when incomplete, green #5CFF1F when done) + 0.012h bar under the label (fill `go` #FF8A1A, track #17101F, corner full, 1.5 px stroke).
- Labels: "Smash 50 pumpkins", "Steal 3 pumpkins" (use `Progression.questSteals`), "Own a {Zone} pet".
- Header line: `{z.title}` 0.030h in the zone colour (`Tokens.zones[...]`), then below the rows a single pill text "Next gate 25% off" (gold #FFC933, 0.024h). Never print `-` before the number.
- Panel: width 0.19w (min 250 px at 1080p), height 0.18h, `BackgroundColor3 #24202F`, 0.12 transparency, corner 0.12 of height, 3 px black UIStroke. Drop it to 0.45 transparency + fade the labels when carrying (`Carry > 0`), do not hide it (the pop-in/out of this panel is currently distracting).
- Done state: when all 3 rows tick, change the panel stroke to `good` #5CFF1F and hold 2 s with a 1.06 pop, then collapse to a single line "Zone quest done! Next gate 25% off".

### 3.3 [S] Fix the toast holder placement and look
- `CFG.UI.toastY = 0.10` -> **0.205** on desktop (below the objective at 0.085-0.125h and above the gate signs); phone `0.19`. Holder size 0.50w x 0.16h, anchor (0.5, 0). Rows 0.04h tall, 0.008h gap, newest on TOP (matches existing code). Max 3.
- Font: 0.034h (`Tokens.type.toast = 0.034`), Heavy, text white, stroke `max(3, 0.006h)` round, no frame. Candy/reward toasts colour the number #FFC933, errors #FF5A5A.
- Icon 0.038h to the left (replace emoji-based icon choice at PC:1068 by explicit icon argument).
- Motion: enter = row slides down 0.02h while fading in over 0.18 s (Quad Out) and scales 0.85 -> 1.0 (Back Out 0.22 s); hold 2.5 s; exit = fade 0.3 s and move up 0.012h. Hold 3.2 s currently: set to 2.5. Reward toasts: a candy icon copy flies from the toast to the candy counter in 0.45 s (Quad In) and triggers `punch()` (PC:1316).
- Priority: error toasts (red) replace the oldest row instead of stacking above objective.
- Remove duplicates inside 3 s (already done); also cap long strings at 52 chars and `TextTruncate = AtEnd`.

### 3.4 [M] Currency counter (bottom-left)
- Block anchored (0, 1) at (0.012h converted to x, 0.975h from top) (use the same margin M = 0.012h for all HUD edges; on phone keep `0.565` as now).
- Row 1 (carry): plain text "Carry 0/3" 0.036h Heavy white, 5 px stroke, NO pill, small scythe/pumpkin icon 0.036h (the 3D icon from 3.8). Colour switches to #FF5A5A when full.
- Row 2: icon 0.058h x 0.058h at x 0 (fully on-screen, no rotated children), number 0.058h Heavy Italic #FFC933, stroke 0.006h = 6.5 px at 1080p round join, left aligned 0.02h after the icon; **+ chip** (0.030h circle, #5CFF1F face, #1F5A00 lip 0.004h, 2.5 px black outline, white "+" 0.026h) at the right of the number opening the Shop (`SelectedTab = "Coins"` if it exists, else the main Shop). Pop on gain: icon 1.25x (already), number 1.1x (already) + 0.35 s roll (already, keep).
- Row 3 (income): show it (remove `Visible=false`): `+1.2K/s` 0.030h green #5CFF1F with 4 px stroke, opacity 0.9. This is the "numbers go up" signal top games show.
- Delete `UI.candyGlyph`'s three-bar shape (see 3.8).

### 3.5 [S] Floating "+N" gains (the most-seen text in the game)
`floatText` PC:222: billboard 200x46 -> 300x80 (big 360x96); `TextScaled=false`, TextSize 40 (big 56); stroke 5 px (big 7), colour `ink` #000; start scale 0.5 -> 1.25 in 0.12 s (Back Out) -> 1.0 in 0.1 s, rise 6 -> 7 studs over 1.0 s (not 1.6 s), alpha fade from 0.6 s. Candy gains #FFC933, pumpkin gains #FF8A1A, crit #FF4D6D with a "!". Also remove the early-return that drops pure "+N" strings (`text:sub(1,1)=="+"` and no "/s"): that is why smash gains rarely show. Stack: offset each new float 0.9 studs sideways (random +-0.8) so 3-hit combos do not overwrite each other (`UI.floatAnchor:Destroy()` currently kills the previous one every time).

### 3.6 [M] Objective + quest placement (single column, no overlaps)
Zones of the screen (desktop, % of screen):
- y 0.012-0.062 (0.05h): objective text (unboxed). Centre x. Keyword colours via RichText (`#FF8A1A`, `#5CFF1F`). Font 0.036h Heavy, stroke 0.006h. Drop the bar fill (leave an optional 0.55-alpha black gradient strip 0.06h tall, fading to 1 at the bottom, for contrast on the bright sky). Progress sub line 0.024h `#FFE196` under it. Hide while any panel is open (already done).
- Toasts: y 0.205-0.365.
- Gate world sign: appears naturally at 0.27-0.37h: **no HUD above 0.205+0.16=0.365 centre** after 3.3 shrinks to 3 rows max (0.12h). Real estate between 0.36 and 0.75 stays clear for gameplay.
- Quest panel: dock LEFT, x 0.012h, y just under the Index button (left bar rows end at 0.062+0.072 = 0.134h + 0.40 base = ~0.55h in PV: Index bottom at 0.54h). Place it at y 0.60h, width 0.17h x 0.20h-ish (not 0.28w) so it sits on the left side, under the buttons and above the stats block (stats top at 0.775h). Collapse chevron (`>` / `v`) toggles it, default expanded for the first zone and collapsed after the zone is completed. Hide on mobile unless toggled.
- Right column: remove the hidden Quests slot; Pets at y 0.36h, Daily at 0.464h (UI.tile slot spacing 0.104h) -> use slots 1 and 2 (re-index `UI.tile("Daily", ..., 2)`). If the quest panel stays docked left, delete the right quest toggle entirely.
- Bottom-right chips: remove fill (BackgroundTransparency 1), keep a 0.35-alpha black gradient strip behind both for contrast, font 0.034h, stroke 0.006h, icon 0.04h. Clock text "Nests respawn in 1m 21s" -> "Nests 1m 21s"; King "King 10m 24s" (shorter, fits at 0.34h). Turn the King line red #FF3B3B and pulse (0.85-1.0 alpha, 0.6 s sin) when under 60 s; pulse the clock green when <= 10 s (already).
- Settings gear: 36 -> 48 px (or 0.044h), 3 px black outline, #FFFFFF gear icon on `off` #4A4458, anchored 0.012h from top-right (inside TopbarSafeInsets as now).

### 3.7 [S] Left buttons, right tiles, price buttons, panels (numbers)
- Left buttons (pill, PC:1441): size 0.17h x 0.062h -> **0.19h x 0.064h**, gap 0.012h (currently 0.072h pitch = 0.010 gap). Label left aligned at x 0.38, 0.034h, stroke 0.006h; icon 0.044h at x 0.04. Face stroke 3 px #000, lip 0.012h (currently 12% of height = 0.0074h), hard shadow 0.006h at 0.55 alpha below. Colours: Shop `go` #FF8A1A / lip #8A3E00 (keep, hero); Index `info` #A13BFF / lip #3D0A73 (keep).
- Right tiles: remove captions (`caption.Visible=false` and delete the layout lines for `caption`); tile 0.070h stays; icon 80% (0.80 x 0.80, centred); badge circle 0.026h red #FF3B3B with 2.5 px black stroke, white number 0.020h.
- Price buttons (`makeButton` consumers in the shop card builder around PC:2121-2200):
  - Affordable: face `go` #FF8A1A, lip #8A3E00, white number 0.032h (stroke 0.006h), candy icon 0.040h left.
  - Can't afford: face #4A4458, lip #2A2533, number #FF5A5A with a **black** 0.006h stroke, icon desaturated (0.6 alpha); on press shake 3 px / 0.2 s + low "buzz" sound (pitch 0.8).
  - Equipped: face `info`? No: use `good` #5CFF1F / lip #1F5A00 with a white tick 0.036h and "Equipped" 0.026h.
  - Height 0.052h, width card minus 0.012h, corner 0.2, face stroke 2.5 -> 3 px, lip 0.008h.
- Panel (PC:1624+): body `Config.UI.Tokens.panel` #1E1530 -> **#24202F** (neutral); header gradient white->0.8 (keep) + a 0.008h lip #8A3E00 (go) / #3D0A73 (Index) at the header bottom edge; add two parallelogram "shine" frames (white, 0.88 alpha, 0.04w wide, rotated 20 deg) on the header; title vertically centred (AnchorPoint (0, 0.5), Position (0.035, 0.5)), 0.058h; stroke 3.5 px.
- Close X: size 0.056h, **inside** the header with 0.01h margin (AnchorPoint (1, 0.5), Position (0.985, 0.5)); glyph label 0.036h Heavy white with 0.006h stroke; face stop #FF3B3B / lip #8A1010 / 3 px black outline.

### 3.8 [M] Icon set: stop drawing from Frames
All icons (`UI.icon`) switch to an ImageLabel from one atlas of 8 PNGs: Candy (wrapped sweet, striped orange/white wrapper, twist ends), Pumpkin (Pets), Gift (Daily), Book (Index), Cart/Bag (Shop), Crown (King), Clock, Gear. Spec: 256x256 PNG, transparent, 3D-looking bevel, 6 px black outline (scaled to 2.5-3 px at render), top-left white highlight, soft bottom shadow. Source options (free only): render from the existing voxel/part pipeline in `scene/VoxelModels.luau` using the existing `Palette.renderModel` (ViewportFrame, `outlined` clone at 1.10x is already implemented, PC:754) at 256 px and capture to PNG via the owner's tooling, then upload; or use free Kenney "game icons"/"UI pack" PNG (CC0) tinted to the palette. Either way all icons must be at least 0.044h in HUD.
Candy glyph: delete `UI.candyGlyph` three-bar shape; Candy = wrapped sweet with orange/white diagonal stripes and two pleated ends, outline 3 px.
Until the PNGs exist, minimum patch: add a 2 px black UIStroke + white 0.20 alpha top gloss to every `piece()` rectangle in `UI.icon` and clamp the root with `ClipsDescendants=true` so nothing leaks past the HUD edge.

### 3.9 [S] Motion
- Open: pop (keep 0.26 s Back, overshoot 1.7) from 0.6 (currently 0.7) -> 1.0; dim 0 -> 0.5 in 0.2 s; HUD left buttons and right tiles slide off by 0.12w (left) / +0.10w (right) in 0.2 s Quad Out (restore on close); stats block stays.
- Close: scale 1 -> 0.9 and fade in 0.14 s (current 0.7 scale is too jumpy), then `Visible=false`.
- Button feedback: already scale 1.06 hover (0.12 s Back) and press 0.92 (0.06 s). Add hover brightness: face colour -> `Color:Lerp(white, 0.08)` over 0.1 s; press drops face Y by `0.012h` (face currently moves 8% of its height, ok) and the lip is the only thing left visible.
- Rewards: reward toast fly-to-counter as in 3.3; counter `punch()` already exists.

### 3.10 [S] Click sounds (route everything through one helper)
- `UI.play(kind)`: click = `Config.Sounds.Click`, volume 0.7 (effective 0.35 on the UI group 0.5; raise `SoundMix.UI` to 0.7 so effective 0.49), pitch 1 +- 3% random; hover = same asset, volume 0.20, pitch 1.25, only once per 0.1 s; open = `Config.Sounds.Whoosh` pitch 1.25, volume 0.35; close = `Whoosh` pitch 0.85, volume 0.30; buy = `Config.Sounds.Buy` (exists) plus `Coin` pitch 1.1; error = `Bonk` pitch 0.6, volume 0.5; toast with reward = `CandyTick` 2^(n/12) rising (already used in collect).
- Hook it inside `chunky` (PC:698) so every `makeButton` gets it, plus `closeButton` -> close sound (not click), plus `panel()` visible-change handler (open sound only when `frame.Visible` becomes true).
- Mute path: all through `play` so `sfxOn` still toggles it.

### 3.11 [S] Text stroke and fonts (one global rule)
- Replace the two stroke formulas (`textLabel` PC:631, `fitText` PC:603, `makeButton` label PC:731) with `thickness = math.max(2.5, h * 0.006)`; Round line join everywhere (already set in `textLabel`); stroke colour #000.
- Type tokens in CFG:50-60: `hud` 0.030 -> 0.034, `objective` 0.032 -> 0.036, `toast` 0.030 -> 0.034, `price` 0.026 -> 0.032, `card` 0.026 -> 0.030, `title` 0.052 -> 0.058, `caption` 0.022 -> 0.026 (floor for any label). Never use TextScaled without `UITextSizeConstraint` (fitText already adds it).
- Keep GothamSSm Heavy for text; Italic only for currency numbers (keep).

### 3.12 [S] Margins
One margin rule: `M = 0.012h` (about 13 px at 1080p) for left buttons, stats block, right tiles, chips, gear. Replace `0.992` right tile anchor with `1 - M/aspect` and chips `0.99` likewise. Safe area on phones: top 0.04h (objective y).

## 4. Colour note for the UI only
Keep orange `go` as hero, but the lime ground and purple panels clash (ZION W2, outside this section). Panel body: #24202F with #3A344A card, strokes #000, rarity strokes from `Tokens.rarity`. Use green #5CFF1F ONLY for done/equipped/+ chip, red #FF3B3B only for X/errors/low timers, gold #FFC933 ONLY for candy numbers. Everything else white with black stroke.

## 5. Acceptance test
1. At 1080p screenshot standing in front of the Graveyard gate: no text from the HUD touches another text block; quest panel is on the left, gate sign reads "Graveyard / New pets / 2,500", objective at top centre with no box.
2. Zero strings containing "-25%", "[ ]", "[x]", "2 new pets + New pets" appear anywhere in the UI (grep the repo for them too).
3. Candy counter fully on-screen with a real candy icon, 0.058h gold number, green "+" chip, income line visible; a smash shows a 40+ px "+N" float with a 5 px stroke.
4. Fire 5 toasts in 1 s: max 3 rows, all below the objective, none overlapping gate signs; each fades in 0.18 s and leaves after 2.5 s.
5. Click every HUD button, close X, hover and open/close a panel: each plays a distinct sound at audible level (>= 0.35 effective), panel pops with overshoot, HUD slides away and back, price buttons are orange when affordable and show a red-on-black number when not.
