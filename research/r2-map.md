## R2 Map and level design (researched 2026-10-01)

Scope: what makes a wave-survival arena good, audit of our "Outpost 9" arena, 10 concrete changes, two more map concepts. Builds on COMPARISON.md (one arena, "gap") and GAME-PLAN.md. Numbers about our arena come from our files; numbers about other games carry a URL. Anything marked ESTIMATE is my judgement, not sourced. Not reachable this run: devforum, youtube, reddit, so no GDC video text; the sources below are wikis, design blogs and Steam guides.

### 1. Evidence: what good arenas do

| Principle | Evidence | Source |
|---|---|---|
| Kiting needs open space plus a loop. Final Swarm guide: "Circle-kite during swarm spikes", wide circles or figure-eights that bunch enemies for AoE. | Players want a closed path around an obstacle, and open floor around it | [final-swarm.wiki](https://final-swarm.wiki/how-to-survive-waves/) |
| Corners are death traps: "Do not stand in map corners - spawns pin you against walls". So our spawns must not sit in the corners players flee to, and the corners must not be safe. | Final Swarm wiki | [final-swarm.wiki](https://final-swarm.wiki/how-to-survive-waves/) |
| Boss fights: keep medium-range orbit, "don't stand in boss center". Arena needs a ring path around the boss gate. | same | [final-swarm.wiki](https://final-swarm.wiki/how-to-survive-waves/) |
| Spawn on multiple sides so "there is no single direction to face"; spawning behind forces repositioning but must be telegraphed (audio, visual markers, wind-up) or it reads as cheating. "No position permanently safe". Fix safe pockets with multi-direction threats, mobile objectives, finite cover. | Wave-survival design article | [reigncreativellc.com](https://reigncreativellc.com/blog/wave-survival-game-design/) |
| Cover height about character height in angled-camera shooters so tall objects do not block the view; low cover only; strong light/dark contrast so geometry reads at a glance; fewer cover points makes players collide, more makes them hide. | Top-down shooter level design (My.Games) | [medium.com](https://medium.com/my-games-company/top-down-shooter-level-design-how-map-design-supports-game-mechanics-6ae39fdd095d) |
| Halo Firefight: enemies arrive from fixed, legible points ("drop the east and west sides... from the energy doors"), high ground to shoot down, corridors as chokepoints, predictable ordnance drops on the left/right, smaller maps are harder because escape routes shrink. | Firefight guide (Steam) | [steamcommunity.com](https://steamcommunity.com/sharedfiles/filedetails/?id=1928595692) |
| COD-Zombies-style: doors opened with kill points gate progression; balanced paths and loops for replay; second floor sectioned off. Map grows as the run grows. | Zombie map design post-mortem | [itch.io](https://itch.io/blog/659140/return-of-the-dead-design-process) |
| Risk of Rain: each stage is "find the teleporter, start a timed event 90 to 120 s with a boss", chests and shrines spent with run currency. A stage has a destination, not just a floor. | Wikipedia | [wikipedia](https://en.wikipedia.org/wiki/Risk_of_Rain) |
| Vampire Survivors: 5 normal stages unlocked by player level in the previous stage (Mad Forest default; Inlaid Library at level 20; Dairy Plant 40; Gallo Tower 60; Cappella Magna 80); each stage carries a rule modifier (+10 percent move speed; +40 percent speed and gold; "no item drops" on Bone Zone). Maps = unlock ladder + modifier, not only geometry. | Stage guide | [rogueranker.com](https://rogueranker.com/vampire-survivors-stages/) |
| Survive The Swarm advertises a "20-map Gauntlet" (campaign of many short maps). Wiki gives no per-map detail; do not copy specifics. | Wiki home | [survivetheswarm.wiki](https://survivetheswarm.wiki/) |
| Roblox sibling "Survive Zombie Arena" has a beginner and high-wave strategy corpus, i.e. players actively theory-craft positions. Not fetched in detail. | search result | [games.gg](https://games.gg/roblox/guides/survive-zombie-arena-beginners-guide/) |

Not found / unverified: Brotato arena size, Fortnite Save the World map rules, Hellreaver Arena and Zombie Uprising layouts, and any Roblox-specific GDC talk. Treat them as open.

### 2. Audit of our arena (Outpost 9)

Facts from files (game/src/Workspace/Arena/*.model.json, ArenaBuilder.server.luau, Config.luau, GAME-PLAN.md):
- Floor 160x160x2 (top at y=1). Walls 160x20x2 at +-80. Fence posts at the four corners, 18 tall.
- Player spawn: 8x8 at the exact centre (0,0). 8 players per arena planned, MaxAlive 30 enemies.
- 8 enemy portals: four corners (+-70,+-70) plus four mid-edges (0,-72), (72,0), (0,72), (-72,0). Boss gate at (0,-70), 12 wide, gate pillars 21 wide.
- Solid blocks: TowerA 14x16x14 at (45,-15) with a 6x8x14 step at (35,-15); TowerB 16x20x16 at (-40,35) with a step; Ledge 30x2x10 at y=12, (0,50); GapPillar 10x12x10 at (-45,-50).
- Props: 10 clusters (crate stacks 4 and 3 studs, barrels 2.4, pillars 5-9 tall) at fixed spots. Floor neon seams every 22 studs. Fog 90 to 420, ClockTime 18.6, dark ambient.
- tools/blender/arena2.py exists at game/tools/blender/arena2.py (the path in the brief was wrong). It is a kit of 12 pieces (floor modules 8x8, walls 8 wide and 10 tall, crates 4, pillars 4.4 and 12 tall, gate 12, boss gate 17.5) that keeps v1 footprints. So geometry changes below are safe for the mesh kit if they stay on the 4-stud grid.

Findings (reasoned from the evidence above):
1. Spawns at (+-70,+-70) are 10 studs from the walls and the corner portal sits inside the corner players flee to. Wiki says corners are the trap. Fix by moving the player-safe zone, not by removing corners.
2. Eight spawns at 70 to 72 studs from centre, all pointing in; players start at the exact centre so every wave starts a symmetric 70-stud ring converging. Symmetric = no landmark, no "good side", no figure-eight route. Good for fairness, bad for orientation and for build identity.
3. Solid monolith towers (14 to 16 wide) are loop-able but only one-sided and tall (16 and 20) against an angled camera: they hide enemies behind them. Sightline rule says cover about character height (about 5 studs for R15, ESTIMATE).
4. Tower tops: no cover, no pickups, no reason to go up other than height. Halo guide: high ground is the reward, so the top should be a risk-reward spot (weapon crate, heal) with a drop-off exit.
5. Ledge (0,12,50) and GapPillar (-45,-50) are 40 to 70 studs from the nearest tower; reachability depends on dash/double jump. Needs a playtest (OPEN).
6. Fog starts at 90 studs, so portals at 70 to 100 from the player are already hazing: telegraph weakens exactly where spawns happen.
7. 160 x 160 for 1 to 8 players: crossing takes roughly 10 s at the Roblox default walk speed of 16 studs/s (default speed from memory, not re-fetched). ESTIMATE: fine for 8, too big for solo (empty feel, enemies take 5 s to arrive).
8. Single map, no rule modifier, no interactive object. Competitors rotate (Vampire Survivors) or add an event (Risk of Rain).

### 3. Ten concrete changes (priority order)

| # | Change | Size (studs) | Why / evidence |
|---|---|---|---|
| 1 | Telegraph every spawn: 2 s portal charge (ring grows 4 to 9 diameter, red floor decal 14 diameter, rising tone) before enemies emerge; no spawn within 30 studs of any player (re-roll to next portal). | decal 14, exclusion 30 | Telegraph or it reads as cheating ([reign](https://reigncreativellc.com/blog/wave-survival-game-design/)). Fog already hides portals (#6). |
| 2 | Push fog out: FogStart 90 to 200, FogEnd 420 to 600; keep the dark mood via Ambient not fog. | fog 200/600 | Readability and spawn visibility; portals sit 70 to 100 studs away. |
| 3 | Kill the corner trap: replace the four corner portals with 4 diagonal "bunker" blocks 20x6x20 in the corners (low roof, walkable, neon edge) so corners are cover islands, not dead ends; move corner spawns inward to (+-58,+-58) facing the centre, keep the four edge spawns. | 20x6x20 at (+-66,+-66) | Final Swarm: spawns pin you against walls ([wiki](https://final-swarm.wiki/how-to-survive-waves/)). |
| 4 | Central kiting ring: a low ring wall (height 5, thickness 3, outer diameter 44, with 4 gaps 10 wide at the compass points) around the spawn point; ring floor lanes 14 wide each side. Replaces the empty centre. | 44 diam x 5 high, gaps 10 | Closed loop plus bunching for AoE; low height keeps sightlines ([My.Games](https://medium.com/my-games-company/top-down-shooter-level-design-how-map-design-supports-game-mechanics-6ae39fdd095d)). |
| 5 | Lower the tower covers to scale and add a top reward: Tower A/B keep height 16/20 but each gets a 8x8 pickup pad on top (heal pad or chest) and a ramp 8 wide on one side; drop-off on the opposite side is a free dash exit. Break the big 14 to 16 block into an L (two 14x16x7 slabs) so it can be circled with an inside pocket. | pad 8x8, ramp 8 wide | High ground should be earned and risky ([Firefight guide](https://steamcommunity.com/sharedfiles/filedetails/?id=1928595692)). |
| 6 | Cover density: raise props from 10 to 24 clusters, all <= 5 tall, minimum 18 studs apart, none within 25 of the centre ring; mix of 4x4 crates, 6x2 low walls. | 24 clusters, spacing 18 | Cover about character height; collision vs hide trade-off ([My.Games](https://medium.com/my-games-company/top-down-shooter-level-design-how-map-design-supports-game-mechanics-6ae39fdd095d)). ESTIMATE on counts. |
| 7 | Landmarks: four distinct coloured beacons at the four edge midpoints (tall 30 studs, colour per compass: cyan N, amber E, magenta S, green W) visible through fog; the boss gate stays red. | 30 tall, 3 wide | Orientation in a symmetric map; mirrors Halo's named, legible approach points ([guide](https://steamcommunity.com/sharedfiles/filedetails/?id=1928595692)). |
| 8 | Chokepoint pocket: one gated side door (12 wide) leading to a 40x40 annex with a weapon crate; door opens at wave 5 (kill-points or wave unlock) and closes at wave 10. Gives COD-style gating and a camp spot that is deliberately finite. | door 12, annex 40x40 | Doors gated by progress ([itch](https://itch.io/blog/659140/return-of-the-dead-design-process)); finite cover prevents safe pockets ([reign](https://reigncreativellc.com/blog/wave-survival-game-design/)). |
| 9 | Interactive objects: 2 turret pads (6x6, buy with coins for 60 s of an auto-turret) at (+-30, 0) and 1 explosive barrel row (8 barrels, 2.4 diameter) near each ring gap. Risk of Rain spends currency on drones/shrines. | pad 6x6 | [Wikipedia](https://en.wikipedia.org/wiki/Risk_of_Rain). Use existing coin economy. |
| 10 | Scale to players: server hides outer 40 studs behind a closing "security shutter" when fewer than 4 players (play area 120x120 solo, 160x160 at 4+). Shutters 8 wide, same 4-stud grid as arena2.py. | 120 vs 160 | Smaller maps are harder and denser ([guide](https://steamcommunity.com/sharedfiles/filedetails/?id=1928595692)); solo crossing is 10 s (estimate). |
| (bonus) | Boss ring: boss gate stays at (0,-70) but players get a 30-stud orbit lane in front (2 low pillars 3x3x6 as anchors). | lane 30 | "Don't stand in boss centre" ([wiki](https://final-swarm.wiki/how-to-survive-waves/)). |

Build note: all new pieces fit the existing arena2.py footprints (4-stud grid, 8x8 floor modules, 8-wide walls, 12 gate); items 3, 4, 8, 10 need new pieces (bunker, ring wall segment, door, shutter).

### 4. Map 2 and Map 3 concepts

Rule from Vampire Survivors: unlock by level in the previous map and give each map one rule modifier ([stages](https://rogueranker.com/vampire-survivors-stages/)). Proposal (names are placeholders, ESTIMATE on numbers):

**Map 2: "The Nest Floor" (unlock: reach wave 10 in Outpost 9)**
- Theme: organic purple cavern; the Nest light our Blender kit already uses. 140x200 oblong, so kiting is a long figure-eight instead of a ring.
- Layout: two chambers 60x60 joined by a 16-wide neck (the chokepoint) at the middle; spawns only in the two chamber ends, so the neck is where fights bunch; 3 egg-sac pillars (10 diameter) per chamber as loop anchors.
- Hazard: acid pools 12 diameter that move to a new spot every 20 s and are telegraphed 3 s; slows 40 percent (ESTIMATE).
- Modifier: enemies +20 percent speed, coins +25 percent.

**Map 3: "Orbit Dock" (unlock: win normal on Map 2, or wave 15)**
- Theme: open-sky platform, three concentric rings (radius 25, 50, 75) linked by 4 ramps at 90 degrees, outside edge is a drop (fall = lose 20 percent HP and respawn on the ring).
- Layout: high ground (the inner ring raised 6 studs) with Flyers a bigger threat; spawns at ramp bottoms only; the boss arrives in the centre by drop pod.
- Hazard: a rotating laser sweep every 45 s along one ring, 4 s warning.
- Modifier: no healing pickups but doubled dash charges.

### 5. Open / follow-up
- Playtest reachability of Ledge and GapPillar (finding 5).
- Check enemy pathfinding with the new ring wall (ground enemies use pathfinding; a closed ring with 10-wide gaps is fine, but verify no stuck cases).
- Check the camera: if it is more top-down than third-person, cover height 5 may be too high; tune on the laptop.
- Brotato, Fortnite STW, Hellreaver Arena, Zombie Uprising: no sourced layout data found this run.
