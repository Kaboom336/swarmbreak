# REDRAW RULES for Steal a Pumpkin concept sheets (blind lead critic, 2026-10-11)

Basis: all 15 sbs images and REFS2.md, TIKTOK-DELTA-2026-10-12, Hit Game Bible. Paths: refs are in `concepts/refs2/<sheet>-ref-N.jpg` (N=1..3; best ref per sheet named below). Brief verdict: our sheets are polished, but they are catalogues and blueprints on cream paper, with voxel noise and a sunset cast. The refs are screenshots: flat bright, huge props, thick-stroke text, tiny HUD. A redraw must read as an in-engine screenshot.

## SCORES (1-10, "built exactly, would it match the ref in a screenshot?")
| sheet | score | verdict |
|---|---|---|
| hub-perspective | 6 | best sheet; fix density and sky |
| hud-desktop | 6 | close; shrink HUD, stroke text, daytime |
| panels-shop-index | 6 | good layout; cream vs dark, no glow |
| zone1-perspective | 5 | pretty but cluttered, dusk |
| pets | 5 | good designs; need scale and labels |
| hud-phone | 4 | 3 big buttons and a joystick cover the field |
| zones-strip | 4 | purple/orange base in every zone |
| hatch-reveal | 4 | storyboard, no skip, no mass pop |
| scythes | 4 | blueprint, untested at 40 px |
| guards-and-king | 4 | no billboard, no boss HUD in a real shot |
| collectibles | 4 | catalogue, no glow or pop text |
| first-5-min | 4 | six panels, banner box, no arrows |
| panels-upgrades-daily | 4 | not launch scope |
| hub-topdown | 3 | blueprint with 20+ labels |
| zone1-topdown | 3 | blueprint, 40 pumpkins in a grid |

## 1. GLOBAL RULES (apply to every redraw)
1. TIME OF DAY: default is DAYTIME. Sky is a clean cyan-to-pale-blue gradient (#4FB8F0 top, #BFE8FF horizon) with 2-4 flat white clouds. No orange sunset wash, no haze, no vignette, no colour cast over the whole frame. Halloween is carried by props, ground colour and lamps, not by the light. Allowed exceptions: zone 5 Vampire Castle and the King throne may be purple dusk. Evidence: SAE1 Snow/Volcano frames (zone1-perspective-ref-3, zones-strip-ref-1) are flat cyan day and read from 100 studs. Our dusk hub (hub-perspective-sbs) and the orange cast over the HUD sheet kill contrast between the orange pumpkins and the orange trees. PS99H keeps a yellow sky but lit fully bright (hub-perspective-ref-1).
2. LIGHTING AND SHADING: flat, fully bright, soft single shadow under objects only. No rim light, no god rays, no bokeh depth of field. Evidence: REFS2 "Lighting is flat and fully bright".
3. SATURATION AND PALETTE: 3 base colours per scene plus one accent (hub: lime floor #6FD13A or purple, white fence, orange pumpkins, purple accent). Ground is ONE flat colour with at most a faint stud grid at 10% opacity; no patterned paths, no grass tufts, no flowers. Evidence: SAE green floor (zone1-topdown-ref-1), PS99 3-colour hub (hub-perspective-ref-1).
4. PROP DENSITY AND SIZE: 5-9 props in frame. Each is 3-5x avatar height for landmarks, 1-1.5x for pumpkins/pets. Remove tree walls, trellis, lanterns by the dozen, scattered flowers, hay clutter. Zone identity = 2-3 giant props plus a colour swap. Evidence: hub-perspective-ref-1, zones-strip REFS2 note "3-5 giant props, not many small ones".
5. CAMERA: gameplay shots only. Raised 3/4 camera 12-15 studs behind and above the avatar, wide FOV, avatar in the lower third, the lane visible to its far end. No overhead blueprint, no low hero angle, no exploded diagrams, no annotation callouts. Evidence: all three SAE/PS99 hub refs.
6. TEXT STYLE (1080p): rounded heavy font (Fredoka One / Luckiest Guy look), WHITE fill with a DARK stroke. Stroke 4 px on body text 28-32 px, 6 px on headers 56-72 px, 3 px on 20 px labels. No pill backgrounds behind HUD text. Currency numbers are gold or lime with the same stroke and an icon. Evidence: hud-desktop-ref-1 (stroked numbers), Bible font rule. Our soft pills fail this.
7. HUD COVERAGE: 10-12% of screen at launch, empty centre. Desktop: left column of 2 square icons only (Shop, Index; 72 px, icon + 18 px stroked label), bottom-left 2 currency lines (Candy, Carry) at 32 px, bottom-centre 2 hotbar slots 80 px with a corner number, top-centre goal text only (no box). Delete the timer plate, "Unlocks later" strip and the Carry banner. Evidence: hud-desktop-ref-1/3, hud-phone-ref-1, Bible Law 3, locked rule "Shop + Index only".
8. PHONE HUD: joystick 150 px bottom-left (semi-transparent ring, thumb dot), ONE jump button 110 px bottom-right, 2-slot tool bar centre-bottom 90 px each, Shop and Index as 64 px pills at the left edge. NO Steal/Smash buttons: interaction is a small hand-cursor icon and a 24 px stroked word ("Hatch!", "Steal") next to the object. "Drop" red pill appears only while carrying (about 18% width). Thumb zone clear. Evidence: hud-phone-ref-1/2/3 (SAEM).
9. GOAL AND GUIDANCE: ONE goal line, 3 words ("Smash a Pumpkin!"), white with dark stroke, top-centre at 40 px, no box. Floor guidance is red or yellow chevron arrows on the ground, plus a hand cursor on the target. Evidence: first-5-min-ref-2, hud-phone-ref-1 ("Hatch the Egg!").
10. PANEL STYLE: dark saturated purple gradient panel (#4B1D8F to #7A3FD0), 6 px lighter outline, cards are white or rarity-tinted with a 4 px rarity-coloured border, header 56 px stroked overlapping the panel top edge, red X 56 px at the top-right corner. Price/Buy buttons: glossy green #3DD13D with a light top lip, 60 px tall, 32 px stroked price with candy icon. Replace cream. Evidence: panels-shop-index-ref-1 (PS99 Castle Pack), panels-upgrades-daily-ref-1 for the upgrade-row grammar (white row, icon, 1-line effect, segmented bar, grey/green arrow button).
11. RARITY GLOW: every card and world pet/pumpkin gets a coloured glow plus the rarity word label: Common #B8B8B8, Rare #3D8BFF, Epic #A64DFF, Legendary #FFC83D, Mythic #FF3B3B, Secret rainbow gradient. Card border 4 px in the colour, 20 px soft outer glow, star badges per tier on the card corner. Evidence: hatch-reveal-ref-2 (star badges), scythes-ref-2 (aura carries rarity), Bible Law 7.
12. WORLD BILLBOARDS AND FLOATING TEXT: every earner/pet has a floating name tag with rarity-coloured word plus "$X/s" in lime with stroke (36-48 px at hero size). Floating "+1 Candy"/"+$" numbers scatter in the air at 24-32 px, white or gold, stroked. Every zone and boss has ONE giant world sign (zone name or "FINAL BOSS / Pumpkin King / Recommended: 120k Luck"), letters 1-2 avatar heights tall. Evidence: pets-ref-2 (Mutant Shark $1.5B/s), guards-and-king-ref-1, zone1-perspective-ref-3 (Volcano banner top-centre).
13. REVEALS HAVE A SKIP: every cutscene/reveal frame shows a "Tap to skip" 20 px stroked line bottom-centre. Reveal is ONE big pop: name card with rarity pill, rarity word, chance %, "NEW!" tile ribbon, a big green "Ok!" button 240x80 px. Mass hatch = wall of overlapping pets with name tags. Evidence: TIKTOK-DELTA rules 1, 2, 6 (oddboxstudioss clips, Brockodile shrine); hatch-reveal-ref-2/3.
14. ZONES = ONE COLOUR EACH: each zone changes sky, floor, wall AND lamp colour together, with one straight lane and a single yellow road line (#FFD23D, 3-4 studs wide) down the middle. Z1 Meadow: cyan sky, lime floor, tan wall, orange lamps. Z2 Graveyard: violet-grey sky, slate floor, cool-blue lamps. Z3 Haunted Woods: green-teal sky, dark green floor, lime lamps. Z4 Swamp: teal sky, murky mint floor, green lamps. Z5 Vampire: magenta dusk sky, crimson floor, red lamps. Z6 Candy: pink sky, lavender floor, white-pink lamps. Z7 Throne: gold sky, purple floor, orange lamps. Evidence: zones-strip-ref-1/2/3 and TIKTOK-DELTA rule 5 (7 biomes).
15. SHEET FORMAT: one in-engine screenshot per image, 16:9 (or 9:16 for phone), with NO sheet header, no palette swatches, no dimension arrows, no logo banner, no stud-spec boxes. Detail sheets (scythes, pets) may keep a clean grey or flat-colour backdrop but show items at in-game size next to the avatar. Evidence: TIKTOK-DELTA rule 16 (judge in-engine at gameplay distance with HUD hidden).
LOCKED (unchanged): one Pumpkin Pup design, faceless round pumpkins, launch HUD = Shop + Index only, rarity hexes above.

## 2. PER SHEET
Format: score | drop? | changes | refs to pass to generator.

**hub-perspective (6)** KEEP, hero sheet. Pass: hub-perspective-ref-1, hub-perspective-ref-2, hub-perspective-sbs (ours as base).
1. Switch sky to cyan day, remove sunset sun and haze (G1).
2. Cut trees, flowers, extra lanterns by 70%; floor flat lime/cream (G3, G4).
3. Raise camera slightly and widen FOV; avatar lower-third; show the whole plaza (G5).
4. Replace tiny Shop/Upgrades/Sell awnings with 3 big stalls with giant stroked words SHOP, SELL (3-4x avatar) (G12). Upgrades is later unlock, remove it from the launch hub.
5. Add one giant billboard over the King throne: "THE KING'S COMING IN 04:32" (G12), plus a red arrow trail on the floor to the first pen (G9).
6. Pens: fewer, 4 per side, bright chunky white/cyan fence 2-3x avatar width.

**hud-desktop (6)** KEEP. Pass: hud-desktop-ref-1, hud-desktop-ref-3, hud-phone-ref-1 (daylight look).
1. Day sky and neutral grade, remove orange cast (G1).
2. Remove "Unlocks later" strip, timer plate and the box around the goal; use stroked white 3-word goal at top-centre (G7, G9).
3. Currency lines 32 px stroked with icons; drop the soft dark pills (G6).
4. Shop/Index at 72 px, left column only; coverage target 10-12% (G7).
5. 2-slot hotbar with corner numbers, flat glossy stickers 80 px.
6. Reduce background to 5-9 big props; keep the lane and "HOME" arrow on the floor.

**panels-shop-index (6)** KEEP. Pass: panels-shop-index-ref-1, panels-shop-index-ref-3, panels-shop-index-ref-2.
1. Dark purple gradient panel instead of cream (G10).
2. Cards get rarity-coloured borders and glow, scythe art 70% of card height (G11).
3. Glossy FREE/price buttons with lip, 32 px stroked (G10).
4. Index: "????" cards plus count "3/12", left tab column, one tooltip (name, rarity, power) on the hovered card.
5. Shop header and X overlap the panel edge at 56 px stroked. Show one coloured bonus bar under the cards ("Weekly Pack"-style).
6. Show panel over a bright day hub, not the sunset patch.

**zone1-perspective (5)** KEEP, merge zone1-topdown into it. Pass: zone1-perspective-ref-3, zone1-perspective-ref-1, zone1-perspective-ref-2.
1. Flat day lighting, cyan sky (G1, G2).
2. Lane = two flat tan walls + lime floor + a yellow road line leading to the far graveyard gate (G14).
3. Delete the 40-pumpkin scatter; show 8-10 pumpkins plus the nest, scarecrow and windmill as the 3 giant props (G4).
4. Zone name banner top-centre "Pumpkin Meadow" with emoji, white with dark stroke (G12).
5. Remove the key-objects, scale and palette panels (G15).
6. Add a speed trail behind the runner and a floating "+1 Candy" (G12).

**zone1-topdown (3)** DROP, merge into zone1-perspective. If kept, redraw as an angled 3/4 shot (not overhead) using zone1-topdown-ref-1 (SAE fence pens, floating $ numbers), with ~8 pumpkins, a big GRAVEYARD sign and no text boxes.

**hub-topdown (3)** DROP, merge into hub-perspective (a blueprint adds nothing for art generation; layout data lives in CONCEPTS.md). Optional single reference: hub-topdown-ref-3 (SABH raised 3/4).

**zones-strip (4)** KEEP but redraw as 6 separate player-camera shots, 1 per zone, or 1 strip of 3 per image. Pass: zones-strip-ref-1, zones-strip-ref-2, zones-strip-ref-3.
1. One colour identity per zone, see G14 table; no purple/orange base everywhere.
2. Each frame from the player camera with the avatar and the yellow road line (G5, G14).
3. Giant zone title banner top-centre with emoji (G12).
4. Max 3 giant props per zone (the guard + 2 more), no small clutter (G4).
5. Daytime sky for Z1-Z4, Z6; dusk allowed only Z5 and Z7 (G1).
6. Remove swatch rows under each frame (G15).

**hud-phone (4)** KEEP, rebuild. Pass: hud-phone-ref-1, hud-phone-ref-2, hud-phone-ref-3.
1. 9:16 phone portrait or 19.5:9 landscape true frame; day sky (G1).
2. Delete Steal and Smash buttons; keep ONE jump button and joystick at G8 sizes.
3. Add a hand-cursor icon with "Smash!" 24 px word beside the pumpkin.
4. 2-slot tool bar bottom-centre; Shop/Index as small pills at left edge.
5. A red "RUN!!" pill 20% width only in the chase variant; "Drop" pill only while carrying.
6. Text stroked 4 px, no pills; coverage 10-12%.

**hatch-reveal (4)** KEEP, rebuild as TWO images (single-pop screenshot, and mass-hatch wall). Pass: hatch-reveal-ref-2, hatch-reveal-ref-3, hatch-reveal-ref-1.
1. Image A: "Pumpkin burst open!" popup: light-blue title bar, pet tile with Common grey glow, star badge, tooltip "Pumpkin Pup, Common, +1 Candy/s", giant green Ok! (G11, G13).
2. Image B: wall of 8-10 overlapping pets with name tags and glow, "New!" ribbons on tiles.
3. "Tap to skip" bottom-centre on both (G13).
4. In-world version: the pumpkin in the pen with a small "Hatch!" hand-cursor, then a floating name tag (hatch-reveal-ref-1).
5. Remove the 6-step storyboard, palette and notes strips (G15).

**scythes (4)** KEEP simplified. Pass: scythes-ref-2, scythes-ref-1, scythes-ref-3.
1. Show the avatar holding Rusty, Witch, King scythes in a day scene, items about 1 avatar tall, with a rarity aura (G11).
2. Hotbar with numbered slots showing the same 7 scythes at 40 px (readability test).
3. Delete the exploded blade, connection diagram, swatch rows (G15).
4. Keep silhouettes distinct by aura colour, not stud detail.
5. Shop card variant already covered by panels-shop-index (merge).

**pets (5)** KEEP. Pass: pets-ref-2, pets-ref-1, pets-ref-3.
1. Show 8-10 pets overlapping in a fenced bright lime pen, not a clean grid (G3, G4).
2. Each wears a floating name tag with rarity word colour and "$1.5/s" lime (G12).
3. Epic+ pets 2-6x avatar scale; keep the avatar next to Mythic for scale.
4. Rarity glow aura per tier (G11); Secret rainbow shimmer on one pet.
5. Keep the 12-pet catalogue as a SEPARATE simple flat-colour model sheet only if needed for 3D modelling, and mark it "reference only" (not a screenshot target).

**guards-and-king (4)** KEEP reduced to 2 images: (a) boss billboard + arena, (b) fight HUD. Pass: guards-and-king-ref-1, guards-and-king-ref-2, guards-and-king-ref-3. Not needed for first slice beyond the scarecrow; the King can slip to slice 2.
1. Arena: two-colour split field (lime vs purple) in daylight, boss at one end (G3).
2. Giant billboard: "FINAL BOSS / PUMPKIN KING / Recommended: 120k Luck / Win chance 50%" in stroked text (G12).
3. Boss name card variant with sunburst and "THE PATCH HAS BEEN BREACHED" subtitle, "tap to skip" (G13, TIKTOK rule 2/4).
4. Top-centre HP bar with portraits and number, "E to join" prompt (guards-and-king-ref-1).
5. Remove roster ladder, turnaround and silhouettes (G15). Scarecrow only for Z1.

**collectibles (4)** MERGE into pets/zone1-perspective; no standalone sheet. Pass: collectibles-ref-1, collectibles-ref-2.
1. Show collectibles in-world: clusters of glowing pumpkin orbs with additive glow, 1-1.5x avatar size (G11).
2. Floating "+1 Candy" white stroked text at the avatar, ground ring at the pickup radius.
3. Nest pumpkins per zone are tint-only swaps (G14), no separate row.
4. Candy as a 3-colour sticker icon only (currency icon).

**first-5-min (4)** KEEP as one 9:16 hero shot of "first 15 seconds", not six panels. Pass: first-5-min-ref-2, first-5-min-ref-1, first-5-min-ref-3.
1. Spawn on a day lane with a hand cursor on a pumpkin and a red floor arrow trail (G9).
2. Goal "Smash a Pumpkin!" top-centre, white text with stroke, no box.
3. FREE chest at the spawn with a "FREE!" green label.
4. Tiny stats strip bottom-left ($0 Candy), phone HUD per G8.
5. Optional "Skip Tutorial" pill (TIKTOK rule 12).

**panels-upgrades-daily (4)** DEFER/DROP for the vertical slice: Upgrades, Daily and Pets are "unlock later". If drawn later, use panels-upgrades-daily-ref-1 and ref-3 with G10 styling and a quest checklist with "Done!" green pills instead of a 7-day calendar.

## Merges and drops summary
Drop: hub-topdown, zone1-topdown, panels-upgrades-daily (defer). Merge: collectibles into pets+zone1-perspective; scythes shop card into panels-shop-index. Remaining redraw set: hub-perspective, zone1-perspective, hud-desktop, hud-phone, panels-shop-index, hatch-reveal (x2), pets, scythes, zones-strip, guards-and-king (x2), first-5-min = 12-13 images.

## 3. RE-SCORE CHECKLIST (per sheet, 1 point-ish each, then give the 1-10 score)
1. Screenshot test: reads as an in-engine gameplay frame at 1080p with no sheet header, swatches or blueprint annotations (G15).
2. Daytime test: cyan sky, no orange or sunset cast, flat bright light, one flat ground colour; dusk only in Z5/Z7 (G1-G3).
3. Prop test: 5-9 props, landmarks 3-5x avatar, no clutter field; zone is identifiable by one colour (G4, G14).
4. Text test: white with dark stroke, rounded heavy font, 4-6 px stroke, no soft pills; every number has an icon (G6).
5. HUD test: coverage at most 12%, empty centre, launch buttons Shop + Index only, one 3-word goal; phone has 1 jump + joystick, no extra action buttons (G7-G9).
6. Panel/reveal test: dark purple glossy panel, glowing rarity-coloured cards using the locked hexes, floating labels with rate, "tap to skip" on reveals (G10-G13).
7. Identity test: one Pumpkin Pup design, faceless round pumpkins, rarity hexes exact.
8. Side-by-side test: place next to the sheet's best ref (REFS2.md); pass only if the judge cannot say ours looks less polished or less readable. Score 8+ needs all of 1-7.
