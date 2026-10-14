# Meadow v4 — Round 4

**Built and rendered; static audits PASS. Final blind visual review:4/5 criteria pass.** Two review rounds completed. The remaining rock-wall finding concerns the retained ravine; it stays unchanged as requested. No full visual PASS claimed. Studio runtime UNKNOWN.

Open [meadow-v4.rbxl](../../prototype/meadow-v4.rbxl), [concept comparison](build-sbs.jpg), [top route plan](build-top.jpg), [jump detail](build-rrr4b-ridge-jumps.png), [side view](build-rrr4b-side.png), [blind reviews](ROUND4-CRITIC.md), [raw evidence](ROUND4-EVIDENCE.json).

Checked final scene/place/render hash bindings:29,409 anchored native parts;40 lights versus121 before;55,474 full-width samples with clearance0 and nominal surface differences0;deadends0 and unreachable0. All18 route dictionaries and2,986 selected original ravine parts remain unchanged. Six Luau containers compile;five non-generated scriptSources equal the prior place byte for byte. Fourteen isolated ravine-policy assertions passed. No Studio movement, jump feel, NPC, multiplayer or performance acceptance.

Changes:landmark lantern pairs;staggered grey-purple block faces/pale tops/planted ledges;tree/bush/boulder/flower clusters and small steps in empty fields;tapered underside and exposed hanging moss;contrasting east jump pads with visible gaps. Native project authoring/export/audit/render helpers were inspected and reused, with no new external asset/code dependency. Reference bar is supplied concept.png; local Roblox playbook read at C:/dev/codex-lab/pumpkin-loop/PLAYBOOK.md. Exact Keystone-titled note unavailable in exposed sources.

Protected files:23/24 baseline hashes match. Guardian-greybox.rbxl changed concurrently during this task;responsible author UNKNOWN. This task never wrote or restored it, guardian scripts or Keeper animation files. Keep that external change. Raw baseline/current hashes are retained in ROUND4-EVIDENCE.json;complete binary baseline equality is not claimed.

Remaining critic notes:retained ravine smooth faces;gold jump standards partly hide pads in close view;vegetation denser and rocks coarser than the concept. Preserve the approved ravine and stop at the two-round cap.

Rebuild from production:bundled Python `prototype/meadow-v4/round4.py`, then `round4-fix.py` once, then `audit.py` and `routes-check.py`. Direct Rojo7.4.4 binary under `.rokit/tool-storage/rojo-rbx/rojo/7.4.4/rojo.exe` builds `prototype/meadow-v4.project.json -o prototype/meadow-v4.rbxl`;direct Lune0.10.5 runs `verify.luau`, `round4-check.luau` and `ravine-test.luau`. Blender `render.py -- rr4b`, `compare.py -- rr4b`;Python `round4-evidence.py` and `round4-final-evidence.py`. The fix script adds geometry, so reset with round4.py before rerunning it.

Lessons:When judging cliff detail, inspect the largest faces separately because small accents can hide smooth sheets. When hanging moss is required, put it beyond the rock silhouette because embedded strips stay invisible. When preserving files, hash the binary directly because script equality cannot prove place equality.
