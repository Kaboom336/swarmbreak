# Lessons from Swarm Break (for every future Roblox game), 2026-10-05

Evidence:
- Zion's playtest at 1014e41 (research/r6: r6-zion-playtest-1014e41.md, with the zion-*.jpg frames).
- The r5 and r6 research files.

## What went wrong
1. **Code-built art reads as cheap.** Parts, streak "VFX" and procedural prop rows looked like placeholders. Kits helped, but only partly. Blue sticks, discs and cylinders were scattered over the lobby.
2. **Auto-aim plus auto-fire removed the game.** Enemies died at the gates, never on screen. The player stood still the whole run because nothing asked them to move.
3. **UI covered the action.** The 3-card level-up panel was on screen about 40% of the time.
4. **The map had no design.** Prop rows lined the walls around an empty asphalt cross. Nothing guided movement, cover or sightlines.
5. **Feedback systems were built but never seen.** Damage numbers, shake and hit-stop existed in code but didn't show for a normal player. Tests passed; the screen didn't change.
6. **We judged screenshots and teleport harnesses, not real play.** Capture lag even produced false pacing numbers.
7. **Scope was too big for a first game.** An action game with campaigns, cores, bases and kits is the hardest genre to make feel good.

## Rules for next time
- **Pick a small, proven genre first:** simulator, tycoon, collect/steal, idle. Copy what works from a top-chart game in that genre.
- **Reference first:** screenshot the target game's map, UI and effects before building. Match them, then improve.
- **Use real art:** kits, image-to-3D meshes and script-free VFX packs. Never ship part-built art.
- **Design the map by hand around play:** lanes, cover and landmarks, with props placed with intent.
- **The player must act:** no auto-win. Enemies come to the player, on screen, and must be dodged.
- **UI never covers play** for more than a moment. Level-ups are quick picks or happen between waves.
- **Every feature is verified on screen by a real-input playthrough** before it counts as done.
- **Only Zion's playtest (recorded video) decides quality.** Batch a lot of work between his playtests.
- **Research deeply before any build usage.**
