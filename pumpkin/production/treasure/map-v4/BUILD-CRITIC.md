# Independent build critics

**Historical reviews below. Current redo review and source evidence are tracked in [REDO.md](REDO.md).**

Each critic received only artifact/reference pointers and the acceptance criteria, without implementer explanations. These are independent Codex reviewers; no Claude session or Studio playtest was claimed. Prior concept review `CRITIC.md` is preserved.

## Round 0 — FAIL, 2/10

Checked concept, v2 Meadow, both build-r0 images and MAP-V4.

1. Broken-looking paths: black strips, exposed grids and overlapping junctions dominate both views.
2. Flat slab terrain: sparse blocks and broad empty lawn replace chunky cliffs, grassy ledges and sculpted summit/valley.
3. Missing atmosphere: pale vegetation, tiny unlit lanterns, sparse fences and blank background.

Worst gap: black path borders and tangled fork intersections. Correction1 changed lifted surfaces, export/render shape handling and visible cliff art; r1 provides the next reviewed proof. Studio appearance, dimensions and traversal are not proven by pictures.

## Round 1 — FAIL, 3/10

Checked both references, both build-r1 renders and MAP-V4. Trees, fences, lanterns, cyan portal and background islands exist, but the scene still reads as a decorated greybox.

1. Flat square slab and plain grey sides replace irregular layered cliffs and dense grass edges.
2. Bright grid paving and black triangular fork gaps; ramps appear suspended.
3. Sparse props, pale grass and tiny lanterns lose lush vegetation, warm glow and strong cyan/gold landmarks.

Worst gap: terrain silhouette and surfaces. Correction2 removed the giant coplanar base face, stepped the outside footprint, exposed small rock faces, added moss/grass lips, richer turf and irregular cobbles, and strengthened background skirts. Final static geometry was subsequently repaired at ridge transitions. The proof uses the same manifest as the Rojo place.

## Final fresh review — FAIL, 5/10

Independent critic checked r3 concept/top views, both references, MAP-V4, scene manifest, collision audit and merge instructions. The audit hash matches the source manifest. A follow-up inspected the final r4 perspective image and unchanged north-up view: visual score remains5/10, acceptance FAIL, Studio PENDING.

1. Full-width clearance fails:37 shelf obstruction samples and16 nominal surface differences remain.
2. Broad flat lawn and small rear mound miss the reference's substantial tiered cliff silhouette; exposed raised paths reveal construction.
3. Trees/fences/lanterns/portal/backgrounds are present, but paving remains too regular and visual richness remains below the supplied art.

The critic confirmed declared ±176 envelope, summit(0,108,24),18-wide routes,32×32 fork,24×24 ridge/cross-link courts,12×12 landings and correct protected rectangle. Maximum sampled authored ramp grade is24.775°. The32×32 bounding camp has trimmed corners, not a full rectangular terrace. Shelf walking centreline is159.872 studs; the original84–123 design budget is superseded by measured geometry and must not be repeated as a built measurement. Guardian isolation was documented; the critic did not independently audit concurrent file history.

Final proof is `build-r4-concept.png`, `build-r4-top.png` and `build-sbs.jpg`. Camera reconstruction is approximate because the approved generated concept has no camera metadata. The improved perspective is a proof-view adjustment, not a geometry correction or a claim that visual acceptance passed.

## Runtime and acceptance

Runtime appearance, shortest traversal, jumps, Keeper pathfinding, animated clearance and fun remain PENDING. A score is a visual opinion, not a gameplay or collision PASS. The strict audit currently FAILS the shelf overlaps documented in BUILD.md. No task acceptance is inferred from completing two correction rounds.

Lessons: When comparing to approved art, match the camera because high plan views hide missing cliff depth. When terrain layering is the reference's main appeal, build its structure first because scattered props cannot supply that depth.
