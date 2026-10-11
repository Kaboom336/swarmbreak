# first-5-min TARGET (spawn view, first objective, tutorial cues, first reward)

## Chosen game and why
**Steal an Egg (current build).** Cleanest new-player funnel on the platform: spawn facing a lane of eggs, three one-line prompts ("Steal an Egg!", "Hatch the Egg!", "Place your Pet!"), a first pet reward at about 0:26 and a big free Index claim at 0:36, all without a popup or a loss. Same steal-then-hatch loop as ours (pumpkin = egg).

Source: "Starting OVER Using NO ROBUX in Steal an Egg" (YouTube 4JdUNbmTBtw, uploaded 2026-09-03, a true fresh-account run), first 5:30 studied. Newer Oct 2 and Oct 10 uploads exist but start with gamepasses or an update recap, which hides the real first-time flow. Frames upscaled from 854x480.

## Frames (what to notice)
1. **ref-1** (0:12, "Steal an Egg!"): the prompt is one 3-word line at top-centre, white with black outline, no panel. Eggs sit loose within 15 studs of spawn, with one sleeping chicken guard ("ZZ") beside them. HUD already tiny: Shop + Index left, two round icon buttons right, speed + cash bottom-left, one clock bottom-right.
2. **ref-2** (0:18, "Hatch the Egg!"): the carried egg sits next to the avatar with a billboard "Egg Ready!"; the instruction changes the instant the previous step completes. The pen fence is the world-space guide.
3. **ref-3** (0:26, reveal): the first pet reveal is a big "Common / Golden Chicken / $2/s" card with a cartoon hand cursor pointing at where to place it; income is stated in the reveal itself.
4. **ref-4** (0:36, Pet Index): the first Index entry gives a free claim (+$100 cash and +420 speed) while the rest of the page is silhouettes with "???" (progress bar 1/8). Speed jumps from 10 to 430 in two seconds: the first reward feels huge.
5. **ref-5** (1:32, "Upgrade your Pen!"): the next goal arrives once cash has built up ($5,100), with a red "!" on the fence; a fresh 2/8 Index claim and a rare Raccoon ($45/s) landed in the first 90 s.

## Timeline we measured
0:12 first prompt | about 0:14 first egg carried | 0:18 hatch | 0:26 first pet ($2/s) | 0:28 first money tick ($12) | 0:36 Index claim | 0:52 second steal | 1:32 pen-upgrade prompt | about 3:20 clock for the next event. Note: a Robux prompt appears at about 1:40 only because the player tapped the x2 Speed shop button; the game itself never forces one.

## Ours must...
1. Spawn view: the avatar spawns facing the first interactable (a pumpkin nest) at 15-25 studs, in front of the camera at default zoom, with the Pumpkin King visible behind it. No menu, no loading card, no popup.
2. First action in 5 s or less: a one-line prompt "Steal a Pumpkin!" (top-centre, 28-36 px on a 1080p screen, white text with 2 px black stroke, no panel) plus a 3D arrow or beam on the nearest nest.
3. Exactly 3 prompts in the first 60 s, one at a time, each replaced the instant its step is done: "Steal a Pumpkin!", then "Carry it to your patch!", then "Hatch it!". Zero blocking text over 12 words, zero modals.
4. First reward within 30 s of spawn: first pumpkin carried home and hatch started by 0:20; the first hatch resolves and reveals within 3 s of the tap.
5. Reveal card shows name, rarity word in rarity colour and income in green ("$2/s") at 60+ px height, with a hand cursor pointing at the placement spot; hold 1.5 s, then dismiss itself.
6. First candy/money tick within 5 s of placing the pet (counter animates, green +N pops); the counter ticks at least every 1 s from then on.
7. First free claim by 0:45 (Index or daily gift): one glowing "CLAIM" button giving at least 5x what has been earned so far; the jump shows in the HUD within 2 s.
8. HUD capped at 8 visible elements in the first 3 min: Shop, Index, Carry bar, currency, one timer (Nests refill) and two round buttons; every other button stays hidden until its system unlocks.
9. Zero ways to lose progress in the first 3 min: guards asleep or slow, no respawn penalty, safe zone covering spawn to first nest.
10. Zero purchase prompts before 5:00; first gate (new zone or upgrade) reached between 3:00 and 5:00 and affordable from play so far (about 2 min of earnings).
11. Next-goal prompt by 1:30 with a red "!" marker; exactly one active objective on screen at any time.

## Ours today (honest)
- r3-hud / r3-farm: spawn faces the Pumpkin King and a candy-stone path, but a quest list ("Smash 50", "Steal 1 pumpkin", "Own a Pumpkin") sits in a dark box and a long text hint sits under the title, so the 3-word prompt rule is broken.
- The first reward is slow: smashing 50 pumpkins comes before steal/hatch, no hatch reveal is in sight, and the first Index claim is an empty 0/15 grid with "25% Candy" tiers instead of a gift.
- The HUD carries about 10-12 items at spawn (Carry, 0% to Graveyard, King timer, Nests timer, side tabs, buttons) and two clocks at once; no arrow or beam points at the first target.

## Assets needed (Creator Store, free, no-script; do not insert yet)
| Need | Search terms |
|---|---|
| Tutorial pointer assets (3D bouncing arrow, beam, hand cursor image, ring marker) | "arrow pointer 3d", "tutorial arrow", "waypoint beam", "hand cursor icon" |
| Reveal / hatch UI kit (rarity cards, burst rays, confetti) | "hatch egg ui", "rarity card ui", "sunburst rays ui", "confetti particle" |
| Reward SFX pack (coin tick, level-up chime, reveal sting, claim button) | "coin collect sound", "level up chime", "ui click pop", "reward jingle" |
| HUD kit (currency pill, small icon buttons, progress bar) | "game ui pack cartoon", "currency counter ui", "button icons set" |
| First-target dressing (starter pumpkin nests, sleeping guard, hay) | "pumpkin patch low poly", "sleeping skeleton", "scarecrow", "hay bale" |
| Prompt and billboard text styling (outlined bold text frames) | "bold outline text ui", "speech bubble ui", "billboard label frame" |
