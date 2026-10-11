# Pillar: combat-boss (boss fight, enemy attacks: telegraphs, phases, hit feedback, rewards)

## Chosen game
**Steal an Egg, "The Rift" boss battle: Abyss Overlord (update 2026-09-05; frames from "Everything NEW In The RIFT Boss Battle" FgqJESTt0dg and "HOW TO DO RIFT BOSS" o1LK80i_Vmo; 720p grabs, 1280 wide).**
Why: it is the same loop as ours (huge boss, whole server fights it, payout is an egg/pet) and the cleanest boss read on Roblox right now: ONE wide HP bar, ONE timer, every attack announced by a solid red shape on the floor, one glowing weak point, and a reward that is a pet roll. Blade Ball and 99 Nights bosses are scarier but not a shared-server "everyone swings" fight like ours.

## Reference frames
1. **ref-1** (3:54) Crystal weak point plus telegraph. A solid saturated red disc under the crystal (about 60% of screen width up close), the crystal has its own green "8 / 35 HP" tag, a banner "A Rift has spawned!" sits under the boss bar. Notice: the danger zone is the loudest colour on screen and nothing else is red.
2. **ref-2** (4:58) Claw slam. The giant fist is outlined in neon red and a flat white-lavender slab on the ground shows where it lands; the fist's own green "10350 / 27300" tag floats on it (the weak point you are told to hit). Notice: body outline plus floor marker, two cues for one attack.
3. **ref-3** (5:44) Arena hazard lines. Thin red neon lines (about 8 px) trace rings and sweeps across a dull purple floor; a small dark vortex pickup sits next to the player; the rainbow trail shows player speed. Notice: threat lines are thin but neon, the floor stays dull so they pop.
4. **ref-4** (6:40) Boss at low HP. A huge glowing magenta-violet figure against a starfield sky; bar shows 350/27300 with segment dividers still visible, timer 04:32 below. Notice: the boss reads from far away as a coloured light shape, and the HUD does not change size during the finish.
5. **ref-5** (reward, how-to video 8:24) "The Rift" egg panel. Reward is a ladder of odds (45 / 36 / 15 / 4 / 0.5 percent) with pet icons and $/s, a pity counter "4/50", and a big green "3 Pets Left" button. Notice: the rare is shown at 0.5% with a pity bar, not a surprise.

## Ours must...
1. One top-centre HP bar, 40-45% of screen width (ref: 545 px of 1280), boss name above in bold white with thick stroke, emblem left, 4-6 visible segment dividers, "Time Left mm:ss" under it. No second boss bar anywhere.
2. Every attack has a floor telegraph visible at least 1.2 s before damage (BOSS-PLAN slam 1.5 s is right), a single saturated red (about #FF1A1A, 70-90% alpha), and it is the ONLY red in the arena (no red props, no red sky during the fight).
3. Telegraph shape equals hit shape: ring radius = damage radius within 0.5 stud, lane width = hit width; a fill from centre outward over the full wind-up shows time left.
4. The attacking body part is outlined or glowing (neon red, fade in 0.3-0.5 s) during wind-up, plus an audio cue: rising whoosh 1 s before slam, deep thud on impact.
5. Weak point carries its own small green HP tag ("12 / 35") readable from 40+ studs and a banner when it opens ("Hit the glowing face! x2") for exactly 6 s.
6. Boss scale at least 6x avatar height (ref: the fist alone is about 2x avatar). A slam hit = knockback + 1 s stagger only, no death, no item loss (keeps BOSS-PLAN).
7. Every swing: floating damage number (white, orange for crit), 0.08 s white flash on the boss, 3-5 chips, camera shake 0.1 s on slam only. Effects never cover more than about 40% of the screen.
8. Phase changes at 66% and 33% each get a 1.5 s centred banner (same style as "A Rift has spawned!") and a sky/lighting tint shift, no new UI.
9. Fight averages 4 min (fail at 5:00), shown by the timer; the bar pulses once per second under 10% HP.
10. Reward screen within 2 s of the kill: odds ladder like ref-5 (icon grid, % per rarity, Mythic 2%, Kinglet pity counter x/10), one green "Claim" button at least 120 px wide and 50 px tall.

## Ours today (honest)
- BOSS-PLAN.md has the right skeleton (King Night clock, Slam ring 1.5 s, Volley lanes, shield phase, weak spot, crate roll), but none of the screenshots in production\shots show the King, a telegraph or an HP bar, so I could not judge it visually.
- Our look is bright green meadow with purple walls: red telegraphs on grass will read, but there is no dark arena, no starfield and no boss glow, so the "boss as a light shape" read (ref-4) is missing.
- Reward is described as "crate reveal (reuse pet reveal card)": no odds ladder or pity bar is drawn yet.

## Assets needed
- **Boss hero model (Pumpkin King, 6x avatar, separate arms/fists for attack tells)**: Creator Store "giant pumpkin king", "halloween boss rig", "jack o lantern monster model".
- **Telegraph and arena VFX kit (floor decals, neon rings, shockwave, impact dust)**: "red warning circle decal", "attack indicator", "shockwave ring effect".
- **Hit and damage feedback kit (damage numbers, hit flash, shake, boss bar)**: "damage indicator", "boss health bar gui", "camera shake module".
- **Combat sound pack (windup whoosh, slam thud, roar, phase stinger, victory)**: "boss roar sound", "heavy impact thud", "epic stinger".
- **Reward UI kit (odds ladder, pity bar, claim button)**: "gacha rarity gui", "loot reveal ui", "reward popup halloween".
