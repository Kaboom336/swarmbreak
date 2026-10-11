# Handoff: Steal a Pumpkin (2026-10-11 ~17:40 UTC)

## Where we are
- Zion APPROVED the target board (17:37 UTC): https://claude.ai/artifact/NSmBa9iQM2xcixJAZnatnh (source: pumpkin/production/board/<pillar>/TARGET.md + ref-1..5.jpg; generator scripts in Claude scratchpad mkboard.py/mkhtml.py). Benchmarks: Steal an Egg (map, first 5 min, models, boss, progression), Pet Sim 99 (UI, loop feel).
- Pets: studded voxel style (Claude default; Zion did not choose; tell him he can switch to chibi).
- Zion wants to keep going until a game is ready to publish; computer stays on. References must be from the last 1-2 months.
- Production system (Roblox Builder skill + Keystone decisions): board -> 2D concepts (Codex built-in image_gen) -> Zion approves 2D -> vertical slice (hub + Zone 1 + full loop) built to match 2D -> gates (scene/SmokeTest.luau passes, side-by-side vs board/2D, blind critics >= 8/10 per pillar) -> Zion plays only gated builds. Launch moves until the slice passes.
- NOW RUNNING: Codex task concepts-run (task C:\dev\codex-lab\concepts-task.md, clone C:\dev\codex-lab\concepts-run\repo, output pumpkin/production/concepts/ + CONCEPTS.md + _sheet.jpg). When done: copy into pumpkin-loop, commit, publish a concept board artifact for Zion's phone approval.

## Code state (branch pumpkin/patch-panic, pushed; latest ~63ed51d + SmokeTest)
- All round-3 work merged: facing fix (FrontFixed), UI fixes, iconforge icons (pumpkin/tools/iconforge/ASSET-IDS.md uploaded ids), K1 combat (3-phase King, guard attacks), L1 (font, pumpkins, multi-hit swing, walk-over collect, labels), S4 scythe hold (blade in front), BX (nest steal range by pumpkin size, no LoS, swing-to-steal, gate closest-point distance, promptcheck debug).
- Scene scripts run in Studio Edit (not auto-saved; Zion must Ctrl+S): LaunchLook1-5, WorldPlan (v2). Hub floor recoloured to grass 8CC765/84BD5E.
- Studio: studio_id fab51806-824a-4d22-a2e7-efd1ee7d0ea0. Rojo NOT connected after Studio reopened: push scripts via python http.server in pumpkin/giant (port 34992) + ScriptEditorService:UpdateSourceAsync (see skill). Verify with a grep for a recent string.
- SmokeTest has not completed a full run yet (Play stopped mid-run). Run it before any Zion playtest.
- Parallel Codex merges: git diff in clone -> git apply -3 in pumpkin-loop. Only `git add pumpkin/giant pumpkin/production pumpkin/tools` (pumpkin/src etc. belong to another workstream).

## Usage
- Claude weekly 79% (resets 10/14 21:00 UTC). Keep Claude to judging/integrating; Codex builds and draws. Pause Claude-heavy judging near 90% and tell Zion.

## Next steps
1. Concepts done -> commit -> concept board artifact -> Zion approves 2D.
2. Vertical slice spec from approved 2D + TARGET.md (hub + Zone 1 + full loop), split into Codex tasks per pillar; use real assets (TOOLING-ROBLOX.md top 10; Creator Store packs without scripts).
3. Gates, then Zion playtest (record with 60 s fragmented segments).
