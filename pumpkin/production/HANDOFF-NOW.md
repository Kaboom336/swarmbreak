# Handoff: Steal a Treasure (2026-10-12 ~23:45 UTC) - ACTIVE

## Decisions today (all in Keystone)
- Evergreen game + holiday events; renamed **Steal a Treasure** (no Roblox clash). Title tag per event: "[🎃] Steal a Treasure".
- Standout: shared guardian islands (4-8 players): hills, simple jumps, 3 routes, hide spots, guardian throws with red telegraphs, PvP loot handoffs, 12 shuffled chunks (slice-v2/ISLAND-V2.md).
- Each island guards its own container that opens into pets: Meadow golden acorn, Crystal Cave geode, Frost Peak ice crystal, Volcano magma orb, Ocean pearl clam; events: pumpkin, present.
- TikTok-first design (clip moments, centre-third action, sound stingers).
- Models approved: Pup A (assetId 98518831184004), Blender Crow (models/crow/blender), pumpkins (now Halloween event loot), pet effects v2 (no disc; Rare+ outline/glow/sparkles; name tags).
- Usage cap: Codex builds, Claude judges; max 2 rounds per model; one review page per batch. Claude weekly ~86% (reset 10/14 21:00Z); money lanes first.

## Running / next
- Codex: greybox island v2 + GreyboxLoopTest + GreyboxPvpTest (task C:\dev\codex-lab\t1b-island-v2-task.md, output t1b.last.txt). Then queued: whole-game GDD + BUILD-PLAN + reference images in pumpkin/production/treasure/ (task gdd-v3-task.md, output gdd3.last.txt).
- Then: open prototype/guardian-greybox.rbxl in Studio, run both tests (set ServerScriptService GreyboxLoopTest / GreyboxPvpTest true during Play; wait for *Result attribute PASS), commit, publish one page (plan + images) for Zion's approval, then build tomorrow in batches per treasure/BUILD-PLAN.md.
- Rule: never hand Zion a build without a passing full-loop test. ProximityPrompts didn't show via MCP input; the loop test calls the same server functions and walks with Humanoid:MoveTo.
- Studio windows open: model-lab.rbxl (unsaved models; Zion Ctrl+S) and guardian-greybox.rbxl.

## Code
- Branch pumpkin/patch-panic; commit with -c user.name/email from last commit; only git add pumpkin/giant pumpkin/production pumpkin/tools.
- Rojo: C:/Users/zerha/.rokit/tool-storage/rojo-rbx/rojo/7.4.4/rojo.exe (shim fails in Codex shell). Blender: C:\dev\codex-lab\tools\blender.
