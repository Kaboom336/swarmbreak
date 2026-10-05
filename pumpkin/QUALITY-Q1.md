# Pumpkin quality round Q1 (2026-10-05)

Zion's verdict on the screenshots: "not good enough". The game has to be comparable to today's best Roblox games.

References: /mnt/project-files/roblox/research/r7-media/ (Break and Steal an Egg, +1 Stone Skipping, Drill for Eggs, plus the thumbnails sheet).

## Side-by-side gaps, worst first
1. **World is dark and murky.** Every reference is bright midday: blue sky, saturated green, light-blue water. Ours is a night sky over a floating green slab with a void below.
2. **The HUD looks thin and empty.**
   - References have a dense left column of square icon buttons with drawn icons, a bottom level/power bar, multiplier chips ("Friend Boost +0%", "2.13K Multiplier") and currency pills with icons.
   - Ours has a few wide text buttons and big empty panels.
3. **Numbers don't fly.** References fill the screen with big "+1"/"+67K" popups, currency bursts and a distance meter during the run. Ours shows small popups, with no meter or counter fly-in.
4. **The thumbnail is a game screenshot.** References are illustrated scenes with these elements:
   - an expressive avatar doing the action;
   - a glowing rare item;
   - a progression contrast ("LEVEL 1 / LEVEL 999", "+1 → +9.2M");
   - 2-4 words of chunky text.
5. **The map is a row of identical fence walls.** References use themed breakables (eggs, ore, stones), varied terrain, trees all around, and no visible void.
6. **Pets are neon spheres.** References use real creature models.
7. **No social boost.** All three references show a Friend Boost.

## Codex task Q1-A (code only, on pumpkin/main)
testcmd: cd pumpkin && stylua --check src tests && selene src && lune run tests/run.luau && rojo build default.project.json -o out.rbxl

1. **Bright daytime look** in default.project.json Lighting:
   - ClockTime 13.5;
   - Brightness 3;
   - a warm autumn colour shift;
   - Atmosphere: light haze and blue-white colour;
   - ColorCorrection: saturation 0.25, contrast 0.1;
   - remove the night-only bloom threshold tweaks.

   Also add a MapFallback ground plane or skirt (big grass baseplate, 2000×2000, 30 studs below the play area, with trees as simple parts) so no void shows past the map edge, unless a part named `Ground` already exists.
2. **HUD rework to the reference layout.** Keep HudLayout pure, with specs at 667×375 and 1920×1080 checking no overlap and buttons at least 56 px.
   - **Left:** a 2-column grid of square icon buttons (Shop, Pets, Rebirth, Codes, Daily, Passes, Settings). Each has an ImageLabel icon from `Config.Icons.<Name>` (an asset id string, default ""). With no id, draw a simple vector glyph from Frames: no emoji, no text-only tiles. A small label sits under each icon, and a red notification dot shows when Daily is claimable.
   - **Top centre:** two compact currency pills (Size, Wins) with icons and abbreviated numbers. The number pops when it changes.
   - **Bottom centre:** the GROW button. Above it, a progress bar "Size → next wall" that shows how many walls the current Size breaks in the current zone (from Roll.simulate) and the progress to the next one.
   - **Bottom left:** multiplier chips: Pets ×N, Rebirth ×N, Friend Boost +N%, and 2x passes when owned.
   - **Right:** the zone and next-unlock panel stays, but smaller.
3. **Juice:**
   - Grow popups are 2× bigger, spread randomly around the pumpkin, colour-tiered by amount (white, yellow, orange, pink, rainbow gradient at 1K+), and scale-pop then rise.
   - Each grow sends a pumpkin-seed particle burst from the GROW button to the Size pill.
   - During a roll:
     - the camera follows from behind and above, with a FOV kick on each smash;
     - a big distance meter counts up at the top ("123 m");
     - each wall shows a "+N WINS" popup at the wall;
     - at the end, win coins fly from the screen centre to the Wins pill and its number ticks up.
   - All pooled, with at most 60 live effects.
4. **Friend Boost:**
   - +10% Size per friend in the same server, max +50%. Pure function plus a spec, applied in the server grow multiplier.
   - Shown as a chip.
   - Use Player:IsFriendsWith on the server, cached per pair and refreshed on join and leave.
5. **Pets look:**
   - If `ServerStorage.PetModels.<PetName>` exists, clone it; otherwise build a cute placeholder: a body with 2 eyes and ears or horns from parts, coloured by rarity, with no Neon on the body.
   - Pets bob, and Legendary pets get a sparkle ParticleEmitter.

Done when: the gate is green, there are new specs for HudLayout, Friend Boost and the wall-progress bar, and there are no new remotes without a rate limit.

## Studio task Q1-B (Play, when the laptop is back)
1. **Map:**
   - Rebuild into a bright day map: terrain hills and grass around everything, autumn trees (orange and yellow), no void.
   - Each zone's track goes steeply downhill.
   - Walls become themed breakables: Patch has hay bales and pumpkin stacks; Forest has log piles; Graveyard has tombstone walls; Castle has stone or candy walls. Keep the names `Wall_n`.
2. **Pets:** 15 pet meshes via generate_mesh (5 per egg, cute cartoon Halloween animals: bat, cat, ghost pup, candy bunny, pumpkin dragon and so on), under `ServerStorage.PetModels.<PetName>`, with names matching Pets.luau.
3. **HUD icons:** 8 button icons (shop bag, paw, rebirth arrows, gift code, calendar, gamepass ticket, gear, star) as flat cartoon PNGs. Upload them, then put the IDs in Config.Icons.
4. **Thumbnail v2,** in the reference style:
   - an avatar posed with a giant glowing pumpkin smashing through a wall;
   - a split "+1 → +1M" or "SIZE 1 / SIZE 999K";
   - a bright day background;
   - 2-4 chunky words.

   Also an icon: the avatar's face plus the glowing pumpkin.
5. **Proof:** record a real-input playthrough of the first 60 s and take 4 screenshots at the reference angles, for the re-judge.

## Re-judge
After Q1-A and Q1-B land, put new screenshots next to the references for each aspect: thumbnail, map, HUD, juice, pets and the first 60 s. Each aspect must match or beat the references. Anything that doesn't goes into Q2.

## Codex task Q2-A (retention layer; queue after Q1-A merges)
Source: research/r8-sim-polish.md. Genre conventions only; the search tool returned no page text.

testcmd: cd pumpkin && stylua --check src tests && selene src && lune run tests/run.luau && rojo build default.project.json -o out.rbxl

1. **Free first egg and starter gift.**
   - A new player's first hatch of the Candy Egg is free.
   - Within the first 30 s, a one-tap "CLAIM" starter gift gives 50 Wins and a 5-minute Lucky Potion.
   - Both are stored in the profile. Pure logic plus specs.
2. **Playtime gifts.**
   - 8 gifts at 1, 3, 5, 8, 12, 17, 23 and 30 minutes of session time. Rewards are Wins, Size boosts, a Lucky Potion and, last, a free Spooky Egg hatch.
   - A HUD gift button shows a countdown to the next gift and a red dot when one is claimable. The panel shows all 8.
   - Session time is tracked on the server and resets each server join, which is the genre norm.
   - Pure schedule plus specs.
3. **Pet Index.**
   - A collection book with every pet per egg, discovered or not (a silhouette until found).
   - Completing an egg's page gives +10% permanent Size.
   - Pure completion logic plus a spec.
4. **Two new passes, IDs 0 until Zion creates them:**
   - Auto Hatch, 149: hatches the nearest egg every 3 s while you stand within 15 studs.
   - 2x Luck, 199: stacks with the potion.

   Also a **Starter Pack** dev product (99): 1,500 Wins, 3 Lucky Potions and a guaranteed Epic pet. It's offered once after the first hatch, with a 30-minute countdown chip, and hidden while its ID is 0.
5. All new buttons follow the Q1 HUD grid and depth stack. Every new remote gets a rate limit.

Done when: the gate is green, with specs for the gift schedule, the free first hatch (only once), Index completion, and the starter pack (one purchase only, idempotent).
6. **Smooth pet follow:** move the follow loop from the server Heartbeat to the client (RenderStepped), for all players' pets. The server only parents the models; the client sets their CFrames.

## Codex task Q3-A "Ride and smash" (only if Zion picks it on the card; queue after Q2-A)
Why: the grow-then-cash-in loop is right, but the cash-in is passive. Make it the best moment in the game.

1. **Ride:** stepping on the start pad seats the player on top of their pumpkin, which rolls downhill on its own and speeds up with the slope.
   - The player steers left and right: A/D on keyboard, thumbstick or tilt buttons on mobile.
   - The server stays authoritative: Roll.simulate still decides the walls broken and the wins. Steering only collects bonuses.
2. **Bonus targets along the track:**
   - candy piles: +10% wins each;
   - gold pumpkins: ×2 wins;
   - speed pads.
   - Spawn positions are seeded per roll and validated by the server: the client reports a pickup, and the server checks the pumpkin's time and lane against the seed. Cap: 6 pickups per roll.
3. **Smash:**
   - each wall breaks into 12-20 pooled chunks with physics-like arcs (client-side, tweened), plus a shockwave ring;
   - hit-stop 0.05 s, a camera shake scaled by wall index, a rising pitch per wall in a combo, and a "WALL x7!" combo counter;
   - the final stop gives a big "+N WINS" plus the coin fly.
4. **Camera:** behind and above the pumpkin; FOV rises with speed.
5. **Specs:** seeded bonus layout is deterministic; pickup validation rejects the wrong lane or time; the wins math with bonuses; the combo counter.

## Codex task Q2-B: HUD fixes from Play's Studio check of 2d3a9ad (queue right after Q2-A, before Q3-A)
1. The multiplier chip panel at the bottom left overlaps the GROW button at 1399×1080. Add the chips to HudLayout as their own rect, and extend the no-overlap spec to cover the chips (and every Q2 button) at 667×375, 1399×1080 and 1920×1080.
2. Chip text is dark purple on purple. Use white text with a dark stroke, and set a contrast rule: chip text is always white or near-white.
3. The roll distance meter ("76 m") draws over the Size/Wins pills. Put it in its own HudLayout rect below the pills, and add it to the no-overlap spec.
4. At Size 16-24 the head pumpkin fills the camera. Fix it two ways:
   - cap the head pumpkin's visual diameter relative to the character (about 3× character height);
   - push the camera zoom out (CameraMinZoomDistance plus the default zoom scaled to the pumpkin diameter).
5. Use Config.Icons.Size for the Size pill. Play will supply the asset ID.

## Re-judge at d8ec9a7 (Play's 8 shots, 10:40Z)
- **Matches the references:** the icon-button grid; the Gift button's red dot and countdown; the daylight map; the themed pumpkin-stack walls; the pets.
- **Worse than the references:** text contrast, centre clutter, camera distance and number formatting.

## Codex task Q2-C: HUD readability and camera (queue next)
1. **Contrast rule, applied everywhere:** every label on a coloured panel or button is white or near-white with a dark (#2a0e3d) 2-3 px UIStroke. Today, dark purple text on purple fails on the tutorial banner and the multiplier chips, and orange text on orange fails on the GROW button. Add a spec that scans the HUD builder, plus a pure `Style.label(...)` helper that every label uses.
2. **Keep the centre clear**, as the references do.
   - Move the tutorial banner to the top, under the Size/Wins pills, at a smaller size. It must never cross the character.
   - Hide the banner during a roll and once TutorialDone is set.
   - Hide the wall-progress bar during a roll; the distance meter replaces it.
   - Move the multiplier chips into a small vertical stack at the bottom left that never touches GROW. They are their own HudLayout rect, and the overlap spec must cover them at 1399×1080, 1920×1080 and 667×375.
3. **Number format:** Size and Wins show as whole numbers or abbreviations (48, 1.2K, 3.4M), never "48.0". The same goes for the progress bar ("4 WALLS • 48 / 66 TO NEXT"). Pure `Format.abbrev`, with specs.
4. **Camera:**
   - The default third-person distance is about 2.2× the pumpkin's visual diameter plus 8 studs, with a minimum of 14.
   - The camera pitch looks slightly down, so the pumpkin never covers the top third of the view.
   - Keep the per-player MinZoomDistance from Q2-B, but make the starting zoom this value (set CameraMinZoomDistance briefly, then release it).
5. **Toasts** ("You need 100 Wins!") show at the top centre under the pills, above every panel, including the Pets panel.

Done when: the gate is green, with specs for the contrast scan, Format.abbrev and the HudLayout overlap (chips, banner, meter, GROW, grid) at all 3 sizes.
