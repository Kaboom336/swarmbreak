# Meadow Keeper animations

## Throw mechanics revision — 2026-10-13

Current lob, fan and legacy throw use 16 articulated joints: pelvis, chest, shoulders, elbows, wrists, hips, knees, ankles, head and hat. Approved art is partitioned into closed rigid sections; the original Blender model/parts JSON and FBX are unchanged by this task. Retained non-throw clips keep their former world poses. `Rig.build` creates the articulated geometry. The historical seven-part FBX cannot support elbow mechanics: `Rig.bind` now requires articulated named visual meshes and rejects the old seven-part import before modifying it.

All three throw clips are 1.10 seconds, with the existing **0.620-second Release**. Preparation ends at .495 (~45%); action lasts .125 (~11%); follow-through/recovery lasts .480 (~44%). Baked 60 fps constrained leg/arm poses prevent the large sinking arcs produced by interpolating local joint rotations alone. The lob gathers a 5.4-stud boulder from .20, lifts with both hands, hops forward, then settles. Its exact socket puts both mitten centres on the boulder's 2.7-stud surface. The existing server collision radius, flight/impact times and hit rules remain unchanged. Fan and legacy throw use a right-hand sidearm chain with opposite left foot braced and support arm pointing then pulling in. Lob gaze stays on committed forward aim; other states retain bounded live head tracking.

Reference: [six poses and timing](THROW-NOTES.md). Proof: [lob GIF](preview/fx/lob.gif), [fan GIF](preview/fx/fan.gif), [real-motion sketch comparison](preview/THROW-compare.jpg). These are offline renders, not Studio captures. [Blind review](THROW-REVIEW.md) records two critics, their disagreement, tied means and remaining stiffness. No claim of owner acceptance or best-in-class motion.

Production modules share `Skeleton` and `Kinematics` so held props, marker snapshots and authoritative projectile spawn use the same articulated pose. Main place was backed up before Rojo. No commit, publishing, security changes, `treasure/map-v4` writes or `meadow-*.rbxl` writes. Files stay in this requested repo because Desktop is outside the writable root.

Regenerate candidates using Blender `-b -t 2 --python-exit-code 1 -P anim/render-fx.py -- --throw-variants --candidate R --only lob` (from the model folder with adjusted path). `author-throw.py` emits apply_patch; it does not mutate source. `proof-throw.ps1 -Blind` assembles candidates; default mode assembles winners and reference sketches. `anim/check-throw.py` checks actual posed triangles, floor surfaces and both-hand support. The Lune kit, Keeper, clearance and animation checks remain the offline runtime contract; Studio/device/continuous human feel are UNKNOWN.

## Current v3

Production now uses the new lob (1.52s), fan (1.32s) and slam (1.72s) clips; idle/chase are revised. Eleven total clips include the retained legacy throw. Two variants each were rendered and blind-judged; winners and polish are recorded in [REVIEW-V3.md](REVIEW-V3.md). Motion reference access limits and five takeaways are in [REFERENCE-NOTES.md](REFERENCE-NOTES.md). Gameplay design is [ATTACKS.md](../ATTACKS.md); current Studio checks are at the top of [WIRING.md](../WIRING.md).

Proof: `preview/idle.gif`, `chase.gif`, `lob.gif`, `fan.gif`, `slam.gif` and GIFs for every other clip; `preview/_sheet-v3.jpg`; `preview/_motion-v3.jpg`; `preview/ATTACK-storyboard.jpg`. New clips share the 0.620s release / 0.800s slam landing keys with authoritative gameplay. Preview flight targets are illustrative; red/amber storyboard is schematic. Studio UNTESTED, human balance UNKNOWN. Artifacts remain in the permitted repo folder because Desktop is outside the writable root.

Regenerate renders with existing Blender command plus `-- --motion`; proof/GIF/storyboard assembly uses `proof-v3.ps1`. Do not use old `sheets.ps1` for v3: it describes the historical eight-clip package below.

## Historical v1/v2 notes (superseded where v3 differs)

Owner-reported model approval; eight original, upload-free animation clips. No game wiring, map edits, uploads or commits. All authored edits used apply_patch. Generated previews/package stay in this folder because the permitted write root excludes Desktop.

## Play in Studio

1. Open an **empty local place**. Insert `MeadowKeeperAnimations.rbxmx` into Workspace using Insert from File in Explorer.
2. Press Play. The package's client-context demo builds eight copies of the approved parts JSON, one for each clip. Look at the labelled rigs; throw shows a held rock and release. No animation IDs are required.
3. Stop Play to remove the runtime demo. This package is separate from the game's maps and guardian logic.

**Studio runtime is UNTESTED here.** EditableMesh creation can fail if unavailable in the local session. The loader reports that failure; it does not change security settings or substitute block geometry. The alternative `Rig.bind` accepts the existing neutral seven-part FBX model, correctly aligned to the JSON's 11-stud, Y-up, front +Z basis. Its placement argument is the neutral ground frame, not the model bounding-box pivot. FBX names must be Torso, Arm.L, Arm.R, Leg.L, Leg.R, Head, Hat. Existing imported geometry needs no animation upload.

## Clips and state contract

| Clip | Seconds | Behavior / eventual guardian state |
|---|---:|---|
| idle | 4.8 loop | Breath, slow glance left/right; guard camp / search pause |
| patrol | 1.12 loop | Opposing feet/arms, shoulder roll; patrol |
| warn | 1.65 | Snap, point, two high fist accents, settle; thief noticed |
| chase | 0.64 loop | Lean, broad arm drive, faster boots; chase |
| throw | 1.4 | Crouch, turn/load, hold, release, cross-body recovery |
| stun | 1.55 | Recoil, alternating imbalance, diminishing hat lag, recover |
| celebrate | 1.9 | Crouch, two-arm hop, landing compression, fist accents |
| return | 1.25 loop | Slumped, annoyed trudge with hanging arm swing and backward glance |

All clips animate in place. Root movement, target facing, navigation, leading aim, collision, knock-drop, safety, leash and treasure ownership stay with gameplay. The seven rigid parts use pose compression/extension and secondary hat motion; **there is no vertex deformation or literal mesh scaling**. No fingers/elbows exist on this approved rig, so pointing uses the mitten.

## Integration example (later; not installed)

```lua
local Rig = require(folder.Rig)
local Animator = require(folder.Animator)
local rig = Rig.build(campGroundCFrame)
rig.model.Parent = workspace
local player = Animator.new(rig)
player:Play("idle")

-- Capture locked lead target at AimLock in gameplay.
player:Play("throw", {
    onMarker = function(marker, clip, time, lateness, snapshot)
        if marker == "Release" then
            -- Use snapshot.releaseCFrame.Position for the projectile origin.
            -- Gameplay launches toward its PREVIOUSLY LOCKED target.
            -- Fast-forward presentation by lateness if a frame hitched.
        end
    end,
})
```

`Marker.Event` also sends `(marker, clip, authoredTime, latenessSeconds, snapshot)`. The snapshot is calculated with forward kinematics, so deferred callbacks and physics timing cannot move the release origin. `Release` is **0.620s** at speed 1, **0.310s** at speed 2. Start `AimLock` at t=0; the GDD's proposed 1.2s lock-to-impact leaves **0.580s** for flight at speed 1. Gameplay must enforce its >=4s windup interval and safe zones; this module cannot enforce them. The visual demo's illustrative arc is not gameplay ballistic tuning.

`Play(name, {speed=1, fade=.12, loop=...})` interrupts the prior clip. Throw disables crossfade to preserve authored release alignment. `Stop(true)` resets rest pose; `Destroy()` removes the driver/events. `Completed.Event` fires once for a one-shot; loop clips do not complete. `Animator.sample(name,t)` supports scrubbing. Drive one instance per rig. For gait matching, the proposed stride is patrol 4.8, chase 8.45, return 5 studs per cycle; set speed from travelSpeed * duration / strideStuds and tune against actual terrain. These are authored starting values, not measured foot-contact distances.

The isolated demo creates geometry locally and uses a Script with RunContext Client. Production should reuse geometry per client and replicate animation state/clock; authoritative projectile decisions belong on the server. An existing replicated imported rig can use the driver's Motor6D.C0 updates from the server. This is a future integration choice, not a claim of multiplayer validation. Motor6D.Transform itself is [not replicated](https://create.roblox.com/docs/reference/engine/classes/Motor6D).

## Evidence and regeneration

`preview/_sheet.jpg` and eight named strips show the actual approved Blender mesh with the same joint hierarchy, CFrame rotation order, quaternion interpolation and easing as the module. `preview/previous/` re-renders the reviewed pre-follow-up throw/chase from `previous-clips.json`; `preview/before/` preserves the original first pass. `preview/_throw-compare.jpg` places old/new throw and chase alongside the supplied throw/title-card references. `throw.gif` and `chase.gif` show sampled continuous motion. `REVIEW.md` distinguishes the historical independent reviews from this follow-up's visual self-check.

Sources: `clips.json` is editable pose data, `Clips.luau` is its synchronized Roblox copy; `Geometry.luau` embeds the approved parts JSON. Original geometry/helpers were inspected and reused; no third-party code or assets added, no new external licence dependency. The named game bar is owner-supplied Pet Simulator / Grow a Garden; current clips from those games were **not** watched. Supplied `blender/compare.jpg` was directly inspected. Exact Keystone playbook was unavailable in exposed tools/local files; local repo PLAYBOOK.md was read without claiming it was the Keystone source.

Render: `C:/dev/codex-lab/tools/blender/blender.exe -b -t 6 -P models/meadow-keeper/anim/render.py`.
Package: run `build.py` with Python after synchronizing source modules. It packages the sources without publishing anything.
Strips: `sheets.ps1` uses System.Drawing; if local script policy blocks direct invocation, run its inspected source as a ScriptBlock without changing policy.
Offline behavior: run `verify.luau` with the actual Lune binary (the Rokit shim needs a home directory in this environment).

Official API references inspected: [Motor6D](https://create.roblox.com/docs/reference/engine/classes/Motor6D), [RunService](https://create.roblox.com/docs/reference/engine/classes/RunService), [AssetService](https://create.roblox.com/docs/reference/engine/classes/AssetService), [EditableMesh](https://create.roblox.com/docs/reference/engine/classes/EditableMesh). No settings were changed.

Remaining checks: local Studio Play, event origin vs drawn hand, client memory, continuous animation feel, movement/feet on hills, phone readability and owner acceptance. No sound, foot IK, gameplay damage or state-machine hooks are included.
# Reviewer FX v4

Current: twelve clips including dash, native runtime effects in `slice-v2/prototype/KeeperEffects.luau`, themed props in `KeeperProjectiles.luau`, and silent TODO sound objects. [FX review and sounds](FX-REVIEW.md), [storyboard](preview/ATTACK-storyboard-v2.jpg), [effect GIF directory](preview/fx).

Run Blender `-b -t 6 -P models/meadow-keeper/anim/render-fx.py` to regenerate offline PNGs; `-- --only warn` or `dash` renders one proof. `proof-fx.ps1` uses existing ffmpeg/System.Drawing to assemble GIFs, blind strips and storyboard. Authoring patch recipes are historical one-shot deltas, not scripts to repeatedly reapply to current sources. Effects proof is approximate, not Studio capture. Existing animation-only v3 GIFs/sheets below are historical; use fx/ for this review.

---
