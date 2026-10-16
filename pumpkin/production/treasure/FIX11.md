# Fix11: stable bell clearing and observable Grab refusals

Owner-reported: fix10 wall bait fully passes LIVE; PvP approach is 33 seconds; bell placement and a dropped-acorn hold remain red. Exact live Grab blocker is UNKNOWN. No Studio connector is available; the open Studio session was not changed or saved by this task.

Changed with apply_patch, no commit: the bell now uses the existing local (36,0,64) clearing, world (36,76,-296), instead of searching the west hillside. The full 18x18 production trap envelope is checked, entirely outside authored lane footprints. Section1's existing end-of-build and late KitSwap audit reserves a 20x20 clearing plus its normal one-stud margin, removing intruding cosmetic assemblies. No floor, lane, wall-bait collider, court, timer, charge or trap acceptance rule changed.

The dressing audit explicitly makes cosmetic parts noncollidable, nonqueryable and untouchable, marking them Cosmetic. Arena sight now uses a separate structural-collider inclusion filter built after scene construction, so late cosmetic kits cannot enter the ray. Floors and gameplay cover still obstruct sight. Stationary loot resets carried rotation and rests at least half its root height plus 0.05 above the authoritative floor socket; the settle bounce uses the same height. Socket position, pickup range, ownership, original deadline and hold validation remain unchanged.

Failed item holds now return range versus sight, measured distance/limit, full blocking instance path or NONE, root and socket coordinates. ServerScriptService.LootHoldLastRefusal also retains item ID/version, target, ray hit and visibility as JSON. This lets the live rerun distinguish a real obstruction from arriving outside the unchanged four-stud Grab range, without assuming either was the reported cause.

Backup BEFORE Rojo: slice-v2/prototype/guardian-greybox.pre-fix11.rbxl, byte-verified SHA256 D3F65336ABCE6E4216AA2F461C85CBC4FACD4257411391DD3C2249A82E9578E0. Source audit compared all six relevant pre-fix11 modules with fix10: identical, so no newer saved Claude source was overwritten. The build mounts only five changed modules into that backup; 66 unrelated sources and serialized Workspace are preserved. 71 scripts compile at O0/O1/O2.

Checked offline: fixed bell production floor/Traps.spot full envelope and off-lane footprint; real late dressing audit; structural sight inclusion policy; production Grab check at the reported local drop coordinates, unchanged range rejection and blocking-instance diagnostics; stationary root height/rotation. Existing check.luau passes (50-seed legacy geometry, deadlines/conservation, PvP/traps/navigation mocks); fix10-check.luau passes including both-origin wall impacts, one stun/star event, no refresh, late kit wall retention, court and route diagnostics. Selene: zero errors/parse errors, style warnings. Native-part casts and navigation mocks do not establish live navmesh or physics behavior.

Claude rerun: reopen slice-v2/prototype/guardian-greybox.rbxl, restart Play for OutsmartTest, then GreyboxPvpTest, then StudioPassAll. Require the original item and deadline. Capture LootHoldLastRefusal and PvpTestLastApproach if red. Runtime acceptance remains UNKNOWN. No live sync, publish or commit.

Lessons: When a test needs a placement clearing, reserve its full validated envelope because dressing can consume it. When a hold can fail for range or sight, record both values and the blocking instance because a combined refusal hides the cause.

The exact Keystone Roblox Process Playbook remains unavailable in the local sources checked by fix10; the supplied project process rules were followed. No new art or mechanic was introduced in this scoped repair.
