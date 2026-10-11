# Pillar: core-loop-feel (farm / hit / collect / carry-run juice)

## Chosen game
**Pet Simulator 99 (BIG Games), fresh-account run + the Halloween update (frames: "Roblox PET SIMULATOR 99 in 2026" XcVf9hsths8, uploaded 2026-10-02, 0:37-7:20; "24 HOURS in Pet Sim 99 Halloween Update" hKdUr4K5c5Q, 2026-10-06). ref-5 is the one steal-run frame, from Steal an Egg "Starting OVER Using NO ROBUX" (4JdUNbmTBtw, 2026-09-03) because PS99 has no carry-and-chase.**
Why: PS99 is still the best-feeling "hit a thing, get paid" loop on Roblox: every swing/chew is a burst plus a number plus coins that fly to you, a bonus word pops on lucky hits, and the field is so dense with loot that the screen is never empty. The Halloween update shows the same engine in our theme (purple map, orange pumpkins, crit/BONUS bursts). Steal an Egg is used only for the carry-run tension (RUN pill, red edge vignette, Drop, visible chaser) because it does that better than anything.

## Reference frames (1280 wide)
1. **ref-1** (PS99 0:37) First breakable popped on a coin field. A white dust/impact burst about 40% of screen width, a coin number ("648") and a gem number ("66") float off the hit, a gem and coins spin out. Notice: the burst is the biggest thing on screen for a few frames, the floater is small, and the field behind is wall-to-wall coins at sizes 80-200 px.
2. **ref-2** (PS99 0:42) Pink "BONUS!" word pops left of the player on a lucky pop, a yellow ground arrow points at the next purchase, loose coins arc up and sparkle. Notice: the bonus is a WORD in a different colour (pink) from the number, so a lucky hit reads without reading digits. Coin sprites are huge and chunky (each about 5-8% of screen width).
3. **ref-3** (PS99 7:20) Breaking a vending machine: a thin red HP bar with the hit number "1,441" above it, "1.51k" collect number on the player, a ring/shockwave under the player, three "New Item!" cards under the character. Notice: three feedback channels at once (HP bar drops, hit number, loot cards) and still nothing covers the player.
4. **ref-4** (PS99 Halloween 5:50, peak) Multi-pet mass hit on a stack of breakables: full-screen white-yellow flash, "BONUS!" at the top, a 4 x 3 grid of "New Item!" cards. Notice: this is the ceiling of juice, and it also shows the failure mode (cards cover the centre). We want the burst, not the card grid.
5. **ref-5** (Steal an Egg 17:44, secondary reference for steal-run) Carrying an egg: a dark-red "RUN!!" pill top-centre (about 21% of width), a red "Drop" button bottom-centre, a green T-rex guard chasing in a straight corridor, strong edge tint. Notice: tension is carried by three static UI pieces plus one big chaser silhouette; no extra text is needed.

## Ours must...
1. First reward within 10 s of spawn: one smash that bursts, pays a number and drops candy (stopwatch from spawn to first "+candy" under 10 s; ref PS99 first coin at 0:37 only because of a long intro).
2. Every hit has 4 channels at once: sound (pitch up 3-5% per consecutive hit, reset after 1.5 s idle), a particle burst, one floater number, and 40-80 ms hit-pause or a 3 px camera nudge. Test: mute it and turn off particles and it must feel clearly worse in both cases.
3. Burst size: 25-40% of screen width on a normal hit (at 1280x720 about 320-500 px), 60% on a crit, with 6-12 chips/shards in pumpkin orange, white and seed-yellow.
4. One floater per hit, white digits with 3 px dark stroke, height 3-4% of screen (about 28 px at 720p), rise 60 px and fade in 0.8-1.0 s. Floaters within 0.3 s merge into one that ticks up; max 4 live at once.
5. Lucky word: crit / golden hit shows a pink or gold word ("CRIT!", "GOLDEN!") at 6% of screen height for 0.6 s, never as plain digits only. Frequency: 1 in 8 to 1 in 12 hits.
6. Candy drops fly to the player in 0.4-0.6 s on an arc and auto-collect inside 18 studs (ref: PS99 coins vacuum to you). No walk-over pickup for the main currency. Candy sprites are chunky: each pile pieces at least 1.5 studs wide so it reads from 30 studs.
7. The bank/deliver moment is bigger than a hit: 0.5-1.5 s of burst, counter that rolls up over 1 s, and a "+N" in green above the candy counter (matches checklist F3).
8. Multi-hit: the scythe swing hits every pumpkin in its arc; 3+ hits in one swing shows one combined floater and a "x3" tag, not three stacked numbers. Combo meter is ONE counter at the screen edge that resets after 2 s.
9. Steal-run (carrying a pumpkin): red-brown edge vignette at 25-35% opacity, "RUN!!" pill top-centre (about 20% of screen width), red "Drop" button bottom-centre at least 140 x 50 px, a chaser silhouette visible within 40 studs, and a safe line that ends the chase on touch. Chase gives at least 12 s of tension before a safe line (our audit says it ends in about 6 s).
10. Screen centre stays clear: no card, banner or toast within the middle 30% of the screen during a hit chain.

## Ours today (honest)
- The shots (r3-hud, r3-farm) show a scythe bigger than the pumpkins and an empty field: 6-8 pumpkins in view, no candy on the ground, no hit number, no burst, "Carry 0/3, 0 candy, +0/s". Nothing on screen tells you a hit happened.
- AUDIT-GAMEPLAY / checklist: smash pays about 1% of income (L2 = 1/10), no hit-pause, thin crescent slash, combo numbers pile up (F2 = 2/10), delivery is plain (F3 = 3/10), scythe invisible at distance.
- The steal-run exists (guard chase, carry 0/3) but the chase ends in about 6 s and the carry UI is text only, so the tension peak of SaE is missing; no screenshot shows a vignette, RUN pill or Drop button.

## Assets needed (do not insert; free / no-script only)
- **Hit and break VFX kit (impact burst, dust ring, shards, crit flash)**: Creator Store "hit effect particle", "impact burst vfx", "crit hit spark".
- **Candy / coin drop models and collect sparkle**: "coin pile low poly", "candy corn model", "collect sparkle effect".
- **Floating-number and combo GUI art (stroked number font frames, BONUS/CRIT word banners)**: "damage number gui", "popup text gui halloween", "combo counter ui".
- **Chaser hero piece (big guard silhouette for the steal-run)**: "giant scarecrow model", "dinosaur chaser npc low poly", "pumpkin monster rig".
- **Hit and collect sound pack (smash thunk with pitch ramp, coin ding, crit sting, delivery jingle)**: "pumpkin smash sound", "coin collect sound", "level up sound effect".
- **Carry-run UI kit (RUN pill, Drop button, red vignette frame)**: "warning vignette gui", "red screen edge effect", "run alert ui".
