# Captures: integrate/wave13 @ f96b4f8

Source: one Studio session on 2026-10-03/04, recorded full screen with no audio and cropped to the game view. The run reached wave 16 and was quit mid-run.

- From the start to about 3:40 the inputs were Claude's scripted test (keyboard moves, AutoFire). A server hook healed the player back to full whenever HP fell below 50%. Then Zion took over at wave 7, and the hook was switched off at that point.
- `run-part1-720p.mp4` covers 0:00 to 7:30 and `run-part2-720p.mp4` covers 7:30 to 15:10. Timestamps below refer to the whole session.
- Stills are 1920x1080 PNGs scaled up from a 1450x838 game view and pillarboxed.
- Missing: death summary (the run was quit), melee clip (no melee weapon), and new enemy and player closeups (not taken this time).

## Zion's verdict (2026-10-04 02:58Z)

- The game looks bland, with no details.
- The glow is unbearable; Zion can't see.
- It isn't satisfying to play.
- Effects are shaky and not smooth.
- Enemy models look bad.
- The new map idea wasn't implemented.
- "We're still at the drawing board." Zion asks for research on how to model, add effects and design the game as a whole, in line with earlier direction.

## What the footage shows

1. **Bloom and exposure are blown out.**
    - The arena floor and walls read as flat peach-white (03, 05, 09).
    - Bright frames wash out the whole screen (c6-glare, around 2:56 to 3:04).
    - Enemies and the player render as near-black silhouettes against it (04, 06, 07). This matches "glow is unbearable" and "can't see".
2. **The camera goes inside enemies and the boss.** Whole frames turn black or green (17-camera-inside-boss; around 3:50 and 4:10). The camera has no collision or occlusion handling against enemy models.
3. **The map is the same arena.** It's the same flat square with orange stripes and teal discs, and none of the new map ideas are visible.
4. **Fixed since 087839f:**
    - The banner now names the right boss ("Survive 5 waves. Beat the Big Brute.", 03).
    - The lobby pad shows a LAUNCH countdown (02b).
    - Wave 11 did not get stuck this run: waves 1 to 16 all advanced.
5. **Balance:** the run cleared normal mode (wave 15) easily. Note that the heal hook was active through wave 7, during Claude's test inputs.
    - Card picks: Second Wind came 5 times between waves 13 and 16, and Thick Skin 3 times.
    - The Thunderburst evolution triggered at wave 4.
6. **Console:** "Rejected N fire requests from Kabbom336" appears 3 times (2, 2 and 1). Otherwise no script errors.
7. **Windows Start menu:** it opened twice mid-run (around 1:50 and around 7:30 to 8:00), probably a Windows-key press. It is not a game bug.
