# Meadow Keeper wiring — 2026-10-13

## Current attack/animation v3 — supersedes historical timing below

Owner feedback is OWNER-REPORTED: animations weak, small rock too easy to dodge. [ATTACKS.md](ATTACKS.md) was written before implementing the kit. Approved geometry, rig, sampler and renderer were inspected/reused; no new third-party assets/code or licensing dependency. Reference playback failed (DevForum verification/direct media network restriction); [anim/REFERENCE-NOTES.md](anim/REFERENCE-NOTES.md) records the fallback and five concrete principles without claiming watched footage. Exact Keystone playbook remains unavailable; repository PLAYBOOK.md was read.

Production Keeper now selects **lob / fan / slam** through `slice-v2/prototype/KeeperAttacks.luau`, mounted as `MeadowKeeper.Attacks`. Tuning lives in `Kit.Tuning`; Arena selects by distance, grouping and elevation, locks clamped velocity lead, preserves the existing hitPlayer knock/drop/mercy/shield callback and pursuit leash. Close slam range is 12 studs; fan covers three ±16° lanes; lob has a 4-stud projectile and 8-stud group splash. Shared start interval 5.5s; per-kind cooldowns 9/8/10s. Optional dash omitted.

Lob: authored release 0.620s, impact 1.520s; fixed red ring visible throughout windup/flight (more than 0.6s). Fan: release 0.620s, 0.700s flight; same socket-derived ground lanes as projectile rays, individually cover-blocked acorns with caps. Fan is restricted to target/landing floor within 1.5 studs of the Keeper's floor; raised targets use lob, predictions over hills defer. Ranged predicted landing distance must be >=12 studs; closer predictions defer to pursuit/slam selection. Slam: crouch/jump/0.800s Land, expanding amber rim at 24 studs/s to 22 studs; feet >2.5 studs above compatible floor avoid it. Static max-radius tell remains faint behind the moving wave. Each attack can call hitPlayer at most once per victim. Reset removes tells/props and pending release.

Eleven animation clips now include revised idle/chase and new lob/fan/slam; legacy throw is retained for historical/package compatibility, **unused by the production Keeper**. Both variants per required motion were blind-judged before selecting winners, then polished. Independent final subjective scores: idle 7, chase 7, lob 7, fan 7, slam 8 /10; static gameplay 8/10. [anim/REVIEW-V3.md](anim/REVIEW-V3.md) records IDs, changes and limits. Strong landing compression and outward/low releases are checked in actual-mesh rendered poses; live head yaw is bounded ±0.45rad. Rigid poses supply a smear surrogate, not vertex deformation.

Proof: [v3 sheet](anim/preview/_sheet-v3.jpg), [ordered motion samples](anim/preview/_motion-v3.jpg), [attack storyboard](anim/preview/ATTACK-storyboard.jpg), and `anim/preview/<clip>.gif` for all eleven clips. Storyboard tells are schematic, not Studio screenshots. GIFs use generated motion samples; critics inspected stills, not GIF playback.

Backup **before any task rebuild**: `slice-v2/prototype/guardian-greybox.pre-attack-v3.rbxl`, SHA256 `76BB58658A3E2BDB93B80B1EC865756372245A5F02D2ED1796FC8D4E1CD7ED78`, verified equal to the previous main binary. Authored source/document changes used apply_patch; binary backup uses Copy-Item with overwrite refusal; Rojo/Blender/ffmpeg generate binary artifacts. No commits. Desktop unavailable under the writable-root restriction; deliverables remain at these clear repo paths. `treasure/map-v4` and all `meadow-*.rbxl` are protected and hash-compared.

Offline checks: `kit-check.luau` executes the real kit with mocked floor/sight/physics, covering selection/cooldown, no early/duplicate release, group splash, swept fan/hitch hits, floor-vs-cover landing, jumping the rim, once/victim, shield refusal, safety/sight at impact and cleanup. It also checks straight-running carriers at actual Config.CarrySpeed and early reversal at 20Hz; these are scalar fixtures, **not human playtests**. `keeper-check.luau` executes real Arena/Pose integration with three acorns from the .620 socket, fan deadline, celebration/refusal/reset/state mapping and built-source parity. `keeper-clearance.luau` samples new pose and legal flight envelopes including the acorn cap; `anim/verify.luau` checks eleven authored clips, loop seams, driver markers/hitches/cancel/reentrancy and isolated package parity. Existing check.luau covers legacy map/ownership/deadline/navigation/route regressions with mocks. Selene, StyLua and git diff whitespace checks accompany these checks. Studio and human balance remain NOT RUN/UNKNOWN.

Final rebuilt greybox SHA256: `D8BD3415E88B553B7217B4D5CD93105222DE22F10A2A69DF9DAF0F1216725758`. CHECKED: all eleven GIFs decode; all new runtime source parity and regression checks pass. Main regression suite uses mocked physics/navigation; its old rock fixtures exercise the legacy non-Keeper path, while kit/keeper checks exercise the new production Keeper path.

Protected-file audit: **this task issued no writes to `treasure/map-v4` or any `meadow-*.rbxl`**. Four original meadow binary hashes still equal baseline. Nine of the ten original map-v4 file hashes still match; `collision-audit.json` changed from `5C0EB43D312E8CF95C1C52ADE0C73CCE3A057BDEBD8A524FEA2F2EC6D3F47D14` to `E9DCF3FC9AA44AD44A1548AFE5E5B463EED1BBE4015DCC4C4200A02AFCD78795`, and new map-v4 build/render files plus `prototype/meadow-v4.rbxl` appeared while this task ran. **Concurrent external work is inferred; its author is UNKNOWN.** Those files were neither edited nor reverted by this task. Do not describe the whole protected folder as unchanged.

Balance target **ESTIMATE**: unskilled solo ~2 accepted hits per 60s escape, skilled 0–1. Actual hit rates, win rates, mobile readability, performance and owner acceptance are UNKNOWN. Do not treat an offline score as acceptance.

### Required Studio v3 checks

1. Reopen the rebuilt `slice-v2/prototype/guardian-greybox.rbxl`. Play; verify one local approved Keeper, proper feet/front/scale, no loader/runtime errors, and no security changes. Run fresh loop/PvP/trap sessions from the historical checklist below; record new results.
2. Trigger each attack at legal near/mid/far range, on slopes and with groups. Check distinct loading poses, clear fists/hat, head following target, planted weight and full recoveries. Confirm a held boulder/acorn disappears at .620 and exactly one boulder or three capped acorns emerge from the same hand. Compare video at release: KeeperReleaseAt is the authored deadline; KeeperReleaseObservedAt can be up to a server tick later. Slam shockwave must begin at the .800 landing pose.
3. Verify fixed red landing ring and three visible fan lanes; changing direction after aim lock must escape. Test cover far from and within four studs of lob landing: only upward Floor collision counts as landing, walls/props block it. Splash hits groups only with sight and existing mercy/safety. Confirm elevated acorn targets use lob and predictions across a hill cannot launch an unsafe fan.
4. At <=12 studs, test grounded slam catches and properly timed jumps, including stepping into/out of the growing rim. Amber outer tell stays faint while the bright rim expands; inside the passed rim is safe. Check R6/R15 root-to-feet assumptions (current offline fixture uses rootY−3), hills, phone cameras and high latency. Tune clearance using actual avatar sizes if this fixture does not match the game.
5. Interrupt/reset before release and during each attack; no ghost damage/props, lingering rings or duplicate releases. Confirm leash/Return, Decoy committed-attack rules, dropped treasure guarding, mercy/shield refusal and two-client/late-join cleanup. Local held props must never obstruct raycasts or physics.
6. Run at least ten full 60-second solo escapes for unskilled play and ten for skilled play. Record accepted hits, drops, escapes and expiration, not merely projectile contacts. Tune interval/radius/lead toward ~2 and 0–1 accepted hits; preserve tells and mercy. Inspect full GIFs and the eleven-clip isolated package before owner review; playback feel remains unverified here.

Lessons: when landing near cover, classify the surface because distance alone admits wall hits. When release originates at a posed hand, check the entire arc including secondary props because release-frame clearance alone can miss later overlap. When impact has its own compression pose, the slam reads more clearly.

## Historical Keeper wiring (v1/v2; new kit supersedes its throw/poke timings)

Owner approval is OWNER-REPORTED in this task. Studio runtime/rendering/multiplayer are NOT RUN. No commit, upload, publish, account or security-setting change.

## Files and build

The existing main greybox is `production/slice-v2/prototype/guardian-greybox.rbxl`. The handoff's `prototype/...` paths are relative to `slice-v2`; `production/prototype` contains the separate meadow studies and had no old guardian greybox. This integration changes the main sources there. The meadow-A/B/C files and `treasure/map-v3` were not modified.

- Backup: `slice-v2/prototype/guardian-greybox.pre-keeper.rbxl`, copied before the first rebuild, SHA256 `287A8B8FC984226D773ECE4A0A751708DCB1EAEEF0322E80D91BF2B74D80AB98` (matches the old main binary).
- Rebuilt main SHA256: `0DB51DDB379D21FACFFE5DEDB263CB74ABB47CB623D167FD02F0D10A2ABA1F9F`.
- Sources: `Arena.luau`, `Keeper.client.luau`, `KeeperPose.luau`, `greybox.project.json`; new offline harness `keeper-check.luau`.
- Every source/document edit used apply_patch. The binary backup used Copy-Item with an overwrite refusal and hash check; binary generation used Rojo only.
- From `slice-v2/prototype`: `C:/Users/zerha/.rokit/tool-storage/rojo-rbx/rojo/7.4.4/rojo.exe build greybox.project.json -o guardian-greybox.rbxl`.

## Import and ownership

Reused and read the original approved geometry/animation modules and the crow JSON basis notes; no third-party code or new licensing dependency. The existing upload-free route is `CreateEditableMesh` → centred vertices/zero-based triangles → `CreateMeshPartAsync(Content.fromObject(...))`. Mesh centre and joint pivot are different: the loader recentres mesh vertices, restores that centre in its CFrame, then welds to a carrier at the approved JSON pivot. EditableMesh objects stay alive until rig cleanup.

Rojo mounts Rig/Animator/Clips/Geometry plus Pose in `ReplicatedStorage.MeadowKeeper`; the isolated Demo is excluded. Clients create the approved mesh locally. The JSON is CHECKED identical to Geometry: seven rigid animation parts, 32 material MeshParts, 1,752 vertices, 3,184 triangles. The seven-mesh FBX remains an unchanged authoring/reference artifact; no asset IDs or uploads are needed.

The old 4×11×4 guardian and its arm remain invisible server references. Their sizes, floor placement, close-poke shrink/restore, navigation agent, hit tests, leash, speeds, target preference, lead, cooldown, safe-zone checks and knock/drop callback stay intact. Local Keeper meshes and held rock have collision/query/touch disabled. Feet follow the hitbox's bottom; +Z mesh front is rotated to the hitbox's -Z look direction. Committed throws face the locked floor target.

The server selects the clip and replicates a shared server-clock start timestamp; clients sample the existing Animator at render time. This avoids a second animation clock and smooths the existing 20 Hz gameplay tick. KeeperElapsed is a diagnostic/fallback. Local mesh failure produces `[MeadowKeeper] EditableMesh loader failed`; it does not substitute another model or change settings.

## State mapping

| Existing state or event | Clip |
|---|---|
| Guard; stationary Search/Investigate | idle |
| Patrol; moving Guard/Search/Investigate | patrol |
| Warn; DecoyTell; close-poke windup | warn |
| Chase | chase |
| Committed ranged windup | throw |
| Existing stalled-return recovery departure; explicit Stun | stun |
| Accepted hit callback; explicit Celebrate | celebrate |
| Return | return |

There is no new gameplay stun or patrol route. Decoy investigation remains movement, never a stun. The 1-second existing warning can interrupt the 1.65-second warn animation. Return/attack/warning take priority over celebration; celebration never fires for a refused hit. Throw recovery can continue to its 1.4-second end unless a higher-priority state interrupts it, without stopping gameplay movement. Reset clears animation state and pending attack visuals.

Aim is locked when the original red disc starts. The server samples the exact authored hand socket at throw time **0.620 seconds**, creating one authoritative ThrownRock on the first existing server tick crossing Release. KeeperReleaseAt records the authored deadline; KeeperReleaseObservedAt records actual tick time; KeeperReleaseOrigin records the exact sampled socket. A hitch can delay observation by a tick; it cannot release twice. The client shows a local held rock before Release and hides it afterward. This held visual is not a damaging projectile.

The original **0.900-second impact deadline** and damage envelope remain unchanged. Flight therefore occupies the remaining **0.280 seconds**, using the existing lob height and spherecast obstruction checks. Reset before Release removes the pending attack. A hitch advances the arc to current elapsed time. Wide-hat clearance was sampled against all posed hat section bounding boxes using a conservative enclosing sphere for the full 2-stud cube, at 101 flight samples for each distance 10/24/56 and relative floor height -8/0/8/16. This is offline geometric evidence, not a rendered clearance claim.

## Offline evidence

CHECKED: main check.luau compiles all 15 local Luau sources at O0/O1/O2; existing placement/conservation/deadline/PvP/guardian/navigation/trap and 50-seed floor/route regressions pass. Geometry/navigation/physics in that harness are mocked. Binary runtime source parity and false / NOT RUN Studio gates pass.

CHECKED: keeper-check.luau executes the real Arena and shared pose sampler: approved JSON parity/triangle bounds; no early rock; one Release; shared socket; unchanged impact deadline; accepted-hit celebration; refused-hit suppression; reset cancellation; clip mapping; sampled hat clearance; all six new mounted runtime sources match the built binary. Existing anim/verify.luau passes all eight clips, authored CFrames, loop seams, marker hitch/speed/cancel/completion/reentrant transitions, compilation and isolated package parity. Selene: zero errors/warnings/parse errors. StyLua --check and git diff --check pass. Rojo build passes.

Exact Keystone Roblox Process Playbook was unavailable in exposed tools/local files; it is not claimed as read. Named comparison bar remains the owner-approved Keeper and supplied Pet Simulator / Grow a Garden references; this task reuses approved art, with no new visual-quality or independent live-review claim.

## Required Studio verification — do not mark complete without these

1. Close the old greybox window and reopen **slice-v2/prototype/guardian-greybox.rbxl**. Start Play. Inspect client Output: no loader/runtime errors. On the client, find one local MeadowKeeper beside the invisible Guardian. Confirm all seven articulated regions and 32 coloured MeshParts, one head/hat, correct scale/front, and feet on the camp floor. Server Explorer should retain the invisible original hitbox, not local meshes. If EditableMesh is unavailable, record the exact error and stop this visual gate; do not change security settings.
2. Run the existing tests in separate fresh Play sessions: set `ServerScriptService.GreyboxLoopTest=true`, wait for `GreyboxLoopTestSuccess=true`, PASS result and three successful runs; restart and run `GreyboxPvpTest=true`; restart and run `GreyboxTrapTest=true`. Check each Success/Result and Output. The loop/PvP runners include full 60-second expiry legs; allow them to finish. Record results rather than copying the old handoff's owner-reported passes.
3. After the normal loop/PvP gates pass in the manual-play session, enter Meadow. Watch idle at camp, warning on approach, chase after the existing one-second tell, patrol animation during actual untargeted movement, idle on search pauses, and return when sight/leash/progress recovery calls for it. Walk hills, cover cutbacks and dropped-treasure guard routes: boots/root must follow terrain without mesh separation, reversed facing or changed guardian pursuit.
4. Trigger several ranged attacks at minimum/middle/maximum legal ranges and different elevations. Check one held rock, one red disc, visible loaded right hand, one projectile emerging from that hand at Release, full hat clearance through loading/recovery/flight, and original disc-impact timing. Inspect SharedIsland attributes: `KeeperReleaseAt-TelegraphStarted=0.620`, `KeeperReleaseObservedAt>=KeeperReleaseAt`, `LastImpactDelay` approximately 0.900 plus tick latency. Compare render footage frame by frame; a matching timestamp alone does not prove visible hand alignment. Dodge and put hard cover in the flight path: existing hit/drop, mercy and obstruction behavior must remain correct. Confirm no early damage or duplicate rocks.
5. Get a legal close poke: no ranged projectile, original hitbox shrink/restore, same range/height/sight/mercy handling. Get a successful guardian catch: celebrate may play but does not pause chase/leash/damage. A shield/mercy-refused hit must not celebrate. Trigger/reset during pre-release windup: no later ghost projectile/disc/held rock. Run return recovery by preventing navigation progress: existing departure poof, stun pose, existing exceptional relocation timing, return/idle recovery, no new gameplay freeze.
6. Exercise Decoy: grant boolean `GreyboxDevTrapUnlock=true` to the Player in server Explorer, enter with fresh charge, place on legal outer floor before stealing. Verify warning then moving investigation/patrol, no new stun and no cancellation of a committed throw; expiration/recall/reset removes trap effects normally.
7. Independently inspect all eight complete authored clips in an empty local place using the existing `anim/MeadowKeeperAnimations.rbxmx` package. Insert from file and Play. This supplements production checks for clips naturally interrupted by existing state deadlines; it does not replace gameplay wiring checks. Verify full warn, throw recovery, stun, celebrate and all loop seams with the approved mesh.
8. Use Studio's two-client local test. Each client must build exactly one Keeper, show the same clip phase/facing/release, and see only the one server projectile. Test late join during throw and reset/arena removal: no stale clip, duplicate rig, orphan held stone, leaked Motor6D driver or retained local model. Confirm local visual meshes never obstruct floor/sight/spherecasts or player physics. Check mobile readability and client memory/frame time; performance and animation quality remain UNKNOWN until measured.

Lessons: When importing centred meshes, keep mesh centres separate from authored joint pivots because they define different transforms. When wiring release markers, retain the server impact clock because changing flight start must not quietly extend the attack tell.
# Current reviewer integration v4 — supersedes historical v3 below

CHECKED: reviewer sources, larger log/acorn geometry, dash, native effects and offline previews implemented. Rojo main place is `slice-v2/prototype/guardian-greybox.rbxl`; no commit or publication. Original pre-task backup: `guardian-greybox.pre-fx-v4.rbxl`, SHA256 `D8BD3415E88B553B7217B4D5CD93105222DE22F10A2A69DF9DAF0F1216725758`, hash-equal to main before the first Rojo build. Additional pre-final backup: `guardian-greybox.pre-fx-final.rbxl`. Source/document/format changes used apply_patch; backup and generated Rojo/Blender/XML/GIF outputs used existing artifact tools.

Final greybox SHA256: `5C29DB1017C1F56D233BC23DFB44BBC8946BAC3884A3F49E3CFEC9F39383133D`. CHECKED: all five effect GIFs fully decode through ffmpeg. Runtime parity check matches the final main place's modules, client and event.

New mounts: `MeadowKeeper.Effects`, `.Projectiles`, `.FXEvent` (RemoteEvent). Server `Arena.fx` only broadcasts presentation; no client damage authority or OnServerEvent. `KeeperAttacks` emits windup/release/impact/hit/wall hooks. Client Effects creates particles, attachments, trails, light flashes, crater decal, wedge shockwave mesh, warning scale bounce, literal hit/stun stars and distance-attenuated camera shake. Key clip transitions emit Warn/Chase/Return/Celebrate/Stun. Reset and guardian removal clean tracked effects; Debris bounds ordinary lifetimes. Sound objects are intentionally silent until verified IDs are assigned.

`KeeperProjectiles` reuses the inspected `HomeArtGeometry.Acorn` mesh and existing EditableMesh import route, recolors/scales it and caches three sections for clone reuse. Rolling log uses Roblox cylinders and cut-end/bark parts. Local visuals have collision/query/touch disabled. Authoritative projectile spheres keep collision independent of art; native Trail attaches to the spinning server carrier. Existing mesh-loader permission requirements persist; no security changes.

Proof: `anim/preview/fx/{lob,fan,slam,dash,warn}.gif`; `anim/preview/ATTACK-storyboard-v2.jpg`. GIFs are Blender approximations with real rig/clip/acorn geometry; particle rendering, camera shake, sound and Studio behavior are not proved. Warning GIF combines warning then a separate player-hit fixture. Dash uses a separate wall fixture. Two critics inspected anonymous ordered still strips; neither watched reference footage or continuous GIF playback. Lowest final scores: lob 4.5, fan 4, slam 5, dash 3, warn/hit 5 /10. One weakest-strip revision made; no claimed reference parity. Details/TODO sound names: [anim/FX-REVIEW.md](anim/FX-REVIEW.md).

Offline real-code checks: kit selection/timing/splash/fan/slam/mercy/cleanup plus dash planted tell, swept hitch hit, wall stun, safety/leash and effect-hook dispatch; Arena integration/source parity; 12 authored clip/driver/package checks; conservative sampled fist/held/flight head-hat clearance; existing map/PvP/ownership/deadline/navigation regressions. Physics/navigation are mocked. Selene and StyLua check pass after source formatting. Studio load/particles/mesh/audio/shake, two-client cleanup, device performance and human balance remain NOT RUN/UNKNOWN.

Task issued **no writes** to `treasure/map-v4` or any `meadow-*.rbxl`; concurrent map work continues, so whole-folder unchanged status is not claimed. Desktop is outside the allowed writable root; deliverables stay at these explicit repo paths.

Studio check route: reopen main greybox; trigger lob at far/group range, fan and alternate dash at 12–28 studs, slam within 12; collide dash with cover and observe full stun; jump the moving rim; accept/refuse hits via shield/mercy; reset before release and during flight. Check both clients, late joining, audio after ID assignment, and camera shake near/far. Match visible rings to actual contact deadlines and ensure log/hat clearance on slopes. Run existing Loop/PvP/Trap sessions separately, then human solo escapes before tuning.

---
