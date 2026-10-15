# ONE Studio pass — Steal a Treasure

Open `slice-v2/prototype/guardian-greybox.rbxl` **after reopening from disk**.
Fix 6 is built only into that requested place; `prototype/guardian-greybox.rbxl`
remains the previous build. No commit or publish. Byte-verified backup, created
before Rojo: `slice-v2/prototype/guardian-greybox.pre-fix6.rbxl`.
Results below distinguish Claude's real pass from offline checks and pending rechecks.

## Real Studio pass 6 / fix 6

OWNER-REPORTED: Claude, approximately 00:40 UTC, kits2 mounted: 74/74 templates,
117/117 textured MeshParts, zero imported scripts. DropSampleTest FAIL:
269/31,824; GreyboxLoopTest FAIL: `path recovery >30s: recover same dropped loot`.
Failure instances and drop/recovery details UNKNOWN: successful DropDiagnostic
spam displaced them from Studio's LogService history. Kit interference remains
INFERRED, not a confirmed category from that run.

CHECKED OFFLINE ROOT CAUSE: the first full kits2 sweep reproduced exactly
269/31,824 failures. All 269 hit native `TunnelValleyJoin`, a collidable authored
`lane` connector with top Y=0.12, coplanar with neighboring route decks. Its name
has no numeric route suffix, so isLane omitted it from the authored-floor tags.
The resolver accepted a coincident solid surface at the same height, while the
independent landing check correctly rejected its missing tag. This is evidence
for the sampler failure; the live Humanoid recovery failure remains unconfirmed.
Evidence: `FIX6-DROPS-before-join.json`, `FIX6-NATIVE-LANDINGS.json`.

Fix: explicitly recognize only TunnelValleyJoin with category=lane as authored
floor (a rock with that name remains rejected), and require the actual solid
landing surface to have WalkableLaneFloor=true even when heights coincide.
This preserves the existing lane geometry. Kit placement/query fixes below are
preventive; the reproduced 269 failures were not caused by imported kit meshes.

CHECKED SOURCE: removed all successful resolver/presentation diagnostic output.
DropSampleTest logs at most 30 individual failures and persists its current top
30 groups (count descending, grouped by lane, landing instance and reason), each
with up to three labeled sample positions. Attributes on ServerScriptService:

- `DropSampleTestFailures`: JSON array, including laneId, landingInstance, count,
  reason and samples with position/landingY. Empty after a clean run.
- `DropSampleTestFailureCount`: numeric total; `DropSampleTestSamples`: numeric samples.
- `GreyboxLoopTestLastDrop`: JSON with carrierPos, carrierFloorY, laneId,
  landingInstance, landingY, lootPos, recoverPath, reason. Captured at the actual
  drop using the resolver's pre-displacement carrier reference when available;
  pathfinding updates waypoints/retry/watchdog reason without losing that snapshot.
  Missing values are explicitly UNKNOWN/NONE. This attribute records the latest
  production drop; it is diagnostic state, not a saved player profile.

KitLibrary now makes all decorative components and generated trunk proxies both
noncollidable and CanQuery=false. KitSwap checks every component's conservative
footprint against every authored lane, reserving one stud beyond each edge.
Intersecting meadow placements are dropped with their original collision carriers;
accents receive the same check. All heights participate, covering stacked lanes.
Native bridge lanes remain in place. This can thin foliage near/under stacked
routes; Claude must check the visual result. KitLanePlacementsDropped records count.
The same gate applies to plant_bush/rock_largeC if selected, independent of asset
name or number of material MeshParts; this fix adds no new placements.

Stacked-floor fix: carrier floor selection examines all hits in its height band
and chooses the closest to feet, instead of accepting the first upper deck
within tolerance. Regression includes an upper deck 1.8 studs above the actual
feet floor. Route segment lookup uses equivalent scalar squared distances to
reduce allocation cost in the large live sampler; graph connectivity rules remain.

CHECKED: backup byte-verified before Rojo; eight mounts including updated KitLibrary
Manifest, KitPlan and KitSwap; Workspace/Lighting parity; 57 unrelated scripts
preserved; all 65 scripts compile at O0/O1/O2; 480 authored floor parts have tags
and LaneId. All 269 previously failed socket positions now independently hit
marked authored floors at the same height. Diagnostic mock: 36 failures produce
30 warning lines, one group with three positions, zero success warnings, cleared
stale failures, and drop/path/watchdog JSON preservation. Kit sanitizer/cache,
swap fallback/idempotence and coordinator/core/policy mocks PASS. Scoped gameplay
Selene: zero errors/warnings. Existing CC0 licences inspected; no new dependencies.

Offline kits2 lattice result: PASS, 0/31,824 failures after the connector fix
(before: 269/31,824). `prototype/FIX6-DROPS.json` records the completed sweep.
94 encroaching kit placements dropped; 200 swaps retained. Production
`slice-v2/prototype/check.luau` PASS, including recovery/path/expiry mocks and
built source parity. Sampler runs actual mounted Builder/Swap/drop resolver at N=8 with
three carrier edges and three knock offsets. Kit proxies use kits2 manifest sizes
and material counts; each material conservatively occupies the whole asset box.
They prove placement bounds/query exclusion, not imported mesh triangles/navmesh.
Real Studio recovery acceptance remains UNKNOWN; no live PASS is claimed.

Claude recheck: reopen the requested place from disk, fresh Play; run the server:

```lua
game.ServerScriptService:SetAttribute("DropSampleTestN", 8)
game.ServerScriptService:SetAttribute("DropSampleTest", true)
-- After completion, read the attributes directly; Output history is not needed.
print(game.ServerScriptService:GetAttribute("DropSampleTestFailures"))
game.ServerScriptService:SetAttribute("GreyboxLoopTest", true)
-- After completion/failure:
print(game.ServerScriptService:GetAttribute("GreyboxLoopTestLastDrop"))
```

Rebuild: direct pinned Lune 0.10.5 `prototype/fix6-build.luau backup` once
(refuses overwrite), Rojo 7.4.4 build `slice-v2/prototype/greybox.project.json`
to `prototype/fix6-rojo.rbxl`, then Lune `prototype/fix6-build.luau`.
Checks: `prototype/fix6-diagnostics-test.luau`, `prototype/fix6-check.luau`.
Source changes use apply_patch; backup/place/reports are generated outputs.
No commit or publish.

Pre-fix6 SHA256: `C628F3FB850EC956C334A2181657BEEFE90235572D43BA70A49897225A876BEF`.
Fix-6 SHA256: `782C110904B4CB061524CCDCFB5102BFFE5B7C4A8B62A832C955FB87B649975E`.

Lessons: When sample volume exceeds log history, persist bounded failure evidence
because successful samples must not erase failures. When kits gain material
components, check every component because a safe anchor does not prove safe bounds.
When identical failure counts survive dressing changes, inspect native coplanar
floor tags because an omitted named connector can imitate a kit collision bug.

## Historical real Studio pass 5 / fix 5

OWNER-REPORTED: Claude, approximately 00:00 UTC after fix 4, still fails at
east ClimbRamp shelf 21. Hit world ~(86.7,117,-468); recover goal
(81.65,120.20,-468); horizontal approach 0.71 studs with bot floor ~113.7.
Loot is about 3.5 studs above that lane. Exact landing instance UNKNOWN.
The historical 9,243 native offline samples omit asynchronous imported kit
placements and are NOT live recovery acceptance evidence.

CHECKED CODE: KitSwap explicitly makes its imported visuals noncollidable and
nonqueryable while preserving original collision carriers. Kit props causing
this specific hit remains a hypothesis, not an established cause.
The lane builder now sets the explicit CollectionService tag `AuthoredLaneFloor`
and a `LaneId` on authored floor parts. Landing rays include only collidable,
direct builder children with that tag and `WalkableLaneFloor=true`, without
`KitAssemblyId`. Exact lane/junction names must also have category `lane` and a
known route; edging suffixes and forged prop categories are rejected. KitLibrary
strips Walkable/WalkableLaneFloor attributes, floor tags and LaneId on import
and clone, including root models and generated trunk colliders.

Every production drop emits `[DropDiagnostic]`: landing ray instance full name,
Walkable and WalkableLaneFloor attributes, AuthoredLaneFloor tag, landing Y,
carrier floor Y and lane ID; it also logs the full-collision surface under loot.
Resolver diagnostics record the carrier floor before Guardian displacement.
Any runner recovery failure (including the thrown 30-second watchdog and legal
expiry) emits `RECOVER FAILURE underLoot=...` from a collidable ray below loot,
with instance, Y, floor markers and lane ID, before preserving the failure.

LIVE RECHECK: reopen `slice-v2/prototype/guardian-greybox.rbxl` from disk in a
fresh Play session. In the SERVER command bar run:

```lua
game.ServerScriptService:SetAttribute("DropSampleTestN", 8)
game.ServerScriptService:SetAttribute("DropSampleTest", true)
```

`DropSampleTest` waits up to 120 seconds for `KitSwapVersion`, refreshes the
allowlist after kit spawn, and uses the production resolver plus real Studio
collision rays over the loaded arena. N is 2..64 samples per route segment;
each point has three carrier lane offsets (-5/0/+5) and three lateral knock
targets (-20/0/+20). It checks every authored route segment, connected lane,
floor height, actual solid landing and kit marker contamination. It fails
closed on missing floors or unresolved sockets and reports failures with
instance names in Output. Results: `DropSampleTestResult`, `Success`, `Samples`,
and `Failures` on ServerScriptService. This is a live geometry/resolver sample;
physical Humanoid recovery is still tested by GreyboxLoopTest.

`StudioPassAll` now runs eight gates: SelfTest, DropSampleTest, LoopTest, PvP,
Trap, Core, Ravine, Tunnel. DropSampleTest runs before LoopTest with a 900-second
ceiling; the existing 30-second recovery watchdog is unchanged. Run the combined
pass, then inspect shelves 18-21, bridge/ravine and tunnel/hill; retain complete
DropDiagnostic and RECOVER FAILURE lines on failure. Live results remain UNKNOWN
until Claude runs this place. No current live PASS is claimed.

CHECKED BUILD: pre-fix5 backup byte-verified BEFORE Rojo; eight mounted sources
match disk, 57 unrelated sources preserved, Workspace/Lighting parity, all 65
scripts compile at O0/O1/O2. Builder contract: 479 tagged floor parts; forged
lane-named rocks/fences/edging rejected. Kit sanitizer poison-marker regression
PASS; coordinator order/failure/timeout/repeat and production reset checks PASS.
Production `slice-v2/prototype/check.luau` and core/policy mocks PASS, including
drop diagnostic fields and recovery wrapper behavior. Runtime Selene (excluding existing KitLibrary formatting
warnings): zero errors/warnings; KitLibrary has zero errors and existing compact
statement warnings. Source edits use apply_patch; place/backup are generated
binary outputs. No commit or publish. Existing CC0 kit assets/licenses reused.
The historical studio-pass-check artifact section targets the older root place;
use `lune run prototype/studio-pass-check.luau coordinator-only` for this pass.

Rebuild: `lune run prototype/fix5-build.luau backup` once before Rojo (refuses
overwrite); Rojo greybox.project.json to `prototype/fix5-rojo.rbxl`, then
`lune run prototype/fix5-build.luau`. Verify with `prototype/fix5-check.luau`.
Pre-fix5 SHA256: `264069C7B27A6438BB1D1B3B4D70DFEBFAA5EB4E831BEF30E7FCD6AE546E648C`.
Fix-5 SHA256: `3941D01CA99048D1F6F751DA81B6B5DCFBDA665176D9FAFC98F9DBDC8E707DA2`.

Lesson: When asynchronous dressing follows geometry construction, sample the
loaded place after dressing because offline geometry cannot prove live ray hits.

## Real Studio pass 4 / fix 4 - 2026-10-14

OWNER-REPORTED: Claude, approximately 23:30 UTC, kits mounted plus fix 3.
GreyboxLoopTest still FAILS at runner line 267, `path recovery >30s: recover
same dropped loot`. East ClimbRamp/shelf descent goals were
`(77.4,118.4,-468)` through `(85,115.1,-468)`; Guardian retained=false near
`(86.3,117.2,-468.3)`; recovery goal `(81.26,120.26,-468)` was above the lane.
The supplied log frame converts to world with `(0,76,-360)`.

CHECKED CODE: Guardian hit already computed its drop before carrier displacement.
Dropped loot was already anchored, with a cosmetic bounce; free physics flight
is not established as this failure's cause. The actual gaps were an unbounded
carrier-floor ray and a global route-center fallback without segment identity.
The floor ray now starts at carrier root +1 and skips surfaces outside +/-2 of
the expected feet height (root -3). An airborne pose without a matching floor
uses the actor's last grounded lane; absent both references, the drop refuses.
The cached grounded floor is updated only while the Humanoid is on the floor.

CHECKED IMPLEMENTATION: capture the carrier floor before Guardian displacement,
identify its nearest 3D route segment, and accept only that segment, its immediate
route neighbours, or segments sharing a 3D endpoint. X/Z overlaps do not connect
lanes. Each candidate still requires the walkable allowlist, +/-2 floor band,
body disc, slope and headroom checks. Radius failure clamps to the carrier's
current segment, with a nearest-first search for a clear point on that segment;
no valid point means refusal. Guardian lob/fan/slam/dash, PvP and traps share
the carrier resolver. The tunnel callback now uses the carrier rather than an
effect position. The explicit ravine-rim recovery exception remains unchanged.
Loot is anchored at the resolved socket and its residual assembly velocities
are cleared; the cosmetic bounce cannot change its authoritative position.
No active TNT implementation was added; synthetic Blast checks exercise the
same transition for a future caller, not live TNT physics.

CHECKED OFFLINE: extended `prototype/fix3-check.luau` writes
[FIX4-DROPS.json](FIX4-DROPS.json). It exercises the actual mounted Builder,
Arena adapter and native collision rays, including the pass-4 pose, every route,
lateral knock origins and remote knock targets with the original carrier lane
retained. Each result asserts same-or-connected segment, height, clearance,
identity, deadline and conservation for Guardian, Pvp, Trap, Blast and Drop.
All 9,243 samples PASS (9,102 local; 141 current-segment fallbacks), zero
failures. The pass-4 cached-floor regression settles at
`(86.3,112.120,-468.3)` in the actual mounted offline map.
`fix4-fixtures.luau` PASS: stacked spiral shelves, bridge/ravine, tunnel/hill,
disconnected same-height peers, and an upper deck first hit by the down-ray.
In the mounted offline map the reported root is over five studs above the
underlying deck, so its regression uses a cached grounded reference rather than
claiming the owner's approximate floor height is measured evidence.
Guardian kit tests (lob/group splash, fan, slam and dash) PASS. Fix-2 clearance
regression PASS: 12,743 checks, zero preflight or resolve failures.

Delivery mounts only ReachableDrops, GreyboxArena and Greybox into the backup.
Workspace/Lighting parity PASS; 61 unrelated sources, including KitLibrary and
the yielded test runner, preserved; all 64 sources compile at O0/O1/O2. Source
edits use apply_patch; the backup, Rojo binary and evidence JSON are tool outputs.
No assets/ or prototype/kits/KitLibrary.luau edits; no commit or publish.
Rebuild: run `fix4-build.luau backup` once BEFORE Rojo; Rojo the greybox project
to `prototype/fix4-rojo.rbxl`, then run `fix4-build.luau`. The backup refuses
overwrite; subsequent builds reject unrelated target source/scene changes.
Pre-fix4 SHA256: `DEDBC951E198E97DB98B4035ED058061F60D0C89F3E5F890A88AAD425CD9D358`.
Fix-4 SHA256: `264069C7B27A6438BB1D1B3B4D70DFEBFAA5EB4E831BEF30E7FCD6AE546E648C`.
Selene runtime: zero errors/warnings; scoped git whitespace check PASS.
`slice-v2/prototype/check.luau` PASS after final rebuild, including production
drop/PvP/trap/guardian/recovery mocks and exact mounted binary source parity.
Runtime gates remain NOT RUN; passing mocks do not establish live recovery.

STUDIO RECHECK UNKNOWN: reopen the slice-v2 place from disk; run StudioPassAll
and three Loop runs. At shelves 18-21, confirm Guardian hit and PvP Bump drop
the same LootId onto the carrier lane and recover within the unchanged 30s gate.
Repeat on the bridge above the ravine and in the tunnel below the hill; confirm
secure/place and the original ravine-rim recovery. Compare the pass-4 failure
with one successful recovery before wider acceptance. No new live Studio
session, screenshot inspection or independent critic acceptance is claimed.

Lessons: When a carrier is airborne, use its last grounded lane because its
knock pose cannot establish a new floor. When lanes overlap, require 3D graph
connectivity because a height band alone cannot prove the drop is reachable.

## Real Studio pass 3 / fix 3 - 2026-10-14

OWNER-REPORTED: Claude, approximately 22:40 UTC, real Studio after fix 2.
SelfTest, PvP (236 seconds, Bump/drop/settle/Grab/secure/place), Trap, CoreLoop,
Ravine and Tunnel PASS. GreyboxLoopTest FAIL at runner line 267:
`path recovery >30s: recover same dropped loot`. Carrier root was
`(84.43,115.81,-468)` on the east Slate shelf; drop recovery goal was
`(83.73,119.91,-468)`, about four studs above the reachable walking surface.
The previous script timeout was addressed by Claude's preflight `task.wait()`
every eight points; that exact runner change is retained. No recovery timeout,
test route, or reach tolerance was changed for fix 3.

CHECKED CODE: generic `SurfaceRole=Floor` admitted most collidable geometry.
The Builder now attributes only authored lane decks, junctions, walking courts,
bridge decks, tunnel floors, jump landings and portal aprons as
`WalkableLaneFloor=true`. Edging, rocks, fences, props, walls, ceilings and ramp
bases receive no eligibility. Existing geometry, collision, materials and route
data are unchanged. No new asset, package or licensing dependency.

Production drop settling raycasts down against that explicit allowlist. It
searches nearest-first on a one-stud grid within 12 studs; each candidate needs
the existing three-stud body disc, slope and head clearance, plus a full-solid
obstruction check. The settled floor must be within +/-2 studs of the carrier's
lane floor. If the radius has no candidate, the nearest valid route center
(sampled at <=1-stud spacing) at that same floor level is used. If no valid level
exists, the transition refuses rather than orphaning loot on scenery. The last
grounded lane floor provides a fallback for airborne/disconnected carriers. Ravine falls
still explicitly use the original rim-drop rule, independently of local settling.

CHECKED OFFLINE: `lune run prototype/fix3-check.luau` exercises the actual mounted
Arena adapter and Builder-created native Parts/WedgeParts through OfflineRay.
[FIX3-DROPS.json](FIX3-DROPS.json) records every one of the 20 route names,
<=2-stud segment stations and lateral origins at -6/-3/0/+3/+6 studs. All 9,102
samples PASS; 9,101 local and one deliberately forced route fallback. Each
sample checks Pvp, Guardian, direct Drop and a synthetic Blast transition for
reachability, original LootId/deadline and conservation. This does not simulate
Humanoids or claim live blast physics. Fixtures cover scenery rejection,
stacked floors, a four-stud rock lip, ceilings, +/-2 height rejection and absent
levels. The reported shelf now settles at `(84.43,112.364,-468)` in the offline
map, on the lane itself; its model/visual offsets remain unchanged.

Guardian lob/group splash, swept fan, slam and dash tests PASS via
`lune run kit-check.luau` from `slice-v2/prototype`; all accepted hits use the
shared production drop callback before carrier displacement. No active TNT
damage/knock-drop implementation exists in the mounted production code. The
optional CaveV2 TNT hooks in Feel are preview camera effects; synthetic Blast
coverage verifies the shared resolver if a future blast calls it.

Fix-2 clearance regression: PASS 12,743 checks, including 926 runner preflight
points, zero loop/PvP failures. Selene: zero errors/warnings; StyLua and scoped
git whitespace checks PASS. Final build preserves Workspace/Lighting and 56
unrelated Sources, mounts five reviewed Sources (including the yielded runner),
and compiles all 61 Sources at O0/O1/O2. Source edits used apply_patch; binaries
and JSON used the checked Lune/Rojo tools. No commit or publish.

Backup SHA256: `C21E7F4ED0D0592ACA853EA51CAB6D127CB5607CF30354501662325EA41F2DFF`.
Fix-3 SHA256: `251893101387A8ADD7E4599826F549344E514E352EA8FA6A2B9D7C4F9D2935DC`.
Rebuild: Rojo `slice-v2/prototype/greybox.project.json` to
`prototype/fix3-rojo.rbxl`, then `lune run prototype/fix3-build.luau`.
The build requires the pre-fix3 backup and refuses to overwrite that backup.

STUDIO RECHECK PENDING / UNKNOWN: reopen the slice-v2 place from disk, run
StudioPassAll, complete three Loop runs and repeat the PvP handoff. At the east
shelf, confirm the same acorn settles on the walkable deck and can be Grabbed;
repeat after a real guardian throw/splash and near shelf edging, then confirm
secure/place and unchanged ravine rim recovery. No new Studio session or shelf
screenshot inspection is claimed by Codex. Compare the old shelf failure with
the new reachable drop side by side before wider acceptance.

Lesson: When scenery shares a generic Floor label, allowlist authored walking
decks because a successful down-ray alone does not prove a reachable drop.

## Real Studio pass 2 / fix 2 — 2026-10-14

OWNER-REPORTED: Claude, approximately 22:00 UTC, real Studio Play after fix 1.
No EditableMesh log errors; pen aisle to home portal walked successfully.
SelfTest, Trap, CoreLoop, Ravine and Tunnel PASS. Loop preflight failed 75 points;
PvP failed 18 points, all on Meadow v4. This section supersedes pending fix-1
rechecks below. Fix-2 Studio locomotion, reward completion and appearance remain
UNKNOWN until Claude reopens the requested place and repeats StudioPassAll.

CHECKED OFFLINE: the actual pre-fix2 binary's Builder reproduces exactly **75
loop + 18 PvP failures** using the runner's resolve contract. All 93 decisions
are **MAP**, with no stale center height/offset failures. The full per-point
record includes runtime root coordinates, first failing hit/normal/height,
reason and decision in [FIX2-BASELINE.json](FIX2-BASELINE.json).

| Reported area | Checked cause | Fix |
|---|---|---|
| Bridge south, spiral foot, shelf 5–14 and 27–33, shelf/shelf_link foot, west PvP | Stone/floor discontinuities inside the clearance disc | Continuous floors, supported turning courts, stone tops cut below the lowest lane surface |
| Spiral and shelf 15–23 | Nominal 18-wide inclined slabs expose steep end faces at bends; clearance rays hit unwalkable faces | Upright native ramp wedges with vertical ends, full-depth bases and overlapping floors |

The cliff/wall message tests both upward **and downward** height differences.
For example, (7,79,-295) hits stone below the floor, rise -2.31; this is a lane
edge/support defect, not evidence that that particular stone protrudes upward.
Moving its waypoint would hide the map defect. No reported point was offset to
avoid a failing collider, and no clearance threshold was relaxed.

Builder now runs Fix2Routes after Fix1Art. The same RouteData centerlines author
the map floors and regenerate Gameplay navigation/test stations at no more than
3-stud spacing, preserving original vertices and route junctions. RouteData
itself is unchanged. Decks remain 18 studs wide, with at least 12 studs of
checked clear travel. Original lane materials/colors are reused. Near-flat
grades under the native 0.05-stud wedge size become full-depth level slabs,
within 0.025 studs of their authored grade. The 5,279 stone columns remain as
terrain below the lane floors; 116 ramp wedges and their bases replace the
problem sloped slabs. Tunnel, ravine and optional jump geometry is excluded
from the lane rewrite.

The runner and offline check share Clearance.resolve: the same 0.5-stud disc
samples, 3-stud radius, 35.1-degree walkable normal, authored-height tolerance
0.7, rise/drop limits 1.5/2.15 and six-stud upward ray. The offline ray provider
intersects the actual Builder-created Part/WedgePart CFrames, sizes and surface
roles; it does not substitute ideal route surfaces. It mirrors Loader's removed
stand-ins and Arena's Cover roles. Box, wedge, transformed ramp, narrow floor,
stone obstruction, stale height and upward ray fixtures verify the provider.

Final mounted binary: **PASS 12,743 resolve checks; loop bad=0, PvP bad=0,
total bad=0**. This includes 926 generated runner preflight points and route
sweeps every 0.5 studs, at center and +/-3 studs laterally, each with the full
3-stud clearance disc: the outer samples reach six studs from the centerline.
Full report: [FIX2-CLEARANCE.json](FIX2-CLEARANCE.json). The sweep covers surface
routes; it does not claim a new Tunnel/Ravine Studio pass or simulate Humanoids.

Reproduce from production: `lune run prototype/fix2-check.luau`.
Baseline: `lune run prototype/fix2-check.luau slice-v2/prototype/guardian-greybox.pre-fix2.rbxl baseline`.
Rebuild: Rojo `slice-v2/prototype/greybox.project.json` into
`prototype/fix2-rojo.rbxl`, then `lune run prototype/fix2-build.luau`.
The build refuses a missing backup and preserves Workspace/Lighting byte parity,
54 unrelated Sources, and compiles all 60 mounted Sources at O0/O1/O2. Source
edits used apply_patch; generated binaries/reports used the checked build tools.
Scoped git whitespace check PASS. No new asset, dependency, account or purchase.

Backup SHA256: `DDF023CF4102C8C8CFD6106C3C79B7FAE43F33BC1AB41154E4D6AA11AE56C0B7`.
Final SHA256: `E9B41FF61572D15CBD10C2E729601C71721CF8923C80BBAA7E8EB1FEE4CCBDD6`.

Claude rerun: reopen the slice-v2 place from disk, Play, run StudioPassAll; confirm
zero Loop/PvP preflight failures, actual spiral/shelf/west walking and secured
loop rewards, plus the already-passing home/art/policy gates. Check one full
approach/return visually before wider acceptance. No new visual/critic acceptance
is claimed by this offline fix.

Lessons: When a ray hits a thin ramp end cap, rebuild the floor because nominal
width alone does not prove a walkable surface. When map and navigation share
centerlines, regenerate stations from them because hand offsets conceal defects.
When cliff/wall reports stone, inspect the signed rise because the defect can be
missing support beside the lane as well as an upward obstruction.

## Real Studio pass 1 / fix 1 — 2026-10-14

OWNER-REPORTED: Claude, approximately 21:00 UTC, real Studio Play on the slice-v2
place. All three `prototype/studio-pass-1/*.jpg` were inspected during this fix;
they show the missing Home art and the hill skin / rounded mouth rocks. No new
Studio session or after-fix screenshot was captured by Codex.

| Check | Real pass 1 | Fix 1 recheck |
|---|---|---|
| SelfTest | PASS | Pending |
| GreyboxLoopTest | FAIL: waypoint preflight, 2 bad points | Pending; three successful runs required |
| GreyboxPvpTest | FAIL: waypoint preflight, 2 bad points | Pending; original ID/deadline handoff |
| Trap | PASS | Pending regression |
| CoreLoop | PASS, ProfileStore.Mock | Pending; durable DataStore remains UNKNOWN |
| Ravine | PASS, policy only | Pending; physical fall/climb UNKNOWN |
| Tunnel | PASS, policy only | Pending; physical traversal/intercept UNKNOWN |
| Keeper / Home art | FAIL: EditableMesh memory unavailable at Play | Pending; native blocks now replace both loaders |
| Tunnel appearance | FAIL: thin green sheet, stacked spheres, yellow props | Pending matched mouth/inside/top screenshots |

Exact shared blocker: `BAD WAYPOINT home aisle at -18, 3, 42:
GreyboxLoopTestRunner:54: clearance cliff/wall Pen2`.
P1 errors included `Failed to create empty EditableMesh ... reaching memory budget
limits`, `MeadowKeeper.Rig:87 ... Rig:61`, and `HomeArt:138 ... HomeArt:103`.

CHECKED CHANGES:

- `HomeAisleX=16.5`: three-stud waypoint radius ends at 19.5, inside the raised
  Pen edge at 20. Both longitudinal player corridors also clear the terrace
  stairs across the reachable gate range, with a 3.5-stud body-width reservation.
  An initial x=14 proposal failed this continuous stair check and was corrected.
- Native Part build, reusing the existing authored geometry/colors and component
  connectivity. Keeper: 80 visual blocks, original 16 Motor6Ds, wrist socket and
  animation sources. Home: one cached template per asset, then clones; Decor
  2,191 Parts, Pup 18, Crow 25, Acorn 3, OpenAcorn 4. No new dependency/license.
  Native bounds simplify curved/rotated details; silhouette parity needs review.
- Both loaders allocate **zero EditableMeshes**. Injected geometry failures print
  an explicit warning and create coloured emergency blocks. Each successful
  template/rig logs its Part count, zero editable allocation, and the session's
  `GraphicsMeshParts` MB (or explicit UNKNOWN if memory tracking is unavailable).
  This category measures the whole session, not this asset or an editable budget.
  API reference: [Roblox Stats](https://create.roblox.com/docs/reference/engine/classes/Stats).
- Hill: removed the thin triangulated skin/skirts; 452 visible grass caps up to
  four studs thick, 435 six-stud slate backing pieces, existing solid earth
  columns. Downward additions reserve route headroom. Rounded tunnel/hill props
  become overlapping voxel blocks; original collision hulls remain hidden.
  Eighteen mushroom caps have 36 glow spots; 20 amber placeholder crystal pieces
  become amethyst wedges. Rock/Basalt become Slate, timber becomes WoodPlanks;
  Grass and existing Cobblestone routes remain. No added collision walls.

CHECKED OFFLINE: Rojo 7.4.4 build; seven reviewed mounts, 51 unrelated Sources
preserved, all 58 embedded Sources compile O0/O1/O2; saved Workspace/Lighting
parity. `lune run prototype/fix1-check.luau` passes actual Keeper construction and
failure recovery, actual Home template/cache and failure recovery, aisle/stair
sweeps, native prop counts, all 7,369 original collision transforms/shapes, and
binary mounts. Runtime files: Selene 0 errors / 0 warnings, StyLua check PASS.
Production tunnel callback mocks PASS. `studio-pass-check.luau` passes 14 ravine
and 29 tunnel policy assertions, core mock suite, coordinator and production
reset scenarios; its later historical artifact comparison FAILS at protected
`ReplicatedStorage.TreasureCore.Profiles` (existing drift from pre-studioprep).
Its core call was repaired to pass the now-required MockStore fixture.

Fix 1 place SHA256: `DDF023CF4102C8C8CFD6106C3C79B7FAE43F33BC1AB41154E4D6AA11AE56C0B7`.
Pre-fix1 backup SHA256: `71194FCD0CA50C695C9DB171BEF254139ED0B54F8901C09B8C566C270DC19370`.

RECHECK IN STUDIO: fresh reopen/Play; run StudioPassAll again and save JSON/Output.
Walk both aisles from all eight gates, including beside/through terrace stairs;
verify return/Place access. Observe the Keeper's full attack rig, hand release,
hat and joint seams. Inspect Home decor, Open reveal, Pup/Crow, Index and late
join for hidden roots or duplicated blocks. Traverse both tunnel mouths/branches
and skylights; compare the same three pass-1 camera views for solid hill edges,
voxel rocks, planted crystals/mushrooms and unchanged headroom.

Load gate: eight clients with eight pets each; native pet maximum is 1,600 Parts
per client plus Decor 2,191 and Keeper 80 (counts, not measured performance).
Record each client's memory logs, frame time and repeated join/reset memory
growth. Eight-client performance and live mesh-memory MB are **UNKNOWN**.
Reference comparison: Grow a Garden is the existing Home art reference; compare
its readable block silhouettes/materials against the prior failed screenshot
and the new build side by side. Zion reviews this one fix before further art work;
no reference-quality or visual acceptance PASS is claimed offline.

Lessons: When aisles move, sweep the whole player corridor because waypoint
checks miss stairs between endpoints. When mesh budgets fail, use native cached
Parts because successful edit-mode geometry does not prove live allocation.

The original full acceptance checklist follows; unchecked boxes are pending,
and the real pass-1 table above supersedes its original NOT RUN baseline.

Merged sources: [merge](MERGE-V4-STUDIO-CHECKS.md), [core](CORE-LOOP.md),
[Keeper](../models/meadow-keeper/WIRING.md), [Home](../slice-v2/HOME-ART.md),
[R5](../treasure/map-v4/ROUND5-STUDIO-CHECKS.md),
[historical map](../treasure/map-v4/STUDIO-CHECKS.md),
[tunnel](../treasure/map-v4/TUNNEL.md). Current production source overrides older
stand-in, +24 summit, automatic Home hatch, and omitted-dash notes: summit is +48,
real Keeper has lob/fan/slam/dash, and **Place → hold Open** creates the pet.
Do not open the standalone meadow place for this pass.

Commands below use the **SERVER Command Bar** unless labeled CLIENT. Let
`s = game.ServerScriptService` in each command, or paste its full name.
Source route tuples are `(x,z,height)`; runtime world XYZ is
`Vector3.new(x,76+height,-360-z)`. Camera tuples below are local Roblox XYZ,
added to `(0,76,-360)`. Timings are estimates until measured.

## (a) Automated tests — first, one player

| Order / exact attribute or command | Expected result | Verdict |
|---|---|---|
| 1. Fresh Play; `workspace:GetAttribute("UseMeadowV4")`; player `GreyboxReady` | Both true; one live Keeper, one actionable acorn; `GREYBOX.SharedIsland.MeadowV4`; no old island/Home stub/duplicate rig. No mesh-loader/server errors. | [ ] PASS [ ] FAIL |
| 2. `game.ServerScriptService:SetAttribute("StudioPassAll",true)` | Fresh isolated store (`CoreUseDataStore=false`), one ready player at Home, no cargo/pets. Runs eight checks in order below; resets fixtures, shields, traps, Keeper, tunnel occupancy, plots and physical state between checks and afterward. No profile awards from legacy fixtures. | [ ] PASS [ ] FAIL |
| 3. `GreyboxSelfTestStudioPassStatus` | PASS; `GreyboxSelfTestResult=PASS`: coordinate contract only. | [ ] PASS [ ] FAIL |
| 3a. `DropSampleTestStudioPassStatus`; `DropSampleTestResult`, `DropSampleTestFailures` | PASS, Success=true, Failures=0. Real loaded geometry after KitSwap; inspect instance-named diagnostics. N samples per route segment, three carrier offsets, three knock targets. | [ ] PASS [ ] FAIL |
| 4. `GreyboxLoopTestStudioPassStatus`; `GreyboxLoopTestRuns=3` | PASS, Success=true, PassCount=3, ExpiryCount<3 (at least one secure/place). Record Catches, PortalToPortal, FreshToSteal and all Result attributes. Same physical LootId through drop/Grab/secure/place, deadline conserved. | [ ] PASS [ ] FAIL |
| 5. `GreyboxPvpTestStudioPassStatus` | PASS, Success=true, Handoffs=1. Real shield expiry, Bump hold, forced drop, settle/Grab, original ID/deadline, winner-only secure/place, real-time expiry and empty return. | [ ] PASS [ ] FAIL |
| 6. `GreyboxTrapTestStudioPassStatus` | PASS, Success=true; >=5 legal open-floor points, decoy tell/reaction, locked-attack preservation, caps/cooldown/lifetime/cleanup, protected and only-route rejection. Bridge/cave must not be legal trap floor. | [ ] PASS [ ] FAIL |
| 7. `CoreLoopTestStudioPassStatus` | PASS, CoreLoopTestSuccess=true. Isolated mock save/load, first Pup, duplicate Open/Collect, ID/deadline/roll conservation, retries/fencing/malformed data and capacity. This is not real DataStore evidence. | [ ] PASS [ ] FAIL |
| 8. `RavineTestStudioPassStatus`, `RavineTestResult` | PASS; all 14 existing policy assertions (fall/rim/ownership). Physical fall remains group (d). | [ ] PASS [ ] FAIL |
| 9. `TunnelTestStudioPassStatus`, `TunnelTestResult` | PASS; all 29 existing policy assertions (mud/lead/rumble/prediction/paths/occupancy). Artifact and callback mocks also run offline; human tunnel remains group (c). | [ ] PASS [ ] FAIL |
| 10. Wait `StudioPassAll=false`, `StudioPassBusy=false`; `print(game.ServerScriptService:GetAttribute("StudioPassResult"))` | JSON status PASS, eight rows with pass/result/seconds; each `<test>StudioPassSeconds` populated; StudioPassSuccess=true, GreyboxConservation=PASS. Failed tests still recorded and next test reset; timeout is FAIL (loop and drop sample 900s, others 300s). Save full JSON and Output. | [ ] PASS [ ] FAIL |
| 11. `game.ServerScriptService:SetAttribute("ShowDebug",true)`, then false, then true | Colored noncollidable/query/touch route lines, current elapsed endpoint timers, completed forward/reverse empty/carry times, Keeper mode/clip and guarded exit. False removes lines and HUD; no duplicate overlay on re-enable. Closed floor loop uses departure/return gate: follow full loop manually. | [ ] PASS [ ] FAIL |

Do not manually start another harness during StudioPassBusy. For a failure, save
diagnostics before manual play. One pass means one Studio visit: Stop/Play inside
it when required for clean state. CaptureShots moves the camera only; it does
not save screenshots or create gameplay rewards.

## (b) Full loop — steal > escape > open > pet > coins > save/load

| Order / exact command or action | Expected result | Verdict |
|---|---|---|
| 12. After automated reset, enter Home portal; hold native Steal E/touch/X for 2s; cross safety `x[-24,24], source z[-156,-116]` | Same LootId and frozen roll/deadline. No Coins for theft/carrying. Automatic secure once; return to own Home gate. No attack/expiry/rival takeover while secure save is pending. | [ ] PASS [ ] FAIL |
| 13. Place at chosen legal point, rotate/snap; attempt blocked/out-of-plot/entrance/overlap placement | Legal Place leaves closed acorn and one small pad; refusal retains cargo. Eight-pet cap refuses safely. No preset rows or fake occupied plots. | [ ] PASS [ ] FAIL |
| 14. Hold Open 0.6s or contextual touch Open; leave range/break sight during hold/dwell; repeat Open | Interrupted action awards nothing. Successful first Open commits one Pup/Common/+1 Coins/s, cap/crack/pop/sparkles/sound once, then same-pad pet. Repeat cannot mint. Skip closes presentation only; movement/input work during reveal (bounded 2.2s). | [ ] PASS [ ] FAIL |
| 15. Observe own plot bank; Collect at gate/prompt twice; rival attempts Place/Open/Collect | Bank accrues actual sum of online pet rates once per second; Collect transfers exactly once to Coins and zeros bank. Cargo/offline time earn zero. Rival refused; home pets/Coins remain safe. | [ ] PASS [ ] FAIL |
| 16. Repeat legal rewards; inspect Index, Pup/Crow feet, pose, labels and rare FX | First Pup +1; Rare Crow +4, Epic Golden Pup +8 per core config; Legendary weight=0, no claim of natural roll. Undiscovered silhouettes dark/?; committed discoveries reveal. Common no persistent aura. No mesh orphan/duplicate cap/stem, plot/gate overlaps, wrong rate or hidden root on loader failure. | [ ] PASS [ ] FAIL |
| 17. Second real client, handoff before safety; reset/disconnect before and after safety; late join during Open/mesh loading | Winner alone opens; loser no pet/Coins/first-pet consumption. Before safety same cargo drops, after safety saved pending cargo restores. One mesh/root each; late join never replays old celebration. | [ ] PASS [ ] FAIL |
| 18. `CoreUseDataStore=false` default; record HUD `STUDIO: UNSAVED`; inspect automated CoreLoopTest save/load evidence | Mock store round-trip PASS; explicitly record real durable reconnect as UNKNOWN if no configured QA environment exists. Stop/Play resets isolated store; never label it persistence PASS. | [ ] PASS [ ] FAIL |
| 19. **Only already configured separate QA experience:** set `CoreUseDataStore=true` before Play; save/rejoin after secure, Place, Open, Collect | QA store `TreasureQA_Core_v1`: same pet IDs/rarity/plot-local poses, pending cargo, Coins/bank/index/flags restored once. Unknown writes retry same revision; load/outage/lease conflict refuses safely, no default overwrite/duplicate reward. Test leave/autosave45s/shutdown. If unavailable, mark FAIL: NOT RUN/UNKNOWN; no publish/security changes. | [ ] PASS [ ] FAIL |
| 20. Phone landscape/gamepad, late join and full plots; 10-minute two-player leave/re-enter soak | Native prompts reachable, 48px touch targets, readable HUD/card/index/billboards, no focus/skip overlap, no duplicate hazards. Record device, graphics, frame time/memory and errors; eight-client/eight-pet load if available, otherwise UNKNOWN. | [ ] PASS [ ] FAIL |

## (c) Each Keeper attack + tunnel exit guard

Normal play triggers attacks; do not invent force-attack attributes. Observe
`Workspace.GREYBOX.SharedIsland` descendants: Guardian `KeeperClip`, model
`KeeperReleaseAt`, `KeeperReleaseObservedAt`, `KeeperReleaseOrigin` and impact
diagnostics where emitted. Save video tell → release → impact → recovery.

| Order / action / exact diagnostics | Expected result | Verdict |
|---|---|---|
| 21. Provoke lob at camp, west bends, bridge approach and raised east court; watch release diagnostics | Gather/hop; locked red landing; .620 release/.90 flight; one 4-stud boulder, socket matches hand, hat/arm clears. Cover blocks, floor lands; 8-stud splash needs sight/mercy/safety; no victim hit twice. Reverse after aim lock to dodge. | [ ] PASS [ ] FAIL |
| 22. Group at compatible midrange floor; provoke fan | Three capped acorns at .620 release/.70 flight, +/-16 degree lanes; individual swept cover collisions. Raised floor (>1.5 studs difference) uses lob/defers. No hat/hand clipping, extra projectiles or unsafe hill predictions. | [ ] PASS [ ] FAIL |
| 23. Approach <=12 studs; provoke slam grounded, then jump amber rim | .800 landing starts 24 studs/s expanding rim to22; properly timed feet >2.5 above floor avoid it. One hit/victim, planted weight/recovery and readable faint max tell. | [ ] PASS [ ] FAIL |
| 24. Provoke dash on compatible straight ground, then behind a wall | .50 planted tell, 24-stud committed straight dash at48 speed, side-step escape, wall/illegal-floor stop and1.55s stun. No retarget mid-dash, clip or hit spam. | [ ] PASS [ ] FAIL |
| 25. Chase all routes/elevations, break cover, leave/re-enter during windup; `GreyboxConservation` | Leash330; no cave entry, stuck/replan loops, prop clipping, moving recovery poof or premature south/east camp return. Arm/rock sweep and 20-stud sky clearance in motion; tells/projectiles cleaned on reset. Compare warning clarity to Fall Guys/Catastrophic Horse Racing. | [ ] PASS [ ] FAIL |
| 26. Carry into source(-76,27,0), exit source(-76,-78,0); repeat south(-61.867,-98.953,0). `TunnelInside`, `TunnelKeeperThrowsSuppressed`, `TunnelGuardedExit`, `TunnelGuardWaiting` | Inside true/suppressed; live Keeper leaps visibly to entry, follows west surface32 speed, guards exactly one predicted exit (60% nearest). No teleport/double guard. Wait up to14s after arrival, then3s after entrant exits; dropping inside keeps guard. Normal AI resumes after timeout. | [ ] PASS [ ] FAIL |
| 27. At guarded mouth accept contact, then rival Grab after0.6s; test ordinary attack inside | CONTACT uses TunnelGuard and shared forced drop/mercy; no lob/fan/ordinary Guardian damage inside. GuardianFirstHitRetains=false unchanged. One original ID/roll/deadline; no second carry implementation. | [ ] PASS [ ] FAIL |
| 28. Cross mandatory mud source z[7,-17]; inspect Humanoid.WalkSpeed | Speed<=8 through24 studs (~3s), server stumble can be slower; exiting restores current carry/stumble speed. No stale speed after drop/handoff/death. | [ ] PASS [ ] FAIL |
| 29. Carry inside1.6s, continue/stop/reverse/sidestep | .7s red warning +.35s fall; target leads motion1.05s; impact radius3, knock18 and shared forced drop. Warning readable at low graphics; no old-life impact. | [ ] PASS [ ] FAIL |
| 30. Camp >8s, drop, repick, exit/re-enter <=3s then >3s; `TunnelRumbling`, `TunnelRumbleActive` | Hazard interval2.4→.9; former thief rumble persists on drop; short re-entry retains age, longer starts new visit. Same visit repick doesn't restart intercept; new visit/handoff does. Death/respawn/disconnect detaches cleanup. | [ ] PASS [ ] FAIL |
| 31. Same entrance→near exit surface/tunnel, 10 experienced carry attempts per exit | Record each time/outcome/hit position and denominator. Estimates: surface119.066 studs=7.44s walk/8.82s carry; tunnel105 incl mud=8.06s/9.00s. South path = trunk first81 +branch49.30. Hypotheses: advantage<=3s (ideally<=1), hit20–35%, escape45–60%; report observed counts, no inferred stable rate. | [ ] PASS [ ] FAIL |

## (d) Route times, jumps, ravine fall + physical climb-out

`ShowDebug=true`; endpoint gates are within6 studs and include combat/pauses.
Completed times print `[StudioPassWalkTime]` and client player attribute
`StudioPassWalkTime`. Follow the entire named line, no shortcuts. Manual stopwatch
backs up automatic gates (nearby shared endpoints can start several timers).
Walk every row both directions, empty16 and carry13.5; record four measured times,
catches/stops/missed turns. The following values are **estimates, not pass results**.

| RouteData key / studs / estimated walk,carry seconds | Expected / measured forward empty,carry; reverse empty,carry | Verdict |
|---|---|---|
| summit_radial /30.00/1.88,2.22 | Continuous floor; ____ / ____ / ____ / ____ | [ ] PASS [ ] FAIL |
| spiral /196.85/12.30,14.58 | Continuous floor; ____ / ____ / ____ / ____ | [ ] PASS [ ] FAIL |
| fork_link /16.59/1.04,1.23 | Continuous floor; ____ / ____ / ____ / ____ | [ ] PASS [ ] FAIL |
| shelf /257.89/16.12,19.10 | Walking ramp; ____ / ____ / ____ / ____ | [ ] PASS [ ] FAIL |
| shelf_link /53.66/3.35,3.98 | Continuous floor; ____ / ____ / ____ / ____ | [ ] PASS [ ] FAIL |
| west /280.72/17.55,20.79 | Continuous floor; ____ / ____ / ____ / ____ | [ ] PASS [ ] FAIL |
| bridge /85.30/5.33,6.32 | Traverse both edges; ____ / ____ / ____ / ____ | [ ] PASS [ ] FAIL |
| bridge_south /76.27/4.77,5.65 | Continuous floor; ____ / ____ / ____ / ____ | [ ] PASS [ ] FAIL |
| east /119.41/7.46,8.84 | Continuous floor; ____ / ____ / ____ / ____ | [ ] PASS [ ] FAIL |
| east_climb /82.00/5.13,6.07 | Walking ramp; ____ / ____ / ____ / ____ | [ ] PASS [ ] FAIL |
| east_descent /136.51/8.53,10.11 | Walking ramp; ____ / ____ / ____ / ____ | [ ] PASS [ ] FAIL |
| north_crosslink /160.16/10.01,11.86 | All turns; ____ / ____ / ____ / ____ | [ ] PASS [ ] FAIL |
| south_crosslink /133.66/8.35,9.90 | All turns; ____ / ____ / ____ / ____ | [ ] PASS [ ] FAIL |
| portal_north /58.95/3.68,4.37 | Actual safety edge; ____ / ____ / ____ / ____ | [ ] PASS [ ] FAIL |
| ravine_ramp /131.06/8.19,9.71 | Physical climb; ____ / ____ / ____ / ____ | [ ] PASS [ ] FAIL |
| ravine_floor_loop /182.00/11.38,13.48 | Follow FULL loop before returning gate; ____ / ____ / ____ / ____ | [ ] PASS [ ] FAIL |
| jump_access /122.00/7.63,9.04 | Walk to pads; ____ / ____ / ____ / ____ | [ ] PASS [ ] FAIL |
| jump_recovery /90.77/5.67,6.72 | Walking miss recovery; ____ / ____ / ____ / ____ | [ ] PASS [ ] FAIL |
| tunnel_trunk /105.00/6.56,7.78 dry | Add mud1.50/1.22; ____ / ____ / ____ / ____ | [ ] PASS [ ] FAIL |
| tunnel_south /49.30/3.08,3.65 branch | Include first81 trunk for complete run; ____ / ____ / ____ / ____ | [ ] PASS [ ] FAIL |

| Ordered extra check / action | Expected | Verdict |
|---|---|---|
| 32. Full summit→safety spiral+west, spiral+bridge, spiral+east, shelf+west, shelf+bridge; five runs each plus shortest mixed/open-ground | Record route/settings/clean vs combat time; no hiding state/inaccessible socket. Historic +24/old lengths superseded; actual +48 route and measured times win. | [ ] PASS [ ] FAIL |
| 33. Source jump pads(148,-24,20),(148,-40,22),(148,-56,24): both4-stud gaps, both directions, empty/carry, three attempts each |12x12 pads, rises2, carry jump height7.2. Record successes/takeoff/landing/head strikes/lips; deliberate miss each side has walkable jump_recovery. Do not use old LoopTestJumpObserved as evidence. | [ ] PASS [ ] FAIL |
| 34. Two clients: fall off bridge center and each bank carrying; local root Y<0 Freefall within ravine | Same acorn goes reachable rim; thief remains bottom with no fall teleport/damage. Rival can Grab after0.6s. ID and60s deadline unchanged. | [ ] PASS [ ] FAIL |
| 35. Land then walk bottom loop→sourceX=-22 ramp→sourcez=-88/-102→south lane | Measure landing-to-surface incl approach; ramp estimate8.19s empty. Camera shows ramp, no dead end/teleport. Distinguish below-localY=-45 outside recovery; test death/disconnect/expiry separately. | [ ] PASS [ ] FAIL |

## (e) No float / clip / dead ends; Round 6 clusters

| Order / exact action | Expected result | Verdict |
|---|---|---|
| 36. Walk center and both edges of all20 route lines, ramps, courts, mouths and cross-links; cargo and third-person |18-wide surface lanes/20-high reservation; no snag, shoulder intersection, black seams/z-fighting, unintended shortcut, unreachable dropped socket or practical dead end. Tunnel14-wide; no extra unintended surface exits. | [ ] PASS [ ] FAIL |
| 37. Inspect oak/bush/boulder/flower/lantern/banner/fence feet and actual44 prop wedge sloped faces | No unintended float/sink/cliff/paving clips. Composite joins intentional. Bridge rails supported/connected, noncollidable fall-risk intentional, ravine walkout unobstructed; four lights in two junction pairs. | [ ] PASS [ ] FAIL |
| 38. Orbit all sides/underside and portal→summit sightline | Planted lip, five setbacks, two hanging points, dark depth266.5/width344; no drum. Four intentional floating accents/root/moss constructions exempt only by name. West oak/east spires/bridge/objective visible; cyan appears in time on escape turns; no foliage screen of real throws. | [ ] PASS [ ] FAIL |
| 39. Offline `prototype/meadow-v4/scene.json`: count keys in `r5.clusters` and `r6.clusters`; in Studio compare `ROUND6.md`/route-eye sheets | Reference57 mixed groups (>=2 tree heights, bush, boulder, flowers). CHECKED current manifest declares17 R5 groups and no r6 metadata, so57 is NOT VERIFIED. Look additions have no complete group inventory; manually count visible full groups, record actual/57 and fail mismatch. Do not infer clusters from raw part count. | [ ] PASS [ ] FAIL |

## (f) Lighting presets A/B

| Order / exact SERVER command | Expected result | Verdict |
|---|---|---|
| 40. `game.ServerScriptService:SetAttribute("LightingPreset","GardenWarm")` | A: Lighting.AppliedLightingPreset=GardenWarm; clock14/brightness2.8, warm silhouettes. Capture same shots at low/high graphics. | [ ] PASS [ ] FAIL |
| 41. `game.ServerScriptService:SetAttribute("LightingPreset","EggClear")` | B: AppliedLightingPreset=EggClear; clock13/brightness3, clearer cave/portal/attack rings. Same camera/device/settings for comparison; no stacked effects. | [ ] PASS [ ] FAIL |
| 42. Switch A→B→A, inspect cave, cyan portal, lamps, pet reveal; compare supplied references side by side | No overbloom/black seam/illegible tell, no new lamp rows. Zion chooses one using actual screenshots; existing presets are authored approximations, no reference parity claim. | [ ] PASS [ ] FAIL |

## (g) Capture shots for Zion — last

Finish manual Open with an owned pet first. Set `ShowDebug=false` for clean shots.
`game.ServerScriptService:SetAttribute("CaptureShots",true)` moves each client's
camera through these eight names, holds2s each, then restores type/subject/FOV/CFrame.
CLIENT `game.Players.LocalPlayer:GetAttribute("StudioPassShot")` and Output identify
the active frame. Repeat separately for A and B; screenshot capture itself is manual.
Save screenshots in `production/shots/studio-pass/` (clearly named; Desktop is outside
the writable root). Missing pet is explicit FAIL; helper does not spawn a fake pet.

| Name / local camera→target / FOV | Expected evidence / filename | Verdict |
|---|---|---|
| portal /(0,5.5,130)→(0,53,-96)/70 | West oak/east spires/bridge/summit; `A-01-portal.png`, B equivalent | [ ] PASS [ ] FAIL |
| summit /(0,53.5,-96)→(-76,5.5,-27)/70 | Live Keeper and cave relation; `A-02-summit.png` | [ ] PASS [ ] FAIL |
| bridge /(0,9,0)→(40,0,24)/70 | Edges/ravine/rim; `A-03-bridge.png` | [ ] PASS [ ] FAIL |
| tunnel mouth /(-76,5.5,-35)→(-76,5.5,5)/70 | Connected entrance/floor/silhouette; `A-04-tunnel-mouth.png` | [ ] PASS [ ] FAIL |
| tunnel inside /(-76,5.5,0)→(-76,5.5,35)/70 | Mud/cave readability; `A-05-tunnel-inside.png` | [ ] PASS [ ] FAIL |
| east ridge /(148,25.5,24)→(148,27.5,56)/70 | Two real jump gaps; `A-06-east-ridge.png` | [ ] PASS [ ] FAIL |
| home island /world(0,150,260)→(0,4,0)/40 | Home composition/plots/portal; `A-07-home-island.png` | [ ] PASS [ ] FAIL |
| pet reveal /owned pet+(8,5,10)→pet/50 | Actual opened pet, pad/name/rate; `A-08-pet-reveal.png`. Camera helper frames the committed pet; film the actual hatch separately. | [ ] PASS [ ] FAIL |
| After eight shots: CLIENT `StudioPassShot=DONE`; move/look normally | Camera fully restored. Repeat trigger works; overlapping triggers ignored. | [ ] PASS [ ] FAIL |
| Supplemental manual clips: attacks, near/south guarded exits, warning→fall→drop→Grab, physical ravine recovery and hatch | Still cameras do not prove motion. Add MeadowReferenceCamera/HomeReferenceCamera via GreyboxCaptureCams=true for overview; record10-minute soak performance. | [ ] PASS [ ] FAIL |

## P1 findings and fixes

- Legacy fixtures left RAM plots/carry/Keeper/tunnel state behind. Combined pass
  resets each boundary and final cleanup, cancels timed-out runner threads,
  resets physical velocity/ownership and preserves empty real profile. Refuses
  existing pets/cargo/real stores/extra players rather than discarding user data.
- Legacy conservation PASS could mean three legal expiries and zero secured
  placements. Combined pass fails that case; original runners remain diagnostic.
- Historical checklists contradicted current production (dash omitted, summit24,
  automatic hatch and standalone stand-in). This checklist uses current source.
- Empty-island idle state could rebuild the entire map on the next harness entry.
  Reset now clears idle/entrant markers and reuses the existing map; tunnel
  adapters are detached/re-attached without regenerating geometry.

## Evidence and limits

No new third-party code/art or licence dependency; inspected/reused local runners,
policy modules, camera coordinates and presets. Keystone exact Roblox Process
Playbook unavailable in exposed tools/local search; existing local source notes
and supplied owner instructions applied. Studio, real persistence, screenshots,
device cost and Zion acceptance remain UNKNOWN until Claude records this pass.
Named comparison bars: Steal an Egg (safe-return loop), Pet Simulator99 (hatch/pet
identity), Minecraft cave silhouettes, Fall Guys/Catastrophic Horse Racing (tells).
Compare one full loop side by side; no independent critic acceptance claimed.

Server attributes are bridged through ReplicatedStorage for the client overlay:
[ServerScriptService is not replicated](https://create.roblox.com/docs/reference/engine/classes/ServerScriptService).
Camera frames run after default camera priority:
[RunService documentation](https://create.roblox.com/docs/reference/engine/classes/RunService).
Offline commands/results: `studio-pass-check.luau`; preserved binary scene/source
checks plus existing core, loop, Keeper, kit, ravine and production tunnel mocks.
The legacy standalone tunnel artifact assertions remain in `tunnel-test.luau`;
only its29 engine-independent policy assertions belong in StudioPass.

Offline run 2026-10-14: Rojo7.4.4 PASS; new coordinator scenarios and core mock
suite PASS;43 unrelated source containers preserved; Workspace/Lighting serialized
byte parity PASS; canonical places byte-equal; all embedded Sources O0/O1/O2 PASS.
Existing check.luau, keeper-check, kit-check (including dash), keeper-clearance,
production merge-v4-tunnel-check and14 ravine assertions PASS. Selene runtime:
0 errors/0 warnings; StyLua runtime check PASS; scoped git whitespace check PASS.
Historical standalone `tunnel-test.luau` FAILS its immutable Loader source comparison
(`ReplicatedStorage.MeadowV4.Loader`), unrelated to these four mounts; the29 policy
checks and production callback mocks PASS. No historical artifact PASS claimed.
Cluster metadata gap is a manual visual acceptance gate, not a verified57 count.

Backup SHA256: `539E8059883A32DC878B067A5A888DE7DA00DB9623946EFAE0889415B8C76243`.
Final place SHA256: `5C0F8DF767E5A7524AE9B42638FBBAD41E42B0537AEC885F7CD252D943E7E220`.
Actual production reset body was also executed offline with fixture state:
actor/shield/plot/loot/velocity restoration, map reuse, tunnel reattachment and
real-store refusal PASS. No commit was made. Intermediate Rojo output is
`studio-pass-rojo.rbxl`; open only the mounted `guardian-greybox.rbxl`.

Lessons: When chaining harnesses, reset fixtures because conserved state can still
contaminate the next test. When every escape expires, fail the loop gate because
conservation alone does not prove a playable reward loop. When documenting a
merged place, use current source because historical stand-ins and timing notes drift.
