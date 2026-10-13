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
