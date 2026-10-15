# QA and build handoff
CHECKED: visually inspected initial six-image sheet, each original blueprint full-size, final sheet with three regenerated overhead planning images. Read reference v2 and v4 visuals. Separate critic reviewed first sheet and final-design draft; see CRITIC.md.
Built-in imagegen: six originals + three overhead corrections. Exact prompts in PROMPTS.json / CORRECTION-PROMPTS.json. Kept originals for audit. Sheet uses corrected generated blueprints + original 3/4 concepts.
True orthographic numeric plans: A-plan.svg, B-plan.svg, C-plan.svg. Created directly from proposed route coordinates, not inferred from generated pixels. They supply actual overhead views because image generation retains visible cliff sides even after correction. Chunky concept images remain style guidance.

| Deliverable | Working | Remaining mismatch / authority |
|---|---|---|
| A | Crescent rock roof, owl, skylights, visible routes; correction fixes main green/tunnel and north forkY0 | Green extra interior flank and some arrows remain ambiguous. West tunnel floor0→8→0, not old+18. SVG/JSON govern. |
| B | Tall twin spires, geode shell guardian, orange north-south shortcut in corrected plan | Scenic bridge runs east-west and looks longer than32; fissure looks much deeper than−8; do NOT build that depth/span/orientation. True plan has18×32 bridge at+8 over−8 floor, two recovery ramps. |
| C | Long mesa/cart identity, low pangolin, clear quarry rim | Corrected generated plan still has perspective and 'east shelf' text on south tunnel. Final doc/JSON/true SVG include added southern bends; its36.3s tunnel replaces earlier28s. Docks/cargo interruption unproven. |
| Sheet | All three alternatives, blueprint + scenic shot, pick and main estimates legible | Sheet is style comparison, not a scaled collision/build specification. |

Style check against v2: broad square rocks, simple block avatars, cyan arch, lanterns, faceted crystal clusters, deep floating underside, daylight and distant islets preserved. Stronger rock mass than original flat-field problem. Guardian art has silhouette variation; exact reusable rig proportions/cargo size UNKNOWN. Guardian attacks are design text, not animations or attack evidence.
Timing: Euclidean3D proposed polyline sum at16; compute time before rounding length. Main34.0/32.9/34.8 seconds. Max slopes23.9/22.5/16.5°, under25. Centreline bounds checked with9-stud lane margin against rectangular envelopes. This does NOT verify rock clearance, corners, exact irregular polygon support, shortcuts, camera, navmesh or guardian animation sweep.
True SVGs: route/mass bands may overlap in plan because rock supports raised paths; roof/terrain cutouts and collision must be authored during future greybox. Cross-link slope/turn clearance and full-width ramp joins need construction audit. Purple lines indicate connections, not exact path-length certification.
Scope check: task authored only treasure/cave-v1. No game edits or commit performed; existing dirty repo state left alone. Built-in generated originals also remain in tool-managed image storage; final project copies are all here.
NOT RUN: Studio, actual movement/carry16, guardian traversal/hits, short-path search,4/8 clients, deadline handoff, bridge recovery/collapse/rebuild, cart fairness, muted-phone readability/performance, owner acceptance.
Next: show B design once; future build requires implementation authorization. Greybox B core theft→bridge/flank→cyan first; then reuse real rock/crystal/guardian art, compare to v2/v4 and owner check before expanding.

