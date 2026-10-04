# Art-final captures: integrate/wave13 @ 6277319 (2026-10-04)

Built from 6277319 (git archive + rojo 7.4.4) and opened in Studio. The pad terrain was pasted back from the LandingPad.rbxm TerrainRegion.
- The ArtLoader loads the Landing Pad in Play: 745 parts, 128 MeshParts, 0 empty meshes.
- Console: no errors, only the usual "Infinite yield possible on Enemies" warnings at startup.

## Shots
| # | Shot | Score vs Hunty | Bright, sharp anime action? |
|---|---|---|---|
| 01 | spawn-view (Play, HUD on) | **close** | Partly. Clean, readable, saturated kit colours (red/white/orange). The walls and floor are still dark grey-blue, and the environment has no outlines (only the character does). |
| 02 | midfight (Play, HUD on, enemies + kill burst + tracer) | **worse** | No. The kill burst is a flat white blob. Hunty's fight frames are filled with big saturated purple/orange VFX and motion streaks. Our fight frame is mostly scenery. |
| 03 | wide (Play, HUD hidden) | **close** | Yes, at this distance. A cohesive stylized sci-fi pad, warm sky, colour accents. Better than anything before. |
| 04 | side-by-side (fight + spawn) | **worse** overall | Environment close, combat VFX/feel worse. |

Extra frame: `x-wave3-start-no-enemies-in-frame.jpg`.

## Wave 3 problems
- **02 is wave 1, not wave 3.** I tried wave 3 in 3 runs and missed it every time:
  - It clears in about 2 seconds, faster than one MCP round trip.
  - In this build wave 3 is also the last wave: the run ends with "Victorious, Wave 3".
  - Balance finding: wave 3 dies faster than it can be seen.
- **Run 2 stalled.** With the reward-card panel hidden client-side, wave 2 stopped for over 3 minutes with 13 enemies alive, and the player went down. This looks like the old "cards open → auto-fire stops" bug. Runs where the cards were left alone played normally.

## FPS (client RenderStepped, Studio in the foreground, 1920x1080)
| Wave | Average | Worst frame |
|---|---|---|
| 1 | 60 | 24 ms |
| 2 | 60 | 25 ms |
| 3 | 53.3 | 68.5 ms |

With Studio in the background (first run), Studio throttles to about 15 fps; ignore that run.
