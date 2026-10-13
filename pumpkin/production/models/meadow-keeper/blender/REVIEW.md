# Meadow Keeper — owner review

Kept round 3 after three rendered design rounds. Local golden-acorn artlib.py read and reused; authored geometry, no external asset packs or new third-party license obligations. Exporter extended for multi-material anatomical meshes.

| Round | Critique / change against approved Crow and Meadow concept |
|---|---|
| 1 | Unified bevelled farmer silhouette; face too narrow, eyes too small, hat crown too rectangular. |
| 2 | Wider face and hat; larger eyes; simple straw edge. Brows read worried and crown remains slab-like. |
| 3 — kept | Larger eye whites, inward-lowered brows, tapered crown. Smile keeps friendly guardian character. |

Compared with approved Crow: readable white/pupil/glint eyes, chamfered brick volumes and clean flat colour blocks. Keeper is intentionally taller and less head-heavy than Crow; face still reads friendlier than stern. Compared with meadow-island.png: wide straw hat with green band, green bib/straps, brown shirt, broad boots. No granular straw texture or tiny decorative stacks. The brim, crown and broad bib are the defining silhouette/details.

Independent read-only critic inspected approved Crow, Pup A LEFT, Meadow, containers/open-reveal and both models. Verdict: owner-review-ready candidates, not owner-approved. Acorn caveat: cap simpler and more faceted than reference. Keeper caveats: friendly face, taller proportions, initial square wind-up stance. Final throwing render was revised after that critique: upper-body twist and forward lean, staggered feet, review-only angular stone. That final pose revision was visually self-checked; independent re-review is not claimed.

Checked via verify.py: 1,532 triangles (limit 4,000), exactly 11 studs, ten unique RGB colour parts, seven FBX mesh objects. Valid triangle indices/areas, closed outward component surfaces, positive signed volumes. FBX re-import reproduces triangles and vertex positions within 0.000002 studs. JSON uses Y-up studs, front +Z, CCW preserved by x,z,-y rotation. RGB is integer 0–255. Roblox Studio import and runtime animation UNTESTED.

Rig-ready grouping: Head, Torso, Arm.L, Arm.R, Leg.L, Leg.R, Hat. Each is separate with origin at its intended joint. L/R refers to Blender X side. Multi-material components joined per anatomical part; JSON intentionally groups disconnected geometry by colour. No armature or skinning authored. Rest-pose blend/FBX/JSON stay neutral; throwing pose saved separately as meadow-keeper-throw.blend. The stone is review scenery and excluded from FBX/JSON and triangle budget.

Deliverables: meadow-keeper.blend, meadow-keeper.fbx, meadow-keeper_parts.json, final-front.png, final-34.png, final-throw.png, iterations.jpg, validation.json. Scripts and round evidence remain here. No game code edits, commits, publishing, or outside-model-folder writes.

Keystone Roblox Process Playbook was not available through callable tools or searched local coordination files; followed user-supplied art/reference requirements. Owner approval remains UNKNOWN.

Lessons:
- When a farmer hat reads as a slab, taper the crown because silhouette matters more than surface detail.
- When a throw reads as a wave, twist the torso and stagger the feet because a raised arm alone does not convey action.
- When rig parts contain several colours, export triangles by their material index because first-material grouping loses colour data.
