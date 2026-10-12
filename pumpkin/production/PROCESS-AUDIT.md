# Process audit: Steal a Pumpkin (2026-10-12)

Asked by Zion 16:46 UTC: review the process and suggest changes.

## Working
- Codex does research, drawing and first-pass judging; Claude reviews and integrates (Claude weekly ~84%).
- Real, recent references per screen plus blind judges gave honest numbers: look rose from 4.5-6.5 (v3, strict) to 6-7.5 (v5); buildability 7-9.
- Blueprint now exists: 8 gameplay diagrams, world/hub/Zone 1 plans with coordinate tables.

## Not working / wasting effort
1. 2D has hit diminishing returns: 5 rounds, look ceiling about 7. A concept image cannot prove the real Roblox look; Studio decides that.
2. Judges are Codex grading Codex-made art (same model family): possible shared blind spots. Scores are not calibrated against anything.
3. Plans went stale: slice spec and 6 build tasks were written before the art direction (v5) and the map changed.
4. Too many pages and links for Zion (board, concepts page, plan page).
5. Run time (65 s) is arithmetic, not measured.

## Changes (proposed)
1. Cap 2D: v6 is the last full art round. After that only fix screens Zion names.
2. Start Studio now, in parallel: greybox the hub + Zone 1 from the picked map, measure real run times with the scripted smoke test, then dress with real asset packs and judge real captures against the same refs.
3. Calibrated judge panel, same rubric: one Codex judge + one cheap Claude judge, with 3-4 real top-game frames mixed in blind as controls. If real hits score under 8, the judge is miscalibrated; this makes scores trustworthy, it does not make them easier.
4. One living page for Zion (the plan page), updated in place.
5. After the map pick, refresh SLICE-SPEC and the 6 build tasks to the final map and v6 art before any code.
