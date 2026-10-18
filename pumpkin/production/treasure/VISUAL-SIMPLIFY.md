# Meadow visual simplification — plan before implementation

2026-10-18. CHECKED: hit-game bible, TikTok lessons, game-theory checklist,
SIMPLIFY, RAID-ARENA, RAID-SLICE-1, ROCK-PASS, section lessons and the four
existing contact sheets containing the requested live JPGs. These are historic
live evidence; this pass uses offline renders only. Keystone's separately titled
Roblox Process Playbook and refs/aspects/lighting are absent; map/UI HOWTO and
the supplied owner rules apply. No fresh live acceptance is claimed.

Best local comparison: Pet Simulator 99 / Grow a Garden's chunky wall props,
cyan daylight and open centre (Bible law 10, colours and world spacing).
Steal an Egg is the wake/run clarity bar (law 5); the treasure, Keeper and
escape tell must win over dressing. TikTok's older dusk/colour-cast recipe is
superseded here by the owner's explicit daytime/no-cast direction.

## Removal and colour decisions

| Section | Remove / merge / recolour | Rule and reason |
|---|---|---|
| S1 arrival | Remove tiny flower recipes and metal bolts; merge decorative wood/grass colours. Keep arrival silhouettes, portal and route signs. | Law 5 one target; law 10 big readable forms, not petal voxels. |
| S2 mouth/west | Keep mouth timbers and rock pass. Remove alternate whole small lamps and small bolts; retain two strong section lights. | Map HOWTO open centre and edge framing; few strong lights, not a dotted light trail. |
| S3 tunnel | Remove lamp cages/sources on alternate ribs as complete recipes; keep rib supports and exit signs. Retain four broad lights, neutral warm timber palette. | Law 10 readability; game theory C4 clear silhouette; fewer competing highlights. |
| S4 bridge | Remove decorative bolts and scattered flower voxels; retain rescue cues and bridge, reduce redundant lights. | Law 5 route/recovery cue wins; preserve every gameplay recovery surface. |
| S5 ridge | Remove decorative bolts and scattered flowers; preserve walk/jump signs, ridge rock and all rails marking real edges. | Map HOWTO readable route choices; law 10 consistent warm path. |
| S6 spiral | Remove duplicate small recovery lamp recipe and tiny bolts/flowers. Keep entry/upper route light landmarks and all rock-pass masses. | Few big wall props; route readability beats small repeated accents. |
| S7 summit | Remove redundant fence lamp light only, tiny exit bolts and scattered hill flowers; retain camp, acorn, fence silhouettes and fire. | Law 5 one focal treasure; game theory F3 payoff is the largest visual beat. |
| S8 underside | Remove only scattered hill-flower recipes selected by exact names. Keep roots, water, moss and all rock relief. | Law 10 coherent large masses; no change to floating-island hero silhouette. |
| S9 home plots | Preserve accepted plot dressing, owner signs, fences and flowers. No pruning without replicated home ownership evidence. | Law 6 read the earner; cosmetic-only scope must not affect home presentation logic. |
| S10 portal row | Preserve destination crowns, low rails and boards. No new accents or geometry. | Law 9 next destination stays visible; law 4 do not add early systems. |

Exact counts are recorded from the frozen Builder manifests below before the
canonical mount; planned and measured after counts are kept distinct. Native
baseline: 34,974 parts, 79 lights, 35,203 descendants. S9/S10 are home sections,
not members of the Meadow Builder; their unchanged source trees are compared
separately. Count colours as exact RGB triples among visible cosmetic parts.

Only parts with CanCollide/CanQuery/CanTouch all false, no lane/cover role,
no tags and no gameplay descendants may be removed or recoloured. Select by
explicit cosmetic recipe names. Never thin protected geometry by size alone.
Existing warm floor materials and collidable colours stay exact. Daylight
grading becomes white, ambient neutral and bloom threshold is raised; Roblox
bloom is luminance based, so strict material-only bloom cannot be guaranteed.

## Acceptance

Freeze original colliders/query/touch parts with multiplicity and all properties;
compare exact serialization after cosmetic cleanup. New raid wall is the sole
separately declared gameplay addition. Total built instances must decrease even
including raid 2. Reuse current licensed code/kits; no new dependency or asset.
Matched section cameras, before/after manifests and SBS live under
`visual-simplify/`. Proxy images do not establish Studio appearance or fun.

## Measured outcome and resolved plan changes

Counts below are **cosmetic parts / lights / distinct visible RGB colours**,
including inherited art. Authored Section tags take priority; untagged parts
use the documented section bounds in `visual-simplify/verify.py`. Home uses
the actual current home export and unchanged Section9/10/HomeArt sources.
These are exact counts under that allocation, not a claim that every legacy
voxel has a verified art-ownership tag. Palette counts include retained native
shading and rock gradients; protected parts are excluded from colour counts.

| Section | Before | After |
|---|---:|---:|
| S1 | 1909 / 2 / 359 | 1909 / 2 / 359 |
| S2 | 1928 / 19 / 366 | 1860 / 4 / 339 |
| S3 | 1434 / 44 / 151 | 1369 / 6 / 146 |
| S4 | 3701 / 5 / 388 | 3699 / 3 / 365 |
| S5 | 5977 / 0 / 434 | 5993 / 0 / 420 |
| S6 | 3721 / 6 / 318 | 3715 / 3 / 305 |
| S7 | 503 / 3 / 160 | 501 / 2 / 159 |
| S8 | 7809 / 0 / 448 | 6744 / 0 / 439 |
| S9 | 3720 / 28 / 41 | 3720 / 28 / 41 |
| S10 | 490 / 0 / 27 | 490 / 0 / 27 |

S1's proposed sunflower pruning was rejected by the conservative protection
predicate: its art carries S1FrameProp tags. The accepted arrival group stays
exact. S5 includes the second fork's 20 cosmetic pieces; its four tiny bolts
were removed. S8 receives most inherited hill-flower removals under the spatial
allocation. No rock-pass mass, native path, hero, original fence or cover was
deleted. Retained decorative Wood/WoodPlanks share warm brown, Grass shares
Meadow green. Protected native colour gradients remain unchanged.

Built Meadow descendants: **35,203 → 33,958** (1,245 fewer), parts:
34,974 → 33,783; lights: **79 → 20**. Includes raid 2's new wall and fork.
The cleanup itself removes 1,212 parts; the raid adds 21 parts. These are
Builder counts, not measured engine memory or frame performance. Deferred
KitSwap and live frame cost are distinct from this count.

Final raid cue correction: the east fork's 20 nonphysical marks sit 0.44 studs
higher so the original cosmetic paving cannot hide them. The full frozen
DropSample input differs only by that strictly enumerated Source change, and
the complete final native geometry confirms identical physical/query records.
No sampler lattice, resolver, threshold or original assertion was modified.

`COLLIDABLE-CONTRACT.json` compares every protected BasePart property before
and after cleanup in the same build, with multiplicity and repeat idempotence.
`VISUAL-CONTRACT.json` independently compares both native manifests: all
8,413 original protected records stay exact; exactly one new raid wall exists.
Saved Workspace and every source outside the explicit mount list remain exact.
The server delta outside RaidSlice/Test is only selecting the vault wall;
original nine suite source bodies and all policies remain unchanged.

The neutral-sun/cyan-sky render setup is identical in both frames. It does not
reproduce Roblox ambient fill, SurfaceGui lettering, material textures, client
hero replacements or exact bloom. The tunnel proxy is darker than historical
Studio evidence; do not treat this as a measured engine exposure regression.
Visual verdict: **REVISIT / Claude live acceptance pending**. Fewer highlights
are visible in the tunnel; the large protected geology still dominates S6.
