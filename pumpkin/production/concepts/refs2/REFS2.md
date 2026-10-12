# REFS2: real-game reference frames per concept sheet

Frames are 1280-wide full frames from 720p downloads. Timestamps are the video time shown on the 10-second frame sampling (+/- 10 s). Best ref per sheet is in `<sheet>-sbs.jpg`.

Videos (all uploaded within 6 weeks of 2026-10-11):
- PS99H = Pet Sim 99 Halloween update, 2026-10-06, https://www.youtube.com/watch?v=hKdUr4K5c5Q
- PS99B = Pet Sim 99 Blood Moon guide, 2026-10-10, https://www.youtube.com/watch?v=hQdosQq0qIQ
- SAE1 = Steal an Egg "I Became the #1 Player", 2026-09-03, https://www.youtube.com/watch?v=edX3_ddAY70
- SAE100 = Steal an Egg 100 days, 2026-09-23, https://www.youtube.com/watch?v=0sqILTHsdU8
- SAEM = Steal an Egg on mobile (new player), 2026-09-25, https://www.youtube.com/watch?v=9oAKkx6stEQ
- SABH = Steal a Brainrot Halloween update, 2026-10-10, https://www.youtube.com/watch?v=vc9J1sf4yks

Grow a Garden and Plants vs Brainrots videos found were all older than 6 weeks (a Grow a Garden fairy-update video was downloaded but its frames were not used). Steal an Egg "Divine" video (2026-10-07) failed to download (HTTP 403). Caveat: the Halloween Pet Sim 99 and Steal a Brainrot frames are the closest theme match; the Steal an Egg frames are the closest mechanic match.

## hub-topdown
Refs: 1 SAE1 1:40; 2 SAE1 4:00; 3 SABH 1:40 (best).
- Refs use a raised 3/4 camera, not a plan view: the hub reads through fence lines and a few huge signs (SHOP, COLLECT ZONE). Ours is an annotated blueprint with 20+ labels.
- Plots are bounded by one chunky, brightly coloured fence (cyan/white, 2-3x avatar width) that reads from 100+ studs; ours uses thin rails.
- Floor is one flat saturated colour (green or purple) with almost no texture, so props pop; ours has patterned paths, grass and planters.
- Floating income numbers ("+$1.5B") cover the ground, so output is visible from the air.
- Landmarks are 3-5x the avatar with distinct silhouettes.

## hub-perspective
Refs: 1 PS99H 4:30 (best); 2 PS99H 4:20; 3 SAEM 0:00.
- Default camera sits about 12-15 studs behind and above the avatar with wide FOV, showing the whole plaza plus sky; ours is a low cinematic hero angle.
- PS99 hub uses 3 colours (lavender stone, yellow sky, orange accents) in flat, low-contrast shading; ours has dense voxel noise (trees, flowers, lanterns) that muddies the read.
- One giant billboard per event (boss name, luck, coins) in thick-stroke text above the arena.
- SAE spawn: a single huge word ("TRAILS SHOP") plus a red arrow trail on the floor leads to the first action.
- Clean sky gradient, no heavy haze or vignette.

## zone1-perspective
Refs: 1 SAE1 2:50; 2 SAE100 0:50; 3 SAE1 3:00 (best, Volcano).
- Lane is a straight corridor of two flat walls and a flat floor; zone identity comes from 2-3 big props and a colour swap, not detail.
- Zone name banner top-centre in white stroked text with an emoji.
- A bright coloured speed trail follows the runner and points at the lane end.
- Lighting is flat and fully bright; ours is dusk-lit with strong shadows and foliage clutter on both sides.

## zone1-topdown
Refs: 1 SAE1 1:30 (best); 2 PS99H 2:50; 3 SAE1 4:10.
- Pens are simple rectangles with clear gates, each holding one hero object with a big label; ours packs about 40 pumpkins in a grid.
- Income popups scatter over the floor and double as visual density.
- The PS99 hatch arena is a two-colour split field (green vs purple), readable instantly from above; use that for the king arena.

## zones-strip
Refs: 1 SAE1 0:40 Snow (best); 2 SAE100 1:50 Prehistoric; 3 SAE100 1:10 Angels.
- Each zone swaps floor colour, wall colour and sky together (snow: white floor, blue sky), so a zone is identified by one colour. Ours keeps a purple/orange base in most zones.
- Zone title is a big floating text banner; our strip uses small captions.
- Shown from the player camera with the avatar for scale; ours shows characters on flat cards.
- 3-5 giant props per zone, not many small ones.

## hud-desktop
Refs: 1 PS99H 3:30 (best); 2 PS99H 4:30; 3 SAE1 1:40.
- PS99: left column of 6 small square icons (no labels), 3 currency lines bottom-left, numbered 7-slot hotbar bottom-centre, quest text top-right. SAE: two tiny pills left, two round icons right. Ours: two big labelled tiles, text stack bottom-left, plus a banner and a timer.
- Their HUD covers about 10-12% of the screen; ours is roughly 20% plus the "Carry it to your patch!" banner.
- All text has a thick dark stroke; ours uses soft pill backgrounds.
- Every number has an icon and abbreviation (62.5b, 2.47m).
- Hotbar tools are flat glossy stickers with a corner number.

## hud-phone
Refs: 1 SAEM 1:20 (best); 2 SAEM 1:40; 3 SAEM 4:30.
- Real phone HUD: a small joystick (bottom-left), ONE jump button (right), a 2-slot tool bar (centre bottom), Shop/Index pills at the left edge. Ours draws 3 large action buttons plus a joystick that would cover the field.
- Context prompts are tiny hand-cursor icons beside the object ("Hatch!"), not extra buttons.
- A red "Drop" pill appears only while carrying; "RUN!!" is a dark-red pill about 20% wide.
- Text is small, heavily stroked; ours is larger and softer.

## panels-shop-index
Refs: 1 PS99H 20:00 (best); 2 SABH 1:50; 3 PS99H 19:50.
- PS99 panels use a dark saturated purple gradient with glowing item cards, rarity-coloured borders, big FREE/price buttons with a glossy lip, and a second coloured bar for bonus rewards. Ours is cream with flat colours.
- Item art is high-contrast and large in the card; our scythes are small in theirs.
- Tooltips (name, rarity, power, supply) on hover; ours has none.
- Index shows "????" cards with a mini team strip and a tab column; ours is a flat silhouette grid.
- Header text is 50+ px stroked and overlaps the panel edge; ours is similar, so this part is on par.

## panels-upgrades-daily
Refs: 1 PS99H 6:20 (best); 2 PS99B 5:40; 3 PS99B 7:50 (Season Pass dailies).
- Upgrade rows: white card, icon left, name, one-line effect, segmented bar, cost with icon, square grey/green arrow right. Ours is close, but our cost button is wider and the icons larger.
- Rows scroll 4 at a time; ours has 3 rows plus a large header.
- Daily/season quests are a checklist with progress bars, "Done!" green pills and a Top Prize card; ours is a 7-day calendar grid.
- Panel opens beside a glowing world marker with a floating header.

## hatch-reveal
Refs: 1 SAEM 2:30 (SAE hatch); 2 PS99H 8:10 (best, 9-reward popup); 3 PS99H 19:00 (mass hatch).
- SAE has no cinematic: the egg is in the pen, a small "Hatch!" prompt, then a name tag floats ("Common Golden Chicken $2/s").
- PS99 reward popup: light-blue title, rarity splash and star badges per tile, tooltip, giant green Ok! button.
- Mass hatch is a wall of pets with name tags, glow and speed-blur; ours is a 6-step storyboard. Real reveals are about 2 s with one big pop and a rarity word.
- "New Item!" tiles rise from the player in a grid.

## scythes
Refs: 1 PS99B 0:40; 2 PS99H 2:00 (best); 3 PS99B 7:20.
- Held tools are about 1 avatar tall, flat colour with a glow aura; silhouette and outline carry the read, not stud detail.
- Rarity is told by aura colour (cyan flames on the reaper) more than shape.
- The held item has a numbered hotbar slot; check that ours reads at about 40 px.
- Ours is a detailed exploded blueprint, good for modelling but not yet tested at in-game size.

## pets
Refs: 1 PS99H 19:00; 2 SAE1 7:20 (best); 3 SAE1 4:20.
- Pets are huge relative to the avatar (Mutant Shark about 6x) and each wears a floating label: name, "$1.5B/s".
- Bold flat colour with a glowing eye or gem; PS99 pets are plush 3D with 2-3 colour blocks.
- Mass shots overlap 8-10 pets; ours is a clean catalogue grid of 12.
- Rarity tab per card in the catalogue (we already match this).

## guards-and-king
Refs: 1 PS99H 4:40 (best); 2 PS99H 15:50; 3 SAE100 2:30 (Rift event).
- Boss is introduced by a giant billboard: "FINAL BOSS", name in large stroked text, "Recommended: 120k Luck", win-chance line. Our sheet has no in-world billboard.
- Fight HUD: long top-centre bar with two portraits and numbers, plus an "E" prompt to join.
- Arena is a bright two-colour field (green/purple) with the boss at one end.
- Reward grid appears over the player immediately after the win.
- SAE events use a top-centre progress bar ("Charge the EMP Bar") and chat-style speech lines.

## collectibles
Refs: 1 PS99H 1:00 (best); 2 PS99H 7:00; 3 SAEM 4:20.
- Collectibles are glowing white orbs in clusters; "+X1 Luck" pops in white at the avatar.
- World items are 1-1.5x avatar size with additive glow in a 3-colour palette.
- Large collect radius (magnet) with instant text feedback.
- Ours is a clean catalogue; add pickup particles, floating "+1" text and a ground ring.

## first-5-min
Refs: 1 SAEM 0:10; 2 SAEM 2:10 (best); 3 SAEM 2:40.
- First steal prompt within about 15 s, first hatch at about 90 s. One 3-word goal at top centre ("Hatch the Egg!"), white with dark stroke, no box.
- Red floor arrows and a FREE chest at spawn guide the player; ours uses a text banner plus a callout.
- A hand cursor sits on the object to interact with; no popups.
- Stats strip is tiny at bottom-left ($0, then $197, $613 climbing).
- Ours is six storyboard panels; real flow changes the instruction the second a step completes.

## Top cross-cutting gaps
1. Camera and clarity: refs are flat-lit, saturated, with few large props; ours is dense dusk-lit voxel clutter.
2. UI text: heavy dark-stroke text everywhere plus world billboards; ours uses soft pills.
3. HUD size: 10-12% coverage, small label-free icons; ours is larger and wordier.
4. Panels: dark gradient, glowing rarity cards, glossy price buttons, tooltips; ours is flat cream.
5. Scale and feedback: giant pets and bosses, floating numbers, "New Item!" tiles, mass hatch walls; ours is calm.
