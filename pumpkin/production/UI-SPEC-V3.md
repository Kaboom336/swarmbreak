# UI-SPEC-V3: merged build spec (arena round 2 judge)

Base: Proposal B's system (semantic colours, lip buttons, motion, ViewportFrame/Frame icons) plus Proposal A's exact SAE layout numbers where they are tighter. Code lives in `giant/src/StarterPlayerScripts/Patch.client.luau` with tokens in `PatchConfig.luau`. No game logic changes.

## Verdict

| Criterion | A | B | Notes |
|---|---|---|---|
| Looks as good as top games | 7 | 8 | B adds lip, gloss, shadow and motion. A has the better dark panel and rarity tiles. |
| Distinct identity, not a SaE clone | 4 | 7 | A says "copy SAE closely" and keeps SAE's red X, green price bar and purple-to-magenta cards. That breaks the FINISH-PLAN rule. B recolours semantically, but still looks like SaE. |
| Simplicity / fewer elements | 8 | 7 | A's target is 9 always-on elements. B is about the same, but adds more motion. |
| Buildable in about 3 h, at most a couple of uploads | 5 | 7 | A needs 10 uploaded PNG icons plus a stud tile. B needs 1 stud tile and 0 to 2 optional uploads. |
| Phone readability | 7 | 7 | A has explicit phone rules. B has the 0.022h floor and the touch lift. Merge both. |
| **Total /50** | **31** | **36** | B is the base. |

Identity rule applied to every item below: if it makes us look more like SaE without adding scythe farming, pumpkin hatching, the Pumpkin King or Halloween zones, cut it.

## 1. Design tokens (`Config.UI.Tokens`, nowhere else)

Sizes are fractions of screen height (h). The ViewportFrame/Frame icon method (section 5) uses no uploads.

**Colour**

| Token | Fill | Stroke/lip | Use |
|---|---|---|---|
| go | #FF8A1A pumpkin orange | #8A3E00 | Shop button, Buy, Claim, Open. Every "do it" action. Orange is our hero colour; SaE's green is not used for actions. |
| info | #A13BFF witch purple | #3D0A73 | Index button, active tab, "Equipped" |
| good | #5CFF1F slime | #1F5A00 | Progress fills, "NEW!", income "+/s", refill timer at 10 s or less. Never a button. |
| stop | #FF3B3B | #8A1010 | Close X (rounded square, not a circle), badges, danger text |
| off | #4A4458 | #2A2533 | Disabled, owned, locked, inactive tab |
| panel | #1E1530 body | #110C1C well | Every panel body (dark purple, studded) |
| card | #2E2640 | #8A7AA8 2 px | Neutral card inside panels |
| candy | #FFC933 text | #000000 | Currency number and prices |
| ink | #000000 | | All text strokes, panel and card outlines |

**Rarity** (tiles, Index, hatch card only): Common #B9C2CF, Uncommon #5BE35B, Rare #35A8FF, Epic #B45CFF, Legendary #FFC21A, Mythic #FF4D6D, Secret = rotating rainbow `UIGradient`. Scythe tiers map to these in order. Rarity colours are never used on buttons.

**Zone colours** (our hook, used on the zone banner, Index zone tabs and the world guard hint): Patch #FF8A1A, Woods #3FB950, Castle #A13BFF, Graveyard #7FD9C9. Use the existing zone config if it already has them.

**Type**
- One family: GothamSSm Heavy for everything. Heavy Italic only for the currency number and for the "NEW!" / "BEST" stickers. Retire LuckiestGuy.
- Text is white with a pure black `UIStroke`, `LineJoinMode = Round`. Stroke is `max(1.5, 0.0028h)` px. A's rule: 3.5 px on text 0.05h and up, 2.5 on 0.03 to 0.05h, 1.5 below.
- Sizes (h): currency 0.058, panel title 0.052, HUD label 0.030, objective 0.032, card name 0.026, price 0.026, toast 0.030, badge 0.022, caption 0.022. Never below 0.022h.
- Use `TextScaled` inside a fixed-height box, with `UITextSizeConstraint` MinTextSize 11 and MaxTextSize round(size x h x 1.1).

**Shape and depth**
- Corners (scale): HUD button 0.16, icon square 0.20, card 0.12, panel 0.04, chip 0.5, badge 0.5.
- Buttons are two frames: a `Lip` in the dark shade at full size, and a `Face` at 88% height on top. Press drops the Face 8% and applies `UIScale` 0.92. Face has one `UIGradient` (white to 0.80 grey, rotation 90) and a gloss strip (top 38%, white, transparency 0.82). Do not make a fully flat button (A) and do not use rainbow gradients.
- Panels and cards get a hard offset shadow: a black frame behind, offset 0.006h, transparency 0.55.
- Studs: one tiled 64x64 stud PNG (the only required upload) at `ImageTransparency` 0.88, `TileSize` 0.035h, on panel bodies and the header strip. Fallback if upload fails: no studs, keep everything else.

**Motion** (one `UI.tween` helper): hover 1.06 in 0.12 s Back; press 0.92 in 0.06 s; release 0.20 s Back; panel open = dim 0 to 0.45, `UIScale` 0.7 to 1 in 0.26 s Back, `CanvasGroup` fade 0.12 s; close 0.14 s Quad In; cards stagger 0.018 s each, capped at 0.25 s; currency counts up over 0.35 s with a 1.12 pop; badges pulse every 2 s while unread; nothing else on the HUD moves at rest.

**Numbers** (`fmt`): commas below 10,000; K, M, B, T, Qa at 3 significant figures above; time as `2m 24s`; prices as candy icon plus number, never the word "candy".

## 2. HUD

At rest: 2 labelled buttons, 3 right tiles, currency, carry, timer chip, gear in the top bar. The objective and boost tray show only when active. That is 9 always-on items.

**Desktop (16:9)**
- **Left bar** at (0.012, 0.40), two buttons 0.062h tall by about 0.17h wide, gap 0.010h.
  - Shop: `go`, icon on the left 30%, label "Shop".
  - Index: `info`, label "Index". Badge shows when rewards are unclaimed.
  - Icons come from section 5.
- **Right column** at AnchorPoint (1,0), (0.992, 0.36). Three squares of 0.070h, gap 0.012h, each a lip button with an icon filling 78%.
  - Pets or Collection: `go`, a hatched-pumpkin icon. The badge shows when a pumpkin is ready to hatch.
  - Quests: #FFC21A, scroll glyph. Replaces the "Zone quests" pill.
  - Daily: `info`, gift icon. The badge shows "!" when claimable.
- **Currency** at AnchorPoint (0,1), (0.006, 0.985). Candy icon 0.058h plus number in Heavy Italic `candy`, stroke 3.5. Above it, a scythe icon plus "0/3" in white at 0.04h (carry). No "+X/s" and no scythe name sentence. The scythe name shows only as a tooltip on the hotbar slot.
- **Timer chip** at AnchorPoint (1,1), (0.99, 0.985), no box. Moon or clock icon plus "in 2m 24s". At 10 s or less the text turns `good` and pulses.
  - Identity hook: a second chip above it for the Pumpkin King, a crown icon plus "King in 12m". It turns red when under 60 s. This is the one extra element and it earns its place.
- **Boost tray** (only when active) at AnchorPoint (1,1), (0.99, 0.925). Tiles 0.055h, black at 0.45 transparency, "x2" badge in #FFE14A, timer 0.022h under each.
- **Objective** at top centre, one line, no box, y 0.015, 0.032h, with a keyword coloured via RichText and a small icon (pumpkin, scythe or nest). Hidden when a panel is open and after the tutorial.
- **Zone banner** shown only on zone change, at y 0.075. Zone name in the zone colour over a black gradient band (transparency 1 to 0.55 to 1). Scale 0.8 to 1 Back in 0.25 s, hold 2.5 s, fade 0.4 s.
- **Gear** moves to a `TopIcons` ScreenGui with `ScreenInsets = TopbarSafeInsets`, a 32 px black circle at 0.4 transparency. One gear only. ADMIN exists only for the admin UserId and only inside Settings.

**Phone (touch, about 844x390)**
- Root `UIScale = clamp(vpY/720, 0.75, 1.15)`. Min text 11 px. Keep x > 0.72, y > 0.62 clear for the jump button and x < 0.30, y > 0.65 clear for the thumbstick.
- Left buttons become icon-only 0.09h squares at (0.012, 0.30) and (0.012, 0.40). Right tiles 0.09h at x 0.99, y 0.30, 0.40, 0.50.
- Currency moves to the top-left, (0.012, 0.06), and carry sits under it. Timer chip and King chip go to the top-right, y 0.01 and 0.07, shifted left of the tile column.
- DROP button at (0.5, 0.80), 0.15w, between the stick and jump.
- Panels are 0.86w x 0.80h with the same internal fractions. The Shop tab column folds into a top row.

## 3. Screens

**Shop** (panel 0.64h tall, aspect 1.45, centred, open tween)
- Header strip 0.095h in orange with studs and gloss. Title "Shop" at 0.052h, no "!", no header icon. Close X is a stop-red lip rounded square 0.062h overlapping the top-right corner by 30%, with a stroked white "X".
- Tabs are a row of pills under the header: "Scythes" and "Upgrades". Active is `info`, inactive is `off`. Remove the mute button.
- Cards: 3 per row, aspect 0.78. Background is a vertical gradient of the scythe's tier colour. A ViewportFrame of the scythe takes the top 62% (see section 5). Name on top of it, a stat chip (sword icon plus number), then a full-width price bar.
  - Price bar states: `go` with candy icon and price (affordable); `off` with red price (too expensive); `off` "Owned"; `info` "Equipped" with a tick.
  - Stickers: a yellow "NEXT" ribbon on the cheapest affordable unowned card, "BEST" on the top tier, rotated 12 degrees.
  - Show a half-visible next row so the scroll is obvious. No row may cut through a name.
- Buying: card scales 1.08, 6 candy icons fly to the counter, price bar changes to Equipped.

**Index** (same panel shell, title "Index", title overhangs the top edge)
- Left rail: 4 zone tiles in zone colours with a mini ViewportFrame of the zone's signature prop. Active tile gets a white stroke.
- Centre: zone progress bar (`good` on `off`) with a gift pip at the end, then a 4x2 grid of rarity tiles in a dark well. Discovered tiles are the saturated rarity colour with a black 2.5 px stroke and the pet render. Undiscovered tiles are the rarity colour x 0.45 with a black silhouette render and a stroked "?".
- Right: detail card (big slow-rotating render, name, rarity word, candy plus "+69/s" chip) and a rewards box with one `go` CLAIM button and a red count badge. The four grey "% Candy" buttons and the "Discovered 0/15" bar are removed.
- Bottom strip: "Unlocked 3/86" with a thin bar. This is the only global counter.

**Daily** (small panel 0.46h tall, orange header)
- 7 tiles in a row. Day 7 is 1.3x wide with gold and a "BIG" sticker. Each shows "Day N", a reward render (candy pile, or a pumpkin egg on day 7) and the amount.
- States: claimed is dimmed with a Frame-built green check; today has a pulsing white stroke and a `go` CLAIM button; future is `off`.
- After claiming, the check stamps in (1.6 to 1.0 scale), candy flies to the counter, the HUD "!" clears.
- Footer: clock icon plus "Next in 13h 20m".

**Hatch card** (the pumpkin-hatching hook, so it gets one hero moment and nothing noisy)
- Card 0.42h tall, aspect 0.78, `panel` body, 3 px black stroke plus an inner stroke in the rarity colour. A rarity ribbon across the top carries the rarity word.
- Hero is the pet render at 0.22h, rotating 25 degrees/s, with one rarity-coloured ray burst behind it (12 thin rotated frames with gradient transparency). Under it: name in white, "+69/s" in `good`, weight on a small grey line. "NEW!" sticker in `good`, rotated 12 degrees.
- Entrance scale 0 to 1.12 to 1 in 0.30 s, with one 360 degree pet spin.
- A cracking-pumpkin beat before the reveal: the pumpkin shell splits in two halves (two Frames or the existing model) in 0.4 s. This is the Halloween identity touch.
- Confetti 20 pieces in 2 colours (rarity plus white), 40 plus gold for Legendary and up, kept inside a 0.6 x 0.6 box. Blur size 6 and the HUD stays crisp (HUD DisplayOrder above the blur, or no blur while the HUD is visible).
- Exit after 2.0 s or on tap: the card shrinks and flies to the Index (or Pets) tile, which pops its badge.

**Toasts** (one system for all transient messages)
- Top centre at y 0.10h, stacking down, maximum 3, no box, 0.030h stroked white, a 0.034h icon in front, RichText keywords (gold candy, rarity-coloured pets, red danger).
- Kinds: reward (also triggers fly-to-counter), info, steal alarm (shakes once, plays the alarm sound), error (also shakes the source button), milestone ("Graveyard 50%"). Identical toasts within 1 s merge with "x2".

**Objective**: see the HUD. The in-world `ProximityPrompt` replaces any subline such as "Hold E at the nest".

## 4. Remove list

1. Daily from the left stack (it becomes the right tile).
2. The "Rusty Scythe | Carry 0/3" sentence (keep icon plus 0/3 only).
3. The "+27/s" line and the stacked "+171 / +27" floaters (one merged income tick plus fly-to-counter).
4. "Graveyard 16%" and its progress bar (moves into the Index and into milestone toasts).
5. The objective subline and the box behind the objective.
6. The always-on "Safe Zone" line (banner on change only).
7. The purple "Nests refill" bar.
8. The ADMIN chip, the duplicate gear and the top-right floating settings box.
9. The "Zone quests" pill, the Shop mute button, all emoji glyphs, header icons, and the "!" in "Shop!".
10. White panel bodies, grey cards, orange rims, cobweb and tilt.
11. The 80-piece confetti and the strong blur on the hatch card.
12. LuckiestGuy and every non-Gotham font.
13. "5 damage per swing" sentences and the tilted green "Equipped!" text.
14. In the world (screen noise): the giant SHOP / SELL billboard letters that clip the HUD corners (set `MaxDistance` to about 60 studs) and the chain of three big red floor arrows (one subtle guide beam).

## 5. Icon method (no uploads except one stud tile)

- **Game objects use live ViewportFrames:** scythes, pets, pumpkins, candy, nest. Fit by projected box, not by bounding diagonal: pose the model first, read the camera-space box, `distance = max(sizeX / aspect, sizeY) * 0.5 / tan(FOV/2) + sizeZ/2`, FOV 20. Poses: scythe Z -35 and Y 20, pets Y -25, pumpkin Y 15. This is the fix for the scythes being 15% of their tile.
- **Outline trick:** clone each finished ViewportFrame, put the clone behind at size 1.10 with `ImageColor3` black. Silhouettes use the same viewport with `ImageColor3` black.
- **Small Part models** in `ReplicatedStorage/UIIconModels` (3 to 8 SmoothPlastic parts each): candy, gift box, spellbook, candy bucket for Shop, gear, clock or moon, up-arrow, crown for King, scroll, hatched-pumpkin for Pets. Ambient #C8C8D2 so they do not render dark.
- **Frame glyphs:** check (two rotated frames), badge, lock, progress bar, ray burst, sticker ribbon, glow rings.
- **Uploads:** one required (stud tile). One optional (soft glow) only if the frame ray burst looks too hard. If the ViewportFrame HUD icons fail a blind judge against SaE's cart and book, render those two as PNGs from the same models and upload them as a phase-2 fallback. Maximum of 3 uploads.
- Cache static icons by id. Build rotating icons with a `WorldModel`. Index tiles build lazily per zone. Budget is 40 live viewports or fewer.

## 6. Build order: 2 Codex tasks

**Task U1 (system and HUD, about 1.5 h)**
1. Add tokens, `fmt()`, `UI.tween`, the lip/gradient/gloss button builder and the pure-black stroke helper. Re-skin every existing button through it.
2. Build `UIIconModels` plus the fixed `Palette.renderModel` (projected fit, outline clone, silhouette, cache).
3. HUD per section 2: strip the remove list, add the right column, currency plus carry, timer chip, King chip, zone banner, objective, top-bar gear, phone variants, boost tray.
4. Toast system.
5. Capture 1509x863 and 844x390 after each step, compare against `refs/aspects/ui/v2/01`.

**Task U2 (panels and screens, about 1.5 h)**
1. Panel shell: studs (upload), dark body, overhanging red X, `CanvasGroup` open tween, hard shadow.
2. Shop cards with scythe renders, price-bar states, stickers and buy feedback.
3. Index re-layout (zone rail, progress plus gift pip, detail card, rewards, unlocked strip).
4. Daily row and claim animation.
5. Hatch card tone-down, shell-crack beat, ray burst, fly-to-Index exit.
6. Capture Shop, Index, Daily and hatch at both sizes. Blind critic against refs `01`, `02`, `04` and `06`.

**Gate each task:** compile check, selene, Studio smoke test by Claude, no duplicate gear or ADMIN on the HUD, no text below 0.022h on the phone capture.
