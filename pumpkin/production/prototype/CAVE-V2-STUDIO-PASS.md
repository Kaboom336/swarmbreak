# Cave v2: handoff for Claude

Latest repair: [pass 4 ride contract](cave-v2/PASS4-FIX.md), following the
owner-reported completed Track/End/Dock ride that the old harness timed out.
LoopTest now checks exit delivery; CartRideTest owns the armed jump/fall checks.
Use that handoff's fresh Studio checks and three evidence-print lines.
Offline contract regression: pinned Lune `run prototype/cave-v2/ride-contract-check.luau`.
Live Studio acceptance of this rebuild remains UNKNOWN.

## Correct full-place rebuild (run from production)

Back up `prototype/cave-v2.rbxl` to a fresh filename first. Then run:

```powershell
& 'C:/Users/zerha/.rokit/tool-storage/rojo-rbx/rojo/7.4.4/rojo.exe' build prototype/cave-v2/studio.project.json -o prototype/cave-v2/studio-rojo.rbxl
& 'C:/Users/zerha/.rokit/tool-storage/lune-org/lune/0.10.5/lune.exe' run prototype/cave-v2/studio-build.luau
& 'C:/Users/zerha/.rokit/tool-storage/lune-org/lune/0.10.5/lune.exe' run prototype/cave-v2/studio-check.luau artifact-only
```

Rojo creates a **source bundle**, not the playable place. `studio-build.luau`
merges it into the preserved `cave-v2.pre-studio-pass.rbxl` baseline and writes
`prototype/cave-v2.rbxl` with `Workspace.CaveV2`, `ReplicatedStorage.TreasureCore`
and `CaveRouteData`. Never point Rojo directly at `prototype/cave-v2.rbxl`.
The historical `cave-v2/build.luau` creates the native art baseline; it does not
mount the current Studio pass and kit sources, so it is not this rebuild entrypoint.

## Pass 2 repair (2026-10-14; current build)

Owner-reported real Studio evidence: SelfTest PASS; BlastPolicyTest PASS alone;
DropSampleTest failed 1/3,024 at carrier `(150.625, 51, -115)`; CartRideTest
timed out awaiting Occupant; LoopTest was not run. These failures supersede the
historical offline-green status below. No fresh Studio PASS is claimed here.

Before rebuilding, byte-verified backup:
`prototype/cave-v2.pre-pass2-fix-20261014-212117.rbxl`, SHA256
`3D5B4B233B3D88CF90A807E6FBC7F9BC2F1A4FD711AE227593A02E9CD4E69365`.
The full-place merge still uses the preserved pre-Studio baseline above.

- Main adjacent segments already share graph connectivity. The resolver now
  preserves candidate X/Z instead of feeding float-rounded ray X/Z back into
  another joint query, and revalidates returned sockets before accepting them.
  Ray drift is an inferred cause, not a proven explanation of the Studio failure.
  The exact reported carrier and both knock directions are regression checks;
  the offline footprint cache now preserves full coordinate precision.
- Ride prompts and the Studio BindableFunction share one production board action:
  Dock/range/alive checks, seat reservation, placement, stopped movement, repeated
  Sit requests through cooldown, and confirmed Occupant/SeatPart/SeatWeld before
  success. Both seats have collision/touch enabled, with one anchored cart base
  and all other parts massless and welded to it. Physics/replication need Studio.
- Ride tests approach from beside the cart and check rider attachment and distance
  during Track/Flight/Landing/Fall. Cart 1 tests the fast jump; cart 2 the slow fall.
  Both paths await production dismount before moving the avatar again.
  Pit ejection cannot trigger the flight reseat callback. State attributes publish
  after transitions/ejections. LoopTest arms its own real gap before its cart leg.
- `cart-board-check.luau` executes the production board function against a delayed
  mock seat: cooldown retry, confirmed success, timeout cleanup, repeat boarding,
  distance, concurrency and death refusal. This is not a Humanoid physics test.

CHECKED for this repair: full-place merge compiled 27 scripts at O0/O1/O2,
47 floor decks and 481 support trims; shared-domain/joint tests, production board
mock, runner PASS/FAIL/timeout mocks and kit-library tests passed. Scoped runtime
Selene: zero errors/warnings. Built cave SHA256:
`5B1B0C517419B0E9A22FDED57639EA96981C258F1C17A35D9383F644362B7947`.
Meadow place SHA256 remained
`FB8308C4AB4CD75C822F4ABFD3E739F15B1E03BF8D0D07A0F5BE6415A83175F3`.
Seat cooldown/weld behavior was checked against the
[Roblox Seat reference](https://create.roblox.com/docs/reference/engine/classes/Seat);
the delayed-seat mock does not establish that the engine behaved that way here.

Fresh dense offline sweep: **PASS, 0/3,024 failures at N=8**, including the
exact pass-2 joint regression, using unchanged drop code in this final build.
`STUDIO-OFFLINE.json` records 1,898 retained kit instances, 279 excluded and
16 retained model types. The final artifact-only check also passed source parity,
scene scope, kit bounds/query/fence joints, SelfTest, strict floor seam and policy
after the ride-dismount test change. This remains offline evidence only.

Fresh Studio acceptance remains required: open the rebuilt file in a fresh
session; rerun DropSampleTest N=8, CartRideTest and LoopTest independently, then
StudioPassAll. Manually use Ride cart, brake and bail on both carts, and fill the
passenger seat with a second player. No Meadow edits or commit are authorized.

Lessons: When a joint ray returns a socket, retain its requested X/Z because a
float-rounded hit can cross a slab edge. When boarding is asynchronous, wait for
Occupant and SeatWeld because issuing Sit is not evidence that a rider boarded.

## Historical pass 1 evidence

Prefix audit: SelfTest now uses a literal substring match for fence models.
The only other exact spawned-kit name check was the rejection diagnostic in
`studio-check.luau`; it now handles the prefix too. Its offline spawn proxy now
uses `island .. '__' .. name`, matching KitLibrary. KitPlan keys and spawn argument
comparisons are asset names, not spawned model names, and need no prefix change.
Lesson: make offline proxy names match the real loader, because otherwise a
passing offline SelfTest can hide a Studio-only failure. Owner-reported Studio
pass 1: 1,898 swaps, zero fallbacks, 279 rejected placements; 592 fences with
two endpoints. These are not a fresh Studio verification of this rebuild.

Rebuild verification (2026-10-14): byte-identical backup
`prototype/cave-v2.pre-prefix-fix-20261014-211158.rbxl`; full-place merge compiled
27 scripts at O0/O1/O2 and preserved 47 floors with 481 support trims.
`studio-check.luau artifact-only` passed mounted source parity, scene scope,
prefixed-kit SelfTest, fence joints, strict floor seam and policy; its kit proxy
accepted 1,898 placements, excluded 279 and reported zero unavailable assets.
`tests.luau` and `runner-check.luau` passed. No new Studio run or commit.

Open **`prototype/cave-v2.rbxl` from disk in a fresh Studio session**. Studio,
seat welds/replication, imported mesh geometry, textures, camera readability and
fun are **UNKNOWN**. Offline evidence is not a Studio PASS. Do not publish.
No commit. The guardian place and its sources were not edited.

## What changed

- Cave-only Rojo mounts reuse the current `prototype/kits/KitLibrary.luau` and
  kits2 manifest: 74 templates, 117 expected textured MeshParts. Existing local
  Kenney and Quaternius CC0 licences were inspected; no new dependency/download.
- Cave-local kit plan/swap fits dungeon columns, walls/openings, wood supports
  and structures, rock, barrel/chest/box supplies and mushrooms. Existing
  `CONNECT-KIT.json` contact pairs supply real fence bay endpoints. Accepted
  kit bays have two joint posts, including slopes. Every component passes the
  conservative one-stud exclusion against **all** lane decks at every height.
  Imported visuals are noncollidable, nontouchable and `CanQuery=false`.
  Rejected placements retain native art; a whole kit arch spanning a lane is
  intentionally rejected. Native collision floors and the breakable span remain.
- Strict floor allowlist: 47 authored lane parts, tagged `AuthoredLaneFloor`,
  `WalkableLaneFloor=true`, with `LaneId`. Rocks and kit components cannot qualify.
  Coplanar ramp end faces are skipped by the floor-only ray, so an almost level
  side face cannot hide a valid flat deck. Solid landing checks still include
  those faces and require an actual tagged floor at matching height.
- The first coarse sweep failed 37/756 drops. Independent rays identified
  `RouteRockButtress` protrusions through sloping decks. The denser sweep also
  identified `StackedMesaRock` protrusions. Build trims only those two families
  below the neighboring deck underside; 481 pieces are trimmed/disabled.
  Authored route floor CFrames/sizes, other scene parts and Lighting are preserved.
- Production cave drops use Meadow's resolver: closest floor to feet, 3-stud
  landing footprint, same-height connected route segments, full solid/headroom
  checks, same cargo ID and original 60-second deadline. Recovery permits 4.5
  studs vertically. Drop/Recover prompts exercise this production path.
- `StudioPassAll` runs SelfTest, DropSampleTest, LoopTest, CartRideTest and
  BlastPolicyTest in order; first failure stops the chain. Physical fixtures
  require one fresh empty cave profile and restore/reset the test avatar/profile.
  Used profiles are refused. No DataStore or live persistence is introduced.
- Cart test boards a real Humanoid, observes Track/Flight/Landing, checks height
  during flight, repeats at 12 speed to observe Fall, then walks pit recovery.
  It checks JUMP READY and actual support-break/occupancy-gated repair. LoopTest
  separately secures/opens the original cargo via main, cart and cave escapes;
  walking routes include an actual drop, walk to loot, recover and deadline check.
- TNT/dynamite/shatter remain non-damaging preview hooks. Policy checks cover
  committed speed, arming/cooldown, occupancy and repair age. The live suite also
  invokes the real timed previews and checks tell/payoff, cooldown, health and
  cargo identity. These hooks do not implement a combat/blast-force system.
- Failure JSON is capped at 30 records and warning lines per suite. Success
  samples do not log. Sampler, dressing and long resolver loops yield. Worker
  watchdogs cancel at 900 seconds for drops / 360 seconds for other suites.
  No runtime RenderFidelity writes. Studio-only server BindableFunctions invoke
  the same actions as prompts; manual checks must still verify prompt holds/UI.

## Studio commands (SERVER command bar)

Start fresh Play with exactly one player. Wait for kit loading before walking.

```lua
local s = game.ServerScriptService
s:SetAttribute("DropSampleTestN", 8)
s:SetAttribute("StudioPassAll", true)
```

Poll in a separate command after the runner starts; RUNNING is not PASS:

```lua
local s = game.ServerScriptService
print("ALL", s:GetAttribute("StudioPassAllResult"))
for _, name in {"SelfTest", "DropSampleTest", "LoopTest", "CartRideTest", "BlastPolicyTest"} do
    print(name, s:GetAttribute(name .. "Result"), s:GetAttribute(name .. "FailureCount"))
    print(s:GetAttribute(name .. "Failures"), s:GetAttribute(name .. "Error"))
end
print("drops", s:GetAttribute("DropSampleTestSamples"), s:GetAttribute("LoopTestLastDrop"))
print("kits", workspace.CaveV2:GetAttribute("KitSwapped"), workspace.CaveV2:GetAttribute("KitLanePlacementsDropped"))
```

Each suite can be triggered independently with `s:SetAttribute("SelfTest", true)`
(substitute its name). Restart Play between physical suites/after failures.
Retain the JSON attributes even if Output history is truncated. Expected full
drop denominator is 3,024 (42 non-rail segments x 8 x 3 edges x 3 knock offsets).
Do not infer PASS from a partial denominator or old per-suite result.

After automated PASS, manually hold Steal for two seconds; board/brake/bail both
carts, check low/high graphics textures and JUMP READY legibility, inspect every
pit fence joint and tunnel mouth from carrier camera. Compare one complete cave
escape side by side with the owner-reported Studio-green Meadow (dd5c600), and
the existing cave concept sheet for silhouette/readability. No visual critic or
reference parity PASS is claimed by this offline handoff.

## Exact offline/rebuild commands

Run PowerShell from `C:\dev\codex-lab\pumpkin-loop\pumpkin\production`.
Pinned executables avoid Rokit shim environment failures.

```powershell
$caveLune = 'C:/Users/zerha/.rokit/tool-storage/lune-org/lune/0.10.5/lune.exe'
$caveRojo = 'C:/Users/zerha/.rokit/tool-storage/rojo-rbx/rojo/7.4.4/rojo.exe'
# ALREADY DONE before the first Rojo build; refuses to overwrite the backup:
# & $caveLune run prototype/cave-v2/studio-build.luau backup
& $caveRojo build prototype/cave-v2/studio.project.json -o prototype/cave-v2/studio-rojo.rbxl
& $caveLune run prototype/cave-v2/studio-build.luau
& $caveLune run prototype/cave-v2/tests.luau
& $caveLune run prototype/cave-v2/cart-board-check.luau
& $caveLune run prototype/kits/library-test.luau
& $caveLune run prototype/cave-v2/runner-check.luau
& $caveLune run prototype/cave-v2/studio-check.luau 8
# Faster final mount/scene/kit/strict-floor contract check, without resampling:
& $caveLune run prototype/cave-v2/studio-check.luau artifact-only
& 'C:/Users/zerha/.rokit/tool-storage/kampfkarren/selene/0.31.0/selene.exe' --display-style Quiet --config slice-v2/prototype/selene.toml prototype/cave-v2/Cart.server.luau prototype/cave-v2/Loop.server.luau prototype/cave-v2/StudioPass.server.luau prototype/cave-v2/Drops.luau prototype/cave-v2/Kits.server.luau prototype/cave-v2/Policy.luau prototype/cave-v2/ReachableDrops.luau prototype/cave-v2/KitPlan.luau
```

Build uses the byte-verified `prototype/cave-v2.pre-studio-pass.rbxl` baseline;
it never opens or rebuilds the guardian place. Do not run the historical cave
`build.luau` or multi-place `prototype/kits/build.luau` for this handoff.
Source changes use apply_patch; binary backups/builds and JSON evidence are
generated outputs. Keep the supplied backup; do not overwrite it on a rebuild.

CHECKED: source compilation at O0/O1/O2, binary roundtrip, strict floor tags,
scene scope, kits2 manifest provenance, conservative kit bounds/query exclusion,
stacked floor regression, policy, economy idempotence/place/open, kit sanitizer
cache/retry/poison-marker contracts, and real coordinator PASS/FAIL/timeout mocks
(40 failures retain 30 records/logs; stale evidence clears; timeout cancels).
CHECKED dense sweep: **PASS, 0/3,024 failures at N=8**, recorded in
`prototype/cave-v2/STUDIO-OFFLINE.json`. Kit bounds mock retains **1,898 instances
across 16 model types**, rejects 279 candidates, and has zero missing templates.
This includes accepted kit fence bays with two joint posts each. Final artifact
check passes mounted-source parity, scene scope, kit bounds/query exclusion,
fence joint markers, SelfTest, the ramp-side/flat-floor regression and policy.
Scoped runtime Selene: **zero errors, zero warnings**. No live PASS is claimed.

SHA256:

- Byte-verified pre-Rojo cave backup:
  `A1D0E50AEF1A36621E45742DEEE9F512DACC3841FEEE29DE8F07143B0BCBE2F1`.
- Final cave place:
  `CDBBB43A9CEFE3F47452C8957BEE4989A6DF89D2C8A0E7198DB41867E51EFE35`.
- Protected guardian place, checked unchanged during this task:
  `FB8308C4AB4CD75C822F4ABFD3E739F15B1E03BF8D0D07A0F5BE6415A83175F3`.

Ray tests use native OBB/wedge faces and conservative per-material kit bounding
proxies, not imported mesh triangles, Roblox navigation or Humanoid physics.
The exact Keystone Roblox Process Playbook was unavailable in exposed tools and
the local note search; the supplied instructions, local production skill and
existing Meadow/cave evidence were used. No independent visual critic was run.

## Lessons

- When slope drops fail, inspect native support tops before blaming imported kits,
  because sampled support blocks can protrude through an otherwise valid deck.
- When a ramp side and flat floor almost coincide, recast without the steep part,
  because lowering the ray origin can skip the real floor by a fraction of a stud.
- When a later art pass changes prop names, reuse its contact manifest, because
  matching an obsolete fence family silently produces no replacement fences.
