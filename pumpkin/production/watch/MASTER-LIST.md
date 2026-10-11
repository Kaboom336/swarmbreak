# Launch master list (one list; nothing Zion said gets dropped)
Tiers: A = launch blockers/bugs/saving/economy, B = feel (Zion named or auditors found), C = polish if time. Auditor-found fixes that clearly improve the game ship tomorrow too (Zion 02:12). LATER = only new systems that add complexity without clear gain (devil's advocate decides).
Sources: Z = Zion said, W = my watch notes, AUD-* = auditor files (merge when they land).

## A: blockers
- [ ] A1 Saving works in the live game (DataStore; needs publish + API access, Zion clicks) (Z)
- [ ] A2 Admin reset of own stats/currency/progress works (Z)
- [ ] A3 "Sell for 0" prompt on pen soil (bug) (W)
- [ ] A4 Farming pays too little: retune smash candy vs pen income and prices (Z)
- [ ] A5 First quest clarity: player didn't know to smash; quest showed 0/30 (W)
- [ ] A6 Text overlaps: "+4/s" over candy number; second banner text under objective pill (W)
- [ ] A8 JOIN RAID button flings player through world -> death/respawn 'Loading your farm' (AUD-SEG0 4:46)
- [ ] A9 Guardian never wakes/chases yet 'You got away!' shows (AUD-SEG0)
- [ ] A10 Price wall: gate/pen slot/Upgrade all 318k right after ~1k gate; quest reward 20 candy = 0.26 s income (AUD-SEG0)
- [ ] A11 One name per thing: glowing/orange/ghost/shadow/mystery pumpkin, King Night/raid, farm/pen/base (AUD-SEG0)
- [ ] A12 Economy retune per AUD-GAMEPLAY (sim passes): Zones candy {8,80,250,1200,6000,30000,150000}; gateCosts {2500,1e5,9e5,9e6,8e7,5.4e8}; arrivalMinutes {0,3,10,18,30,48,75}; King payout/pity; supersedes FARM-PLAN Zone1=1 conflict
- [ ] A13 Flat income stall min 8.5-16 (player idled twice): next-gate % bar on HUD; King crate one rarity above zone + KINGLET pity counter
- [ ] A14 First session = 5 systems (steal, place, smash, shop, gate); tutorial order steal->place->smash 50->buy Iron->gate; hide King until 10 min, zone quests until Zone 3, Fuse to Zone 3, Dash to scythe tier 3, Lucky Swing cut, Stack max 1, CarveNewSeconds 2
- [ ] A15 Loss rules punish exploring: ambient raids off; Purge once/hour never in first 30 min; no ghost losses before 30 min (ghosts drop candy)
- [ ] A16 One event chip replaces 3 timers (DayLength 255); Daily popup only in hub and not carrying; stale 'Lock your base' banner outside Purge
- [ ] A17 Offline income (none today) [devil's advocate: launch or later?]
- [ ] A18 No hatch in 5.5 min: pen full from second 0, stolen pumpkins only sellable; 'Swap weakest pet' gives a toast, no reveal -> full pen must offer swap WITH hatch reveal, or more starting slots (AUD-SEG1)
- [ ] A19 Objective stuck: 'Pens full!' banner while stealing; 'Smash 25' resets -> 110 s idle (AUD-SEG1)
- [ ] A21 Few-player servers: stealing needs targets; NPC/bot pens or wild nests always enough (PREMORTEM #6)
- [ ] A22 Badges absent (BadgeService); welcome + first hatch + first steal badges (PREMORTEM #10)
- [ ] A23 Overlapping pen prompts: label 'Swap weakest' (Q) but holding E SOLD rare pumpkins (4 rares lost) (AUD-SEG2)
- [ ] A24 'Guard stunned' tap still bonked 4 s later (AUD-SEG2)
- [ ] A25 Gate purchase: no confirm (took 92% candy), no celebration, no 'income +X' feedback (AUD-SEG2)
- [ ] A26 AFK is best play (59% idle, full income + idle shield) (AUD-SEG2)
- [ ] A27 Witch Scythe one-shots everything; 60k/400k scythes pointless (scythe ladder vs hp) (AUD-SEG2)
- [ ] A28 Rename 'The Purge' (film title) + it does nothing solo; 6 clock types (AUD-SEG2)
- [ ] A7 Performance: 12.4k parts, 3.6k welds, 651 billboards, 299 prompts (W). Biggest win: 18 nest Mystery Pumpkins = 3,042 parts + 3,042 welds -> use existing mesh + glowing '?' (AUD-MODELS-ANIM); hub walls 2.7k bricks (AUD-LOBBY-MAP)
- [ ] A20 Guard eyes never glow red on wake (all voxel parts named 'V'); Gold pets lose faces (AUD-MODELS-ANIM)

## B: feel Zion named
- [ ] B1 Farming per ../FARM-PLAN.md (3 swing variants, hit-stop, pitch ladder, crunch sounds, pooled FX, zone weights variety, crack tint+wobble, Z2-7 candy x3). CONFLICT: judge kept Zone 1 at 1 candy because econ-sim gate says Zone 2 must not open before 3.75 min; but Zion's complaint IS early farming. Resolve: raise Zone 1 smash pay (feel) and move the gate/price instead; Zion's feedback beats the sim gate.
- [ ] B2 Plot UI cleanup: 1 tag per pet (name in rarity colour + $/s), 1 prompt per viewer, cut Swap/Sell, Lock+Upgrade on sign board, padlock-only slots, hide YOUR BASE near pen (Z)
- [ ] B3 Index with pet pictures + discovery and milestone rewards (Z)
- [ ] B4 HUD/UI rework to match top games (Z, UI-SPEC-V2)
- [ ] B6 Hatch reveal: first hatch only a toast; reveal cards small and open over Shop (AUD-SEG0)
- [ ] B7 HUD clutter: 3 timers, 6 left buttons, settings gear overlaps a button (AUD-SEG0)
- [ ] B8 Steal cutscene with faceless guardian interrupts a steal: cut or shorten (AUD-SEG0)
- [ ] B9 Sounds: ~70 cues reuse 5 sounds; roar/siren/stomp = pitched Bonk, stacking copies -> 16-sound Halloween kit + SoundGroups (AUD-VFX-SFX)
- [ ] B10 Camera shake overwritten each frame (15 call sites dead) -> rotational shake after camera (AUD-VFX-SFX)
- [ ] B11 Colour grade: 4 stacked ColorCorrections = +0.59 saturation (garish lime); bloom threshold 1.6 (AUD-VFX-SFX)
- [ ] B12 Reward moments (steal grab, purchase, rarity tiers) lack effects (AUD-VFX-SFX)
- [ ] B13 Midnight has no night look (sky/lighting stay day, conflicting warnings, no ghosts seen) (AUD-SEG1)
- [ ] B14 Shop icons are coloured balls; HUD colours muddy; gear covers LOCK (AUD-SEG1)
- [ ] B15 Hatch payoff shrinks (15-40 stud pumpkin -> 4-7 stud pet): pets pop out bigger; pet hop/tilt idle, rarity auras; carry pose; scythe swing moves arm (AUD-MODELS-ANIM)
- [ ] B16 Programmer art: Zone 1 Scarecrow, Jack fallback, carry halo ball, all-Neon gold finish (AUD-MODELS-ANIM)
- [ ] B17 Carried pumpkins are glowing cubes hiding the avatar (AUD-SEG2)
- [ ] B5 Red full-screen tint while carrying, also in Safe Zone (W)

## C: polish if time
- [ ] C1 Lobby premium in our own Halloween style (Z, AUD-LOBBY-MAP, scored 3.5/10): one lighting preset (lilac ambient, peach haze, bloom so Neon glows) [cheap, do in B]; recolour ground/paths/soil/walls; Pumpkin King's Throne centrepiece at eye level; +120-150 kit props; wall-top lanterns + string lights; cut 2.7k wall bricks (perf)
- [ ] C2 Boss: swap mesh-head-on-cylinder King for the existing voxel PumpkinKing (233 parts), bigger + walking (Z, AUD-MODELS-ANIM) [cheap, move to B]
- [ ] C3 Garish lime ground and checker walls; King centrepiece reads unfinished (W)

## LATER

## Zion-only clicks (ask once, together, at launch)
- Game icon + 3 thumbnails + title/description (we draft them, Zion uploads) (PREMORTEM #1)
- Create GamePasses/Dev Products and give IDs (all are 0 now, Shop hidden) (PREMORTEM #8); create badges
- Ctrl+S to save the place; 2-Step Verification; File > Publish to Roblox (private first); Game Settings > Security > Enable Studio Access to API Services; Rojo Connect if needed; Game Pass / Dev Product IDs.
