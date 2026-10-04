# e38b458 captures (new rigs, new look, Outpost 9)

The laptop screen was locked, so everything comes from Studio MCP screen_capture (about 1450x840 scaled to 1080p). There is no video, so the c3 walk clip is not done.

## Rigs: all 5 load
- The server log has **no** "Nest rig ... unavailable" lines on this build.
- Live enemies are the new rigs (Body, Head, Leg_1..6, Eye_Glow with the generated MeshIds and TextureIDs). A Walker spawns as the Mite rig, for example.
- 07 closeups: each enemy type was built through EnemyBuilder.build in the running server (Walker=Mite, Runner, Spitter=Shooter, Tank, Flyer), on a plain floor next to the arena. All 5 show the new rigs. The Flyer is shown grounded in the closeup because I anchored it; the HoverHeight attribute isn't applied in that standalone build.
- Spawned sizes (fit to enemy defs): Mite 11.9x10.8x13.1, Runner 12.2x9.2x11.4, Shooter 8.3x9.9x14.1, Tank 14.4x13.7x12.4, Flyer 12.0x8.8x12.0. These are about 2x the agreed bands vs a 5-stud avatar, because Fit.sizeForRelativeHeight scales the rig to the old def sizes. It's very visible in x-camera-inside-mite-wave6.png, where a Mite covers half the screen.

## Shots
| Shot | Status |
|---|---|
| 04 wave 1 pack | 04-wave1-pack-arriving.png: the pack (teal eyes, legs) arriving at the gate |
| 05 crowd | not captured. The crowd moment kept landing on an empty frame or with the camera inside an enemy (each capture takes several seconds). |
| 06 hit | not captured (too brief for screen_capture) |
| 07 closeups | all 5 captured |
| c3 walk clip | not captured (needs an unlocked screen) |

## FPS
- About **60 fps**, with a worst frame of 27 ms over a 5 s sample. That was in wave 11 with 2 enemies alive, so it's light load. No MicroProfiler: it needs an interactive Studio session.

## Stall: wave 11 stuck about 8 minutes ("2 LEFT", then "1 LEFT")
- My stall watcher logged "wave 11 alive 2 unchanged 40s". In the console, WaveReached 11 is at 302 s and WaveReached 12 at 788 s.
- Cause: waves 11–15 spawn at the Hive Core gates (x 400–468), but the player is still in the Landing zone at about (0,4,0). Nothing moves players between zones.
- The chasers can't path all the way. A Tank walked from x 461 to about x 244 and stopped. The watchdog then **Respawns it back at a Hive gate** (x 461), and the loop repeats: 308 → 244 → 461 → 467 → 461.
- The Kill rule never fires, because x 461 is inside MaxRadius 560.
- Also, RefineryGateNorth (200,2,-68) and RefineryGateSouth (200,2,68) have **no floor under them** (a raycast down hits nothing), so wave 6–10 spawns there fall.
- Waves 6–10 still cleared, about 30 s each.
