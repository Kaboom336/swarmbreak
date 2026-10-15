# Cave Round 2

**Built and statically verified; visual target failed at 5.5/10 after three blind reviews.** Open [cave-v2.rbxl](../cave-v2.rbxl), [comparison](CONCEPT-COMPARE.png), [side elevation](build-rr2-final-side.png), [top](build-rr2-final-top.png), [reviews](ROUND2-CRITIC.md), and [bound evidence](ROUND2-EVIDENCE.json).

Camp terrace remains +48, middle routes +24 and pit -16. Slate/purple-grey stacked rock replaces the original thin supports, with lighter tops, a substantial summit shoulder and secondary west peak. The camp crystal is rooted on its +48 mesa. Organic lobes, an offset inverted-mountain spine, tapered hanging rock groups, downward crystal clusters and six small floating rock satellites replace the disc-like silhouette. Timber decks and bracing carry the crossing visually; inherited rail gap and cart route are preserved.

Dressing includes varied purple/cyan crystal groups with native PointLights and facet edges, paired caged lanterns, scaffold/crate groups, three ore carts, TNT stacks, camp banners, cobbled paths and edging, tunnel arches and interior crystal light, a cyan spiral portal, and tiny moss patches. Night sky, cool ambient, Atmosphere and BloomEffect are present in the saved Roblox place. Offline point-light power and sky are approximate translations; the rendered appearance does not establish Studio lighting fidelity.

Each authoring stage had an inspected proof before the next: height-final, shape-final, dressing, then lighting; afterward the three bounded critic revisions. Source edits used apply_patch. Build/export tools generated the place, manifest, evidence and images. The final top framing was widened after review without altering geometry.

Checked: route dictionaries and five hook-part dictionaries equal to the captured baseline; cart, loop and core source hashes preserved. Existing route clearance, graph reachability, cave headroom, cart-track envelope, green flight, red fall, missing floor rays and floating collider flags are zero. One connected mountain collider component. Native binary transforms match the rendered manifest within 0.0001 stud; nine Luau containers compile. These are sampled static checks, not continuous physics or a full decorative-prop clipping audit. Max floor snap remains 2.6565 studs. Studio play, performance, multiplayer, continuous sweep and dismount remain UNKNOWN.

Protected Meadow/map-v4, guardian-greybox, core and route-input hashes were captured before edits and checked afterward. No protected path was targeted by an authoring or generation command. No commit, publishing, account, purchase or external message. Files stay in the authorized production workspace; Desktop is outside its writable root.

Reuse: read and reused local Lune native builder, Meadow renderer and existing cave auditors; no new external code/art dependency. Read Meadow ROUND2/ROUND5/ROUND6 and the Roblox production skill/gates. The exact Keystone-titled Roblox Process Playbook was not available in the local skills/work-note paths inspected; its supplied owner rules were followed without claiming to retrieve that note.

Rebuild from production: direct Lune 0.10.5 runs `prototype/cave-v2/build.luau 4`, `tests.luau` and `round2-check.luau`; bundled Blender Python runs `audit.py` and `structural-audit.py`; Blender runs `render.py -- r2-final concept side top`; the inspected `compare.ps1` composes existing pixels; `round2-evidence.py after` binds hashes and asserts zero counts. Capture a new baseline only for a new task, not midway through this one.

Lessons:
- When paths pass clearance but the scene reads flat, establish large terrain shoulders before decoration because a bright hero cannot supply missing rock mass.
- When copying cluster placement, vary the entire destination group because repeating one crystal arrangement creates evenly spaced ornaments.
- When static checks pass, retain independent visual judgment because zero collision flags do not establish concept fidelity.
