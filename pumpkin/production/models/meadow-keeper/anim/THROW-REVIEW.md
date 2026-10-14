# Throw mechanics: evidence and blind outcome

OWNER-REPORTED: previous throws looked unnatural. CHECKED/reused: approved project-owned geometry, rig, sampler, renderer, runtime attack clock and local Blender/ffmpeg/Lune/Rojo tools. No new third-party code/art or licence dependency. Repository PLAYBOOK.md read; exact Keystone playbook was not available through exposed tools/local copies. THROW-NOTES.md explicitly uses motion knowledge plus a read biomechanics reference; no video was watched.

## Implementation

The old seven-part rig could not show elbow, wrist or knee sequencing. It now has 16 carriers, a separate pelvis/chest chain, closed articulated sleeve/pants sections and whole boots attached to ankle joints. All non-throw world poses remain equivalent apart from 1e-5 vertex rounding and internal cut caps. Original art files were not edited. Shoulder pivots never translate away from the body.

Rear load, opposite left stride, pelvis-first turn, delayed chest/shoulder/elbow/hand action, wrist release, forward bend, rear-foot lift/drag and ease-out recovery are authored into lob/fan/legacy throw. Heavy lob uses both hands on a 5.4-stud boulder and a forward hop; fan is one-hand sidearm with pointing/pulling support arm. Release is exactly .620 in both authoritative and presentation FK. All clips finish at the existing idle pose at 1.10 seconds. Hat accents trail the body; dense keys preserve constraints, rather than translating detached arms as a smear.

Initial critic evidence scored approximately 4–6/10 and exposed a floating log, small weight transfer and weak arm chain. The renderer had inherited a scene cursor height for primitive creation. Corrected that, changed the requested heavy prop to a boulder, added ankle contacts, reversed the fan coil to put the right shoulder rearward, strengthened body transfer and moved arms clear of the head through deceleration. Reference sketches are original schematic drawings from motion knowledge, not traced footage.

## Final blind review

Two independent critics saw only THROW-NOTES and anonymized six-pose strips plus chronological 30 fps motion samples. They did not inspect recipes, source, mapping or each other's scores. They inspected still/contact sheets, not continuous GIF playback. Values are subjective visual scores, not runtime measurements.

Criterion order: weight transfer / joint ordering / attack silhouette / release-follow-through / head-hat overlap / recovery-contact.

| ID | Critic 1 criteria | Mean | Critic 2 criteria | Mean | Combined mean |
|---|---|---:|---|---:|---:|
| K | 6 / 6 / 6.5 / 5.5 / 6 / 6.5 | 6.08 | 5 / 5 / 6 / 5.5 / 4.5 / 5.5 | 5.25 | 5.67 |
| R | 6 / 6 / 6.5 / 5 / 6 / 6.5 | 6.00 | 5 / 5.5 / 6 / 5.5 / 4.5 / 5.5 | 5.33 | 5.67 |
| M | 6.5 / 6 / 7 / 6.5 / 7 / 6.5 | 6.58 | 5.5 / 5 / 5.5 / 6 / 5.5 / 6 | 5.58 | 6.08 |
| T | 6.5 / 6 / 6.5 / 6.5 / 7 / 6.5 | 6.50 | 5.5 / 5.5 / 5.5 / 6 / 5.5 / 6 | 5.67 | 6.08 |

Reveal: K = lob with stronger coil/elbow flare; R = restrained lob; M = restrained sidearm; T = stronger sidearm coil. Critic 1 picked K/M; critic 2 picked R/T, each with low confidence. **Combined means tie exactly within each pair.** Keep **R lob** for the critic's cleaner forearm silhouette and restrained coil. Keep **M fan** for its more continuous diagonal arm silhouette and tighter sampled lead-foot contact (maximum sole height .048 studs versus T .108). Both candidates pass the .12-stud offline brace tolerance. Legacy throw reuses M's mechanics. Losing recipes remain in variants-throw.json for audit, not as extra production clips.

## What still needs improvement

Both critics call the stride small and the elbow/hand whip muted. The lob prop and hands crowd the face/brim in this camera view, hiding the far hand and exact release; an unmistakable overhead extension and strong hop remain weak. Knees/feet still look block-like. Far-hand support, mesh separation and timing cannot be certified from those images. **Do not describe these scores as a convincing natural throw or owner approval.** A side-view playback and Studio playtest are the next useful evidence.

## Verification

Checked current offline sources and built package: every authored CFrame and loop seam, exact Release snapshots for all three throws, hitch/speed/cancel/completion/reentrancy, shared client/server socket and no duplicate projectile; existing attack safety/hit/deadline behavior; compiled modules and built-source parity. Geometry sampling checks 221 times/clip for flat-ground surfaces, held/head surface clearance and both-hand support; actual glove/head triangle intersection checks use 61 regular samples plus exact release, with applicable live yaw. Fan/throw retain +/-0.45rad head tracking; lob keeps committed forward gaze. Sampled glove/head intersections are zero for both variants of each attack. The regular source/frame interpolation between these samples, slopes, Studio EditableMesh rendering, multiplayer and human feel remain UNKNOWN.

R sampled lob held/head surface margin .680 studs, K .696; both hand centres match the boulder surface within floating-point tolerance. M held acorn/head surface margin 1.366 studs, T 1.412. These are offline geometric values, not guarantees across terrain. Original conservative enclosing mitten spheres falsely intersected the broad hat; replaced acceptance with actual posed triangle intersection checks, while retaining sphere diagnostics. Flight clearance resolves uncertain rotated-hat AABB cases against actual triangles.

Main pre-Rojo backup: `slice-v2/prototype/guardian-greybox.pre-throw-mechanics.rbxl`, verified SHA256 `5C29DB1017C1F56D233BC23DFB44BBC8946BAC3884A3F49E3CFEC9F39383133D`. Protected-file baseline is `protected-throw-baseline.json`; task writes exclude map-v4 and meadow binaries. No commits, uploads or security-setting changes. Requested artifacts are in the repo; Desktop is outside this session's writable root.

Final main build SHA256: `058293F0482CC29F3E2E23822B0CC170A1FDC1FF6D4F574B2A7A9B1C07B66938`. The intermediate build is preserved as `guardian-greybox.pre-throw-format.rbxl`, hash `494610BA20E066EF2EF4C970EDBDBAC1673341E5403E2E370324885987FFB5EB`, copied and verified before the final formatting rebuild. GIFs decode and the comparison was visually inspected. Protected audit compared 86 pre-existing files: nine changed externally while this task ran (eight map-v4 files and prototype/meadow-v4.rbxl). This task issued no writes to those paths and did not revert them. Concurrent external work is inferred; its author is UNKNOWN. Do not claim the whole protected folder stayed unchanged.

The retained throw harness formerly tested a hypothetical legacy high-arc cube across old Config ranges. That path is not the current Keeper kit or the isolated demo. Updated it to the demo's actual .7-stud sphere and 10*t-22*t*t / 24*t arc; current production fan/lob legal ranges and floor bands remain covered separately by keeper-clearance.luau. No production trajectory was changed to make the fixture pass.

## Lessons

1. When a rigid rig lacks elbows and wrists, add joints before polishing timing, because shoulder rotation cannot show the throwing chain.
2. When endpoint poses are grounded, also check between keys, because local rotation interpolation can sink the feet despite correct endpoint contacts.
3. When a large prop hides both hands, inspect from the side, because a frontal strip cannot prove two-hand support or a readable release.
