# Carry regression investigation — 2026-10-16

**Performance cause identified by Claude's live measurement; tagged conservation fix mounted. Live recovery/expiry retest remains UNKNOWN.** Section dressing remains stopped. The earlier geometry investigation below is historical evidence.

## Performance follow-up — 2026-10-16

- **Owner/Claude-reported live evidence:** GreyboxLoopTest on the current dressed place reduced server Heartbeat to 3.7 Hz, with a 1.49 s worst frame and 36,739 instances. These measurements were supplied in this follow-up, not independently profiled here. The runner calls `api.audit()` every movement poll; the old `conservation()` enumerated every Workspace descendant each time. S3/S4 dressing enlarged that enumeration. This is the measured performance cause; post-fix live timing and expiry outcomes remain unverified.
- **Reviewed source equivalence:** `visual()` is the sole `LootId` attribute setter across the Luau sources in slice-v2/prototype and prototype. It now tags the same BasePart `GreyboxLoot`. Carried/secured loot moves under characters, placed loot stays in GREYBOX, and retired visuals are destroyed; none removes the tag. CollectionService lookup retains BasePart, Workspace-descendant, known-ID and exact physical count checks. Native Instance Clone preserves both tag and ID, so extra physical clones still fail the original assertion. An untagged externally injected LootId part is outside this reviewed producer invariant; no runtime producer does that.
- **HomeArt/Pets:** HomeArt observes the server root's LootId and clones art templates, not that root; template parts do not set LootId. Core pets are domain records and rendered art, not another LootId producer. The server visual root remains the counted object through pet/art presentation.
- **Other scan review:** GreyboxArena/Arena.floor and KeeperAttacks use prebuilt filtered raycast parameters, with model scans confined to build/lazy initialization. LoopTest driver calls its waypoint validator before entering the movement polling loop; validator scans GREYBOX per waypoint/preflight, not per movement poll. Recovery modifiers scan at setup. Its two full-Workspace physical checks run once at expiry/placement; they remain independent checks over all LootId parts. No equivalent per-frame/per-poll full-Workspace scan remains in the requested paths. These setup/waypoint/one-shot scans were preserved to avoid stale collider snapshots or weakening assertions.
- **Artifact:** `guardian-greybox.pre-perf.rbxl` was written first and byte-verified. `treasure/perf-build.luau` mounts reviewed Greybox source directly into the canonical native place with Lune, preserving all 73 other source containers, serialized Workspace and assets. All 74 sources compile at O0/O1/O2; Section5 is absent. Partial S5 files remain untouched. No plain Rojo, commit or publish. Hashes: `treasure/PERF-BUILD.json`.
- **Conservation verification:** `treasure/perf-conservation.luau` executes the exact production visual/conservation bodies with native Lune Instances and a CollectionService registry shim. Twelve cases compare the old full scan with the tagged assertion: normal, duplicate clone, storage filtering, reparented clone, destroyed clone, missing visual, restored visual, character parenting, unknown ID, placed, retired, and a clone of a retired ID. All pass; native Clone tag/attribute inheritance is asserted. The shim excludes destroyed userdata as Roblox CollectionService does; this does not exercise the live service scheduler.

**Fresh final verification: PASS.** Offline origin/late-kit/failure-isolation and S2/S3/S4 cosmetic contracts; policy/domain/coordinator/reset behavior; existing 50-seed walking-floor/cliff/cover check with mounted source parity; all 12 conservation equivalence cases; production N8 DropSample **31,824 cases / 20 routes / zero failures**. Workers completed 14,904 + 8,280 + 8,640 cases and each exited zero, with 194 kit swaps / zero fallbacks. `treasure/perf-results.luau` verified exact-once complete route coverage and stable canonical/backup hashes. Results: `treasure/perf-evidence/FINAL.json`, `treasure/PERF-BUILD.json`, `treasure/perf-*.log`. The 50-seed test still uses the legacy numeric Layout fixture; DropSample uses the mounted production map with conservative kit bounding proxies. These are offline checks, not live navmesh, physics or Heartbeat measurements.

Canonical SHA-256: `1d3fcdade30d6e4a421063aeb5e652b3dbe1c1f87a69080413011e4670de03ba`. Pre-perf backup SHA-256: `10523bf474b8b48b81f67ee455646d96c4e90ae0f50e10c99b51c9d8020732e2`. Next live verification: restart Play with this artifact, profile server Heartbeat during GreyboxLoopTest, and rerun solo/PvP gates unchanged. Improvement and expiry recovery remain UNKNOWN until that run.

Reproduce with pinned Lune 0.10.5: `run treasure/perf-conservation.luau`; `run treasure/carry-tests.luau contracts`; `run treasure/carry-tests.luau behavior`; from slice-v2/prototype, `run check.luau`; from production, `run treasure/carry-tests.luau drop 1` (then 2 and 3). Do not rerun perf-build over its existing backup. Capture fresh logs as `treasure/perf-*.log`, then `run treasure/perf-results.luau`.

## Historical geometry investigation (before the performance follow-up)

The following sections describe the earlier unchanged artifact and its evidence, not the newly mounted performance fix.

## Evidence

- Owner-reported live evidence: S2 close-out had zero solo expiries; S3 had two or three; current StudioPassAll has three solo expiries and PvP cargo expiry. The reported carrier recovered from three Guardian hits and expired near the portal. These live results were supplied by Zion/Claude, not independently rerun here.
- Inspected Claude's existing `sections/S3/STUDIO-R4-FINDINGS.md`: it records two legal expiries in a passing three-run suite and a separate all-expiry/PvP failure **while eight Studio windows were open**. That makes a controlled single-window A/B run especially useful. It does not prove the current failure has the same environment or that window count is the cause.
- Compared `slice-v2/prototype/guardian-greybox.pre-s3.rbxl` with the current canonical `guardian-greybox.rbxl`, rebuilding each file's **own mounted sources** with the existing Lune builder. The baseline has 34,780 BaseParts; current has 35,253. Duplicate-sensitive multiset comparison found **zero added, removed, moved, resized, rotated or collision/query/touch-flipped physical parts**. Solid materials, attributes and tags also match. Thus the structural sight-blocker selection used by Arena is unchanged. This is native offline geometry evidence, not Studio navmesh or imported-mesh evidence.
- Both serialized Workspaces are empty and byte-equivalent. Neither contains ServerStorage. Geometry is constructed at runtime. No serialized cosmetic collider was hiding in the canonical Workspace.
- Exact mounted Source equality: GreyboxConfig, GreyboxLayout, Gameplay, RouteData, Fix2Routes, ReachableDrops, TunnelPolicy, RavinePolicy, Greybox, GreyboxArena, GreyboxLoopTestRunner and StudioPass. Keeper behavior, runner, speed, deadline and gate sources did not change between these artifacts.
- Only mounted source differences are Section3/Section4 additions and later Builder/Loader/Section1/Section2/KitLibrary edits. Existing source edits are yield checkpoints and Section2 light tuning. The section builders create noncollidable, nonqueryable, nontouching cosmetics; S3 removal guards cannot remove structural sight blockers. S4 bridge plank resizing affects cosmetic planks; the physical decks remain exact.
- The production `Gameplay.carry()` authored polyline is **507.1168 studs** in both versions. At CarrySpeed 13.5 its idealized length/speed is **37.5642 seconds** in both versions. `carry-route.json` lists every segment's distance, rise and slope; `carry-state.json` does the same for all RouteData paths. These exclude navmesh detours, acceleration, polling delays, dodge/hold time, hits and recovery. Actual live route time is UNKNOWN.

## Fix and artifact status

No causal source edit is justified by this diff. No timers, tests, Keeper rules, gates or production sources were changed, and no speculative fix was mounted. A no-op rebuild would conceal the unresolved problem and is not a fix.

Created and byte-verified `slice-v2/prototype/guardian-greybox.pre-carryfix.rbxl` before any possible mount. Canonical remains unchanged, SHA-256 `10523bf474b8b48b81f67ee455646d96c4e90ae0f50e10c99b51c9d8020732e2`. All 74 mounted source containers compile at O0/O1/O2. Section5 remains absent from the mounted place; partial S5 files were not edited. No plain Rojo, commit or publish.

One inspected performance lead, **not a demonstrated cause**: the movement driver invokes `api.audit()` every poll; `Greybox.server.luau` conservation scans the entire Workspace. More decoration increases that work. The additional native parts alone do not establish sufficient slowdown to explain the regression. Profile live server script/physics time before changing production code; do not weaken conservation assertions or change the runner.

## Verification

- Fresh origin/late-kit/failure-isolation and S2/S3/S4 cosmetic contracts: PASS (`carry-contracts.log`, `carry-evidence/CONTRACTS.json`).
- Fresh policy/core/coordinator/reset contracts: PASS (`carry-behavior.log`).
- Existing 50-seed walking-floor/cliff/cover check and built source parity: PASS (`carry-50-seed.log`). Its normal offline entry point uses the legacy numeric Layout fixture (the MeadowV4 install requires a live Workspace flag); its success does not establish mounted MeadowV4 traversal or live carry timing. The separate mounted builder comparison and production N8 DropSample cover native MeadowV4 geometry/resolution.
- Fresh unchanged production N8 DropSample: **PASS, 31,824 cases / 20 routes / zero failures**. Three disjoint complete-route workers passed 14,904 + 8,280 + 8,640 cases and exited zero. All reported 194 kit swaps / zero fallbacks. `carry-results.luau` checked exact-once complete route coverage, final canonical/backup hashes and the other completed test logs; see `carry-evidence/FINAL.json` and `carry-drop-1/2/3.log`. Kit geometry remains a conservative offline bounding proxy.
- Live solo/PvP retest, Studio physics/navmesh, runtime profiling and causal fix: UNKNOWN / NOT DONE.

## Evidence needed to finish

Capture a failing run's `ServerScriptService.PvpTestLastApproach` (contains phases, leg times, path points, stuck events, nearby blockers, WalkSpeed, remaining deadline), `GreyboxLoopTestLastDrop`, `StudioPassResult` and complete loop console log. Compare against the S2 close-out run in the same Studio session/device setup. Determine which leg or phase gained time and whether simulation runs slower than the deadline clock. No Studio integration is available in this session. A request for these diagnostics was sent to Zion in the task UI; no message was sent to another person or service.

## Reproduce the offline investigation

Run from production with the pinned Lune 0.10.5 executable (the Rokit shim in this restricted environment reports a missing home directory):

```powershell
& C:/Users/zerha/.rokit/tool-storage/lune-org/lune/0.10.5/lune.exe run treasure/carry-inspect.luau
& C:/Users/zerha/.rokit/tool-storage/lune-org/lune/0.10.5/lune.exe run treasure/carry-diff.luau
& C:/Users/zerha/.rokit/tool-storage/lune-org/lune/0.10.5/lune.exe run treasure/carry-state.luau
& C:/Users/zerha/.rokit/tool-storage/lune-org/lune/0.10.5/lune.exe run treasure/carry-route.luau
& C:/Users/zerha/.rokit/tool-storage/lune-org/lune/0.10.5/lune.exe run treasure/carry-tests.luau contracts
& C:/Users/zerha/.rokit/tool-storage/lune-org/lune/0.10.5/lune.exe run treasure/carry-tests.luau behavior
& C:/Users/zerha/.rokit/tool-storage/lune-org/lune/0.10.5/lune.exe run treasure/carry-tests.luau drop 1
# Repeat DropSample workers 2 and 3; each partitions complete routes without changing assertions.
```

Existing repository builders, native-ray implementation and offline contracts were reused; no third-party code or assets added. The exact Keystone Roblox Process Playbook was not present in the inspected local active-work filenames and no Keystone/Studio tool is exposed; its contents remain UNKNOWN. No new visual/reference comparison was warranted because no scene design was changed.
