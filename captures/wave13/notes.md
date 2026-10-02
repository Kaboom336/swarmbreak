# Swarm Break wave 13 playtest vs the reference games (2026-10-02)

Source: Zion's recording `C:\Users\zerha\Videos\Recording 2026-10-02 122549.mp4` (3 min 16 s, Studio Play solo, build 2d401a3). I looked at a frame every 4 s (49 frames; sheets in `C:\dev\swarmbreak-refs\w13\`). The HUD crash fixed in 0e19333 was still present in this build, so every HUD item below was missing for that reason. Re-check them after the fix.

Zion's own notes: enemies are far too small; shooting should auto-aim like Final Swarm; no upgrade appeared; no weapon model or animation; no good animations; models need work; overall still terrible.

## What the recording shows
- **Start:** you spawn straight into the arena with no lobby, no goal line, no countdown and no guide. Zion opened the Roblox settings menu twice in the first 40 s. There was nothing on screen telling him what to do.
- **HUD:** only Roblox's default health bar (top right). No wave number, timer, objective, XP bar, coins, ability keys, upgrade cards or run summary (the UiKit crash).
- **Arena:** a near-white floor, blue-grey blocks scattered at random angles, cyan neon trim on the walls, a bright daytime sky with ocean. It reads as a blockout. The floor is overexposed, and the blocks clutter the camera view and block shots. Nothing says "hive" or "sci-fi base".
- **Player:** a default Roblox avatar with empty hands. No gun, no aim or fire pose, no recoil. The camera is far behind and high, so the player covers the action.
- **Enemies:** tiny dark bugs, about knee height, hard to see on the floor at that distance. Tiny red health bars. The bee/hornet model looks decent up close (orange and black stripes), and the boss (a big orange striped sphere) is the most readable thing on screen. Few enemies at once, nothing like a swarm.
- **Combat feedback:** small yellow and cyan particles. No damage numbers, no hit flash, no knockback, no death burst, no coins or XP dropping. The red damage vignette works. Death ends in a ragdoll with no summary screen.
- **Pacing:** about 3 minutes with no level-up, no reward and no change in goal. Nothing to look forward to.

## Gap list vs the references (ranked by impact)
| # | Gap | Best reference | What "good" looks like there |
|---|---|---|---|
| 1 | No first 10 s goal or onboarding | Final Swarm, Hunty Zombie | A guide NPC line ("Survive to wave 6 and kill the Queen"), a 3-2-1 countdown, the objective at top right |
| 2 | HUD missing (fixed in 0e19333, verify) | Hunty Zombie, Final Swarm | Wave + timer at top center, boss bar, a left icon column, XP bar, coins, weapon mastery card, 3 ability keys |
| 3 | No level-up loop | Final Swarm, Vampire Survivors | 3-card pick every 15–30 s, rarity colors, a reveal animation |
| 4 | Enemies too small and too few | Hunty Zombie, DRG | Enemies at player height or larger, 20–60 on screen, bright readable silhouettes |
| 5 | Manual aim | Final Swarm, Vampire Survivors | Auto-target the nearest enemy, auto-fire; the player only moves and dashes |
| 6 | No weapon in hand, no animations | Rivals, DRG | A held gun, idle/aim/fire/reload animations, recoil, muzzle flash light; enemy walk/attack/hit/death |
| 7 | Weak hit feedback | Hunty Zombie, Strongest Battlegrounds, Blox Fruits | Damage numbers, hit flash, knockback, goo splat decals, death burst, coins flying to the player, small camera shake |
| 8 | Arena has no identity and the blocks clutter it | DRG, Pressure | A themed hive or base, dark purple and teal with glowing crystals and colored lights, cover only at the edges, a clear open fight space |
| 9 | Camera too far and high | Hunty Zombie, Final Swarm | A closer over-the-shoulder or top-down 3/4 view, with the player off-center so enemies stay visible |
| 10 | No end-of-run payoff | Final Swarm, Pet Sim 99 | A run summary, then a portal or chest room with a rarity reveal |
| 11 | No lobby and no reason to come back | Hunty Zombie, Rivals, Anime Vanguards | A lobby with a Start Here pad, a select panel, daily quests, a shop and pass buttons (prices stay 0), status cosmetics |
| 12 | No audio identity (one sound fails to load) | DRG, Rivals | Distinct fire, hit and kill sounds, a wave-start horn, music |

## Suggested order for the next build
1. Verify the HUD fix, then a goal line and countdown in the first 10 s.
2. Auto-aim and auto-fire, a held weapon with fire animation, and bigger enemies (2–3x) in bigger crowds.
3. Level-up cards every 15–30 s, hit feedback (numbers, flash, death burst, coin drops).
4. Re-theme the arena (DRG palette, glowing props), clear the clutter, move the camera closer.
5. Run summary and chest payoff; then the lobby.

## Studio Output from this session (log 0.741.19.7411056_20261002T162131Z_Studio_15B54_last.log)
- `UiKit is not a valid member of PlayerScripts "Players.Kabbom336.PlayerScripts"` (Hud.client; fixed in 0e19333)
- `Failed to load sound rbxasset://sounds/swoosh.wav: Asset is not approved for the requester` (x5; Sounds.Swing/Dash)
- `Wrap-deformer fetching meshes resulted in error. Skipping follow-on stages.` (once)
- No funnel lines (run_start, first_hit, first_kill, first_levelup, first_damage_taken, death) appeared in Output.

Files: f001-f098.jpg = a frame every 2 s; fight.mp4 = 20 s from 2:45 (the boss and the crowd).
