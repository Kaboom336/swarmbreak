# Steal a Pumpkin — concept builder guide

15 current PNG concept sheets. Redraws and corrections used the built-in imagegen tool only. Ten original targets have .v1.png backups. panels.png is replaced by two current sheets. No game code edits or commit.

Checked: existing sheets, hatch-reveal.png identity, combat-boss/TARGET.md, full PatchConfig.luau including later additions/rarity overrides, and existing Steal an Egg / Pet Simulator 99 reference boards. Existing kit and assets reused as references; no external game code or art downloaded. Reference redistribution licence UNKNOWN; _refs are review material.

## Locked build rules — 2026-10-11

- Pumpkin Pup authority: hatch-reveal.png. Chubby orange studded voxel puppy, green head stem, big black eyes with square white highlights, cream muzzle/chest/paws, black nose, short four legs and little tongue.
- Rarity tokens: Common **#B8B8B8**, Rare **#3D8BFF**, Epic **#A64DFF**, Legendary **#FFC83D**, Mythic **#FF3B3B**, Secret **rainbow gradient**. Exact tokens govern implementation; generated gloss/shading is not an exact pixel swatch.
- Wild pumpkins: round, ribbed, orange, stemmed, faceless. Nest pumpkins: same shell with whole-shell orange/ghost-lavender glow in Zone 1; no glowing eyes/mouth. Guards and King retain their character faces.
- Zones: **1 Pumpkin Meadow, 2 Graveyard, 3 Haunted Woods, 4 Witch Swamp, 5 Vampire Castle, 6 Candy Kingdom, 7 Pumpkin King's Throne**.
- Boss weak point: **glowing face only**, green **12 / 35** HP tag, **Hit the glowing face! x2** banner during 6-second opening. No chest crystal.
- Launch HUD: left Shop/Index only; bottom-left Candy + income/s + Carry 1/3; one goal banner; one glowing ground arrow; small top-right King timer; two-slot hotbar scythe/carried pumpkin. Mobile adds joystick, SMASH, STEAL, JUMP. No quests/progress/extra system tiles; at most one small toast.
- Numeric stud dimensions below govern building; generated diagrams are approximate visual targets. No runtime/camera/mobile test is claimed.
- Warm peach/lavender sunset, muted green terrain, cream paths, grape/orange walls, PS99 rounded bevel UI. Four unrequested sheets retain original artwork; these locks override older inconsistencies in them.
- .v1 and _refs files are not current builder sheets and are excluded from _sheet.jpg.

## hub-topdown.png

- Hub 248 × 160 studs; straight north lane 120 studs wide.
- Exactly 8 pens: four west, four east; each 38 × 28 studs.
- King throne 40 studs high; paths at least 12 studs clear; 8 plaza lanterns.
- Three stalls: Shop, Sell, Upgrades. South spawn, north Pumpkin Meadow gate.
- Grass #8CC765/#84BD5E, paths #FBF1DC, walls #7A4FD0/#8A63DE, caps #FF8A1F.


## hub-perspective.png

- Eight pens, four each side; stalls Shop, Sell, Upgrades in side alcoves; north gate 1 Pumpkin Meadow.
- Central throne **40 studs** beside **5.5-stud avatar**, about **7.3× player height**; same-baseline inset.
- Pens: Pumpkin Pup, Crow, Ghosty, Black Cat, Candy Bat, Golden Pup, Bone Pup, Frost Owl only.
- Locked orange Pumpkin Pup; round faceless pumpkins; cream rails, grape posts, straw floors.
- Clear routes at least 12 studs. Environment sheet omits HUD; default-camera sightline needs Studio verification.

## zone1-perspective.png

- Pumpkin Meadow: 120 wide × 160 deep; walls 25 high, side paths 12 wide.
- Grass #9ED66A/#96CE62; tan walls #E8B87A/#F0C88E; orange caps #FF8A1F.
- One active Scarecrow guard, config height 11 studs; one nest with 3 concept Ghost pumpkins.
- Config maximum 40 wild pumpkins; round ribbed shells with stems, never cubic cores.
- Escape SOUTH HOME across the safe line; Graveyard gate north is progression.
- Five prop families: hay, windmill, pumpkin sign, decorative scarecrows, lanterns.


## zone1-topdown.png

- Dimension authority: 120 WIDTH × 160 DEPTH, 25 wall height, 12 path width.
- North Graveyard; south HOME. Escape arrow points down/south from nest.
- Starter nest 15–25 studs beyond south entry; one 11-stud guard directly adjacent.
- 40 round wild pumpkins; three pale Ghost nest pumpkins; match perspective palette.


## zones-strip.png

- Six panels: **2 Graveyard, 3 Haunted Woods, 4 Witch Swamp, 5 Vampire Castle, 6 Candy Kingdom, 7 Pumpkin King's Throne**.
- Guards fill about half each scene height; lane floors and routes remain readable.
- Skeleton Knight 9, Tree Ent 13, Swamp Toad 16, Vampire 18, Candy Golem 20, Pumpkin King guard 24 studs.
- Landmarks: crypt, hollow tree, cauldron, castle, candy factory, throne.
- Round ribbed faceless orange wild pumpkins; lanes 120 × 160, walls 25 studs.
- Original floor/wall palettes retained; Swamp floor muted mint, never blue.

## hud-desktop.png

- Launch HUD only: Shop/Index left; Candy, income/s, Carry 1/3 bottom-left.
- One top-centre goal, one glowing ground arrow toward HOME patch, small King timer top-right.
- Exactly two hotbar slots: scythe, faceless round carried pumpkin; avatar holds it in both hands.
- No quests, progress bar or extra system tiles. Gameplay centre clear.
- Edge inset **UNLOCKS LATER: Upgrades • Daily • Pets** is builder guidance outside live HUD.
- Design target 1920 × 1080; illustrated counters are examples.

## hud-phone.png

- Roblox mobile landscape; wide gameplay frame with separate builder footer.
- Shop/Index top-left; joystick bottom-left; Candy/income/carry directly above it.
- Big orange SMASH and purple STEAL, smaller purple JUMP bottom-right.
- One goal, one ground arrow toward patch, small King timer, exactly two hotbar slots.
- Locked Pumpkin Pup; faceless round pumpkins; no quests/progress/extra menu tiles.
- Later-unlock strip outside gameplay. Targets: 32 logical px safe inset, 48 logical px minimum tap area; Studio mobile verification pending.

## panels-shop-index.png

- Two large panels in cream/grape/orange PS99 kit; purple close buttons, larger labels.
- Scythes tab: four visible cards Rusty FREE, Iron 150, Bone 1.2K, Witch 9K; chevron for later tiers.
- Iron silver/grey, Rusty brown; green purchase buttons.
- Index exactly **3 columns × 4 rows = 12 tiles**: three revealed, nine silhouettes.
- Pumpkin Pup Common, Ghosty Rare, Candy Bat Epic; locked rarity borders, 3 / 12 count, one Claim button.
- Remaining seven-tier names/prices are Rusty/Iron/Bone/Witch/Vampire/Candy/King at 0/150/1,200/9,000/60,000/400,000/2,500,000 Candy.

## panels-upgrades-daily.png

- Separate **later-unlocked** modal designs; never place their tiles in launch HUD.
- Upgrades: Carry Capacity, Swing Power, Pen Slots; large before/after values, costs, green/grey arrows.
- Daily exactly seven tiles arranged 4 + 3; Day 1 Claim, other days locked.
- Values/rewards illustrative; use live config. Round faceless pumpkin rewards; no invented pets.

## hatch-reveal.png

- Six beats: place, crack, shell open, pet pop, rarity/name/income, New! toast.
- Reveal timing: 0/.3/.6/1/1.5/2.2 seconds AFTER hatch wait. Config wait remains 6 s new-player, 8 s Orange, 20 s standard.
- Round lobed hollow pumpkin; curved rind and cream seeds, no block core. Cream rails/grape posts/straw floor.
- Same studded voxel Pumpkin Pup; Common grey, income green +1 Candy/s example, green Collect.
- Effect target: at most 8 rays and 12 spark chips; avoid covering gameplay.


## scythes.png

- Exactly seven tiers: Rusty, Iron, Bone, Witch, Vampire, Candy, King.
- Rusty reddish brown blade/taped wood shaft; **Iron silver/grey metal**, dark grey shaft, riveted collar.
- Blades use **3–5 large chunky block/wedge parts** with visible seams; exploded examples show four pieces.
- Motifs: tape, rivets, skull, mint gem, bat wings, pinwheel, crowned pumpkin medallion.
- 2–3 base colours plus glow; about 6-stud shafts; held pose against 5.5-stud avatar.
- Technical inset replaces unnecessary world/HUD. Validate actual grip, swing and part counts in Studio.

## pets.png

- **12 roster designs only**: Pumpkin Pup, Crow, Ghosty, Black Cat, Candy Bat, Golden Pup, Bone Pup, Frost Owl, Lava Slime, King Cat, Gummy Bear, Pumpkin Dragon.
- Full config contains 15 pets. Selection uses original ten plus Gummy Bear and Pumpkin Dragon; Moth, Toad and Pumpkin Kinglet are not depicted. No PROPOSED tags.
- Final config rarities: Pumpkin Pup/Crow Common; Ghosty/Black Cat/Bone Pup Rare; Candy Bat/Golden Pup/Frost Owl Epic; Lava Slime/Gummy Bear Legendary; King Cat/Pumpkin Dragon Mythic.
- Exact hatch-reference orange Pumpkin Pup; studded voxel bodies, stepped ears/wings/tails, 2–3 base colours.
- Size targets against **5.5-stud avatar**: Common 3.2, Rare 3.9, Epic 4.7, Legendary 5.7, Mythic 7 studs.
- Same-baseline silhouettes show size progression; numeric values govern construction. Secret rainbow is only a palette swatch.

## guards-and-king.png

- Seven zone guards; Zone 1 Scarecrow 11, Zone 7 Pumpkin King guard 24 studs.
- Separate King boss **40 studs**. Size ladder: **Player 5.5 / Zone 1 guard 11 / Zone 7 guard 24 / King 40**.
- Orange crowned head, purple armour, gold fists, walking feet and separate arms.
- **Face-only glowing weak point**, green 12 / 35 HP tag; face opens 6 seconds, not a six-second stun.
- Exact opening banner: **Hit the glowing face! x2**. No chest crystal.
- Fight inset: dull purple arena, one segmented boss HP bar, one timer; red floor telegraph and attacking-fist outline, slam wind-up 1.5 seconds.
- HP examples are illustrative. Build targets override approximate silhouette ratios.

## collectibles.png

- **Zone 1 only** primary catalogue: wild orange pumpkin, ghost-lavender pumpkin, glowing nest pumpkin, carried pumpkin, wrapped candy.
- All pumpkins round/ribbed/stemmed/faceless; no cube cores. Nest glow covers the whole shell.
- Avatar 5.5 studs carries same pumpkin in both hands; wrapped candy target 1.5 studs wide.
- Small per-zone nest strip: **1 Ghost, 2 Moon, 3 Golden, 4 Shadow, 5 Crystal, 6 Inferno, 7 King's Seed**.
- Item state does not assign rarity; no invented rarity pills.

## first-5-min.png

- Six beats: spawn, smash, steal/chase, place, hatch, first gate; same avatar and locked orange Pumpkin Pup.
- Target timeline 0:00 / 0:08 / 0:15 / 0:20 / 0:26 / 3:00–5:00; not measured results.
- Spawn goal **Steal a Pumpkin!**, arrow toward **1 Pumpkin Meadow**. Chase escapes **SOUTH HOME**, away from northern guard.
- **Purple Drop button**; red RUN means danger. Placed interaction **E Hatch!**.
- Round faceless pumpkins, hollow curved rind/cream seeds, one candy floater.
- Pup in hatch/gate beats matches hatch-reveal.png; Common grey, green +1 Candy/s.
- Final gate **2 Graveyard**, shown price 1,000 Candy. Storyboard vignettes omit full HUD; two HUD sheets are launch authority.

## Review limits and lessons

Visually checked all 11 new current sheets against the requested locks and existing Steal an Egg / PS99 references. Used targeted built-in imagegen corrections for cubic pumpkins, face-shaped nest glows, stale rarity labels, extra HUD and misleading rulers. Independent read-only critic reviewed all 11 changed PNGs, the contact sheet, hatch reference, model/UI reference boards, boss TARGET and final config rarity overrides: PASS, no serious mismatch requiring another redraw. No numeric score assigned. Scale drawings remain approximate; runtime behavior was not tested. Studio scale/camera/mobile checks remain UNKNOWN.

- When a config mutates its roster later, read the overrides because the first table can contain stale rarities.
- When generating nest pumpkins, request whole-shell glow because localized light can become a jack-o-lantern face.
- When comparing scale, use one baseline because perspective and labels alone can hide wrong proportions.


