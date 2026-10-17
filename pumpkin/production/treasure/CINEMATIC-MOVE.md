# Cinematic movement / roadmap 14

## Direct binding repair, 2026-10-17

Owner-reported live evidence: real intent 1 and horizontal speed 16 while the
client reported idle/blend 0/FOV 70. Root cause remains inferred; Studio was not
run. Every render now resolves frame-local Humanoid/root directly from
player.Character and rejects descendants outside that character. Cached
identities only trigger effect cleanup. MoveDirection and horizontal
AssemblyLinearVelocity come from those exact frame-local objects.

StudioDebug now includes CineIntent, CineSpeed and CineHum (GetFullName), also
on bypass frames. The replacement fixture gives the retired objects zero
movement and the new objects independent movement, so stale reads cannot pass.
It covers replacement after startup without events, same-character replacement,
missing/foreign roots, foreign Humanoids, late root arrival and vertical velocity.

Pre-edit files and both complete places are in
`treasure/cinematic-binding-backup-20261017-115904/`. Mounts additionally preserve
`.pre-cine-bindingfix.rbxl` next to each canonical place. Earlier backups remain.
Use the Meadow Lune pipeline and Cave build.luau cinematic mode below.

Checked this repair: both mounts compiled all scripts at O0/O1/O2 (Meadow 92,
Cave 45); complete-place/server preservation, cinematic-check, shared core,
Meadow behavior, Cave cart drive and boarding passed. Selene reports zero
errors/warnings/parse errors. Prior dense/legacy evidence was not rerun.
Studio Play and live render-priority acceptance remain UNKNOWN. No commit.

Lesson: when testing replacement bindings, give old and new objects different
inputs because inherited fixture values can hide stale reads.

## Live-path repair — 2026-10-17

Owner-reported Studio failure: Grass/Running, intent 1, speed and WalkSpeed 16,
Custom camera following the current Humanoid, FOV pinned at 70 despite a working
pure policy. Live root cause remains inferred until Claude verifies this build.
Offline reproduction: fire unchanged carry/preference notifications each frame
for 2.4 seconds. The previous actual client fails because `refresh()` calls
`reset()` unconditionally; the patched client reaches FOV 80. Meadow's server
republishes carry state from its update/publish paths. This fixture forces
notification delivery; it does not prove how often Roblox delivers those signals.

Refresh now updates labels only; effective suppression is sampled every render.
Character and Humanoid/root identity are rechecked each frame, so delayed events
or replaced descendants cannot leave the camera comparing against a stale
Humanoid. Actual-client fixtures cover notification churn, character replacement
without CharacterAdded, same-character descendant replacement, camera-subject
bypass, debug opt-in, and no debug writes outside Studio. Existing suppression,
cleanup, composition and guarded physics fixtures remain in place.

Before editing, sources, reports and both complete places were copied to
`treasure/cinematic-live-backup-20261017-115116/`. Both mount entrypoints now patch
the current complete place, saving `.pre-cine-livefix.rbxl` first; they restore
prior sources in memory and prove complete serialization equality before saving.
The original `.pre-cine.rbxl` backups remain untouched. No server speed or other
gameplay change. Studio Play was not launched; live acceptance is UNKNOWN.

Claude: in Studio's **client** command bar, set
`game.Players.LocalPlayer:SetAttribute("StudioDebug", true)`. Walk on grass for
one second: `CineBlend` should reach 1, `CineGate` should be `running`, and FOV
should reach 80; stop and blend/FOV should return to 0/70. A bypass reports its
gate (`humanoid`, `root`, `camera`, `camera-type`, `camera-subject`, `vr`,
`reduced`); policy gates include carry, blocked, dead, slow, air and idle.
Attributes are client-local and written only with StudioDebug true in Studio.
Reopen both freshly mounted canonical places before checking.

Repair verification: both source mounts compiled every script at O0/O1/O2;
cinematic-check, shared core tests, Meadow behavior, Cave cart drive and boarding
passed. Complete-place preservation also passes against the original pre-cine
baseline. Earlier dense sampling and four documented historical failures were
not rerun for this camera-only repair; final seal distinguishes that evidence.

Lesson: when pure policy passes but presentation fails, execute the actual client
under repeated notifications and changing object identities, because cached
bindings and UI callbacks can erase otherwise correct state.

Decision, before implementation: reuse TreasureFeel, its MIT RbxUtil Trove/Shake
packages and Roblox's built-in particle texture. No new dependency, uploaded
animation, remote, gameplay speed or input controller. Licence ledger inspected:
prototype/core/Packages/README.md; Trove and Shake implementation inspected.

## Reference comparison

| Reference | Evidence checked | This slice |
|---|---|---|
| [Huss Valley](https://www.roblox.com/games/107535308163741/Huss-Valley) | Owner-reported gradual run start; listing located. Exact identity/tuning and live movement UNKNOWN. | 0.75 s smoothstep presentation ramp; immediate stock movement remains responsive. |
| [Evade](https://www.roblox.com/games/9872472334/Evade) | Official listing checked; selected best-in-class chase-feel target, not a measured ranking. Live acceleration/animation values UNKNOWN. | Readable widening and grounded footfalls; no slides, momentum physics or balance changes. |
| [nico's nextbots](https://www.roblox.com/games/10118559731/nicos-nextbots) | Official listing located; live tuning UNKNOWN. | Automatic cosmetic run works with the existing thumbstick, gamepad and keyboard; no extra sprint button. |

These are side-by-side design targets, not a claim of observed parity. Claude
compares one shared implementation in both maps before any additional variants.
[Roblox Humanoid docs](https://create.roblox.com/docs/reference/engine/classes/Humanoid)
describe WalkSpeed as a maximum with analog movement below it. We only read it.

## Scope and behaviour

No existing server sprint was found. Choose stamina-free cosmetic auto-run:
after sustained ground movement, FOV eases 70 to 80 over 0.75 s, then eases back
on stopping. This is perceived acceleration through camera, not physical
acceleration: slowing the real start would change chase timing and tests.
Default avatar locomotion remains engine-owned. No animation speed is falsified.
Full analog input and actual horizontal motion are required; a wall, slow
thumbstick movement, mud, hit stun, jumping, seated cart or death cannot charge run.

GreyboxCarry and CaveItemID are the existing replicated carry signals. Either
suppresses FOV, bob, dust and landing shake; any WalkSpeed below ordinary 16 also
suppresses them. No inferred sprint entitlement and no writes to WalkSpeed,
velocity, CFrame of the character, MoveDirection, jump or gameplay attributes.

Small foot-level dust bursts use one client emitter and measured travel distance,
with a hard per-frame emission cap. Subtle camera bob/sway is optional with motion;
landing shake is light and OFF by default, including existing impact shake.
ReducedMotion disables FOV animation, bob/sway, shake and dust. A compact settings
panel exposes reduced motion and camera shake using Activated, touch-sized buttons
and gamepad selection. Preferences are session-local; no saving/economy changes.
VR and script-controlled cameras bypass movement effects. Reset/death/camera
replacement and destruction restore owned presentation and retire old emitters.

## Build and acceptance contract

The initial mount backed up complete binaries to guardian-greybox.pre-cine.rbxl
and cave-v2.pre-cine.rbxl. The repair uses current-place backups described above.
Meadow uses a source-only Lune mount;
Cave enters through prototype/cave-v2/build.luau cinematic mode. Never rebuild
the maps from historical plain Rojo or the historical Cave generator.
After removing the new movement client/module and restoring the small Feel edit,
complete serialized place equality must hold, proving every server script,
WalkSpeed value, Keeper rule, timer, carry rule, test body and map property exact.
Add executed policy/lifecycle fixtures and a client write-prohibition contract.
Run existing offline Meadow and Cave checks without weakening assertions.

Claude's one live check remains required: Meadow then Cave, keyboard/phone/pad,
start/stop/turn/wall/jump/landing, carry/drop/recover, mud/hit, cart seat, respawn,
camera replacement, settings, ReducedMotion and enabled/disabled shake. Capture
a short 9:16 start-to-run-to-landing clip. Studio visuals, device feel, frame cost
and TikTok appeal remain UNKNOWN until that check. No Studio play, commit,
publish, message, account or spend is authorized here.

## Implementation evidence and handoff

Mounted sources: `prototype/core/CinematicMove.client.luau`, pure
`CinematicMove.luau`, and the existing `Feel.luau` shake preference guard.
TreasureFeel's existing impact hookups stay intact. No uploaded animation is
required. Cave Loop currently does not assign WalkSpeed; its default locomotion
and CaveItemID cargo signal are preserved exactly. Meadow still owns walk 16,
carry 13.5, mud 8 and hit slowdowns. The client cannot write any of those.
CaveItemID remains assigned during dropped-cargo recovery, so Cave conservatively
keeps the cosmetic run disabled until that cargo session resolves. This avoids
inventing a new replicated carry state or changing the existing Loop contract.

Build commands from production root (use the pinned Lune 0.10.5 executable if
the Rokit shim cannot locate its home):

```powershell
lune run treasure/cinematic-meadow-build.luau
lune run prototype/cave-v2/build.luau cinematic
lune run treasure/cinematic-check.luau
```

Build reports: `CINEMATIC-BUILD-meadow.json`, `CINEMATIC-BUILD-cave.json`.
Executed contracts: `CINEMATIC-CONTRACT.json`; guarded Humanoid/root fixtures
throw on any write. Tests include 30/60/144 fps ramp, analog input, wall stop,
carry signals, slowdowns, seat/death, reduced motion, VR/scripted cameras,
respawn, camera replacement, Activated settings, landing via intermediate
Landed, effect composition and destruction cleanup. New client/policy lint:
zero errors/warnings. Complete neutralized place equality includes all original
tests, configuration, saving, timers, map art and every server property.

Current offline suites run through `cinematic-existing-checks.luau` preserve
their bodies/assertions and write to `cinematic-evidence/`. The legacy 50-seed
test exercises Layout, not live MeadowV4 timing; the separate three-shard N8
sampler exercises the mounted Meadow map. Cave uses its accepted C8 source-aware
checker, including its historical explicit cosmetic exceptions, at N8.

Four historical checks are **not green**: core-check's obsolete place-alias
equality, kit-check's missing hit-instance fixture, home-art-check's pre-art
GreyboxTraps comparison, and home-round3-check's old warm-lighting values.
`cinematic-legacy-check.luau` reproduces these against backup and final unchanged;
`CINEMATIC-LEGACY-FAILURES.json` records the exact failures. Shared core domain
tests run verbatim before the obsolete archival tail; current full-place
preservation is independently proved by the new contract. No historical test
assertion is edited or represented as passing.

`CINEMATIC-FINAL.json`, when present, seals final hashes and measured dense
sample totals. Sampling can overlap client-only camera iterations: all sampled
server, test and physical map inputs remain exactly the same. Offline checks
do not establish camera quality, mobile frame cost or TikTok appeal.

Claude: open each canonical fresh, use Motion settings at upper right. Verify
default shake OFF; toggle shake ON for landings, then Reduced motion ON to stop
all added motion. Walk normally for one second, stop into a wall, use a partial
thumbstick, jump/land, carry/drop/recover, enter mud/get hit, sit in Cave cart,
respawn and change camera. FOV should remain 70 while carrying/slowed/seated;
at ordinary running it reaches 80 in .75 s. Run existing live suites separately;
none were run by Codex. Do not overwrite canonical from a running session.

Lessons: when preserving balance, ramp camera presentation because physical
acceleration changes chase timing; when stacking effects, test restore order
because offsets can accumulate; when detecting landings, retain Landed state
because Freefall may not transition directly to Running.
