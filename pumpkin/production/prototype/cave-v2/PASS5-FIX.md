# Cave Studio pass 5: confirmed boarding before departure

Owner-reported after cave-fix4: SelfTest and DropSampleTest PASS; LoopTest
failed at `timeout: seat occupant`. Cart 1 transitioned to Track with no
Occupant or SeatWeld in the retained samples. This is live failure evidence;
the exact engine scheduling that produced it is UNKNOWN.

Inspected defects: Dock accepted any Occupant without checking a rider weld
or a successful board request. The board action also returned true for any
already occupied seat without confirming its weld, while the harness assumed
DriverSeat. Touch seating was enabled. A passenger-seat race is an inference,
not a proven diagnosis of the reported Studio run.

The production prompt and Studio adapter still share boardPlayer. Departure
now requires a completed request, the same live Humanoid in Occupant/SeatPart,
and an engine Weld whose Part0 is the seat and Part1 belongs to that character.
Pending requests block the countdown; attachment is rechecked every Dock step.
Occupant changes revoke confirmation. Touch seating is disabled, and reset
invalidates in-flight boarding requests and clears confirmations.

Cargo is allowed. Boarding unanchors character parts, clears PlatformStand,
enables the Seated state, requests GettingUp, enables the selected seat, stops
movement/jumping and places the root two studs above the seat before Sit.
Once Occupant appears, retries stop moving the root or calling Sit while the
engine finishes attachment. Explicit Ragdoll/Ragdolled/Stunned/Mercy attributes
on player/character/Humanoid cause a clear wait prompt rather than being erased.
The cave has no authored combat stun/mercy controller to override.

`CartLastRide.boarding` records rider, cargo ID, attempt count, timestamps,
success/reason, returned seat, Occupant match, rider-weld validation, Humanoid
state, PlatformStand, root anchoring, Seated enabled, seat Disabled and range.
Refusals also set `CaveBoardingReason` and the Ride cart prompt text. Timeout
records distinguish attachment failures through the Occupant/weld fields.

LoopTest and CartRideTest call one boardCart helper, which invokes the exact
production action and uses its returned seat. BoardingTest uses that helper
without cargo and after a real geode steal/drop/walk/recovery. Each case first
waits on the touched seat without a request and rejects departure; it then
requires attachment to persist through Track departure and retains its trace.
StudioPassAll order: SelfTest, DropSampleTest, BoardingTest, LoopTest,
CartRideTest, BlastPolicyTest. BoardingTest has the same reset/snapshot/watchdog
cleanup as the other cart suites and leaves the cargo fixture pristine.

Byte-verified backup: `pass5-backup-20261014-221007/` (place and edited sources).
Backup cave SHA256: `96BB7D4CB84F00AFABA41DAD06A158A8CA72B2F978D2E4A8BA7C5A0DED9B9548`.
Rebuilt using the documented pinned Rojo source bundle, then studio-build.luau
against the preserved pre-studio-pass baseline. No new assets/dependencies.
All source edits used apply_patch; no commit or publish.

Checked offline: production boarding helpers, cargo acceptance, cooldown,
avatar readiness, Occupant-only/missing/wrong weld, touch-only/pending/lost
rider, refusal diagnostics; actual Heartbeat refuses empty/missing-weld/pending
departure; fast jump, slow fall, intact route and reset/error persistence;
runner PASS/FAIL/watchdog and all three cart-suite cleanup; ride acceptance
and shared core/drop-joint regressions. All pass with virtual seats/time.
The final mounted-place check passes source parity, scene scope, kit bounds,
query/fence joints, SelfTest, strict floor seam and policy. All 27 embedded
scripts compile O0/O1/O2. Edited runtime Selene: zero errors/warnings.
Drop resolver and scene did not change; no new dense drop sweep was required.

Final cave SHA256: `B5ED4B9E9F26547EB45F165DC28CEDD0A55E8CF13555EB89C09B2C5F940E80A5`.
Protected places match their hashes taken before this pass: guardian-greybox
`FB8308C4AB4CD75C822F4ABFD3E739F15B1E03BF8D0D07A0F5BE6415A83175F3`;
meadow-v4 `CD7E5DC4475F504F84F3B92814837A7B5D577DE7293C1BC213A83A0118B1B134`.
Meadow was untouched. No live Studio, replication or prompt UI PASS is claimed.
Claude should reopen prototype/cave-v2.rbxl from disk in fresh Play with one
empty profile and set ServerScriptService.StudioPassAll to true.

Three SERVER command-bar print lines after the run:

```lua
local s = game.ServerScriptService; print(s:GetAttribute("StudioPassAllResult"), s:GetAttribute("BoardingTestResult"), s:GetAttribute("BoardingTestError"), s:GetAttribute("BoardingTestCartLastRide"))
print(s:GetAttribute("LoopTestResult"), s:GetAttribute("LoopTestError"), s:GetAttribute("LoopTestCartLastRide") or s:GetAttribute("CartLastRide"))
print(s:GetAttribute("CartRideTestResult"), s:GetAttribute("CartRideTestError"), s:GetAttribute("CartRideTestCartLastRide"))
```

Engine contract checked against the [Roblox Seat reference](https://create.roblox.com/docs/reference/engine/classes/Seat).
The exact Keystone Roblox Process Playbook remains unavailable as recorded
in the existing cave handoff; the local Roblox production skill was read.
No art or best-in-class visual comparison is claimed for this runtime fix.

Lesson: when boarding is asynchronous, require the same rider's Occupant and
weld at departure, because a successful request or transient Occupant can
precede a stable attachment.
