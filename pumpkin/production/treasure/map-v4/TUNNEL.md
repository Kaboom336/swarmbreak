# Meadow v4 tunnel — approved route slice

Design recorded before build. Owner-approved: a west cave **route**, visible from summit camp, two exits, harder than the covered west path. No commit/publish. `guardian-greybox.rbxl` and guardian/Keeper sources are protected.

## Geometry and feel

Source coordinates are X,Z,Y (Roblox X,Y,-Z). Entrance (-76,27,0); near exit (-76,-78,0) at the valley/south cross-link; south exit (-61.867,-98.953,0) on the existing west lane. A 14-stud trunk passes through new chunky west rock from the existing west/north junction; a 14-stud branch forks inside to the south exit. Existing west surface lane remains the fallback and Keeper intercept path. All tunnel endpoints join the route graph. Roof underside >=24 studs, including ceiling ornaments; portals widen only where existing lane junctions require it. Skylight roof gaps, cyan mushrooms, violet crystal pockets and a pale uninterrupted walking strip make the dark rock readable. Props stay outside the audited lane.

## Balance hypotheses — all ESTIMATED, not observed

At 16 studs/s, the direct near-exit trunk is 105 studs / 6.56 s before puddle. The existing west subsection is measured during build. A mandatory 24-stud puddle caps speed at 8 studs/s: 3 s crossing, adding 1.5 s over dry travel. The south branch adds distance. Target tunnel advantage <=3 s, ideally <=1 s after puddle. No money or monetization change.

`TunnelPolicy.luau` is the single source of tuning: width14, ceiling24, normal speed16, mud speed8, mud length24, mud occupancy~3 s; shadow0.7 s, fall0.35 s, impact radius3, knock velocity18, first hazard after1.6 s, normal interval2.4 s, camping threshold8 s, rumble interval0.9 s, exit hold3 s, prediction probability0.60 for the nearest exit. ESTIMATED intended experienced-carrier hazard hit rate20–35%, clean tunnel escape45–60%, guarded-exit share exactly one of two per entry. These are playtest targets, **UNKNOWN measured rates**. Prediction includes uncertainty; no exit is permanently safe. Rivals may pick up a knocked-down acorn immediately. Exit/entrance re-entry within3 s retains the rumble age, preventing doorway timer resets.

Measured geometry, estimated timing: matched west subsection119.066 studs gives7.442 s at16; tunnel105 studs gives6.563 s dry +1.5 s puddle penalty =8.063 s. Near tunnel is **0.621 s slower ESTIMATED**, so saves less than3 s. Hit/escape targets are not used as fabricated measurements. The south branch is longer and has the same unavoidable puddle on a summit-to-exit run.

## Isolated implementation and later Keeper hook

`TunnelPolicy.luau` contains pure region, timing and prediction rules. `TunnelController.luau` owns prototype hazard/slow/rumble/exit handling. Two isolated integration edits in `Links.server.luau`: `TunnelController.attach({getCarrier=..., drop=...})` after its local carry/drop state exists, and a below-roof drop ray in `supportedPosition`. This uses the same acorn and pickup prompt, so rivals retrieve the real dropped object. No duplicate ownership state.

Merge later: Keeper controller calls `TunnelPolicy.inside(root.Position.X, root.Position.Y, root.Position.Z)` to suppress throws; provide `intercept(exitId, surfaceWaypoints, holdSeconds)` to `TunnelController.attach` (entry is detected inside the controller; no public onEntry method). Keeper uses only the retained west surface waypoints, leaps/runs along that short path, then holds one predicted exit. The prototype waits up to14 s, then holds3 s after the thief leaves; this avoids expiring before the slowed thief arrives. Release/restore chase on tunnel exit or wait timeout. The isolated prototype moves the authored Keeper stand-in along those surface waypoints and applies contact knock/drop at the selected exit; it is not the production Keeper AI. The prototype has no throwing system; suppression attribute plus region predicate are the explicit production hook, not evidence of tested production suppression. Existing guardian files are not edited. Dynamic blockers are temporary hazards, never hidden static clearance exceptions.

Prototype-only additional hook: `Links.supportedPosition` uses a ray starting atY10 inside tunnel regions, below the roof, for manual/death/disconnect/test-link drops. This prevents a roof-top acorn. Rumble age and former-thief status persist after dropping inside, so rocks continue threatening that player even without the acorn. Re-entering after the3 s grace begins a new visit; death clears state and restores speed. Red shadow lasts0.7 s before a0.35 s visible fall (impact1.05 s after warning).

Hazard telegraph is locked at the predicted impact position using horizontal velocity × `HazardLeadSeconds=1.05`; simple straight running no longer auto-dodges the shadow. If projection leaves the cave, fall targets the current floor location. Sidestep, stop or reverse after the warning to evade. Ownership handoff/re-pickup starts a new carrying episode/intercept while retaining occupancy age and the visit's exit prediction. Disconnect cancels delayed impact callbacks, restores walk speed and original Keeper art. No runtime success claimed from syntax/policy tests.

## Evidence gates

Re-run exact native geometry check, full-width 20-stud static clearance audit (target0), and `routes-check.py` (target0 dead ends,0 unreachable). Four offline renders: entrance, inside, near exit, south exit. `build-top.jpg` overlays surveyed centerlines on the shipped scene. Independent blind critic checks look and balance against named reference standards. Offline geometry and pure-policy tests do not establish Studio physics, Keeper swept clearance, human dodge rates or multiplayer reliability; those remain UNKNOWN until Studio playtest.

Executed final static checks: **0 clearance violations across57,893 samples;0 graph dead ends;0 unreachable nodes;47 Lune policy/syntax/artifact assertions;25,136 native parts matched within0.0001 stud;2 exit mouth clusters and0 extra mid-branch surface contacts.** `TUNNEL-GEOMETRY.json`, `TUNNEL-TEST.json`, `TUNNEL-EVIDENCE.json`, `TUNNEL-CONTACTS.json`, `collision-audit.json` and `routes-graph.json` hold machine evidence. Added source files are separate tunnel modules; prototype Links changes are limited to adapter and below-roof drop ray. Offline renderer was corrected to honor source transparency rather than falsely render the94%-transparent light shafts as opaque yellow columns.

The guard wait follows the captured entrant's occupancy, including when they drop the acorn; it does not expire merely because ownership becomes empty. Delayed impact checks require the original character/root and a living humanoid, preventing prior-life rocks from hitting a respawn. Built module Sources are compared exactly with current policy/controller files. Evidence includes a fifth view from summit camp toward the entrance. Earlier `build-top.jpg` is preserved as `tunnel-baseline-build-top.jpg` before overlay.

Repeated same-player pickup never restarts an active intercept or draws a waiting Keeper away; visit prediction remains fixed until a full exit. The roof carries irregular stepped rock/moss overburden, and98.5%-transparent narrow light shafts replace the initial wide bars. Trees are preserved; exit views show their real sightline limits.

Final art refinement replaces all full-height pillars/lintel with204 staggered6–9-stud rock courses/facets, offset11–12-stud roof chunks, asymmetrical mouth brow and attached moss. Clear roof underside stays>=24. Light/glow shafts align genuine skylight slots at sourceZ-18/-48. Foundation top is-.15 and new walking/paving slabs lifted.14, avoiding coplanar black floor lattice. Every proof camera is preflighted against actual collidable OBB/Wedge solids. No cave hide state added.

Fork seam repair gives trunk floor/paving deterministic lift.14+.003×segment, branch.17+.003×segment, and branch roof distinct.03+fragment offsets above the24-stud underside. This separates coplanar overlapping junction faces without changing route connectivity or meaningful timing; full-width audit remains0.

Exact two-mouth correction: the old diagonal south-crosslink cut across the tunnel branch mid-way. Its first sampled span now reuses the existing curved west surface near→south (including source(-66.8125,-92.125)), then joins from the actual south mouth to(-22,-100) and the retained cross-link curve. No duplicate west slab/paving is emitted; old first-span slabs and only orphaned cobble/edgings removed. The new across segment has0 whole-prop footprint intrusions. `tunnel-contacts.py` classifies entrance plus exactly2 centerline mouth contacts,0 extras; continuous-body Studio egress remains UNKNOWN. `ExitGuardRadius=12` covers a14-wide mouth/18-wide apron; two exit discs do not overlap, verified by tests.

External merge adapter signature: `intercept(exitId, surfaceWaypoints, holdSeconds, entrant, occupancyEpoch)` may return a cleanup function. It must observe the captured entrant's occupancy, wait at the exit, then clear/restore its own chase after exit/timeout. The controller calls returned cleanup on a new pursuit or detach. Dedupe uses entrant+exit+occupancyEpoch: same-visit re-pickup cannot pull the guard away, but a later full visit invokes the adapter again even for the same player/exit. Four regression assertions exercise those dispatch cases. Detach clears both rumble and guarded-exit attributes.

## Reuse and references

Reuse inspected repository `geometry.py` native-part emitter, `render.py` manifest renderer, `audit.py` OBB audit and `routes-check.py` graph derivation. No external asset/dependency adopted; repository licence governs existing code (no new third-party licence claim). Look bar: existing Meadow v4 chunky rock/lantern vocabulary; mechanic bar: Minecraft caves for clear navigable silhouettes, Fall Guys for readable warning-to-impact timing (comparison targets, no claim of copied code or measured equivalence). Read local `C:/dev/codex-lab/pumpkin-loop/PLAYBOOK.md`; exact Keystone Roblox Process Playbook is unavailable here.

## 2026-10-13 cave LOOK follow-up

The owner rejected the previous interior as a city alley. `tunnel_look.py` now
refines only this route slice using the existing native-part vocabulary: a sealed
rock cap over the route union with two small 3x4-stud skylight cells, sloping rock
ribs and inverted wedge teeth above24, varied angled wall masses, dirt/stone
surface dressing and visible muddy puddles, blue crystal/mushroom colonies,
wall moss/roots, mouth teeth/vines and amber exit lights. Roof art preserves the
24-stud underside; the required distant route opening remains an actual exit.
No new dependency or third-party asset was adopted.

`TunnelPolicy.luau` and `Links.server.luau` remain byte-identical to the prior
tunnel evidence. The only controller change replaces the falling block with an
inverted WedgePart; warning/fall timing, target, ownership/drop, hit radius and
intercept logic remain intact. The latest native build matches25,436 parts within
0.0001stud and passes47 existing assertions. Full-width clearance0 across57,893
samples; graph dead ends0/unreachable0; mouth clusters2/extra contacts0. Guardian
hash remains9bd153ce675b50ca4f1ab796c156872dfe56c97b59955b82d5faed014d5d0ea2.
No commit or publish. Studio runtime and measured gameplay rates remain UNKNOWN.

The five identical player-eye cameras are rerendered from the shipped manifest;
the previous five are retained in `tunnel-look-before/`. `build-tunnel-sbs.jpg`
compares all five before/after pairs. Round1 blind visual critic failed3/10;
its fixes were applied before the final five renders. Final review disposition
is **FAIL5/10**, recorded in `TUNNEL-LOOK-CRITIC.json` and the refreshed
`TUNNEL-EVIDENCE.json`. The interior improved, but the exterior/summit still reads
as a freestanding rock shed. Terrain integration, rectangular teeth and light
props remain unfinished; the requested two blind review rounds are exhausted.
This supersedes the earlier supplemental PASS7/10 below; no current look PASS.

Lesson: When a cave reads as a corridor, change the wall and vault silhouettes
before adding glow props, because repeated straight geometry dominates the read.

## Playtest route

Open `prototype/meadow-v4.rbxl`, pick up the summit acorn, walk to the glowing west cave mouth. Try both exits; verify one Keeper intercept, no throws inside, 0.7 s red floor warning then rock/drop, rival pickup, 3 s puddle crossing, and increased rumble after8 s including rapid doorway re-entry. Compare matched dry-west and tunnel runs with two players. Rates/time advantage remain estimates until that test.

## Current hill revision: look round 2

See `TUNNEL-HILL.md` for the rebuilt grassy landform, native light/crystal changes,
six-view comparison and preservation evidence. Current disposition supersedes
all historical look scores above: **STATIC PASS; LOOK FAIL 6.5/10; RUNTIME UNKNOWN**.
Two new blind critics scored6/10 and6.5/10; the requested7/10 was not reached
within the two-round cap. Current native build matches26,612 parts and passes47
policy/artifact assertions. Full-width clearance0 over57,893 samples; surface prop
audit errors0; graph dead ends0/unreachable0; exit contacts2/extra contacts0.
132 roof centerline samples have0 unplanned gaps, and both skylight shafts are
open through roof and hill. Route data, policy/controller/Links sources and the
starting guardian hash remain equal. No guardian edits, commit or publish.

Lesson: When turf follows a curved hill, tilt it in both directions because
one-axis tiles create repeated ribs. Projecting panel edges remain a visual gap.

## Final evidence status and lessons

**STATIC PASS; supplemental look PASS7/10; RUNTIME PENDING.** Final five offline views18:24:37–18:26:16 and top overlay18:26:41 (2026-10-13 local) were inspected. No large new roof artifact/floor lattice; connected mouths, readable glows/shafts and summit visibility accepted by the supplemental critic. Rectangular mouth/parallel walls and minor recesses remain polish, not a claim of perfect art. Low-bar traversal, humanoid/NPC swept movement, continuous egress, production throw suppression and measured multiplayer hit/escape rates remain UNKNOWN. Guardian hash matches the prior `ROUND5-PROTECTED-HASHES.json`; no guardian edit, commit or publish.

- When adding a route, audit surface contacts as well as dead ends, because a retained cross-link can create an unintended extra exit.
- When joining flat solids, separate coplanar surfaces slightly, because passing clearance does not prevent black rendering artifacts.
- When timing an intercept, retain entrant/occupancy identity through drops, because changing acorn ownership does not mean the thief exited.
