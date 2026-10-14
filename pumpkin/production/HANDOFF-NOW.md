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
- Codex binary now C:/Users/zerha/AppData/Local/OpenAI/Codex/bin/8aaf1547b825b104/codex.exe. Codex used ~3%.

## 2026-10-14 ~01:00 UTC
- Map v4 (+ tunnel through hill, underside, 57 clusters) MERGED into guardian-greybox.rbxl (backup guardian-greybox.pre-v4.rbxl); lighting presets (LightingPreset attribute, treasure/map-v4/LIGHTING.md) + rock variety (backup pre-look). Checklist: prototype/MERGE-V4-STUDIO-CHECKS.md.
- WATCH: treasure/map-v4/build-look.jpg (merged file render) looks SPARSER than the round-6 lush render: check in Studio that the 57 clusters survived the merge.
- Keeper: fan mocap retry failed the gate (kept hand-keyed). Lob/slam/chase from mocap rounds. Mocap pack: C:/dev/codex-lab/vendor/quaternius-ual (CC0).
- Core loop (acorn open -> pets -> coins -> DataStore save -> index) queued on Codex: chain-core.sh -> core.last.txt, prototype/CORE-LOOP.md.
- Hermes tasks queued: iris-coordination/dispatch/hermes-roblox-01-top-game-refs.md (REFS.md), -02-pets-lore.md (CONTENT.md).
- Full roadmap: treasure/ROADMAP-TO-LAUNCH.md. Zion: tunnel route approved (balanced, not hide spot); cutscenes + cinematic run later.
- Codex used ~18%.
