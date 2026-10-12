# T2 — production run contract and server authority

DRAFT future task. After T1 core-moment owner check. One writer; no parallel edits. No commit/publish/spend/real-save reset. Read actual current Patch code and reuse its safeguards before extracting logic.

## Files touched (future only)

- `pumpkin/giant/src/ReplicatedStorage/PatchConfig.luau`
- New `pumpkin/giant/src/ReplicatedStorage/IslandConfig.luau`
- New `pumpkin/giant/src/ServerScriptService/IslandRuns.luau`
- `pumpkin/giant/src/ServerScriptService/Patch.server.luau` (run adapters/feature gates only)
- New `pumpkin/giant/scene/IslandScene.luau` (plain template/scene contract)
- `pumpkin/giant/sync.project.json` (map existing files only after created)
- `pumpkin/production/slice-v2/CONTRACT.md`, `evidence/T2-run.md`

## Work

1. Freeze names/types for run request/state messages in existing PatchRemotes: enter/steal/return/cancel, runId/slot/seed/recipeVersion/island/difficulty/event snapshot/cargo itemId. Clients supply intent only. Specify allowed transitions Home→Outbound→Carrying→Returned/Recovery; placement/hatch contract handed to T3.
2. Add explicit evergreen-slice mode, isolated QA namespace and clean-profile defaults; retain legacy seed/zone/upgrade fields. Do not change owner/live namespace or purge older future-zone pets. Gate all old schedules/economic remotes so hidden handlers cannot mint rewards. Record compatibility policy separately from clean-profile tuning.
3. Port validated T1 piece recipe/connector geometry; module owns eight slots, per-run guardian and one reward. Server selects seed/difficulty/outcome; separate geometry/reward RNG. Active slots do not regenerate. Scope old zone singleton lookups and `Lane.zone/SafeLineZ` checks to adapters that use run volumes/waypoints.
4. Validate loaded/alive player, owned slot, state, cargo capacity, range,1s continuous hold and cooldown; reject wrong runId/type/nonfinite/spam. Escape needs committed steal + valid return pad. Guardian cannot hit through cover or across adjacent runs; no mandatory jump/fight.
5. Transfer same-place, preserve itemId/ownership. Reserve one pen slot before entry; reject full pen. Release reservation on pre-steal cancel; committed cargo retains reservation through recovery. Death/leave/rejoin must not clone or reroll the item; durable recovery fields are completed in T3.
6. Disable `Hoards.swing` auto-theft, old timed drop/giveBack loss, Wild payout/spawns, boss/raid/Purge/Spooky/Daily/orders/pass/sell/fuse/offline/compensation economy. Keep compatibility source, exclude its runtime branches. Map only Patch + required new modules; Feed/Giant stay excluded.

## Acceptance

- Compile existing checks at O0/O1/O2 debug2; assert final-returned config, not initial table. Contract enumerates active and disabled handlers, seed/version fields and T3 persistence obligations.
-50-seed validation per preset:3–5 instances,84–112 route,96×144 bounds,≥12 clear paths, one guardian/reward, reachable return. Invalid recipe falls back deterministically within8 attempts; inspect rejection coverage.
- Studio solo/two clients exercise each transition/replay, wrong ownership/range and reset; one authoritative item acquisition and one completion. Walk at least10 layouts and check guardian navigation forward/back. Stub placement is marked incomplete until T3.
- Eight-slot isolation smoke; ninth entrant has no pen/slot allocation, no reused owner. No live profile access. Capture logs/seeds and failed cases; static success is not multiplayer proof.

Next: immutable CONTRACT handed to T3; T3 adds the completed pen/save/economy loop, without expanding mechanics.
