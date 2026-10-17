# C1 — the safe quarry threshold

Story: step out onto an open stone apron, see the rocky mine ahead, and return
here carrying the geode. Gameplay job: orientation and safe return, no new fork.

Bounds: Roblox X[-192,-100], Y[-24,36], Z[96,164]. Actual SafetyApron is
center (-150,-1,120), size (48,2,40), top Y0; PortalSpawn is already on it.
No part of C1 may imply a new cart boarding point: the real dock is northeast.
Existing portal artwork, apron, spawn and all of CaveV2 remain byte-preserved.

Best visual reference: approved cave `concept-v2.1.png` (illustrative chunky
slate rock, sparse crystals and warm mine lamps). REFS.jpg pairs it with the
current arrival camera. Steal an Egg is the existing objective-clarity bar;
Catastrophic Horse Racing is the existing explosion anticipation bar, reserved
for C4. Neither is a newly observed gameplay reference.

Locked cameras: CAMERAS.json, two literal player eyes 5.5 studs over apron,
24 mm lens, identical native geometry and lighting setup in every round.
No new Studio image exists: BEFORE renders are labelled offline proxies.
Generated TARGET is an aspirational edit of these actual camera renders;
background/carts/geode/blasts are frozen and outside the C1 target delta.

R1: only large rock silhouettes outside the protected floor footprints.
Two irregular shoulder groups, quiet central opening, no small props or lights.
Reuse CC0 Quaternius Rock_Medium_1 through the existing sanitized KitLibrary.
Native wedges remain a bounded fallback until all kit shells fit successfully.
No imported art is allowed to bring its texture atlas into tinted slate shells.

R2: freeze every R1 form; identify its top three gaps against TARGET, change only
those. Do not spend a third round. Purposeful optional accents: stone seams,
one restrained warm bearing-mounted lamp per shoulder, no extra sign forest.
If silhouette misses TARGET, record REVISIT rather than assert acceptance.

Safety: full-envelope one-stud horizontal exclusion from all 47 lane decks;
R2 follows the existing Meadow arrival-apron shoulder method: only new cosmetics
in X[-133,-126], Z[105,139] may overlap SafetyApron's horizontal footprint,
while their bases remain tangent to its unchanged top. Central X[-166,-134]
is a clear 32-stud corridor. All other lanes retain full one-stud exclusion.
seven-stud player space; new cosmetic collision/query/touch false. Contact 0
means no new envelope penetration into protected physical solids at .035,
excluding intentional rock embedding only when explicitly recorded. New lights
brightness <=1.5, range <=18, shadows off. Build and mesh scans yield.
No gameplay, old cosmetics, cart, blast, geode, guardian, lane, collider or test
edits. C1 is a Workspace sibling so existing CaveV2 child-order contracts remain
exact. Original full-place serialization must match after deleting C1 additions.

Entry: pinned Lune `run prototype/cave-v2/build.luau c1-before|c1-r1|c1-r2`.
Backup `prototype/cave-v2.pre-c1.rbxl` is created once and byte-verified before
the first mount. The preexisting handoff's Rojo rebuild is superseded for C1;
historical baseline generation is never invoked. No Studio play or commit.
