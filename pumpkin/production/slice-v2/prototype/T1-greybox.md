# T1 v2 greybox — ARENA-1013 deadline revision

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
