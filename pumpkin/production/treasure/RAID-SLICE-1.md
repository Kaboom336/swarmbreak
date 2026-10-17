# Island Raid slice 1 — S2 surface fork

Built for the owner's 2026-10-17 approval of arena D. Open
`slice-v2/prototype/guardian-greybox.rbxl`; the original is backed up as
`guardian-greybox.pre-raid1.rbxl` beside it. No Studio play or commit by Codex.
Final offline results and the exact place hash are sealed in `RAID-FINAL.json`.
Live play, visual quality, real device feel and fun remain **UNKNOWN** until Claude's check.

## What was built

One fork on the existing S2 west **surface** path, two seven-part Sprout Runners,
and one marked low wall. The initial mouth-side placement was rejected: floor
rays returned ground underneath solid hill earth. Native convex body sweeps
selected the clear surface pocket farther along S2 instead. No hill, tunnel,
bait cover, existing route floor or policy geometry was cut or moved.

Coordinates below are **island-local native XYZ**, added once to arena origin
`(0,76,-360)`. Do not apply `Arena.position`'s configuration-Z flip to them.

- Lane 1: `(-88,0,48)` to `(-98,0,48)`.
- Lane 2: `(-88,0,58)` to `(-98,0,58)`.
- Approach: near `(-94,0,40)`. Connecting path marks make the fork visible.
- Wall: centre `(-98,1.12,53)`, size `2.8 × 2 × 1`; base meets the measured
  authored floor at approximately Y `0.12`.
- Walking switch: `(-98,0,48) → (-92,0,48) → (-92,0,58) → (-98,0,58)`.
  The original west walking route remains available beside the wall.

After a completed steal, approaching the fork can deploy exactly one pair for
that cargo ID. Deployment waits for the Guardian's current attack, stun/recovery,
bell and tunnel reservations. The Guardian visibly commands, the chosen lane's
ground chevrons light, and a local chirp sounds. One runner commits to lane 1,
charges without retargeting, pauses and withdraws; the second does the same for
lane 2. This finite deployment trades against Guardian attacks. Bells wait for
the reservation to finish. Entering a tunnel/intercept cancels the surface squad
for safety; it cannot redeploy on the same dropped/recovered or handed-off cargo.

Runners are anchored, noncolliding, nonquery cosmetic creatures with server
swept lane hit checks. Accepted hits call the existing production Guardian
hit function: reachable knock/drop, the same cargo/deadline and shared mercy.
Players have no minion attack action or minion HP. Reset, retirement, cargo
completion/expiry and the bounded deployment lifetime destroy the whole squad
and clear its tells. The pair never wanders or uses a navmesh.

The client acknowledges a commitment only after its persistent squad, ground
marker and loaded sound are present. Server damage eligibility requires another
complete 1.2 seconds after that client's acknowledgement. A late or unloaded
client cannot receive an unseen charge hit. Muting SFX keeps the visual warning.

## How to play

1. Claude reopens the freshly built canonical place and starts one isolated
   Studio session. Enter normally, complete the existing 2-second Steal, then
   take the west surface route. Keep the existing 60-second cargo deadline.
2. Near local `(-94,0,40)`, read the Guardian command and lit lane. Switch to
   the other lane, or cut back through the walking connection. There is no
   requirement to wait for either runner before returning to cyan.
3. For the shortcut, stand near `(-98,3.12,49)`, move toward +Z and press the
   normal Jump control. The marked wall is at Z 53; land near Z 57. Reverse
   approach works with -Z. Keyboard, native touch Jump and gamepad Jump share
   the same request path; no new button is added.
4. Walk without Jump to compare the bypass. Jump elsewhere remains normal
   Jump. Forward movement alone never requests a vault.

The server checks phase, proximity, forward intent, cooldown, living character,
floor, landing footprint, headroom and the complete arc. It moves the player
over the marked wall in bounded steps, with the ordinary body checks and no
new immunity. A hit, cargo change, character change or new obstruction cancels
the vault and returns network ownership. Only the marked wall is excluded
from its collision sweep; other walls and ceilings remain blockers.

## Tuning

| Value | Current setting |
|---|---|
| Runners | 2 maximum; one deployment per stolen cargo ID |
| Tell / minimum complete client warning | 1.5 s / 1.2 s |
| Lane length / charge | 10 studs / 0.45 s |
| Recovery / gap between runners | 1 s / 0.3 s |
| Hard deployment lifetime | 18 s |
| Swept hit radius | 2.6 studs; lanes are 10 studs apart |
| Mercy | Existing 3 s; army also waits 0.5 s beyond mercy before eligibility |
| Vault / cooldown | 0.38 s / 1 s |
| Vault displacement / arc | At most 8 studs along Z; 3-stud arc lift |
| Vault approach | Within 0.9 stud of wall centre X; 1.3–4.5 studs from its Z |
| Forward intent | Dot product at least 0.65 toward the opposite side |
| Walking switch length | 22 studs; vault is faster at existing walk/carry speeds |

These are implemented tuning values, **not measured balance or performance**.
There is no full-map expansion, physical sprint, slide, new economy or Cave change.

## Offline checks and live suite

- `raid-build.luau`: Lune overlay of the complete current place; all 101 sources
  compile at O0/O1/O2. Undoing the mounts restores the previous serialization
  exactly. Saved Workspace and original suite bodies are preserved. Runtime
  Builder deliberately adds the fork marks and single low wall.
- Existing policy, persistence/replay, coordinator, reset, origin/late-kit,
  failed-section and 50-seed checks are retained. Historical harness adapters
  extend only the tenth-suite roster and missing fixture capabilities, without
  removing assertions. See `raid-existing-checks.luau` and the final seal.
- Fresh complete N8 DropSample workers use frozen place bytes and preserve the
  existing lattice, thresholds and production resolver. The final seal proves
  the complete saved input equals the delivered place after neutralizing only
  the final client visibility guard's Source, which the resolver does not execute.
  It verifies 31,824 samples across 20 routes and exact-once coverage.
- `raid-contracts.luau fresh` rebuilds the mounted map and executes the actual
  raid lifecycle, tell, hit/miss, mercy, reservation and vault policy.
- `raid-vault-check.luau` executes the actual mounted server request and movement
  functions against native convex collision proxies, including body volumes,
  floor contact, landing, obstruction/hit cancellation and ownership cleanup.
  This is explicitly an offline collision proxy, not Roblox engine proof.
- `raid-client-check.luau` executes the actual client with deterministic native
  JumpRequest fixtures for keyboard/touch/gamepad, cue readiness and cleanup.
  Real hardware and audio output remain untested.

`RaidSliceTest` is the new tenth live suite in `StudioPassAll`. It uses production
Steal, hit/drop and vault functions on the live map. It checks tell ≥1.2 s,
single commitment, other-lane carrier miss, committed-lane knock/drop, original
ID/deadline, shared mercy, Jump/location restrictions, walking clearance,
vault landing/time advantage and despawn. The original nine suite implementations
remain intact; **their new live results and RaidSliceTest are UNKNOWN**.

Claude, in a fresh one-player isolated-store session, uses the server command bar:

```luau
game:GetService("ServerScriptService"):SetAttribute("StudioPassAll", true)
```

Read `StudioPassResult` and all ten per-suite results. Standalone fresh-session
entry is the `RaidSliceTest` attribute. The existing harness rejects real stores,
nonempty profiles and extra clients. Codex did not launch this check.

## What to judge before making more

| Arena's named reference bar | This one slice | Still to judge live |
|---|---|---|
| Steal an Egg: owner-reported immediate wake/run clarity | Guardian command, one lit lane, one escape decision | Can Zion identify the threatened lane in a muted phone clip? |
| Evade: arena-selected movement bar | A deliberate Jump shortcut plus ordinary walking | Is the vault useful and reliable on touch/controller? |
| Outsmart identity | Bait/route choice, finite commitments and shared mercy | Harder but fair, with no unavoidable overlap or waiting? |

These are design comparisons from `RAID-ARENA.md`, not new footage or parity
claims. Claude should compare walking-only and vault-enabled attempts, a wrong
lane hit and late visibility. Check real Jump input, sound/mute, return, drop
recovery, reset, and that the sprout silhouette reads at chase distance. Record
the actual ten-suite result and one representative clip. Zion judges this
moment before any larger island or additional army.

Implementation reuses existing game source, native parts, the existing native
bell chirp and shared SFX preferences. No external model/code/asset was imported.
Existing MIT/Apache dependency notices and CC0 kit licences are unchanged.
Native input/streaming references: [JumpRequest](https://create.roblox.com/docs/reference/engine/classes/UserInputService#JumpRequest)
and [model streaming](https://create.roblox.com/docs/reference/engine/enums/ModelStreamingMode).
The exact Keystone Roblox Process Playbook was unavailable in callable tools
and the checked local active-work files; supplied arena rules and section lessons
were applied. No independent live critic or owner acceptance is claimed.

## Lessons

1. When ground can sit inside a hill, check occupied body volumes and swept
   headroom, because a downward ray can hit a floor underneath solid earth.
2. When adding a timed lane threat, gate hits on each client's complete warning,
   because a server tell alone does not establish what a late client saw.
3. When a shortcut changes character ownership, cancel it on shared hit/cargo
   state changes and restore ownership, because a movement tween must not erase Bump.
