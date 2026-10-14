# Meadow Keeper reference rebuild — 2026-10-13

Delivered one candidate after five render/comparison rounds. Owner approval is pending; this is not a claim of reference parity. No commit, game code edits, or changes to the golden acorn.

## Reference bar and reused source

Primary shape target: `../../../concepts/v7/guardian-sheet.png`, straw-hat Keeper. Composition/action references: `../../../treasure/v2/meadow-island.png`, `../../../treasure/meadow-island.png`, and `../../../treasure/title-card.png`. Approved finish target: `../../crow/blender/final-34.png`.

Inspected the existing Keeper build, local `artlib.py`, and approved Crow build before rebuilding. Reused the project's original box/mesh, material, stage and export helpers. No third-party model, texture, or kit was imported; no new external asset licence is required. The Keystone service/playbook was unavailable in this session; read the local project `PLAYBOOK.md` and `game/tools/blender/RECIPE.md` instead.

## Delivered files

- `meadow-keeper.blend`: final neutral source with render stage.
- `meadow-keeper.fbx`: only seven rigid mesh parts; stage and throwing stone excluded.
- `meadow-keeper_parts.json`: 32 rig/material sections, world vertices in Y-up studs, each with `rig_part`, `material`, and rig `pivot`. It remains a list of coloured triangle meshes; material sections now preserve rig ownership rather than combining both arms/legs into one colour mesh.
- `final-front.png`, `final-34.png`, `final-throw.png`: inspected 1000 × 1000 renders.
- `meadow-keeper-throw.blend`: posed review scene; the gray stone is an intentional studio-only throwing prop.
- `compare.jpg`: final render next to reference crops, including all four supplied Keeper artworks and approved Crow.
- `iterations.jpg`: five comparison rounds; detailed sheets are `renders/redo1-compare.jpg` through `redo5-compare.jpg`.
- `validation.json`, `verify-log.txt`: measured export checks.

## Iteration evidence

| Round | Measured triangles | Changes and visual findings |
| --- | ---: | --- |
| 1 | 1,644 | Replaced white eyes/smile with dark rectangles and stern brow; cream head/cuffs, gold gloves, brown short legs, wide stepped hat and large patch pocket. Shoulders/eyes still narrow/small. |
| 2 | 2,788 | Broader torso/arms, shirt/sleeve seams, side utility pockets, patch-pocket border, wider brim and band joins. Independent critic: subjective 7/10; flat brim and head/chest balance still weak. |
| 3 | 3,052 | Larger rectangular eyes, level mouth, warmer cream/gold and greener canvas, thumb blocks, deeper hat brim and straw courses. Head still dominates chest. |
| 4 | 3,184 | Wider chest, straps and shoulders, wider boot stance, slightly shorter face, warmer hat, flared/notched brim. Two independent critics: subjective 8/10. Raised cuff/stone obscures brim clearance. |
| 5 | 3,184 | Stronger underside slope; throwing hand rotated outward, stone positioned at palm, torso leaned and feet spread/tilted. Independent recheck: subjective 8.2/10, visual pass; glove/cuff clears brim visually. |

All five comparison sheets were created and visually inspected before moving on. Review scores are judgments, not measured quality or owner approval. Remaining visible differences: the hat crown is more tiered and the pocket/body construction cleaner and flatter than the painted concept. The requested stern brow and level mouth deliberately add expression to the reference's minimal face.

## Technical verification — measured PASS

- 3,184 total triangles, below 5,000; exactly 11.0 studs in neutral pose.
- Parts: `Torso`, `Head`, `Hat`, `Arm.L`, `Arm.R`, `Leg.L`, `Leg.R`.
- Each mesh has closed edges, positive signed volume, and no unapplied modifiers. Parts contain joined overlapping closed components; this does not assert a single fused shell or an intersection-free interior.
- JSON triangle indices and areas valid. Vertex correspondence and triangle totals checked separately per rig part.
- FBX reimport yields the same seven named parts and triangle totals; rig pivots match. Maximum vertex deviation approximately 0.00000102 studs.
- Front is -Y in Blender, +Z in JSON; up is Z in Blender, Y in JSON. JSON basis `(x,z,-y)` preserves winding. One Blender unit represents one stud.
- Neutral FBX only: separate rigid parts with useful origins, no skinned armature or animation clip requested.
- Roblox Studio import/runtime: UNTESTED. Throw clearance checked visually, not with an exact triangle collision solver.

## Reproduce

Use `rebuild_keeper.py`, not the superseded `build_keeper.py`:

```powershell
& C:/dev/codex-lab/tools/blender/blender.exe -b -t 6 -P pumpkin/production/models/meadow-keeper/blender/rebuild_keeper.py -- 5
& C:/dev/codex-lab/tools/blender/blender.exe -b -t 6 -P pumpkin/production/models/meadow-keeper/blender/verify.py
```

Earlier `iter*.blend` and `iter*-log.txt` files belong to the rejected attempt. Current round archives start with `redo`.

## Lessons

- When increasing head size, compare it against shoulder width because a large head can weaken the heavy guardian silhouette.
- When matching a character reference, reuse its eye shape and colour blocks because importing another character's face changes identity.
- When posing a wide-hat character, inspect throwing clearance from the final camera because a good neutral pose can still create visible overlaps.
