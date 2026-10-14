# Meadow v4 — Round 3 result

**Static gameplay flow PASS; visual acceptance FAIL after three blind review rounds; Studio gameplay PENDING.**

Updated [meadow-v4.rbxl](../../prototype/meadow-v4.rbxl). New [concept comparison](build-sbs.jpg) and [route plan](build-top.jpg). Complete node/edge audit: [ROUTES-CHECK.md](ROUTES-CHECK.md). Raw source/place/proof hashes: [ROUND3-EVIDENCE.json](ROUND3-EVIDENCE.json). Independent findings: [ROUND3-CRITIC.md](ROUND3-CRITIC.md).

Implemented a 32-stud-deep dark rock gorge on both bridge sides, sparse curved stream and one physical long walkout. The standalone acorn has exclusive pickup, carry/manual drop, fall-point bank drops, and reset/disconnect/test-travel recovery. Falling has no scripted damage, respawn or teleport. Removed isolated recovery ends. West has covered oak canopies; bridge has an exposed timber span and twin beacons; east has raised walking/jump paths, split spires and a rising marker triplet. Warmer purple-grey stone, pale facets, moss, faceted boulder clusters, flower patches and path lanterns use the existing native-part source. Fences border cliffs/ravine.

Checked: **55,474 full-width samples, clearance flags 0; 23 nodes, 37 edges, dead ends 0, unreachable nodes 0.** Maximum grade 24.567 degrees, 20-stud vertical reservation. Final place: 25,359 anchored parts, 121 lights, six compiling Luau containers. Fourteen executed policy assertions pass. Final critic independently reran graph and policy checks; the preceding flow critic independently reran full-width clearance and probed representative rim support.

Centreline traversal at speed16 is ESTIMATED: west 524.2 studs / 32.8s; bridge 405.0 / 25.3s; east 581.3 / 36.3s. Exit ramp alone 131.1 / 8.2s; moving across the bottom adds distance. These are authored geometry distances, not observed player timings or shortest-route measurements.

Remaining visual gaps: the separated east jump pads still read weakly from portal/summit beside the continuous walking road; major cliff faces remain too uniform/rectangular and focal boulder/pale-top variation is below the supplied concept. Both fresh final verdicts and these gaps are retained. The three-round cap ends this iteration; no full visual PASS is claimed.

Proof is an offline Blender render of exported native geometry, not Studio. Concept camera is approximately reconstructed; turned portal/summit views inspect route identity. Runtime fall detection, actual survival/walkout, competing-player retrieval, jumps, animation and device performance remain **UNKNOWN**. [Studio test route](ROUND3-STUDIO-CHECKS.md).

Owner-reported: “the map still needs work”; concept may change for gameplay. Reused inspected project-native authoring/export/render code; no new third-party licence dependency. Best supplied art bar: concept.png; local Steal an Egg study supplies objective-to-safety context. Read the local Roblox playbook; the exact Keystone-titled note was unavailable in checked sources.

Only meadow source/project/build and treasure/map-v4 evidence were written by this task. Guardian scripts and Keeper animation were excluded. Of 24 protected baseline files, guardian-greybox.rbxl changed concurrently during finalization (observed modification 2026-10-13 15:14:11 local; author **UNKNOWN**). Its current file was preserved. No guardian restoration, commit, publish, purchase or external message.

Rebuild: bundled Python `round3.py`, `audit.py`, `routes-check.py`; Rojo build `prototype/meadow-v4.project.json -o prototype/meadow-v4.rbxl`; Lune `verify.luau` and `ravine-test.luau`; Blender `render.py -- rr3final`, `compare.py -- rr3final`; Python `round3-evidence.py`.

Lessons: When ramps join routes, finish the incline before the junction because full-width overlaps create hidden steps. When clearance filters place landmarks, count emitted parts because rejected placements can silently remove them. When jumps define a route, expose their gaps at decision points because an overhead label cannot make them readable.
