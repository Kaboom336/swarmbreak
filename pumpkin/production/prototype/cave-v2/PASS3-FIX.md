# Cave Studio pass 3 repair

Owner-reported: SelfTest PASS; DropSampleTest PASS 3,024/3,024;
LoopTest ride timeout, carts subsequently Dock; later suites not reached.

Inferred cause, not a Studio-confirmed diagnosis: production discarded every
Heartbeat second above 0.1, while support repair and cargo expiration used wall
time. A delayed cart could reach the span after repair, take the intact track,
finish and dock without Flight/Landing. The old ride predicate then waited until
timeout. No pre-fix live trace exists to prove this was the reported run's cause.
The backed-up pre-fix controller reproduces this exact state sequence in the
virtual timing regression: 0.3-second Heartbeats and real-time repair produce
End at about 48 seconds and then Dock, with no Flight/Landing. This confirms the
code defect; connecting it to the reported Studio run remains an inference.

Changes reuse the existing production controller and prompt action:

- Consume the full Heartbeat delta using <=0.1-second integration steps.
- Reserve span state from occupied departure, blocking repair during approach;
  brake remains available until the original near-gap speed commitment.
  Departure waits for a support blast's fuse/cracks to finish.
- Cart `CartLastRide` JSON contains timestamped transitions, bounded samples,
  TrackDistance, both Occupants/welds, speed, rail segment, jump/state,
  broken/armed/reserved/committed flags and last error. ServerScriptService
  `CartLastRide` contains `{carts = [cart1, cart2]}`. Heartbeat exceptions are
  captured. Dock/fixture reset retains evidence; next boarding starts a new ride.
- LoopTest/CartRideTest reset both carts/span/switch before and after runs,
  including errors/watchdog. Generation tokens invalidate old blast/repair and
  switch timers. Suite-specific `LoopTestCartLastRide`/`CartRideTestCartLastRide`
  preserve the snapshot before cleanup. Timeout snapshots include the expected
  terminal sequence. Tests and player prompts still call the same board action.

Backup: `pass3-backup-20261014-214253/` contains the original cave binary and
both edited runtime scripts. No commit; Meadow sources and places untouched.
Build: documented `studio.project.json` Rojo build then `studio-build.luau`,
using the preserved pre-studio-pass baseline. Historical multi-place builders
were not used. No new dependency or asset.

Checked offline: all embedded scripts compile O0/O1/O2; binary roundtrip;
production drive mocks at 1/60 and 0.5-second frames, jump/fall/intact span,
approach reservation, completion, repeated reset and persistent injected error;
boarding cooldown/weld mocks; coordinator PASS/FAIL/watchdog and both cart
suite cleanup mocks; shared core/joint regressions; final mounted source parity,
scene preservation, kit bounds/query exclusion and strict-floor checks.
Runtime Selene: zero errors/warnings. Physics, replication and live Studio suites
after this patch remain UNKNOWN. No new visual/art claim or visual review.

The exact Keystone Roblox Process Playbook remains unavailable in the exposed
tools/local search, as documented in CAVE-V2-STUDIO-PASS.md. The local Roblox
production skill and existing build/check workflow were used.

Recheck in fresh Studio Play: `game.ServerScriptService:SetAttribute("StudioPassAll", true)`.
After completion/failure, these three SERVER command-bar lines retain the useful evidence:

```lua
local s = game.ServerScriptService; print(s:GetAttribute("StudioPassAllResult"), s:GetAttribute("LoopTestResult"), s:GetAttribute("LoopTestError"))
print(s:GetAttribute("LoopTestCartLastRide") or s:GetAttribute("CartLastRide"))
print(s:GetAttribute("CartRideTestResult"), s:GetAttribute("CartRideTestError"), s:GetAttribute("CartRideTestCartLastRide"))
```

Extra regression: pinned Lune `run prototype/cave-v2/cart-drive-check.luau`.
Existing rebuild/check commands remain in `../CAVE-V2-STUDIO-PASS.md`.

Lesson: when movement shares a deadline with wall-clock timers, consume elapsed
time and reserve shared track state at departure, because clipping delta time
lets repairs overtake an active ride.
