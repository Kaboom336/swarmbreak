"""Arena kit: modular pieces for Outpost 9 (station platform built over the Nest).

Pieces are sized on a 4-stud grid so ArenaBuilder can tile them. Front = +Y. Sizes in studs.
Exports assets/models/arena/<Piece>.fbx|glb plus a lineup render.

Run:  python3 arena.py            python3 arena.py Pillar Crate
"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(__file__))
import bpy
import sb
from sb import PAL, rgb
from mathutils import Vector

STEEL = rgb(70, 78, 92)
STEEL_DARK = rgb(36, 40, 50)
STEEL_LIGHT = rgb(120, 128, 142)
PAINT = rgb(214, 120, 30)      # hazard orange paint
GLOW = rgb(40, 220, 200)       # station teal
NEST = rgb(150, 80, 200)       # nest purple
NEST_HOT = rgb(230, 170, 255)  # hot core of a nest glow
NEST_SHELL = rgb(90, 40, 130)  # veined purple on the top of roots
SLAB = rgb(24, 26, 32)         # floor slab / recess walls: a full value step below the walls
PANEL = rgb(54, 60, 72)        # floor panel
RECESS = rgb(30, 33, 42)       # recessed wall panels
SCORCH = rgb(22, 22, 26)
WARM = rgb(255, 235, 200)      # lamp light

ROT_Y = (math.pi / 2, 0, 0)    # cylinder axis along Y
ROT_X = (0, math.pi / 2, 0)    # cylinder axis along X


def metal(ob, color=STEEL, rough=0.55, metallic=0.3):
    return sb.paint(ob, color, roughness=rough, metallic=metallic)


def glow(ob, color=GLOW, strength=3.0, alpha=1.0):
    return sb.paint(ob, color, emission=strength, alpha=alpha)


def flat(name, size, at, color, rough=0.9, rot=(0, 0, 0)):
    """A thin non-metal box: paint bands, chevrons, scorch marks, decals."""
    b = sb.box(name, size, at, rot, bevel=0)
    sb.paint(b, color, roughness=rough)
    return b


def bolt(name, at, rotation=(0, 0, 0), r=0.14, depth=0.1, color=STEEL_LIGHT):
    b = sb.cylinder(name, r, depth, at, rotation, verts=8)
    metal(b, color)
    return b


def rz(p, a):
    """Rotate a point around Z."""
    c, s = math.cos(a), math.sin(a)
    return (p[0] * c - p[1] * s, p[0] * s + p[1] * c, p[2])


def torus_lp(name, major, minor, location=(0, 0, 0), rotation=(0, 0, 0), maj=24, mn=8):
    """Low-poly torus: sb.torus is 32x12 (768 tris), far too many for clamps, bands and rings."""
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor, major_segments=maj, minor_segments=mn)
    ob = bpy.context.active_object
    ob.name = name
    ob.location = location
    ob.rotation_euler = rotation
    for p in ob.data.polygons:
        p.use_smooth = True
    return ob


def cut_with(ob, cutter):
    """Boolean DIFFERENCE (EXACT) of cutter from ob, baked. Same pattern as the grate frame."""
    m = ob.modifiers.new("Cut", "BOOLEAN")
    m.operation = "DIFFERENCE"
    m.object = cutter
    m.solver = "EXACT"
    sb.apply_modifiers(ob)
    bpy.data.objects.remove(cutter, do_unlink=True)
    return ob


def cut_box(ob, size, location):
    return cut_with(ob, sb.box("Cut", size, location, bevel=0))


def cut_cyl(ob, radius, depth, location, verts=32):
    return cut_with(ob, sb.cylinder("Cut", radius, depth, location, verts=verts))


def solid_limb(name, pts, radii, location=(0, 0, 0), joints=1.2, subdiv=1):
    """sb.limb with Skin/Subsurf baked, so paint/gradient colour the real shell (vertex colours need polygons)."""
    t = sb.limb(name, pts, radii, location=location, joints=joints, subdiv=subdiv)
    sb.apply_modifiers(t)
    return t


def zgrad(ob, top, bottom, z0, z1, roughness=0.5):
    """Vertex gradient over a fixed world Z range shared by several objects, shown in renders too
    (sb.gradient uses each object's own range and a flat material)."""
    me = ob.data
    attr = me.color_attributes.get("Color") or me.color_attributes.new(name="Color", type="BYTE_COLOR", domain="CORNER")
    mw = ob.matrix_world
    for poly in me.polygons:
        for li in poly.loop_indices:
            z = (mw @ me.vertices[me.loops[li].vertex_index].co).z
            t = max(0.0, min(1.0, (z - z0) / max(z1 - z0, 1e-6)))
            attr.data[li].color_srgb = tuple(bottom[i] * (1 - t) + top[i] * t for i in range(4))
    me.color_attributes.active_color = attr
    me.color_attributes.render_color_index = me.color_attributes.find("Color")
    m = bpy.data.materials.new("M_vcol")
    m.use_nodes = True
    nodes = m.node_tree.nodes
    bsdf = nodes["Principled BSDF"]
    vc = nodes.new("ShaderNodeVertexColor")
    vc.layer_name = "Color"
    m.node_tree.links.new(vc.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = roughness
    me.materials.clear()
    me.materials.append(m)
    return ob


def along(w, radii, t):
    """Point, unit tangent and radius at fraction t (by length) along a polyline of Vectors."""
    seg = [(w[i + 1] - w[i]).length for i in range(len(w) - 1)]
    d = t * sum(seg)
    for i, L in enumerate(seg):
        if d <= L or i == len(seg) - 1:
            f = max(0.0, min(1.0, d / L))
            return w[i] + (w[i + 1] - w[i]) * f, (w[i + 1] - w[i]).normalized(), radii[i] * (1 - f) + radii[i + 1] * f
        d -= L


# ---------------------------------------------------------------- floor
def _slab():
    slab = sb.box("Slab", (8, 8, 1), (0, 0, -0.5), bevel=0.08)
    metal(slab, SLAB, 0.8, 0.1)
    return slab


def _sub_panels(dents=0.0):
    """Four 3.4 panels with a 0.3 dark seam between them (the seam carries the glow)."""
    out = []
    for x in (-1.85, 1.85):
        for y in (-1.85, 1.85):
            if dents > 0:
                bpy.ops.mesh.primitive_grid_add(x_subdivisions=6, y_subdivisions=6, size=3.4)
                p = bpy.context.active_object
                p.name = "Panel"
                p.location = (x, y, 0.08)
                m = p.modifiers.new("Solid", "SOLIDIFY")
                m.thickness = 0.12
                m.offset = -1
                sb.displace_noise(p, dents, 1.5)
            else:
                p = sb.box("Panel", (3.4, 3.4, 0.12), (x, y, 0.02), bevel=0.05)
            metal(p, PANEL, 0.78, 0.1)
            out.append(p)
    return out


def _tile_dressing(seed, treads=True, scorch=2):
    rnd = random.Random(seed)
    out = [bolt("Bolt", (x, y, 0.1), r=0.17) for x in (-3.3, 3.3) for y in (-3.3, 3.3)]
    out += [bolt("Bolt", (x, y, 0.1), r=0.17) for x in (-3.3, 3.3) for y in (-0.45, 0.45)]
    out += [bolt("Bolt", (x, y, 0.1), r=0.17) for y in (-3.3, 3.3) for x in (-0.45, 0.45)]
    if treads:
        for x in (-2.6, 2.6):
            t = sb.box("Tread", (0.35, 6.6, 0.05), (x, 0, 0.1), bevel=0)
            metal(t, STEEL_LIGHT, 0.7, 0.1)
            out.append(t)
    for i in range(scorch):
        x, y = rnd.uniform(-2.6, 2.6), rnd.uniform(-2.6, 2.6)
        out.append(sb.plate_on("Scorch", (x, y, 0.085), (0, 0, 1), (1.4, 0.9, 0.02), SCORCH, bevel=0, roll=rnd.uniform(0, math.pi)))
    return out


def build_floor_tile():
    body = [_slab()] + _sub_panels() + _tile_dressing(1)
    g1 = sb.box("Groove_Glow", (0.2, 6.8, 0.06), (0, 0, 0.03), bevel=0)
    g2 = sb.box("Groove2", (6.8, 0.2, 0.06), (0, 0, 0.03), bevel=0)
    for g in (g1, g2):
        glow(g, GLOW, 3)
    return {"Body": sb.join(body, "Body"), "Groove_Glow": sb.join([g1, g2], "Groove_Glow")}


def build_floor_tile_b():
    """Worn variant: dented panels, a T of glow seam, a hazard corner patch."""
    body = [_slab()] + _sub_panels(dents=0.05) + _tile_dressing(2, treads=False, scorch=0)
    body.append(flat("Hazard", (2.0, 0.6, 0.02), (2.4, 3.05, 0.12), PAINT, 0.7))
    body.append(flat("Hazard", (0.6, 2.0, 0.02), (3.25, 2.3, 0.12), PAINT, 0.7))
    g1 = sb.box("Groove_Glow", (0.2, 6.8, 0.06), (0, 0, 0.03), bevel=0)
    g2 = sb.box("Groove2", (3.4, 0.2, 0.06), (-1.7, 0, 0.03), bevel=0)
    for g in (g1, g2):
        glow(g, GLOW, 3)
    return {"Body": sb.join(body, "Body"), "Groove_Glow": sb.join([g1, g2], "Groove_Glow")}


def build_floor_tile_c():
    """Hazard / edge tile: plain panel, two diagonal paint stripes, a vent, one edge light (on -Y)."""
    panel = sb.box("Panel", (7.2, 7.2, 0.12), (0, 0, 0.02), bevel=0.05)
    metal(panel, PANEL, 0.78, 0.1)
    body = [_slab(), panel] + _tile_dressing(3, treads=False, scorch=1)
    for d in (-1, 1):
        body.append(flat("Stripe", (0.6, 5.0, 0.03), (d * 1.0 + 0.5, d * 1.0 + 0.5, 0.095), PAINT, 0.7, (0, 0, math.pi / 4)))
    vent = sb.box("Vent", (2.0, 1.0, 0.1), (-1.6, -2.4, 0.05), bevel=0)
    metal(vent, SLAB, 0.8, 0.1)
    body.append(vent)
    for k in range(3):
        s = sb.box("Slat", (1.8, 0.12, 0.05), (-1.6, -2.4 + (k - 1) * 0.3, 0.115), bevel=0)
        metal(s, STEEL, 0.6)
        body.append(s)
    g = sb.box("Groove_Glow", (7.0, 0.2, 0.06), (0, -3.8, 0.03), bevel=0)
    glow(g, GLOW, 3)
    return {"Body": sb.join(body, "Body"), "Groove_Glow": g}


def build_floor_grate():
    """Grate over the Nest: a real cavity in the slab with purple light in it, bars silhouetted on top."""
    slab = sb.box("Slab", (8, 8, 1), (0, 0, -0.5), bevel=0.08)
    cut_box(slab, (6.8, 6.8, 1.2), (0, 0, -0.3))      # cavity z -0.9 .. 0
    metal(slab, SLAB, 0.8, 0.1)
    frame = sb.box("Frame", (7.6, 7.6, 0.3), (0, 0, 0.05), bevel=0.04)
    cut_box(frame, (6.8, 6.8, 1), (0, 0, 0.05))
    metal(frame, STEEL, 0.6, 0.2)
    body = [slab, frame]
    for i in range(7):
        b = sb.box("Bar%d" % i, (0.35, 7.4, 0.3), (-3 + i, 0, 0.05), bevel=0.03)
        metal(b, STEEL, 0.55, 0.3)
        body.append(b)
    for y in (-2.2, 2.2):
        c = sb.box("Cross", (7.4, 0.3, 0.2), (0, y, -0.06), bevel=0.02)
        metal(c, STEEL_DARK, 0.6)
        body.append(c)
    body += [bolt("Bolt", (x, y, 0.2), r=0.16) for x in (-3.6, 3.6) for y in (-3.6, 3.6)]
    under = sb.box("Under_Glow", (6.6, 6.6, 0.08), (0, 0, -0.86), bevel=0)
    glow(under, NEST, 4)
    core = sb.cylinder("Core", 1.8, 0.05, (0, 0, -0.8), verts=24)
    glow(core, NEST_HOT, 7)
    glows = [under, core]
    for (x, y, a) in ((-1.5, -1.2, 0.6), (2.0, 1.5, 3.7)):   # roots poking up between the bars
        pts = [rz(p, a) for p in ((0, 0, -0.7), (0.3, 0.2, 0.05), (0.7, 0.5, 0.4))]
        r = solid_limb("Root", pts, [0.2, 0.13, 0.04], location=(x, y, 0), joints=1.2, subdiv=1)
        sb.paint(r, PAL["chitin2"], roughness=0.5)
        body.append(r)
        t = sb.tip(r)
        n = sb.sphere("Node", 0.12, (t.x, t.y, t.z), subdiv=2)
        glow(n, NEST, 4)
        glows.append(n)
    haze = sb.box("Haze_Glow", (6.6, 6.6, 0.6), (0, 0, -0.5), bevel=0)
    glow(haze, NEST, 1.2, alpha=0.3)
    return {"Body": sb.join(body, "Body"), "Under_Glow": sb.join(glows, "Under_Glow"), "Haze_Glow": haze}


# ---------------------------------------------------------------- walls
def build_wall():
    """8-stud station wall, dressed on both faces: plinth, hazard band, recessed panels, pipes, vent, ribs, cap."""
    base = sb.box("Base", (8, 1, 8), (0, 0, 4), bevel=0.08)
    metal(base, STEEL, 0.7, 0.2)
    plinth = sb.box("Plinth", (8.2, 1.5, 1.2), (0, 0, 0.6), bevel=0.05)
    metal(plinth, STEEL_DARK, 0.7)
    top = sb.box("Top", (8.2, 1.8, 0.6), (0, 0, 8.1), bevel=0.05)
    metal(top, STEEL_LIGHT, 0.6)
    body = [base, plinth, top]
    for x in (-3.6, 0, 3.6):
        r = sb.box("Rib", (0.8, 1.4, 8.2), (x, 0, 4.1), bevel=0.05)
        metal(r, rgb(92, 100, 114), 0.6)
        body.append(r)
        for sy in (-1, 1):
            for z in (1.7, 7.5):
                body.append(bolt("Bolt", (x, sy * 0.72, z), ROT_Y, 0.12, 0.08))
    glows = []
    for sy in (-1, 1):
        body.append(flat("Band", (8.0, 0.08, 1.2), (0, sy * 0.54, 1.9), PAINT, 0.7))
        for bx in (-1.8, 1.8):
            p = sb.box("Panel", (2.6, 0.12, 3.6), (bx, sy * 0.55, 4.6), bevel=0.03)
            metal(p, RECESS, 0.75, 0.1)
            body.append(p)
        for pz in (6.65, 7.05):
            pipe = sb.cylinder("Pipe", 0.18, 8, (0, sy * 0.72, pz), ROT_X, verts=12)
            metal(pipe, STEEL_LIGHT, 0.5)
            body.append(pipe)
            for cx in (-2.4, 0.9, 2.9):
                c = torus_lp("Clamp", 0.22, 0.05, (cx, sy * 0.72, pz), ROT_X, 16, 6)
                metal(c, STEEL_DARK, 0.6)
                body.append(c)
        vx = -1.8 * sy   # louvre vent in one bay (a different bay on each face)
        for k in range(5):
            s = sb.box("Slat", (1.8, 0.06, 0.12), (vx, sy * 0.64, 3.3 + k * 0.22), bevel=0)
            metal(s, STEEL, 0.6)
            body.append(s)
        for cx in (-3.6, 3.6):   # hazard chevron (V) on the outer ribs
            for d in (-1, 1):
                body.append(flat("Chevron", (0.32, 0.06, 1.0), (cx + d * 0.15, sy * 0.73, 1.9), PAINT, 0.7, (0, d * math.radians(35), 0)))
        body.append(flat("Scorch", (1.5, 0.06, 0.9), (2.3, sy * 0.78, 0.55), SCORCH, 0.9, (0, 0.15, 0)))
        body.append(flat("Scorch", (1.2, 0.06, 0.7), (-1.6, sy * 0.78, 0.5), SCORCH, 0.9, (0, -0.2, 0)))
        g = sb.box("Strip_Glow", (7.4, 0.1, 0.35), (0, sy * 0.55, 7.5), bevel=0)
        glow(g, GLOW, 3)
        glows.append(g)
    return {"Body": sb.join(body, "Body"), "Strip_Glow": sb.join(glows, "Strip_Glow")}


def build_wall_door():
    """Wall with a doorway on the same 8-stud footprint; the Gate slots into it (its jambs cover the stubs)."""
    body = []
    for sx in (-1, 1):
        stub = sb.box("Stub", (0.7, 1, 8), (sx * 3.65, 0, 4), bevel=0.06)
        metal(stub, STEEL, 0.7, 0.2)
        rib = sb.box("Rib", (0.6, 1.4, 8.2), (sx * 3.7, 0, 4.1), bevel=0.05)
        metal(rib, rgb(92, 100, 114), 0.6)
        pl = sb.box("Plinth", (0.8, 1.5, 1.2), (sx * 3.8, 0, 0.6), bevel=0.05)
        metal(pl, STEEL_DARK, 0.7)
        body += [stub, rib, pl]
    header = sb.box("Header", (8, 1, 1.6), (0, 0, 7.2), bevel=0.06)
    metal(header, STEEL, 0.7, 0.2)
    top = sb.box("Top", (8.2, 1.8, 0.6), (0, 0, 8.1), bevel=0.05)
    metal(top, STEEL_LIGHT, 0.6)
    body += [header, top]
    glows = []
    for sy in (-1, 1):
        g = sb.box("Strip_Glow", (7.4, 0.1, 0.35), (0, sy * 0.55, 7.5), bevel=0)
        glow(g, GLOW, 3)
        glows.append(g)
        body.append(flat("Band", (8.0, 0.08, 0.5), (0, sy * 0.54, 6.7), PAINT, 0.7))
    return {"Body": sb.join(body, "Body"), "Strip_Glow": sb.join(glows, "Strip_Glow")}


def build_pillar():
    """Cover column, wider than a player: dark corner brackets, collar, recessed panels, hazard band, two glow bands."""
    shaft = sb.box("Shaft", (3.5, 3.5, 8), (0, 0, 4), bevel=0.12)
    metal(shaft, STEEL, 0.6, 0.2)
    base = sb.box("Base", (4.4, 4.4, 0.8), (0, 0, 0.4), bevel=0.06)
    metal(base, STEEL_DARK, 0.7)
    cap = sb.box("Cap", (4.4, 4.4, 0.6), (0, 0, 7.95), bevel=0.06)
    metal(cap, STEEL_DARK, 0.7)
    collar = sb.box("Collar", (3.9, 3.9, 0.5), (0, 0, 4.0), bevel=0.05)
    metal(collar, STEEL_DARK, 0.7)
    body = [shaft, base, cap, collar]
    for sx in (-1, 1):
        for sy in (-1, 1):
            e = sb.box("Edge", (0.4, 0.4, 7.4), (sx * 1.75, sy * 1.75, 4.0), bevel=0.04)
            metal(e, STEEL_DARK, 0.6)
            body.append(e)
    for k in range(4):
        a = k * math.pi / 2
        rot = (0, 0, a)
        body.append(flat("Band", (3.6, 0.06, 0.6), rz((0, 1.77, 1.4), a), PAINT, 0.7, rot))
        for (z, h) in ((5.65, 2.5), (2.95, 1.3)):
            p = sb.box("Panel", (2.0, 0.15, h), rz((0, 1.76, z), a), rot, bevel=0.03)
            metal(p, RECESS, 0.75, 0.1)
            body.append(p)
        body.append(bolt("Bolt", rz((0, 1.98, 4.0), a), (math.pi / 2, 0, a), 0.12, 0.1))
    ring = sb.box("Ring_Glow", (3.8, 3.8, 0.18), (0, 0, 7.2), bevel=0)
    ring2 = sb.box("Ring2", (3.8, 3.8, 0.14), (0, 0, 1.95), bevel=0)
    disc = sb.cylinder("Disc", 1.4, 0.06, (0, 0, 8.28), verts=20)
    for g in (ring, ring2, disc):
        glow(g, GLOW, 3)
    return {"Body": sb.join(body, "Body"), "Ring_Glow": sb.join([ring, ring2, disc], "Ring_Glow")}


# ---------------------------------------------------------------- props
def _crate_frame(size=4.0):
    """Four light edge rails and eight dark corner brackets around a cube of `size`."""
    c = size / 2
    out = []
    for sx in (-1, 1):
        for sy in (-1, 1):
            r = sb.box("Rail", (0.36, 0.36, size + 0.04), (sx * (c - 0.1), sy * (c - 0.1), c + 0.02), bevel=0.04)
            metal(r, STEEL_LIGHT, 0.55)
            out.append(r)
            for sz in (-1, 1):
                z = c + sz * (c - 0.16)
                bx = sb.box("Bracket", (1.5, 0.5, 0.44), (sx * (c - 0.75), sy * (c - 0.19), z), bevel=0.04)
                by = sb.box("Bracket", (0.5, 1.5, 0.44), (sx * (c - 0.19), sy * (c - 0.75), z), bevel=0.04)
                for b in (bx, by):
                    metal(b, STEEL_DARK, 0.65)
                out += [bx, by]
    return out


def build_crate():
    """4-stud cover crate: recessed face plates, corner brackets, hazard band and a big label on both faces."""
    core = sb.box("Core", (4, 4, 4), (0, 0, 2), bevel=0.15)
    metal(core, rgb(88, 92, 104), 0.75, 0.1)
    body = [core] + _crate_frame(4)
    for k in range(4):
        a = k * math.pi / 2
        plate = sb.box("Plate", (2.6, 0.12, 2.6), rz((0, 2.0, 2.0), a), (0, 0, a), bevel=0.03)
        metal(plate, STEEL_DARK, 0.7)
        body.append(plate)
    lid = sb.box("Lid", (2.6, 2.6, 0.12), (0, 0, 4.0), bevel=0.03)
    metal(lid, STEEL_DARK, 0.7)
    body.append(lid)
    glows = []
    for sy in (-1, 1):
        body.append(flat("HazardBand", (4.1, 0.12, 0.8), (0, sy * 2.06, 1.0), PAINT, 0.7))
        label = sb.box("Label_Glow", (2.0, 0.08, 0.6), (0, sy * 2.08, 2.8), bevel=0)
        glow(label, GLOW, 3)
        light = sb.sphere("Light", 0.14, (1.35, sy * 2.08, 3.5), subdiv=2)
        glow(light, PAINT, 5)
        glows += [label, light]
    return {"Body": sb.join(body, "Body"), "Label_Glow": sb.join(glows, "Label_Glow")}


def build_crate_b():
    """Strapped variant for stacking variety: orange straps, lid seam, off-centre labels."""
    core = sb.box("Core", (4, 4, 4), (0, 0, 2), bevel=0.15)
    metal(core, rgb(80, 84, 96), 0.75, 0.1)
    body = [core] + _crate_frame(4)
    for a in (0, math.pi / 2):
        s = sb.box("Strap", (4.16, 0.7, 4.16), (0, 0, 2), (0, 0, a), bevel=0.04)
        sb.paint(s, PAINT, roughness=0.7)
        body.append(s)
    seam = sb.box("Seam", (4.1, 4.1, 0.1), (0, 0, 3.3), bevel=0)
    metal(seam, STEEL_DARK, 0.7)
    body.append(seam)
    glows = []
    for sy in (-1, 1):
        label = sb.box("Label_Glow", (1.4, 0.08, 0.5), (-1.2, sy * 2.08, 2.6), bevel=0)
        glow(label, GLOW, 3)
        glows.append(label)
    return {"Body": sb.join(body, "Body"), "Label_Glow": sb.join(glows, "Label_Glow")}


def build_barrel():
    """Steel hazard drum, waist high, with a purple Nest leak: pool on the lid, drip down the side, puddle."""
    drum = sb.cylinder("Drum", 1.1, 3.2, (0, 0, 1.6), verts=18, bevel=0.08)
    metal(drum, rgb(56, 62, 76), 0.65, 0.25)
    body = [drum]
    for z in (0.7, 2.5):
        b = torus_lp("Band", 1.12, 0.12, (0, 0, z), maj=24, mn=8)
        metal(b, STEEL_DARK, 0.6)
        body.append(b)
    hz = sb.cylinder("Hazard", 1.13, 0.5, (0, 0, 1.6), verts=18)
    sb.paint(hz, PAINT, roughness=0.7)
    body.append(hz)
    for k in range(6):
        a = k * math.pi / 3 + 0.26
        r = sb.box("Rib", (0.18, 0.18, 2.8), (math.cos(a) * 1.12, math.sin(a) * 1.12, 1.6), (0, 0, a), bevel=0.02)
        metal(r, STEEL_LIGHT, 0.55)
        body.append(r)
    lid = sb.cylinder("Lid", 1.0, 0.14, (0, 0, 3.24), verts=18)
    metal(lid, STEEL, 0.6)
    handle = torus_lp("Handle", 0.35, 0.05, (0, 0, 3.34), maj=16, mn=6)
    metal(handle, STEEL_LIGHT)
    body += [lid, handle]
    pool = sb.cylinder("Leak_Glow", 0.6, 0.08, (0.35, 0.2, 3.33), verts=16)
    glow(pool, NEST, 4)
    drip = solid_limb("Drip", [(0, 0, 0), (0.1, 0, -1.0), (0.2, 0, -2.0)], [0.25, 0.18, 0.1], location=(1.02, 0.15, 3.2), joints=1.0)
    glow(drip, NEST, 3)
    puddle = sb.cylinder("Puddle", 1.0, 0.04, (0.9, 0.2, 0.02), verts=16)
    puddle.scale = (1.4, 1.0, 1.0)
    glow(puddle, NEST, 2.5)
    return {"Body": sb.join(body, "Body"), "Leak_Glow": sb.join([pool, drip, puddle], "Leak_Glow")}


# ---------------------------------------------------------------- gates
def build_gate():
    """Airlock-style gate: posts with dark jambs, door leaves parked open, track, lit sign and lamps on both faces."""
    body, glows = [], []
    for sx in (-1, 1):
        post = sb.box("Post", (2, 2.5, 9), (sx * 5, 0, 4.5), bevel=0.1)
        metal(post, STEEL, 0.6, 0.2)
        jamb = sb.box("Jamb", (0.7, 2.6, 9), (sx * 3.65, 0, 4.5), bevel=0.05)
        metal(jamb, STEEL_DARK, 0.7)
        rail = sb.box("Rail", (0.3, 0.3, 8.6), (sx * 3.15, 0, 4.4), bevel=0.03)
        metal(rail, STEEL_LIGHT, 0.5)
        leaf = sb.box("Leaf", (3.6, 0.5, 8.2), (sx * 3.9, 0, 4.25), bevel=0.06)
        metal(leaf, STEEL, 0.55, 0.3)
        body += [post, jamb, rail, leaf]
        for sy in (-1, 1):
            for z in (3.0, 5.6):
                body.append(flat("Chevron", (0.4, 0.05, 1.6), (sx * 2.75, sy * 0.28, z), PAINT, 0.7, (0, sx * math.radians(35), 0)))
            for z in (1.0, 8.0):
                body.append(bolt("Bolt", (sx * 5, sy * 1.28, z), ROT_Y, 0.14, 0.1))
            house = sb.box("Housing", (0.9, 0.6, 0.6), (sx * 5, sy * 1.3, 8.2), bevel=0.04)
            metal(house, STEEL_DARK, 0.6)
            body.append(house)
            lamp = sb.sphere("Lamp", 0.3, (sx * 5, sy * 1.5, 8.2), subdiv=2)
            glow(lamp, GLOW, 3)
            glows.append(lamp)
    track = sb.box("Track", (12, 0.6, 0.15), (0, 0, 0.075), bevel=0.02)
    metal(track, STEEL_DARK, 0.7)
    thresh = sb.box("Threshold", (6.6, 1.6, 0.25), (0, 0, 0.125), bevel=0.03)
    metal(thresh, STEEL_DARK, 0.7)
    lintel = sb.box("Lintel", (12, 2.6, 1.8), (0, 0, 9.6), bevel=0.1)
    metal(lintel, STEEL_DARK, 0.65, 0.2)
    header = sb.box("Header", (12.4, 2.8, 0.5), (0, 0, 10.75), bevel=0.05)
    metal(header, STEEL_LIGHT, 0.6)
    body += [track, thresh, lintel, header]
    for sy in (-1, 1):
        plate = sb.box("SignPlate", (6.4, 0.12, 1.0), (0, sy * 1.33, 9.6), bevel=0.03)
        metal(plate, STEEL, 0.6)
        body.append(plate)
        for x in (-2.0, 0.0, 2.0):
            bar = sb.box("Sign_Glow", (1.6, 0.1, 0.5), (x, sy * 1.42, 9.6), bevel=0)
            glow(bar, PAINT, 3)
            glows.append(bar)
        for x in (-4.4, 4.4):
            for d in (-1, 1):
                body.append(flat("Chevron", (0.5, 0.06, 1.2), (x + d * 0.35, sy * 1.33, 9.6), PAINT, 0.7, (0, d * math.radians(35), 0)))
    return {"Body": sb.join(body, "Body"), "Sign_Glow": sb.join(glows, "Sign_Glow")}


def build_boss_gate():
    """Monumental boss door: header, buttresses, threshold, two heavy leaves with wide stripes, red seam and light bar."""
    frame = sb.box("Frame", (14, 1.5, 12), (0, 0, 6), bevel=0.15)
    metal(frame, STEEL_DARK, 0.65, 0.2)
    header = sb.box("Header", (16, 2.6, 2.2), (0, 0, 12.8), bevel=0.12)
    metal(header, STEEL_DARK, 0.6, 0.2)
    cap = sb.box("HeaderCap", (16.4, 2.8, 0.5), (0, 0, 14.15), bevel=0.06)
    metal(cap, STEEL_LIGHT, 0.6)
    thresh = sb.box("Threshold", (14, 2.0, 0.4), (0, 0, 0.2), bevel=0.05)
    metal(thresh, STEEL_DARK, 0.7)
    body = [frame, header, cap, thresh]
    for sx in (-1, 1):
        but = sb.box("Buttress", (2.2, 2.6, 13), (sx * 7.6, 0, 6.5), bevel=0.1)
        metal(but, STEEL, 0.6, 0.2)
        body.append(but)
        for sy in (-1, 1):
            body.append(flat("Band", (2.3, 0.06, 0.8), (sx * 7.6, sy * 1.33, 1.6), PAINT, 0.7))
        door = sb.box("Door", (6.4, 0.6, 10), (sx * 3.3, -0.6, 5.4), bevel=0.1)
        metal(door, STEEL, 0.55, 0.3)
        body.append(door)
        for x in (2.4, 4.5):
            body.append(flat("Stripe", (1.1, 0.06, 5.0), (sx * x, -0.93, 4.2), PAINT, 0.65, (0, sx * math.radians(35), 0)))
        panel = sb.box("Panel", (3.6, 0.12, 2.2), (sx * 3.3, -0.92, 8.9), bevel=0.03)
        metal(panel, RECESS, 0.75, 0.1)
        body.append(panel)
        for x in (0.7, 5.9):
            for z in (1.0, 3.7, 7.1, 10.0):
                body.append(bolt("Bolt", (sx * x, -0.95, z), ROT_Y, 0.16, 0.1))
        body.append(flat("Scorch", (2.0, 0.06, 1.2), (sx * 2.6, -0.97, 1.05), SCORCH, 0.9, (0, sx * 0.1, 0)))
    for sy in (-1, 1):   # hazard chevrons across the header, both faces
        for x in range(-6, 7, 2):
            for d in (-1, 1):
                body.append(flat("Chevron", (0.55, 0.06, 1.3), (x + d * 0.4, sy * 1.34, 12.4), PAINT, 0.7, (0, d * math.radians(35), 0)))
    # warning triangle above the seam
    body.append(flat("Tri", (1.2, 0.06, 0.22), (0, -0.85, 10.55), PAINT, 0.7))
    body.append(flat("Tri", (1.2, 0.06, 0.22), (0.3, -0.85, 11.07), PAINT, 0.7, (0, math.radians(60), 0)))
    body.append(flat("Tri", (1.2, 0.06, 0.22), (-0.3, -0.85, 11.07), PAINT, 0.7, (0, math.radians(-60), 0)))
    seam = sb.box("Seam_Glow", (0.45, 0.14, 10.2), (0, -0.95, 5.5), bevel=0)
    glow(seam, PAL["red"], 4)
    bar = sb.box("LightBar", (13, 0.2, 0.35), (0, -1.38, 13.55), bevel=0)
    glow(bar, PAL["red"], 3)
    return {"Body": sb.join(body, "Body"), "Seam_Glow": sb.join([seam, bar], "Seam_Glow")}


# ---------------------------------------------------------------- nest
def build_spawn_hole():
    """A Nest opening: an 8x8 floor module with a real hole, cracked rim, torn plating, purple pit glow,
    a translucent beacon column (Studio tweens its transparency on spawn) and four big tendrils climbing out."""
    slab = sb.box("Slab", (8, 8, 1), (0, 0, -0.5), bevel=0.08)
    cut_cyl(slab, 3.0, 2.0, (0, 0, 0))
    metal(slab, SLAB, 0.8, 0.1)
    rim = sb.torus("Rim", 3.2, 0.6, (0, 0, 0.3))
    sb.displace_noise(rim, 0.35, 0.6)
    sb.apply_modifiers(rim)
    metal(rim, STEEL_DARK, 0.75, 0.2)
    body = [slab, rim]
    for k in range(5):   # buckled floor plates lifted around the rim
        phi = k * 2 * math.pi / 5 + 0.5
        p = sb.box("Torn", (1.6, 1.1, 0.14), (math.cos(phi) * 3.45, math.sin(phi) * 3.45, 0.4), (0.55, 0, phi + math.pi / 2), bevel=0.03)
        metal(p, STEEL, 0.65, 0.2)
        body.append(p)
    body += [bolt("Bolt", (x, y, 0.05), r=0.16) for x in (-3.5, 3.5) for y in (-3.5, 3.5)]
    inner = sb.cylinder("Inner_Glow", 2.85, 0.1, (0, 0, -0.45), verts=32)
    glow(inner, NEST, 5)
    core = sb.cylinder("Core", 1.6, 0.1, (0, 0, -0.42), verts=24)
    glow(core, NEST_HOT, 8)
    glows = [inner, core]
    for k in range(8):   # glow leaking into cracks in the plating
        a = k * math.pi / 4
        if k % 2 == 0:
            c = sb.box("Crack", (0.6, 0.12, 0.03), rz((3.7, 0, 0.015), a), (0, 0, a), bevel=0)
        else:
            c = sb.box("Crack", (1.8, 0.12, 0.03), rz((4.4, 0, 0.015), a), (0, 0, a), bevel=0)
        glow(c, NEST, 3)
        glows.append(c)
    column = sb.cylinder("Column_Glow", 2.4, 7.9, (0, 0, 3.05), verts=24)
    glow(column, NEST, 2, alpha=0.25)
    roots = []
    tpts = [(0, 0, -0.4), (0.8, 0, 1.3), (1.9, 0.25, 2.3), (2.8, 0.5, 1.5), (3.5, 0.7, 0.35)]
    tradii = [0.55, 0.42, 0.3, 0.18, 0.06]
    for k in range(4):
        a = k * math.pi / 2 + 0.7
        pts = [rz(p, a) for p in tpts]
        loc = rz((1.6, 0, 0), a)
        t = solid_limb("Tendril%d" % k, pts, tradii, location=loc, joints=1.25, subdiv=2)
        zgrad(t, NEST_SHELL, PAL["chitin"], -0.5, 2.6)
        roots.append(t)
        w = [Vector(loc) + Vector(p) for p in pts]
        roots += sb.claws("Claw%d_" % k, w[4], (w[4] - w[3]).normalized(), count=2, length=0.4, radius=0.06, color=PAL["chitin2"])
        bpts = [rz(p, a) for p in ((0, 0, 0), (0.5, 0.9, -0.6), (0.9, 1.9, -2.0))]
        b = solid_limb("Branch%d" % k, bpts, [0.22, 0.14, 0.05], location=tuple(w[2]), joints=1.2, subdiv=1)
        zgrad(b, NEST_SHELL, PAL["chitin"], -0.5, 2.6)
        roots.append(b)
        out = Vector(rz((1, 0, 0), a))
        for i, f in enumerate((0.3, 0.5, 0.7)):
            pos, tan, r = along(w, tradii, f)
            d = (Vector((0, 0, 1)) + out * 0.5).normalized()
            th = sb.cone_dir("Thorn%d_%d" % (k, i), pos + d * (r * 0.5), d, 0.8, 0.15)
            sb.paint(th, PAL["bone"], roughness=0.35)
            roots.append(th)
        for i, f in enumerate((0.4, 0.6)):
            pos, tan, r = along(w, tradii, f)
            n = sb.sphere("Node%d_%d" % (k, i), 0.13, tuple(pos + Vector((0, 0, r * 0.8))), subdiv=2)
            glow(n, NEST, 4)
            glows.append(n)
    return {"Body": sb.join(body, "Body"), "Roots": sb.join(roots, "Roots"),
            "Inner_Glow": sb.join(glows, "Inner_Glow"), "Column_Glow": column}


def build_nest_root():
    """The Nest breaking through the platform: torn plating with a glowing crack, a big arched root with
    floor-hugging branches and claws, thorns, and glowing cracks / nodes along its back."""
    plate = sb.box("Torn", (3.6, 3.6, 0.3), (0, 0, 0.15), bevel=0.05)
    cut_cyl(plate, 1.5, 1.0, (0, 0, 0.15))
    metal(plate, STEEL_DARK, 0.7, 0.2)
    body = [plate]
    for k in range(4):   # peeled plates around the hole
        phi = k * math.pi / 2 + 0.4
        p = sb.box("Peel", (1.2, 0.9, 0.12), (math.cos(phi) * 1.75, math.sin(phi) * 1.75, 0.55), (0.5, 0, phi + math.pi / 2), bevel=0.03)
        metal(p, STEEL, 0.65, 0.2)
        body.append(p)
    rim = torus_lp("Rim", 1.55, 0.22, (0, 0, 0.3), maj=32, mn=10)
    sb.displace_noise(rim, 0.15, 0.9)
    sb.apply_modifiers(rim)
    metal(rim, STEEL_DARK, 0.75, 0.2)
    body.append(rim)
    pts = [(0, 0, 0.0), (1.0, 0.5, 1.2), (1.6, 2.4, 2.6), (3.0, 4.2, 3.0), (4.6, 5.6, 1.8)]
    radii = [1.0, 0.85, 0.6, 0.4, 0.12]
    root = solid_limb("Root", pts, radii, joints=1.15, subdiv=2)
    cut_box(root, (16, 16, 4), (2, 2, -2))       # flat underside: nothing below the floor
    zgrad(root, NEST_SHELL, PAL["chitin"], 0.0, 3.0)
    body.append(root)
    w = [Vector(p) for p in pts]
    bdefs = [(1, [(0, 0, 0), (-1.1, 0.8, -0.6), (-2.3, 1.5, -0.95)]),
             (2, [(0, 0, 0), (1.4, -0.4, -1.3), (2.7, -0.3, -2.3)]),
             (3, [(0, 0, 0), (-0.7, 1.3, -1.4), (-1.2, 2.6, -2.7)])]
    for k, (i, bp) in enumerate(bdefs):
        b = solid_limb("Branch%d" % k, bp, [0.42, 0.26, 0.06], location=tuple(w[i]), joints=1.2, subdiv=1)
        zgrad(b, NEST_SHELL, PAL["chitin"], 0.0, 3.0)
        body.append(b)
        end = w[i] + Vector(bp[2])
        body += sb.claws("Claw%d_" % k, end, (Vector(bp[2]) - Vector(bp[1])).normalized(), count=2, length=0.5, radius=0.07, color=PAL["chitin2"])
    for i in range(6):
        pos, tan, r = along(w, radii, 0.15 + i * 0.14)
        side = Vector((-tan.y, tan.x, 0)) * (0.4 if i % 2 else -0.4)
        d = (Vector((0, 0, 1)) + tan * 0.3 + side).normalized()
        th = sb.cone_dir("Thorn%d" % i, pos + d * (r * 0.5), d, 0.9, 0.18)
        sb.paint(th, PAL["bone"], roughness=0.35)
        body.append(th)
    glows = []
    for i in (1, 2, 3):   # glowing cracks around the joints
        tan = ((w[i] - w[i - 1]).normalized() + (w[i + 1] - w[i]).normalized()).normalized()
        ring = torus_lp("Crack%d" % i, radii[i] * 1.15 + 0.03, 0.08, tuple(w[i]), tan.to_track_quat("Z", "Y").to_euler(), 24, 8)
        glow(ring, NEST, 4)
        glows.append(ring)
    for i, f in enumerate((0.3, 0.55, 0.75)):
        pos, tan, r = along(w, radii, f)
        n = sb.sphere("Node%d" % i, 0.26, tuple(pos + Vector((0, 0, r * 0.85))), subdiv=2)
        glow(n, NEST, 4)
        glows.append(n)
    pos, tan, r = along(w, radii, 0.45)
    hot = sb.sphere("Hot", 0.3, tuple(pos + Vector((0, 0, r * 0.85))), subdiv=2)
    glow(hot, NEST_HOT, 7)
    glows.append(hot)
    crack = sb.cylinder("Crack_Glow", 1.45, 0.08, (0, 0, 0.06), verts=24)
    glow(crack, NEST, 3)
    glows.append(crack)
    for k in range(4):
        a = k * math.pi / 2 + math.pi / 4
        c = sb.box("Strip", (1.0, 0.12, 0.04), rz((2.05, 0, 0.32), a), (0, 0, a), bevel=0)
        glow(c, NEST, 3)
        glows.append(c)
    return {"Body": sb.join(body, "Body"), "Nodes_Glow": sb.join(glows, "Nodes_Glow")}


# ---------------------------------------------------------------- furniture
def build_railing():
    """Waist-high catwalk railing: thick posts on foot plates, kick plate with a hazard stripe, mesh panels, glow line on top."""
    body = []
    for i in range(4):
        x = -3.75 + i * 2.5
        p = sb.box("Post", (0.45, 0.45, 3.0), (x, 0, 1.5), bevel=0.04)
        metal(p, STEEL_LIGHT, 0.55)
        f = sb.box("Foot", (0.9, 0.9, 0.15), (x, 0, 0.075), bevel=0.03)
        metal(f, STEEL_DARK, 0.7)
        body += [p, f]
        if i in (0, 3):
            body.append(flat("Tip", (0.5, 0.5, 0.3), (x, 0, 3.15), PAINT, 0.7))
    top = sb.box("TopRail", (8, 0.32, 0.32), (0, 0, 2.95), bevel=0.04)
    metal(top, STEEL_LIGHT, 0.55)
    kick = sb.box("Kick", (8, 0.15, 0.7), (0, 0, 0.5), bevel=0.02)
    metal(kick, STEEL_DARK, 0.7)
    body += [top, kick]
    for sy in (-1, 1):
        body.append(flat("Stripe", (7.6, 0.05, 0.3), (0, sy * 0.1, 0.5), PAINT, 0.7))
    mesh = []
    for i in range(3):
        m = sb.box("Mesh", (2.2, 0.06, 1.3), (-2.5 + i * 2.5, 0, 1.6), bevel=0)
        sb.paint(m, STEEL_DARK, roughness=0.7, alpha=0.6)
        mesh.append(m)
    line = sb.box("Line_Glow", (7.0, 0.1, 0.14), (0, 0, 3.18), bevel=0)
    glow(line, GLOW, 4)
    return {"Body": sb.join(body, "Body"), "Mesh": sb.join(mesh, "Mesh"), "Line_Glow": line}


def build_lamp():
    """Double-headed work light: thick post on a base, hazard band, two big warm bulbs and a translucent light cone."""
    base = sb.cylinder("Base", 1.0, 0.35, (0, 0, 0.175), verts=16, bevel=0.04)
    metal(base, STEEL_DARK, 0.7)
    post = sb.cylinder("Post", 0.35, 7, (0, 0, 3.5), verts=12, bevel=0.04)
    metal(post, STEEL, 0.6)
    band = sb.cylinder("Band", 0.37, 0.4, (0, 0, 1.0), verts=12)
    sb.paint(band, PAINT, roughness=0.7)
    body = [base, post, band]
    status = sb.sphere("Status", 0.12, (0, -0.36, 2.2), subdiv=2)
    glow(status, GLOW, 4)
    glows = [status]
    for sy in (-1, 1):
        arm = sb.box("Arm", (0.35, 2.2, 0.35), (0, sy * 1.0, 6.95), bevel=0.03)
        metal(arm, STEEL_DARK, 0.6)
        head = sb.box("Head", (1.6, 2.0, 0.5), (0, sy * 1.9, 6.8), bevel=0.05)
        metal(head, STEEL_DARK, 0.6)
        cable = solid_limb("Cable", [(0, 0, 0), (0, sy * 0.55, -0.35), (0, sy * 1.1, -0.05)], [0.06, 0.06, 0.06], location=(0, sy * 0.2, 6.75), joints=1.0)
        sb.paint(cable, PAL["rubber"], roughness=0.8)
        body += [arm, head, cable]
        bulb = sb.box("Bulb_Glow", (1.3, 1.7, 0.12), (0, sy * 1.9, 6.52), bevel=0)
        glow(bulb, WARM, 6)
        glows.append(bulb)
    beam = sb.cylinder("Beam_Glow", 3.8, 6.0, (0, 0, 3.45), verts=20, r2=2.2)
    glow(beam, WARM, 0.7, alpha=0.1)
    return {"Body": sb.join(body, "Body"), "Bulb_Glow": sb.join(glows, "Bulb_Glow"), "Beam_Glow": beam}


BUILDERS = {
    "FloorTile": build_floor_tile, "FloorTileB": build_floor_tile_b, "FloorTileC": build_floor_tile_c,
    "FloorGrate": build_floor_grate, "Wall": build_wall, "Wall_Door": build_wall_door, "Pillar": build_pillar,
    "Crate": build_crate, "CrateB": build_crate_b, "Barrel": build_barrel, "Gate": build_gate, "SpawnHole": build_spawn_hole,
    "BossGate": build_boss_gate, "Railing": build_railing, "Lamp": build_lamp, "NestRoot": build_nest_root,
}


def build_all(names=None, render=True):
    names = names or list(BUILDERS.keys())
    for name in names:
        sb.reset()
        parts = BUILDERS[name]()
        objs = list(parts.values())
        entry = sb.export_model("arena/" + name, objs, {"kind": "arena"})
        print("%-10s parts=%d tris=%5d size=%s" % (name, len(objs), entry["tris"], entry["size_studs"]))
        if render:
            sb.render_model(name, objs, "arena/%s.png" % name, angle_deg=40, elev_deg=25)


def lineup():
    """One scene with the whole kit assembled as a corner of the arena, for a single 'what it looks like' render.
    The wall row (boss gate, gate in its Wall_Door, walls) is the backdrop at -Y with fronts turned to +Y, so the
    camera (at +X +Y) sees the front faces; the floor mixes the tile variants at random 90-degree turns like
    ArenaBuilder should."""
    sb.reset()
    objs = []
    rnd = random.Random(9)

    def place(name, at, rot_z=0):
        parts = BUILDERS[name]()
        for o in parts.values():
            o.location = (o.location.x + at[0], o.location.y + at[1], o.location.z + at[2])
            if rot_z:
                o.rotation_euler.z += rot_z
                # rotate location around the piece origin
                x, y = o.location.x - at[0], o.location.y - at[1]
                c, s = math.cos(rot_z), math.sin(rot_z)
                o.location.x = at[0] + x * c - y * s
                o.location.y = at[1] + x * s + y * c
            objs.append(o)

    specials = {(4, 8): "SpawnHole", (-12, -8): "SpawnHole", (-20, 0): "FloorGrate", (12, -8): "FloorGrate",
                (-4, 16): "FloorGrate", (20, 8): "FloorGrate"}
    for x in range(-20, 21, 8):
        for y in range(-16, 17, 8):
            name = specials.get((x, y))
            rot = rnd.choice((0, 1, 2, 3)) * math.pi / 2
            if name is None:
                if y == 16 or x in (-20, 20):
                    name = "FloorTileC" if rnd.random() < 0.6 else "FloorTile"
                    rot = {16: math.pi, -20: -math.pi / 2, 20: math.pi / 2}[y if y == 16 else x]   # edge light outward
                else:
                    name = "FloorTileB" if rnd.random() < 0.3 else "FloorTile"
            elif name == "SpawnHole":
                rot = 0
            place(name, (x, y, 0), rot)
    # back row, fronts turned to +Y
    place("BossGate", (16, -20.5, 0), math.pi)
    place("Wall", (4, -20.5, 0), math.pi)
    place("Wall_Door", (-6, -20.5, 0), math.pi)
    place("Gate", (-6, -20, 0), math.pi)
    place("Wall", (-16, -20.5, 0), math.pi)
    place("Pillar", (-22, -20, 0))
    place("Pillar", (-4, -4, 0))
    place("Pillar", (12, 4, 0))
    place("Crate", (-13, 5, 0), 0.15)
    place("CrateB", (-9, 6.5, 0), 0.5)
    place("Crate", (-13, 5, 4), 0.35)
    place("Barrel", (-6, 10.5, 0))
    place("Barrel", (-4, 12.6, 0), 1.0)
    place("NestRoot", (14, 12, 0), 1.2)
    place("NestRoot", (0, -14, 0), 2.2)
    place("Railing", (-12, 19.5, 0))
    place("Railing", (-4, 19.5, 0))
    place("Lamp", (20, 18, 0))
    place("Lamp", (-20, 18, 0))
    place("Lamp", (-10, -16, 0))
    sb.render_model("Arena", objs, "arena/Lineup.png", angle_deg=30, elev_deg=28, pad=0.75, samples=64, res=960, floor=True)


if __name__ == "__main__":
    args = sys.argv[1:]
    if args == ["lineup"]:
        lineup()
    else:
        names = [a for a in args if a in BUILDERS] or None
        build_all(names, render=os.environ.get("SB_NO_RENDER") != "1")
        if not names:
            lineup()
