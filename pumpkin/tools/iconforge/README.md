# Iconforge

Offline Python 3 + Pillow renderer. Run from any directory:

    python pumpkin/tools/iconforge/iconforge.py

The default input is `icons.json` beside the script; `--data PATH` selects another
compatible data file. Outputs always go to this folder's `out/` directory.
No network, installs, image generator, Roblox edits, or external art/code.

## Data and rendering

The 12 grids and all 22 palette entries match `SECTION-LOOK.md` section 2.5
verbatim. Original renderer code reuses this repository's authored specification;
no third-party code or art was adopted. No separate license file was found in
pumpkin during the source check.

Every occupied cell is extruded 3 units. The front/base, lighter top, and
purple-shaded right faces use a shared orthographic camera (18 degree yaw,
16 degree elevation, -10 degree tilt). Highlights remain on the front; side
pigments use their base palette key. Hidden top/right faces are culled and visible
faces are painted in camera depth order without voxel edge strokes.

Each image is rasterized at 2048 square and downsampled with Lanczos to 512 square.
The rounded #1B1028 silhouette outline is 5.5% of the projected subject span;
the outline fit leaves 8% padding per side of the longest axis. A soft offset
shadow stays inside the transparent canvas. One top-face white gloss strip and
specular dot are clipped to visible top surfaces. Flat face colours contain no
texture, noise, or colour gradients. User-requested colour/size/shadow override
the older document's black-outline/256px/no-ground-shadow defaults.

## Visual review

Opened and inspected `_sheet.png` after two rendering passes. It contains all
12 icons on #85858B mid-grey and #24202F dark backgrounds, plus native 64px
previews and filled silhouette checks. Compared against the documented
Steal an Egg / Pet Simulator 99 traits in SECTION-UI 3.8 and UI-DIFF: chunky
volume, bold continuous contour, bright colours, top-left shine and soft shadow.
The underlying reference screenshots were not present at the documented paths;
this comparison uses the written style evidence, not a direct screenshot match.
These retain visible voxel steps rather than the reference games' smooth art.

Second pass tightened the outline from 6% to 5.5%, reduced yaw and grouped the
gloss over contiguous top surfaces. Crown and sprint are recognizable at 64px.
Remaining visual limitations (reviewer judgment):

- **Scythe:** still resembles a 7; the source blade is angular and the diagonal
  handle produces a stepped edge. Weakest icon in colour and silhouette.
- **Carry:** pumpkin is recognizable in colour, but the supplied long green
  centre stripe looks like a slash, rather than short stem plus orange ribs.
- Index/quests and pets/carry need their colour/details to distinguish their
  related blocky silhouettes. The shop handle opening narrows under the outline.

Verification: all grids/palette match the source; all 12 icons are 512x512 RGBA,
contain opaque art and transparency, and have fully transparent outer edges.
The contact sheet is valid. All writes are under `pumpkin/tools/iconforge/`.
No commit was created.

Lessons: when the input grid carries odd details, preserve it and flag the
limitation instead of silently redesigning it. When a voxel gloss fragments,
merge its visible top run so the shine reads at HUD size. Check the actual 64px
preview because large renders conceal silhouette ambiguity.
