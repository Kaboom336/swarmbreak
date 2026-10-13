# T1 v2 greybox — ARENA-1013 free-placement plots

## Current revision: live-position pathfinding recovery (2026-10-13)

OWNER-REPORTED: GreyboxLoopTest 1/3 passed; loop 2 failed immediately after re-grabbing treasure at (-60.74, 3.45, 0.00), with `resume nearest route node 9` / `no reachable recovery/rejoin path`. CHECKED: the existing recovery pathfinder used radius 3/height 6 or walking-only radius 1.5, selected nearest scripted segments, validated navmesh points as authored markers, and never recomputed blocked/stalled paths.

Reused the shared driver and native Roblox PathfindingService. Every dropped-item recovery, solo rejoin after falls/knockbacks, PvP recovery and expiry exit now computes from the live root. Solo carrying recovery goes directly to the final return goal; other displaced route movement paths to its next goal. Removed nearestRoute and the fixed gully climb-out/stone index. CreatePath uses AgentRadius=2, AgentHeight=5, AgentCanJump=true, WaypointSpacing=4 and JumpGully cost=20. Harness-only PathfindingModifiers label the recovery floor and stones to prefer the walking bypass while allowing escape from the gully. Production geometry, collision, guardian tuning, treasure identity/deadline, rewards and rules are unchanged.

Computed floor waypoints use the shared segment-progress/radius arrival rule and real Humanoid Jump actions. They bypass authored-marker clearance validation. Forward Blocked events or 3 seconds without segment progress recompute from the current root; NoPath retries briefly instead of asserting at a fixed node. Connections and paths are cleaned up. Drop/stumble/expiry remain legal interruptions; return still requires production automatic secure with the same cargo before its original deadline. The existing 30-second recovery bound remains a harness failure if traversal cannot resolve.

CHECKED: pinned Lune compile O0/O1/O2 and complete check.luau harness, StyLua --check, Selene and the exact requested Rojo build. Added deterministic driver checks starting at the reported west-side position for live-start Blocked recomputation, a 3-second stall, Jump-action execution, NoPath retry, agent/cost settings, authored-validator bypass and path/connection cleanup. Navigation and physics in these checks are mocked; they do not establish a live navmesh pass. Built-source parity and locked NOT RUN runtime gates are checked by the harness.

Studio retest NOT RUN: no callable Studio integration is exposed. Reopen guardian-greybox.rbxl in fresh Play, leave GreyboxLoopTestRuns=3, trigger GreyboxLoopTest and require `3/3 passed`. Inspect recovery after west-side re-grab, stone falls and guardian knockbacks: logs should show computed path waypoints or live-position recomputation, without fixed-node resumes. Run GreyboxPvpTest separately. UNKNOWN: live Studio navmesh/physics, 3/3 and owner acceptance. No commit or publication. All text edits via apply_patch; the place stays in the requested prototype folder. Exact Keystone Roblox Process Playbook remains unavailable in exposed tools/local copies.

Reference comparison: Roblox's official pathfinding guide provides the native waypoint/Blocked pattern (https://create.roblox.com/docs/characters/pathfinding). Compared with the previous hand-picked node rejoin, this version replans from the actual player position. Retained Steal an Egg's guarded-objective/immediate-return loop and the existing meadow walking bypass. No new best-in-class gameplay verdict or independent live critique is claimed.

Lessons:
- When physics displaces a player, path from the live root because the nearest authored node may be unreachable.
- When following navmesh waypoints, use navmesh positions because authored-marker clearance tests reject valid edge/jump paths.
- When a path blocks or forward progress stalls, disconnect and recompute because a stale path cannot recover itself.

Current build SHA256: A3A37D32CCCF01AF5E8C1B4B10961B721D93B9AA282984330A5FE9D57D14E036

## Previous revision: shared waypoint arrival and route progress (2026-10-13)

OWNER-REPORTED: GreyboxLoopTest 0/3 passed; loop 1 stuck >8s at straight run-up Jump first stone, circling 1.45-2.33 studs from its goal. CHECKED: reused the existing shared LoopTest driver and check.luau harness. The driver required 0.3-stud run-up arrival, steered every tick and stopped on arrival. This repair changes only harness movement, regression checks, this report and verification.log, plus the requested generated place. Production game rules, map, speeds, jump heights, guardian, treasure ownership/deadline and placement remain unchanged. Text edits use apply_patch; no commit or publication.

- Shared walking, edge, recovery/path, home, dodge and jump landing arrival: horizontal distance <=3 studs OR projection along the segment reaches/passes its goal. Existing floor/height checks remain; jumps still require actual observed takeoff and grounded landing. Return legs still finish only when production legally secures the same cargo before its deadline.
- Run-ups cross a plane through the run-up marker, perpendicular to the incoming horizontal segment. Their single MoveTo target lies three studs beyond the plane, avoiding braking at the marker. Takeoffs cross the plane through the launch marker along the launch-to-landing direction; no point-distance requirement or early 0.15-stud threshold. An actor already on the run-up line completes immediately.
- Each moving segment issues MoveTo once. No per-tick steering, endpoint slowdown, arrival stop or intervening yield before the next segment. Explicit hold actions stop movement; legal interruptions and unready jumps retain their stop behavior.
- The eight-second stuck watchdog tracks increasing horizontal projection along the current route segment, with a 0.2-stud progress threshold. Lateral circling does not refresh it. The thirty-second segment limit remains; logs show horizontal distance and along-route progress separately.

CHECKED PASS: pinned Lune0.10.5 `run check.luau` (all ten sources compile O0/O1/O2; complete harness); StyLua2.0.2 `--check .`; Selene0.31.0 (0 errors/warnings/parse errors); exact Rojo7.4.4 `build greybox.project.json -o guardian-greybox.rbxl`; final binary/runtime source parity. New production-driver mocks cover all four reported X/Z positions against a synthetic goal Z33.5 (reported goal X=-57.1; exact goal Z was not supplied), normal/edge arrival, overshoot outside the radius, immediate next-segment command with no stop, run-up line crossing and zero-length run-up, airborne-to-grounded jump landing beyond the goal, forward progress despite growing lateral distance, and a sideways orbit that still fails after >8s. Existing run-up/takeoff/missed-jump, drop/stumble/expiry, secure, PvP, three-run batch and fifty-seed route regressions remain PASS. Movement/physics are mocked; these are not live Studio passes.

Studio retest NOT RUN: no callable Studio integration is exposed. Reopen the rebuilt guardian-greybox.rbxl, leave GreyboxLoopTestRuns=3, and trigger GreyboxLoopTest once; require `3/3 passed` without a run-up arrival stall. Inspect line-crossing takeoffs and continuous movement through stone, ramp, recovery and home waypoints. Run GreyboxPvpTest separately. Both built runtime gates remain false/NOT RUN; live physics/navmesh, 3/3 and owner acceptance are UNKNOWN. Exact Keystone Roblox Process Playbook remains unavailable through exposed tools/local copies.

Reference comparison: retained Steal an Egg's guarded-objective/return loop and meadow-topdown's optional walking bypass. The former sub-stud point driver stopped at each waypoint; the revised driver crosses route lines and preserves momentum. No new best-in-class verdict or independent live critic claimed for this harness-only fix.

Lesson: When momentum crosses a route marker, accept segment progress and advance immediately because repeatedly seeking an exact point creates false stuck failures.

Current build SHA256: 06736357A81132E27E44BD3116D692DB5520B5FA586DD43DBBEA45747A6143CE

## Previous revision: missed-jump climb-out and void recovery (2026-10-13)

OWNER-REPORTED: GreyboxLoopTest 0/3 passed; loop 1 stalled >8s at Jump four-stud gap after falling to root Y0.45 instead of normal Y3.45. CHECKED: read production Layout/Arena/player fall handling, movement driver and offline harness; inspected ../../treasure/v2/meadow-topdown.png, including its "Optional bypass; walking route". Reused existing native-Part geometry and treasure rules; no dependency, asset, commit or publication. No changes outside prototype/ for this repair; pre-existing workspace edits preserved. All text edits via apply_patch; binary generated with the exact requested Rojo command.

- Game: both existing 12-wide climb-out ramps now overlap the west/east banks of the only authored gully, rather than ending exactly at the cutout boundary. Offline sampled center traversal has no rise of 0.7 studs or greater. Live collision/navmesh remains UNKNOWN. Original ramps already existed; the reported harness did not attempt them, so a physically impassable original ramp is not established.
- Game: record a grounded, body-clear route spot near the current floor as lastSafe; initialize it on each arena entry. Void/outside falls still use the existing production drop, one-second hidden cargo recovery, poof/settle and original treasure clock. Restore the player to lastSafe (entry fallback), clear linear/angular fall velocity, and retain the same arena/run. Ordinary gully falls keep carried treasure unless the existing guardian/drop/expiry rules act.
- Test: every authored jump first walks back to a supported marker 6.6 studs behind takeoff, arrives within 0.3 studs, then runs straight toward the edge. Launch threshold is 0.15 studs before the marker. Run-up/edge checks permit intentional lower floor beside supported launch platforms; normal destination clearance remains three studs. CarrySpeed13.5 and CarryJumpHeight7.2 unchanged.
- Test: root Y more than two studs below both launch and landing triggers missed-jump recovery before the stuck timeout. Choose the optional walking bypass instead of another stone attempt: walk out using PathfindingService with jumping disabled, then resume at east stone clearance. Recovery uses a 1.5-stud radius so the real avatar can leave the four-stud stone corridor; its path waypoints use matching floor/body/head checks. Drops/stumbles/expiry still interrupt and preserve the existing rules.
- Gap: extend Stone3's south edge one stud (same top height/width), reducing the longer authored gap from six to five. The historical "six-stud gap" waypoint label remains for continuity. At assumed default gravity196.2, conservative center trajectories at speed13.5/height7.2 give required distances3.51/4.81/5.89/0.80 versus ranges7.05/7.05/7.05/8.01. Smallest inferred landing margin1.16 studs; these calculations do not establish live jump success.

CHECKED: all ten Luau files compile O0/O1/O2; full Lune harness PASS; StyLua --check PASS; Selene0 errors/0 warnings/0 parse errors; requested Rojo build PASS; every runtime source matches the binary. Added production-driver regressions for straight run-up, edge launch and reported Y0.45 fall detection before8s; walking-only recovery configuration; both bank ramp profiles; carrying jump margins; and production void branch with/without cargo and with/without lastSafe. Movement, collision and navigation are mocked offline. Existing guardian, PvP, deadline, drop and three-run batch checks pass.

Studio retest NOT RUN here: no callable Studio integration is exposed. Reopen guardian-greybox.rbxl in Studio and run GreyboxLoopTest (default3 runs). Deliberately miss a stone: confirm walking climb-out/bypass, no stuck timeout and unchanged cargo clock. Separately fall off the island with and without cargo: confirm lastSafe recovery, stopped fall velocity and normal treasure recovery/drop rules. Rerun GreyboxPvpTest. Both generated runtime gates remain false/NOT RUN; new live results, navmesh, physics and owner acceptance are UNKNOWN. Keystone Roblox Process Playbook remains unavailable through exposed tools/local copies.

Reference comparison: meadow-topdown's optional stone bypass and walking routes are preserved; the harness now uses them after a miss. Retained existing named gameplay reference Steal an Egg for guarded treasure/return. No new best-in-class verdict or independent live critic claimed.

Lessons: When a jump fails, detect height loss and choose a walking exit because pursuing the landing from the gully repeats the trap. When tuning carrying jumps, check takeoff-to-landing distance and leave a margin because nominal gap width omits approach geometry.

Current build SHA256: CDA4FAD03C843F1E2E6263C921BEEA72C0E51613297D57235FF337B042B9CEB2

## Previous revision: interruption-safe loop harness after plots

OWNER-REPORTED: GreyboxPvpTest PASS. GreyboxLoopTest FLAKY: Run A hit/dropped at (-24.3,6.4,22.3) during the stepping stones, then attempted a jump at stumble speed5; Run B exceeded the real60s deadline and stalled on the empty return. CHECKED: read the existing runner, production loot/guardian/drop rules, Layout, plots and offline harness. Reused that foundation; no external dependency or asset imported. Only LoopTest.luau, Greybox.server.luau, greybox.project.json, check.luau and this report changed for this task, plus verification.log and the requested generated binary. All text edits via apply_patch; no commit or publication.

- Every carrier walk/jump, including jump readiness and takeoff approach, observes drop/stumble/expiry before further movement. A legal interruption stops movement, waits out stumble, retries production settle/Grab on the same treasure and preserves firstPickup/deadline. Interrupted holds can retry until the original clock expires. Recovery and rejoin use real Humanoid movement along a PathfindingService path with a three-stud agent radius and independently checked floor/body clearance; no obstacle teleport or guardian immunity added.
- After recovery, select the nearest supported route segment or grounded stone endpoint from the current root, then continue its route index. Grounded segment projection prevents aiming across a hill from the obsolete next step; jump segments expose landing endpoints only. Legal automatic securing during recovery/rejoin is accepted after checking original cargo, holder and deadline. Home placement walks still require physical arrival. Returning from a placed plot retraces the open gate for the next loop.
- Natural deadline expiry ends that loop as `PASS-with-expiry`: verify retired original, no holder/hold/visual/weld/shared clock, no completion or plot award, rejected expired Grab/Place, and exactly one new Nest ID with no deadline after the normal respawn delay. Empty return joins a shared, preflighted terrace/ramp/central-lane exit and ends at reachable cyan Z=-40. It no longer blindly reverses Quick into the old stuck return goal. The existing PvP forced60s expiry regression uses the same exit recipe and checks.
- `ServerScriptService.GreyboxLoopTestRuns = 3` by default; integer values >=3 run that many loops. One trigger reports each loop and totals in `GreyboxLoopTestPassCount`, `GreyboxLoopTestExpiryCount` and `GreyboxLoopTestResult`. Default PASS requires3/3 without harness errors; conserved game losses count and are reported separately from placed treasure. A failure reports the partial pass count and failing loop. Later loops wait for a fresh Nest and use its new production deadline; plot counts accumulate normally.
- Dodge interruptions recover normally. A missing throw window continues the legal carry and logs that gap; observation attributes are evidence of events actually observed, not prerequisites that turn a legal loss into a harness failure. This gate verifies harness completion/conservation and does not claim three successful steals or complete obstacle coverage when legal losses occur.

CHECKED PASS: pinned Lune0.10.5 `run check.luau`, all ten Luau files compiled O0/O1/O2, complete existing harness and new live-driver regressions; StyLua2.0.2 `--check .`; Selene0.31.0 zero errors/warnings/parse errors; exact requested Rojo7.4.4 `build greybox.project.json -o guardian-greybox.rbxl`; rebuilt source parity, runs=3/counts=0 and both false/NOT RUN runtime gates. New checks inject drop/stumble/expiry during walking, jump approach and airborne readiness; legal secure at an arbitrary step; required Home walking while secured; stumble wait, interrupted Grab retry and unchanged original clock; expiry during recovery; reported stone/ramp nearest resume; all50-seed empty-exit endpoints and continuous ramp/floor segments; mixed3/3 outcomes, rejected2/3 harness failure and rejected fewer-than-three configuration; clean-loss/new-ID conservation and orphan-weld rejection. Movement, raycasts, navigation and effects are mocked offline.

Studio retest: reopen guardian-greybox.rbxl, fresh solo Play, leave GreyboxLoopTestRuns=3 and trigger GreyboxLoopTest once. Require `3/3 passed`, inspect placed versus legal-expiry totals, and confirm hit recovery during stones/ramp/dodge/return without a stumble takeoff. On expiry require retired-ID/new-Nest conservation and completed empty return before the next loop. Run GreyboxPvpTest separately to retain its handoff/forced-expiry evidence. CURRENT STUDIO: NOT RUN here; new navmesh/Humanoid physics, live3/3 and owner acceptance UNKNOWN. Owner-reported prior PvP PASS is not copied into the rebuilt gates. Exact Keystone Roblox Process Playbook remains unavailable in supplied/local sources; applied the supplied core-moment/reference rules.

Reference bar retained: Steal an Egg's guarded-objective/immediate-return loop. Side by side, the previous harness required uninterrupted scripted movement; this harness accepts game-legal drops/losses while still rejecting ownership, award and physical-duplication errors. No new visual comparison, independent critic verdict or live pass claimed for this narrow harness repair.

Lessons: When combat can interrupt any await, inspect ownership and the clock inside each movement/hold because boundary-only checks race live hits. When loss is legal, judge cleanup and conservation separately from winning because a timeout should not fabricate a harness failure. When recovery changes location, rejoin verified route geometry because the scripted next point can be across an obstacle.

Current build SHA256: 75E7E1679E0324F6C99FDEF6C891395B691EB05FF82A4A10CED6C9DAF0AA1065

## Previous revision: larger plots and free placement (recipe 6)

CHECKED: read ARENA-1013.md and GDD.md; inspected treasure/v2/home-island.png, existing prototype placement, both Studio runners and the regression harness. Reused existing native Parts, Scene, LootRules and item conservation. No external code, assets or dependencies imported. All source/report edits used apply_patch, only inside prototype/. Generated guardian-greybox.rbxl with the exact requested Rojo build. No commit or publication.

- Eight 64×48 plots, 56×40 usable interiors (4-stud inset), in two columns. Design/map centres X=±52, Z=-96/-32/32/96; map north converts to negative world Z. Home is 216×320, central corridor40, row gaps16. Twelve-wide inward gates, 12×12 entrance reserves and eight-wide clear entry paths. No PetPad instances or preset placement rows.
- Meadow portal map(0,0), spawn(0,-16), Shop(0,-144), four locked selectors near Z144. Preserved raised portal/ramp presentation; secure cargo returns to its own gate outside the reserve. Central fresh/empty return spawn resolves to the raised landing. Home capture camera reframed for the enlarged island.
- Secured cargo automatically enables a green/red footprint ghost. Aim on the floor and Place with E/X or the button; rotate15° with R/Y/button; optional1-stud snap with G/B/button, OFF initially. Touch/controller aim through screen centre while moving the camera. Walk close enough to the chosen point (24-stud range); placement can use any legal free point in the owned interior.
- Shared Placement module previews/validates rotated4×4 footprints with conservative axis-aligned envelopes. Server additionally checks owner, secured/Home state, finite coordinates/yaw, actual own-plot floor, range, entrance/path reserve,2-stud spacing, eight active records and replay. Rejected placement retains the same secured cargo. Successful placement records chosen X/Z/yaw once; disconnect clears the vacated plot's footprint records.
- `GreyboxConfig.PetsWander = false`: anchored chosen X/Z/yaw, small0.15-stud idle bounce. The single flag's true branch adds bounded0.25-stud lateral idle drift inside the reserved footprint; full home navigation/roaming awaits owner direction. Existing placeholder blocks remain; actual pets, opening/income and durable saves are still outside this greybox.
- Both GreyboxLoopTest and GreyboxPvpTest share the updated placement step: walk to a free own-plot point, reject out-of-bounds and an overlapping reserved fixture, verify rejections retain cargo/count, place at chosen yaw, reject replay and check one physical item. Their guardian, PvP, original-ID/deadline and full60s expiry checks remain. Home entry/expiry waypoints use the shifted ramp.

CHECKED PASS: ten Luau files compile at O0/O1/O2; complete Lune harness; StyLua --check; Selene0 errors/0 warnings/0 parse errors; requested Rojo build; all runtime sources including Placement match the binary. New production-adapter tests exercise all eight plots, fractional free positions, rotation, malformed/nonfinite coordinates, floor/range, owner, gates, overlap, capacity8/replay and retained cargo. Constructed-scene checks confirm the216×320 home,64×48 rails,12-wide gates and absent pads. Built-floor sampling checks all eight gate-to-portal paths and ramp continuity. Raycasts/visuals/navigation are mocked in offline adapter checks.

OWNER-REPORTED baseline: both Studio tests PASS before this revision; PvP takes approximately140s. CURRENT STUDIO RETEST: NOT RUN here, no callable Studio integration available. Both binary runtime gates remain false/NOT RUN; no prior pass copied onto changed code. Live Humanoid movement, ghost/button usability, rendered idle motion, phone performance, farthest-plot timing and owner acceptance remain UNKNOWN. Exact Keystone Roblox Process Playbook remains unavailable in the supplied/local sources.

Retest: reopen guardian-greybox.rbxl. In fresh Play enable ServerScriptService.GreyboxLoopTest; then run GreyboxPvpTest in a separate fresh Play and allow its full expiry regression (baseline ~140s, not a new measured duration). After both gates pass in the current session, secure cargo and try off-grid placement/rotation/snap; out-of-bounds/occupied points stay red and retain cargo. Eight active placements prevent another run, preserving the existing prototype capacity behavior.

| Supplied reference bar | Previous prototype | This revision / evidence |
|---|---|---|
| BGSI hub legibility; home-island.png two plot columns | Cramped38×28 pens, fixed pads | Eight64×48 plots around a40-wide corridor; dimensions inspected offline, rendered comparison NOT RUN |
| PS99 / Package-A-Pet plot/reward clarity | Automatic pad chosen by count | Chosen floor footprint and yaw, explicit invalid feedback; real pet/reveal presentation remains outside T1 |

These are the arena's supplied reference anchors, not a current popularity ranking or a claimed visual victory. No independent live critic or new footage test performed.

Lessons: When plots grow, keep the active cap separate from coordinates because space must not create extra earners. When Place is invalid, validate before consuming cargo because retries must conserve the same reward. When a portal moves, sample every plot's entry route because a legal endpoint alone does not prove a traversable path.

Current build SHA256: 70C7968AFF445309485F8BAC64CAA9FCAB6F5F450AEE32DB9F7096122F02AD32

## Previous deadline revision and retest history

CHECKED: read ../../treasure/ARENA-1013.md, the Roblox production skill, prototype code and earlier T1 report. Reused the native-Part scene and item/guardian foundation; no dependency or asset imported. Recipe version5. Only this prototype folder edited; no commit or publication.

## Current Studio retest round 3: reachable drops and live PvP approach

OWNER-REPORTED: GreyboxLoopTest failed `no standable Grab point for arena1:1` after treasure settled near world (-24,82,-344), beside JumpLanding. GreyboxPvpTest failed actual root range at tester (-59.85,3.44,56.20), dummy (-65.36,3.00,54.63), while the guardian poked the carrier. CHECKED in code: old drop sockets were an arbitrary four-stud floor grid with no ledge/body envelope; the PvP runner walked to a fixed court goal with a 2.25-stud arrival tolerance.

Game fix: reused the existing walking routes, cross-links, carrying route and PvP routes as the drop network. Grounded segments supply candidates every two studs; airborne jump/recovery segments supply endpoints only. The nearest valid candidate to the live root wins, with no six-stud search cap or stale lastSocket fallback. Actual floor raycasts must agree with authored height and pass a half-stud sampled three-stud clearance radius, slope/floor checks and six studs of head space. Safe apron proximity is excluded. Results are cached against this static map. Reset/disconnect drops also project onto the same safe network.

Off-island cargo uses the same nearest safe destination, stays hidden/ungrabbable for one second, then reappears with a visible expanding orange poof and the normal 0.6-second settle bounce. Expiry still runs first; original ID, pickup time and escape deadline stay unchanged. The treasure remains anchored while dropped, so the production carrier-fall boundary triggers this recovery rather than physical item falling.

PvP runner fix: after the dummy reaches the court, a test-only API cancels guardian attacks/paths and holds it at camp. The tester walks toward the dummy's live floor until actual root separation is at most three studs, re-reads both roots immediately before Bump, and still uses the production four-stud eligibility/hold checks. Shield, mercy, cooldown, settle and ownership rules are untouched. Guardian simulation resumes before the full expiry regression and is restored on every test success/failure. This isolates the court handoff; the solo runner continues testing guardian combat.

CHECKED: Lune nine-file O0/O1/O2 compile and full harness PASS; StyLua --check PASS, all formatting edits via apply_patch; Selene zero errors/warnings/parse errors; requested Rojo build PASS; binary/source parity and both false/NOT RUN runtime gates PASS. New production-code regressions cover the reported cliff, cover, island edge and off-island positions across seeds 101/202/303, independently check clearance and nearest valid candidate, test no recovery before one second/exact-one-second poof/normal settle, and reproduce the reported PvP separation with a dummy moving again after the first snapshot. Navigation/visual effects/movement are mocked in these offline checks.

Studio retest: reopen guardian-greybox.rbxl. Run GreyboxLoopTest then GreyboxPvpTest in fresh Play; verify reachable recovery around JumpLanding, three-stud live Bump setup, original-ID Grab/secure/place and both full expiry checks. Separately carry treasure off an island edge: verify a one-second hidden interval, arrival poof at a reachable route spot, and unchanged countdown. UNKNOWN: new Studio results, live Humanoid/navmesh clearance, poof appearance and owner acceptance. No Studio/Keystone tools are exposed; local searches did not locate the Keystone Roblox Process Playbook. No commit or publication; prototype-only source/report edits via apply_patch and the requested generated binary.

Reference comparison: retained the established Steal an Egg guarded-objective/immediate-return reference. Compared the prior floor-grid/fixed-goal implementation with route-constrained/body-clear drops and live-root approach in production-code regressions. No new best-in-class verdict, footage comparison or independent critic run is claimed.

Lessons: When treasure drops near cliffs, project onto verified reachable route spots because a floor hit alone does not prove access. When a target can move, close against its live root and re-check before acting because waypoint tolerance does not establish interaction range.

Current round 3 build SHA256: 1303980C5C629D76444C7E8BD0F2804C4BCDC62DF7A9FAA2BD0B45C78E1F0A38

## Previous Studio retest fixes: corner arrival, walking guardian return, expiry home route

OWNER-REPORTED: Loop runner stalled at inner return corner with distance1.94; guardian Return/Guard logs appeared to snap back to post. PvP runner stalled at expiry home portal. CHECKED: ordinary arrival used horizontal<=0.8; guardian Return assigned camp CFrame on arrival or a2.5s timeout; expiry walked diagonally from the pen to the raised portal, bypassing its ramp. Guardian body is noncollidable; its body cannot explain the player stall. Exact live blocking geometry remains UNKNOWN.

Changed ordinary grounded walk arrival to2.25 studs while retaining vertical<2 and airborne rejection. Jump arrival remains0.8 and requires actual takeoff/landing. Return legs complete only on the production Home/secured-cargo transition; the larger walk tolerance cannot bypass secure entry or its deadline.

Guardian Return keeps ordinary pathfinding and bounded walking steps. Reaching its existing3-stud post radius enters Guard without snapping position. Removed2.5s relocation; exceptional recovery requires20s without meaningful movement while returning, then a1s visible expanding departure poof before relocation and a1s arrival poof. Progress cancels recovery; reset destroys effects. Difficulty/attack/loot/deadline rules unchanged.

Expiry now retraces the pen aisle to HomeSpawnZ, enters the central lane, then uses ramp approach(0,0,24), landing(0,3,-6), portal(0,3,-16). One shared homeEntryPoints recipe feeds live preflight and expiry walking. CHECKED offline: all eight pen routes sampled against constructed home floor transforms, including the cylinder platform; waypoint3-stud clearance and continuous ramp traversal pass.

CHECKED: Lune nine-file O0/O1/O2 compile and complete regression harness PASS; StyLua --check PASS (format edits via apply_patch); Selene0 errors/0 warnings/0 parse errors; requested Rojo build PASS; binary/runtime source parity PASS. New regressions accept reported1.94 walk distance, reject unlaunched jump arrival, reject early guardian relocation through8s, walk home with bounded steps, and require long-stall departure/arrival poofs. Guardian floor mock corrected to preserve world Z instead of double-flipping it. Earlier claimed <8s hill snap/throw recovery is superseded by these walking/long-stall expectations.

Studio retest: reopen rebuilt guardian-greybox.rbxl; run GreyboxLoopTest and GreyboxPvpTest in fresh Play. Watch inner return corner arrival, a spatially continuous Return->Guard, expiry pen/central/ramp waypoints, full60s expiry and empty-handed return. UNKNOWN: new Studio results, live navmesh/physics and visible poof appearance. No connected Studio tool available; both build gates remain false/NOT RUN. Keystone Roblox Process Playbook still unavailable locally/through connectors. Scope: prototype only, edits via apply_patch, no commit or publication; binary generated by the requested Rojo command.

Reference comparison: retained the existing Steal an Egg guarded-objective/immediate-return reference; guardian return now uses visible travel rather than the old silent snap. No new footage, best-in-class verdict or independent critic run is claimed for this repair.

Lessons: When a waypoint stalls inside a character-sized radius, allow grounded walking arrival while preserving jump/secure requirements. When NPC return navigation fails, measure lack of movement rather than total journey time because long walks are valid. When re-entering from a raised-side approach, retrace the authored ramp because a standable destination alone does not prove reachability.

Previous build SHA256: 254EC403F7D70FE30C48DD4EE9DD3F7FD12350218E8ED8DD133D80018819EB60

## Earlier Studio failure fixes after map/guardian/timer batches

OWNER-REPORTED: GreyboxLoopTest rejected `Dodge locked red disc` because authored Y disagreed with CampSouthRamp. GreyboxPvpTest failed `unexpected arena reset/return` while walking toward world (-26,79,-304); the actor arrived Home with the same item Secured.

CHECKED: inspected treasure/v2/meadow-topdown.png beside Layout/Arena geometry. The reference keeps camp top +4 and a ramp from ground; current CampSouthRamp runs from local (-4,0,0) to (-4,4,12). The north dodge option (0,8) lies on that ramp, with surface Y=8/3, not Y=0. Geometry retained. Added shared `Layout.dodgePoints()` used by both dodge/make-room movement and live preflight. Both north/south options now receive the same slope, floor, head-space and 3-stud clearance checks before pickup. Actual walk targets still resolve to raycast surface Y+3; authored-height validation remains strict.

CHECKED cause of PvP return: the production heartbeat calls `returnRun(actor,true)` when carried cargo enters `Arena.safe`. `Layout.protected` includes the independent west arch apron X=-38..-16, Z=-74..-42. The old target (-26,0,-56) was inside it. `Rules.secure` followed by `home()` accounts for phase Home, cargo Secured and world (0,4,84). This is legal automatic boundary entry, consistent with the reference's eight-stud return apron; no touch handler or deadline teleport causes this path. Expiry retires cargo without forcing Home. Guardian warning does not cancel a legal secure entry.

Changed the runner to execute its already-authored `Winner` route: approach X=-42 outside the apron, then X=-34 marked Return across X=-38. Removed duplicated hard-coded goals. Legal drops still retry recovery of the original ID; automatic return now requires the same held cargo, Secured state and securedAt before the original deadline. Other waypoint returns still fail. Added a server return log with source, protected-boundary status, pre-teleport world position and cargo ID/state for the next Studio run.

CHECKED offline: nine files compiled at O0/O1/O2; StyLua format/check PASS; Selene 0 errors/0 warnings; requested Rojo build PASS; rebuilt runtime source parity PASS. Added 50-seed clearance checks for both dodge options and a negative reproducing the old Y0 failure. Executed the production movement driver's return branch with mocked movement: reproduced the old unexpected-return assertion, accepted a legal secure, rejected lost cargo and exact-deadline secure. Verified X=-38 boundary and every Winner route point's expected protected status. Movement mocks and scalar floors do not establish Studio physics success. See verification.log current-run section.

Studio retest: reopen guardian-greybox.rbxl; in fresh Play enable GreyboxLoopTest, then GreyboxPvpTest. Confirm both dodge-option preflights, normal dodge, original-ID Bump/Grab, `[Greybox] return source=protected apron` at the west boundary, `legal automatic secure`, placement and full 60-second expiry regressions. UNKNOWN: new Studio pass, live Humanoid clearance/jumps/navigation and owner acceptance. Build gates remain false / NOT RUN. No commit; edits and outputs only in prototype/. Keystone connector/playbook unavailable; prior local-search gap remains.

Reference comparison: inspected meadow-topdown.png's camp +4/ramp and portal (-24,-58)/eight-stud apron alongside generated geometry; retained both rather than moving geometry to satisfy incorrect runner assumptions. The existing named gameplay reference is Steal an Egg (guarded objective/immediate return); no new live comparison or independent critic run is claimed for this narrow fix.

## Implemented

- Removed hide state/occupancy, concealment timers, leave-hide controls, markers, log/bush scenery, chunks I09/I10, sniff and special log-opening poke. Ordinary close guardian attacks remain.
- Four solid open rocks replace those areas. Map X,Z centres: (38,-18), (38,-38), (62,-26), (62,-46); footprints8×8, heights6–8. Each pair leaves a12-stud through passage, open sides and no enclosed interior.
- Preserved the160×160 top-down layout, hills, stones/recovery, three routes, two links, safety apron and ordinary cover.
- The60.0-second escape deadline starts on first completed nest Steal and belongs to that treasure ID. Drop/Bump/settle/Grab/recovery/handoffs preserve it.
- Portal accepts cargo immediately while server now < escapeDeadline. Exact-zero/late entry awards nothing. Empty-handed return remains available.
- All arena occupants, including late arrivals, see one countdown near screen centre, using replicated server time. Amber≤15s; red and larger≤5s. Securing clears the shared clock.
- Expiry retires the old ID, clears holders/holds, destroys item/weld, disables old prompts and resets guardian attack/path state. No completed escape or placed reward is added. A new nest ID appears3s after expiry, with no deadline until stolen. Occupants remain.
- Secured cargo is unaffected. T1 has placeholder secure/place and no durable economy/save service; ARENA-1013 SecurePending/storage reconciliation remains outside this prototype.

## Preserved difficulty

User-requested harder tuning overrides the arena document's older values: walk16, carry13.5, guardian14.5, burst15 for0.7s every4s, detect24/throw56, telegraph0.9s, cooldown2.5s, lead0.65s capped9, mercy3s. First guardian hit drops carried cargo. Last-seen search is now2s, without concealment immunity. Steal/Grab/Bump2/0.4/0.4s; shield12s, settle0.6s, Bump cooldown2s. Idle10s + warning2s drop remains. LOOT keeps one ID through contested holds.

## Geometry and cameras

Map +Z north converts to world -Z. Meadow origin(0,76,-360). Camp(0,32)/40×40/+4; west hill(-40,12)/40×40/+10; east hill(40,12)/40×40/+8; stone cutout(-32,-28)/32×24/floor-3; original cover(-10,-10)/(10,8); pad(0,-58)/32×24; arch(-24,-58). Slopes≤25°; no mandatory route jumps.

| Camp-return route | Authored 3D length |
|---|---:|
| Quick | 93.52 studs |
| Ridge | 110.48 studs |
| Grove | 129.88 studs |

Solo carrying traversal:376.78 studs, previously477.44. It retains one hill climb/descent, the stone set and a normal locked-disc dodge near camp before the detour. Measured distance is not observed completion time. The runner fails if cargo reaches its deadline before securing.

Home, pens, altitude bands and cameras are retained. Enable ServerScriptService.GreyboxCaptureCams. Workspace.GREYBOX.CaptureCameras contains marker Parts/Cameras. Home eye(0,96,172), target(0,4,-22), FOV55; Meadow eye(0,140,-228), target(0,80,-370), FOV58. Use16:9; restore CameraType Custom and subject afterward.

## Verification

CHECKED offline: nine Luau files compile O0/O1/O2; StyLua format/check passes; Selene0 errors/warnings; requested Rojo build passes. See verification.log.

- Deadline tests: before-zero success, zero rejection, original deadline through handoff, carried/dropped retirement, competing hold cleanup, no award, fresh ID/+3 refill scheduling, actual production weld/visual cleanup.
- Production scene construction: absent hide chunks/scenery, six hard covers,12-wide cutbacks, guardian attack/path cleanup, home/vistas/capture-camera cleanup.
- Fifty fixed seeds: authored floor heights/slopes/cliffs/cover, solo/PvP waypoint clearance, grounded jump lead-ins and invalid waypoint rejection.
- Production guardian state machine: carrier preference, sight/range/mercy/cooldown, close attacks, stalled navigation recovery and throws across three seeds. Navigation mocked.
- Production PvP adapter: range/sight/height/arena/safety, shield/mercy, contested holds, Bump/drop/settle/Grab, winner secure/place conservation.
- Binary source parity includes every runtime source, including Scene. Both Studio gates remain false / NOT RUN.

Studio runners UPDATED, NOT RUN: in fresh Play set GreyboxLoopTest=true, then GreyboxPvpTest=true. Each secures original cargo before deadline and checks placement. PvP asserts original ID/timestamp/deadline through Bump/Grab. Each then performs a second real Steal, waits the full60s, checks no award/holder/hold/weld/physical duplicate, one new nest ID after3s, and empty-handed return. This extra regression extends total runner time; successful cargo escape must be under60s.

UNKNOWN: Studio pass, Humanoid jump physics, navmesh, rendered countdown readability, mobile performance, real multi-client fairness, fun and owner acceptance. No live runtime or screenshots claimed. Exact Keystone Roblox Process Playbook unavailable after local search.

Recovery note: a PowerShell alias caused an edit script to overwrite sources. Runtime code was recovered from the pre-edit binary, previously reported source-matched. check.luau was reconstructed from its committed harness, updated for harder guardian/world conversion, and extended with current expiry/scene checks. Earlier constructed-ray/pen-route checks are not claimed as rerun by this harness.

Offline arena comparison: Steal an Egg keeps the guarded objective/immediate return; Steal and Hide dedicated hiding is removed per owner direction, while ordinary rock cutbacks preserve visible pursuit. Reference superiority and independent live critique remain UNKNOWN.

Pinned commands, from this folder:
- C:/Users/zerha/.rokit/tool-storage/johnnymorganz/stylua/2.0.2/stylua.exe .
- C:/Users/zerha/.rokit/tool-storage/kampfkarren/selene/0.31.0/selene.exe .
- C:/Users/zerha/.rokit/tool-storage/rojo-rbx/rojo/7.4.4/rojo.exe build greybox.project.json -o guardian-greybox.rbxl
- C:/Users/zerha/.rokit/tool-storage/lune-org/lune/0.10.5/lune.exe run check.luau
- C:/Users/zerha/.rokit/tool-storage/johnnymorganz/stylua/2.0.2/stylua.exe --check .

Lessons:
- When holders change, keep deadlines on items because carrier clocks allow refresh exploits.
- When expiry races entry, decide on one server clock because client numerals cannot award ownership.
- When editing through PowerShell, use explicit function names and stop on errors because aliases can shadow short names.
Current-fix lessons:
- When test movement branches dynamically, preflight every candidate because static route checks miss dodge/recovery destinations.
- When a route crosses an automatic secure boundary, mark that segment Return and verify cargo/deadline because the destination may never be reached.
- When editing sources through PowerShell tooling, use apply_patch because aliases previously overwrote runtime code.

Build SHA256: 5E9BB88ECD59CFC3AB28CE0E69C8BBAF8D8B71D232E14C184A65DC0A132DD99E
