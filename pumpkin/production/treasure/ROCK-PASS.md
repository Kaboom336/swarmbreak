# Meadow rock pass — 2026-10-17

## Round 3 — final conditional collision pass, 2026-10-17

**Mounted; offline checks PASS; visual REVISIT.** The owner explicitly
permitted this round to reshape Keeper sight blockers only with identical corpus
verdicts. **27 structural walls** now have inward native wedge facets and a
continuous rear core at least 80% of original thickness (minimum 3.2 studs).
Cuts stay inside each original collider and at most 1.25 studs behind its face.
**27 other walls** retain their exact collider with legal far-side cosmetics;
two further candidates had no legal fallback. No reserve was relaxed.

| Section | Collision walls / far-side walls | Matched before/after board | Final visual judgment |
|---|---:|---|---|
| S2 mouth | 3 / 9 | [SBS-ROCK3](sections/S2/SBS-ROCK3.jpg) | 5/10 REVISIT: broad mouth piers remain. |
| S5 ridge | 5 / 5 | [SBS-ROCK3](sections/S5/SBS-ROCK3.jpg) | 6/10 REVISIT: base-left remains a broad plane. |
| S6 spiral | 6 / 6 | [SBS-ROCK3](sections/S6/SBS-ROCK3.jpg) | 7/10 REVISIT: mid-up detail reads; entry slab remains. |
| S4 ravine | 8 / 2 | [SBS-ROCK3](sections/S4/SBS-ROCK3.jpg) | 7/10 ACCEPT overall; recovery-right still has broad dark panels. |
| S3 interior | 5 / 5 | [SBS-ROCK3](sections/S3/SBS-ROCK3.jpg) | 5/10 REVISIT: rectangular piers and dark planes remain. |

Backup **`slice-v2/prototype/guardian-greybox.pre-rock3.rbxl`** was made and
byte-verified before geometry work, SHA256
`763549e4fc24399a08d99a232d2fe27d78c4336652004a94b3d080b349e062cf`.
Only **ZRock3 and Rock3Plan** are mounted through Lune 0.10.5. Removing them
restores complete serialized baseline equality. All **85 original source
bodies** remain exact, including **RavinePolicy, TunnelPolicy, Outsmart, Arena
and every original reference**. All **87 sources compile at O0/O1/O2**.

[Actual emitted geometry contract](rock3/CONTRACT.json): **PASS**. Every
replacement retains CanCollide/CanQuery/CanTouch, collision group, tags and
attributes. Actual emitted shape/rotation equality connects planned bounds to
the artifact. All other original native parts and all **79 lights** are exact.
Full-height SAT checks cover every lane plus 1.01 studs, entire jump footprint,
PvP court, cover and bait approach; **zero new lane/buffer intrusions**. No
replacement expands outside the original volume, preserving tunnel clearance.
Maximum measured face change including far-side cosmetics is **1.3504 studs**.
Native totals: **35,176 parts**, **7,991 colliders**; 883 new parts replace 27
old walls (net +856), plus one model/two modules. Deferred mesh kits are excluded
from this native count. Existing actual CC0 rocks and kit assets remain intact.

[Keeper sight](rock3/SIGHT.json): **149,613 verdicts unchanged**, **20,725 visible /
128,888 occluded / zero changed**. The original **5,592 rays** remain an exact
prefix and their baseline verdicts match round 2. The frozen initial expansion
of 92,865 rays remains a prefix too. [Coverage](rock3/COVERAGE.json) records all
56 candidate walls and **189 adjacent lane primitives**. There are **9,458
deduplicated standing/crouch lane points**, sampled every half stud on three
transverse tracks within eight studs of each wall; root heights are +3/+1.5.
Six guard anchors query them with both raw-root and production upper-body
patterns (guard +3 / endpoint +2, giving +5/+3.5 endpoint heights). Additional
half-stud wall-face/corner probes catch grazing cracks. These are explicit
offline heights, not a live crouch-controller measurement. Exact convex native
block/wedge intersections and actual Builder-tree KitDressing exclusion audits
are used. This establishes finite-corpus equivalence, not all-segment equality
or Roblox engine raycast results.

The condition caused real reversions. Four initial wall attempts changed sight;
20 failed reserves. The first full actual-emitted comparison then found **83
occluded-to-visible grazing verdicts**, retained in
[rejected evidence](rock3/SIGHT-rejected-first.json). Three probe-origin labels
traced to **five responsible overlapping walls**, all restored exactly:
S5 8305/8447, S6 3241/3239/3259.
[Reversion records](rock3/REVERT-FINAL.json) preserve the sample identities;
overlapping per-wall counts are not disjoint totals. Only far-side cosmetics
remain on these walls. The final rerun uses the identical frozen corpus.

Pre-mount checks also caught integer-array truncation of fractional core cuts;
the generator and finalizer now use float dimensions and the actual core
contract passes. A Lune accessor and nonunit-basis rotation guard were corrected
before mounting. Actual module publication/idempotence/cleanup/retry/rotation
drift, nonzero-origin/late-kit/failure-isolation, policy/save/reset/replay/
coordinator and fresh unchanged **50-seed walking-floor/cliff/cover checks PASS**.
The legacy Layout check does not establish live Meadow carry timing.

Final-artifact production N8 **DropSample PASS: 31,824 samples / 20 routes /
zero failures**, in exact-once shards **14,904 + 8,280 + 8,640**. The
[merged evidence](rock3/DROPS.json) verifies every worker's final canonical hash
and complete disjoint route coverage. All workers report 194 production kit
swaps, zero fallbacks and 59 rejected pre-existing kit placements. Sampler,
resolver, lattice and tolerances are unchanged. No failed candidate result is
inherited as final evidence.
All **32 matched-camera frames and five SBS-ROCK3 boards** are complete and
visually inspected. The [independent visual critic](rock3/CRITIC-VISUAL.md)
finds only a small visible round 3 delta; the named flat problem planes have
not all become readable rock. Scores above judge final whole-section images,
are subjective, and must not be treated as measured round-to-round gains.
S4 acceptance refers to its bounded overall presentation, not a claim that the
recovery-right plane is resolved. **No fourth art round follows this review.**
The before side is the immediate pre-rock3 artifact including rounds 1–2.
The existing renderer/cameras/lights/actual CC0 FBX are reused. The recorded
Grow a Garden / Pet Simulator 99 chunky-geology bar remains; no new live game
reference footage or Claude acceptance is claimed. The separate
[technical critic](rock3/CRITIC-TECHNICAL.md) scores safety/evidence **8/10** after
checking the final corpus, geometry contract and mounted artifact hash; later
production checks are recorded separately.

Canonical SHA256:
`2981027387b051a4a6afd30aa7b4a9b1e4a388850e63c5b132cbdc35c8cdb2e3`.
[Reproduction and limits](rock3/README.md). The local project PLAYBOOK was read;
a fresh connected Notion exact-title search again found no Keystone Roblox
Process Playbook result, so that separate note remains unavailable/UNKNOWN.
Live traversal, actual engine fitting/sight, device performance and owner visual
acceptance remain **UNKNOWN**. No Studio play, plain Rojo, commit or publish.
Lessons are recorded in [LESSONS](sections/LESSONS.md): freeze dense production
height patterns; use float geometry and verify emitted cores; revert actual
grazing failures rather than accepting planned-geometry results.

[FINAL-EVIDENCE](rock3/FINAL-EVIDENCE.json) seals the final artifact, backup,
unchanged sources, corpus, contracts, complete DropSample, both critics and all
32 matched camera frames/five boards.

---

## Round 2 — protected-wall fallback, 2026-10-17

**Mounted; REVISIT. Zero collision replacements.** Reference inspection found
that Arena's Keeper sight snapshot includes every structural wall collider;
SolidMountainStone also has a direct fix2-check reference. The owner's explicit
"leave it" exception therefore protects the S2 mouth/overhang, S6 near-right
slab, S3 reverse/far piers and structural S4 walls. No permission to reshape
those blockers was inferred. [REFERENCES.json](rock2/REFERENCES.json) records
the actual source predicate and test reference. Existing RavinePolicy,
TunnelPolicy, Outsmart, cover, bait approach, court, jump and floors stay exact.

The legal visible correction replaces **one nonphysical S5 base-left
SolidRampBody and 79 nonphysical S4 recovery/lower cladding blocks**, preserving
their false CanCollide/CanQuery/CanTouch, collision group, tags and attributes.
Rear cores and unequal staggered sloping wedge strata, varied rock tones and
inset moss/roots remain wholly inside each old cosmetic envelope. Maximum
carve depth is 1.25 studs. Forty protected wall targets receive only far-side
cosmetic relief, on the opposite face from the sampled player-camera plane.
Those additions clear every conservative all-height lane/one-stud reserve,
cover/bait reserve, PvP court and the complete jump footprint. Maximum far-side
outward reach is 0.651 studs; no reserve or gameplay rule was weakened.

| Section | Round 2 matched player-camera board | Remaining gap |
|---|---|---|
| S2 mouth | [SBS-ROCK2](sections/S2/SBS-ROCK2.jpg) | Protected foreground piers/overhang remain broad; far-side relief cannot resolve them. |
| S5 ridge | [SBS-ROCK2](sections/S5/SBS-ROCK2.jpg) | Base-left cosmetic underlay gains actual sloping facets; thin relief still falls short of chunky geology. Jump floors/ramp slopes exact. |
| S6 spiral | [SBS-ROCK2](sections/S6/SBS-ROCK2.jpg) | Protected near-right foreground slab remains. |
| S4 ravine | [SBS-ROCK2](sections/S4/SBS-ROCK2.jpg) | Recovery/right and lower cosmetic cladding gain facets; protected structural and broad ramp planes remain. |
| S3 interior | [SBS-ROCK2](sections/S3/SBS-ROCK2.jpg) | Reverse/far structural piers remain; tunnel darkness limits judgment. |

Before renders are the immediate pre-rock2 place, including round 1, with the
same player cameras and lighting. Actual existing CC0 rock FBX is retained in
both sides. The first new grid-like panel pass was corrected once into unequal
staggered wedge strata. [Self-review](rock2/VISUAL-REVIEW.md) compares with the
established Grow a Garden / Pet Simulator 99 geology bar; independent Claude
review and owner acceptance are pending, not fabricated. The separate
[independent internal visual judge](rock2/CRITIC-VISUAL.md) retains REVISIT:
S2 2/10, S5 5/10, S6 3/10, S4 5/10, S3 2/10. These are subjective scores;
remaining masonry courses, repeated bracket-like roots and the low visible
return from hidden-side detail are recorded defects. No further art changes
follow that final review.

Immediate backup `slice-v2/prototype/guardian-greybox.pre-rock2.rbxl` was made
and byte-verified before edits, SHA256
`dbda3b0a25d6d70d256b4381e6cff31f035a7a574491d62e036154999b9d4eb6`.
Only **ZRock2 and Rock2Plan** are mounted through Lune. Neutralizing those two
modules restores complete serialized-place equality to backup; all **83 original
source bodies** and imported kits/Workspace remain exact. **85 source bodies
compile at O0/O1/O2.** All **7,522 colliders** and **79 lights** are exact,
including collider colors/materials/flags/groups/tags/attributes. The delivered
native count is **34,320**: 935 inset replacement parts + 285 far-side parts,
minus 80 old cosmetics, for net +1,140 parts plus one model/two source modules.
No new light, dependency, asset upload, Studio play, plain Rojo or commit.

[Geometry contract](rock2/CONTRACT.json): exact original conservation except
the 80 explicitly listed nonphysical cosmetics; full-corner original-envelope
containment; source metadata parity; independent far-side SAT clearance; zero
new lane/buffer intrusions. Existing under-floor cosmetic volume is contained,
not incorrectly presented as a newly clear all-height footprint.

[Keeper sight comparison](rock2/SIGHT.json): **5,592 samples, 1,398 visible,
4,194 occluded, zero changed verdicts**. Complete duplicate-sensitive structural
blocker multiset equality additionally establishes every-segment geometry
equivalence. No pre-existing named standard Keeper sample-set artifact was
found. [The frozen corpus](rock2/SIGHT-SAMPLES.json) uses unchanged production
RouteData vertices plus camp/exits/bait/court and both production sight-height
patterns; it is explicitly new evidence, not an inherited standard or engine
raycast result. A final Builder-tree ancestry audit checks production's
KitDressing exclusion: **zero collidable descendants**, exact audit/deliver
geometry and identical canonical hashes. Original collider ancestry is unchanged.
Exact query membership, policies and Arena source stay exact. The
[independent internal technical judge](rock2/CRITIC-TECHNICAL.md) scored safety/
evidence 8/10 conditional on final DropSample/seal, with no confirmed safety bug;
the ancestor-exclusion proof gap and one comment were corrected before sealing.

Final checks: actual mounted module flags/publication/idempotence/missing-target
cleanup/retry PASS; nonzero-origin/late-kit/failure-isolation contracts PASS;
policy/save/reset/replay/coordinator behavior PASS; fresh **50-seed walking-floor/
cliff/cover/placement PASS** (legacy Layout, not live Meadow timing).
Fresh final-artifact production N8 **DropSample PASS: 31,824 samples / 20 routes /
zero failures**, in exact-once shards **14,904 + 8,280 + 8,640**. All workers
report 194 production swaps, zero fallbacks and 59 rejected pre-existing kit
placements with unchanged sampler/resolver/tolerances. [Merged evidence](rock2/DROPS.json)
checks every worker's canonical hash and disjoint complete route coverage. No
interrupted first-candidate result counts.

Final canonical SHA256:
`763549e4fc24399a08d99a232d2fe27d78c4336652004a94b3d080b349e062cf`.
[FINAL-EVIDENCE](rock2/FINAL-EVIDENCE.json) seals the artifact, source preservation,
checks, independent reviews, 32 matched camera frames and five boards.
Reproduction and offline limitations:
[rock2/README](rock2/README.md). Live traversal, frame cost, actual Studio fitting,
carry/PvP timing and owner visual acceptance remain UNKNOWN. The exact Keystone
playbook remains unavailable locally; round 1 recorded its failed connected
exact-title search. Project owner instructions and section process were applied.

Lessons: check complete query membership before considering a collision edit;
inset cosmetic strata when protected lane faces cannot move; compare matching
player cameras because regular tile patterns can pass safety and still miss rock.

---

## Round 1 — archived evidence

**Mounted for review; natural-wall goal remains incomplete (REVISIT).**
The pass adds legal relief, most visibly on the spiral and bridge approach,
but still leaves dominant flat faces in the mouth, ridge base and recovery
views. Offline safety passes are not visual acceptance. No Studio play was
launched; Claude's one final live check and device performance are pending.

Canonical: [guardian-greybox.rbxl](../slice-v2/prototype/guardian-greybox.rbxl).
Byte-verified immediate backup: `guardian-greybox.pre-rock.rbxl` beside it,
SHA256 `5ee7eff93109e87c614cc7f813b58bd0b4369bde74bef56110be54aac0399d81`.
No commit, publish, plain Rojo, purchase, new account or external message.

Read first: LESSONS, SECTION-CHECKLIST, every S1–S10 RESULT, latest available
studio JPGs in every section, plus S2 close mouth/walk, S5 R4 base/jump,
S6 R4 entry/shelf and S4 R4 approach. `studio-rock-input.jpg` retains the
contact sheet. Local project PLAYBOOK was read; the separately titled exact
Keystone Roblox Process Playbook remains unavailable/UNKNOWN. Named visual
bar: Grow a Garden / Pet Simulator 99 chunky geology. Existing TARGET images
are generated aspirations, not verified live reference footage.

The connected Notion exact-title search also returned no results for
“Roblox Process Playbook”; that does not establish whether the Keystone note
exists outside the connected search scope.

## Before / after, in requested order

| Section | Before | Final correction and remaining gap | Meshes / runtime instances |
|---|---|---|---:|
| [S2 mouth](sections/S2/SBS-ROCK.jpg) | Flat foreground piers, long interior planes, box overhang | Added faceted relief on legal faces and matching backing color. Foreground piers/overhang remain broad; close lane reserves reject many shells. | 65 / 130 |
| [S5 ridge](sections/S5/SBS-ROCK.jpg) | Long ramp-side slabs and sparse isolated rocks | Denser overlapping ridge-side strata. Base-left ramp underlay remains a dominant plane; the visible producer includes SolidRampBody rather than only mountain stone. | 126 / 252 |
| [S6 spiral](sections/S6/SBS-ROCK.jpg) | Box piers between straight ledges | Chunky overlap improves outer walls/mid-up; the entry's near-right central slab and straight kerb remain visible. | 70 / 140 |
| [S4 ravine](sections/S4/SBS-ROCK.jpg) | Broad bank faces and regular stacks | Layered approach walls and larger masses improve; recovery-right and lower ravine planes remain. | 140 / 280 |
| [S3 interior](sections/S3/SBS-ROCK.jpg) | Flat faces beside timber frames | More relief on legal recessed faces; close reverse/far piers remain boxy. Darkness limits judgment; no fake opening or interior clearance change. | 99 / 198 |

Total **500 MeshParts + 500 model containers + one group = 1,001 runtime
instances**. Two source modules make **1,003 total additions**. The imported
asset has 342 source triangles: **171,000 added source triangles**, an asset
count rather than a measured live render cost. No new lights, emitters,
native wedges or gameplay tags. Existing moss, roots, floor art, lamps, signs
and kerbs remain. S7/S8 receive no new shell clusters; this pass prioritizes
the five required sections. Retained wall backing color is unified across
the Meadow; S7/S8 are not claimed as a separate completed rock pass.

Each section retains `rock-before-*`, `rock-r1-*`, `rock-final-*`,
`SBS-ROCK-r1.jpg`, `SBS-ROCK-final.jpg`, `SBS-ROCK.jpg` and `GAPS-ROCK.md`.
`SBS-ROCK-phone.jpg` provides the small comparison; large exposed planes
remain apparent at phone size too.
Independent first-image/technical criticisms are recorded in
[CRITIC-R1](rock/CRITIC-R1.md). The single correction pass fixes false
camera occlusion from ramp bounding boxes by intersecting real wedge
half-spaces, then refills legal cells and shrinks unsafe shell edges.
No additional art changes follow final review.

[Independent final review](rock/CRITIC-FINAL.md) retains REVISIT in all five
sections: S5's right wall and S4's central recovery improve, while dominant
mouth, base-left, foreground pier and lower/recovery canyon planes persist.

The expanded final contract found five candidate envelopes in the actual
tagged bait-cover reserve. Four S2 shells and one S3 shell were removed;
`rock/BAIT-FIX.json` retains their identities. Buffers were not relaxed.
The pre-fix DropSample workers were stopped and their partial logs archived;
only the restarted final-artifact run counts as final evidence.

## Preservation and tests

Only new `ZRockShells` and `RockShellPlan` are mounted through Lune.
Removing them restores exact complete serialized-place equality to backup,
including Workspace, imported kits and every original source. **83 sources
compile at O0/O1/O2**. `ZRockShells` runs under the existing MeadowDressing
pcall guard in island-local coordinates; deferred KitLibrary meshes wait for
MeadowOrigin and receive one world translation. Complete-group publication,
idempotence, failure cleanup/retry and nonzero-origin fixture checks pass.

Duplicate-sensitive rebuilt comparison preserves all **33,180 original
native parts**, allowing only named wall Color changes. Sizes, CFrames,
CanCollide/CanQuery/CanTouch, collision groups, shapes, transparency,
materials, tags and attributes remain exact. All lane/floor palettes stay
exact; **79 lights are exact**. Full-envelope contracts report **zero lane
or one-stud-buffer intersections** and sampled rock-union distance <=2
studs. Jump/cover/court footprints participate in the strict all-height
reserve. Twenty-seven points per envelope check retained block-rock union;
runtime code also validates every fitted component corner against that
audited envelope before parenting it to the world. These are conservative
geometry checks, not a proof of complete rendered rock coverage.

Checked: cosmetic contract, actual module fixture, origin/failure-isolation,
policy/save/reset/replay/coordinator behavior and fresh unchanged **50-seed
walking-floor/cliff/cover/placement check PASS**. The 50-seed command uses
legacy Layout; it cannot prove Meadow carry timing. Fresh production N8
DropSample **PASS: 31,824 samples / 20 routes / zero failures**, with disjoint
workers completing **14,904 + 8,280 + 8,640** samples on this final artifact.
Every worker reports 194 production kit swaps, zero fallbacks and 59 rejected
pre-existing kit placements under the unchanged production clearance logic.
`rock/DROPS.json` verifies exact-once route coverage and identical canonical
hashes; the sampler lattice/resolver and tolerances remain unchanged. Earlier
section or interrupted pre-bait-fix results are not inherited.

Final canonical SHA256:
`dbda3b0a25d6d70d256b4381e6cff31f035a7a574491d62e036154999b9d4eb6`.
`rock/FINAL-EVIDENCE.json` seals sources, audit/logs and all comparison images.

See [rock/README](rock/README.md) for reproduction and renderer limitations.
New rock relief uses original CC0 kits2 FBX and the existing KitLibrary;
retained client art/Roblox textures, font lettering and light falloff are
offline proxies. Actual engine fitting, camera motion, carry/PvP timing,
navigation, frame cost and owner acceptance remain **UNKNOWN**.

Claude: use the same player cameras from each section's CAMERAS.json
(S2 uses render.py's fixed walk/mouth views), compare the supplied studio
shots with SBS-ROCK, and inspect mouth piers, base-left ridge slab, near-right
spiral pier, recovery-right wall and reverse tunnel foreground. Do one live
check at the end under the owner's rule; this agent ran none. Do not save a
running session over the canonical file.

Lessons: use exact ramp geometry for visibility because boxes hide real
walls; test full shell envelopes because centers miss edge intrusions; keep
visual REVISIT when protected buffers prevent coverage because safe geometry
does not establish the requested natural-rock look. Added to LESSONS.md.
