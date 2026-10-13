# Handoff: Steal a Treasure (2026-10-12 ~23:45 UTC) - ACTIVE

## Decisions today (all in Keystone)
- Evergreen game + holiday events; renamed **Steal a Treasure** (no Roblox clash). Title tag per event: "[🎃] Steal a Treasure".
- Standout: shared guardian islands (4-8 players): hills, simple jumps, 3 routes, hide spots, guardian throws with red telegraphs, PvP loot handoffs, 12 shuffled chunks (slice-v2/ISLAND-V2.md).
- Each island guards its own container that opens into pets: Meadow golden acorn, Crystal Cave geode, Frost Peak ice crystal, Volcano magma orb, Ocean pearl clam; events: pumpkin, present.
- TikTok-first design (clip moments, centre-third action, sound stingers).
- Models approved: Pup A (assetId 98518831184004), Blender Crow (models/crow/blender), pumpkins (now Halloween event loot), pet effects v2 (no disc; Rare+ outline/glow/sparkles; name tags).
- Usage cap: Codex builds, Claude judges; max 2 rounds per model; one review page per batch. Claude weekly ~86% (reset 10/14 21:00Z); money lanes first.

## Running / next (updated 2026-10-13 ~00:30 UTC)
- Plan page for Zion (waiting on 'go'): https://claude.ai/artifact/RjiitVJmQswzyYZt4gxTpF (source scratchpad conceptpage/mk6.py + template6.html; content pumpkin/production/treasure/GDD.md, BUILD-PLAN.md, images).
- Greybox island v2 (prototype/guardian-greybox.rbxl): GreyboxPvpTest PASS in Studio. GreyboxLoopTest passes steal, jump set, carrying hill climb, then FAILS 'no normal throw/telegraph >8s': guardian follows carrier up the west hill and stays there (~44 studs away). Codex round 5 running (task C:\dev\codex-lab\t1f-fix-task.md, output t1f.last.txt): guardian leash + ranged throw + state logs. Then reopen in Studio, run both tests (attributes GreyboxLoopTest / GreyboxPvpTest on ServerScriptService during Play), commit, tell Zion.
- Fix rounds so far: 5 (over the 2-round cap; Codex only). If round 5 fails, stop and ask Zion.
- Tomorrow after Zion's go: follow treasure/BUILD-PLAN.md batches, each with a passing Studio test before Zion sees it.

## Code
- Branch pumpkin/patch-panic; commit with -c user.name/email from last commit; only git add pumpkin/giant pumpkin/production pumpkin/tools.
- Rojo: C:/Users/zerha/.rokit/tool-storage/rojo-rbx/rojo/7.4.4/rojo.exe (shim fails in Codex shell). Blender: C:\dev\codex-lab\tools\blender.

