# The v2 recipe: how a Swarm Break model must be built (read before touching any model)

The bar is the reference sheet: `assets/renders/refs-sheet.png` (open-licence Kenney / KayKit / Fox / robot models rendered
with OUR lighting) and the front-page Roblox games named in RESEARCH.md and COMPARISON.md. A model is done when two judges
score it 8+ against that bar. Look at your render every time. Never report a model you have not looked at.

## What the good ones have (measured in assets/renders/refs/refs.json)
- 100 to 1500 triangles per prop or character (ours: aim 2k-6k per enemy TOTAL, under 1.5k per part, well under 10k).
- Big simple shapes, flat shading, one material, big areas of saturated colour, no small floating detail.
- Exaggerated proportions: head + jaw 30-40 % of the body, big hands / claws, thick short legs, hunched or leaning pose.
- Each enemy has ONE glyph you can name at 40 studs (huge jaw, one giant arm, a dome, a lantern tail, a single eye).
- Bosses are their own shape, never a scaled regular.
- Dark body + one saturated accent that covers a real area (bands, plates, veins), bone-white sharp bits, one glow.

## The helpers (sb2.py on top of sb.py)
| Need | Use |
|---|---|
| organic body | `sb.blob(name, [(x,y,z,r),...], resolution=0.14)` then `sb2.facet(ob, 900)` (decimate + flat) |
| fuse overlapping pieces into one shell | `sb2.merge([objs], name, voxel=0.12)` then `facet` |
| armour that hugs the body | `sb2.cap_from(body, lambda c, n: <keep faces>, "Pads", thickness=0.25)` |
| limbs with joints | `sb2.seg_limb(name, points, radii, location, sides=7, joint=1.3, fuse=0.13)` then `facet(ob, 600)`; `ob["tip"]`, `ob["root"]` |
| horns, claws, teeth, spikes | `sb2.horn(name, base, direction, length, radius, sides=4..5, curve=0.3)`; `claw_fan`, `crest` in enemies2.py |
| eyes | `sb2.eye(name, center, direction, radius, iris_color, glow=3.0)` -> [white, iris_Glow, pupil]; place with `sb.on_ellipsoid` |
| jaws, snouts | `sb2.wedge(name, size, location, taper=0.55)` |
| put things ON a body | `p, n = sb.on_ellipsoid(center, radii, direction)` |
| paint | `paint_body(ob, acc, shell, stripe=(axis, period, duty, phase))`, `paint_plate(ob, STEEL)`, `paint_bone(ob)`; custom: `sb2.paint_rules(ob, base, [top_light(), belly(), band(), stripes(), spots(), near(), region()])` |
| glow parts | `sb2.flat_color(ob, color, emission=1.5)`; name must end `_Glow` (Neon in Studio) |
| shading in the crevices | `sb2.bake_ao(objs)` (build loop does it) |
| poses for the render | module `POSE = {part: (pivot, (rx, ry, rz) degrees)}`; applied after export only |
| render | build loop calls `sb2.render_model2` (dark world, rims, bloom); `VIEW = (angle, elev)` |

## Rules that do not bend
- One file per enemy: `enemy_<Name>.py` with `build() -> {part_name: object}`, `POSE`, `VIEW`. Shared helpers only in enemies2.py / sb2.py (do not edit those while another artist may be working; add helpers to your own file).
- Part names match the rig: Torso, Head, Jaw, Arm_L, Arm_R, Leg_L/Leg_R or Leg_1..n, Wing_1..n, Eyes_Glow, other `*_Glow`. Keep every rig part the v1 model had (see assets/models/manifest.json), you may add more.
- Front = +Y, up = +Z, feet on z = 0, 1 unit = 1 stud. Sizes: Walker 5.5, Runner 3, Flyer 3 (flies at z 4-6), Tank 5, Spitter 4.5, Brute 11, Queen 14, Warden 15 wide.
- Colours: dark chitin base (BODY), lit shell (SHELL mixed with the accent), FLESH under, BONE for sharp bits, STEEL plates; accent per enemy from `ACCENT`. Glow emission 1.2-3.0 only on small parts; big glow masses at 0.8-1.1 (they blow out to white otherwise).
- No blood, no gore. Enemies burst into light and sparks in game.
- Build and look: `cd /mnt/project-files/roblox/game/tools/blender && python3 enemies2.py <Name>` (about 2 minutes: build, AO bake, export, render). `SB_NO_RENDER=1 SB_NO_AO=1` for a 10-second syntax/shape check. Renders land in `assets/renders/enemies/<Name>.png`. Read that PNG.
- Fix a failing build before anything else. A part over 3000 tris prints a WARNING; bring it down (smaller facet budget, fewer subdivisions).

## Weapons and arena
Same helpers. Weapons: two-tone bodies (dark base + bright panel colour) before any glow, pushed proportions (muzzle as big as
the receiver, huge magazines, three-step barrels), rarity by material (gold body for Legendary, not gold trim), layered
glow (bright core, dimmer halo). Arena: dark tiles, glow seams and Nest light actually visible, props at R15 scale (a
crate is 4 studs), CC0 KayKit Space Base Bits pieces may be kitbashed with `sb2.import_kit` (bakes their palette to vertex colours).

## Round 2 additions (2026-10-01, sources in COMPARISON.md "Research round 2" e)
- Silhouette test: render each enemy as a 64x64 black shape on the arena floor colour; if a judge cannot name it, redo the glyph.
- Rarity ladder is one set of hues everywhere: Common grey, Rare blue, Epic purple, Legendary gold (body, frames, crates, drops).
- Player-side colours stay cool (cyan/white); enemy projectiles and telegraphs stay warm (red/magenta) and never reuse a player hue.
- No two enemies that share a wave share an accent hue.
- Floor and tiles must be clearly lighter in value than enemy bodies, or the enemy gets a rim light; inverted-hull outline only after a one-enemy test.
- Weapon glow per element (4 hues) as bright core plus dim halo; hotbar icons rendered 3/4 view on a flat rarity-colour disc, same angle for all.
- Icon and thumbnails: one focal point, hero + swarm + boss, 0-3 words, judged at 128 px before upload.
