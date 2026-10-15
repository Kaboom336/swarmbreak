# Cave Studio pass 4: ride acceptance contract

Owner-reported Studio: SelfTest PASS; DropSampleTest PASS; LoopTest timeout.
Cart 1 traversed TrackDistance 0 to 330.4 in about 14 seconds, reached End,
then Dock, without Flight/Landing. This establishes that the pass-3 harness
required a jump for a completed intact-span ride. The virtual regression
reproduces that timeout using the backed-up harness and a completed ride.

The harness now waits for End independently of jump states, checks the same
rider/cargo throughout transit, latches arrival distance before Dock resets,
then awaits production dismount and checks the exit platform position. It also
accepts End first observed after the rider has already been dismounted.
LoopTest uses the normal intact-span route and records LoopTestCartExit before
walking the actual Humanoid to the portal and securing/opening the same geode.
It does not teleport the rider between arrival and the portal.

CartRideTest independently invokes the same blast function as the production
support prompt, waits for the gap and JUMP READY / 24, then requires Flight,
Landing, visible height, End and exit dismount. The second cart separately
requires Fall and pit recovery at 12 speed. Production Cart.server.luau and
Loop.server.luau were not changed. No assets or dependencies were added.

Byte-verified backup: `pass4-backup-20261014-215829/`, binary SHA256
`D2F09D511A9813E802D7DF899BB16B3EE6F346C5A5309D6FB7E74E48896EECC9`.
Rebuilt with the documented Rojo source bundle followed by studio-build.luau,
using the preserved pre-studio-pass baseline. No commit; Meadow untouched.

Offline checks: ride-contract-check.luau executes the actual harness with
virtual seats/time; intact arrival, late End observation, big air, slow fall,
wrong cargo/rider/exit, missing End, missing flight and pass-3 reproduction.
Existing production drive/boarding, runner and shared-core checks also pass.
Final rebuilt artifact-only check PASS: mounted source parity, scene scope,
kit bounds/query/fence joints, SelfTest, strict floor seam and policy. All 27
embedded scripts compile at O0/O1/O2; runtime Selene has zero errors/warnings.
Final cave SHA256: `96BB7D4CB84F00AFABA41DAD06A158A8CA72B2F978D2E4A8BA7C5A0DED9B9548`.
Meadow binary hashes match before/after: guardian-greybox
`0079B985B4D2F8346F9997BAEE62DDB5B52063425748412BDABB752629499732`;
meadow-v4 `CD7E5DC4475F504F84F3B92814837A7B5D577DE7293C1BC213A83A0118B1B134`.
These mocks do not establish real Humanoid physics, replication or prompt UI.
Fresh Studio suites and a manual geode carry/exit/walk remain UNKNOWN here.
The Keystone playbook remains unavailable, as recorded in PASS3-FIX.md.

Fresh Studio: open prototype/cave-v2.rbxl from disk; one fresh empty profile;
run LoopTest and CartRideTest independently, then StudioPassAll. Manually steal
the geode, use Ride cart with the intact span, confirm automatic exit dismount,
walk to the portal and open the original geode. Separately blast the support,
wait for JUMP READY / 24, board at 24 and confirm big air and exit delivery.

Three SERVER command-bar lines after the run:

```lua
local s = game.ServerScriptService; print(s:GetAttribute("StudioPassAllResult"), s:GetAttribute("LoopTestResult"), s:GetAttribute("LoopTestError"))
print(s:GetAttribute("LoopTestCartExit"), s:GetAttribute("LoopTestCartLastRide") or s:GetAttribute("CartLastRide"))
print(s:GetAttribute("CartRideTestResult"), s:GetAttribute("CartRideTestError"), s:GetAttribute("CartRideTestCartLastRide"))
```

Lesson: when an optional branch has its own suite, accept the shared terminal
contract in the loop test, because an intact track need not produce jump states.
