# Handoff: Steal a Treasure (2026-10-12 ~23:45 UTC) - ACTIVE

## Decisions today (all in Keystone)
- Evergreen game + holiday events; renamed **Steal a Treasure** (no Roblox clash). Title tag per event: "[🎃] Steal a Treasure".
- Standout: shared guardian islands (4-8 players): hills, simple jumps, 3 routes, hide spots, guardian throws with red telegraphs, PvP loot handoffs, 12 shuffled chunks (slice-v2/ISLAND-V2.md).
- Each island guards its own container that opens into pets: Meadow golden acorn, Crystal Cave geode, Frost Peak ice crystal, Volcano magma orb, Ocean pearl clam; events: pumpkin, present.
- TikTok-first design (clip moments, centre-third action, sound stingers).
- Models approved: Pup A (assetId 98518831184004), Blender Crow (models/crow/blender), pumpkins (now Halloween event loot), pet effects v2 (no disc; Rare+ outline/glow/sparkles; name tags).
- Usage cap: Codex builds, Claude judges; max 2 rounds per model; one review page per batch. Claude weekly ~86% (reset 10/14 21:00Z); money lanes first.

## Running / next (updated 2026-10-13 ~02:05 UTC)
- Plan page: https://claude.ai/artifact/RjiitVJmQswzyYZt4gxTpF (GDD v1). References v2 + Meadow top-down map: treasure/v2/ (Zion likes the background floating islands; keep them).
- Greybox (prototype/): layout rebuilt to refs v1, harder guardian done (offline checks pass). RUNNING: Codex t1i aligns Meadow + home to treasure/v2/meadow-topdown.png (task C:\dev\codex-lab\t1i-topdown-task.md -> t1i.last.txt). RUNNING: Codex design arena on Zion's 10/13 ideas (no hide zones, 1-min portal escape timer, traps before stealing, themed island backdrops/weather, bigger free-placement plots, unique future islands) -> treasure/ARENA-1013.md + revised GDD.md (task arena-1013-task.md -> arena1013.last.txt).
- NEXT: show Zion the arena keep/change/cut list (max 1 question); build order core loop (guardian, timer, map) -> plots -> backdrops; traps/unique spawns later unless arena says core. Before Zion plays: open guardian-greybox.rbxl in Studio, run GreyboxLoopTest and GreyboxPvpTest (Play, set attributes on ServerScriptService; portal stays locked for players until both pass in that session), capture side-by-side shots with GreyboxCaptureCams vs treasure/v2 images.
- Claude ~88% weekly (reset 10/14 21:00Z): pause Claude judging at 90%, Codex keeps building; money-lane Codex jobs first. Max 2 Codex rounds per piece.

## Code
- Branch pumpkin/patch-panic; commit with -c user.name/email from last commit; only git add pumpkin/giant pumpkin/production pumpkin/tools.
- Rojo: C:/Users/zerha/.rokit/tool-storage/rojo-rbx/rojo/7.4.4/rojo.exe (shim fails in Codex shell). Blender: C:\dev\codex-lab\tools\blender.



## Overnight build rule (Zion 2026-10-13 02:15)
- Keep building batches on Codex: map+guardian -> timer/no-hide (t1j) -> plots (C:/dev/codex-lab/t2-plots-task.md) -> backdrops (t3-backdrops-task.md) -> traps. Each batch: both Studio tests pass. Stop only if Codex weekly used >= 85% (check: grep rate_limits in newest ~/.codex/sessions/*/*/*/*.jsonl; was 22% at 02:20Z) or Zion opinion needed. Claude: light checks only until 10/14 reset.
