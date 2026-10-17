# Crystal Cave section ownership

Source of truth: current `prototype/cave-v2.rbxl`, its mounted CaveRouteData,
47 authored decks and existing gameplay. Bounds below are Roblox **X,Y,Z**
(authored north is negative Roblox Z). Inclusive review envelopes overlap at
seams; the named gameplay object/route owns the seam, never the bounding box.
No section authorizes changing gameplay, colliders, lanes or the six suites.

| Section | Bounds min → max (X,Y,Z) | Gameplay job / ownership |
|---|---|---|
| C1 Arrival | (-192,-24,96) → (-100,36,164) | Southwest PortalSpawn/SafetyApron: orient a new arrival toward the existing uphill routes; keep returning carriers' safe apron open. Portal and destination objects frozen. |
| C2 Geode camp | (100,30,-170) → (244,120,-90) | Northeast +48 camp, geode and guardian: identify the treasure and main/cart/cave choices. Geode/guardian and route fan frozen. |
| C3 Cart dock and upper ride | (20,12,-113) → (150,76,-5) | cartApproach and upper cartRail to the TNT court; identify boarding and show the ride ahead. Carts/seats/rails/bypass frozen. |
| C4 Blast, jump and recovery | (-112,-30,-35) → (72,66,80) | Existing support-break gap, landing, pitRecovery and lower rail/switch: anticipation, big air or recoverable fall. All blast, flight, repair and occupancy contracts frozen. |
| C5 Crystal tunnel | (30,-18,-110) → (240,66,110) | East descent and roofed cave to chain-shatter chamber; readable continuous escape with crystals at the sides. Roof, shatter, lanes and cover frozen. |
| C6 Main escape | (-205,-20,-160) → (145,66,100) | Permanent western main switchbacks and northern crosslink; dependable foot escape. Main floors and crosslinks own their seams. |
| C7 Lower cave / return | (-154,-24,65) → (75,40,156) | cave south bends, lower cart exit and three separate safety approaches. C1 owns apron presentation; C7 owns approach presentation outside apron. |
| C8 Edges, underside and backdrops | (-479,-251.831,-701.75) → (559,292.5,239), excluding C1–C7 route/court envelopes | Continuous rocky island silhouette, grounded support and biome identity. Includes distant background scenery in the actual serialized map. Residual geography only; never a new walk route. Exact native extrema: C1/BOUNDS.json. |

Arrival is the southwest safety portal, **not** the northeast geode camp.
Mounted routes differ from the older illustrative ROUTES.json (especially the
east descent); use the mounted routes. C1 is the only implementation in this job.

Owner-reported direction: option C; mine carts, rockier identity and TikTok-able
explosions; cave previously confusing/cluttered. Existing reference bar:
Steal an Egg for objective/exit clarity, Catastrophic Horse Racing for readable
anticipation/payoff, approved `concept-v2.1.png` for chunky slate geology.
These are prior project comparisons, not fresh game/footage observations.

Method: lock player cameras, SPEC + REFS + generated TARGET, R1 silhouette only,
freeze R1, R2 only its three largest gaps, offline safety/preservation checks,
side-by-side and Claude review. Stop after R2; no Studio play, commit or publish.
`treasure/hermes/CAVE-REFS.md` was absent; inspected `hermes/REFS.md` instead.
Exact Keystone Roblox Process Playbook was unavailable in checked local notes;
owner-supplied process rules and the installed production skill were applied.
