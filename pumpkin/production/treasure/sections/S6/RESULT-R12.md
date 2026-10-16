# S6 Spiral and Shelves — R1/R2 only

**Visual REVISIT; stop for Claude's live Studio check. No R3/R4.** Protected cliff
faces still hide the summit; the low shoulder studies and lower-path cues read
weakly from player height. TARGET-level continuous descent readability is not met.
The locked shelf-down render does not reveal LOWER PATH or its recovery lamps;
their existence does not establish a visible descent choice. The entry shows one
small lamp, and the mid-up image remains dominated by the protected cliff.

Canonical: `../../../slice-v2/prototype/guardian-greybox.rbxl`.
Byte/hash-verified immediate backup: `guardian-greybox.pre-s6.rbxl`, SHA-256
`fd45b06c14f326c9a86c04a57daf376cc0d108636019fd9d4cb7017ea942466e`.
This retains the current PvP reset fix. The source-only Lune mount adds Section6;
removing it restores full serialized-place equality. All 75 prior sources,
Workspace, templates, kits, gameplay, policies and tests remain exact. No plain
Rojo, commit, publish or new external dependency.

Review `PRE-R1.jpg`, `GAPS-R1.md`, `SBS-R1.jpg`, `PRE-R2.jpg`, `GAPS-R2.md`,
`SBS-R2.jpg` and phone boards beside `TARGET.png`. `R1-review.rbxl` and
`R2-review.rbxl` preserve both states for Studio. Built-in imagegen made TARGET
from the three exact player-camera renders, not a schematic. Prompt/provenance:
`TARGET-PROMPT.md`. Grow a Garden's existing local crops remain the named warm
palette/grouping reference; the generated target is aspiration, not approval.

R1 fixes only its three silhouette gaps: warm finish on residual cliff solids,
two five-piece low parapet studies on actual 24/36-stud spiral shoulders, and a
five-piece study on the 12-stud recovery shoulder. Actual ramp profile, shelf
heights, drops and sight blockers stay exact. One sill crossed a taller column
and was moved to a clear shoulder. Final R1 contains no light/sign/story dressing.
Its 15 parts and cliff finish remain frozen through R2.

R2 fixes only its three gaps: two attached entry lantern groups; colour/material
on existing untagged nonphysical relief/facets and ray-identified foreground
stacked rocks; two recovery lamps and a LOWER PATH board on the frozen parapet.
The board faces the shelf camera. Trial closer/longer entry mounts failed the
lane margin and were rejected; safe original pockets remain, with weak visibility.
No invented landing patch, usable platform or rope bridge was added.

Story: maintained parapets outline real shoulders; lanterns and the board name
the existing lower route. Each parapet is 3 piers + 2 sills, each lantern is
bracket/glass/hood/base, and the board is board + 2 bolts. **34 new native cosmetic
parts**, including **15 frozen R1 parts**. **4 PointLights**, brightness 1.25,
range 18, Shadows=false. All new parts anchored and collision/query/touch false.
All creation/scan loops yield every 300 operations when task exists. Section6
uses the existing MeadowV4 island-local pcall guard and one origin translation.

Both rounds compile **76 sources at O0/O1/O2**, preserving **75 existing sources**.
Duplicate-sensitive audits allow only explicit solid/cladding colour/material
changes. No geometry, opacity, collider, query/touch, tags, LaneId, walking floor,
jump ledge, gameplay or test edits. Warm paving, every edge stone, existing kits
and summit court remain exact. Below-court cosmetics at Y<44 belong to the cliff
approach; court art at Y>=44 is untouched.
The final finish inventory is 803 existing solid bodies and 1,146 existing
nonphysical cladding parts; only colour/material changes on those objects.
Native contact/support and lane audits report zero errors at the unchanged
.035-stud tolerance and one-stud margin;
an additional oriented projection check reserves that margin at every altitude.

Fresh final checks and hashes: `FINAL-EVIDENCE.json`. This seals origin/failure
isolation, current policy/reset/persistence/replay/coordinator contracts, the
existing 50-seed command, S5's existing late-kit check and production N8 DropSample.
**All final offline checks PASS. DropSample: 31,824 samples / 20 routes / 0 failures.**
Workers completed 14,904 + 8,280 + 8,640 cases, with exact-once complete route
coverage and the same final canonical SHA-256
`7dddaa90353efcb060943c480485dbdcab05a59b3cadc4de75856e900f2eb4dc`.
The latter uses disjoint complete-route workers and explicitly includes deferred
S5 kits. Its merged report gives actual count and exact canonical input hashes.
The older reset mock failed because it lacked current Keeper/socket state;
`behavior-legacy-fixture.log` retains that failure. The final wrapper reuses the
existing current `pvpflake-tests.luau` assertions. No production test was edited.
Pre-correction DropSample attempts were cancelled and do not count as final evidence.

Process deviation: PRE-R1 composition completed during compilation after local
image-library failures, although BEFORE images and generated target predated
editing. The three player cameras stay exact. An overview-only northwest correction
was rendered identically for each stage. See `RENDER-LIMITS.md` for these details,
offline font/material/light proxies and omitted deferred meshes in renders. The
exact Keystone playbook text was unavailable locally and remains UNKNOWN.

Claude: open the canonical in fresh Play and compare both review places from
`CAMERAS.json`; add MeadowOrigin `(0,76,-360)` for world coordinates. Check the
lower-path sign/lamps, whether the parapets are worth keeping, and the blocked
summit sight lines. Run all nine live suites, especially Loop → PvP and consecutive
StudioPassAll. Independent review, live traversal/carry/PvP recovery, engine
appearance, device/fun and owner acceptance remain **UNKNOWN/PENDING**. Legacy
50-seed Layout coverage does not establish MeadowV4 live timing. Stop before R3/R4.

Lessons: when cladding covers a finish, identify its foreground producer before
editing; when placing near a curved route, audit the full oriented horizontal
margin; when a canonical contains a reset fix, reuse its current dirty-state fixture.
