# Meadow v4 — Round 2 mountain and valley

**Round 2 historical report. Current Round 3 build, checks and limitations: [ROUND3.md](ROUND3.md); topology: [ROUTES-CHECK.md](ROUTES-CHECK.md).**

Current artifact: [meadow-v4.rbxl](../../prototype/meadow-v4.rbxl). Comparison: [build-sbs.jpg](build-sbs.jpg), supplied concept left / exported geometry right. The old blueprint image is superseded for heights and routes.

OWNER-REPORTED: prior critic 6.5/10; raise the summit, deepen the ravine, wind the paths, strengthen rock mass and match concept framing. CHECKED: existing native-part generator/exporter, source, audit, supplied concept, protected baseline, Roblox production skill and gates. Reused project-authored code and native Parts/WedgeParts; no third-party imports or new licence dependency. The exact Keystone Roblox Process Playbook remains unavailable in checked local sources; its supplied greybox/art/reference rules were applied. Best supplied visual bar: concept.png. The existing local Steal an Egg study supplies objective-to-exit readability context, not a new live ranking.

## Current dimensions

Coordinates **(X,Z,Y)**; north = +Z. Exported Roblox XYZ uses world Z = -spec Z.

| Element | Built geometry |
|---|---|
| Island | 352 × 352 nominal envelope; irregular connected rock land, moss lips and tapered hanging stone underside |
| Summit | (0,108,+48); trimmed 32 × 32 terrace with full central 24 × 24 court, acorn, physical Keeper stand-in, tall banners and fence |
| Shelves | +36/+24/+12/0 eastern switchback; four 12-rise ramps with 28 horizontal run; rounded flat turns and separate tangent pads |
| Spiral | 18-wide, radius 30→50, 270° east→north→west→south, +48→0; flat entry/exit tangents; full solid rock support |
| Fork | (0,42,0), 28 × 28 court, after both summit descents |
| Valley | Irregular east–west -12 floor and tall grey rock walls; two 18-wide recovery routes with narrow winding decorative stone trails |
| Optional bridge | Timber centre at +4, Z[-12,+12], 18-wide collider; 12-run approaches rising 4; railings and red test tells |
| West main | Winding 18-wide continuous ground causeway through ordinary rock cover to independent west portal approach |
| East ridge | +20 crest, 18-wide walking climb/descent; 24 × 24 court at (110,-60,+20); optional three 12 × 12 landings, 4-stud gaps, 2-stud rises, walking access/recovery bypass |
| Portal | (0,-136,0), pad 32 × 24, protected apron 48 × 40; independent west/north/east approaches |
| Background | Far decorative floating windmill, castle, waterfall and wooded islands, outside playable land |

All audited walking envelopes are **18-wide**, never below 12. Full-width static OBB sampling reserves **20 studs headroom**. Maximum ramp **23.199°**, below 25°. Smooth inclined collision supports decorative stones/steps. Every lane has ground support. No mandatory bridge/jump, tunnel, tent, hide state, trap or exit lock. Open cross-links preserve alternatives. Guardian scripts/place and the Keeper animation job are outside this task.

## Route budgets — ESTIMATED

Calculated from exported 3D centreline segments at **16 studs/s**. Start = acorn; end = first protected apron edge. These are not Studio stopwatch results, shortest-path guarantees or combat measurements. Acceleration, turning, carrying and interference are excluded.

Common summit route: 30.0 radial + 196.8 spiral + 16.6 fork link = **243.4 studs**.

| Route | Length, ESTIMATED | Time at 16, ESTIMATED |
|---|---|---|
| West main | 524.2 studs | 32.8 s |
| Centre bridge | 405.0 studs | 25.3 s |
| East walking | 581.3 studs | 36.3 s |
| Shelf walking + west | 622.3 studs | 38.9 s |
| Shelf walking + bridge | 503.1 studs | 31.4 s |

West main: acorn → expanding spiral → fork → winding west rock causeway → west apron. Centre: same summit descent → optional bridge → winding south link → north apron. East: same summit descent → walking ridge climb → +20 court → winding descent → east apron. Shelf variants use the longer shelf ramp bypass and rejoin at the fork.

The main west walk meets **25–35 s**. Doubling shelf rises requires longer ramps: its full walking bypass is now slower than the spiral and is no longer advertised as a quick walk. Optional falls/jump cuts may shorten it; execution time is UNKNOWN. Cross-link and meadow cuts can be shorter. Not every possible route is claimed to meet the main-walk budget.

The existing 60-second item deadline leaves about 27 seconds after the west estimate for interference, excluding the steal interaction; actual contested pacing remains UNKNOWN. No timeout, gameplay or guardian behavior changed.

## Evidence and next check

Static audit: **0 flags / 55,360 full-width samples**. Rojo/Lune artifact integrity and compilation: [ROUND2-ARTIFACT-CHECK.log](ROUND2-ARTIFACT-CHECK.log). Source/place/render linkage, route estimates, protected-file hashes and static portal sight rays: [ROUND2-EVIDENCE.json](ROUND2-EVIDENCE.json). Independent visual reviews: [ROUND2-CRITIC.md](ROUND2-CRITIC.md). Visual acceptance is separate from static PASS.

Proof = offline Blender render of the exported native parts, not a Studio screenshot. The generated concept has no camera metadata; angle, distance and framing were reconstructed approximately. No exact camera calibration is claimed. Existing rest hat geometry fits the 18-wide reservation; animated swept clearance remains UNKNOWN.

UNKNOWN: Studio movement, actual traversal times, cargo camera, animated Keeper clearance/pursuit, multiplayer, fun and device performance. V selects the reconstructed concept camera, B the plan, N the player camera. Open this standalone place for review; no guardian merge or publishing authorized. Protected-file changes from concurrent work were preserved and recorded; this task wrote only the meadow prototype and its evidence folder.

Lessons: When doubling heights, lengthen ramps and keep tangent pads because full-width corners can obstruct lower lanes. When matching a concept, compare the whole frame because fitting the mountain alone can crop distant landmarks. When judging terrain, open the valley view because decoration can conceal the rock silhouette.
