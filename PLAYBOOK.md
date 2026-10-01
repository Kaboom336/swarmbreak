# Roblox game playbook (Iris Works)

How we make a Roblox game that can reach the front page, starting from an idea in Notion. Written from Swarm Break
(2026-09-30). Every later game starts here; every lesson from a gauntlet round gets folded in.

## 0. The rules that never change
- Zion does: the Roblox account, Studio install, first Publish, game passes / products, any Robux spend, DevEx.
- Claude in the cloud does: design, code, models (Blender), tests, docs, research. It never runs Studio from the cloud.
- Names are plain words a 12-year-old knows. No niche lore words on buttons. (Zion, 2026-09-30.)
- No blood. Enemies burst into light and sparks in their own color.
- Never invent numbers. Player counts and revenue are sourced or marked estimate / UNKNOWN.
- Placeholder prices until launch; finalize from data.

## 1. Research first (half a day)
1. Name the niche and the 3-5 games that own it. Read their store pages and fan wikis with WebFetch (YouTube is blocked in the cloud).
2. Write RESEARCH.md: a chart of the top games overall, a table of the niche leaders (loop, currencies, servers, monetization, look), and 5 design takeaways.
3. Keep COMPARISON.md running for the whole project: what they do better, what we copied, what we beat.

## 2. Design in files, small and testable
- GAME-PLAN.md (one-line idea, core loop, first playable, how it earns, sequence). LORE.md in plain words.
- Pure logic lives in ReplicatedStorage/Shared modules with Lune tests (waves, weapons, economy, evolutions, profile).
- Checks that run in the cloud: `stylua --check src tests && selene src && lune run tests/run.luau` (selene offline std in roblox_min.yml).
- Persistent data: one Profile schema (sanitize on load, autosave, save on leave), run state on top.
- Lobby first (30 players) with themed zones, then small arenas (8) via TeleportService. Friends-first is what the top games share.

## 3. Art pipeline (Blender by script, in the cloud)
- `pip install bpy` gives Blender 5 as a Python module; Cycles CPU renders work. Libraries: game/tools/blender/sb.py (primitives,
  export, manifest) and sb2.py (the v2 technique). RECIPE.md in that folder is the artist's checklist; read it before any model.
- FIRST get a reference bar: clone open-licence packs (git clone of public GitHub repos works in the cloud; Kenney starter kits,
  KayKit CC0 kits, Khronos and three.js sample models) and render them with OUR lighting into assets/renders/refs/ with a licence
  README. Measure them (refs.json): 100-1500 tris, one palette, big flat colour areas, exaggerated proportions. Every judge and
  artist compares against that sheet, not against memory.
- The v2 recipe that finally read as a game asset: faceted low-poly (voxel remesh + decimate to a budget + flat shading), pieces
  fused into one shell, armour cut from the body surface so it hugs the curve, limbs from tapered segments with joint balls,
  eyes/horns/jaws placed ON the head with on_ellipsoid, heads 30-40 percent of the body, one nameable glyph per enemy, dark body
  + one saturated accent covering real area + bone-white sharp bits + one glow, colours painted per face by rules into vertex
  colours with baked ambient occlusion multiplied in (Roblox imports vertex colours, so the shading survives), an attack pose for
  the render only, and a thumbnail-style render (dark gradient world, warm key, cool rims, glossy floor, bloom, AgX).
- One file per model (enemy_<Name>.py, weapon_<Name>.py) so several artist agents can work at once without clobbering each other;
  shared helpers only in the libraries; manifest writes under a file lock.
- Parts are named for the Motor6D rig so the animation code keeps working; `_Glow` parts become Neon in Studio.
- Render every model, LOOK at it, and publish a 3D gallery (GLB + three.js) so Zion can look.
- Laptop step: File > Import 3D (FBX, Scale Unit = Studs), Neon on `_Glow`, fill mesh ids in Shared/Meshes.luau.

## 4. Gauntlet loops (the quality process)
For each piece (a model group, a system, a screen):
1. Build it.
2. Render it or test it.
3. Two or three judge agents with different lenses score it 1-10 against named top games and list concrete gaps
   (a fix must say which helper / file, where, what size and color).
4. One fixer agent applies the gaps, rebuilds, re-renders, and LOOKS at the result before reporting.
5. Repeat until a round has no major gaps (max 3 rounds), then move on. Log the lessons here.

## 5. Ship and learn
- PUBLISH-GUIDE.md lists Zion's clicks. MONETIZATION-SETUP.md lists passes and products with placeholder prices.
- After launch: check retention (D1, D7) and session length in Creator Hub before spending on ads. Weekly content drop.

## Lessons log
- 2026-09-30: part-built (blocks) models are not enough; Zion called them terrible. Real meshes, even simple ones, read far better.
- 2026-09-30: the first Blender pass looked like balloon animals: smooth blobs, floating plates. Fixes that worked: joint bulges on limbs, plates placed ON the shell with on_ellipsoid, segmented bodies, spikes and claws for edges, darker bodies with brighter accents, render from the front.
- 2026-09-30: names like Verdant / Circuit / Void / Aster-9 / Breakers read as niche; Nature / Tech / Lightning / Dark / Outpost 9 / Survivors do not.
- 2026-09-30 (later): the second Blender pass was still "terrible" to Zion, and he was right: smooth blobs + hose limbs + boxes on spheres + pastel colours + a bright grey studio render read as balloon animals whatever the judges tweaked. What fixed it was a technique change, not more rounds: reference renders as the bar (measured, in the same lighting), faceted low-poly with fused shells, armour cut from the body, big glowing eyes and an open jaw placed on the head surface, per-face rule painting with baked AO, and a dark thumbnail render with bloom. Lesson: when two fix rounds do not move the score, change the method and the reference, not the parameters.
- 2026-09-30: judges without pictures judge from memory. Give them a reference sheet rendered in the same setup.
- 2026-09-30: real stylized game assets use 100-1500 triangles; our 3-6k-tri models looked worse because detail was noise, not shape. Fewer, bigger facets read better.
- 2026-10-01: discovery now reads retention over 28 days (Day 1, Days 2-7, Days 8-28) plus first-play bounce and intentional co-play; spike-and-fade is penalised, so plan for return visits, not launch CCU. https://create.roblox.com/docs/discovery
- 2026-10-01: update spikes decay fast (Final Swarm 20,107 peak to ~2,400 in a week; 100 Waves Later 98.3% rating, 184 live). Only a steady update cadence holds players; a good rating does not. https://www.rolimons.com/game/99521272836282
- 2026-10-01: codes are marketing: give them a job (bring a friend, unlock after a milestone) and post a hype code the day before each update. https://www.pockettactics.com/build-and-kill-zombies-codes
- 2026-10-01: AI agents write server logic well and fail at space, UI layout and difficulty; keep layout as numeric data with tests, and leave tuning to a human playtest. https://medium.com/@andy.a.g/i-built-a-roblox-game-using-only-ai-agents-heres-what-happened-ed57b553facc
- 2026-10-01: bounded tasks (one target, one failing check, allowed files) beat open requests by a wide margin; even top models pass about half of open Studio tasks first try. https://github.com/Roblox/open-game-eval/blob/main/LLM_LEADERBOARD.md
- 2026-10-01: keep a numbered pitfalls file per domain and load it into every agent task; it was the biggest quality lever in a Codex vs Claude build test. https://note.com/hottarita/n/nb972e1eb21db?hl=en
- 2026-10-01: ship 3-5 thumbnails from day one; Roblox bandit-tests them by play-through rate (avg +8.5%). https://gamesbeat.com/roblox-will-let-game-devs-personalize-thumbnails-to-attract-more-players/
