# S1 — Keeper's garden gateway

Scene: a cared-for farm gateway at the foot of the Keeper's hill. Someone tends flowers here and marks the paths; this is a welcoming departure and a recognizable place to return.

Round 2: owner requests fuller farm story groups with player-scale barrels/crates, cart, shovel/sacks, sunflowers, fences, round trees/bushes, portal-side post lamps and timber mine framing. Keep the 32-stud central apron reservation (owner minimum 30), actual route buffers and physical floors. Existing stair/bridge retained. Apron shoulder artwork includes grouped farm props and lamps, using the same outside-corridor rule. Mine framing alone extends west to approximately (-76,98) and (-52,88); narrow timber face trim avoids retained cliff solids. Its supported overhead header has underside Y=10, above the walking envelope. No ground-level dressing occupies lanes; no route geometry changes.

Focal hierarchy: existing cyan return portal at close range, open warm plaza, then the distant golden summit beam. No roof, giant sign, or tree crown may cut the central summit sight line. West, north and east leave through deliberate gaps; signs stand beside paths, never in their walking envelopes. Arrival proof camera: Roblox (0, 5.5, 154), 18 studs behind portal centre (0,0,136), facing (0,24,-96). Overview: (92,88,205), facing (0,4,122). Use identical cameras for before/after.

Palette: saturated leaf green, golden flowers, warm brown timber, honey sandstone path; cyan reserved for portal and gold for destination. Materials: existing grass/rock/path retained; rough timber garden borders and signposts; warm lantern cores, restrained accent light. CC0 kits2 Kenney Nature and Quaternius assets reused; inspected KitLibrary and local licences. No new purchased assets or imported scripts.

| Prop / cluster | Intent |
|---|---|
| Two low timber garden beds outside apron | Show cultivation and define the plaza edge without narrowing it |
| Golden flower groups in beds | Repeat reward colour at low visual weight; avoid uniform confetti |
| One bush per bed | Give each bed a readable large/medium/small hierarchy |
| Two outer trees | Frame the scene from outside the walking field; keep crown below beam |
| West/east route-edge flower clusters | Lead eye toward side departures; no hedge across a mouth |
| Three low signposts: WEST / BRIDGE / RIDGE | Associate a short readable name with each direction |
| Timber rails at outer garden edges | Contain the garden story, not the player |
| Two lanterns on garden posts | Warm arrival accents with an actual bracket/support |
| Stump and log at west bed | A contained maintenance grouping, not unrelated scattered debris |
| Watering barrels beside shoulder beds | Explain who tends the garden; warm service props connect flowers to the farm story |

Remove/hide obsolete nonphysical flower, bush, mushroom, pebble and grass-tuﬅ scattering within S1. Preserve all physical objects, lane surfaces, floor tags, route definitions, portal handles, guardian behavior and drop rules. If a retained physical object is a visual defect, record it rather than silently changing gameplay.

Grounding: solve base height from actual horizontal collidable source floors under the complete footprint; every bed rail, post and kit gets a support check. Kits use the same bottom-centre convention as KitLibrary. No decorative floor is tagged/queryable. All new dressing is noncollidable/nonqueryable/nontouchable. Run lane-overlap/contact audits and compare rebuilt physics signatures before delivery.

Blind review correction 2: detail must appear in the arrival camera. Add a low left bed on the outer apron shoulder (-19,122); shift compact east bed to (31,110). The sole apron exception permits nonphysical artwork outside a reserved 32-stud central corridor. PortalPad and ProtectedPortalApron remain byte-for-byte identical as generated physical floors, including all tags; every actual route retains its one-stud decoration buffer. No other dressing may use this exception. The earlier blanket statement about placing all beds outside the apron is superseded by this specific shoulder treatment.

References: REFS.jpg contains five labelled crops from owner-provided official promo art plus the generated target. Grow a Garden is primary for tended beds and warm/green contrast; Adopt Me for compact flowers and clean forms; Brookhaven for framing a destination. These are composition references, not literal gameplay layouts. PS99/Brainrot/99 Nights were inspected on the source contact sheet; their darker or busier thumbnails are not the S1 lighting target.

Evidence limits: offline native geometry and original kits2 FBX meshes can verify layout/contact; Roblox texture import, lighting, labels and live StudioPassAll require Studio. CAVE-REFS.md and AI-BUILDERS.md were found and read in iris-coordination/dispatch/work/hermes-roblox-03-cave-refs and -04-ai-builders. Their useful shared rule is structural contact first, then purposeful story clusters and quiet routes. Exact Keystone playbook remains unavailable locally. Do not inherit a pre-polish runtime PASS.

Blind review correction 1: the existing opaque upright portal blocked the entire required arrival frame. Its nonphysical artwork is rebuilt as a low pool within the protected apron; return trigger, location, lane geometry and drop rules stay unchanged. This is a presentation change to S1, not a new portal interaction.

Concept provenance: built-in imagegen; prompt saved in TARGET-PROMPT.md. The generated image is aspirational; its large distant hill is not a request to rebuild S6/S7 during this pilot.
