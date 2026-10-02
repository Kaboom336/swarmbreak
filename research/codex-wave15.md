# Codex wave 15: close the playtest gaps

Base: the integrate/wave13 head at dispatch (b604704 or later; dispatched on fb57e80). The reviewer resolves any conflicts with G3/G5/G6.

## Rules (every task)
- Failing spec first. Touch only the listed files plus one spec.
- No blood: goo is teal or green. Prices stay 0. Plain names. No new dependencies.
- Runtime-safe only (L1 lint). Sibling client modules always load with WaitForChild (L1b).
- List in RESULT (your final summary) every Instance path the code waits on.

testcmd: cd game && stylua --check src tests && selene src && lune run tests/run.luau && lune run ../tools/lint_runtime_apis.luau && rojo build default.project.json -o out.rbxl

Order: H4 and H1; then H2 and H5; then H3 and H6; H7 last. H4/H3 both touch WaveManager, and H3/H7 both touch Hud.client, so those pairs run one after the other. H0 and H8 are laptop jobs (not dispatched).

## H1 Arena: open fight space, hive-station identity
- ArenaBuilder + ArenaLayout/Maps: no cover blocks in the central 90x90 fight space. Cover goes only in the outer ring, as low ledges <= 3 studs and pillars.
- Floor (155,158,168) concrete, with a darker grid and hive goo patches (teal, decals or flat neon-edged parts).
- Station preset: ClockTime 17, a dusk sky (no ocean daytime), ExposureCompensation -0.3.
- Glowing crystal clusters (purple and teal neon with PointLights) at the 4 corners and beside the spawn portals.
- Spec tests/arenaopen.spec.luau: no layout piece's footprint inside the central square; floor color equals Theme.Floor = {155,158,168}; every corner has a crystal cluster.

## H2 Camera closer and lower, enemies visible
- CameraConfig: Distance 12 -> 9, HeightOffset 1.5 -> 2.2, RightOffset 2 -> 2.5. Starting pitch is 18° down, clamped 8-40°.
- While auto-firing, pull out gently to Distance 11 when 12 or more enemies are within 30 studs.
- Spec tests/cameraconfig.spec.luau: the values above; the distance function is monotonic and clamped.

## H3 First 10 seconds
WaveManager "starting" phase + Hud.client:
- A full-width objective banner, "Survive 5 waves. Kill the Queen.", for 3 s.
- A 3-2-1 countdown with a sound.
- Wave 1's first pack spawns in view in front of the player, 25-35 studs away.
- An arrow points toward the nearest enemy until the first kill.
Shared/Onboarding.luau (pure). Spec: the banner text, the 3 s countdown, the spawn distance window, and the arrow hides after the first kill.

## H4 Make it a swarm
- WaveManager reads WaveTable.Compositions (C3) and spawns in packs of 3-6 from 2 portals at once.
- Config.MaxAlive 30 -> 60.
- Wave 1 = 16 Walkers in 4 packs, with health scaled so starter time-to-kill stays <= 1 s (C2 BalanceMath).
- Target 20+ on screen by wave 3, and 40+ by wave 5.
- Spec tests/swarm.spec.luau: packs sum to the composition; at most 2 portals per pack burst; the wave-1 TTK spec still holds; MaxAlive is respected.

## H5 Hit feedback and drops (beat Hunty)
- Damage numbers: verify HitMarkers shows them on every hit, with crits bigger and yellow.
- Knockback on hit: 2 studs for small enemies, 0 for bosses.
- A hit flash (from G4) that fires on every hit.
- Small camera shake on kill: 0.15 magnitude, capped.
- XP gems (teal) and coins drop on death and fly to the player within 12 studs (magnet). The Magnet card raises the radius. The server credits XP on pickup, with a 6 s auto-collect fallback.
Shared/Drops.luau (pure). Spec: the magnet radius math; the fallback timer; gem value sums match the old xpForKill exactly.

## H6 An element moment in the first 3 minutes
- The level-2 card offer always includes one element card (Nature, Tech, Lightning or Dark) that recolors the weapon and adds that element's on-hit effect.
- The level-4 offer shows the first evolution preview.
LevelUp.luau. Spec: the level-2 offer contains exactly one element card; offers stay rarity-valid.

## H7 Lobby
- A separate small lobby area next to the arena in the same place.
- A "Start Here" pad starts a run after 3 s on it (party pads).
- A weapon and kit select board, a daily quests board, and a shop board (prices 0).
- A teleport ring into the arena.
Places.luau and Shared/Lobby.luau (pure), plus a LobbyBuilder server script. Spec: pad timing, party grouping, and every price is 0.
