# Cutscenes / roadmap 15

## Cave dependency fix — 2026-10-17

Claude-reported live check: Meadow arrival, steal, escape, repeat arrival and
Custom restoration work; all nine Meadow suites pass. Cave shows no cutscene
because ReplicatedStorage.UIStyle is missing. That missing mount is also
confirmed offline in the saved pre-fix cave. Cave live behavior after this fix
remains UNKNOWN; no Studio Play was run.

`prototype/cave-v2/build.luau cutfix` patches the complete canonical cave and
creates `prototype/cave-v2.pre-cutfix.rbxl` without overwriting an existing backup.
It mounts `prototype/core/UIStyle.luau`, asserted byte-identical to Meadow's
mounted UIStyle, and the shared Cutscenes client. The regular cave cutscenes
mount and historical baseline builder now include UIStyle too. The client emits
one named warning and stops when TreasureCore, UIStyle, PlayerGui, Cutscenes,
Packages or Trove is missing. Meadow's saved place was not rebuilt.

Offline dependency audit: TreasureCutscenes is the only saved cave LocalScript
that references UIStyle. CinematicMovement does not use UIStyle; its mounted
client/module match source, and the cave fixture executes both camera clients
together through arrival, normal movement, cargo steal and reduced motion.
TreasureCoreHud and TreasureUIWorld use UIStyle in shared source but are not
mounted in this cave; adding their Meadow-specific event dependencies is outside
this fix.

Verification: all 48 cave scripts compiled at O0/O1/O2; full serialized undo
matched the input exactly. `cutscenes-check.luau` passes 48 actual-client fixture
groups, using each place's saved client and real mounted UIStyle implementation.
It asserts TreasureCutscenes ScreenGui creation in PlayerGui, real panel styling,
all six missing-dependency warnings exactly once, cave beats, and movement
composition. These service fixtures establish offline execution, not Roblox
rendering or replication timing. Existing movement, cart drive and cart boarding
checks pass. The existing cave N8 native/kit/drop checker was rerun against the
patched place: 3,024 samples, zero failures, 1,898 retained kits and 16 types.
Selene with the repository Roblox config: zero errors, warnings or parse errors.
Evidence: `CUTFIX-BUILD-cave.json`, `CUTSCENES-CONTRACT.json`,
`CUTSCENES-MOVEMENT.json`, `cutscenes-evidence/cave-treasure_cave-sections_C8_STUDIO-OFFLINE.json`.
`CUTSCENES-FINAL.json` is resealed with the cutfix build and current source hashes;
its earlier Meadow/core/origin evidence remains historical. No commit.

```powershell
$lune = 'C:/Users/zerha/.rokit/tool-storage/lune-org/lune/0.10.5/lune.exe'
& $lune run prototype/cave-v2/build.luau cutfix
& $lune run treasure/cutscenes-check.luau
& $lune run treasure/cutscenes-existing-checks.luau movement
& $lune run treasure/cutscenes-existing-checks.luau cave 8
& $lune run prototype/cave-v2/cart-drive-check.luau
& $lune run prototype/cave-v2/cart-board-check.luau
& $lune run treasure/cutscenes-seal.luau
```

Lesson: when a client needs a shared module, validate the dependency in every
saved place and execute its real bootstrap because permissive module mocks can
hide a missing mount.

Design recorded before implementation, 2026-10-17. Scope: one shared client
runner, seven authored beats in the two existing complete places. No Studio
Play, commit, publishing, account, spend or new asset dependency. Reuse local
UIStyle (Fredoka, cream/ink, gold/cyan panels), TweenService and the inspected
MIT RbxUtil Trove cleanup implementation; preserve its existing licence ledger.
Read CINEMATIC-MOVE.md, sections/LESSONS.md, CinematicMove.client, TreasureFeel,
TreasureCoreHud, UIStyle and StudioPass capture before designing this layer.

## Reference comparison and limits

| Reference | Design comparison | Our short story beat |
|---|---|---|
| [DOORS](https://www.roblox.com/games/6516141723/DOORS) | Best-in-class target here for a threat that reads without exposition. Official listing confirms horror/exploration; exact shot timings and live camera behavior UNKNOWN. | One Keeper look, then immediate return; no dialogue or pause. |
| [Piggy](https://www.roblox.com/games/4623386862/Piggy) | Story/escape framing target; official listing confirms escape/mystery. Exact current chapter cinematics UNKNOWN. | Establish destination and celebrate escape with a single readable card. |
| [Grow a Garden](https://www.roblox.com/games/126884695634066/Grow-a-Garden) | Listing describes growing, collecting and showing finds to friends. Moment-to-moment camera behavior UNKNOWN. | Keep the prized object central and readable in a muted vertical clip. |
| [Steal a Brainrot](https://www.roblox.com/games/109983668079237/Steal-a-Brainrot) | Listing confirms stealing as a core action. Live steal presentation UNKNOWN. | STOLEN! with a small player-following orbit; continue the escape immediately. |

These are design inferences, not watched-footage, tested parity or an arena win.
Claude compares this one shared slice before any extra variants. The Keystone
Roblox Process Playbook was not available through the exposed Keystone tools;
the local production skill/gates and project lessons were read. That source gap
does not authorize expanding scope or claiming a reference review happened.

## Shot list

| Beat | Duration | Existing signal | Authored camera path / card |
|---|---:|---|---|
| Meadow arrival | 3.2 s first, 2 s repeat | GreyboxPhase enters Run | Current view -> high approach to summit beam -> current player view; MEADOW. |
| Keeper wake/warn | 2 s | First visible, unobstructed Guardian with replicated KeeperClip | Brief look towards Keeper -> player view; THE KEEPER IS WATCHING. Only empty-handed, non-danger. |
| Acorn steal | 2 s | GreyboxCarry false -> true during Run | Small tracking orbit around current player view; STOLEN! Controls remain live. |
| Portal finish | 2.4 s | GreyboxMeadowEscapes increases and phase is Home; CaveSecured changes | Follow player at home portal, pull back -> player view; ESCAPED! No celebration for death, empty return or a failed secure. |
| Cave arrival | 3.2 s first, 2 s repeat | Enter PortalBeacon arrival area, no cargo | Approach -> geode vista -> player view; CRYSTAL CAVE. |
| Geode steal | 2 s | CaveItemID nil -> ID | Small tracking orbit; STOLEN! Recovery also reads this signal, but session latch prevents replay. |
| Cart blast jump (escape beat) | 2.4 s | Local rider's RideableCart State enters Flight | Gentle tracking pull-back with eased camera pacing, then return; BLAST OFF! No simulation time changes. |

Camera paths are client-authored offsets relative to the existing landmarks and
live player view. TweenService eases path progress; it never tweens a character.
All controls stay live, including steals and cart flight. Any begun input skips:
keyboard, mouse buttons/movement, touch, gamepad buttons, thumbstick movement and wheel input.
Skip is also an Activated touch-sized/selectable button. No input is consumed.
Held movement at start uses a card only; new movement skips a running shot.
Letterbox bars are thin (6%) and only appear with camera motion. Cards occupy
38%-45.5% of screen height plus a 36 px HUD inset allowance, below the shared
countdown at 26%. Skip sits 8 px below the card, clear of bottom touch controls.
The countdown and existing HUD remain running/visible.

## Safety, lifecycle and ownership

Every non-arrival beat is latched once per client session (survives respawn).
Arrival is edge-triggered on island entry and shortens after the first accepted
entry. Arrival has a 0.9 s entry-local settling window for the first grounded
frame after portal/spawn replication; it expires or clears on carry/exit/death.
Other rejected beats are not queued for a later unsafe moment. A new higher
priority payoff cancels the previous beat; stale timers cannot end its successor.

ReducedMotion or VR means title only, including a mid-shot preference change.
Other Scriptable cameras (especially StudioPass capture) are never acquired or
overwritten. Capture toggles cancel our shot before StudioPass renders. A missing
landmark falls back to the card. All waits for startup are bounded; streamed
landmarks are rediscovered. Death, respawn, character/camera replacement, loss of
focus, script destruction, skip, errors, or expiry cancel and restore owned
CameraType Custom, original FOV and current Humanoid subject. A separate 4.5 s
watchdog is independent of render frames and Tween completion. Maximum authored
duration is 3.2 s; the restoration contract is <=5 s after start when the engine
can schedule callbacks. An externally owned capture camera is outside our lease.

No ordinary arrival/warn while carrying or danger is detected. Danger is
conservative: near Keeper, active Keeper attack clip, hurt/slow/air/seated, or
Cave TNT/support telegraphs. Unsafe non-payoff requests are suppressed and an
already playing non-payoff ends immediately. Steal/escape shots use small
tracking flourishes with controls live; they add no protection. Cave cart blast
is an escape flourish, including cargo rides. Server timers, Keeper and physics
keep running. Existing shields alone apply. No new remote, input controller,
gameplay attribute write, invulnerability, WalkSpeed write or client reward.

## Build / acceptance

Back up complete places and edited files first. Mount only the new module and
LocalScript into current canonical places, via Meadow's Lune entrypoint and
cave-v2/build.luau cutscenes mode. Do not regenerate historical map baselines.
Remove only the additions and require complete serialized equality with backup;
this proves server scripts, physics, rules, saved properties and test bodies exact.
Compile every mounted script at O0/O1/O2. Execute lifecycle/trigger fixtures,
authority/write guards, session/skip/motion/camera tests and existing offline
checks for both places. Keep offline evidence separate from live acceptance.

Claude's one live check: reopen both canonical files fresh; first/repeat arrival,
spot Keeper, steal, skip with keyboard/touch/pad, secure vs empty return/death,
Cave geode, cargo cart Flight, ReducedMotion before/during, respawn, capture
conflict and sustained movement. Confirm live controls/timers and <=5 s Custom
return. Capture one muted 9:16 steal-to-escape clip. Actual framing, device feel,
frame cost and TikTok appeal remain UNKNOWN until Claude checks them.

## Implementation / review handoff

Sources: `prototype/core/Cutscenes.luau` (session policy/lifecycle) and
`prototype/core/Cutscenes.client.luau` (local camera/UI, read-only triggers).
The three-line StudioPass client change invokes a local BindableFunction before
saving the capture camera. This is synchronous presentation cleanup, not a
remote or a gameplay signal. The same camera module/client serves both places.
Landmarks are discovered every half-second to avoid recursive map scans on every
render; camera tracking and safety/identity reads remain per-frame.

Pre-edit source files and both complete inputs are in
`cutscenes-backup-20261017-123111/`. Each canonical place also has an immutable
`.pre-cutscenes.rbxl` sibling. No server source, physical map, existing test body,
shield, Keeper rule or timer changed. Full serialized restoration proves this.

```powershell
$lune = 'C:/Users/zerha/.rokit/tool-storage/lune-org/lune/0.10.5/lune.exe'
& $lune run treasure/cutscenes-meadow-build.luau
& $lune run prototype/cave-v2/build.luau cutscenes
& $lune run treasure/cutscenes-check.luau
& $lune run treasure/cutscenes-existing-checks.luau core
& $lune run treasure/cutscenes-existing-checks.luau behavior
& $lune run treasure/cutscenes-existing-checks.luau origin
& $lune run treasure/cutscenes-existing-checks.luau movement
& $lune run treasure/cutscenes-existing-checks.luau cave 8
& $lune run prototype/cave-v2/cart-drive-check.luau
& $lune run prototype/cave-v2/cart-board-check.luau
& $lune run treasure/cutscenes-seal.luau
```

Build reports: `CUTSCENES-BUILD-meadow.json`, `CUTSCENES-BUILD-cave.json`.
The contract report executes the shipped client with guarded player, Humanoid
and root writes, deterministic scheduling and actual render priorities. It tests
all seven normal and stalled-render watchdog exits, all input skip routes,
session latches, both success/phase arrival orders, short repeat arrival, missing
character startup, death/respawn/rebinding, presentation errors, camera replacement,
mid-shot reduced motion, local capture release, cargo cart flight, empty returns,
HUD slot separation, and composition with the actual CinematicMove client.
Fixture service/UI mocks do not establish Roblox rendering or replication timing.

The `movement` wrapper executes the existing actual-client fixture body verbatim.
Its old complete-place equality assumes no later client feature, so this stage's
full-place/server proof is `CUTSCENES-CONTRACT.json`. No old test assertion was
edited. The core wrapper retains the prior documented archival alias exclusion;
the Cave wrapper retains C8's source-aware historical cosmetic exceptions.
The four archival failures documented in CINEMATIC-MOVE.md were not rerun or
reclassified as passing. Evidence paths are isolated under `cutscenes-evidence/`.

Limits: arrival/warn can be suppressed by conservative danger detection; missing
streamed landmarks give a card. Cave entry means the existing portal arrival
area (there is no separate replicated island-entry phase). Recovering cargo uses
the same steal signal but cannot replay the session beat. Actual camera bearing,
device cost, fun and Claude acceptance remain UNKNOWN. No Studio Play or commit.

## Verified offline

- Both final mounts compiled every script at O0/O1/O2: Meadow 94, Cave 47.
- Full-place restoration, exact server/physics preservation and write authority
  contracts PASS. Shipped-client fixtures: 41 groups PASS, including every beat's
  normal and stalled-render <=5 s Custom restoration and actual movement composition.
- Existing shared core, Meadow behavior/reset/coordinator, nonzero/late origin,
  movement policy at 30/60/144 fps, actual movement/Feel, Cave cart drive and
  boarding checks PASS. Old assertion bodies are retained as described above.
- C8 source-aware native/kit/drop checker: N8, 3,024 samples, zero failures;
  1,898 retained kits, 16 types. It started during an earlier camera iteration;
  final server/Workspace serialization still equals the same pre-cutscenes input.
- New camera sources: Selene zero errors, warnings or parse errors.

`CUTSCENES-FINAL.json` seals final source/place hashes and the evidence paths.
These are offline results. Claude still owns the one live check and visual review.

Lessons: when capture saves a camera, release the cinematic synchronously first
because otherwise capture can restore Scriptable; when attributes replicate
separately, test both orders because valid success can arrive before its phase;
when staging a chase moment, animate only presentation because the timer and
controls must keep working.
