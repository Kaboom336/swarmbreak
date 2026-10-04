# b5257eb quick stills (03, 05)

Taken with Studio MCP screen_capture. The screen was locked, so there's no desktop recording. Frames are 1450x840 scaled to 1080p.

- **03-arena-start.png**: ok. Midday lighting, banner "Survive 5 waves. Beat the Big Brute.", countdown "2". The floor and walls are near-white, and the arena still reads flat and washed out.
- **05 (crowd)**: not achieved. In waves 1 to 3, every attempt landed on an open level-up card panel with the 3D view fully black. Live checks showed why:
  - **The camera is inside a Walker's head** (`GetPartBoundsInRadius` at the camera position returned `Workspace.Enemies.Walker.Head.Handle`). Enemies walk onto the player while the card panel is open, and the camera has no occlusion or pop-out against enemies. See 05-attempt and x-wave1.
  - Cards queue faster than they can be picked, so the panel is open most of the fight.

## Root cause found for "2 LEFT, can't find them" (stalled wave)

Live check at wave 2, with 2 enemies alive and the card panel open:
- One Walker was in **Freefall on top of `Workspace.Arena.BossGate.Body` at y≈21**, the floating gate. It is stuck up there, out of view and out of reach, so the wave can't end.
- The other was standing on the player, with the camera inside its head.

The wave resumed after cards were picked and the gate Walker eventually came down or died. Fix ideas:
- Make BossGate (and other floating gates) non-collidable for enemies, or put them in a collision group enemies can't stand on.
- Despawn or teleport enemies that stay airborne or off-navmesh for more than ~5 s.
