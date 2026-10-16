# S2 — Close-out: round 3 plus cosmetic fixes; REVISIT

## Close-out

**REVISIT. S2 stops at round 3 plus the small fixes below; the four-round cap is reached.**
Claude's live Studio round-4 judgment was **not better than round 3** (owner-reported;
`studio-r4-walk.jpg` and `studio-r4-mouth.jpg` were also inspected here). The warm
paving/edge-stone path regressed to a flat slab, the clipped cue remained, SHORTCUT
was obscured by the header, the tiled ceiling remained visible, and the barrel
left the orchard group. Round 4 is retained below as historical failed evidence.

Restored the mounted sources from `guardian-greybox.pre-s2r4.rbxl` before the fixes.
Only Section2 differed in the R4 place; its source was restored with apply_patch.
The rebuilt baseline matched **all 34,793 native part signatures exactly**, using
duplicate-sensitive comparison. Final physical/query/touch/floor/lane/tag signatures
remain exact, including hill/wall geometry, path material and edge-stone detail.
`guardian-greybox.pre-s2close.rbxl` was deserialized and byte-verified before Rojo.

Cosmetic fixes: removed the actual clipped `OutsmartCorner` floating “CHARGE → CUT
ASIDE” cue (it runs after Section2, explaining why the previous Section2 cleanup
missed it); removed detached upper rock stacks 3/4/6/7 and their invisible anchors;
lowered and projected the wooden SHORTCUT board below the unchanged header.
The full SHORTCUT word is readable in the inspected locked mouth-camera render
`close-after-mouth.png`. Native Studio text/material rendering remains unverified.
The round-3 barrel, crate, orchard and remaining rock cladding placements are retained.

**What blocked it:** the mouth sits under a big overhang with box walls. Dressing
cannot fix that silhouette; reshaping the solids in one round broke the path look.
TARGET remains the supplied silhouette aspiration; Grow a Garden remains the
named orchard/supply-grouping reference. No new visual round or parity claim.

**Next time:** prototype the silhouette with a blockout and player-camera render
before dressing. Keep the warm path material and edge-stone look as locked
requirements. When late-built UI survives cleanup, find its actual producer and
remove the cosmetic cue there, because section ordering can recreate it.

Close-out checks and hashes are recorded in `CLOSE-SIGNATURES.json`, `close-AUDIT.json`,
`close-contact.log`, `close-contracts.log`, `close-behavior.log`,
`close-50-seed.log`, `close-DROPS.json` and `close-drop-final.log`.
**Checked final result:** 72 sources compile at O0/O1/O2, 70 unrelated sources
preserved; strict protected signatures equal R3. Contact audit: 242 native
cosmetics and 18 kits, **zero errors**. Offline origin/late-kit/failure-isolation,
policy/persistence/replay/coordinator/reset contracts and the existing 50-seed
walking-floor/cliff/cover check pass. Offline N8 DropSample: **31,824 samples,
20 routes, zero failures**, complete disjoint route coverage; no tolerance changes.
`FINAL-EVIDENCE-CLOSE.json` pins the delivered artifact and evidence hashes.
Delivered place: `../../../slice-v2/prototype/guardian-greybox.rbxl`.
No commit or publish. All nine live StudioPassAll suites remain UNKNOWN.

## Round 4 — west path + tunnel mouth, 2026-10-16

**Checked result: still a visual MISS.** `SBS-R4.jpg` compares round 3 / round 4 /
TARGET with the same locked walk, mouth and overview cameras; the normal and
phone boards were inspected. Sky is visible, but **2.10% versus the required 8%**.
Mouth prop coverage is **17.33% versus 18%**. The remaining tiled inner roof and
rectangular backing still dominate. The beveled corner soffits and longer timber
braces improve the opening, but this does not read like TARGET's tall rock arch.
Do not call this TARGET parity, owner acceptance, or a complete fix of the diagnosis.

Delivered `../../../slice-v2/prototype/guardian-greybox.rbxl`. The immediate
`guardian-greybox.pre-s2r4.rbxl` backup was deserialized and byte-verified **before
Rojo**. Only mounted `ReplicatedStorage.MeadowV4.Section2` changes: **72 sources
compile at O0/O1/O2; 71 other sources, all policy/data/routes, gameplay, Keeper,
nine suite implementations and coordinator remain exact**. Serialized Workspace
is unchanged. No commit, publish, purchases, account creation or external messages.

Structural scope: **68 explicit exterior hill edits and 112 hill-cap removals**.
Upper approach mass is cut back to the existing diagonal mouth plane; high side
walls are lowered while their lower barrier volumes remain. Two exterior hill
solids receive **56.3° and 71.6° nonphysical slope shells over their original
collision cores**. The cores retain their exact original shape, size, position,
query/touch/collision flags and tags; only their visual opacity/palette changes.
The shells have no collision, touch or query participation. A final engine-default
audit found CharacterMaxSlopeAngle **89**, so colliding wedges were rejected:
steepness alone would permit a new climb. This agrees with the
[official Humanoid documentation](https://create.roblox.com/docs/reference/engine/classes/Humanoid#MaxSlopeAngle).
Player slope settings remain unchanged. The east visual wedge was shortened after the native resolver caught it
entering the south crosslink; final native clearance has zero failures. Interior
rock courses, rough cores, facets, closed vaults, bait cover, PvP court and all lane
floor parts/tags/attributes/palettes remain exact. `REMOVED-R4.json` independently
checks **7,342 other protected parts**, including duplicate-sensitive source
signature protection in the build pipeline. This is structural work, but it has
not successfully removed the *visible* corridor-like roof impression.

Reused the inspected existing CC0 Kenney/Quaternius kits2 and KitLibrary; no new
dependency. Removed unsupported upper clusters and added three-rock clusters
fitted to each reshaped shoulder. Final contact audit: **234 native cosmetics and
29 kits**, zero penetration, unsupported assembly, kit-support or one-stud lane
margin failures through the seven-stud player envelope. Imported original FBX
bases are checked separately. Mounted stone footings/corbels remain: an attempted
grounded frame failed against protected lanes and rock courses and was rejected.
The header is thinner than R3 (2.1 rather than 3 studs); two triangular rock
soffits and larger diagonal braces bevel its upper opening corners.

STUDIO-R2-FINDINGS remediation:

- Removed the old floating pebble-column decorations and unsupported upper rock
  anchors in the affected view region. The final S2-bounds export contains no
  positive-height `Round4StackedRock` columns.
- Added guarded removal of old nonphysical BRIDGE/RIDE text boards in the west
  mouth area. The exact clipped three-line owner-reported board was not present
  in the offline export; **its live removal remains UNKNOWN**, requiring Studio.
- Retained two facade lanterns plus four interior pairs; the locked cameras show
  six and seven lamps rather than a row of tiny lights.
- Removed floating `StonePathEdge` pieces in the approach; changed existing
  nonphysical grass-edge thickness downwards. Replaced the raised cosmetic paving
  pieces with a **0.01-stud query/collision/touch-false finish** following existing
  lane transforms. Wide cosmetic shoulder panels receive the same dirt palette;
  this closes the abrupt green road interruption. All finish surfaces are excluded
  from S2 prop masks and receive no walking tags or lane IDs. **Black side gaps
  remain visible in the comparison; grass-seam craft is not fully resolved.**
- Wall tones, kits2 groups and sparse attached ivy remain, but the large flat
  surfaces still miss the reference's sculpted rock coverage.

| Locked camera measure | Goal | R4 |
|---|---:|---:|
| WALK visible S2 props / frame | >=10% | 17.15% PASS |
| MOUTH visible S2 props / frame | >=18% | **17.33% MISS** |
| MOUTH timber/lantern horizontal span | >=25% | 81.48% PASS |
| MOUTH pale-grey source-material share | <=9.51% | 3.11% PASS |
| MOUTH largest same-colour wall region | <=12% | 7.37% PASS |
| Visible lamps WALK / MOUTH | 4–8 | 6 / 7 PASS |
| Fixed destination ROI bright pixels | >0 | 1,284 PASS |
| Facade, braces, footings and entrance lamps | fully in frame | PASS |
| WALK sky / frame | >=8% | **2.10% MISS** |
| Opening upper corners | rounded/beveled | two WedgePart soffits PASS |

`METRICS-R4.json` defines measurements. Sky uses a primary-camera render-depth
background mask, with actual FBX occlusion; native geometry cannot count as sky.
The arch gate records actual triangular geometry, not a claim that the whole
cliff now reads as a convincing arch. Source-albedo connected-wall masks remain
independent of lighting. Grow a Garden remains the named orchard/supply grouping
reference; TARGET is the supplied generated mine-mouth aspiration.

One independent blind image-only critic and one final correction are retained
in `CRITIC-R4.md`, `r4-iteration0-*` and the final images. Its worst gap was the
entrance silhouette/outdoor exposure. The correction reshaped the shoulders,
re-fitted their clusters/ivy, exposed longer braces and addressed the path finish.
**That correction did not close the worst gap.** No second critic verdict or owner
approval is claimed.

Offline evidence: `r4-deliver.log`, `r4-AUDIT.json`, `REMOVED-R4.json`,
`r4-contact-final.log`, `r4-after-mesh-contact.json`, `r4-contracts.log`,
`r4-behavior.log`, `r4-50-seed.log`, `r4-CLEARANCE.json`, `r4-ENCLOSURE.json`,
`r4-drop-final.log` and `FINAL-EVIDENCE-R4.json`. The existing 50-seed walking-floor,
cliff/cover checks pass. Native actual-map resolver: **12,667 checks, zero failures**;
loop/PvP preflight: **850 checks, zero failures**. Origin translation, late kits,
cosmetic flags and intentional section failure isolation pass. Policy/domain
save/load/replay and coordinator/reset/failure/timeout contracts pass; the offline
harness adapts its historical eight-suite fixture to the unchanged nine-suite
production coordinator and provides the current temporary-fixture map stub.

Additional 50-seed convex geometry comparison: **4,050 Keeper-to-interior segments
and 450 upward rays**, no newly opened sight line or upward hole behind the mouth
plane. **25 upward misses already exist in the baseline** and are retained, not
silently certified enclosed. Wedge slopes and unchanged walking surfaces are
offline evidence; actual Humanoid climbing and Keeper runtime sight remain UNKNOWN.

N8 DropSample uses the existing production Swap/resolver harness, conservative
imported-model boxes and all route lattice/knock samples. Three disjoint complete-
route workers execute exactly the same eight along-segment positions, three edge
offsets and three knock offsets. The merge asserts every route occurs exactly
once. Final result: **31,824 samples across 20 routes, zero failures, PASS**.
The tested artifact and hash are retained
in `r4-drop-input.rbxl` / `r4-DROP-INPUT.json`; `r4-DROP-PARITY.json` proves exact
delivered geometry, flags, tags, attributes and kit placements. No test or tolerance
was weakened for the floor finish. Results are recorded in FINAL-EVIDENCE-R4.

All nine **live StudioPassAll results remain UNKNOWN**: no callable Studio
integration. Native Roblox materials/text/lights/Beams, imported mesh contact,
device performance and owner judgment require Studio. The exact Keystone Roblox
Process Playbook was not found in the local search; its contents remain UNKNOWN.

Lessons: when a silhouette gate fails, retain the failed result rather than padding
coverage; when a wedge changes its footprint, run the actual route resolver before
accepting it; when judging climb safety, inspect the actual Humanoid slope setting
rather than assuming that a steep-looking surface cannot be climbed. See `../LESSONS.md`.

## Round 3 — west path and tunnel mouth, 2026-10-16

Delivered `../../../slice-v2/prototype/guardian-greybox.rbxl`. Immediate backup `guardian-greybox.pre-s2r3.rbxl` was deserialized and byte-verified before Rojo. Only mounted `ReplicatedStorage.MeadowV4.Section2` changes: **72 sources compile at O0/O1/O2; 71 other sources preserved**, including gameplay, Keeper, coordinator and all nine suite implementations. Serialized Workspace is equal; rebuilt solid geometry, query/touch flags, tags, attributes, lane and floor palettes are equal. No commit or publish.

Reused the inspected CC0 kits2 Kenney/Quaternius assets and existing KitLibrary/build/render pipeline. Visible authorized wall solids now use three warm grey-brown tones with Rock/Slate; **139 Color/Material-only edits** are recorded in `REMOVED-R3.json`. Replaced the thin round-2 rock stacks with **seven clusters of 3–7 fitted original rock meshes, 25 rocks total**, tangent to existing wall/shoulder faces, with varied size and tone. These fitted cladding meshes deliberately have shallower proportions than the original uniform rocks. Their conservative envelopes pass strict horizontal one-stud lane margins at every height. Some remain partly hidden in the locked mouth view; their count is not a claim of target-level rock coverage.

The two timber facings are wider and taller, with exposed post grain, visible stone corbel footings, header and stronger knee braces. Both mounted bases, posts, header, braces and facade lanterns are fully in the mouth frustum: bounds **(110.84,49.00)..(1154.10,314.00)**. Bases sit at Y7.5–8, above the protected player envelope, tied through the existing wall brackets/contact assembly. They are mounted corbels, not grounded posts. Sparse ivy replaces the bulky green pads, and additional roots/ivy trail down the east shoulder's actual solid front face above headroom. Lanterns are 20% larger on the facade and 35% larger inside: one facade pair and four interior pairs, at Z78/62/46/32 (16/16/14-stud intervals). The bright end-wall glow remains; no new exit is implied.

The plank-to-tunnel transition uses **41 palette-only cosmetic paving edits**, with a worn dirt/stone Ground gradient. No overlay strips were added, so no new surface thickness or DropSampleTest tolerance exception exists. Lane Color/Material and every walking query/tag remain exactly unchanged. All three orchard trees, barrel, crate and shovel remain at the left supply pocket. The barrel/crate read in the walk view, while the shovel and cropped orchard canopy remain weaker than TARGET.

| Locked camera measure | Goal | Round 3 |
|---|---:|---:|
| WALK visible S2 props / full frame | >=10% | **18.67% PASS** |
| MOUTH visible S2 props / full frame | >=18% | **21.30% PASS** |
| MOUTH timber/lantern horizontal span | >=25% | **81.48% PASS** |
| MOUTH pale-grey source-material share | <=9.51% (half R1) | **2.24% PASS** |
| MOUTH largest same-colour connected wall region | <=12% | **6.67% PASS** |
| Visible lanterns, WALK / MOUTH | 4–8 | **6 / 8 PASS** |
| Fixed R2 destination ROI bright pixels | >0 | **1,286 PASS** |

`METRICS-R3.json` defines exact measurements. Flat-wall share uses full-resolution, four-connected source-albedo masks for the three wall tones, with actual original FBX occlusion. Lighting and shadow variation cannot fragment these regions. Lantern count uses separate occlusion-aware masks of each shipped lantern core with at least one visible pixel, excluding the destination glow. Source-colour variation can pass this gate while the rectangular silhouette still looks artificial; the image judgment remains separate.

One independent blind image-only critic and one visual correction are retained in `CRITIC-R3.md` and `r3-iteration0-*`. Worst gap was the beam reading without a complete frame. Correction exposed/widened post faces and bases, thinned foliage, strengthened joinery, enlarged/reduced lanterns, blended existing threshold cosmetics and added shoulder trails. `SBS-R3.jpg` and phone board were inspected against round 2 and TARGET from identical locked cameras. Best named reference remains **Grow a Garden** for readable fruit/supply grouping; TARGET supplies the sculpted mine-mouth aspiration. The reference has a broad faceted rock portal, grounded full-height posts and a clear orchard group; this candidate still has protected rectangular walls, a diagonal inherited opening, mounted short post facings and tightly cropped orchard props. **Numeric gates pass; TARGET-level craft is still incomplete and owner acceptance is UNKNOWN.**

Checked on the final source: `r3-deliver.log`, `r3-AUDIT.json`, `REMOVED-R3.json`, `r3-contact-final.log`, `r3-after-physical-contact.json`, `r3-after-mesh-contact.json`, `r3-contracts.log`, `r3-behavior.log`, `r3-50-seed.log`. Final contact audit covers **254 native cosmetics and 30 kits**, with zero physical/kit penetrations, support failures, unsupported assemblies or lane-buffer failures. Existing origin translation, late-kit placement, cosmetic query flags and intentional dressing-failure isolation pass. Existing policy/core persistence/replay, coordinator/reset/failure/timeout and 50-seed walking-floor/cliff/cover checks pass; no tests were edited.

All nine **live StudioPassAll suites remain UNKNOWN**: no Studio integration is available. Offline native materials do not reproduce Roblox Rock/Slate/Wood texture; point lights, text and Beam shafts remain approximations, older kit swaps remain native proxies, and new kits use original FBX. Actual Studio imports, lighting, contact and device performance need runtime evidence. The Keystone Roblox Process Playbook was not found in local active-work filenames/content search or connected exact-title Page search; its contents remain UNKNOWN. Supplied owner scope and local section process were followed.

Lessons: when foliage hides the timber, expose faces and bases first; when a protected wall prevents grounded dressing, plan tangent envelopes and corbels against the whole lane buffer; when numeric image gates pass, retain the blind critic's silhouette judgment instead of declaring TARGET parity. See `../LESSONS.md` and `FINAL-EVIDENCE-R3.json`.

## Round 2 — widened mouth scope, 2026-10-16

Built and delivered `../../../slice-v2/prototype/guardian-greybox.rbxl`; byte-verified immediate backup `guardian-greybox.pre-s2r2.rbxl` was saved before changes/Rojo. No commit or publish. Only the mounted Section2 source changes from that backup: **72 scripts compile at O0/O1/O2; 71 other sources preserved**, including all nine StudioPassAll suite implementations, coordinator, gameplay and Keeper policies. Serialized Workspace remains equal. Section2 still builds in island-local coordinates under the existing section pcall guard; offset and intentional-failure contracts pass.

Owner-authorized cosmetic cleanup removes the right-seam arch blockers, revealed slabs and competing near-mouth crystals. `REMOVED-R2.json` contains all **188 removed/replaced native cosmetics**, their original geometry, 429 cosmetic palette edits and the exact 139 solid palette edits. Physical hill/rock edits change **Color/Material only**; the independent immediate-backup audit compares every other exported solid field, all collider attributes/tags, query flags, and every lane/floor palette. No lane, bait cover, PvP court, gameplay collider, tag or gameplay source changes. Palette permission is not used to count existing hill solids as S2 props.

Reused inspected CC0 Kenney/Quaternius kits2 and KitLibrary. Added three five-rock wall clusters with size variety, uniform original mesh proportions, invisible tangent support envelopes and cosmetic/query-false imported parts. All fifteen new rock envelopes also pass a strict horizontal one-stud lane-buffer search, including above the player envelope. The final unchanged contact audit checks 271 native cosmetics and 20 imported kit placements: **zero physical penetrations, kit penetrations, support errors, floating assemblies or lane-buffer errors**. Original FBX bases are checked separately. These are conservative box/support checks, not a claim that every mesh vertex touches its wall naturally.

The lower, wider timber facade, header, SHORTCUT board, both entrance lanterns and braces are inside the locked mouth frustum. Entrance lamps hang below the braces; the sign projects from the header to prevent coplanar faces. Seven warm wall-bracket lantern pairs follow the tunnel at approximately twelve-stud intervals (the 24-stud row shifts to 27 to clear an existing angled facet). Soft mouth Beam shafts remain. A bright, supported end-wall glow lights the far visual destination; **this is a cosmetic daylight cue, not a newly opened exit**. Keeper sight/stealth policy remains byte-identical.

| Locked camera metric | Goal | Round 1 | Round 2 |
|---|---:|---:|---:|
| WALK visible S2 props / full frame | >=10% | 12.27% | **14.66% PASS** |
| MOUTH visible S2 props / full frame | >=18% | 8.09% | **19.13% PASS** |
| MOUTH timber/lantern horizontal span | >=25% | 77.03% | **80.78% PASS** |
| MOUTH pale-grey source-material pixels | <=half R1 | 19.03% | **2.01% PASS** |
| MOUTH bright pixels in fixed interior destination ROI | >0 | not scored | **1,279 PASS** |
| MOUTH facade + entrance lantern bounds | fully in frame | cropped | **(119,45)..(1153,270) PASS** |

`METRICS-R2.json` defines both grey measures. The occlusion-aware pale material mask uses source RGB max >=120, saturation <=20%, and Rock/Slate/Concrete/SmoothPlastic; it excludes S2 prop masks. It drops from 19.0252% to 2.0115% of the full mouth frame (89.43% reduction). Independent rendered-PNG neutral pixels (max channel 48..224, saturation <=22%) drop from 5.6341% in the original round-1 image, or 4.7224% in its matched-renderer version, to 0.0028%. Both measures satisfy half of round 1. The destination ROI is fixed at x560..650/y310..420, R>=200/G>=140/B>=70. Frustum bounds establish no cropping, not zero self-occlusion of every bolt.

`SBS-R2.jpg` and `SBS-R2-phone.jpg` were inspected at normal and phone size: round 1 / round 2 / generated TARGET, walking and mouth cameras plus the identical overview. `r2-baseline-*` rerenders round-1 geometry with the same final renderer as round 2; original round-1 `after-*` images remain. The point-light proxy now lets light escape its own opaque lamp-core mesh while retaining wall shadows. Both comparison columns use that correction. Runtime lights still need Studio; text uses the same labelled local font approximation and shafts remain labelled effect proxies.

Two blind image-only reviews are retained in `CRITIC-R2.md` and linked from `CRITIC.md`, with `r2-iteration0-*` and `r2-review1-*`. Worst gap both times was the disappearing route. Correction 1 cleared complete revealed crystal clumps, warmed existing cosmetic paving and added rock groups. Correction 2 strengthened the lit destination, repaired offline lamp self-shadowing, lowered unobscured entrance lamps and increased in-frame timber/ivy coverage. Contact defects were fixed rather than waived. **Measured offline goals pass; TARGET-level craft and owner approval are not claimed.** Compared with Grow a Garden's fruit/story grouping and TARGET's sculpted entrance, broad flat wall faces, thin imported rock cladding and the weak orchard remain qualitative gaps.

Checked now: `r2-build-final.log`, `r2-AUDIT.json`, `r2-contact-final2.log`, `r2-after-mesh-contact.json`, `r2-contracts.log`, existing policy/core/coordinator/reset checks in `r2-behavior.log`, and existing 50-seed fixed-v2 checks in `r2-50-seed.log`. All nine **live StudioPassAll suites remain UNKNOWN** because no callable Studio integration is available; no live green result is inherited. `STUDIO-CHECKS.md` remains the live test route. The Keystone Roblox Process Playbook was not available locally; connected search returned an AI Roblox page but fetch failed, so its contents are UNKNOWN. Supplied owner rules and local section process were applied.

Lessons: when pale scene blockers dominate, remove cosmetic blockers and recolor only authorized solid palettes before adding small props; when an offline lantern glows but lights nothing, check whether its own opaque mesh traps its PointLight; when a tunnel bends, measure the actual destination glow and preserve its gameplay boundary rather than claiming an invented exit.

## Round 1 record — visual acceptance NOT MET

Canonical place: `../../../slice-v2/prototype/guardian-greybox.rbxl`. Byte-verified backup before Rojo: `guardian-greybox.pre-s2.rbxl` beside it. No commit, publish, purchases, accounts or external messages by this agent. The workspace contains pre-existing work; only three mounted sources differ from the immediate backup: new Section2, its late KitSwap hook, and removal of the mouth's floating OutsmartExit cue. Serialized Workspace and rebuilt physical/floor/lane/tag signatures match.

Built one section: a shady orchard supply pocket and timber mine-mouth facade, two bracket-supported timbers with diagonal braces, bolted joinery, paired amber lanterns, attached ivy/roots, a wooden SHORTCUT board using shared FredokaOne/UIStroke, two subtle Beam shafts, three varied fruit trees, a 3.4-stud barrel, crate, shovel and three varied kit rocks. Kits2 Kenney/Quaternius CC0 licences, original FBX and KitLibrary were inspected and reused. Removed nine S2-owned cosmetic left arch voxels and superseded nonphysical mine trim; preserved the bait cover, every lane/collider/floor tag, S1 right seam and S3 interior. Exact owner-reported RECOVERY -> CYAN wording was absent; the current source-created floating cyan cue at the mouth was removed.

| Locked player view metric | Goal | Measured | Result |
|---|---:|---:|---|
| WALK: visible S2 props / full frame | 10% | 12.27% | PASS |
| MOUTH: visible S2 props / full frame | 18% | 8.09% | MISS |
| MOUTH: timber/lantern horizontal span | 25% | 77.03% | PASS |

Occlusion-aware object-index masks count new S2 native parts and original imported kit meshes, excluding floor and shadows. The doorway spans the frame but occupies too few visible pixels; span alone does not establish a rich entrance. Grow a Garden is the named grouping/fruit reference, with 99 Nights informing the warm destination in shade. `SBS.jpg` compares identical before/after walking and mouth cameras plus overview against the generated target. `SBS-phone.jpg` is the small-size review. The generated target invents broader shoulders and a brighter direct tunnel endpoint; it is aspiration, not evidence of existing geometry.

Two independent blind image reviews and two correction rounds are retained in `CRITIC.md`, `iteration0-*`, `review1-*`, and `review2a-*`. Worst gaps were the weak timber destination and dark route. Corrections exposed the left facade, strengthened/lowered its lights and sign, replaced the old low bar, widened/braced the timber and enlarged an in-frame orchard crown. No final critic or owner approval is claimed. The remaining S1 right seam and S3 slabs/crystals still dominate parts of the mouth view, and the route beyond the threshold stays dark. Do not expand to another section or relabel this visually accepted.

Checked: 72 mounted scripts compile at O0/O1/O2; 69 unrelated sources preserved, including all nine suite implementations and coordinator. `after-physical-contact.json`: 121 native cosmetics and five kit placements, zero physical penetrations, zero unsupported assemblies, zero kit support/penetration errors, zero one-stud lane-buffer failures at .035-stud tolerance. The complete player envelope has seven studs of headroom; wall-mounted posts start at Y9.5. `after-mesh-contact.json` checks actual original FBX base positions. Botanical joins and assembly joints are intentional contacts; this audit does not declare older retained decoration clip-free.

`contracts.log` executes nonzero origin translation, late kit origin/support, cosmetic query flags and an intentional failing section that warns while retaining the island. `behavior.log` passes existing policy/core save/load/replay, coordinator/reset/failure/timeout and production-reset checks. `legacy-check.log` passes the existing 50-seed walking-floor/cliff/cover contract. `FINAL-EVIDENCE.json` records final hashes. No gameplay tests were weakened. All nine **live StudioPassAll results remain UNKNOWN**: no Studio integration was available. Use `STUDIO-CHECKS.md` with the owner account and mock persistence.

Offline limitations: native Roblox parts and new original kit FBX reconstructed in Blender; older kit substitutions remain native scene proxies. PointLight brightness/falloff and transparent Beam shafts are labelled approximations. Local Comic Sans Bold approximates runtime FredokaOne; runtime board uses the actual shared style and stroke. Existing summit beam remains a proxy. Runtime mesh imports, actual lights/text, contact, device performance and player judgment need Studio. The overview camera was repaired to the southeast exterior for both columns; player cameras stayed locked throughout the review.

Lessons: when the facade stays hidden, ray-probe the blockers before adding props; when posts cannot fit a protected lane, test wall brackets and headroom; when compilation passes, still inject an origin shift and dressing failure. Added to `../LESSONS.md`; checklist now correctly names nine live suites.
