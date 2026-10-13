# T1 island v2 greybox — 2026-10-12

Implemented and rebuilt `guardian-greybox.rbxl` after reading all of ISLAND-V2.md, the previous T1 notes and scripts. Plain parts/UI only. No art, commit or publish. All task edits stay in this prototype folder; unrelated working-tree changes were left alone.

**CHECKED round 5:** three guardian seeds (101, 202, 303), all eight files compile O0/O1/O2, StyLua format/check, Selene (0 errors/warnings/parse errors), exact Rojo 7.4.4 build, binary source/gate checks, existing 50-seed routes and production PvP/item conservation PASS. **OWNER-REPORTED round-4 Studio:** Loop still FAIL; guardian stranded on west hill. **Round-5 Studio: NOT RUN / UNKNOWN.**

## Studio test round 5 - current build

**OWNER-REPORTED new diagnosis:** Guardian at world (455.7,14.0,5.9), arena-local (-44.3,14.0,5.9), after following the carrying player up the west hill. Carrier reached local (-0.4..2.7,3.45,8); no normal telegraph within 8s. This supersedes round 4's incomplete acquisition-only diagnosis.

**CHECKED code:** chase had no camp leash, patrol included a distant south waypoint, and failed/blocked/unfinished paths had no bounded recovery. Existing prototype code reused; no dependency or licence change. Only Arena.luau, check.luau, this note, verification.log and the requested rebuilt rbxl were edited for round 5. LoopTest, geometry and Config unchanged; no commit/publish.

- Camp is local (8,4,32), guardian centre (8,9.5,32). A 32-stud horizontal camp leash bounds chase, Search movement and all patrol waypoints. A step beyond it is refused. Already outside it enters Return immediately; two seconds without meaningful navigation progress also enters Return. Return tries normal pathfinding, then resets this NPC to its authored camp after at most 2.5s if navigation fails. Thus off-area recovery is bounded to 2.5s; stuck-path recovery to 4.5s, excluding an already planted 1.2s windup. Player movement/test deadlines are unchanged.
- Carrier detection and throws share 56-stud range. Upper-body raycast from guardian centre +3 to player root +2 clears small cover tops; tall walls and terrain still block it. Valid throw positions wait for mercy/cooldown without counting that wait as stuck. Projectile collision/interception remains unchanged. Warning 1.2s, throw telegraph 1.2s, 4s cooldown and 8s test limit preserved.
- Stale asynchronous paths are discarded after warn/return/reset, and path creation/compute errors cannot leave the computing flag stuck after the callback finishes. `[GreyboxGuardian] state=... pos=... target=... range=... reason=...` logs state transitions, including Return and Throw. Positions are arena-local; range is actual 3D distance or -1 without a target.
- Offline checks execute production Arena.tick with Roblox value types, generated terrain/cover samples and frozen navigation. Each of seeds **101, 202, 303** checks both reported lane endpoints from the actual hill pose, including a spent 4s cooldown, and requires a camp return plus normal red-disc throw before 8s. Each also checks failed navigation, an outward waypoint at the leash boundary, 18 terrace/lane Patrol/Search cases (throws within 3s), slope throws, low-cover tops versus tall walls, carrier priority, and negative sight/hide/Home/safe/range/mercy cases. The old 24-stud acquisition stall still reproduces. Lune's offline guardian proxy derives Position from CFrame to match Studio semantics; offline results are not navmesh/engine physics evidence.

**UNKNOWN:** rebuilt real Studio Loop/PvP, live hill navigation, line-of-sight and projectile collision, replication and feel. Both binary gates remain NOT RUN/false. Open the rebuilt `guardian-greybox.rbxl` in fresh Studio Play; run Loop then PvP using the commands below. See `verification.log` for checked output.

Reference comparison: **Steal an Egg** remains the guarded pickup/return reference: readable warning and a ranged throw should continue after an escape detour. This build adds bounded camp recovery where the previous build could remain on the hill. No played side-by-side comparison or independent runtime critic pass is claimed. Exact Keystone Roblox Process Playbook remains unavailable in searched local files/exposed tools; supplied rules and Roblox production skill applied.

Lessons: When chase can follow terrain, leash it to camp and bound path recovery because acquisition fixes cannot repair a stranded NPC. When an AI waits for cooldown, suspend navigation-stuck timing because intentional waiting is not a failed path. When offline value types omit engine property coupling, model that coupling because a CFrame reset must change observed Position.

## Historical Studio test round 4


**OWNER-REPORTED:** `GreyboxPvpTest` PASS (legal Bump/drop/settle/Grab/secure/place with dummy carrier; no duplicate/lost). `GreyboxLoopTest` completed Steal, the jump set, carrying hill climb and west return lane, then failed at `GreyboxLoopTestRunner:281: no normal throw/telegraph >8s`. Carrier stood near island-relative (-0.5..2, 3.45, 8), shield=0, mercy=0, without a red telegraph.

**CHECKED code cause:** new-target detection was limited to 24 studs while normal throws allow 12-36 studs. Camp guardian centre (8,9.5,32) puts that lane beyond 24 studs; even centre (0,7,32) to (0,3.45,8) is just outside 24. After hill sight loss and Search expiry, an open carrier could therefore be throwable but never reacquired without successful patrol movement. Carrier preference applied only after the visibility/detection filter. **INFERRED:** this explains the reported live stall; the exact live guardian pose/state was not captured.

- Visible Run carriers now acquire throughout the existing 36-stud throw range, using the same range constant as throw eligibility. Empty-handed detection stays at 24 studs. Existing 1.2s warning, target lock/preference, sight-loss Search, cover/hide, safe apron/disc rejection, mercy, close pokes, planted windup and 4s throw cooldown stay intact. No geometry, runner, LootRules or config edits; the test still fails after 8s.
- Offline regression loads actual `Arena.tick` and attack code with Roblox value types, scalar ray samples against the authored terrace/ramp/cover recipe, and frozen navigation. Restoring the old 24-stud filter reproduces no throw through 8s. All 18 combinations of three camp poses, three reported lane X positions and Patrol/Search start a normal red-disc throw within 3s when mercy/cooldown are ready. Carrier priority over a closer empty-handed target and sight reacquisition pass.
- Negative checks preserve empty-handed aggro, blocked sight, hidden/Home/safe/out-of-range exclusions, mercy and cooldown. A just-spent cooldown still blocks through 3s and reopens at 4s; this is deliberately preserved rather than bypassed to force the timing target. Close range still produces the existing poke. Sight sampling is offline evidence; live engine raycasts/navmesh/replication remain UNKNOWN.

**CHECKED:** eight files compile O0/O1/O2; StyLua format/check PASS; Selene 0 errors/warnings/parse errors; exact Rojo 7.4.4 build PASS; binary source matching and initial NOT RUN/false gates PASS; existing 50-seed route and PvP/item conservation checks PASS. See `verification.log`. Only this prototype folder edited; no commit or publish. Open the rebuilt `guardian-greybox.rbxl` in fresh Studio Play and rerun Loop first, then PvP. The previous owner-reported PvP PASS is retained as evidence for the prior build, not stamped onto this binary.

Reference comparison: **Steal an Egg** remains the guarded pickup/return reference. A visible carrier inside the guardian's actionable throw range should receive readable warning and a locked red disc; the previous detection gap prevented that. Existing code reused, no new dependency/licence. No played reference comparison or independent Studio critic pass is claimed. Exact Keystone Roblox Process Playbook remains unavailable in the local files/exposed tools; supplied greybox rules and Roblox production skill applied.

Lesson: When attack range exceeds acquisition range, align acquisition for priority targets because otherwise valid attacks depend on navigation closing the gap. When diagnosing AI after a terrain detour, freeze navigation in a regression because target reacquisition must work independently of pathfinding.

## Historical Studio test round 3

**OWNER-REPORTED:** real Studio completed portal, nest, camp descent, throw/disc dodge, central/west lanes and carrying ridge steps 4-10, then circled near (-22..-26, 3.45, -10..-14) until `Walk east of jump gully` timed out. **CHECKED:** guardian/arm collision is disabled and the driver already uses Humanoid:Move, not MoveTo. Scalar geometry does not identify a wall at the old (-24,0,-12) goal. **INFERRED:** endpoint oscillation around the former 0.35-stud tolerance is plausible; exact Studio cause remains UNKNOWN.

- Preflight Home endpoints at test start, then all island endpoints/takeoffs immediately after enterRun creates the arena, before island walking or Steal. Raycast down against anchored collidable geometry, require a walkable normal (at most 25.1 degrees), reject wrong floor heights, sample a 3-stud-radius disk at half-stud spacing and cast upward for body/head clearance. Print every BAD WAYPOINT with name, position and reason before asserting. Every walk rechecks and targets measured floor Y + 3. Dynamic recovery tries the same loot socket and nearby verified points within Grab range. Launch lips require grounded center support and obstacle clearance while allowing lower recovery floor beside their edge.
- One escape: Steal, south camp descent, east-side jump approach, JumpLanding, Stone2, Stone1, west ground, west hill ascent/opposite descent, central throw lane, one locked-disc dodge, cyan auto-secure, own-pen Place. Four short hops cross ONE stepping-stone set east-to-west toward the hill. Each sets Humanoid.Jump/Jumping at a grounded takeoff marker and requires observed airborne/landed states. No second island tour or deliberate gully drop. Natural legal drops still recover through settle/Grab.
- Grounded arrival tolerance is 0.8 studs. Preserve >8s no-progress and >30s waypoint limits, readiness bounds, production actions and LOOT identity/state/physical-block audits. Progress adds resolved goal, distance and no-progress duration. No teleport, immunity, production rules/config/arena geometry change.
- PvP court moves to (-62,0,-56), two studs from the nominal dummy position, leaving margin within the actual 4-stud Bump range after endpoint tolerance. Dummy cover lane uses X=-20 for 3-stud obstacle clearance. Shared scalar PvP routes cover tester/dummy approach, shield pacing, mercy movement, former-carrier departure and winner return.

**CHECKED round 3:** eight files compile O0/O1/O2; StyLua format/check PASS; Selene 0 errors/warnings/parse errors; exact Rojo 7.4.4 build PASS; binary sources/gates PASS. Fifty seeds pass solo/PvP endpoint clearance, grounded takeoff/run-up and walking-segment checks. Negative points reject inside-cover, insufficient-clearance and wrong-height cases. Offline PvP loads the actual production server eligibility function with mocked roots/sight/safe geometry and real LootRules: range/height/sight/arena/safe refusals, shield/mercy, hold-completion range revalidation, Bump/drop/settle, contested/replayed Grab, winner secure/place and stable ID/time all PASS. [Lune load documentation](https://lune-org.github.io/docs/api-reference/luau/) and [Roblox casts](https://create.roblox.com/docs/reference/engine/classes/WorldRoot) checked.

**MEASURED:** fixed-recipe authored nest-to-cyan route is **368.62 studs**, previously **559.63**, excluding Home travel, pad approach, recovery and takeoff deviations. This is still a coverage route requiring stones and a hill; it is longer than the quick player escape. **UNKNOWN:** rebuilt Studio solo/PvP PASS, live raycasts/jumps/navmesh/AFK heartbeat, replication and pacing. Offline PvP is a logic check, not full live Test.pvp execution. Both rebuilt runtime gates remain NOT RUN/false.

Reference comparison: **Steal an Egg** remains the guarded pickup/return reference. Previous automation doubled back across the island; this test uses one carrying escape through one stone set and one hill. No new visual/feel or independent Studio critic pass is claimed. Existing code reused; no new dependency/licence. Exact Keystone Roblox Process Playbook remains unavailable in local search/exposed tools; supplied greybox/core-loop rules and Roblox production skill applied.

Lessons: When a runner circles a tiny goal, allow grounded arrival tolerance because momentum can defeat exact arrival. When authoring test targets, measure floors and clearance because center points miss nearby cover and ledges. When checking PvP offline, execute production eligibility because permissive callbacks miss range/sight/safe failures.

## Historical fix round 2 of 2 ? Studio failures

**OWNER-REPORTED:** Loop stalled >8s at `Walk takeoff 4 gap`, with a ground Grab prompt appearing. PvP refused Bump with `carrier/Taken` after the tester approached the dummy. These are real Studio Play failures; the rebuilt tests have not yet been rerun there.

**CHECKED:** production Bump target selection and Rules.eligible/finish keep the required empty hands, carried active item, same arena, 4-stud range, sight, safe apron, shield and mercy checks. No LootRules/config/arena geometry changes were needed. The dummy has ordinary actor flags and production heartbeat handling. Existing code was reused; no new dependency or licence.

**INFERRED causes:** the takeoff requested 0.3-stud precision while Humanoid:MoveTo ends about one stud short; the tester arrival tolerance could also leave actual Bump distance above 4. The dummy waited unattended during a long player approach, allowing the production 10s idle + 2s warning drop. The ground prompt confirms Dropped state was visible, but does not identify whether its cause was hit, fall or idle. New diagnostics distinguish these events.

- Drive the runner with server-owned Humanoid:Move and a 0.35-stud endpoint, slowing at endpoints. Run continuously from JumpStart/Stone1 toward each landing and set Jump=true/Jumping at the grounded takeoff edge (-37.5 Z / -49.2 X). Wait for normal stumble/ground readiness; require observed takeoff and landing. The west walk-around remains a grounded route to JumpStart, before the jump run-up. No obstacle teleport or gap/jump-height change.
- Put the tester at the remote contest court before spawning/picking up with the dummy. Keep ordinary shield expiry/mercy pacing, recover legal drops with settle then fresh production Grab, and assert actual root distance and dummy item ownership before Bump. No immunity/AFK bypass or forged target.
- Recover legal solo drops between route steps through the same settle/Grab path. Check the original active item ID and firstPickup timestamp, audit throughout, and still require exactly one placed physical block. Unexpected lost/taken/retired loot still fails.
- Every step, action hold, arrival, once-per-second movement progress, hit/drop and result prints player position, carried flag/ID/state and active item state; PvP includes the dummy too. Positions are island-relative during Run and world coordinates at Home. Include floor, speed and remaining shield/mercy. Failure snapshot prints before dummy cleanup.
- Extend 50-seed route checks to validate grounded takeoff floors, 2.5?6-stud run-ups and their ordering independently of airborne segments.

**CHECKED round 2:** eight files compile at O0/O1/O2; StyLua format/check pass; Selene 0 errors/warnings/parse errors; exact Rojo 7.4.4 build passes; Lune rules/layout/grounded-run-up/binary checks pass. Gates remain NOT RUN/false in the rebuilt binary. **UNKNOWN:** real Studio jump physics and both rebuilt runtime PASS results. Run the commands below in fresh Studio Play; do not promote static success to runtime acceptance.

Reference comparison: the existing guarded-return loop from **Steal an Egg** remains the target; round 2 repairs automation reliability and does not establish a new visual/feel pass. No independent Studio critic pass is claimed.

Lessons: When a test needs edge precision, use continuous direction movement because MoveTo has a stopping tolerance. When two actors are driven serially, position the waiting actor before pickup because production AFK rules still run. When LOOT legally drops, recover the same ID through Grab because conservation is about identity/state, not uninterrupted carrying.

## Implemented

- One frozen arena ID/difficulty/seed for up to eight members, one guardian and one provisional item. Late join grants arrival mercy. Existing home, eight pens, portals, E/controller X/touch/native prompts, action button and ServerScriptService.GreyboxSeed remain.
- Nine native chunk models: fixed I01 entry/I02 camp, I03/I04 hill sockets, I06 jumps/recovery, I08 cover, I09 log, I10 bushes, I11 twin bridges. Ground-port attachments carry widths/orientations. Two 8/10-high hills with opposing 12-wide ramps, three walking routes/two cross-links, optional 4/6 edge gaps, low stones/ledges, two gully exits and ramped bridge decks. Normal escape never requires jumping.
- Fixed first Easy recipe; bounded seeded hill swaps/cover variants (six distinct collision recipes across 50 seeds). At most eight retries, logged rejection, fixed fallback. No reshuffle while occupants/provisional loot remain; abandoned empty arenas retire without an award.
- One glowing block per item ID. **GreyboxConfig.ItemName** is the sole display-name value. Move that same block through Nest → Carried → Dropped → Carried → Secured → Placed. Carried captions are nearby and occluded, not server-wide reveals through hills.
- Guardian patrol uses non-jumping navmesh paths; actual surface-height movement rejects walls/cliff cuts. Visible detection, amber `!`, 1.2s head-start/warn, carrier preference/target lock, sight-loss search/`?`, raised arm, planted arcing throws, locked outlined/filling 8-diameter red discs, collision interception and protected-disc rejection. Close/log-opening pokes warn and validate actual sight/range; no overlapping windups.
- Hits stumble 0.6s and knock back at most 3.5 studs; shared 3s mercy prevents repeat hits/drop/hostile holds. First carrying guardian hit before a player's first escape retains loot once, surviving reset/re-entry. Later hits drop to validated danger-floor sockets, bounce/settle 0.6s. No death, ragdoll, rolling loot or safe-apron attacks.
- Steal 1s, Bump 0.4s, Grab 0.4s. Server holds identity/target/version/timing. Bump requires empty hands, same arena, ≤4 root distance, ≤3 vertical separation and sight throughout sampled validation. Every attempt cools down 2s; Bump drops rather than grants. Settled ground holds have one atomic winner. Mercy permits ground Grabs; players cannot body block one another.
- Once-only 12s FIRST RUN PvP shield; hide stop/occupancy/expiry/re-hide rules; moving/jumping leaves hide. Already airborne rocks and legal rivals can still hit. Log has avatar clearance/two openings. Outside-combat idle 10s → warning 2s → same-item drop.
- Cyan apron crossing atomically secures cargo and transfers its winner home. First-pickup timestamp/base placeholder freezes through handoffs; only the secured winner consumes the first-Pup placeholder flag. New nest ID after 3s if entrants remain. Reset/disconnect/fall drops provisional cargo; only secured cargo recovers home. No economy, persistent saves or actual Pup reward/art is built in T1.

## Explicit geometry changes and gaps

The design permits 120–160 across; this build uses **160×160**. Hills move to ±48 instead of proposed ±40 to open joins. Camp `(0,32)` and entry `(0,-58)` stay fixed. Cover court moves south and twin bridges north to clear route joins. I11 is **36×32**: two 12-wide decks plus 10 separation cannot fit the proposed 32-wide footprint.

Static waypoint lengths excluding pad-to-first-point approach: Quick **70.65**, Ridge **201.65**, Grove **256.22** studs. Quick from pad centre is **90.65**. **Side routes exceed the proposed 110–130 budgets** and need shortening after real traversal. No pacing/fun pass is claimed. General route samples check centre floors and 1.5-stud cover clearance. Round-3 test endpoints additionally sample a 3-stud radius; full corridor width, live avatar/cargo clearance and navmesh reachability remain unverified.

Explicit height mode: UseJumpPower=false; walking/carrying JumpHeight=7.2, speeds 16/15, gravity 196.2. Easy chase ratio 0.88, one 1.2s throw, ≥4s between windup starts. Carry height 6.0 remains disabled pending live passes. Standard/future tiers are not built.

## Runtime gates

Open this rbxl in Studio. Start a fresh **Play** with a player, not Run, and wait for character/client readiness. Do not move or press actions during the tests. Use **Server** Explorer/Command Bar, sequentially:

```luau
game:GetService("ServerScriptService"):SetAttribute("GreyboxLoopTest", true)
-- Wait for PASS / GreyboxLoopTestSuccess=true before the next command.
game:GetService("ServerScriptService"):SetAttribute("GreyboxPvpTest", true)
```

Loop requires an unused first-player state; PvP can follow it in the same session. Run Loop first. On FAIL, stop Play, fix/rebuild and retry fresh. Do not bypass owner gates with attribute edits.

**GreyboxLoopTest:** waypoint preflight; real Humanoid movement to camp; normal Steal; cross ONE stone set east-to-west with grounded launch markers and observed takeoff/landing; carrying west ridge ascent/opposite descent; observe a newly targeted normal throw and dodge its locked disc; cyan auto-return; own-pen Place. Recover naturally dropped same-ID loot through settle/Grab. Reject repeated steal/return/place and require exactly one physical placed block. Require chase movement and a normal throw. No obstacle teleports. Controls/network ownership restore on finish.

**GreyboxPvpTest:** a test-only plain-part Humanoid dummy takes real nest loot through the production hold, walks to a contest court, naturally expires its once-only shield, and moves while waiting out impact mercy when needed. Player completes Bump → same-item drop → settle → fresh Grab → secure → place. Check precharge/repeat rejection, stable ID/first-pickup timestamp, empty former-carrier hands and physical conservation. This is a dummy-carrier test, **not two-client replication evidence**. Offline rules checks additionally exercise competing simultaneous holds.

Both modes fail on stuck >8s, waypoint >30s, missing character/arena, refused legal action, absent required throw/jump/chase evidence, duplication or loss. Ready/nest/telegraph/handoff-window waits have 8s bounds. Deliberately illegal/replayed actions must be refused.

Results on **ServerScriptService**, plus `[GreyboxLoopTest]` / `[GreyboxPvpTest]` Output:

- Each mode: trigger boolean, `<mode>Result` (NOT RUN/RUNNING/PASS:…/FAIL:…), `<mode>Success`.
- Loop: FreshToSteal (server join → pickup, including time before trigger), PortalToPortal, Catches, JumpObserved, ClimbObserved, TelegraphObserved.
- PvP: ItemId, Handoffs. GreyboxConservation audits records and actual blocks; a failure invalidates both gates.
- SharedIsland attributes: Seed, RecipeVersion, ArenaId, Difficulty, TelegraphStarted, LastImpactAt/Delay.

## Local verification

Eight Luau files compile at O0/O1/O2. StyLua format/check PASS; Selene **0 errors, 0 warnings, 0 parse errors**. Rojo 7.4.4 rebuilds with the required command from this folder:

```powershell
& C:/Users/zerha/.rokit/tool-storage/rojo-rbx/rojo/7.4.4/rojo.exe build greybox.project.json -o guardian-greybox.rbxl
& C:/Users/zerha/.rokit/tool-storage/lune-org/lune/0.10.5/lune.exe run check.luau
& C:/Users/zerha/.rokit/tool-storage/johnnymorganz/stylua/2.0.2/stylua.exe --check .
& C:/Users/zerha/.rokit/tool-storage/kampfkarren/selene/0.31.0/selene.exe .
```

Lune deserializes the binary and verifies matching server/client/config/layout/rules/arena/test sources and both gates initially NOT RUN/false. Fifty seeds check replay, fixed terminals, chunk footprints/nonoverlap, ramp slopes, gap sizes, sampled walking floors, cover clearance, cross-links and the actual typed carrying-test route. Negative layouts reject overlap/steep slopes. Rules checks cover contested nest/Grab winners, short holds, Bump/drop/settle, cancelled-attempt cooldown, shared mercy, reset protections, winner-only secure/place and deliberate duplication/loss corruption.

Build SHA256: **28BF5CC4B7A38553C98072375C6E486792B530F744251D3D43A9E9FEE42C74DD**. See `verification.log` for the final tool output.

**UNKNOWN / NOT RUN:** rebuilt Studio solo/PvP PASS results, guardian hill navigation, 10 distinct carrying walks, hit/drop/cover interception demonstrations, hide opening feel, 2/4/8 actual clients, network races, reset/disconnect/fall under load, native E/X/touch, phone performance and 9:16 clips. Static PASS is not physics or owner acceptance.

Supplied offline reference comparison: **Steal an Egg** sets guarded pickup/return clarity; v2 keeps one item/portal but has overlong side trips. **Steal and Hide** sets log → HIDDEN → `?`; that state/geometry exists, feel untested. **Catastrophic Horse Racing** sets readable anticipation; red disc/arc exists, phone readability untested. No played/visual comparison, independent runtime critic or owner acceptance is claimed. Exact Keystone Roblox Process Playbook was unavailable in the local search/exposed tools; supplied greybox/core-loop rules and Roblox production skill/gates were applied. Existing prototype code was reused; no external kit/new licence dependency.

Official APIs checked: [WorldRoot casts](https://create.roblox.com/docs/reference/engine/classes/WorldRoot), [Humanoid](https://create.roblox.com/docs/reference/engine/classes/Humanoid), [network ownership](https://create.roblox.com/docs/physics/network-ownership).

Lessons:

- When one item changes hands, keep one ID/block and commit at safety because provisional holders must not duplicate rewards.
- When terrain changes, audit the actual runner's path because footprint checks missed blocked joins.
- When proposed widths conflict, calculate collision space first because two 12-wide decks plus 10 separation cannot fit in 32.
