# Meadow R5 — static PASS, visual FAIL

**Built; three blind reviews completed. Final underside 6/10, placement 4/10, overall 4.5/10.** The silhouette improved, but the map remains below the supplied Meadow art reference. Studio behavior and performance are UNKNOWN. No fourth round, commit, publish or protected-file edits.

Open [meadow-v4.rbxl](../../prototype/meadow-v4.rbxl). Review [concept/v2 comparison](build-sbs.jpg), [top before/after](build-top.jpg), [underside before/after and four sides](build-under.jpg), [main player-eye before/after](build-ground.jpg), [all 18 route-eye pairs](build-route-ground.jpg), [initial screenshot audit](REVIEW-R5.md), [blind and technical reviews](ROUND5-CRITIC.md), [exact Studio checks](ROUND5-STUDIO-CHECKS.md), [raw bound evidence](ROUND5-EVIDENCE.json).

Changed: five offset rock tiers, irregular staggered face masses, two narrow hanging points, darker lower rock, four root chains and four floating rock accents. Native depth 266.5 / terrain width 344 = 0.775. Replaced broad scatter and canopy slabs with 17 authored planting groups of 3–5 members, larger west cover, grounded edge flowers, two junction lantern pairs and supported timber bridge guards. Keeper/acorn stand-in art moved forward within the existing summit court. Existing physical terrain, all 18 route dictionaries and original jump geometry remain unchanged; bridge edge supports are additions.

| Static audit, same final method on saved baseline and final scene | Before | After |
|---|---:|---:|
| Ground prop assemblies / parts | 3,040 / 3,955 | 76 / 373 |
| Cross-prop overlap pairs | 3,116 | 0 |
| Floating assemblies | 361 | 0 |
| Sunk assemblies | 226 | 0 |
| Unsupported assemblies | 111 | 0 |
| Props intruding into lane reserve | 27 | 0 |
| Prop parts clipping construction | 837 | 0 |
| Flowers outside edge band | 289 | 0 |
| Disconnected art envelopes | 0 | 0 |
| Fence endpoint gaps/stubs | 0 | 0 |
| Main width / actual jump-pad errors | 0 / 0 | 0 / 0 |

Final lane audit: 55,474 full-width samples, clearance 0, nominal surface differences 0. Route graph: dead ends 0, unreachable 0. Native export: 24,496 anchored parts match the manifest within 0.0001 stud; four lantern lights, six compiled Luau containers, five non-generated Sources byte-equal to baseline. Fourteen isolated ravine-policy assertions pass. All 24 baseline protected raw hashes match, including guardian-greybox; no task command wrote guardian scripts or Keeper animation/art files. Animation-directory hashes were not captured at task start, so full-directory byte equality is not claimed.

The independent technical critic reproduced all final zero counts and separately checked excluded geometry for hidden intersections. Construction coverage includes cosmetic edging/paving. Root contact tolerance is 0.20 stud; nominal lane/pad surface tolerance is 0.75. Forty-four prop Wedges use conservative OBB envelopes; actual wedge joins still need Studio/visual acceptance. Four selected portal tree rays and five straight throw chords have no tree blockers, not an all-map or ballistic throw guarantee. The initial fence-gap count 5 was a false positive for uninterrupted rails passing through intermediate posts; the corrected before and after counts are both 0.

Honest remaining art defects from blind review 3: repetitive upper rim slats and black slots, broad lip transition, roots barely perceptible, groups that still read as sparse individual props, no clearly readable flower edging, partially exposed west route, weak east orientation and sparse fence/junction cues. Black triangular path seams and edge strips across junctions persist. Static zero prop clipping does not establish clean terrain-to-terrain joins. The Keeper reads better from the portal, but runtime interaction and real rig placement remain unverified.

Evidence is 35 final Cycles renders of the exact exported native manifest: eight overview/underside views, nine principal player views and 18 individual route views. Ground eyes are 5.5 studs above authored nominal route elevations, not Roblox avatar captures. The first black summit capture was replaced using the saved baseline and an X8 camera. All final images, comparisons, place and audits are bound by hashes in ROUND5-EVIDENCE.json.

Reuse/licence: existing local authoring, Rojo/Lune and HOME render/export sources were inspected and reused; no new external code/art or third-party licence dependency. This remains native voxel/Wedge art, not imported textured mesh art. The supplied v2 Meadow is the strongest placement comparison; this build does not beat it. The local Roblox playbook was read; the exact Keystone-titled note was unavailable through exposed tools, so its supplied owner rules were followed without claiming a fetch.

Rebuild from production using bundled Python `C:/dev/codex-lab/tools/blender/4.5/python/bin/python.exe`: run `prototype/meadow-v4/round5.py`, `placement-audit.py before`, `placement-audit.py after`, `audit.py` and `routes-check.py`. Rojo 7.4.4 builds `prototype/meadow-v4.project.json -o prototype/meadow-v4.rbxl`; Lune 0.10.5 runs `round5-check.luau`, `verify.luau`, `ravine-test.luau`. Blender renders `render.py -- r5final all-views route-eyes`; `round5-sheets.ps1 final` composes existing pixels; `round5-evidence.py` binds final evidence. Every authored source edit used apply_patch; emit/build steps generate the source-data/model artifacts. Deliverables remain in this writable production workspace.

Lessons: When feet pass, check entire props against cosmetic construction because grounded objects can still clip. When a mountain reads as rings, offset the major masses because facade detail cannot fix its silhouette. When counts pass, judge player-eye composition against references because numerical clustering does not prove good placement.
