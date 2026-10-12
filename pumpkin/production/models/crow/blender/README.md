# Crow — Steal a Pumpkin

**Iteration 3 with approved eye fixes.** Final: **2,362 triangles**, **3.2 studs** tall, head **54.8%** of height. Owner approval of the original design/fix round is owner-reported in the task. The new renders were locally inspected; a fresh Studio import remains untested.

Fix round: broad filled white eye discs; pupils exactly 55% of eye width, slightly low/inward, each with two white dots. `Pupil` is a separate **#111018** colour part. All 17 non-eye meshes are byte-identical in their vertex/face fingerprints to the pre-fix source, including the beak, hat, wings and feet.

**Duplicate-beak investigation:** both original and regenerated Blender/JSON contain exactly one beak. Every BillFeet/Pumpkin island was checked: BillFeet is two feet plus one beak; Pumpkin is the cap plus two studs. Each is closed, outward-facing, positive-volume, with no unused vertices or stray face islands. The extra orange piece in the supplied Studio capture is absent from these assets. Existing overlapping Studio geometry is an inference; its actual cause/removal is **UNKNOWN** without Studio inspection. No valid beak/hat geometry was deleted. Evidence: `fix-baseline.json` and `fix-audit.json`.

Open `final-34.png` first. `iterations.jpg` contains all twelve renders. `reference-comparison.jpg` puts the final next to the approved Pup A and supplied Pet Simulator 99 frame.

## Deliverables

- `crow.blend`: editable named meshes, applied bevels, seven flat-colour materials, camera and studio lights. Pet collection is separate from the studio collection. Each pet object has its origin at the bottom centre. Native front is Blender **-Y**.
- `crow.fbx`: pet meshes only; no studio, floor, camera, lights, or scale box. 25 named meshes, 2,362 triangles. Roblox Studio import has **not** been tested.
- `crow_parts.json`: an array of seven parts, one per palette colour, including `Pupil`. Each has `name`, integer `color` in 0–255, `vertices` in studs, and zero-based `triangles`. Coordinates use **(Blender x, z, -y)**: Y is up, native -Y front becomes **+Z**. This right-handed conversion preserves outside counter-clockwise winding. It is mesh data for a loader, not a standalone Roblox place.
- `final-front.png`, `final-34.png`: 1024 × 1024 Eevee studio renders.
- `renders/iterN-front.png`, `iterN-34.png`, `iterN-side.png`, `iterN-scale.png`: each iteration, with a real 5.5-stud dark box for scale.
- `iter1.blend`, `iter2.blend`, `iter3.blend`: retained iterations.
- `critique.md`, `independent-critique.md`, `validation.json`: review and verification evidence.

## Iterations

| Iteration | Triangles | Changes |
|---|---:|---|
| 1 | 1,980 | Rounded brick head, tucked body, domed eyes, compact bill, purple feather bib, pumpkin cap. |
| 2 | 2,260 | Wider head, larger eyes, three stepped feathers in each continuous wing, one higher wave, restrained studs, stronger orange. |
| 3 — final | 2,362 | Flatter eyes, pupils slightly up/inward, shorter tapered bill with seam, smaller bib, softer sheen, welded clamped bevel vertices. |

## Rebuild

Run from this directory:

```powershell
& C:/dev/codex-lab/tools/blender/blender.exe -b -P build_crow.py -- --iteration 3 --export --fix-round
& C:/dev/codex-lab/tools/blender/blender.exe -b -P verify_crow.py
& C:/dev/codex-lab/tools/blender/blender.exe -b -P audit_fix.py
```

`--fix-round` refreshes only final assets/renders and leaves archived iteration files intact. Archived iteration 3 shows the pre-fix eyes. Rebuilding without this flag replaces the corresponding iteration archive with current script settings.

`contact_sheet.ps1` assembles existing renders with System.Drawing; it does not create character art or change Blender geometry. No external geometry, textures, downloaded models, or image-generation assets are used. Foundation: locally installed Blender primitives, bevel tools, and original procedural meshes. Existing project images are visual references only.

Local validation checks closed, consistently oriented meshes, exact palette values, applied modifiers, zero origins, no image textures, valid nonzero-area JSON triangles, and FBX re-import. Maximum FBX round-trip position difference: **0.000000522 studs**. All twelve iteration renders were checked as 1024 × 1024.

All authored deliverables stay in this directory. No game code edits, publishing, or commits.
