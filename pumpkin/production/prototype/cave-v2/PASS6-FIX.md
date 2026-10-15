# Cave Studio pass 6: preserve the boarded rider

Owner-reported live evidence after cave-fix5: SelfTest, DropSampleTest,
BoardingTest and LoopTest (all three escapes) PASS. CartRideTest failed with
`wrong rider at End` after a broken-span Flight/Landing. Exact engine cause is
UNKNOWN; throwing/unseating and a stale respawn reference were hypotheses.

Inspected: Model:PivotTo moved cart descendants while the welded character
remained outside that model. Occupant changes revoked the confirmed rider;
recovery depended on a single deferred Sit. The previous code is preserved in
`pass6-backup-20261014-222609/`, with byte-verified place/source copies.

Production now applies one BulkMoveTo transform to every cart and confirmed
character BasePart, preserving their relative transforms and existing SeatWeld.
It retains the exact boarded Humanoid through transient Occupant loss, disables
Jumping while riding, retries Sit every 0.25 seconds if attachment is missing,
and records each retry. An intact weld is never destroyed by movement/recovery;
recovery will not reposition a root while a SeatWeld still exists. Dead/replaced
avatars are invalidated with an error rather than adopting a replacement rider.
Exit/reset releases the retained rider and restores its prior jump state.

The cart carries a CaveRiderControls LocalScript template, cloned into the
boarded character once. Both server and client apply/restore their own Jumping
state, since state enablement does not replicate between them. No new package,
art, external asset, account or licence dependency was added.

Flight/Landing/Fall samples record seat Occupant, SeatWeld presence, confirmed
rider and attachment validity at 0.1-second intervals, with matching Output
seat lines. Track samples retain the 0.5-second cadence. Re-seat events are
retained in CartLastRide and Output. Diagnostic buffers remain bounded.

Failed low-speed jumps eject the retained rider into the pit, clear its ride
reservation and restore controls. The existing cargo rule remains: same geode
ID and original 60-second clock during pit rescue. CartRideTest now carries a
real stolen geode on its slow fall, checks the pit position before walking the
recovery route, then checks ID, carrying status and the unchanged start time.
End rejects a replacement Occupant or foreign SeatPart, but accepts the two
properties clearing on different ticks during normal dismount. Complete
unseating at the expected platform is still required; Flight/Landing checks
continue requiring the original rider, SeatPart and weld together.
Arrival release runs once: Fall/Siding already released their riders, so End
cannot re-eject a stale Occupant onto the bypass during a long Heartbeat.

Built only the cave with pinned Rojo 7.4.4 then studio-build.luau using the
preserved pre-studio-pass baseline. All source edits used apply_patch. No
commit, publish or Meadow edit. The existing project code was reused; no
best-in-class visual comparison or independent visual review is claimed for
this focused runtime repair. The Keystone Playbook remains unavailable as
recorded in the earlier handoff.

Checked offline after the final build:

- All 28 embedded scripts compile at O0/O1/O2 and the binary roundtrips.
- Actual retention/movement/release helpers with virtual seats: intact weld
  identity, same bulk transform for cart/avatar, forced mid-air unseating and
  logged re-seat, pit ejection, stale respawn rejection, server/client prior
  jump restoration.
- Actual boarding helpers, driver integrator, fast jump/landing, slow fall,
  intact span, frame delays, reservations, reset/error retention. Slow fall
  ejects once into the pit and never onto the bypass, including three-second
  frames and delayed Occupant clearing. Removing the arrival guard reproduces
  the unwanted second bypass ejection in the same mock.
- Actual ride acceptance helpers: cargo/attachment/exit/arc, late End
  observation, wrong floor rejection, missing End and historical regressions.
  Actual CartRideTest fixture rejects changed ID, reset deadline or dropped cargo.
  End accepts either property clearing first and rejects a replacement Occupant
  or foreign SeatPart.
- Coordinator PASS/FAIL/watchdog, all cart-suite cleanup and evidence retention;
  shared economy/identity/place/open and drop-joint regressions; kit loader.
- Final mounted source parity includes the client control template; scene,
  kits, bounds/query exclusions, fence joints, SelfTest, floor seam and policy
  pass. Scoped runtime Selene: zero errors, zero warnings.

Dense N=8 drop sweep: PASS, 0 failures across 3,024 samples, with 1,898 retained
kit instances across 16 model types. See STUDIO-OFFLINE.json and PASS6-OFFLINE.log.
Offline checks use virtual seats/time and conservative solid/kit bounds.
They do not establish live weld physics, replication or a StudioPassAll PASS.
Claude should reopen `prototype/cave-v2.rbxl` from disk in a fresh Play session,
set ServerScriptService.StudioPassAll = true, and retain all six suite verdicts.

Three SERVER command-bar print lines after the run:

```lua
local s = game.ServerScriptService; print("ALL", s:GetAttribute("StudioPassAllResult"), "SELF", s:GetAttribute("SelfTestResult"), "DROPS", s:GetAttribute("DropSampleTestResult"), "BOARD", s:GetAttribute("BoardingTestResult"))
print("LOOP", s:GetAttribute("LoopTestResult"), s:GetAttribute("LoopTestError"), "BLAST", s:GetAttribute("BlastPolicyTestResult"), s:GetAttribute("BlastPolicyTestError"))
print("CART", s:GetAttribute("CartRideTestResult"), s:GetAttribute("CartRideTestError"), s:GetAttribute("CartRideTestCartLastRide") or s:GetAttribute("CartLastRide"))
```

SHA256:

- Backup cave: `B5ED4B9E9F26547EB45F165DC28CEDD0A55E8CF13555EB89C09B2C5F940E80A5`.
- Final cave: `E783E67AD1F852AE0F50495BD1D1A35798902CE5A59A668FE17CB6077F6A612B`.
- Unchanged Meadow: `CD7E5DC4475F504F84F3B92814837A7B5D577DE7293C1BC213A83A0118B1B134`.
- Guardian observed before/after: `0079B985B4D2F8346F9997BAEE62DDB5B52063425748412BDABB752629499732`.

API references checked: [Humanoid state controls](https://create.roblox.com/docs/reference/engine/classes/Humanoid),
[Seat attachment](https://create.roblox.com/docs/reference/engine/classes/Seat).

Lessons: When a welded rider lives outside the moving model, transform both
together because model descendants do not describe the complete ride. When
Occupant temporarily clears, retain the boarded avatar until intentional exit
because transient engine state must not erase its recovery identity. When
testing a failed jump, check the actual pit and cargo clock because a generic
unseated verdict can hide bypass ejection or a reset deadline.
