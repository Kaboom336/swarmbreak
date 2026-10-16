# S3 — delivered; visual REVISIT at four-round cap

Canonical place: [guardian-greybox.rbxl](../../../slice-v2/prototype/guardian-greybox.rbxl). Backup, byte-verified before Rojo: `guardian-greybox.pre-s3.rbxl` beside it. Module: [Section3.luau](../../../prototype/meadow-v4/Section3.luau). No commit or publish.

Review [SBS-R4.jpg](SBS-R4.jpg), [TARGET.png](TARGET.png), [CRITIC-R4.md](CRITIC-R4.md), and [RENDER-LIMITS.md](RENDER-LIMITS.md). **Visual acceptance is not met.** The final independent critic finds the mine corridor/support rhythm and warm lanterns working, but junction enclosure, mining/track identity and two separate visible destinations still miss TARGET. Four rounds are spent; no post-critic cosmetic fix or fifth round.

## Built

Eight five-part timber ribs at 11-stud stations; paired seven-piece lantern cages with warm points and downward track cones; nine fitted three-piece wall corbel/shoe/bolt groups; three four-piece mounted pickaxes; two five-part decision boards with physical arrows and native UIStyle EXIT 1 / EXIT 2 text; two roof-attached exit light assemblies. **207 S3 native cosmetic parts**, all CanCollide/CanTouch/CanQuery=false, in island-local coordinates under the unchanged MeadowV4 pcall guard. Lowest new architecture is above 9.5 studs. No ground clutter or new climbable collider.

Every prop has a job: ribs shore the old mine, corbels show wall attachment, tools explain abandoned work, lamps reveal the existing track, and numbered arrows map directly to TunnelPolicy.Exits. Cart/rails/crates were omitted because no supported interior pocket clearing all lanes was established. One candidate at (-66,0,50) lies outside the policy interior and was rejected. Do not mistake omission for target-level mining-story success.

The complete existing warm floor, dirt/stone patches, edge detail, palettes, lane tags, query/touch/collision geometry, route data, Keeper cover and gameplay producers remain exact. No plain-slab replacement, mud overlay, fake fixed rockfall target, dust timing or gameplay change. Width 14 / Ceiling 24 and all tuning remain byte-exact through preserved policy source. Overhead architecture spans the path above the seven-stud audited player envelope; floor props have no lane-margin exception.

## Bounded rounds

| Round | Before-round evidence | Work | Blind result |
|---|---|---|---|
| R1 | PRE-R1.jpg / GAPS-R1.md | Silhouette only: repeated structural frames, light origins, retained enclosed shell | REVISIT: cage shape, track continuity, exit pair |
| R2 | PRE-R2.jpg / GAPS-R2.md | Angled haunches, source placement, additional junction evidence; still no dressing | REVISIT: branch, suspended-looking uprights, track lighting |
| R3 | PRE-R3.jpg / GAPS-R3.md | Frozen R2 arch geometry; fitted corbels, lantern cages, arrow boards | REVISIT: floor craft, mining/contact story, destinations |
| R4 | PRE-R4.jpg / GAPS-R4.md | Track cones, three stored pickaxes, EXIT 1 / EXIT 2 labels | REVISIT; cap reached |

Each round retains SBS, phone board and one independent blind review. R1 was rendered before any new dressing. R2's 40 core rib parts were then frozen; source/geometry equality is checked in the final audit. This geometry freeze was a constrained implementation decision, **not a silhouette acceptance claim**: target-style ground posts cannot fit the protected full-width lane plus margins. The critics' rejection is retained rather than relabeled approved.

The explicit-basis repair and corbel fit corrections occurred before their round's blind review. R3 critic inputs are frozen in `critic-input-r3/`: the initial renderer omitted an existing S2 SurfaceGui label. Corrected R3 and final R4 render the source-authored labels with actual face orientation. S2's SHORTCUT faces outward, so its inward back remains genuinely blank; renderer omission was not the whole explanation. S2 source was never changed, and the critic's destination concern is retained.

## Cameras and evidence

`CAMERAS.json` records three literal 18-stud Surface-follow cameras, five 18-stud interior trailing views (entry, middle, far, reverse, junction), and an overview cutaway. Every eye and nominal walking-root point is outside retained query/collider solids; all horizontal trailing offsets measure 18 studs (`CAMERA-CLEARANCE.json`). These are static offline cameras, not a live walking-avatar recording.

TunnelPolicy.Surface is the **Keeper's exterior interception route**; `inside()` excludes its x=-100 segment. Those three requested views are retained, but interior judgments also use the actual tunnel views. The branch travels +X/east and therefore reads screen-left while looking +Z; the generated TARGET's right bend is aspiration. Do not change policy to match the concept.

Final physical aperture sampling has clear rays to both exit regions from the middle/junction views. This does **not** prove two visually separated portals: framing and cosmetic occlusion still fail the blind image judgment. Exact protected geometry plus 4,050 Keeper segment comparisons / 450 upward rays over 50 seeds show no new openings; 25 baseline upward misses remain unchanged. Cutaway roof visibility is only a render setting.

## Checked / unknown

- PASS: 73 mounted sources compile at O0/O1/O2; 72 existing sources preserved. Delivered serialized Workspace equals the pre-S3 backup; temporary proof islands are not installed.
- PASS: duplicate-sensitive protected physical/query/touch/floor/lane/tag signatures exact, all retained native floor/edge art exact, existing kit placements exact, frozen 40 R2 rib parts exact. Final R4 native parts/lights/kits and Section3 source equal the delivered builder (`PARITY.json`).
- PASS: 207 new parts audited; zero penetration, support, kit or one-stud lane-buffer errors at the existing .035-stud tolerance, over the seven-stud player envelope. This is an offline conservative OBB/contact graph, not engine contact simulation.
- PASS: nonzero origin translates exactly once, late existing kit origin/support, cosmetic flags, intentional failed-section warning/island survival, all nine suite coordinator names; existing policy/core persistence/replay/reset contracts.
- PASS: existing 50-seed walking-floor/cliff/cover check. Native production drop coverage is recorded separately below; the legacy check is not a live Humanoid traversal claim.
- PASS: fresh offline production N8 DropSample on the delivered place: **31,824 samples / 20 routes / zero failures**. Workers executed 14,904 + 8,280 + 8,640 cases with exact disjoint complete-route coverage; the original lattice/resolver and tolerances are unchanged (`final-DROPS.json`). No inherited S2 result.
- UNKNOWN: all nine live StudioPassAll suites, imported mesh/runtime light/text parity, avatar/camera movement, device performance, shortcut travel benefit and owner acceptance.

Use [STUDIO-CHECKS.md](STUDIO-CHECKS.md) for owner verification. Final hashes and actual DropSample totals are in `FINAL-EVIDENCE.json`. Normal and phone-size SBS-R4 were inspected; the remaining visual misses are retained. Existing reusable native build/render/contract code and CC0 Kenney/Quaternius library were inspected; no external code dependency or new uploaded asset was added. Local promotional 99 Nights imagery is the named warm-light hierarchy reference, not gameplay evidence. Built-in imagegen produced the target; exact prompt is in `TARGET-PROMPT.md`.

## Lessons

1. When Surface names a Keeper route, add actual interior player cameras, because route names alone do not establish the walking viewpoint.
2. When an offline beam rotation disagrees with its endpoints, use an explicit basis and rerun contacts, because plausible images can hide invalid orientation.
3. When a rendered sign looks blank, inspect SurfaceGui export and face orientation, because an outward label does not establish interior readability.
