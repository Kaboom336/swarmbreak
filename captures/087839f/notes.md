# Captures: integrate/wave13 @ 087839f

Source: Zion played one run in Studio on 2026-10-03, from about 03:46Z to 03:58Z. The screen was recorded with no audio. The run reached wave 11 and was quit mid-run while that wave was stuck.
The closeups (12, 13) and the music check came from a short follow-up playtest driven through the Studio MCP tools.

- `run-full-720p.mp4`: the first 6:40 of the run (waves 1 to 11, including the start of the stuck wave). The timestamps below refer to this file.
- Stills are 1920x1080 PNGs. The Studio game view was only 1450x838, so frames are scaled up and pillarboxed. They are not native 1080p renders.
- Clips are 1920x1080 MP4s with no audio.

## Shot list status

| Shot | File | Status |
|---|---|---|
| 01 lobby wide | 01-lobby-wide.png | ok (the default camera can't pull back far; the lobby is one small room) |
| 02 lobby pad + countdown | 02-lobby-pad.png | partial: there is **no visible countdown** on the pad, only the "Stand for 3 seconds" text |
| 03 arena start | 03-arena-start.png | ok: banner + "3" |
| 04 wave 1 pack | 04-wave1-pack.png | ok |
| 05 crowd (wave 3+, 20+) | 05-crowd.png | partial: wave 9, but nowhere near 20 enemies are on screen at once |
| 06 hit | 06-hit.png | ok: white flash + small "17" damage number |
| 07 kill burst | 07-kill-burst.png | weak: only small cyan sparks (right side), no goo burst, drops are hard to see |
| 08 cards | 08-cards.png | ok (ELEM / RNG / SPD) |
| 09 element | 09-element.png | ok: cyan Tech glow on the gun after the ELEM pick |
| 10 boss | 10-boss-intro.png, 10-boss-midfight.png | ok (Big Brute) |
| 11 death summary | none | **missing**: the run never ended because wave 11 got stuck, so Zion quit |
| 12 enemy closeups | 12-closeup-*.png (+ lineup) | ok: Walker, Runner, Spitter, Flyer, Tank, Brute |
| 13 player closeup | 13-closeup-player.png | partial: front view, but **no weapon held** (the character was respawned for the shot) |
| extra | 14-evolve-card.png, 15-stuck-wave11.png | evolution offer (Thunderburst); stuck wave 11 |
| c1 move + shoot | c1-move-shoot.mp4 | ok |
| c2 melee + dash | none | **missing**: no melee weapon in this run (Starter Pistol, then Burst SMG from the crate) |
| c3 enemy walk | c3-enemy-walk.mp4 | ok (wave 9) |
| c4 level-up | c4-levelup.mp4 | ok |
| c5 boss | c5-boss.mp4 | ok (intro into the fight) |

## Zion's verdict (verbatim summary of the 03:57Z message)

- The models are still bad and weak. The game has no style.
- The boss doesn't feel cinematic. The intro is decent, but the fight itself isn't good.
- The map is small and boring. It should be bigger, with unique, cool-looking parts and parkour spots to run and dash through.
- Balance and leveling speed need work. Gameplay feels aggressive.
- The UI looks old, outdated, wrongly sized and bad.
- There are barely any animations: combat, enemies, evolutions (none) and others.
- The gun recoil shake feels janky and lowers the quality.
- The enemy spawn gate floats.
- The round broke: the HUD said 2 enemies were left, but they couldn't be found.
- Color theory and world building are weak.
- Zion is open to deciding on creative direction questions.

## Bugs and issues seen in the footage and logs (beyond Zion's list)

Timestamps refer to run-full-720p.mp4.

1. **Stuck wave 11 (the "2 enemies left" bug).** Wave 11 starts at about 5:50. From about 5:10 the Roblox menu is open repeatedly while Zion looks for the enemies. The console has no WaveReached after wave 11 (game time 334s), and the next event is QuitMidRun at 705s. That is about 6 minutes stuck. See 15-stuck-wave11.png.
2. **Card auto-pick spam.** The console shows *Second Wind* picked 17 times in a row across waves 9 to 11. The picks are batched at identical timestamps (3 at 317s, 6 at 334s), which looks like queued offers being auto-picked at the end of intermission. Either the offer pool collapses to one card or autoPick drains the queue. (Console log, not visible on screen.)
3. **Wrong objective text.** The arena banner says "Survive 5 waves. Kill the Queen." (0:20), but the wave 5 boss is Big Brute (2:30).
4. **The lobby "START HERE / Stand for 3 seconds" billboard shows inside the arena.** It appears over the fight in 05, 07 and 10-boss-midfight, probably an AlwaysOnTop or long-MaxDistance billboard.
5. **Floating spawn gates.** The black and orange gate boxes hang in midair above the floor (04, 1:20, 2:35).
6. **No pad countdown** in the lobby (02, 0:15 to 0:20).
7. **Level-up cards open mid-combat over the center of the screen** while enemies keep attacking (0:30, 2:38 to 2:45 during the boss).
8. **Hit and kill feedback is tiny.** The damage numbers are small, and the kill burst is a few sparks (07). Drops and coins barely read.
9. **Enemy models (closeups):**
    - The Walker, Runner, Spitter and Brute are default white blocky R15 bodies under a low-poly mesh head, so body and head don't match.
    - The Spitter's face is hidden behind its sac.
    - The Brute (a boss) has a tiny white body under a huge black egg, and its red "boss dressing" bars float detached from the model.
    - The Flyer (bee) and the Tank are the most finished.
10. **The console shows "Rejected N fire requests from Kabbom336"** 5 times during normal play. The fire guard may be rejecting legitimate shots at high fire rate.
11. The crate at the end of wave 5 gave a **Common Burst** weapon. That's fine, but it's worth checking that the evolution offer at about 3:42 (Thunderburst) attached to the right weapon.

## Music check

- Lobby loop 101945305370690: plays, Looped = true, 224s long.
- On entering the arena the track swaps to 1837768013 (fight loop): plays, Looped = true, 130s long. This was verified through Luau in the follow-up playtest.
- There are no "not approved" or asset load errors in the Output, so the backups weren't needed.
- The recording has no audio, so I couldn't confirm by ear that each loop restarts cleanly.

## Output and FPS

- Errors and warnings: none from game scripts. The only notable lines are the "Rejected N fire requests" messages (item 10).
- FPS (Shift+F5): **UNKNOWN**. The overlay isn't readable in the footage.
