# C1 R3/R4 — final two rounds mounted; visual REVISIT

Current artifact: `prototype/cave-v2.rbxl`, built only through
`prototype/cave-v2/build.luau c1-r3|c1-r4`. Pre-R3 byte backup:
`prototype/cave-v2.pre-c1r3.rbxl`, SHA256
`103d16d05bf9fedee826968b2ddbf66e1d2c3b479544e0ab52bd8b4bd0590340`.
Final artifact and evidence hashes: `FINAL-R34-EVIDENCE.json`.

Read and compared prior RESULT, SBS-R2, TARGET and approved concept-v2.1.
The user's supplied Claude critique is owner-reported; R3/R4 visual review here
is by the author, not an independent Claude review. The exact Keystone Roblox
Process Playbook remains unavailable in the checked local active-work notes.

R3 addressed only the three supplied gaps: increased the supported outer rock
silhouette, added two checked kit envelopes, reduced small foreground crystal
noise, and recoloured the green header and nearby cosmetic wall faces. Initial
outer-footprint trials failed support/contact and were removed before the R3
review. Final R3 has contact 0 and no lane/support errors. Its locked-camera
render exposed the next three issues, written to `GAPS-R4.md` before R4 edits.

R4 addressed those three: lowered the central crown and increased the existing
right-edge run, recoloured the two remaining green pennants, and restored cyan
emission to the retained larger crystals. Final: 11 kit-rock envelopes plus
four existing lamp components. The existing lamp remains brightness 1, range
14, shadows off. TextureID/SurfaceAppearance clearing and Color+Slate are retained.
No assets, scripts or services were purchased or imported from new sources;
the inspected existing Quaternius rock and its local CC0 licence were reused.

The appearance-only module is mounted under the existing C1 script. It changes
only Color, Material, Transparency and existing crystal light Enabled values
on explicit cosmetic names: three fabric pieces, 146 rock faces, 35 hidden
crystal components and 18 retained toned components. These are component counts,
not independent crystal-cluster counts. It runs on the server when the place
runs; the offline export executes that same module for the renders. Saved
original CaveV2 data stays exact. No cart, fence, post, gameplay prop, giant
purple crystal, geode, guardian, blast, lane, collider or existing test changed.

Checked offline on the final artifact:

- R3/R4 audit: all 47 lanes pass; zero support failures; bounds/flags/light caps pass.
- R3/R4 conservative OBB SAT: **contact 0** against 14,409 protected solids.
- 30 mounted sources compile at O0/O1/O2. Arrival script and presentation module:
  Selene zero errors, warnings or parse errors using the existing Luau config.
- `VERIFY-R34.json`: exact pre-R3 original serialization after removing the C1
  siblings; actual mounted runtime with textured mesh fixtures passes clearing,
  envelope/lane checks, idempotence, complete staging, failure cleanup and retry.
  Presentation changes only whitelisted appearance; all other map state is exact.
- Existing tests, cart-board, cart-drive, rider, ride-contract, runner and kit
  library checks pass; fresh `r34-*.log` files. Existing test files untouched.
- Unchanged artifact-only cave checker passes source parity, scene conservation,
  kit bounds/query/fence joints, SelfTest, strict floors and policy. Its existing
  wrapper still pins the expected loader to the preserved mounted cave version.
- The previous 3,024-sample dense sweep is historical evidence, not a fresh R4
  run. Exact original serialization and presentation-only changes preserve the
  physical/query geometry it tested; fresh runtime appearance is checked separately.

`SBS-R3.jpg`, `SBS-R4.jpg` and phone boards show both locked cameras and TARGET.
Inspected both final camera renders. They use real licensed FBX envelopes and
the actual native map, with approximate offline lighting; disabled crystal lights
are excluded from the final export. Real asset replication, Studio appearance,
device performance, gameplay feel and owner acceptance remain **UNKNOWN**.

**REVISIT:** right foreground mass and panel cleanup are visible, and the stair
and purple crown remain readable, but the required large left foreground frame
is still absent. Checked legal outer pockets fall outside the locked frustum;
failed safe-footprint trials did not justify entering lanes or buffers. Large
background walls still read as boxes, and fences/posts still contribute clutter.
The approved concept/TARGET bar is not met. Four-round cap reached; stop here.
No Studio launch/play, commit, publish or messages sent.

## Historical R1/R2 record

Delivered `prototype/cave-v2.rbxl` through **only** the new C1 branch in
`prototype/cave-v2/build.luau`. No Rojo, Studio launch/play, commit, publish,
purchase or new external dependency. Eight-section ownership: ../SECTIONS.md.

Byte-verified pre-edit backup: `prototype/cave-v2.pre-c1.rbxl`, SHA256
`e783e67ad1f852ae0f50495bd1d1a35798902ce5a59a668fe17cb6077f6a612b`.
Final hash and fresh evidence are in FINAL-EVIDENCE.json / MOUNT-r2.json.
Deleting the C1 Workspace sibling and presentation script restores exact full
original place serialization. All 28 original source bodies, six suite bodies,
cart/blast/geode/guardian logic, lanes, colliders, old cosmetics, tags, attributes,
lighting and route data remain exact; 29 sources compile at O0/O1/O2.

R1: six large rock silhouettes only. R2 freezes all six and addresses only
GAPS-R2's three issues: visible near-edge framing, descending mass hierarchy,
one quiet mine lamp. Final: nine rock envelopes plus four lantern components,
one PointLight brightness 1 / range 14 / Shadows false. Tint explicitly clears
TextureID and SurfaceAppearance; all added parts anchored, collision/query/touch
false. Existing sanitized cave KitLibrary loads the existing CC0 Quaternius
Rock_Medium_1; its local licence and spawn/fit code were inspected first.
Build/export/kit loops yield. Native wedges survive until the complete staged
kit assembly passes bounds and lane checks; failed fits retain fallback art.

The scoped apron exception is explicit: only X[-133,-126], Z[105,139] permits
cosmetics tangent to the unchanged SafetyApron top. The central 32-stud corridor
X[-166,-134] stays open; all other decks retain full one-stud horizontal margins.
No new route/dock or physical floor is implied. Arrival is southwest, geode camp
and real boarding dock northeast. Section bounds use mounted CaveRouteData,
not the older illustrative route plan.

Checked offline:

- AUDIT-r1/r2: 47 decks, no lane-margin errors, no support errors at 25 bearing
  probes per rock; new flags/bounds/light limits pass.
- CONTACT-r1/r2: **contact 0** against 14,409 protected solids at .035 tolerance,
  conservative full-envelope OBB SAT (native wedge boxes overbound their shape).
  Nonphysical cluster overlaps are intentional; this is not live physics.
- RUNTIME.json: actual mounted script with textured MeshPart/SurfaceAppearance
  fixtures passes tint clearing, flags, fit/envelope margins, idempotence,
  complete staging, failed-fit cleanup/retry and exact frozen R1. The fixture
  bounds a kit component; real InsertService/mesh replication remains UNKNOWN.
- Existing `tests`, `cart-board-check`, `cart-drive-check`, `rider-check`,
  `ride-contract-check`, `runner-check` and kits `library-test` pass (logs here).
- New runtime Selene: **0 errors, 0 warnings**; no lint suppressions added.
- Source-aware artifact-only check passes original SelfTest, strict floors,
  source parity, scene scope, kit bounds/query/fence joints and policy.
  Stock checker first failed because its expected shared working-tree loader
  includes later Meadow edits. `offline-check.luau` runs the **unchanged checker**
  with that expected loader read pinned to the exact pre-C1 mounted cave version.
  No test assertions or gameplay sources were changed to make it pass.
- Dense N=8 drop sweep: **PASS, 3,024 samples / zero failures** in
  `dense-drop-mounted.log`; fresh output copied to DENSE-FINAL.json. The plain
  unchanged ray implementation completed; a redundant exact-cache experiment
  was stopped afterward and is not acceptance evidence. Do not inherit an old
  STUDIO-OFFLINE.json result.
  The sweep started on R1; final-only C1 changes have no physical/query membership
  and complete original serialization parity independently proves the same tested
  gameplay, lanes and resolver. Final-source runtime fixtures are separate.

Visual evidence: SPEC, REFS.jpg, generated player-camera TARGET.png, two locked
player eyes, BEFORE, PRE-R1/R2, SBS-R1/R2 and phone boards. Final arrival,
outgoing and phone SBS were inspected. Native scene/real CC0 rock FBX renders
use matching cameras and fixed approximate lighting. Deferred original kits,
SurfaceGui text, Studio lighting/particles and avatar occlusion are not reproduced.
TARGET drifted in framing and apron occupancy; those details never override
the protected corridor. PROMPT.md records built-in tool, exact inputs and prompt.

**Visual REVISIT:** R1's strict outer pockets are mostly outside the player
frustum. R2's near-edge rocks are visible but asymmetrical and much smaller than
TARGET; the low lamp is off-camera in the locked views. A tall R2 trial hid the
cart/stair vista and was reduced within R2. The inherited sign dominates the
left frame, and background blockiness/clutter remain. The scoped pass is safe
offline, not a claim of reference quality or a fix for the whole cave.

Independent Claude critique, six live Studio suites, imported asset appearance,
device performance, gameplay feel and owner acceptance remain **PENDING/UNKNOWN**.
No Studio play was launched. Stop after these two rounds; no R3 authorization.
`hermes/CAVE-REFS.md` and exact Keystone Roblox Process Playbook were unavailable
in the checked local files; existing hermes/REFS and supplied process rules used.

Lessons:

1. When the canonical has later runtime repairs, preserve its serialized place
   before decorating, because a historical native generator can discard suites.
2. When an apron shoulder is safe but absent from the camera, check visible
   framing before adding detail, because legal bounds do not guarantee useful art.
3. When a shared loader evolves for another biome, test the preserved mounted
   version explicitly, because remounting unrelated changes can invalidate scope.
