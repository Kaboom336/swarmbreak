# Steal a Pumpkin — concepts v7

2026-10-12. Eight built-in image_gen concepts for the evergreen direction and Guardian Island Runs. [Contact sheet](_sheet.jpg) · [v6 side-by-side](_v6-comparison.jpg) · [Full final prompts](PROMPTS.md) · [Independent critique](CRITIC.md).

## Evidence and limits

**Checked:** SLICE-V2.md; ISLAND-PIECES.md; slice-v2/prototype/T1-greybox.md, GreyboxConfig.luau and Layout.luau; REDRAW-RULES.md; v5/BUILDABILITY.md; all 15 v6 PNGs; supplied v6 comparison frames; Pup A LEFT, Crow final-34, A fixed/D fixed pumpkins and pets-fx-v2. All four approved model reference images were passed on every successful generation. Existing authored assets/layout reused; no new third-party pack/code/licence adopted.

**Owner-reported approved:** model identities and v6 finish. **Proposed:** Meadow Keeper guardian and new world visual shells. **UNKNOWN:** Studio rendering parity, exact mesh identity, performance, gameplay feel and owner approval. Prototype handoff reports full-loop runtime NOT RUN; this art does not establish it. Exact Keystone Roblox Process Playbook unavailable in the supplied project search; supplied real-art/core-moment/reference rules applied.

All eight tool exports are 1672×941 (approximately 16:9, not mathematically exact). Six gameplay concepts use third-person framing; guardian and pieces are requested technical exceptions. These are AI concepts, not captured gameplay or measured geometry. Automatic image_gen originals live at the tool-owned default; all task-authored copies/documents are in v7. No game code changes or commit.

Native construction contract: Grass, Cobblestone, WoodPlanks, Brick, Slate, SmoothPlastic, small Neon; chunky colour-separated meshes; Future-style lighting; no painted world maps/lighting, dense leaf parts, cinematic DOF or ray-traced effects. Use low decorative shells over the unchanged greybox collision floor. Preview inside portal is proposed image/ViewportFrame art, not evidence of a native render-through portal.

## home-island.png

- Build home at **240×192**; eight **38×28** pens centred X=±88 and Z=-54/-18/18/54, fronts inward, eight slots each. Preserve the four-per-side count shown.
- Portal is **(0,0)**, shop **(0,-72)**, first spawn **(0,-12)**. The picture shifts shop front-left and compresses spacing; use coordinates, not image measurements.
- Clear paths ≥12 studs. Slate portal arch, bounded cyan Neon/PointLight, flush threshold/ramp; low WoodPlanks fences, two broad green canopy trees.
- Reuse the actual approved Pup A/Crow meshes unchanged. Common Pup +1 Candy/s and Rare Crow +8 are illustrative slice tags. Rare outline blue, sparse rising sparkles; Common has no aura. Generated pet geometry is not an exact identity pass.

## home-island-halloween.png

- Same camera, eight pens, portal, pets and route as base; colour/ornament overlay only.
- Swap canopy colour and shop awning, attach thick bat plaques and decorative jack-o-lantern lamps to visual sockets. Keep cyan daytime, green floor and clear telegraph contrast.
- Disable seasonal prop collision/query where appropriate. Ground leaf details should be a few merged chunky clusters; do not reproduce a part per leaf.
- Keep base pet meshes/rates intact, as shown. HUD restore retained Shop+Index and Candy0; use the same shared GUI dimensions/colour tokens as base when built.

## portal-enter.png

- Player enters the same central circular arch; short **RUN 1 / Pumpkin Meadow** banner, no new menu or queue.
- Preview depicts the enabled P01/P02/P06/P07 route and one nest reward; use an authored image or ViewportFrame, not a promised see-through-world system.
- Local same-place transfer; preview never grants cargo. First run is fixed easy; later route variation comes from existing recipe logic.
- Bound cyan particles/light to arch. Replace illustrated stair lips with flush floor/ramp over unchanged collision so entry needs no jump.

## island-run-dodge.png

- P02 has two staggered Slate cover blocks and ≥12-stud bypass; choice is movement around cover, no dash, jump or combat.
- Show contiguous P02→P06→P07; bridge deck ≥16 wide, rail1.5 high, matched floor height; island bases4 thick.
- Guardian warning ≥1.2s: amber exclamation and readable floor sector, actual guardian turn before approach. One guardian, one treasure.
- Keep grass margins nonwalkable/railed so the picture's open edges cannot become shortcuts. Put glowing faceless A fixed on the P07 integrated nest, not an extra P08 tile.

## island-steal.png

- One contextual hold ring on the nest; pictured65% is an illustrative mid-hold state. Hold lasts1s; Carry0/1 until theft completes.
- P07 is **48×48**, pumpkin anchor **(0,16)**, guardian origin **(12,8)**, cover X=±12; nest is inside this terminal piece, no Out.
- Guardian turns/warns; attach red/amber exclamation to rig, without health bars, weapons or damage numbers.
- Reverse route visible behind: bridge→cover tile→same circular P01 return portal. Reward is one carried pumpkin, **no Candy at theft**. Use approved A fixed/D fixed mesh; do not author from the generated ribs.

## island-escape.png

- Reverse same P07→P06→P02→P01 route; one circular return portal and one safe pad. No P09 exit or second terminal.
- Carry one approved faceless orange pumpkin on real grip attachments; pictured Carry1/1, Candy0. Keep arms/cargo clear of cover and camera.
- Catch means **1s slow +3s mercy**, pumpkin retained: short amber feedback and bounded pale-blue outline/particles, no loss or health deduction.
- Guardian chases through waypoints, stops outside P01 safe volume. Sheet specifies11-stud rig; image perspective cannot verify chase speed, distance or catch radius3.5.

## guardian-sheet.png

- **Proposed Meadow Keeper**, not an approved existing model: 11 studs tall against5.5-stud player. Match front/side/back silhouette.
- Broad straw ranger hat, green band/apron, cream square face, timber brown body, gold-tan hands, dark stump boots; native materials, no carved pumpkin face/Halloween-only base costume.
- Separate articulated parts for rig/animation; apron rigid panels, cuff wedges, no cloth simulation or tiny straw fibres. Sheet is a modelling reference, not a working rig.
- Patrol arms low; warn torso/head turn and raised arm; chase forward lean/arm pump. Amber warn/red chase BillboardGui; one rig identity for all action frames.

## pieces-sheet.png

- Includes P01–P09 plus P02/P06 short variants; connector labels are the written contract. **Pixel tile aspect ratios and nest offsets are imperfect**, especially P07; do not trace or measure this generated diagram.
- Enabled prototype: P01/P02/P06/P07 and shorts. P03/P04/P05 proposed; P08/P09 **FUTURE ONLY**. P07/P08/P09 have no Out; P08 never appends to launch P07.
- Examples: P01→P02→P06→P07=108 studs; P01→P02→P07=84; P01→P02Short→P06Short→P02Short→P07=108. Layout.luau may shuffle the short travel order; fixed terminals remain.
- Align In/Out with opposite normals; floors level/no gaps, clear width≥12, envelope≤96×144. Route84–112; no self-intersection/shortcuts; return uses identical assembled pieces. Technical dimensions/coordinates in ISLAND-PIECES.md override diagram proportions.

## Comparisons and iteration

Best-in-class anchors from supplied plan: **BGSI** home/portal legibility, **Steal an Egg** guarded pickup/return, **Pet Simulator 99** pet/rarity finish. Comparison is against supplied offline references, not current live-game research. v6 carries darker Halloween environments and superseded scythe/money popups; only its mesh/GUI finish was retained.

Side-by-side v6 checks: v7 home has a clearer centre portal/eight-pen count but loses v6 village richness; portal preview makes the next action explicit; dodge opens sightlines around cover; steal keeps contextual action and warning while removing scythe; escape shows retained cargo rather than old direct Candy payout. Approved-model comparison: silhouettes remain recognizable, but Pup layered forehead/chest/body and Crow eye/wing/head proportions drift. Exact A-fixed/D-fixed pumpkin identity remains uncertain. Builders must instance approved models rather than remodel these pictures.

Independent critic checked all final images against refs/layout; see CRITIC.md. No arena pass or owner acceptance asserted. Working: day readability, holiday composition match, one target, hold/slow feedback, consistent guardian. Change/simplify: centre-axis shop, true home spacing, exact approved meshes, tile proportions, margins and shared UI scale.

Selected attempts: home3 (two regenerations: six→eight pens, central portal); Halloween2 (HUD restore); portal1; dodge1; steal2 (circular portal and missing cover tile); escape2 (missing cover tile); guardian1; pieces2 (vertical connected routes/terminal labels). No image exceeded two regenerations. Final prompt set saved in PROMPTS.md.

## Lessons

- When exact layout matters, count modules and preserve coordinates because imagegen compresses spacing and moves landmarks.
- When meshes are approved, reuse their actual files because reference images constrain identity without guaranteeing identical geometry.
- When the core loop changes, remove old reward/tool cues because polished inherited UI can still teach the wrong game.

