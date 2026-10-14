# Keeper library retarget review — 2026-10-13

## Reviewer correction — current selection

Selected: **old hand-keyed chase with dense sole correction; revised library hybrid lob; unchanged library slam; existing hand-keyed fan/throw**.
The earlier blind vote below is historical and was overruled by the owner's chase feedback.

CHECKED: restored chase retains the old timing and limb motion, resampled into 81 linear keys with a small root lift. The rejected Sprint_Loop remains visible as the unselected comparison row.
Lob retains the CC0 gather/hybrid structure, widens the grip, steps the left leg forward, translates the pelvis forward 0.65 studs at peak, adds 18 degrees of chest lean, and accelerates the hands forward over .585–.620s. Release remains .620s; slam Land remains .800s. These are authored targets, not measured live gameplay displacement.

Fan uses the existing local HomeArt Acorn mesh, normalized from 3 studs to **1.5 studs tall**. Its native trail now attaches to the spinning visible mesh rather than the hidden authoritative carrier. The offline fixture uses the same mesh and a schematic gold spin trail. Mesh availability and actual native trail appearance in Studio remain UNKNOWN.

### In-between audit and honest limits

`selected-check.json`: every baked key, interval midpoint and regular 120 Hz samples; runtime easing and quaternion interpolation. Chase minimum sole Y **0.01897**, lob **0.01500**, fan **0.00000**, unchanged slam **-0.00629 studs** (within the existing .04-stud tolerance). Held-log/head/hat triangle contacts: **zero sampled contacts**. A negative vertical bounding-box margin at release is possible because the log is forward of the hat; triangle geometry, rather than vertical boxes alone, was checked.

`overlap-check.json`: 78 chase, 133 lob, 133 fan and 208 slam regular samples, checking non-adjacent forearms/hands/knees/boots against torso/head/hat triangles. Contact reports remain: chase **22**, lob **217**, fan **454**, slam **849** pair/sample flags. These are collision flags, not unique defects or perceptual scores. The wide lob grip reduced its flags from **448 to 217**. Chase flags are boots versus the long torso/apron; lob still has forearm/head/hat contacts; retained fan/slam have inherited contacts. **This revision is not certified overlap-free.** No terrain or live aim check is implied.

Every selected 24 fps rendered frame is exposed in `preview/mocap/*-all-frames.jpg`; all 20 chase, 27 lob, 27 fan and 42 slam frames were visually inspected in those chronological sheets. Selected GIFs and OLD-VS-LIBRARY.jpg are refreshed and decoded by ffmpeg. Offline visuals are the evidence; Studio, phone readability and human acceptance remain UNKNOWN. Selene also reports zero errors/warnings for the changed runtime sources.

Current self-review scores, subjective /10: **chase 7, lob 6, slam 7, fan 6**. Chase is visibly upright and readable again. Lob has more forward force but the large prop obscures the lift and limb contacts remain. Slam remains the owner's preferred library clip. Acorn identity improves, but the small projectile still needs a live game-camera check. Aspirational bar remains Vesteria Ethera / World // Zero; no fresh reference footage or independent rescore was obtained, so these numbers do not claim parity.

CHECKED: real driver CFrame parity/loop seams/timing/cancel/completion, XML module parity, real Arena shared .620 release and three-acorn spawn, built guardian module parity, real attack-kit contracts, StyLua. Place backups `guardian-greybox.pre-reviewer-anims-20261013.rbxl` and `guardian-greybox.pre-reviewer-wide-grip-20261013.rbxl` precede the respective Rojo builds. No commit or protected map/place writes. Artifacts remain in the requested repository because Desktop is outside the writable roots.

Lessons: When restoring a known winner, check interpolation too, because the old chase still sank between poses. When judging projectile identity, render the runtime mesh, because the old fixture showed a dark rock despite mesh-based runtime code. When a contact check passes for the prop, also check limbs, because log clearance does not prove arm clearance.

## Historical library selection review

Previously selected: **library-derived lob, slam and chase; existing hand-keyed fan/throw**.
Library idle, patrol, return, hit-react and dance substitute are also installed.
Warning and dash keep their existing authored tells; library candidates are provided separately.
No commit, publish, account, payment, map-v4 edit or meadow place-file write.

## Checked source and reuse

Owner-reported download: Quaternius Universal Animation Library Standard, already local.
CHECKED: local License.txt says CC0 1.0; copied unchanged to LICENSE-QUATERNIUS.txt.
The [official pack page](https://quaternius.com/packs/universalanimationlibrary.html) also states CC0.
Only the non-root-motion Unreal-Godot/UAL1_Standard.glb was imported, through our Blender script outside the vendor folder.
No vendor script ran and no vendor data was changed. FBX and _RM variants were not needed.
Inventory: **43 actions**, recorded in inventory.json. Recording method is UNKNOWN:
these are library-derived animations, not verified optical motion capture.
The exact Keystone playbook was unavailable locally; pumpkin-loop/PLAYBOOK.md and the Roblox production skill were read.

## Selection and real gaps

| Keeper clip | Standard source / selected recipe | Gap or adaptation |
|---|---|---|
| lob | PickUp_Table lower-body gather + authored overhead upper body and two-hand IK | **No heavy throw**. This is a hybrid, not a captured heave. Torso and head constraints are authored for the large hat/log. |
| fan / legacy throw | Existing hand-keyed winner; Spell_Simple_Shoot candidate retained | **No one-hand throw**. Spell extension is an imperfect substitute and lost both critics' votes. |
| slam | Jump_Start + Jump_Loop + Jump_Land | Jump clips exist; boss landing height/compression and exact impact are authored. |
| chase | Sprint_Loop | Larger rotations, existing game cycle duration, root envelope correction. |
| idle | Idle_Loop | Rescaled to existing idle duration. |
| stun | Hit_Head | Short hit reaction adapted to existing stun duration and recovery. |
| celebrate | Dance_Loop | **No cheer**. Dance is the free substitute; owner acceptance UNKNOWN. |
| patrol / return | Walk_Loop / Walk_Formal_Loop | In-place; navigation owns displacement. |
| warn candidate | Spell_Simple_Enter | Spell gather, not a warning. Existing warning retained. |
| dash candidate | Crouch_Fwd_Loop + Sprint_Loop | No special boss charge. Existing .500 tell and dash retained. |

Pro was not bought. A missing clip was never labelled as present.

## Retarget and timing

Keep the seven original visual groups and existing 16-joint articulated driver, rather than removing its elbows/knees.
Map pelvis, accumulated chest, head, upper/lower arms, hands, thighs/calves/feet; fingers are omitted on mittens.
Source-left +X and source-front -Y map to Keeper-left -X and front +Z; rotations are conjugated across the reflected basis.
Absolute limb directions are solved into the Keeper's local hierarchy. Rotations are enlarged approximately 20%; authored attack constraints then override unsuitable library upper-body poses.
Hat response follows body rotation with delayed sine accents; lob counter-tilts the hat during a deep head tuck.
Bake existing XYZ-degree/translation keyframe data and quaternion interpolation. Baseline snapshot: hand-keyed.json.

Throw **Release stays .620s**; slam **Land stays .800s**; dash tell remains **.500s**.
The spell surrogate's furthest forward hand extension is measured and retimed to .620; it is not falsely described as a real throwing release.
The hybrid lob's authored overhead release and actual shared socket occur at .620.
Selected fan keeps its original real .620 release frame. Server spawn, client pose and FX deadlines remain shared.

The runtime boulder contradicted the older log notes. It is now an **8x6x6 cylindrical log with cut ends**,
matching the render. Both hands support its circular underside; the socket moves from forward support into overhead support as the hands rise.
Existing authoritative 8-stud collision sphere and 8-stud splash radius remain.

## Independent blind review

Two independent critic agents saw only anonymous chronological sheets/strips, no code, mapping or prior scores.
Named aspirational bar: **Vesteria Ethera / World // Zero bosses**.
The [official Ethera database](https://db.playvesteria.com/monsters/ethera) was read for encounter context;
current reference footage was not viewed. **No visual parity or best-in-class claim.**
Critic 1 originally scored six categories, critic 2 gave holistic scores. The means below are subjective summaries, not measured performance.

| Clip | Anonymous candidates | Critic 1 winner score | Critic 2 winner score | Summary /10 | Selected |
|---|---|---:|---:|---:|---|
| lob | A library hybrid / B old | 6.0 revised | 7.5 revised | **6.8** | A |
| fan | C old / D spell-derived | 6.0 | 6.0 | **6.0** | C |
| slam | E library / F old | 6.67 | 8.0 | **7.3** | E |
| chase | G old / H library | 6.83 | 7.0 | **6.9** | H |
| four-clip mean | same chosen candidates | — | — | **6.8** | subjective |

Both critics agreed on all four choices. Revised lob was independently rejudged after the lift-path correction.
Remaining visible gaps: weak forward lob release; gather hands obscured; fan extension/spread poorly represented by the close pose fixture;
slam striking hands could read better; chase may look like a low shuffle in playback.
Tiny later sole-envelope corrections were not independently rescored. Supporting clips were self-inspected, not independently compared.

## Artifacts and verification

- preview/mocap/OLD-VS-LIBRARY.jpg: matched, labelled old/library rows for all four attacks/moves, selected winners marked.
- preview/mocap/lob.gif, fan.gif, slam.gif, chase.gif: selected winners; anonymous candidate GIFs remain alongside them.
- Supporting selected GIFs and separate warn/dash library candidates are in the same folder.
- clips.json / Clips.luau, MeadowKeeperAnimations.rbxmx and slice-v2/prototype/guardian-greybox.rbxl contain the selected data.
- guardian-greybox.pre-quaternius-20261013.rbxl preserves the pre-task place; a second pre-quaternius-contact backup precedes the final contact rebuild.

CHECKED: real animation driver CFrame/data parity, seams, marker/hitch/speed/cancel/completion/transition; Studio XML module parity;
real Arena .620 spawn/shared socket, three acorns, accepted-hit/mercy/reset/state mapping;
real attack kit selection/cooldown/splash/sweeps/cover/jumpable rim/cleanup and dash .5 tell/wall stop/full stun.
Rojo rebuilt only the guardian place after backup. Matched stills were inspected and selected/candidate GIFs decoded with local ffmpeg.
Selene and StyLua checks passed for changed runtime socket/prop sources. Content's existing engine-global use has a line-scoped offline-stdlib annotation.

Geometry check uses actual cylindrical log and actual posed head/hat triangles at baked keys and interval midpoints.
Selected lob has **zero sampled held-log/head/hat triangle contacts**. Fully-overhead vertical margins are about
**.262 studs at .550s** and **.225 studs at .620s**. Selected lob/fan/slam/chase soles stay on/above flat ground at the checked samples (floating-point tolerance).
Quarter/midpoint root envelope correction prevents the boot dips found in the first proportional bake.
These checks do not prove continuous collision freedom on every terrain or with live head aim.
Existing warning/dash have inherited below-floor sole samples (about 1.04 / .90 studs in this fixture); those authored clips are retained and explicitly not certified for contact.

UNKNOWN: Studio playback, live log spin/contact, particles/audio/camera shake, phone readability, multiplayer, terrain, human hit rates, owner acceptance and reference-game parity.
The previews are pose/prop fixtures, not native Roblox FX or playable footage. Release still lacks convincing forward force.

## Reproduce

Use the local Blender binary for inspect.py, retarget.py, render.py and check.py; bundled Python for sheets.py, select.py and deliver.py.
retarget.py preserves the first hand-keyed snapshot. select.py emits apply_patch source changes; it never writes source files directly.
Render main pairs with --motion; extras with --extras --motion, or --selected --extras --motion.
Never save over the approved .blend or import/execute code from the vendor pack.

## Lessons

1. When a retarget uses different limb lengths, check between keys and correct the sole envelope, because grounded endpoints can interpolate below the floor.
2. When a heavy prop must go overhead, solve both hands and its actual cross-section together, because a forward sphere socket can cut through the hat.
3. When the free pack lacks an attack, compare the substitute blindly against the authored clip, because imported motion can be worse for gameplay readability.
