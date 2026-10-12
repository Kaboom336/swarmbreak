# Hand-made guardian island pieces

2026-10-12. PROPOSED construction contract; no models/code created in this pass. Sizes are studs, X width × Y base thickness × Z depth; walking surface is local Y=0, base extends down4. Decoration/guardian height is separate. Pieces are authored once in Studio, then cloned/rotated, never generated terrain or random obstacle soup.

Each template has GroundPivot, In/Out attachments, traversable centerline waypoints, Safe/Danger volumes and visual sockets. Connections below use `(X,Z)` at Y=0. In faces south (-Z), Out north (+Z), except stated turns. Align Out to the next In with opposing outward normals. Clear floor≥12 studs; matched floor heights and no gap/step at joins. Disable colliders/queries on visual-only props. Unused margins are nonwalkable/railed, not shortcuts.

| ID / piece | Size and connections | Authored danger / purpose |
|---|---|---|
| P01 EntryReturn | **32×4×24**; portal `(0,-8)`, In `(0,-12)`, Out `(0,12)`; portal→Out20 | Safe arrival/return pad; exit is this same portal. Guardian stops outside pad. One clear outbound arrow; reverse arrow after steal. No free pumpkin. |
| P02 StraightCover | **32×4×24**; In `(0,-12)`, Out `(0,12)`; route24 | Two staggered cover blocks,≥12-stud bypass. Breaks guardian sight, forces a visible left/right decision. Authored short variant32×4×16 with ports Z±8, route16. |
| P03 LeftTurn | **32×4×32**; In `(0,-16)`, Out `(-16,0)` facing west; rounded centerline radius16, route≈25.1 | One broad corner with sightline window; guardian can follow, cannot attack through inner cover. Leaves return arrow visible from bend. |
| P04 RightTurn | **32×4×32**; In `(0,-16)`, Out `(16,0)` facing east; mirrored radius16 centerline, route≈25.1 | Mirrored navigation choice, same threat/readability contract. Not a random mirror of attached art at runtime. |
| P05 BypassFork | **40×4×32**; In `(0,-16)`, Out `(0,16)`; authored route32 | Two≥12-wide shallow channels reunite around a central block. Sidestep choice, no dead end, reward, second guardian or timed door. Longer geometric route must pass112-stud cap. |
| P06 WideBridge | **32×4×24**; In `(0,-12)`, Out `(0,12)`; route24 | Continuous≥16-wide deck with1.5-high rail; visual void adds urgency, no jump/fall lesson. Short variant32×4×16, ports±8, route16. No guardian shove across rail. |
| P07 GuardianNest | **48×4×48**; In `(0,-24)`, pumpkin anchor `(0,16)`, return via In; route40 | One guardian origin `(12,8)`; one glowing pumpkin at nest, dodge cover at±12. Guardian arena and nest platform are ONE launch piece. No Out: end of sequence. Telegraph, steal hold and chase start here. |
| P08 NestPlatform | **32×4×24**; In `(0,-12)`, nest `(0,8)`; route20, no Out | FUTURE alternative terminal platform, not added to P07 in launch. Requires a separately authored guard-arena connector contract before selection. No extra reward slot or rarity boost from decoration. |
| P09 ExitDock | **32×4×24**; In `(0,-12)`, portal `(0,8)`; route20, no Out | FUTURE one-way escape variant only. Never selected for launch: it would bypass the reverse-path chase. Safe-volume activation must require run completion, not arbitrary touch. |

Launch pool is P01–P07; P08/P09 are designs for later, not a demand to build nine pieces now. Build P01/P02/P06/P07 in the first greybox, add turns/bypass only if that run feels good. All dimensions are hypotheses validated at default camera and touch movement.

## Sequence and deterministic seeds

1. Run is **P01 →1–3 travel pieces →P07**, total3–5 instances. Each run has exactly one start/return portal, guardian and pumpkin. Default4-piece seed is P01/P02/P06/P07, route108. Three-piece shortest is P01/P02/P07, route84. Five-piece examples use three16-stud short travel variants, also108.
2. Select an authored allowed recipe, then variant choices and optional whole-route quarter-turn. Examples: straight/bridge; left/right; right/left; short straight/short bridge/short straight. Rounded turn pairs give20+25.1+25.1+40≈110.3 studs; square-corner32+32 turns would exceed112 and must be rejected. No unconstrained permutation of terminals. P05 is rare alternative for a one-travel-piece recipe after measured centerline bounds pass.
3. Snap connectors; validate the entire path BEFORE teleporting a player: route84–112, floor continuous, return reachable, envelope≤96×144, width≥12, no self-intersection/nonadjacent floor shortcut, covers/guardian clear, only one terminal reward. Turn pairs must remain in bounds. Check actual centerline length, not only bounding boxes.
4. Reject invalid recipes deterministically, max8 attempts, then known-safe108-stud default. Never make player wait on regeneration. Record rejection reason; do not silently ship a pool that always falls back.
5. Server creates seed from session seed + assigned slot + server run counter + island ID + difficulty + recipeVersion. Fixed seed produces same recipe, transforms and guardian waypoints. Use a separate reward RNG/state; geometry retries never reroll prizes. Clients cannot choose seeds/rewards or claim another slot.
6. Freeze seed, recipeVersion, difficulty, eventVersion and outcome at run creation (first-run guarantee overrides outcome; limited eligibility locks at successful steal). Record actual seed in QA evidence. Destroy/regenerate only after home return or recovery cleanup; connected players/cargo prevent replacement.
7. First run uses one known easy4-piece recipe. Following runs vary the recipe; after3 completed escapes, Standard is available through the SAME portal interaction. Easy remains available. No daily rotations or shared public queue.

## Difficulty and future island scaling

| Preset | Geometry | Guardian proposal | Reward proposal |
|---|---|---|---|
| First/Easy | 3–4 pieces,≥16-wide safe travel; max1 turn pair; no required jump | 1 guardian; warning1.2s, head start1.2s, chase.88×carrier speed, catch3.5; catch retains item | First Pup Common guaranteed; later Common80%/Rare20%, Pup/Crow equally within tier |
| Standard island1 | 4–5 pieces, width≥12; more sightline cover, total≤112 | Same guardian, warning1.2s/head start1.2s; chase.92×carrier speed; bounded pursuit, same mercy | Common60%/Rare40%; rates remain those in SLICE-V2 |
| Future island2+ | Separate approved palette/guardian, later jump/fight pieces by explicit update | More demanding timing/behaviors, still fair telegraphs; not implemented here | Tier ceiling and odds rise per island table; preview has NO rolls |

Danger belongs to one guardian, never surprise traps on every piece. Dodge = change position around visible cover/telegraphed approach; no dash cooldown to learn. Validate guardian traversal both ways on every enabled recipe. A loop with no meaningful dodge is a failed greybox even if the stopwatch passes.

## QA and art contracts

- Sweep50 fixed seeds per active difficulty with connector/bounds/reachability checks; then walk at least10 distinct valid layouts forward AND back in Studio. Include a turn pair, longest path, shortest path, fallback and repeated seed. Static geometry alone does not prove NPC navigation.
- Test two concurrent runs have independent state; eight slots each preserve their recipe when someone else escapes, quits or reruns. Return portal cannot be used to award more than once; home cannot start a second run while cargo/recovery is unresolved.
- Plain parts in T1; final route collision stays the same beneath authored visual shells. Swap only tagged sky/palette/props/variant sockets; no seasonal collider or connector changes. Winter snow is visual-only and never hides telegraphs.
- Compare one decorated route/guardian camera to Steal an Egg; home/portal to BGSI; nest/pet reveal to PS99. Independent review and Zion check precede extra visual variants. No reference image is imported as world art.
