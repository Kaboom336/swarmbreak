# C2 final client geode fix — 2026-10-17

Claude's live trial is owner-reported: setting only the Geode root's client
`LocalTransparencyModifier = 0.85` reveals the cracked shell, crystals and
pedestal and removes the orange floor flood (`studio-geode-trial.jpg`). This
supersedes the earlier pending-review note below; no fresh live run is claimed.

Added `prototype/cave-v2/GeodeArt.client.luau`, mounted only by
`prototype/cave-v2/build.luau c2-geode` into the cave's
`StarterPlayer.StarterPlayerScripts.CaveGeodeArt`. It scans existing BaseParts
and listens to Workspace.DescendantAdded for recreated/carried roots and late
`C2_GeodeArt` children. Only a BasePart with that direct child receives 0.85;
art descendants are untouched. No polling or server property writes.

Delivery: `prototype/cave-v2.rbxl`, SHA256
`a50a0f8cefc6d7c78d26610ba2988057a017e72a754d088a9d76ed209f35b3a7`.
Byte-verified backup: `prototype/cave-v2.pre-c2geode.rbxl`, SHA256
`b03077de16297f681131d924ebfc42512b42dffd9605572a1394bd5db11b63f7`.
`C2GEODE-BUILD.json` records compilation of all 34 mounted sources at O0/O1/O2
and exact full-place serialization after removing only the new LocalScript.
Thus all existing server parts, Transparency/Material/Color/Size/CFrame,
prompts, attributes, scripts and tests remain unchanged.

Pre-edit search of prototype sources and treasure cave checks/tests found no
LocalTransparencyModifier reads. Existing cave shared-domain, cart-board,
cart-drive, rider, ride-contract and runner offline checks PASS; individual
`c2geode-*.log` files record results. Artifact-only checker PASS: mounted source
parity, scene scope, kit bounds/query/fence joints, SelfTest, strict floor seams
and policy (`c2geode-artifact-only.log`, matching `OFFLINE-INPUT-artifact-only.json`).
The existing source-aware wrapper uses the unchanged mounted cave KitLibrary
because the shared working-tree library has later Meadow changes.
Studio play, publish and commit were not performed. The installed Rokit shim
failed with `home directory not found`; checks used its installed Lune 0.10.5
binary directly. Earlier dense-sweep evidence belongs to the previous hash.

Lesson: hide the loot part client-side with LocalTransparencyModifier when hero art must show.

# C2 live fix — 2026-10-17: offline PASS; live review pending

This entry supersedes the R3/R4 appearance claims below. Claude's live Studio
finding is owner-reported; `studio-r4-geode.jpg` and the locked `TARGET.png` were
inspected here. The live image shows an unbroken glowing ball and orange floor;
the target has readable facets and separate pools of light. Offline proxies did
not predict the live occlusion/bloom. No new visual acceptance is claimed.

Built only through `lune run prototype/cave-v2/build.luau c2-fix`.
Delivery: `prototype/cave-v2.rbxl`; immediate byte-verified backup:
`prototype/cave-v2.pre-c2fix.rbxl`, SHA256
`c65ffb935ee49b1f3c9bbb37f911c68281ff68f2042c50f98c372d752a2f1e40`.
Final SHA256: `b03077de16297f681131d924ebfc42512b42dffd9605572a1394bd5db11b63f7`.
The saved place changes only `ServerScriptService.CaveGeodeC2.Dress.Source`.

Dependency audit: the unchanged `prototype/cave-v2/studio-check.luau` explicitly
requires exact Geode Material, Transparency and Color (scene property loop).
Therefore all three stay original under the requested fallback. Mounted
CaveLoop/carry/StudioPass sources were inspected; none reads those three Geode
properties. The on-disk HomeArt client/geometry contain no Geode references;
neither is mounted in this cave. No test assertions or gameplay sources changed.
Geode Size, CFrame, Anchored, collision/query/touch, prompts, original children,
tags and attributes remain exact, including after runtime art removal.

The existing native art recipe is reused: 26 dark Slate shell wedges now have
horizontal centre radii 2.65–2.8 studs and an open west/southwest camera face.
Twelve glowing crystal points extend outside the radius-two ball. Opaque
SmoothPlastic octagonal cavity facets cover the preserved Neon root; broad
Neon cavity bars/crown are removed. The visible plinth spans y48.04–48.80,
above the unchanged y48.02 floor, with an inset at y48.86. Existing camp/cart
art and the licensed CC0 Quaternius rock pipeline remain in use; no new assets.

Inherited lights within 40 studs of (160,51,-120) are capped at brightness .55,
range 14, shadows false. Added lamps use .55/range 10 and the soft core light
uses .55/range 10, all shadowless. Both complete runtime dressings are measured
in `C2FIX-CHECK.json`: 15 lights, total enabled brightness 34.55 → 8.25.
This measures configured brightness, not Roblox luminance.

Offline evidence: `C2FIX-BUILD.json`, `C2FIX-CHECK.json`, `CONTACT-c2fix.json`,
`C2FIX-FINAL.json` and `c2fix-*.log`. Checks cover exact unrelated saved state,
exact loot root, cosmetic flags, locked-eye clearance, pedestal support height,
shell radii/opening, crystal points, full camp light caps, idempotence and
reversibility. Contact is zero for 184 cosmetic envelopes against 14,409
protected solids. Native convex-face segment checks mask all 285 arrival and 252
close-geode sampled visible sphere points; this is geometry evidence, not bloom
or visual approval. Contact uses the existing conservative OBB SAT with the same
.035 tolerance, translated to Lune because Python is unavailable in this shell.

Existing artifact-only cave, cart-board, cart-drive, rider, ride-contract,
runner, shared cave tests, kit library and mounted runtime fixture pass.
All 33 mounted sources compile at O0/O1/O2. Selene on Dress: zero errors,
zero parse errors, 51 style warnings; no suppressions. Fresh dense N=8 PASS:
3,024 samples, zero failures. `C2FIX-FINAL.json` seals the completed sweep,
all check logs and current sources to the final place hash above.
Historical R34 reports/boards below do not prove the new artifact's appearance.
Current checker/test files have no tracked diff; their fresh source hashes are
sealed separately because at least one old R34 test hash predates the current file.

Claude must recheck arrival/geode cameras in live Studio for shell silhouette,
facet/crack glow, exposed points, pedestal and orange-floor reduction.
Live suite results, bloom, carry appearance and owner acceptance remain UNKNOWN.
Studio was not launched or played; no commit or publish.

Lesson: hero loot art must wrap outside the loot part; check live.

# C2 Geode camp — final rounds 3 and 4: REVISIT

Canonical delivery: `prototype/cave-v2.rbxl`, built only with
`prototype/cave-v2/build.luau c2-r3 / c2-r4`. Immediate byte-verified backup:
`prototype/cave-v2.pre-c2r3.rbxl`, SHA256
`55227b09ed9b9538a072fe2832059edb75b767ae9a5dc050e639607fb511dcf2`.
No Studio launch/play, existing test edits, commit, publish, purchase or messages.

Final SHA256: `c65ffb935ee49b1f3c9bbb37f911c68281ff68f2042c50f98c372d752a2f1e40`.
Final offline seal PASS: **3,024 fresh N=8 samples, zero failures; contact 0**
for 183 cosmetic envelopes against 14,409 protected solids; 47 rock lane checks
and all bearing probes pass. `FINAL-R34-EVIDENCE.json` binds the final hash,
runtime/preservation checks, completed dense sweep and comparison-board hashes.

Read R2 RESULT, SBS-R2, TARGET, C1 final lessons, sections/LESSONS, repository
PLAYBOOK and the existing CC0 Quaternius licence/kit fitting code. The separately
titled Keystone Roblox Process Playbook was not found in local active-work notes;
its exact contents remain UNKNOWN. Existing renderer, kit loader and licensed
Rock_Medium_1 FBX were reused. No new external assets or dependencies.

R3 addressed the three supplied Claude gaps (owner-reported critique): a broken
rock shell, crystal cavity, cut stone plinth, soft glow and four static sparkles;
supported kit-rock shoulders/veins, mining rack/picks, lantern posts, grouped tarp,
floor-edge veneers and cart wheels/rim/ore; and removal of the aligned distant
inverted cosmetic stack plus its complete crystal recipes. Failed terrain-bearing
trials were replaced before the accepted R3 audit/contact pass. `r3-review.rbxl`
preserves that round. R3 locked-camera review produced `GAPS-R4.md` before R4.

R4 fixes exactly those next three gaps: less repetitive broken shell cheeks and
an eight-sided crystal core covering the smooth egg silhouette; one more visible
rear-right crate/tarp/tool grouping; and cart ribs, upper steel bands and rivets.
R3/R4 use seven supported kit-rock envelopes, including all four R2 envelopes.
The seven rock envelopes pass all 47 lane checks and 25 bearing probes each.
Nonblocking loot/camp/cart children and flush floor veneers are separately checked
for contact and flags; they are not claimed to satisfy the rock lane-margin test.
Original lane/collider/query geometry stays exact.

The loot part's size, CFrame, hold range, tags, attributes, properties and original
children remain byte-exact after removing only `C2_GeodeArt`. No geode/guardian,
moving-cart, blast, lane, collider or original test/source behavior is changed.
Parked cart dressing is separate cosmetic geometry; original cart fields remain
exact. Full pre-R3 unrelated serialization is verified after removing the C2
siblings. Existing R2 presentation remains mounted; the new Dress module is
reversible/idempotent and publishes complete child assemblies only at the end.
The mounted cosmetic script creates this dressing when the place runs; the
offline exporter executes the same module for the review images. It is not
baked into the saved original Geode or parked cart.
All new art is anchored, collision/query/touch false; dressing children are also
massless. Three added lights
are shadowless, brightness <= .85 and range <= 12. Four sparkles are static art,
not an unyielding animation loop. Runtime/build/export loops yield.

Offline evidence: `AUDIT-r3/r4.json`, `CONTACT-r3/r4.json`, `VERIFY-R34.json`,
`RUNTIME-R34.json` and fresh `r34-*.log`. The original SAT/tolerance are reused;
`contact-fast.py` vectorizes only its identical AABB broad phase and runs the
unchanged SAT on all surviving pairs. Final evidence is sealed separately in
`FINAL-R34-EVIDENCE.json`; only matching-hash completed checks count. The earlier
interrupted `r34-dense.log` and superseded runs are not acceptance evidence.
Existing cart-board/cart-drive/rider/ride-contract/runner, cave tests and kit
library checks passed. Source-aware artifact check passed on R3; final dense
checker repeats all its assertions on the final artifact. Original checker and
test bodies are unchanged. All 33 mounted sources compile at O0/O1/O2. Runtime
Selene with the existing Luau config: zero errors/parse errors; 46 style warnings
are recorded in `r34-selene.log` without suppressions.

`SBS-R3.jpg`, `SBS-R4.jpg` and phone boards compare the six locked cameras.
The native scene, actual CC0 FBX geometry and cosmetic module output share fixed
cameras/approximate offline light. Roblox lighting, guardian/GUI, asset replication,
motion, phone performance, six live suites and owner acceptance remain UNKNOWN.
Author review only; independent Claude review remains pending.

**REVISIT at the four-round cap.** The treasure, cart detail and removal of the
inverted stack are visible changes. However, the shell/core still use a coarse
native-parts visual language; the protected broad walls remain boxy, and some camp
dressing is masked by original props. Compared side by side with approved cave
v2.1/TARGET, continuous chunky geology and polished treasure facets are not at
the bar. Steal an Egg objective/exit clarity remains the inherited comparison
bar, not a fresh footage observation. No fifth round is authorized or performed.

Lessons: judge silhouette in the actual player camera; measure terrain bearing
before fitting rocks; verify cosmetic loot children independently of root state.
Details and evidence are in `treasure/sections/LESSONS.md`.

## Historical rounds 1 and 2

Mounted for review; **visual REVISIT**, not owner acceptance. Canonical:
`prototype/cave-v2.rbxl`. No Studio launch/play, commit, publish, account,
purchase or external message. Only R1/R2; no next-section work.

## Delivery and preservation

Built ONLY through `prototype/cave-v2/build.luau c2-before / c2-r1 / c2-r2`.
No studio.project.json, plain Rojo or historical baseline generator.
Immediate byte-verified backup: `prototype/cave-v2.pre-c2.rbxl`, SHA256
`0aee510e523b4df49998a649b1ab792728f807396eed5816eaba05857ed7227c`.
Final SHA256: `55227b09ed9b9538a072fe2832059edb75b767ae9a5dc050e639607fb511dcf2`.

Removing only Workspace.CaveGeodeC2 and ServerScriptService.CaveGeodeC2
restores exact complete pre-C2 serialization. All 30 original mounted sources,
C1 final art/presentation, all original geometry/flags/tags/attributes and
lighting remain exact. Geode/guardian behavior, carts, blasts, lane/collider
geometry and all six Studio suite bodies are unchanged. **32 sources compile
at O0/O1/O2.** VERIFY.json records source hashes and full preservation.

R1 contains three large slate rock silhouettes only, reused from the existing
CC0 Quaternius Rock_Medium_1 FBX. R2 freezes all three and addresses only
GAPS-R2's three gaps: one larger east shoulder, complete bounded small crystal
group simplification, and quieter cosmetic cliff backing. Four final rock
envelopes; **no new lights**, crystals, signs, crates or filler.
R2 hides 23 complete small ornamental groups and quiets 17 larger groups,
533 crystal components total; 595 fully contained nonphysical cliff faces
receive only Color/Material changes at runtime. Actual Geode, guardian,
oversized decorative crown and route/cart labels remain untouched.

All additions anchored; CanCollide/CanQuery/CanTouch false. Tinted runtime
meshes clear TextureID and SurfaceAppearance. Existing loader/templates are
unchanged. Complete kit staging, bounds/lane validation and bounded retry
retain native fallback silhouettes on failure. Build/export/runtime loops yield.
Appearance edits require every component corner inside C2 bounds, preserve
physics/query/metadata, and are reversible/idempotent (VERIFY.json).

## Checked offline

- AUDIT-r1/r2: **47 lanes, zero margin or support errors**; 25 bearing probes
  per rock, full section bounds, flags and light limits checked.
- CONTACT-r1/r2: **contact 0** against 14,409 original physical solids at .035
  tolerance. Conservative full-envelope OBB SAT overbounds wedge shape.
  Nonphysical cluster overlaps are intentional; this is not engine physics.
- VERIFY: full unrelated serialized state exact, appearance whitelist/full-corner
  bounds/reversibility/idempotence, C1/C2 execution-order equality, mounted-source
  parity, all five locked player eyes clear of authored
  solids/new envelopes, and source compilation pass. Overview is non-player.
- RUNTIME: actual mounted C2 script with textured MeshPart/SurfaceAppearance
  fixtures passes tint clearing, transforms, flags, full-envelope lane margins,
  staging/failure cleanup/retry, idempotence and exact frozen R1. Four runtime
  rocks; three expected injected failure warnings. Real asset replication UNKNOWN.
- Existing tests, cart-board-check, cart-drive-check, rider-check,
  ride-contract-check, runner-check and kits/library-test PASS. These exercise
  production logic in offline mocks; they are not six live Studio suite passes.
- Source-aware artifact-only check PASS: original SelfTest, strict floors,
  source parity, scene scope, kit bounds/query/fence joints and policy. The
  unchanged checker uses only its exact pre-C2 mounted KitLibrary for the expected
  loader read; shared on-disk loader has unrelated later Meadow edits. Assertions
  and gameplay source are not modified. Logs record expected retained-kit rejects.
- Fresh final-artifact N=8 drop sweep: **PASS — 3,024 samples, zero failures**,
  1,898 retained kits / 279 excluded / 16 types. DENSE-FINAL.json and
  FINAL-EVIDENCE.json seal the exact final input hash and unchanged checker.
  Only dense-drop-final.log / final matching OFFLINE-INPUT-8.json count.
  dense-drop-aborted-r1.log was stopped before completion and is not evidence.
- Runtime Selene: **0 errors, 16 style warnings** (multiple statements per line),
  no suppressions. See selene.log; source compiles at all three levels.

The six live suites — SelfTest, DropSampleTest, BoardingTest, LoopTest,
CartRideTest, BlastPolicyTest — remain **UNKNOWN / NOT RUN** in this task.
No assertions, distances, tolerances, timers, gates or test bodies were weakened.

## Visual review and limits

SPEC.md, REFS.jpg, built-in generated TARGET.png/PROMPT.md, six locked
CAMERAS.json views, BEFORE, PRE-R1/R2, SBS-R1/R2 and phone boards are supplied.
Inspected all R1/R2 camera renders and final phone board. Camera views: arrival
on the main approach, close to the geode, main/cart/cave choices looking out,
and overview. Native geometry and actual CC0 rock FBX share matched fixed cameras
and approximate lighting. Deferred original kits, live guardian, GUI text,
Roblox bloom/fog/falloff, motion and avatar occlusion are not reproduced.
TARGET changes topology, backgrounds, gem facets and lighting; it is aspiration,
never build evidence or authorization to reshape routes/colliders.

Named comparison bars: Steal an Egg objective/exit clarity, approved cave v2.1
chunky slate geology, Catastrophic Horse Racing anticipation/consequence.
These are inherited project bars, not fresh observed footage or ranking claims.
Side-by-side self-review: R2 reduces nearby crystal competition and the geode
remains clear; additional east rock gives a larger visible shoulder in close
and cave views. The actual cart remains conspicuous. **Still REVISIT:** most
safe rear boulders remain masked; broad block walls still dominate; oversized
ornamental crown outside the full C2 envelope remains luminous. The target's
continuous chunky framing is not achieved. Outgoing views change little, and
their live label/guardian readability is UNKNOWN. No extra round follows.

Independent Claude visual/live review, six live suites, actual fitted-kit
appearance, frame cost, motion/phone play and owner acceptance remain
**PENDING/UNKNOWN**. Compare all six cameras during Claude's final review;
do not mistake offline preservation for visual approval.

Read first evidence: LESSONS, SECTION-CHECKLIST, ROCK-PASS (atlas/live light),
cave design/style/reviews/routes, current pipeline and mounted sources, C1
final evidence, HANDOFF-NOW and hermes/REFS. Requested hermes/CAVE-REFS.md
is absent. Repository PLAYBOOK read; exact separately titled Keystone note
unavailable/UNKNOWN. Generated source scene dumps remain gitignored/untracked.
Delivery stays in the requested repo, overriding the general Desktop preference.

## Lessons added to sections/LESSONS.md

1. When supported framing is hidden, inspect every locked player view before
   multiplying it, because safe placement can produce little visible improvement.
2. When crystals compete with treasure, quiet whole bounded groups before
   adding glow, because fewer coherent groups improve focus without behavior edits.
3. When the crown crosses section bounds, preserve it and report the gap,
   because a target image cannot expand cosmetic scope.
