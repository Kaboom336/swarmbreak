# Meadow layout study evidence

Studio capture is pending: Computer Use rejected Roblox Studio window access in this session.
No file in this folder is claimed to be a Studio screenshot unless explicitly captured in Studio.

Place files: `production/prototype/meadow-A.rbxl`, `meadow-B.rbxl`, `meadow-C.rbxl`.
These contain saved geometry, not a runtime generator. Existing game scripts and the original place are untouched.

## Checked versus pending

Checked: Rojo seed build, Lune binary place round-trip, all authored ramp angles <=25 degrees,
nominal walking lanes >=12 studs, saved geometry for three separate islands, independent static critic.
Main route lengths / ESTIMATED at 15 studs/s: A 140.0 / 9.3s; B 107.3 / 7.2s; C 238.6 / 15.9s.
No character walked these routes. These estimates include the marked main route to the portal centre,
not Steal, combat, acceleration, cargo, safety-boundary secure, or an observed escape.

NOT RUN: Studio open/render, actual avatar/cargo/hat clearance, NPC traversal, jump misses,
guardian combat, original Loop/PvP/Trap tests, multiplayer, device or owner playtest.
These are geometry studies with a cosmetic Keeper/acorn/portal, not copies of the full gameplay loop.
The supplied handoff test recipe applies to the original combat prototype; do not report its old passes
as evidence for these geometry-only places.

The sampled collision audit retains A4/B5/C1 marginal intersections at optional recovery/ramp joins.
It found no centre-line intersections in its sampled main routes, but this is NOT a physics pass.
See `collision-audit.json` for actual coordinates and the limited sampling method.

## Camera / capture handoff

Open each `production/prototype/meadow-LETTER.rbxl` in Studio. Geometry is already saved in Workspace.
The default spawn is on the treasure camp; Play permits ordinary character walks.
No tests or game scripts need editing or enabling to inspect the layout study.

Use these Command Bar camera selections in edit mode (change `Top` to `ThreeQuarter` for the second view):

```lua
local c = workspace.ReviewCameras.Top
workspace.CurrentCamera.CFrame = c.CFrame
workspace.CurrentCamera.FieldOfView = c.FieldOfView
```

Capture the actual viewport as `A-top.png`, `A-34.png`, and equivalents for B/C in this folder.
Then create `_sheet.jpg` from those actual captures with each escape line below.
These seven requested image files do NOT exist yet; Studio access was rejected.

- A: Escape: descend camp, cut across the south court; ring and hill routes offer flanks.
- B: Escape: descend +18/+12/+6 shelves; spiral and east switchback offer reversals.
- C: Escape: dog-leg off camp to optional bridge; west causeway and east ridge bypass it.

Supplementary previews live in `../offline-preview/` and are explicitly labelled OFFLINE.
They are Blender renders of the saved Parts, without Roblox materials or Studio lighting.
Do not rename them as in-game screenshots.
