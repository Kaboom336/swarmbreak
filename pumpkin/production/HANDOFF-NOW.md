# Handoff: Steal a Pumpkin (2026-10-11 ~19:00 UTC)

## Where we are (updated 2026-10-12)
- Zion asked (10/12 00:08Z) to improve concepts vs popular games + TikTok favourites. Done: refs2/ (45 current frames, side-by-sides), refs/TIKTOK-DELTA-2026-10-12.md, REDRAW-RULES.md, concepts/v3/ (15 in-game style screens, JUDGE.md + SCORES.md). Method = Roblox Builder skill step 10 + Keystone lesson.
- WAITING ON ZION: round 3 page https://claude.ai/artifact/ULmLC7G8SuQCfBXJjGDS9y (v2; ours vs ref). Old v1/v2 sheets stay in concepts/ for history.
- Slice prep done: slice/SLICE-SPEC.md, tasks T1-T6, ASSETS.md, QUEUE.md, giant/scene/SliceSmokeTest.luau (untested in Studio). Spec still references the old concept sheets: point builders at concepts/v3 + REDRAW-RULES (daytime, dark glossy UI, phone = joystick + one action + Jump).

## Next steps
1. Zion yes -> run T1..T6 via Codex (order and file ownership in SLICE-SPEC section 5), Claude reviews/merges each, Studio-tests.
2. Gates: SmokeTest full run, side-by-side shots vs concept sheets, blind critics >= 8/10 per pillar. Then Zion playtest.
3. Zion changes -> redraw named sheets (task template C:\dev\codex-lab\concepts-fix-task.md, clone concepts-run\repo), republish same page.

## Code / Studio notes (unchanged)
- Branch pumpkin/patch-panic. Commit with -c user.name/email from the last commit (no global git identity).
- Only git add pumpkin/giant pumpkin/production pumpkin/tools.
- Studio Rojo may be disconnected; push via http.server + ScriptEditorService (see roblox-builder skill).
- Claude weekly ~80%, resets 10/14 21:00 UTC. Codex builds and draws; pause Claude-heavy judging near 90%.

