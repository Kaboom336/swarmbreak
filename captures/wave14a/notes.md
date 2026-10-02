# Interim Play check, fd4509d (2026-10-02)
Source: Zion's recording `Videos\Captures\C__dev_swarmbreak_game_out.rbxl - Roblox Studio 2026-10-02 13-24-37.mp4` (2 min 48 s, Play solo, reached wave 4, 37 kills). Frames are 640 px, taken every 3 s; file names keep the frame number (f004 is about 12 s in).

## The four checks
1. **HUD and cards: PASS.** The goal line "Survive 5 waves", a WAVE counter at top center, a health bar, "STARTER PISTOL / AMMO UNLIMITED", and a level/XP bar at the bottom. Upgrade cards appear (3 cards, "Press 1/2/3"), "Wave clear +10/+20 Coins", "CHEST OPEN" with a reward line, and a RUN OVER summary (wave, kills, gems).
2. **Enemies 2x and animated: PARTIAL.** Flying bugs are still about head-size at gameplay distance (f019, f047), and the R15 walkers were not clearly seen. Animation can't be judged from stills; the boss/large spiky enemy is readable.
3. **Auto-fire: likely PASS.** Muzzle flashes and tracers while the player isn't aiming (f038, f051). No gun model in hand in this build (that comes in wave 14).
4. **[funnel] lines: none** in the Studio log for this build. They arrive with dc41f7f.

## Output (log 0.741.19.7411056_20261002T172246Z_Studio_DF26F, Play 17:24:40-17:28:26 UTC)
- No CreatorError lines, and **no "not approved" sounds**: the H8 IDs loaded.
- Warning x4: `Failed to apply StyleRule property 'CornerRadius' from '>> .RoundedCorner8 ::UICorner': Unable to cast string to UDim`
- Warning x1: `Wrap-deformer fetching meshes resulted in error. Skipping follow-on stages.`

## Other issues seen
- **The mouse stays locked** after the run ends; Zion couldn't click Play again (reported).
- **The timer at top right shows "0.00"** in every frame (f009, f025, f047): it looks stuck.
- **A big dark translucent panel at top center** covers the view for long stretches, with tiny unreadable text (f025: probably a shop or offer row with 8 slots). Too large and too low contrast.
- **The upgrade cards are plain dark boxes**, all "COMMON", with small text: no rarity color, no icon, no reveal (compare Final Swarm).
- **The arena** is still a near-white floor with scattered blocks; the camera is high and far.
