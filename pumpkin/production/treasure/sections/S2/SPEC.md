# S2 — orchard supply lane / timber mine mouth

Round 4 owner override (this round only): eligible exterior hill/wall solids may
change size, position or shape to open the approach, bevel the mouth and slope
its shoulders. Test/policy-referenced solids, all lane floors/tags/attributes,
bait cover, PvP court, route/policy data and interior Keeper blockers remain
authoritative. Use the explicit R4 hill plan and independent preservation audit,
not R2's palette-only parity rule. Original collision cores are retained beneath
nonphysical sloped shells: the place's 89-degree Humanoid slope default makes
colliding wedges climbable. Current R4 delivery still misses sky and mouth
coverage goals; see RESULT.md, METRICS-R4.json and CRITIC-R4.md. This record grants
no new permission for another section or a later round.

Round 2 owner override: cosmetic parts visible from the two locked cameras may be removed/restyled across S1 seam and S3 interior; visible collidable rock/hill solids permit Color/Material only. All other solid fields, query flags, tags/attributes, floors, lanes, bait cover and PvP court remain authoritative. R2 uses explicit ray-visible solid identities, complete revealed cosmetic clumps, warm wall-bracket lamp pairs at roughly 12 studs, three five-rock uniform kits2 wall clusters outside strict horizontal lane buffers, and an in-frame high-mounted timber facade. The bright endpoint is a supported wall-light cue, not a new opening. Round 2 evidence and actual goals are in RESULT.md; the original scope/removal limits and final facade coordinates below are retained as the round-1 record, superseded only by this explicit owner override.

Story: a shady orchard lane dives into the hill through an old timber mine mouth; harvest workers left a supply station beside the shortcut.

Ownership: island-local X -120..-40, Y -3..28, Z -5..125, excluding S1's X -58..58/Z 98..156 envelope. S3 interior, S1 seams, all lanes, bait cover/floor and court stay authoritative. Existing hill heights exceed S2; no reshaping. The original opening is diagonal from (-76,98) to (-52,88). Dress its exterior faces only.

Best reference: Grow a Garden, for readable fruit-tree silhouettes, warm timber and grouped planting. Secondary: 99 Nights in the Forest, for a warm lit destination inside dark forest shapes. Local promo crops prove art hierarchy only, not gameplay or live cameras. Kenney and Quaternius kits2 are existing CC0 assets; read KitLibrary's bottom-centre fitting and sanitization before reuse.

Locked cameras (Roblox XYZ, 24mm / 73.7 degree horizontal FOV, 1280x720): WALK eye (-35,7,130), look (-68,5,92), player approximately (-47,0,116); MOUTH eye (-53,6,115), look (-69,6,86), player approximately (-62,0,99). Both trail the route about 18 studs horizontally. Final overview (-5,90,170) toward (-70,10,90), 28mm; repaired identically in both columns to show the southeast exterior. Identical lighting and cameras before/after; black initial walk image was a rejected camera inside hill, replaced before dressing.

Frame goals, measured using occlusion-aware S2 object-index masks: WALK S2 >=10% total image; MOUTH S2 >=18%; timber/lantern focal assembly spans >=25% image width at mouth. Keep the central route opening legible, with no new occluders across its walking corridor. These are acceptance goals, not claims of achieved results.

Palette: warm chestnut timber, desaturated iron, moss/leaf greens, apple reds, grey rock; amber lanterns. Cyan/gold remain portal/reward cues. Warm light shafts at the exterior are subtle effect proxies offline; runtime PointLights/Beams are documented separately.

Purposeful groups (3–7 main objects, varied sizes):
- Mine frame: two wall-mounted timber uprights, joined header and knee braces, two amber lanterns, one wooden shortcut board. Header above head height; the lower S1 mine trim within S2 is superseded.
- Orchard pocket: three trees, 5/5.5/2.5 studs wide and 17/18/10 studs tall, each with four attached red fruit, creates shade and a harvest story on the only broad supported shoulder near Z120–125.
- Supply pocket: 3.4-stud barrel, 2–3-stud crate, hand shovel; supplies support orchard maintenance. No cart rail across a lane; tools satisfy the story prop requirement.
- Mouth clusters: 3–5 varied rocks at supported wall feet and 3–5 attached vine/root strands on actual wall faces. Never place surface moss in empty space under the hill cap.

Removals: only existing nonphysical filler within S2 that competes with the mouth; never gameplay colliders, floor/query tags or bait cover. Remove the nine left `TunnelExitArchShoulderVoxel*` decorations at Z99, X<-58; retain the right S1 seam voxels and S3 interior. Replace explicitly named old S1 mine trim whose positions lie in S2. Exact owner-reported RECOVERY -> CYAN text was absent in inspected source/place; remove the current `OutsmartExit` floating cyan cue at its creation site. No new floating world labels.

Final facade refinement: uprights centred at (-75.2,14,99), (-52.7,14,88), 1.2x9x3.5 studs, backed by three contact-tested brackets each. They start at Y9.5 because the protected bait approach prevents grounded thick posts here. The timber header centre is Y17.5, 2 studs tall, .35 studs deep, with two diagonal knee braces. Three attached ivy/root strands per support and two 28-stud-range amber lights make the mouth readable. The nine cosmetic arch voxels were discovered by camera-ray probing, not assumed to be gameplay solids. S2's orchard uses native pruned trees with attached apples; the three varied rocks, barrel and crate use kits2. The wall-mounted facade is a deliberate fit to preserved gameplay, rather than the generated target's grounded arch.

Support: full footprint sampling <=1 stud, exact imported FBX base check, oriented physical penetration plus assembly contact graph; zero unintended contact failures. All cosmetics CanCollide/CanQuery/CanTouch=false. Enforce one stud lane-edge clearance throughout the seven-stud player envelope; the mounted facade starts at Y9.5. No ground prop exception. Per-prop pcall warns; top-level existing MeadowV4 section guard remains intact. Late kits use origin once.

Process: byte-verified pre-s2 backup before Rojo; before cameras; REFS + built-in generated TARGET; detailed candidate; two blind reviews and two corrections; final matched renders and SBS at normal/phone size. Preserve all nine suite sources and run available offline contracts. Live StudioPassAll requires actual Studio owner/mock persistence; otherwise UNKNOWN.
