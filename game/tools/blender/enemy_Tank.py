"""Tank: an armoured beetle, 5 studs tall, front = +Y. Glyph: the huge domed shell split in two green elytra
with a glowing seam between them (and a glow ring leaking out under the shell rim), a bone rhino horn on a big
head tucked under the pronotum, two front pincers, six short jointed legs with steel shin guards.
Recipe: see RECIPE.md. Run: python3 enemies2.py Tank"""
import math
import os
import sys

import bpy
from mathutils import Vector, Matrix

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sb
import sb2
from sb import rgb
from sb2 import top_light, belly, height, band, stripes, spots, region, near, facing
from enemies2 import BODY, SHELL, FLESH, BONE, STEEL, STEEL_DARK, ACCENT, masked, paint_body, paint_plate, paint_bone, claw_fan


# ---------------------------------------------------------------- helpers local to this file (do not edit sb2 / enemies2)
S = 1.10          # built at design size, scaled about the world origin at the end (feet stay on z = 0)


def scale_world(parts, s):
    """Uniform scale of every part about the WORLD origin."""
    M = Matrix.Scale(s, 4)
    for ob in parts.values():
        ob.matrix_world = M @ ob.matrix_world
        sb.apply_transforms(ob, location=True, rotation=True, scale=True)


def trim_far(ob, center, maxr):
    """Solidify's even offset throws a vertex to infinity on a sliver face; delete any vertex farther than
    `maxr` from `center` (world) so a plate can never leave the body. Returns the number removed."""
    if ob is None:
        return 0
    import bmesh
    mw = ob.matrix_world
    c = Vector(center)
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    far = [v for v in bm.verts if ((mw @ v.co) - c).length > maxr]
    n = len(far)
    if far:
        bmesh.ops.delete(bm, geom=far, context="VERTS")
        bm.to_mesh(ob.data)
        print("TANK trimmed", n, "far vertices from", ob.name)
    bm.free()
    bpy.context.view_layer.update()
    return n


def cap(body, keep, name, center, maxr, **kw):
    """cap_from with the far-vertex guard."""
    ob = sb2.cap_from(body, keep, name, **kw)
    if ob is not None:
        trim_far(ob, center, maxr)
        if not ob.data.polygons:
            bpy.data.objects.remove(ob, do_unlink=True)
            return None
    return ob


def surf(ob, origin, direction, sink=0.0):
    """Exact surface point and outward normal of a built mesh along a ray from `origin` (world coords)."""
    mw = ob.matrix_world
    mi = mw.inverted()
    o = mi @ Vector(origin)
    d = (mi.to_3x3() @ Vector(direction)).normalized()
    hit, loc, nrm, _ = ob.ray_cast(o, d)
    if not hit:
        hit, loc, nrm, _ = ob.ray_cast(o + d * 50.0, -d)
    if not hit:
        return Vector(origin), Vector(direction).normalized()
    p = mw @ loc
    n = (mw.to_3x3().inverted().transposed() @ nrm).normalized()
    return p - n * sink, n


def paint_elytron(ob, acc, sx):
    """A saturated green wing case: dark green base, mid green on the top faces (no white: the glow seam has to be
    the brightest thing on the dome), darker grooves running front to back, darker underside."""
    deep = sb2.darken(acc, 0.4)
    lit = sb2.darken(acc, 0.82)
    groove = sb2.darken(acc, 0.3)
    return sb2.paint_rules(ob, deep, [
        top_light(lit, 0.9, 0.85),
        masked(stripes(0, 0.55, 0.28, groove, phase=0.12, amount=0.85), lambda p, n, t: 1.0 if n.z > 0.3 else 0.0),
        belly(sb2.darken(acc, 0.25), 0.7),
    ], roughness=0.5)


def ribbon(name, frames, half_w, height, sink=0.12, top_w=0.7):
    """A closed strip of box cross-sections riding ON a surface: frames = [(p, n, side), ...] (world), each a
    surface point, its outward normal and the sideways axis. Sunk `sink` into the body, `height` proud of it.
    This is how the glow seam and the rim ring are built: real geometry that can never be buried by solidify."""
    import bmesh
    bm = bmesh.new()
    rings = []
    for p, n, side in frames:
        p, n, side = Vector(p), Vector(n).normalized(), Vector(side).normalized()
        lo = p - n * sink
        hi = p + n * height
        ring = [bm.verts.new(lo - side * half_w), bm.verts.new(lo + side * half_w),
                bm.verts.new(hi + side * half_w * top_w), bm.verts.new(hi - side * half_w * top_w)]
        rings.append(ring)
    for a, b in zip(rings, rings[1:]):
        for i in range(4):
            j = (i + 1) % 4
            bm.faces.new((a[i], a[j], b[j], b[i]))
    bm.faces.new(rings[0])
    bm.faces.new(list(reversed(rings[-1])))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    for f in me.polygons:
        f.use_smooth = False
    bpy.context.view_layer.update()
    return ob


# ---------------------------------------------------------------- the beetle: 5 studs tall, front = +Y
def build_tank():
    parts = {}
    acc = ACCENT["Tank"]
    shell = sb2.mix(SHELL, acc, 0.3)

    # --- torso: one fused dome (wide, a little longer than wide), flat under the belly
    spheres = [(0, -0.1, 2.75, 2.2), (0, 0.7, 2.35, 1.8), (0, -0.8, 2.45, 1.8), (-1.0, 0, 2.3, 1.5), (1.0, 0, 2.3, 1.5), (0, 0, 1.7, 1.6)]
    torso = sb.blob("Torso", spheres, resolution=0.14)
    for v in torso.data.vertices:
        if v.co.z < 1.15:
            v.co.z = 1.15 + (v.co.z - 1.15) * 0.15
    bpy.context.view_layer.update()
    lo, hi = sb.bounds([torso])
    print("TANK torso bounds", tuple(round(v, 2) for v in lo), tuple(round(v, 2) for v in hi))
    ely_z = 2.35                                        # the elytra skirt ends here
    front_y = hi.y
    pron_y = front_y - 0.5                             # pronotum (front steel collar) starts here
    # every plate is cut from the dense metaball mesh BEFORE the dome is faceted: clean straight edges, and thin
    # strips do not turn into slivers (a sliver from a decimated mesh explodes in solidify)
    gap = 0.26                                         # half width of the split between the elytra
    # the glyph: a fat glowing ridge down the middle of the dome, ray-cast onto the dome so it rides the surface,
    # and a glow ring around the skirt where the elytra end. Real geometry, not caps (caps sink in the trench).
    frames = []
    y0 = lo.y + 0.12
    n_s = 12
    for i in range(n_s):
        y = y0 + (pron_y - 0.05 - y0) * i / (n_s - 1)
        p, n = surf(torso, (0, y, 6.0), (0, 0, -1))
        frames.append((p, n, (1, 0, 0)))
    seam = ribbon("Seam", frames, gap * 1.15, 0.66, sink=0.25, top_w=0.45)      # taller than the elytra edges: a ridge, not a trench
    # thin strips: AO in the trench scales the colour by ~0.65, so emission sits high (still a small glow mass)
    sb2.flat_color(seam, sb2.lighten(acc, 0.05), emission=2.4)
    frames = []
    for i in range(28):
        a = 2 * math.pi * i / 28
        d = (math.sin(a), math.cos(a), 0)
        p, n = surf(torso, (0, 0, ely_z - 0.45), d)
        frames.append((p, (n.x, n.y, 0), (0, 0, 1)))
    frames.append(frames[0])
    ring = ribbon("Ring", frames, 0.16, 0.34, sink=0.18, top_w=0.6)
    sb2.flat_color(ring, sb2.lighten(acc, 0.05), emission=2.0)
    for g in (seam, ring):
        l2, h2 = sb.bounds([g])
        print("TANK glow", g.name, tuple(round(v, 2) for v in l2), tuple(round(v, 2) for v in h2))
    glow = [seam, ring]
    # two elytra halves: everything above the skirt line behind the pronotum, the gap down the middle
    elytra = []
    for i, sx in enumerate((-1, 1)):
        e = cap(torso, lambda c, n, sx=sx: n.z > -0.1 and c.z > ely_z and c.y < pron_y and c.x * sx > gap, "Elytron%d" % i, (0, 0, 2.5), 3.2,
                         thickness=0.34, grow=0.05, bevel=0.04, tris=240)
        if e is not None:
            paint_elytron(e, acc, sx)
            elytra.append(e)
    # pronotum: a steel collar on the front slope of the dome only (front-facing faces), over the head
    pron = cap(torso, lambda c, n: n.z > -0.1 and c.z > ely_z - 0.1 and pron_y <= c.y, "Pronotum", (0, 0, 2.5), 3.2, thickness=0.24, grow=0.04, bevel=0.04, tris=160)
    if pron is not None:
        paint_plate(pron, STEEL_DARK)
    sb2.facet(torso, 800)
    paint_body(torso, acc, shell)
    parts["Torso"] = sb.join([torso] + elytra + ([pron] if pron is not None else []), "Torso")
    parts["Seam_Glow"] = sb.join(glow, "Seam_Glow")

    # --- head: big (about a third of the body), pushed forward under the pronotum lip; brow plate, rhino horn, pincers, eyes
    hc = Vector((0, front_y + 0.25, 1.55))
    hr = (1.3, 1.15, 0.95)
    head = sb2.lowpoly_sphere("Head", 1.0, hc, scale=hr, subdiv=3)
    sb2.facet(head, 400)
    brow = cap(head, lambda c, n: n.z > 0.25 and n.y > -0.3 and c.z > hc.z + 0.25, "Brow", hc, 2.2, thickness=0.22, grow=0.03, tris=160)
    paint_body(head, acc, shell, extra=[masked(band(2, hc.z - 0.05, 0.4, acc, soft=0.3, amount=0.85), lambda p, n, t: 1.0 if n.y > 0.15 else 0.0)])
    if brow is not None:
        paint_plate(brow, STEEL)
    bits = [head] + ([brow] if brow is not None else [])
    # the rhino horn: one big bone blade out of the brow, sweeping up and back
    hp, hn = sb.on_ellipsoid(hc, hr, (0, 0.55, 1.0))
    horn = sb2.horn("Horn", hp - hn * 0.25, (0, 0.5, 1.0), 2.1, 0.36, sides=5, curve=0.5)
    paint_bone(horn)
    bits.append(horn)
    # pincers: two thick bone blades from the cheeks, forward and curling inward
    for sx in (-1, 1):
        p, n = sb.on_ellipsoid(hc, hr, (sx * 0.8, 0.75, -0.35))
        pin = sb2.horn("Pincer%d" % (sx + 1), p - n * 0.2, (sx * 0.45, 1.0, -0.12), 1.6, 0.24, sides=5, curve=0.0)
        tipd = Vector((sx * 0.45, 1.0, -0.12)).normalized()
        tp = p - n * 0.2 + tipd * 1.1
        hook = sb2.horn("Hook%d" % (sx + 1), tp, (-sx * 0.9, 0.8, 0.05), 0.9, 0.17, sides=4, curve=0.0)
        paint_bone(pin)
        paint_bone(hook)
        bits += [pin, hook]
    whites, irises = [], []
    for sx in (-1, 1):
        p, n = sb.on_ellipsoid(hc, hr, (sx * 0.62, 0.9, 0.2))
        ps = sb2.eye("Eye", p - n * 0.12, n, 0.36, acc, glow=3.0)
        whites += [ps[0], ps[2]]
        irises.append(ps[1])
    parts["Head"] = sb.join(bits + whites, "Head")
    parts["Eyes_Glow"] = sb.join(irises, "Eyes_Glow")

    # --- six legs: short, thick, knee above the shell rim, steel shin guard, two bone claws
    n_leg = 1
    for y in (1.0, -0.1, -1.2):
        for sx in (-1, 1):
            root = Vector((1.35 * sx, y, 1.5))
            pts = [(0, 0, 0), (0.95 * sx, 0.1, 0.55), (1.45 * sx, 0.2, -0.6), (1.4 * sx, 0.45, -1.32)]
            name = "Leg_%d" % n_leg
            leg = sb2.seg_limb(name, pts, [0.42, 0.36, 0.3, 0.2], location=root, sides=7, joint=1.3, fuse=0.12)
            sb2.facet(leg, 240)
            knee = root + Vector(pts[1])
            guard = cap(leg, lambda c, n, sx=sx, knee=knee: n.x * sx > 0.45 and 0.3 < c.z < knee.z - 0.45 and c.x * sx > knee.x * sx + 0.1,
                        "Guard%d" % n_leg, knee, 2.5, thickness=0.17, grow=0.03, tris=90)
            paint_body(leg, acc, shell, extra=[masked(band(2, knee.z, 0.3, acc, soft=0.25, amount=0.95), lambda p, n, t: 1.0 if n.z > -0.2 else 0.0)])
            if guard is not None:
                paint_plate(guard, STEEL)
            foot = Vector(leg["tip"])
            claws = claw_fan("Claw%d" % n_leg, (foot.x, foot.y + 0.1, foot.z - 0.02), (0.25 * sx, 0.8, -0.5), 2, 0.5, 0.1, 0.22, curve=0.25)
            parts[name] = sb.join([leg] + ([guard] if guard is not None else []) + claws, name)
            n_leg += 1

    # feet exactly on the floor
    lo, hi = sb.bounds(list(parts.values()))
    for ob in parts.values():
        ob.location.z -= lo.z
        sb.apply_transforms(ob, location=True)
    scale_world(parts, S)
    lo, hi = sb.bounds(list(parts.values()))
    for k, o in parts.items():
        print("TANK part", k, sb.tri_count(o))
    print("TANK bounds", tuple(round(v, 2) for v in lo), tuple(round(v, 2) for v in hi))
    return parts


def build():
    return build_tank()


# attack pose: head rears up to gore, the two front legs lift off the floor
def _p(x, y, z):
    return (x * S, y * S, z * S)


POSE = {
    "Head": (_p(0, 2.3, 1.7), (14, 0, 0)),
    "Eyes_Glow": (_p(0, 2.3, 1.7), (14, 0, 0)),
    "Leg_1": (_p(-1.35, 1.0, 1.5), (0, 24, -10)),
    "Leg_2": (_p(1.35, 1.0, 1.5), (0, -24, 10)),
}
VIEW = (40, 30)
