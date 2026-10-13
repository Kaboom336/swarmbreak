# Treasure references v2 — 2026-10-12

Built-in image_gen concepts in gameplay screenshot framing; **not Studio captures or owner-approved new art**. Originals preserved. No game code edits, commit, upload or publication. Five requested deliverables; containers/title cards remain in the original folder unchanged. [Contact sheet](_sheet.jpg) · [Exact prompts](PROMPTS.md).

Checked: REVIEW.md, REFS.md, GDD.md, slice-v2/ISLAND-V2.md; all seven original PNGs and original sheet; approved Pup A LEFT, Crow final-34 and pets-fx-v2. Owner requests are owner-reported. Heights below are proposed, not measured gameplay. Actual mesh identity, collision, chase, pacing and owner acceptance remain UNKNOWN.

## Short self-critique against REVIEW / REFS

| Image / tries | Improved | Remaining / build instruction |
|---|---|---|
| home-island.png / 2 | Eight pens, clearer 2x4 pads and inward side gaps; Shop moved south; broad ramp to cyan arch; correct Pup +1 and Crow +4 labels; five destination islands in visibly different altitude bands. | Enter Meadow/next-price text disappeared on final pass; add real UI/signs from GDD. Far pen entrances/pads remain partly compressed; build eight full accessible slots each from coordinates. Shop/title sign cropped. Generated pets retain proportion drift. |
| meadow-island.png / 1 | Four empty-handed rivals on distinct routes; one acorn stays at camp; Keeper mid-throw above red target, with visible camp ramps; west small mountain/east hill, stepping stones/recovery floor, hollow log and cross-links. Giant RUN poster removed. | Perspective exaggerates terrace/height, hides second log exit and some ramp joins. Safe apron not drawn clearly; use numeric contract below. Still image cannot prove chasing or threat. Only one rock is airborne; HUD acorn icon is not another world item. |
| pvp-handoff.png / 2 | Compact banner, one settling ground acorn, empty hands, restrained stumble/dust; portal lowered to flush cyan entry, Keeper pursuing outside safety; no pets/pumpkin props in shared arena. | Exact camera continuity/three return approach widths remain schematic. NPC looks smaller at distance. Bump timing, same-ID and secure behavior require runtime evidence. Pup/Crow intentionally absent here per GDD no-followers rule. |
| open-reveal.png / 2 | Pup on original pad; two tipped hollow rind halves plus one cap, no extra bowls; correct Common/Pup/+1 Coins/s and skip; fleeting reveal burst, Rare-only Crow effects. | Pup A forehead/chest/ears and Crow silhouette are closer, **not exact mesh matches**. Pup body is too frontal/short; Crow eyes remain too small and outline too bright. Use approved actual meshes, never remodel from these pixels; Common burst is transient only. |
| meadow-topdown.png / 2 | Flat plan; labelled heights, three routes/two links, camp/treasure, southwest jumps and portal, southeast hide spots matching screenshot landmarks; explicit studs and legend. | Generated footprints/grid/coordinates are not reliably to scale. Bottom approach arrows misleadingly point from outside island; connect routes inside base before apron. Recovery ramps/landings not fully diagrammed. Numeric table below governs greybox. |

No third attempts. No fun, arena or exact-identity pass claimed.

## Greybox contract for matching Meadow

GDD's newer 160x160 base takes precedence over ISLAND-V2's older 144 envelope. Local Y0 ground, +Z north. X/Z below are **centres**; footprints XxZ. This v2 composition proposes shifting arch west to match screenshot; keep entry/safety hub centred south. This is a documented art/layout proposal, not a silent GDD change.

| Feature | X,Z studs | Footprint | Surface height / requirements |
|---|---|---|---|
| Continuous base | 0,0 | 160x160 | Y0; bounds +/-80; no disconnected sky chunks |
| Guardian camp | 0,32 | 40x40 | +8 terrace; two broad ramps and shoulder stairs, one nest/acorn, one 11-high Keeper |
| West small mountain | -40,12 | 40x40 main hill plus rear shelves | +18 summit; rear terraces +6/+10/+14/+18; two opposite 12-wide ramps and ground bypass |
| East grove hill | 40,12 | 40x40 main hill plus rear shelves | +14 summit; rear terraces +2/+6/+10/+14; two opposite 12-wide ramps |
| Jump section | -32,-28 | 32x24 | Three 8x8 stones tops +1/+2/+3; edge gaps 4/6; floor -3; 12x12 landings, two recovery ramps, 12-wide walking bypass |
| Hard cover | -10,-10 and 10,8 | 8x12 each | +6–8; route must go around collider |
| Two-ended log | 40,-24 | 16x8 | exterior +9; interior at least 7 high x6 wide; both openings reachable |
| Bush hide | 56,-36 | 12x12 | two exits; concealment state distinct from hard cover |
| Safe entry pad | 0,-58 | 32x24 | Y0, independent 8-stud protected apron outside pad |
| Return arch | -24,-58 | arch on flush west pad extension | continuous Y0 path; apron includes arch/extension; no required jump/stairs |

Three camp-return walking routes: centre width16–20, ridge/grove >=12. Two cross-links near Z=-18/+18 join all three; route around cover, never through rock. Three separate approaches join safety **inside** base. All ramps <=35 degrees, walking bypass on every jump, guardian routes reach both summits. Height pass 2 measured authored route lengths: Quick 95.29, Ridge 112.25, Grove 128.76 studs; these remain within GDD quick90–105 / side110–130 targets. Offline geometry checks pass; live traversal and navmesh remain UNKNOWN. Reject overlaps or length misses rather than tracing generated terrain.

### Owner height clarification - 2026-10-13, Meadow height pass 2

Owner requested clearer height after meadow-height1.jpg still read as a flat slab. The +18 Mountain, +14 Grove and +8 camp supersede the old +10/+8/+4 labels in the generated top-down image and earlier notes. Four rear shelf levels have four-stud rises; ramps are at least 12 wide and at most 35 degrees (camp ramps retain width 16). The north hill ramps join the raised +8 camp; south ramps start at Y0. Keep the stone/recovery section and safe portal floor unchanged. Border rock/grass lobes, twenty additional off-route tree/bush clusters and deeper hanging rock teeth are native-Part greybox scenery. Generated reference perspective remains a composition guide; fresh Studio appearance and both runtime test results are UNKNOWN until rerun.

## Named reference comparison

Supplied offline best-in-class anchors, not fresh rankings: BGSI hub clarity versus v2's visible central arch/locked destinations (UI label gap remains); Steal an Egg objective versus v2's single guarded nest and single ground handoff; Steal and Hide versus two-ended log (far exit obscured); Catastrophic Horse Racing anticipation versus visible rock/red-disc pair; PS99 + Package-A-Pet reward finish versus same-pad three-piece opening (actual model fidelity still needed). No gameplay superiority claim.

## Lessons

- When generation fixes framing, recheck UI text because correct labels can disappear.
- When pictures guide a greybox, supply numeric coordinates because generated grids are approximate.
- When models are approved, instance the meshes because reference-conditioned art still changes proportions.
- Zion 2026-10-13 01:57: keep the current background floating islands (he likes them).
