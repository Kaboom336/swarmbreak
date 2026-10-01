"""Arena kit, pass 2 (recipe v2): Outpost 9, a fenced sci-fi platform sitting on the Nest.

Look: near-black steel with chamfered (faceted) panels, a lighter steel for raised parts, ONE hazard-stripe accent per
piece, rust and scorch patches as big flat decals, cyan station lights, and the purple Nest light coming up through
grates, spawn holes and cracks (every glow part sits above or inside an open cavity, never buried in a slab).
Every v1 piece name and footprint is kept (8x8 floor modules on the 4-stud grid, 8-wide walls, 4.4 pillars, 4-stud
crates, 12-wide gate, 17.5-wide boss gate, 8-long railing); heights are pushed to R15 scale (walls 10, pillars 12).

Kitbashed CC0 KayKit Space Base Bits pieces (sb2.import_kit, palette baked to vertex colours, then repainted):
  - lights.gltf : the four-headed lamp unit of the Lamp (imported at 4.2 = 1.5x the 2.8 kit scale so the heads read
                  at R15 distance; its own short post and base are cut away and it sits on our octagonal post).
Everything else is built here from sb/sb2 primitives.

Run:  python3 arena2.py                 (all 12 pieces, then the Lineup corner)
      python3 arena2.py Crate Wall      python3 arena2.py lineup
      SB_NO_RENDER=1 SB_NO_AO=1 python3 arena2.py   (10-second shape check)
"""
import math
import os
import random
import sys

import bpy
import bmesh
from mathutils import Vector, Matrix

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sb
import sb2
from sb import PAL, rgb
from sb2 import top_light, belly, band, stripes, spots, region, near, facing

KIT = "/tmp/claude-0/-home-claude/87377bc6-a5d0-5e15-9329-d04a40333c32/scratchpad/refs/KayKit-Space-Base-Bits/addons/kaykit_space_base_bits/Assets/gltf/"
KIT_SCALE = 2.8            # 1 KayKit unit -> 2.8 studs
WALKER_GLB = os.path.join(sb.ASSETS, "models", "enemies", "Walker.glb")

# ---------------------------------------------------------------- palette (two-tone dark steel + accents)
STEEL_DARK = rgb(24, 26, 34)       # near-black steel: slabs, wall bodies, shafts
STEEL = rgb(60, 65, 78)            # mid steel: ribs, panels, props
STEEL_LIGHT = rgb(132, 140, 156)   # lit top faces and chamfers
FLOOR_TOP = rgb(36, 39, 48)        # the walkable top of a floor panel (barely lighter than the body)
RUST = rgb(118, 56, 32)
RUST_DARK = rgb(78, 38, 24)
SCORCH = rgb(10, 10, 14)
HAZARD = rgb(236, 158, 40)         # hazard stripe amber
HAZARD_DARK = rgb(32, 28, 28)      # the dark stripe between the amber ones
CYAN = rgb(40, 220, 200)           # station lights
NEST = rgb(180, 80, 240)           # Nest purple
NEST_HOT = rgb(236, 196, 255)      # hot core of a Nest glow
NEST_SHELL = rgb(104, 50, 150)     # lit top of a root
CHITIN = rgb(20, 15, 32)
BONE = rgb(228, 218, 196)
RED = rgb(240, 60, 60)
WARM = rgb(255, 226, 170)


# ---------------------------------------------------------------- shape helpers
def cbox(name, size, at=(0, 0, 0), rot=(0, 0, 0), bevel=0.1):
    """A chamfered box (one bevel segment, flat shaded): the basic faceted block of the kit."""
    b = sb.box(name, size, at, rot, bevel=bevel, segments=1)
    if bevel > 0:
        sb.apply_modifiers(b)
    sb2.shade_flat(b)
    return b


def octo(name, r, depth, at, sides=8, bevel=0.0, rot=None):
    """An n-gon prism (flats facing the axes), optional chamfer on the rims only."""
    rot = (0, 0, math.pi / sides) if rot is None else rot
    ob = sb.cylinder(name, r, depth, at, rot, verts=sides, smooth=False)
    if bevel > 0:
        m = ob.modifiers.new("Bevel", "BEVEL")
        m.width = bevel
        m.segments = 1
        m.limit_method = "ANGLE"
        m.angle_limit = math.radians(60)
        sb.apply_modifiers(ob)
    return ob


def torus_lp(name, major, minor, at=(0, 0, 0), rot=(0, 0, 0), maj=16, mn=6):
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor, major_segments=maj, minor_segments=mn)
    ob = bpy.context.active_object
    ob.name = name
    ob.location = at
    ob.rotation_euler = rot
    sb2.shade_flat(ob)
    return ob


def cut(ob, cutter):
    """Boolean DIFFERENCE (exact), baked; the cutter is deleted."""
    m = ob.modifiers.new("Cut", "BOOLEAN")
    m.operation = "DIFFERENCE"
    m.object = cutter
    m.solver = "EXACT"
    sb.apply_modifiers(ob)
    bpy.data.objects.remove(cutter, do_unlink=True)
    return ob


def rz(p, a):
    c, s = math.cos(a), math.sin(a)
    return (p[0] * c - p[1] * s, p[0] * s + p[1] * c, p[2])


def slice_diag(ob, period=0.8, duty=0.5, axes=(0, 2), sign=1.0, phase=0.0):
    """Cut the mesh with parallel diagonal planes (x + z = const) so that a per-face rule paints crisp stripes."""
    me = ob.data
    bm = bmesh.new()
    bm.from_mesh(me)
    ea = Vector((0, 0, 0))
    ea[axes[0]] = 1.0
    eb = Vector((0, 0, 0))
    eb[axes[1]] = sign
    no = (ea + eb).normalized()
    vals = [v.co[axes[0]] + sign * v.co[axes[1]] for v in bm.verts]
    lo, hi = min(vals), max(vals)
    cuts = []
    k = math.floor((lo - phase) / period) - 1
    while phase + k * period < hi + period:
        for c in (phase + k * period, phase + (k + duty) * period):
            if lo + 1e-3 < c < hi - 1e-3:
                cuts.append(c)
        k += 1
    for c in cuts:
        geom = bm.verts[:] + bm.edges[:] + bm.faces[:]
        bmesh.ops.bisect_plane(bm, geom=geom, dist=1e-5, plane_co=no * (c / math.sqrt(2.0)), plane_no=no)
    bm.to_mesh(me)
    bm.free()
    return ob


# ---------------------------------------------------------------- paint helpers (rules from sb2 + a few of our own)
def diag(color, period=0.8, duty=0.5, axes=(0, 2), sign=1.0, phase=0.0, amount=1.0):
    """Diagonal stripes on a plane: faces where (x + z) mod period < duty take `color`."""
    def r(p, n, t):
        f = ((p[axes[0]] + sign * p[axes[1]] - phase) / period) % 1.0
        return color, amount * (1.0 if f < duty else 0.0)
    return r


def segs(color, n=8, center=(0, 0), amount=1.0):
    """Every other side of an n-gon prism around `center` takes `color` (a chunky hazard ring)."""
    def r(p, nrm, t):
        a = (math.atan2(p.y - center[1], p.x - center[0]) / (2 * math.pi) * n + n) % 2.0
        return color, amount * (1.0 if (a < 1.0 and abs(nrm.z) < 0.5) else 0.0)
    return r


def paint_steel(ob, base=STEEL_DARK, top=None, rules=(), roughness=0.58, metallic=0.1):
    """Dark steel: base on the sides, `top` on faces that point up (chamfers take the mix), darker underneath."""
    top = top if top is not None else sb2.mix(base, STEEL_LIGHT, 0.3)
    return sb2.paint_rules(ob, base, [top_light(top, 0.9, 1.0), belly(sb2.darken(base, 0.55), 0.7, 1.2)] + list(rules),
                           roughness=roughness, metallic=metallic)


def paint_glow(ob, color, emission=1.2, alpha=1.0):
    return sb2.flat_color(ob, color, roughness=0.4, emission=emission, alpha=alpha)


def paint_nest(ob, rules=()):
    """Nest tissue: dark chitin with the purple shell tone on the faces that point up."""
    return sb2.paint_rules(ob, CHITIN, [top_light(NEST_SHELL, 1.0, 0.8), belly(sb2.darken(CHITIN, 0.6), 0.5)] + list(rules), roughness=0.55)


def paint_hazard_ring(ob, n=8):
    return sb2.paint_rules(ob, HAZARD_DARK, [segs(HAZARD, n)], roughness=0.65, metallic=0.05)


def hazard_plate(name, w, h, period=0.9, duty=0.5, thick=0.05, phase=0.0):
    """A plate in the XZ plane at the origin with crisp diagonal hazard stripes. Move / rotate it AFTER (it is painted here)."""
    p = sb.box(name, (w, thick, h), (0, 0, 0), bevel=0)
    slice_diag(p, period, duty, (0, 2), 1.0, phase)
    sb2.paint_rules(p, HAZARD_DARK, [diag(HAZARD, period, duty, (0, 2), 1.0, phase)], roughness=0.65, metallic=0.05)
    return p


def decal(name, size, at, color, rot=(0, 0, 0), rough=0.85):
    """A big flat patch of rust / scorch lying on a surface (no small floating detail: keep these over a stud)."""
    d = sb.box(name, size, at, rot, bevel=0)
    sb2.shade_flat(d)
    sb2.flat_color(d, color, roughness=rough)
    return d


def nodes_on(name, limb, fractions, radius, color=NEST, emission=2.0):
    """Small glowing nodes along a seg_limb's joints polyline."""
    out = []
    pts = [Vector(p) for p in limb["joints"]]
    for i, f in enumerate(fractions):
        j = min(int(f * (len(pts) - 1)), len(pts) - 2)
        u = f * (len(pts) - 1) - j
        pos = pts[j].lerp(pts[j + 1], u)
        n = sb2.lowpoly_sphere("%s%d" % (name, i), radius, pos + Vector((0, 0, radius * 0.9)), subdiv=1)
        paint_glow(n, color, emission)
        out.append(n)
    return out


# ================================================================ floor
def build_FloorTile():
    """8x8 floor module: near-black slab, four chamfered panels around a recessed cross groove with a thin lit seam,
    one rust patch and one vent inset for wear. Walkable top at z = 0."""
    slab = cbox("Slab", (8, 8, 0.85), (0, 0, -0.575), bevel=0.05)
    paint_steel(slab, sb2.darken(STEEL_DARK, 0.75), sb2.darken(STEEL_DARK, 0.85))
    body = [slab]
    for x in (-1.975, 1.975):
        for y in (-1.975, 1.975):
            p = cbox("Panel", (3.75, 3.75, 0.3), (x, y, -0.15), bevel=0.13)
            paint_steel(p, STEEL_DARK, FLOOR_TOP)
            body.append(p)
    # wear: ONE big rust patch in a corner (no confetti: 25 of these tile the floor) and a vent inset with slats
    body.append(decal("Rust", (2.4, 1.6, 0.02), (2.2, -2.3, 0.0), RUST_DARK))
    body.append(decal("Vent", (1.8, 1.0, 0.03), (-2.2, 2.3, 0.0), sb2.darken(STEEL_DARK, 0.4), rough=0.7))
    for k in range(3):
        body.append(decal("Slat", (1.5, 0.12, 0.05), (-2.2, 2.3 + (k - 1) * 0.3, 0.0), STEEL, rough=0.6))
    g1 = sb.box("Groove_Glow", (0.08, 7.7, 0.06), (0, 0, -0.1), bevel=0)
    g2 = sb.box("Groove2", (7.7, 0.08, 0.06), (0, 0, -0.1), bevel=0)
    for g in (g1, g2):
        paint_glow(g, CYAN, 1.6)
    return {"Body": sb.join(body, "Body"), "Groove_Glow": sb.join([g1, g2], "Groove_Glow")}


def build_FloorGrate():
    """8x8 grate over the Nest: an open pit with the purple light in it (glow plate just under the bars, hot core),
    five heavy chamfered bars and two roots pushing up between them, a purple haze in the pit."""
    body = []
    bottom = sb.box("Bottom", (8, 8, 0.2), (0, 0, -0.9), bevel=0)
    paint_steel(bottom, sb2.darken(STEEL_DARK, 0.5))
    body.append(bottom)
    for sx in (-1, 1):
        for size, at in (((0.7, 8, 0.85), (sx * 3.65, 0, -0.425)), ((6.6, 0.7, 0.85), (0, sx * 3.65, -0.425))):
            w = cbox("Side", size, at, bevel=0.04)
            paint_steel(w, sb2.darken(STEEL_DARK, 0.75))
            body.append(w)
        for size, at in (((0.9, 8, 0.3), (sx * 3.55, 0, -0.15)), ((6.2, 0.9, 0.3), (0, sx * 3.55, -0.15))):
            f = cbox("Frame", size, at, bevel=0.1)
            paint_steel(f, STEEL_DARK, FLOOR_TOP)
            body.append(f)
    for i in range(5):
        b = cbox("Bar", (0.46, 6.4, 0.3), (-2.4 + i * 1.2, 0, -0.15), bevel=0.1)
        paint_steel(b, sb2.darken(STEEL, 0.8), sb2.mix(STEEL, STEEL_LIGHT, 0.12))
        body.append(b)
    for y in (-2.0, 2.0):
        c = sb.box("Cross", (6.2, 0.3, 0.16), (0, y, -0.38), bevel=0)
        paint_steel(c, STEEL_DARK)
        body.append(c)
    body.append(decal("Rust", (1.4, 0.9, 0.02), (2.6, -3.5, 0.0), RUST_DARK))
    under = sb.box("Under_Glow", (6.2, 6.2, 0.1), (0, 0, -0.62), bevel=0)
    paint_glow(under, NEST, 1.1)
    core = octo("Core", 2.1, 0.06, (0, 0, -0.55), sides=12)
    paint_glow(core, NEST_HOT, 2.2)
    glows = [under, core]
    for (x, y, a) in ((-1.8, -1.3, 0.6), (1.8, 1.5, 3.6)):
        pts = [rz(p, a) for p in ((0, 0, -0.8), (0.4, 0.3, 0.3), (1.1, 0.8, 1.25))]
        r = sb2.seg_limb("Root", pts, [0.42, 0.3, 0.08], location=(x, y, 0), sides=6, joint=1.2, fuse=0.1)
        sb2.facet(r, 300)
        paint_nest(r)
        body.append(r)
        t = Vector(r["tip"])
        n = sb2.lowpoly_sphere("Node", 0.22, (t.x, t.y, t.z - 0.05), subdiv=1)
        paint_glow(n, NEST, 2.2)
        glows.append(n)
    haze = sb.box("Haze_Glow", (6.2, 6.2, 0.4), (0, 0, -0.35), bevel=0)
    paint_glow(haze, NEST, 0.8, alpha=0.3)
    return {"Body": sb.join(body, "Body"), "Under_Glow": sb.join(glows, "Under_Glow"), "Haze_Glow": haze}


# ================================================================ walls
def build_Wall():
    """8 wide x 10 tall x 2 deep. Player side is +Y: hazard plinth, two raised chamfered panels, a pipe with clamps,
    a cyan light strip, rust and scorch. The back is plain."""
    body = []
    core = cbox("Core", (8, 1.6, 10), (0, -0.2, 5), bevel=0.1)
    paint_steel(core, STEEL_DARK)
    body.append(core)
    plinth = cbox("Plinth", (8, 2.0, 1.4), (0, 0, 0.7), bevel=0.1)
    paint_steel(plinth, STEEL_DARK, STEEL)
    body.append(plinth)
    hz = hazard_plate("Hazard", 7.2, 0.7, period=1.0)
    hz.location = (0, 1.02, 0.75)
    body.append(hz)
    cap = cbox("Cap", (8, 2.0, 0.6), (0, 0, 9.7), bevel=0.12)
    paint_steel(cap, STEEL, STEEL_LIGHT)
    body.append(cap)
    for sx in (-1, 1):
        rib = cbox("Rib", (0.9, 1.9, 9.6), (sx * 3.55, 0, 4.9), bevel=0.1)
        paint_steel(rib, STEEL, sb2.mix(STEEL, STEEL_LIGHT, 0.5))
        body.append(rib)
        panel = cbox("Panel", (2.7, 0.4, 5.0), (sx * 1.6, 0.75, 4.5), bevel=0.15)
        paint_steel(panel, STEEL, sb2.mix(STEEL, STEEL_LIGHT, 0.5))
        body.append(panel)
    pipe = octo("Pipe", 0.3, 6.8, (0, 0.95, 8.4), rot=(0, math.pi / 2, 0))
    paint_steel(pipe, STEEL, STEEL_LIGHT)
    body.append(pipe)
    for x in (-2.3, 2.3):
        cl = cbox("Clamp", (0.5, 0.55, 0.85), (x, 0.9, 8.4), bevel=0.06)
        paint_steel(cl, STEEL_DARK, STEEL)
        body.append(cl)
    body.append(decal("Rust", (1.4, 0.03, 1.5), (-1.3, 0.965, 2.8), RUST_DARK))
    body.append(decal("Scorch", (2.4, 0.03, 0.9), (1.9, 0.615, 1.9), SCORCH, rough=0.95))
    strip = sb.box("Strip_Glow", (6.6, 0.12, 0.26), (0, 0.66, 7.5), bevel=0)
    paint_glow(strip, CYAN, 2.4)
    return {"Body": sb.join(body, "Body"), "Strip_Glow": strip}


def build_Pillar():
    """12-stud octagonal column on the 4.4 footprint: dark shaft, hazard ring at the base, mid collar, four cyan slots
    under a lit ring, rust running down from the cap."""
    body = []
    base = octo("Base", 2.2, 0.9, (0, 0, 0.45), bevel=0.12)
    paint_steel(base, STEEL_DARK, STEEL)
    body.append(base)
    shaft = octo("Shaft", 1.7, 11.0, (0, 0, 6.0))
    paint_steel(shaft, STEEL_DARK)
    body.append(shaft)
    ring = octo("Band", 1.8, 0.6, (0, 0, 1.25))
    paint_hazard_ring(ring)
    body.append(ring)
    collar = octo("Collar", 1.95, 0.7, (0, 0, 6.6), bevel=0.08)
    paint_steel(collar, STEEL, STEEL_LIGHT)
    body.append(collar)
    cap = octo("Cap", 2.2, 0.8, (0, 0, 11.6), bevel=0.12)
    paint_steel(cap, STEEL, STEEL_LIGHT)
    body.append(cap)
    flat = 1.7 * math.cos(math.pi / 8)
    glows = []
    for k in range(4):
        a = k * math.pi / 2
        s = sb.box("Slot", (0.32, 0.12, 3.2), rz((0, flat + 0.03, 8.9), a), (0, 0, a), bevel=0)
        paint_glow(s, CYAN, 2.2)
        glows.append(s)
        pl = cbox("Plate", (1.4, 0.2, 2.2), rz((0, flat + 0.05, 3.6), a), (0, 0, a), bevel=0.06)
        paint_steel(pl, STEEL, sb2.mix(STEEL, STEEL_LIGHT, 0.5))
        body.append(pl)
    body.append(decal("Rust", (1.1, 0.03, 1.8), rz((0.3, flat + 0.02, 10.2), 0), SCORCH if False else RUST_DARK))
    lit = octo("Ring", 1.85, 0.16, (0, 0, 11.1))
    paint_glow(lit, CYAN, 1.0)
    glows.append(lit)
    return {"Body": sb.join(body, "Body"), "Ring_Glow": sb.join(glows, "Ring_Glow")}


# ================================================================ props
def build_Crate():
    """4-stud cargo crate: chamfered dark cube with a hazard-amber lid third (the KayKit two-tone), four corner ribs,
    a grab bar, a lit label on two faces, rust at one corner."""
    core = cbox("Core", (4, 4, 4), (0, 0, 2), bevel=0.3)
    paint_steel(core, STEEL_DARK, STEEL)
    lid = cbox("Lid", (4.1, 4.1, 1.3), (0, 0, 3.4), bevel=0.3)
    paint_steel(lid, sb2.darken(HAZARD, 0.9), sb2.lighten(HAZARD, 0.12), roughness=0.62, metallic=0.0)
    body = [core, lid]
    for sx in (-1, 1):
        for sy in (-1, 1):
            r = cbox("Rib", (0.55, 0.55, 4.1), (sx * 1.8, sy * 1.8, 2.05), bevel=0.1)
            paint_steel(r, STEEL, sb2.mix(STEEL, STEEL_LIGHT, 0.5))
            body.append(r)
    bar = cbox("Bar", (1.8, 0.4, 0.4), (0, 0, 4.2), bevel=0.08)
    paint_steel(bar, STEEL, STEEL_LIGHT)
    body.append(bar)
    body.append(decal("Rust", (1.3, 0.03, 0.9), (-0.9, 2.06, 0.9), RUST_DARK))
    glows = []
    for sy in (-1, 1):
        lab = sb.box("Label_Glow", (1.5, 0.08, 0.36), (0.4, sy * 2.06, 1.7), bevel=0)
        paint_glow(lab, CYAN, 2.2)
        glows.append(lab)
    return {"Body": sb.join(body, "Body"), "Label_Glow": sb.join(glows, "Label_Glow")}


def build_Barrel():
    """Ten-sided steel drum, 2.5 wide and 3.4 tall: dark body, hazard ring, two ribs, and a purple Nest leak
    (pool on the lid, a drip down the side, a puddle)."""
    drum = octo("Drum", 1.2, 3.2, (0, 0, 1.6), sides=10, bevel=0.1)
    paint_steel(drum, STEEL_DARK, STEEL)
    body = [drum]
    for z in (0.7, 2.5):
        rib = octo("Rib", 1.3, 0.26, (0, 0, z), sides=10)
        paint_steel(rib, STEEL, STEEL_LIGHT)
        body.append(rib)
    ring = octo("Band", 1.26, 0.7, (0, 0, 1.6), sides=10)
    paint_hazard_ring(ring, 10)
    body.append(ring)
    lid = octo("Lid", 1.05, 0.2, (0, 0, 3.3), sides=10, bevel=0.05)
    paint_steel(lid, STEEL, STEEL_LIGHT)
    body.append(lid)
    bar = cbox("Handle", (0.9, 0.28, 0.24), (0, -0.2, 3.5), bevel=0.05)
    paint_steel(bar, STEEL, STEEL_LIGHT)
    body.append(bar)
    body.append(decal("Rust", (0.9, 0.03, 1.1), (-0.4, -1.16, 0.75), RUST_DARK))
    pool = octo("Leak_Glow", 0.6, 0.08, (0.3, 0.3, 3.42), sides=10)
    paint_glow(pool, NEST, 1.5)
    drip = sb2.seg_limb("Drip", [(0, 0, 0), (0.05, 0.02, -0.9), (0.1, 0.05, -2.0)], [0.22, 0.16, 0.08], location=(0.95, 0.65, 3.3), sides=6, joint=1.0)
    paint_glow(drip, NEST, 1.5)
    puddle = octo("Puddle", 0.9, 0.05, (1.0, 0.7, 0.025), sides=10)
    puddle.scale = (1.4, 1.0, 1.0)
    sb.apply_transforms(puddle)
    paint_glow(puddle, NEST, 1.2)
    return {"Body": sb.join(body, "Body"), "Leak_Glow": sb.join([pool, drip, puddle], "Leak_Glow")}


# ================================================================ gates
def build_Gate():
    """12-wide airlock gate, 11 tall, player side +Y: two heavy posts with jambs, lintel and cap, the door leaves parked
    open in front of the posts with a hazard band, cyan lamps on the posts, a lit sign on the lintel."""
    body, glows = [], []
    for sx in (-1, 1):
        post = cbox("Post", (2.4, 3.2, 10.2), (sx * 4.8, 0, 5.1), bevel=0.15)
        paint_steel(post, STEEL_DARK, STEEL)
        jamb = cbox("Jamb", (0.6, 2.4, 9.6), (sx * 3.4, 0, 4.8), bevel=0.08)
        paint_steel(jamb, STEEL, STEEL_LIGHT)
        leaf = cbox("Leaf", (3.4, 0.7, 8.6), (sx * 4.9, 1.9, 4.45), bevel=0.14)
        paint_steel(leaf, STEEL, sb2.mix(STEEL, STEEL_LIGHT, 0.5))
        body += [post, jamb, leaf]
        hz = hazard_plate("Hazard", 2.8, 1.3, period=0.9)
        hz.location = (sx * 4.9, 2.27, 3.5)
        body.append(hz)
        body.append(decal("Rust", (1.2, 0.03, 1.3), (sx * 4.4, 2.265, 1.0), RUST_DARK))
        house = cbox("Housing", (1.0, 0.9, 0.7), (sx * 4.8, 1.85, 9.4), bevel=0.06)
        paint_steel(house, STEEL_DARK, STEEL)
        body.append(house)
        bulb = sb2.lowpoly_sphere("Lamp", 0.32, (sx * 4.8, 2.25, 9.35), subdiv=1)
        paint_glow(bulb, CYAN, 2.2)
        glows.append(bulb)
    lintel = cbox("Lintel", (12, 3.2, 1.6), (0, 0, 10.2), bevel=0.15)
    paint_steel(lintel, STEEL_DARK, STEEL)
    cap = cbox("Cap", (12.4, 3.4, 0.4), (0, 0, 11.2), bevel=0.1)
    paint_steel(cap, STEEL, STEEL_LIGHT)
    track = cbox("Track", (12, 0.9, 0.16), (0, 1.5, 0.08), bevel=0.03)
    paint_steel(track, sb2.darken(STEEL_DARK, 0.8))
    thresh = cbox("Threshold", (6.4, 2.6, 0.2), (0, 0, 0.1), bevel=0.05)
    paint_steel(thresh, STEEL_DARK, STEEL)
    body += [lintel, cap, track, thresh]
    sign = sb.box("Sign_Glow", (4.2, 0.1, 0.5), (0, 1.65, 10.2), bevel=0)
    paint_glow(sign, CYAN, 2.0)
    glows.append(sign)
    return {"Body": sb.join(body, "Body"), "Sign_Glow": sb.join(glows, "Sign_Glow")}


def build_BossGate():
    """17.5-wide, 14.4-tall boss door, player side +Y: buttresses, header with a hazard band, two heavy leaves with a
    hazard band each, the red seam between them and a red light bar on the header."""
    body = []
    frame = cbox("Frame", (14, 1.6, 12.6), (0, 0, 6.3), bevel=0.15)
    paint_steel(frame, STEEL_DARK)
    header = cbox("Header", (16, 2.8, 2.2), (0, 0, 12.9), bevel=0.15)
    paint_steel(header, STEEL_DARK, STEEL)
    cap = cbox("Cap", (16.4, 3.0, 0.4), (0, 0, 14.2), bevel=0.1)
    paint_steel(cap, STEEL, STEEL_LIGHT)
    thresh = cbox("Threshold", (14, 2.4, 0.4), (0, 0, 0.2), bevel=0.06)
    paint_steel(thresh, STEEL_DARK, STEEL)
    body += [frame, header, cap, thresh]
    hz = hazard_plate("HeaderHazard", 12.0, 1.0, period=1.1)
    hz.location = (0, 1.43, 12.9)
    body.append(hz)
    for sx in (-1, 1):
        but = cbox("Buttress", (2.2, 2.8, 13.2), (sx * 7.65, 0, 6.6), bevel=0.15)
        paint_steel(but, STEEL, sb2.mix(STEEL, STEEL_LIGHT, 0.5))
        body.append(but)
        door = cbox("Door", (6.4, 0.8, 10.2), (sx * 3.3, 1.0, 5.5), bevel=0.15)
        paint_steel(door, STEEL, sb2.mix(STEEL, STEEL_LIGHT, 0.4))
        body.append(door)
        hz = hazard_plate("DoorHazard", 4.6, 1.6, period=1.1)
        hz.location = (sx * 3.3, 1.43, 3.4)
        body.append(hz)
        panel = cbox("Panel", (3.6, 0.3, 2.6), (sx * 3.3, 1.5, 8.4), bevel=0.12)
        paint_steel(panel, STEEL_DARK, STEEL)
        body.append(panel)
        body.append(decal("Scorch", (2.4, 0.03, 1.2), (sx * 2.6, 1.42, 1.1), SCORCH, rough=0.95))
        body.append(decal("Rust", (1.0, 0.03, 2.2), (sx * 5.6, 1.42, 6.6), RUST_DARK))
    seam = sb.box("Seam_Glow", (0.4, 0.2, 10.2), (0, 1.35, 5.5), bevel=0)
    paint_glow(seam, RED, 1.6)
    bar = sb.box("LightBar", (13, 0.2, 0.34), (0, 1.5, 13.75), bevel=0)
    paint_glow(bar, RED, 1.3)
    return {"Body": sb.join(body, "Body"), "Seam_Glow": sb.join([seam, bar], "Seam_Glow")}


# ================================================================ nest
def tendril(name, pts, radii, location, sides=7, tris=450):
    t = sb2.seg_limb(name, pts, radii, location=location, sides=sides, joint=1.25, fuse=0.13)
    sb2.facet(t, tris)
    paint_nest(t)
    return t


def build_SpawnHole():
    """8x8 module with a real hole in it: torn, lifted plates around a rough rim, the Nest glow in the pit (plate + hot
    core), cracks of purple light running out over the floor, four tendrils climbing out, a translucent beacon column
    (Studio tweens its transparency on spawn)."""
    slab = cbox("Slab", (8, 8, 1), (0, 0, -0.5), bevel=0.05)
    cut(slab, sb.cylinder("Cut", 3.0, 2.0, (0, 0, 0), verts=16))
    paint_steel(slab, STEEL_DARK, FLOOR_TOP)
    body = [slab]
    rim = torus_lp("Rim", 3.15, 0.38, (0, 0, 0.12), maj=16, mn=6)
    sb.displace_noise(rim, 0.22, 0.7)
    sb.apply_modifiers(rim)
    sb2.shade_flat(rim)
    paint_steel(rim, sb2.darken(STEEL_DARK, 0.8), STEEL)
    body.append(rim)
    for k in range(6):
        phi = k * 2 * math.pi / 6 + 0.4
        p = cbox("Torn", (1.6, 1.1, 0.16), (math.cos(phi) * 3.5, math.sin(phi) * 3.5, 0.42), (0.5, 0, phi + math.pi / 2), bevel=0.04)
        paint_steel(p, STEEL, sb2.mix(STEEL, STEEL_LIGHT, 0.5))
        body.append(p)
    body.append(decal("Scorch", (2.0, 1.2, 0.02), (2.6, -2.9, 0.0), SCORCH, rot=(0, 0, 0.5), rough=0.95))
    inner = octo("Inner_Glow", 2.9, 0.1, (0, 0, -0.32), sides=16)
    paint_glow(inner, NEST, 1.0)
    core = octo("Core", 1.6, 0.08, (0, 0, -0.26), sides=12)
    paint_glow(core, NEST_HOT, 2.0)
    glows = [inner, core]
    for k in range(8):
        a = k * math.pi / 4 + 0.2
        L = 0.9 if k % 2 == 0 else 2.0
        c = sb.box("Crack", (L, 0.16, 0.05), rz((3.25 + L / 2, 0, 0.02), a), (0, 0, a), bevel=0)
        paint_glow(c, NEST, 1.3)
        glows.append(c)
    # beacon: a narrower column whose colour (and so its emission) fades to nothing at the top
    column = octo("Column_Glow", 2.1, 7.0, (0, 0, 3.6), sides=12)
    sb2.paint_rules(column, NEST, [sb2.height(NEST, (0, 0, 0, 1), curve=1.0)], roughness=0.4, emission=1.0, alpha=0.14)
    roots = []
    tpts = [(0, 0, -0.5), (0.9, 0, 1.4), (2.0, 0.3, 2.5), (3.0, 0.6, 1.7), (3.7, 0.8, 0.45)]
    tradii = [0.55, 0.45, 0.32, 0.2, 0.06]
    for k in range(4):
        a = k * math.pi / 2 + 0.7
        pts = [rz(p, a) for p in tpts]
        loc = rz((1.5, 0, 0), a)
        t = tendril("Tendril%d" % k, pts, tradii, loc, tris=420)
        roots.append(t)
        w = [Vector(loc) + Vector(p) for p in pts]
        d = (w[4] - w[3]).normalized()
        for i, off in enumerate((-0.15, 0.15)):
            side = d.cross(Vector((0, 0, 1))).normalized()
            h = sb2.horn("Claw%d_%d" % (k, i), w[4] + side * off, d, 0.5, 0.07, sides=4, curve=0.3)
            sb2.paint_rules(h, sb2.darken(BONE, 0.6), [top_light(BONE, 0.8, 1.0)], roughness=0.35)
            roots.append(h)
        out = Vector(rz((1, 0, 0), a))
        for i, f in enumerate((0.35, 0.6)):
            j = int(f * 4)
            u = f * 4 - j
            pos = w[j].lerp(w[j + 1], u)
            r = tradii[j] * (1 - u) + tradii[j + 1] * u
            dd = (Vector((0, 0, 1)) + out * 0.5).normalized()
            th = sb2.horn("Thorn%d_%d" % (k, i), pos + dd * (r * 0.5), dd, 0.75, 0.13, sides=4)
            sb2.paint_rules(th, sb2.darken(BONE, 0.6), [top_light(BONE, 0.8, 1.0)], roughness=0.35)
            roots.append(th)
        glows += nodes_on("Node%d_" % k, t, (0.3, 0.55), 0.15)
    return {"Body": sb.join(body, "Body"), "Roots": sb.join(roots, "Roots"),
            "Inner_Glow": sb.join(glows, "Inner_Glow"), "Column_Glow": column}


def build_NestRoot():
    """The Nest breaking through the platform: torn plating with a glowing crack, one big arched root with three
    floor-hugging branches, claws, bone thorns, purple crack rings at the joints and glowing nodes on its back."""
    plate = cbox("Torn", (3.6, 3.6, 0.3), (0, 0, 0.15), bevel=0.05)
    cut(plate, sb.cylinder("Cut", 1.5, 1.0, (0, 0, 0.15), verts=12))
    paint_steel(plate, STEEL_DARK, STEEL)
    body = [plate]
    for k in range(4):
        phi = k * math.pi / 2 + 0.4
        p = cbox("Peel", (1.2, 0.9, 0.12), (math.cos(phi) * 1.75, math.sin(phi) * 1.75, 0.55), (0.5, 0, phi + math.pi / 2), bevel=0.03)
        paint_steel(p, STEEL, sb2.mix(STEEL, STEEL_LIGHT, 0.5))
        body.append(p)
    rim = torus_lp("Rim", 1.55, 0.22, (0, 0, 0.3), maj=16, mn=6)
    sb.displace_noise(rim, 0.12, 0.9)
    sb.apply_modifiers(rim)
    sb2.shade_flat(rim)
    paint_steel(rim, sb2.darken(STEEL_DARK, 0.8), STEEL)
    body.append(rim)
    pts = [(0, 0, 0.2), (1.0, 0.5, 1.5), (1.7, 2.4, 3.1), (3.1, 4.3, 3.3), (4.7, 5.7, 1.9), (5.5, 6.5, 0.4)]
    radii = [1.35, 1.15, 0.85, 0.6, 0.3, 0.08]
    root = sb2.seg_limb("Root", pts, radii, location=(0, 0, 0), sides=8, joint=1.2, fuse=0.15)
    sb2.facet(root, 1000)
    cut(root, sb.box("Cut", (24, 24, 4), (3, 3, -2), bevel=0))
    paint_nest(root)
    body.append(root)
    w = [Vector(p) for p in pts]
    bdefs = [(1, [(0, 0, 0), (-1.1, 0.8, -0.6), (-2.3, 1.5, -1.1)]),
             (2, [(0, 0, 0), (1.4, -0.4, -1.4), (2.7, -0.3, -2.6)]),
             (3, [(0, 0, 0), (-0.7, 1.3, -1.5), (-1.2, 2.6, -2.9)])]
    for k, (i, bp) in enumerate(bdefs):
        b = sb2.seg_limb("Branch%d" % k, bp, [0.55, 0.34, 0.08], location=tuple(w[i]), sides=6, joint=1.2, fuse=0.12)
        sb2.facet(b, 260)
        cut(b, sb.box("Cut", (24, 24, 4), (3, 3, -2), bevel=0))
        paint_nest(b)
        body.append(b)
        end = w[i] + Vector(bp[2])
        d = (Vector(bp[2]) - Vector(bp[1])).normalized()
        side = d.cross(Vector((0, 0, 1))).normalized()
        for j, off in enumerate((-0.15, 0.15)):
            h = sb2.horn("Claw%d_%d" % (k, j), end + side * off - Vector((0, 0, 0.1)), (d.x, d.y, -0.2), 0.55, 0.08, sides=4, curve=0.3)
            sb2.paint_rules(h, sb2.darken(BONE, 0.6), [top_light(BONE, 0.8, 1.0)], roughness=0.35)
            body.append(h)
    for i in range(6):
        f = 0.15 + i * 0.14
        j = min(int(f * 5), 4)
        u = f * 5 - j
        pos = w[j].lerp(w[j + 1], u)
        tan = (w[j + 1] - w[j]).normalized()
        r = radii[j] * (1 - u) + radii[j + 1] * u
        side = Vector((-tan.y, tan.x, 0)) * (0.45 if i % 2 else -0.45)
        d = (Vector((0, 0, 1)) + tan * 0.3 + side).normalized()
        th = sb2.horn("Thorn%d" % i, pos + d * (r * 0.5), d, 0.9, 0.16, sides=4)
        sb2.paint_rules(th, sb2.darken(BONE, 0.6), [top_light(BONE, 0.8, 1.0)], roughness=0.35)
        body.append(th)
    glows = []
    for i in (1, 2, 3):
        tan = ((w[i] - w[i - 1]).normalized() + (w[i + 1] - w[i]).normalized()).normalized()
        ring = torus_lp("Crack%d" % i, radii[i] * 1.12 + 0.03, 0.09, tuple(w[i]), tan.to_track_quat("Z", "Y").to_euler(), 12, 5)
        paint_glow(ring, NEST, 1.5)
        glows.append(ring)
    glows += nodes_on("Node", root, (0.3, 0.5, 0.72), 0.24)
    hot = sb2.lowpoly_sphere("Hot", 0.3, tuple(w[2] + Vector((0, 0, radii[2] * 0.9))), subdiv=1)
    paint_glow(hot, NEST_HOT, 2.5)
    glows.append(hot)
    crack = octo("Crack_Glow", 1.45, 0.08, (0, 0, 0.05), sides=12)
    paint_glow(crack, NEST, 1.2)
    glows.append(crack)
    for k in range(4):
        a = k * math.pi / 2 + math.pi / 4
        c = sb.box("Strip", (1.1, 0.14, 0.05), rz((2.1, 0, 0.32), a), (0, 0, a), bevel=0)
        paint_glow(c, NEST, 1.3)
        glows.append(c)
    return {"Body": sb.join(body, "Body"), "Nodes_Glow": sb.join(glows, "Nodes_Glow")}


# ================================================================ furniture
def build_Railing():
    """8-long waist-high railing: chamfered posts on foot plates, top and mid rail, a hazard kick plate, cross braces
    in the bays (the 'Mesh' part) and a cyan line along the top."""
    body = []
    for i in range(4):
        x = -3.75 + i * 2.5
        p = cbox("Post", (0.5, 0.5, 3.0), (x, 0, 1.5), bevel=0.06)
        paint_steel(p, STEEL, STEEL_LIGHT)
        f = cbox("Foot", (0.9, 0.9, 0.16), (x, 0, 0.08), bevel=0.04)
        paint_steel(f, STEEL_DARK, STEEL)
        body += [p, f]
    top = cbox("TopRail", (8, 0.36, 0.36), (0, 0, 2.95), bevel=0.06)
    paint_steel(top, STEEL, STEEL_LIGHT)
    mid = cbox("MidRail", (8, 0.2, 0.2), (0, 0, 1.85), bevel=0.04)
    paint_steel(mid, STEEL_DARK, STEEL)
    kick = hazard_plate("Kick", 8.0, 0.7, period=1.0, thick=0.16)
    kick.location = (0, 0, 0.5)
    body += [top, mid, kick]
    mesh = []
    for i in range(3):
        cx = -2.5 + i * 2.5
        for d in (-1, 1):
            b = sb.box("Brace", (0.1, 0.08, 2.4), (cx, 0, 1.4), (0, d * math.radians(44), 0), bevel=0)
            sb2.shade_flat(b)
            paint_steel(b, STEEL_DARK, STEEL)
            mesh.append(b)
    line = sb.box("Line_Glow", (7.2, 0.12, 0.12), (0, 0, 3.19), bevel=0)
    paint_glow(line, CYAN, 2.2)
    return {"Body": sb.join(body, "Body"), "Mesh": sb.join(mesh, "Mesh"), "Line_Glow": line}


def build_Lamp():
    """7-stud work light: our octagonal post on a base with a hazard ring and a junction box with a cyan status light;
    on top the four-headed CC0 KayKit 'lights' unit (repainted dark steel) with our warm bulb plates under its heads,
    and a faint light cone (Beam_Glow, translucent)."""
    base = octo("Base", 1.0, 0.4, (0, 0, 0.2), bevel=0.08)
    paint_steel(base, STEEL_DARK, STEEL)
    post = octo("Post", 0.32, 6.2, (0, 0, 3.1))
    paint_steel(post, STEEL, STEEL_LIGHT)
    ring = octo("Band", 0.35, 0.5, (0, 0, 1.2))
    paint_hazard_ring(ring)
    box = cbox("Box", (0.7, 0.5, 0.9), (0, -0.3, 2.4), bevel=0.06)
    paint_steel(box, STEEL_DARK, STEEL)
    body = [base, post, ring, box]
    glows = []
    ks = KIT_SCALE * 1.5
    head = None
    if os.path.exists(KIT + "lights.gltf"):
        head = sb2.import_kit(KIT + "lights.gltf", name="Head", scale=ks)
    if head is not None:
        # keep the head unit (everything above 0.57 KayKit units: the upper post and the four heads), drop its own
        # base, lift it so the heads top out at 6.9 studs on our post (the unit is 1.0 KayKit unit tall)
        bpy.context.view_layer.update()
        me = head.data
        bm = bmesh.new()
        bm.from_mesh(me)
        mw = head.matrix_world.copy()
        kill = [f for f in bm.faces if (mw @ f.calc_center_median()).z < 0.57 * ks]
        bmesh.ops.delete(bm, geom=kill, context="FACES")
        bm.to_mesh(me)
        bm.free()
        lift = 6.9 - 1.0 * ks
        head.matrix_world = Matrix.Translation((0, 0, lift)) @ mw
        paint_steel(head, STEEL, STEEL_LIGHT)
        body.append(head)
        for k in range(4):
            a = k * math.pi / 2
            b = sb.box("Bulb_Glow", (0.5, 0.42, 0.08), rz((0.24 * ks, 0, 0.868 * ks + lift), a), (0, 0, a), bevel=0)
            paint_glow(b, WARM, 2.4)
            glows.append(b)
    else:
        for k in range(4):
            a = k * math.pi / 2
            arm = cbox("Arm", (0.3, 1.6, 0.3), rz((0, 0.8, 6.7), a), (0, 0, a), bevel=0.04)
            paint_steel(arm, STEEL_DARK, STEEL)
            hd = cbox("Head", (1.1, 1.2, 0.5), rz((0, 1.5, 6.6), a), (0, 0, a), bevel=0.08)
            paint_steel(hd, STEEL_DARK, STEEL)
            body += [arm, hd]
            b = sb.box("Bulb_Glow", (0.8, 0.9, 0.08), rz((0, 1.5, 6.32), a), (0, 0, a), bevel=0)
            paint_glow(b, WARM, 2.4)
            glows.append(b)
    status = sb2.lowpoly_sphere("Status", 0.13, (0, -0.58, 2.5), subdiv=1)
    paint_glow(status, CYAN, 2.5)
    glows.append(status)
    beam = sb.cylinder("Beam_Glow", 3.4, 6.2, (0, 0, 3.35), verts=12, smooth=False, r2=1.3)
    paint_glow(beam, WARM, 0.5, alpha=0.07)
    return {"Body": sb.join(body, "Body"), "Bulb_Glow": sb.join(glows, "Bulb_Glow"), "Beam_Glow": beam}


# ================================================================ registry + build loop (mirrors enemies2.py)
ARENA = {
    "FloorTile": build_FloorTile, "FloorGrate": build_FloorGrate, "Wall": build_Wall, "Pillar": build_Pillar,
    "Crate": build_Crate, "Barrel": build_Barrel, "Gate": build_Gate, "SpawnHole": build_SpawnHole,
    "BossGate": build_BossGate, "Railing": build_Railing, "Lamp": build_Lamp, "NestRoot": build_NestRoot,
}
# render angle per piece (angle, elevation): flat floor modules from higher up, the root from its side
VIEW = {"FloorTile": (35, 32), "FloorGrate": (35, 32), "SpawnHole": (35, 28), "NestRoot": (-52, 24)}


def build_all(names=None, render=True, ao=True):
    names = names or list(ARENA.keys())
    for name in names:
        sb.reset()
        parts = ARENA[name]()
        objs = [o for o in parts.values() if o is not None]
        if ao:
            sb2.bake_ao(objs, strength=0.7, distance=1.4, samples=12)
        entry = sb.export_model("arena/%s" % name, objs, {"display": name, "recipe": "v2"})
        big = [(o.name, sb.tri_count(o)) for o in objs if sb.tri_count(o) > 3000]
        print("built", name, "parts=%d tris=%d size=%s" % (len(objs), entry["tris"], entry["size_studs"]), ("WARNING big parts: %s" % big) if big else "")
        sys.stdout.flush()
        if render:
            a, e = VIEW.get(name, (35, 22))
            out = sb2.render_model2(name, objs, "arena/%s.png" % name, angle_deg=a, elev_deg=e)
            print("rendered", out)
            sys.stdout.flush()


# ================================================================ the corner scene
def _point(name, at, color, energy, radius=1.0):
    ld = bpy.data.lights.new(name, "POINT")
    ld.energy = energy
    ld.color = color[:3]
    ld.shadow_soft_size = radius
    ob = bpy.data.objects.new(name, ld)
    sb._link(ob)
    ob.location = at
    return ob


def import_walker():
    """Our v2 Walker (vertex colours already baked) as separate parts, or None if the GLB is missing."""
    if not os.path.exists(WALKER_GLB):
        return None
    before = set(bpy.context.scene.objects)
    sb2.import_kit(WALKER_GLB, to_vcol=False, join_all=False, flat=False)
    parts = [o for o in bpy.context.scene.objects if o not in before and o.type == "MESH"]
    for o in parts:
        sb2.use_vcol(o, roughness=0.6, emission=2.0 if o.name.endswith("_Glow") else 0.0)
    return parts


def lineup(ao=True, render=True):
    """A corner of Outpost 9 from a gameplay angle: 5x5 floor modules (two grates, a spawn hole), walls on the -Y and
    -X sides with the gate in the back wall, pillars, crates, barrels, a nest root, railings, lamps and two Walkers
    for scale. The platform sits one stud above the Nest ground so its lit edge and the pit glow read."""
    sb.reset()
    rnd = random.Random(11)
    Z = 1.0
    built = {}
    placed = []

    def get(name):
        if name not in built:
            parts = ARENA[name]()
            objs = [o for o in parts.values() if o is not None]
            if ao:
                sb.hide_all_but(objs)
                sb2.bake_ao(objs, strength=0.7, distance=1.4, samples=8)
                sb.show_all()
            built[name] = [(o.name, o.data, o.matrix_world.copy()) for o in objs]
            for o in objs:
                bpy.data.objects.remove(o, do_unlink=True)
        return built[name]

    def put(name, x, y, rot=0.0, z=Z):
        R = Matrix.Rotation(math.radians(rot), 4, "Z")
        for pname, data, mw in get(name):
            c = bpy.data.objects.new("%s_%s" % (name, pname), data)
            sb._link(c)
            c.matrix_world = Matrix.Translation(Vector((x, y, z))) @ R @ mw
            placed.append(c)

    specials = {(0, 0): "SpawnHole", (-8, 8): "FloorGrate", (8, -8): "FloorGrate"}
    for x in range(-16, 17, 8):
        for y in range(-16, 17, 8):
            name = specials.get((x, y), "FloorTile")
            put(name, x, y, rnd.choice((0, 90, 180, 270)) if name == "FloorTile" else 0)
    # back wall (fronts to +Y) with the gate, and the left wall (fronts to +X); pillars in the corners
    put("Pillar", -20.2, -20.2)
    put("Wall", -13.8, -21.0)
    put("Wall", -5.8, -21.0)
    put("Gate", 4.2, -21.4)
    put("Wall", 14.2, -21.0)
    put("Pillar", 20.6, -20.2)
    put("Wall", -21.0, -13.8, -90)
    put("BossGate", -21.4, -1.05, -90)
    put("Wall", -21.0, 11.7, -90)
    put("Pillar", -20.2, 18.4)
    put("Pillar", 10, -12)
    # cover and dressing
    put("Crate", -14.5, 12.5, 12)
    put("Crate", -10.4, 13.3, -20)
    put("Crate", -14.3, 12.6, 40, z=Z + 4.0)
    put("Crate", 15.5, 9.0, -30)
    put("Barrel", -15.6, -7.0)
    put("Barrel", -13.4, -5.0, 60)
    put("Barrel", 13.6, 5.0, 20)
    put("NestRoot", 8, 11, 210)
    put("Railing", 20.5, 4, 90)
    put("Railing", 20.5, 12, 90)
    put("Lamp", 16.5, 16.5)
    put("Lamp", -16.0, -16.0)
    # the Nest under the platform: a purple ground that shows as a lit line under the platform edge
    bpy.ops.mesh.primitive_plane_add(size=46, location=(0, 0, 0.03))
    ground = bpy.context.active_object
    ground.name = "NestGround_Glow"
    paint_glow(ground, NEST, 0.6)
    placed.append(ground)
    # two Walkers for scale: one half out of the spawn hole (sunk 1.6 studs, inside the beacon), one crossing the
    # floor from the right toward it; neither sits under the camera
    walker = import_walker()
    if walker:
        placed += sb2.place_copy(walker, (10.5, -4.0, Z), rotation_deg=-115, suffix="_2")
        for o in walker:
            o.matrix_world = Matrix.Translation(Vector((0.3, 0.6, Z - 1.6))) @ Matrix.Rotation(math.radians(-30), 4, "Z") @ o.matrix_world
        placed += walker
    # scene lights: a dim cold moon, warm pools under the lamps, purple spill from the Nest openings, cyan at the gate
    sd = bpy.data.lights.new("Moon", "SUN")
    sd.energy = 0.9
    sd.color = (0.72, 0.78, 1.0)
    sd.angle = math.radians(6)
    so = bpy.data.objects.new("Moon", sd)
    sb._link(so)
    so.location = (30, 36, 50)
    sb._look_at(so, Vector((0, 0, Z)))
    _point("NestLight", (0, 0, Z + 2.5), NEST, 1400, 2.5)
    _point("GrateLight1", (-8, 8, Z + 1.5), NEST, 500, 2.0)
    _point("GrateLight2", (8, -8, Z + 1.5), NEST, 500, 2.0)
    _point("RootLight", (9, 12, Z + 3.5), NEST, 350, 1.5)
    _point("LampLight1", (16.5, 16.5, Z + 6.3), WARM, 900, 1.0)
    _point("LampLight2", (-16, -16, Z + 6.3), WARM, 900, 1.0)
    _point("GateLight", (4.2, -18.5, Z + 9.3), CYAN, 500, 1.0)
    if render:
        cam_at = (-3.0, -3.0, Z + 2.0)
        cam_from = (cam_at[0] + 0.55 * 28, cam_at[1] + 0.835 * 28, Z + 2.0 + 18)
        out = sb2.render_scene("arena/Lineup.png", cam_from=cam_from, cam_at=cam_at, lens=32, floor_z=0, fog=False, sun=False)
        print("rendered", out)
        sys.stdout.flush()
    return placed


if __name__ == "__main__":
    args = sys.argv[1:]
    render = os.environ.get("SB_NO_RENDER") != "1"
    ao = os.environ.get("SB_NO_AO") != "1"
    if args == ["lineup"]:
        lineup(ao=ao, render=render)
    else:
        names = [a for a in args if a in ARENA] or None
        build_all(names, render=render, ao=ao)
        if not names:
            lineup(ao=ao, render=render)
