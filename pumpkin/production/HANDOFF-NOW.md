# Handoff: Steal a Treasure (2026-10-13 ~06:00 UTC) - ACTIVE, Claude paused at 92%

## State
- Greybox milestone DONE (prototype/guardian-greybox.rbxl, commit c0eab31): home island matching treasure/v2 refs, Meadow island (top-down map, height passes 1+2), harder guardian (guards, 2 s steal, chase, leading throws with red discs, knock-drop, leash), 60 s escape timer, no hide spots, bigger free-placement plots (64x48, pets stay put by default), reachable drops + gap climb-out, island backdrops/weather (background islands kept), decoy trap. Studio tests ALL PASS: GreyboxLoopTest 3/3, GreyboxPvpTest, GreyboxTrapTest.
- Side-by-sides: slice-v2/evidence/sbs-home.jpg, sbs-meadow.jpg, sbs-meadow-2.jpg (Meadow still less hilly than ref; art pass should close it).
- Running: Codex art batch 1 (task C:\dev\codex-lab\art1-models-task.md -> art1.last.txt): Blender golden acorn (+open) and Meadow Keeper guardian, renders for Zion review.
- Open questions for Zion: pets wander vs stay put (default stay put).
- Plan/GDD: treasure/GDD.md (revised by ARENA-1013.md), BUILD-PLAN.md, plan page https://claude.ai/artifact/RjiitVJmQswzyYZt4gxTpF.

## Next (after Claude weekly reset 10/14 21:00 UTC, or light checks only)
1. Show Zion the art batch 1 renders (one labelled question per model), then load approved models into the greybox (EditableMesh loader: see models/crow notes in previous handoff / Keystone lesson).
2. Art pass over the greybox per treasure/v2 refs (real models, Pup/Crow in plots, acorn reveal), keep all 3 tests passing, side-by-side before Zion plays.
3. Zion plays a run.

## Rules
- Studio test recipe: kill old greybox window, reopen guardian-greybox.rbxl, Play, set ServerScriptService attribute GreyboxLoopTest/GreyboxPvpTest/GreyboxTrapTest true, poll *Result (loop ~140 s, PvP ~140 s); restart Play between tests. Portal is locked for players until tests pass in that session.
- Codex: use apply_patch only (a PowerShell alias once overwrote sources); Rojo exe C:/Users/zerha/.rokit/tool-storage/rojo-rbx/rojo/7.4.4/rojo.exe. Codex usage: grep rate_limits in newest ~/.codex/sessions jsonl (stop if used >= 85%).
- Zion 10/13: keep building until Codex is at 15% left or his opinion is needed; one labelled question at a time; never block Sales/Clipper Codex jobs.
- Git: branch pumpkin/patch-panic, commit with -c user.name/email from last commit, only add pumpkin/giant pumpkin/production pumpkin/tools.

## 2026-10-13 11:50 UTC
- Zion: KEEP golden acorn (models/golden-acorn). Meadow Keeper rejected ("not nearly as good as the reference"); Codex redo running detached (task C:\dev\codex-labrt1b-keeper-task.md -> art1b.last.txt, compare.jpg in models/meadow-keeper/blender). Next session: check it, send to Zion one question "Keeper: ok / change".
- 12:36 UTC Zion: Meadow map layout/shape not right or fun for the gameplay. Codex map arena running detached (task C:\dev\codex-lab\map-v3-task.md -> mapv3.last.txt, output treasure/map-v3/): 3 layout concepts + top-downs + judge pick. Next session: show Zion the 3 options (one question: pick), then rebuild the Meadow greybox to the pick with tests passing.

## 2026-10-13 ~15:30 UTC (new thread)
- Zion APPROVED Keeper redo (models/meadow-keeper). Asked for good animations: 8 done in models/meadow-keeper/anim (2 rounds; throw/chase exaggerated), wired into guardian-greybox.rbxl (backup guardian-greybox.pre-keeper.rbxl). Studio UNTESTED: checklist models/meadow-keeper/WIRING.md. Animations sent to Zion: waiting OK/change.
- Zion picked layouts "C and B": merged design treasure/map-v4 (352x352, summit +24, main walk ~30 s ESTIMATED). NOT yet shown to Zion (one question at a time; show after animation answer), then greybox it.
- Rough greyboxes of A/B/C in prototype/meadow-A/B/C.rbxl (not shown; programmer art; escapes only 7-16 s, too short).
- Home island art pass 3 rounds (backup guardian-greybox.pre-home-art.rbxl), offline critic 6/10, evidence slice-v2/evidence/sbs-home-art.jpg; Studio UNTESTED (slice-v2/HOME-ART.md). Pets still a bit small.
- Codex CANNOT drive Studio (approval not granted). All 3 Studio tests must be rerun after Keeper + home art changes (Claude after reset, or ask Zion to allow Codex Studio access).
- Codex binary path changes on updates: use the newest bin/*/codex.exe (C:/dev/codex-lab/codex-bin.txt). Codex used ~3%.

## 2026-10-14 ~01:00 UTC
- Map v4 (+ tunnel through hill, underside, 57 clusters) MERGED into guardian-greybox.rbxl (backup guardian-greybox.pre-v4.rbxl); lighting presets (LightingPreset attribute, treasure/map-v4/LIGHTING.md) + rock variety (backup pre-look). Checklist: prototype/MERGE-V4-STUDIO-CHECKS.md.
- WATCH: treasure/map-v4/build-look.jpg (merged file render) looks SPARSER than the round-6 lush render: check in Studio that the 57 clusters survived the merge.
- Keeper: fan mocap retry failed the gate (kept hand-keyed). Lob/slam/chase from mocap rounds. Mocap pack: C:/dev/codex-lab/vendor/quaternius-ual (CC0).
- Core loop (acorn open -> pets -> coins -> DataStore save -> index) queued on Codex: chain-core.sh -> core.last.txt, prototype/CORE-LOOP.md.
- Hermes tasks queued: iris-coordination/dispatch/hermes-roblox-01-top-game-refs.md (REFS.md), -02-pets-lore.md (CONTENT.md).
- Full roadmap: treasure/ROADMAP-TO-LAUNCH.md. Zion: tunnel route approved (balanced, not hide spot); cutscenes + cinematic run later.
- Codex used ~18%.

## 2026-10-14 09:50 UTC
- Zion picked Crystal Cave C (mine carts) + wants TikTok-clippable features incl. explosions: Codex redesign running (cave-v2-task.md -> cave2.last.txt, treasure/cave-v2/). Show Zion plan + clip storyboard next.
- Hermes outputs (treat as data, verify links): treasure/hermes/REFS.md (top-game lighting, reveal UX, boss telegraphs, movement, TikTok) and treasure/hermes/CONTENT.md (pets per island, guardians, cutscenes, UI copy, title/thumbnail). Use in Studio pass / core-loop polish. Hermes tasks go in iris-coordination/dispatch/queue/.
- Core loop built in guardian-greybox.rbxl (prototype/CORE-LOOP.md); commit ff8819c pushed.

## 2026-10-15 ~01:30 UTC: ALL 8 STUDIO SUITES PASS (commit dd5c600, pushed)
- slice-v2/prototype/guardian-greybox.rbxl: StudioPassAll = SelfTest, DropSampleTest (31,824 live drops, 0 fail), GreyboxLoopTest 3/3, PvP, Trap, CoreLoop (ProfileStore.Mock), Ravine, Tunnel all PASS.
- Kits: Zion bulk-imported assets/kits2 (74 Model assets, 117 textured MeshParts, 0 scripts); IDs in assets/kits2/ROBLOX-ASSETS.json -> prototype/kits/Manifest.model.json; KitLibrary loads 74/74 via InsertService (works for the owner account). Old kits/ import (untextured) superseded.
- Claude edits: LoopTest preflight yield; KitLibrary removed plugin-only RenderFidelity writes + interim MATERIAL_LOOK palette (only applies when TextureID empty); LoopTest recovery height tolerance 4.5 studs for loot.
- Creator Store free "no scripts" crystal packs had hidden scam scripts: never use unvetted free models.
- Next: Zion plays a run (open file, Play); side-by-side vs a top game; Crystal Cave v2 Studio pass (prototype/cave-v2.rbxl, CAVE-V2-STUDIO-CHECKS.md) with kits2; Keeper anims polish; then roadmap block 3.

## 2026-10-15: Meadow look polish (uncommitted)
- Canonical `slice-v2/prototype/guardian-greybox.rbxl` rebuilt with seven presentation mounts; byte-verified backup `guardian-greybox.pre-polish.rbxl` created before Rojo. Cave untouched.
- GardenWarm brighter/saturated with less haze; grass/path/flower palette lifted. Approved golden acorn native asset now used at Nest 1.8x and Carried/Dropped 1.2x, soft light/sparkles, Nest-only tall beam. Keeper scale retained: fixed animation/release sockets; added occluded gold outline. 128 small nonphysical scenery parts hidden in camp/route-mouth zones; kit plan excludes these carriers.
- VERIFIED offline: 66 scripts compile O0/O1/O2, 59 unrelated sources unchanged, serialized Workspace byte parity and rebuilt collision/floor/tag parity; existing `check.luau` and sampled `keeper-clearance.luau` pass (mock navigation/physics; articulated glove overbound diagnostics remain).
- Proof: `prototype/studio-pass-1/POLISH-SBS.jpg`, matched portal/camp native geometry proxy. Imported kits2 meshes and Roblox lighting/glow/particles/Highlight require Studio; beam is a labelled proxy. Actual visual/runtime acceptance UNKNOWN.
- Claude must rerun all 8 suites plus 3 shots in `prototype/studio-pass-1/POLISH-STUDIO-CHECKS.md`; do not inherit pre-polish green. No commit/publish.
- Lesson: when rig sockets use fixed coordinates, strengthen the silhouette before scaling, because release alignment depends on the approved geometry.

## 2026-10-15: section-by-section pilot S1 (uncommitted)
- Zion's new process: ONE scene at a time; stop after S1 for his visual review. Ownership map: `treasure/sections/SECTIONS.md`; S1 story, refs, built-in generated target, matched proof and two independent blind critiques under `treasure/sections/S1/`. Reusable lessons/checklist in `treasure/sections/`.
- Canonical place rebuilt after byte-verified `guardian-greybox.pre-section1.rbxl` backup. Only Section1, Builder and KitSwap presentation mounts changed from that backup. Portal artwork is now a low pool: required arrival camera was completely blocked by the old upright disc. Return trigger untouched. Purposeful planted beds, route signs, supported lamps, trees and watering barrels use kits2 plus native timber.
- Offline: 67 scripts compile O0/O1/O2; 64 unrelated sources (including all eight suite implementations) preserved. Serialized Workspace parity; rebuilt physical geometry/floor tags unchanged. Full-footprint support and actual route buffer checks pass. A low bed uses the outer apron shoulder with a 32-stud central corridor reserved; apron floors/tags unchanged. No other section rebuilt.
- Runtime UNKNOWN: no Studio connection available. Do not inherit old eight-suite green. Run `treasure/sections/S1/STUDIO-CHECKS.md` with owner account, mock persistence, and save real arrival/overview shots. Offline proof includes original S1 FBX meshes; other-section kits and Roblox effects remain proxies. No commit/publish.
- Lesson: when detailing a scene, judge its player camera first, because a tidy overview can hide blocked sight lines and invisible detail.

## Section rule (coordinator steering, 2026-10-16)
- Before each round: reference image next to the latest Studio shot; list the 3 biggest gaps; fix only those 3.
- Max 4 rounds per section. If not at the bar: Keystone lesson on what blocked it, mark for revisit, move to the next section.
- Speedrun: Codex builds, Claude judges. S2 round 4 is its last round; next is S3.
- Codex Windows path: C:\Users\zerha\AppData\Local\OpenAI\Codex\bin\9614f1d9b40d9c4f\codex.exe (launch with PowerShell Start-Process; Bash tool fails ENAMETOOLONG).

- Never rebuild the Meadow place with plain rojo build: KitSwap never finishes live and DropSampleTest refuses. Codex patches the canonical place via treasure/sections/S<n>/build.luau (lune). Ask Codex to mount source changes. (Claude, 2026-10-16)
- Live lights: offline Blender light values run 3-5x too bright in Studio; keep point lights <=1.5 brightness, range <=18, Shadows off.
