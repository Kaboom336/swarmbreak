# Meadow v4: ordered Studio checks

Open **prototype/guardian-greybox.rbxl** for the session. The canonical
slice-v2/prototype/guardian-greybox.rbxl is byte-identical. No commit or publish.
All Studio outcomes below are **UNKNOWN / NOT RUN** until recorded by the tester.

Look follow-up: lighting A/B, hill dressing and rock variety are documented in
`../treasure/map-v4/LIGHTING.md`; final offline evidence is in LOOK-VERIFY.json
and LOOK-CRITIC.md there. The pre-look place is guardian-greybox.pre-look.rbxl.
All three live test Sources/expectations are preserved. Studio outcomes remain
UNKNOWN / NOT RUN. The historical merge evidence below describes the pre-look map.

## Evidence checked before Meadow v4 delivery (pre-look)

- Verified the original guardian backup by byte equality, successful place deserialization,
  and SHA256: `9bd153ce675b50ca4f1ab796c156872dfe56c97b59955b82d5faed014d5d0ea2`.
  Backup: guardian-greybox.pre-v4.rbxl in this folder.
- Rojo 7.4.4 builds the full game with UseMeadowV4=true. All 32 shipped source
  containers match current project sources after line-ending normalization and
  compile at O0/O1/O2. No standalone Links, Camera, Home stub or prebuilt map is imported.
- Fresh manifest OBB audit plus migrated test centerlines: 60,101 samples,
  zero support/headroom/grade violations; 24-node/37-edge reviewed graph rechecked:
  zero non-goal dead ends and zero unreachable nodes. The graph is reused from the
  identical scene SHA256 `ebc9fbecafd645aed8589cb52711a0bb92586b0c04ab8a633288019615ae9c87`,
  while centerlines are compared independently to runtime RouteData.
- Actual Builder/Loader executed offline: 26,598 retained map parts from the
  26,612-part reviewed source; 11 decorative Keeper parts and 3 decorative acorn
  parts removed. Live guardian/arm/portal handles survive the switch.
- Production Arena floor/drop/safe/outside exercised with manifest raycasts:
  summit Y48, below-roof tunnel drops, both rim banks, ravine floor without teleport,
  and south protected rectangle. Production tunnel callbacks exercised with
  mocked services: retained world origin, shared drop, warning/impact, server-owned
  speed, former-thief rumble, doorway grace, intercept dedupe and detach cleanup.
  Exit contact explicitly passes TunnelGuard at the actual mouth.
- Existing check.luau, keeper-check.luau, kit-check.luau and keeper-clearance.luau pass.
  Standalone verify, 14 ravine assertions and 47 tunnel policy/artifact assertions pass.
  Selene on the eight changed production scripts: zero errors/warnings/parse errors;
  StyLua check passes. No Python executable was available: the OBB audit math was
  ported and rerun in merge-v4-check.luau; no Python audit execution is claimed.
- Current Keeper rig/animations/attacks/projectiles/FX and client Sources, Home art
  geometry/client, and treasure ownership rules match the pre-v4 backup.
  Historical home-art-check and home-round3-check were attempted: their
  old protected-source comparisons FAIL on intentionally changed Traps/Arena.
  Those historical restrictions are superseded for this authorized merge; the
  fresh backup preservation assertions above pass. Their old PASS is not claimed.
- Independent read-only critic found the exit contact/suppression conflict; fixed
  and regression checked. Final reread reported no concrete blocker.
  Runtime pathfinding, continuous sweeps, appearance, performance and balance remain UNKNOWN.

Machine evidence: MERGE-V4-OFFLINE.json, MERGE-V4-KEEPER-SWEEP.json and
MERGE-V4-VERIFY.log (commands, exit codes and final artifact hashes).
Re-run from production with the pinned tools via the script block in
merge-v4-verify.ps1; no execution-policy change is needed.
Reusable repo-native modules were inspected; no external code, assets or licence
dependency was added. Reference bars remain the reviewed Meadow v4 art,
Minecraft cave silhouettes and Fall Guys warning readability; no tested parity claim.

## Run these checks in this exact order

1. **Fresh Play, one player.** Check Workspace.UseMeadowV4=true before Play.
   Wait for GreyboxReady=true on the player. The map is generated under
   Workspace.GREYBOX.SharedIsland.MeadowV4. Confirm one visible Keeper and one
   actionable Golden Acorn; no old island, duplicate acorn, test Keeper or Home stub.
   Coordinate convention: source X,Z,Y becomes local Roblox X,Y,-Z, then add
   world origin (0,76,-360). Camp ground is (-7,48,-99), acorn ground (0,48,-96),
   entry/portal ground (0,0,136), all LOCAL Roblox XYZ. The older MERGE.md Y24
   coordinate is superseded by the reviewed Y48 data. Do not toggle the switch
   during Play: Config/Layout modules are cached; restart Play to test flag-off.

2. **Self-test.** In the SERVER Command Bar run
   `game.ServerScriptService:SetAttribute("GreyboxSelfTest", true)`.
   Require GreyboxSelfTestResult=PASS. This is the coordinate contract,
   not a physics pass. Save the Output log.

3. **Solo loop, three runs.** Set GreyboxLoopTestRuns=3, then
   GreyboxLoopTest=true in SERVER attributes. Wait for the flag to clear and
   require GreyboxLoopTestSuccess=true and PassCount=3. Record Result,
   ExpiryCount, Catches, PortalToPortal and FreshToSteal. Legal 60-second expiries
   are counted separately; require at least one actual secure/place before
   accepting the core loop. If all three expire, record a balance failure even
   if the harness's conservation result is PASS. Verify one physical LootId
   through pickup, legal drop/recovery, automatic south secure and placement.
   This test follows portal -> bridge -> spiral -> camp; carrying follows
   radial -> shelf -> bridge -> protected south boundary.

4. **PvP regression.** With that same player at Home and empty-handed, set
   GreyboxPvpTest=true. Require Success=true, Result=PASS and Handoffs=1.
   The server-created dummy starts at the real camp and walks the spiral,
   fork, west north cross-link and surface lane to the south cave mouth court.
   Confirm real shield expiry, Bump hold, forced drop, settle, contested Grab,
   original LootId/deadline, winner-only secure/place, then the real-time expiry
   regression and empty return. Do not pre-mark Success flags to open entry.
   If a test fails, stop and save its full diagnostic Output before proceeding.

5. **Trap regression.** At Home and empty-handed set GreyboxTrapTest=true.
   Require Success=true and Result=PASS. It uses real v4 floor queries and an
   accelerated clock; confirm at least five legal open-floor fixture points,
   decoy tell/reaction, locked attack preservation, cooldown/caps/cleanup and
   protected/only-route rejection. A narrow cave or bridge must not become
   legal trap floor. Record refusal coordinates if no five points can be found.
   Restart Play after the three modes for manual tests; rerun the two entry
   gates in the fresh server. Each new server legitimately starts NOT RUN.

6. **Walk every route both ways.** Use the segment timing table below.
   First walk empty-handed, then carry. Stopwatch from each authored start
   to finish; record time, catches, stops and missed turns separately.
   Do not compare a paused combat run to a no-pause estimate.
   Walk the full width at turns and every cross-link; check floor lips and camera
   occlusion. Test empty return and automatic secure only within
   spec X[-24,24], Z[-156,-116]; the legacy west safe extension is gone.

7. **Optional ridge jumps.** Follow jump_access to pads at source
   (148,-24,20), (148,-40,22), (148,-56,24). Test both four-stud edge gaps
   in both directions, empty and carrying, three attempts each.
   Carry speed=13.5 and jump height=7.2 are unchanged. Record success count,
   actual takeoff/landing, head strikes and snagging at the retained surface lips.
   Deliberately miss each gap and walk jump_recovery back to the ridge.
   GreyboxLoopTestJumpObserved is not evidence for these v4 jumps:
   the automated v4 loop now uses walking routes; this is the manual jump gate.

8. **Ravine recovery, two players.** Carry across the bridge, then deliberately
   fall at center and near both banks. When local root Y<0 in Freefall within
   the ravine, the SAME acorn drops to the reachable rim. The thief stays in
   the ravine, with no fall teleport/damage; the rival can Grab after the existing
   0.6-second settle. Walk the physical bottom loop to the long ramp at source
   X=-22, then climb toward source Z=-88/-102 and rejoin south lane.
   Measure time from landing to surface; compare the ramp's estimated 8.19 s
   plus the actual bottom approach. Test death/disconnect during carrying,
   dropped acorn expiry, and off-island recovery below local Y=-45 separately.
   Confirm neither fall nor handoff refreshes the 60-second deadline.

9. **Tunnel balance and lifecycle, two real players.** Start with summit pickup.
   Enter at source (-76,27,0); exit through (-76,-78,0), then repeat for
   (-61.867,-98.953,0). Watch one live Keeper leap visibly to the entrance,
   run the retained west surface waypoints at 32 studs/s, then guard exactly
   one predicted exit. Prediction is 60% nearest, not a permanently safe exit.
   Hold is up to 14 s waiting after arrival, shortened to 3 s after the captured
   entrant leaves; dropping inside must not release the guard early.
   Keeper resumes ordinary behavior after hold/timeout; no hidden teleport.
   No lob/fan damage or ordinary Guardian hits while inside. Guarded-mouth
   CONTACT is allowed, uses TunnelGuard and forces a drop; stalactites also
   force the shared drop. Neither uses ordinary first-hit retention; current
   GuardianFirstHitRetains=false remains unchanged. Mercy still governs Keeper contact.
   Confirm rival pickup uses the existing Grab/settle rules; no second carry state.

10. **Tunnel hazards.** Cross the unavoidable 24-stud mud patch at speed <=8:
    estimated 3 s occupancy. Server stumble can slow it further; exiting mud
    restores the currently applicable carry/stumble speed, not a stale speed.
    After 1.6 s carrying inside, observe 0.7 s red warning and 0.35 s falling
    stalactite; impact radius=3 and knock velocity=18. Telegraph leads current
    horizontal motion by 1.05 s; try continue, stop, reverse and sidestep.
    Camp for >8 s, drop inside, and check former-thief rumble continues:
    hazard interval changes 2.4 ->0.9 s. Exit/re-enter within 3 s and verify
    age persists. Stay out >3 s, re-enter and verify a new visit.
    Re-pickup in one visit must not draw a waiting guard away; a full new visit
    must start a new intercept. Test rival handoff, death, respawn and disconnect,
    then leave/re-enter the island: no duplicate hazards or old-life impacts.

11. **Measure the tunnel tradeoff.** Compare identical entrance-to-near-exit
    runs on dry west surface versus tunnel. Surface=119.066 studs; tunnel=105.
    At 16 speed: surface 7.44 s; tunnel 8.06 s including mud.
    At 13.5 carry: surface 8.82 s; tunnel 9.00 s including mud.
    All are ESTIMATES from length/speed. South branch is longer; include only
    the entrance->fork 81 studs plus its 49.30-stud branch, not the whole trunk.
    Record at least 10 experienced carrier attempts per exit, outcomes and
    hit locations; retain counts and denominator. Targets: tunnel advantage <=3 s
    (ideally <=1), hazard hit rate20–35%, clean escape45–60%. These targets are
    hypotheses, not current results; a small trial does not establish stable rates.

12. **Keeper attacks and routes.** On camp, west bends, bridge approach, east
    court and ridge, provoke all four attacks through normal play.
    Lob: two-hand gather/hop, .620 release, .90 flight, readable locked landing.
    Fan: three acorns at one .620 release, .70 flight, readable spread, no hat/hand
    collision. Slam: .80 landing, jumpable amber rim and no repeated hit per victim.
    Dash: .50 planted tell, 24-stud straight commitment at48 speed, wall stop and
    1.55 s stun. Verify current windups, release sockets, recovery, head tracking,
    dust/rings/trails/impact FX and celebration. Record feel/readability as
    tester judgement with clips. Chase all surface routes and both elevations;
    ensure no camp-leash return near the new south/east turns, no cave entry,
    no clipping through props, no stuck loop and no recovery poof while moving.
    Leash=330. Sampled visual walking diameter<=12.727 and height<=11.424;
    largest sampled attack diameter17.836 (slam). Physics navigation body remains
    4x11, AgentRadius2; 18-wide/20-high static lanes do not prove continuous NPC sweeps.

13. **Capture cameras and finish.** Set GreyboxCaptureCams=true in SERVER
    attributes. CaptureCameras retains Home shots; MeadowReferenceCamera now
    uses local XYZ (0,180,320) looking at(0,24,-20), FOV58.
    MeadowSurroundingsCamera is player-eye (0,5.5,130) looking at(0,53,-96),
    FOV70. Capture the named shots below with the real live rig, at low/high
    graphics where relevant. Finally do a 10-minute two-player repeat/leave/
    re-enter soak and record device, frame time, memory and errors. Native map
    parts/lights are not a performance result. Save Output, timings, clips,
    screenshots and pass/fail notes; no publish is needed.

## Route segment stopwatch worksheet

Lengths are measured source centerlines; seconds are ESTIMATED, excluding turns,
holds, attacks, mud, falls and human decisions. Table is not observed walk times.
Tunnel rows below are dry; add 1.50 s at walk16 or1.22 s at carry13.5 for the
single mandatory mud crossing. Use the same origin/sign conversion as step1.

| Route (source name) | Studs measured | Walk at 16 (s, estimated) | Carry at 13.5 (s, estimated) |
|---|---:|---:|---:|
| summit_radial | 30.00 | 1.88 | 2.22 |
| spiral | 196.85 | 12.30 | 14.58 |
| fork_link | 16.59 | 1.04 | 1.23 |
| shelf | 257.89 | 16.12 | 19.10 |
| shelf_link | 53.66 | 3.35 | 3.98 |
| west | 280.72 | 17.55 | 20.79 |
| bridge | 85.30 | 5.33 | 6.32 |
| bridge_south | 76.27 | 4.77 | 5.65 |
| east | 119.41 | 7.46 | 8.84 |
| east_climb | 82.00 | 5.13 | 6.07 |
| east_descent | 136.51 | 8.53 | 10.11 |
| north_crosslink | 160.16 | 10.01 | 11.86 |
| south_crosslink | 133.66 | 8.35 | 9.90 |
| portal_north | 58.95 | 3.68 | 4.37 |
| ravine_ramp | 131.06 | 8.19 | 9.71 |
| ravine_floor_loop | 182.00 | 11.38 | 13.48 |
| jump_access | 122.00 | 7.63 | 9.04 |
| jump_recovery | 90.77 | 5.67 | 6.72 |
| tunnel_trunk | 105.00 | 6.56 | 7.78 |
| tunnel_south | 49.30 | 3.08 | 3.65 |

## Camera shots to capture

| Shot | Local Roblox XYZ camera -> target | Evidence |
|---|---|---|
| Home + Meadow overview | Use HomeReferenceCamera, then MeadowReferenceCamera | old Meadow absent, real Keeper/acorn, full silhouette |
| Portal player eye | (0,5.5,130) -> (0,53,-96) | west oak, east spires, bridge, summit objective |
| Camp toward cave | (0,53.5,-96) -> (-76,5.5,-27) | visible entrance and real live Keeper |
| West mouth | (-76,5.5,-35) -> (-76,5.5,5) | entrance silhouette and readable cave floor |
| Mud + hazard | (-76,5.5,0) -> (-76,5.5,35) | full warning/fall/knock-drop video, rival Grab |
| Near exit | (-76,5.5,62) -> (-76,5.5,90) | one predicted Keeper intercept, contact, resumed chase |
| South exit | (-60,5.5,82) -> (-61.867,5.5,106) | branch egress and same intercept rules |
| Bridge fall + rim | (0,9,0) -> (40,0,24) | original acorn on rim, thief below |
| Ravine ramp eye | (-22,-26.5,0) -> (-22,-20,45) | actual climb-out route, no recovery teleport |
| Ridge jumps | (148,25.5,24) -> (148,27.5,56) | two real gaps, carrying and miss recovery |
| Attack set | normal player camera at camp/west/bridge/east | lob/fan/slam/dash full tell->impact->recovery |

Add world origin (0,76,-360) to every local XYZ camera/target above.
Camera positions are proposed session shots, not inspected Studio screenshots.

## Every test-position / expectation change

- **Solo (LoopTest.run):** v4 Layout adapter replaces old Quick and carry points.
  Approach reverses bridge_south, bridge, fork_link, spiral, radial and ends at
  acorn(0,48,96). Carry uses radial, shelf, shelf_link, bridge, bridge_south,
  ending source(0,-120,0), inside the new safe rectangle. Old hill/gully jump
  detour is removed from this loop; climb remains observed, v4 jumps move to
  step7. Dodge choices become source(0,108,48)/(20,108,48).
  The walking carry recipe does not schedule the old forced Dodge pause;
  GreyboxLoopTestTelegraphObserved is therefore not a v4 acceptance gate.
  Attacks remain active during traversal; explicit attack/dodge acceptance is
  step12, with real-player clips rather than a fabricated observed flag.
  Floor preflight begins 9 studs above the expected root instead of42, keeping
  tunnel/low-floor queries below ceilings. Expiry wait moves old(-4,18,8) to
  source(0,108,48); empty expiry exit uses the same supported v4 carry route.
  Original time/identity/conservation and legal-expiry expectations remain.
- **PvP (LoopTest.pvp):** dummy spawn uses Config.Nest (source0,96,48);
  approach uses exact spiral/fork centerlines, partial north cross-link and
  retained west surface to source(-61.867,-98.953,0). Tester approaches that
  court along reversed south_crosslink from the south portal. Pacing is
  source(-64.423,-95.529,0); mercy/leave source(-66.813,-92.125,0).
  All old fixed(-64,-56)/(-72,-48)/(-68,-52) goals now come from that route
  contract. Return resolves the actual south dock; no legacy west apron.
  Bump/range/settle/shield/mercy/deadline and winner-only assertions remain.
- **Trap (TrapTest.exercise):** v4 fixture search expands X[-150,150],
  source Z[-100,120] from old X[-66,66], Z[0,66]. Rejection fixtures become
  source(0,96),(0,-136),(-24,-136),(148,-40),(0,0),(0,42),(175,60),
  covering nest, safe pad/portal, jump/ravine, junction and edge.
  Actual floor/range/bypass checks and at-least-five legal points remain.
  V4 nest margin uses sourceZ96 instead of32.
- **Server harness/entry:** last-safe/spawn/fallback now sourceZ-136 instead of-58;
  all nest refill/death/disconnect fallback uses Config.Nest. Safe handles and
  dock move to the new south pad; only safe rectangle is used.
  Offline check.luau extraction fixtures now inject Config/Layout explicitly
  for expiry route and fall fallback; old v2 fixture tests still pass.
- **Camera expectations:** Meadow overview position(0,64,132)->(0,180,320),
  target(0,4,-10)->(0,24,-20); surroundings position(0,38,145)->(0,5.5,130),
  target(0,42,-150)->(0,53,-96). Home camera coordinates are preserved.
- Module Sources for Keeper and Home art are preserved; author edits use
  apply_patch. Binary backup/build/copy and machine reports are generated
  artifacts. Original standalone map binary, geometry data and policy remain
  unchanged; production has its own origin-aware tunnel controller.

Lessons: When replacing geometry, migrate gameplay/test coordinates together
because an art switch cannot move ownership or AI anchors. When suppressing cave
throws, identify exit contact separately because a shared hit callback otherwise
blocks the guard. When a historical preservation test rejects an authorized merge,
check the current backup's retained systems rather than calling that old test PASS.
