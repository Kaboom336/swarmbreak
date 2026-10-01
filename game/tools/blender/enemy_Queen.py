"""Queen: the wave-10 boss, a walking nest about 14 studs long. Glyph: the enormous egg-sac abdomen with glowing
green eggs sunk into chitin sockets. Crowned head with huge inward-hooked mandibles and six eyes, a ribbed thorax
with plates cut from its own shell, six long knee-jointed legs with knee caps and claws, an ovipositor spike.
Recipe: see RECIPE.md. Run: python3 enemies2.py Queen"""
import math
import os
import sys

import bpy
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sb
import sb2
from sb import rgb
from sb2 import top_light, belly, band, near, facing
from enemies2 import BODY, SHELL, FLESH, BONE, STEEL, STEEL_DARK, ACCENT, masked, paint_body, paint_plate, paint_bone, claw_fan

MB = 1.75          # metaball element radius / visible surface radius (threshold 0.6, stiffness 2)


# ---------------------------------------------------------------- helpers local to this file
def on_mesh(ob, origin, direction, fallback=None):
    """Surface point and outward normal of `ob` hit by a ray from `origin` along `direction` (object at identity)."""
    d = Vector(direction).normalized()
    ok, loc, nrm, idx = ob.ray_cast(Vector(origin), d)
    if ok:
        n = Vector(nrm).normalized()
        if n.dot(d) < 0:
            n = -n
        return Vector(loc), n
    if fallback is not None:
        return fallback
    return Vector(origin) + d, d


def lp_torus(name, major, minor, center, normal, maj_seg=10, min_seg=5):
    """A low-poly ring (socket rim) lying on the plane with the given normal."""
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor, major_segments=maj_seg, minor_segments=min_seg)
    ob = bpy.context.active_object
    ob.name = name
    ob.rotation_euler = Vector(normal).normalized().to_track_quat("Z", "Y").to_euler()
    ob.location = center
    sb.apply_transforms(ob)
    sb2.shade_flat(ob)
    return ob


def prune_far(ob, center, radius):
    """Delete vertices farther than `radius` from `center` (an even-offset solidify on a thin band can shoot a
    sliver off to infinity; this clips such spikes before the part is joined)."""
    if ob is None:
        return None
    import bmesh
    c = Vector(center)
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    bad = [v for v in bm.verts if ((ob.matrix_world @ v.co) - c).length > radius]
    if bad:
        bmesh.ops.delete(bm, geom=bad, context="VERTS")
        bm.to_mesh(ob.data)
    bm.free()
    ob.data.validate(verbose=False)
    return ob


def small_eye(name, center, direction, radius, iris_color, glow=2.4, white=True):
    """Like sb2.eye but with an 80-tri white ball so six eyes stay in budget. Returns [white?, iris_Glow, pupil]."""
    d = Vector(direction).normalized()
    out = []
    if white:
        ball = sb2.lowpoly_sphere(name + "_White", radius, center, subdiv=2, flat=True)
        sb2.flat_color(ball, (0.93, 0.93, 0.9, 1), roughness=0.25)
        out.append(ball)
    iris = sb.cylinder(name + "_Glow", radius * 0.64, radius * 0.26, Vector(center) + d * (radius * 0.84), verts=10, smooth=False)
    iris.rotation_euler = d.to_track_quat("Z", "Y").to_euler()
    sb.apply_transforms(iris)
    sb2.flat_color(iris, iris_color, emission=glow)
    out.append(iris)
    pu = sb.cylinder(name + "_Pupil", radius * 0.28, radius * 0.12, Vector(center) + d * (radius * 1.02), verts=8, smooth=False)
    pu.rotation_euler = d.to_track_quat("Z", "Y").to_euler()
    sb.apply_transforms(pu)
    sb2.flat_color(pu, (0.02, 0.02, 0.03, 1), roughness=0.2)
    out.append(pu)
    return out


def paint_accent_plate(ob, acc):
    """Saturated green chitin plate (non-glow): dark rim, lit from above."""
    return sb2.paint_rules(ob, sb2.darken(acc, 0.5), [top_light(acc, 0.7, 1.0), belly(sb2.darken(acc, 0.35), 0.6)], roughness=0.5)


# ---------------------------------------------------------------- the queen
def build_queen():
    parts = {}
    acc = ACCENT["Queen"]
    shell = sb2.mix(SHELL, acc, 0.35)
    deep = sb2.mix(acc, rgb(255, 230, 120), 0.25)             # warm core of the eggs

    # --- thorax: one fused blob with a shoulder hump; rib plates and a collar cut from its own surface
    tc = Vector((0, 0.8, 4.0))
    spheres = [(0, 0.8, 4.0, 1.55 * MB), (0, 1.6, 4.15, 1.2 * MB), (0, -0.1, 3.9, 1.3 * MB), (0, 0.5, 4.8, 0.9 * MB),
               (-1.1, 0.6, 3.6, 0.8 * MB), (1.1, 0.6, 3.6, 0.8 * MB)]
    thorax = sb.blob("Torso", spheres, resolution=0.13)
    ribs = []
    for i, yc in enumerate((1.45, 0.75, 0.05)):
        ribs.append(prune_far(sb2.cap_from(thorax, lambda c, n, yc=yc: abs(c.y - yc) < 0.2 and n.z > -0.1 and c.z > tc.z - 0.3, "Rib%d" % i, thickness=0.26, grow=0.02, tris=100), tc, 3.5))
    collar = sb2.cap_from(thorax, lambda c, n: n.y > 0.45 and n.z > -0.3 and c.z > tc.z - 0.6 and c.y > tc.y + 0.9, "Collar", thickness=0.3, grow=0.03, tris=140)
    sb2.facet(thorax, 430)
    paint_body(thorax, acc, shell)
    for r in ribs:
        if r is not None:
            paint_accent_plate(r, acc)
    paint_plate(collar, STEEL)
    tbits = [thorax, collar] + [r for r in ribs if r is not None]
    for sx in (-1, 1):   # two shoulder horns leaning back
        p, n = on_mesh(thorax, tc, (sx * 0.8, -0.3, 0.9))
        h = sb2.horn("Shoulder%d" % (sx + 1), p - n * 0.15, (sx * 0.6, -0.7, 0.8), 1.3, 0.24, sides=5, curve=0.3)
        paint_bone(h)
        tbits.append(h)
    parts["Torso"] = sb.join(tbits, "Torso")

    # --- abdomen: the glyph. A huge sac, girdle rings cut from its shell, eggs sunk into socket rims, a tail spike
    ac = Vector((0, -4.0, 4.7))
    asph = [(0, -2.1, 4.2, 2.0 * MB), (0, -3.7, 4.65, 2.7 * MB), (0, -5.4, 4.85, 2.45 * MB), (0, -6.8, 4.75, 1.55 * MB), (0, -7.6, 4.5, 0.8 * MB)]
    abd = sb.blob("Abdomen", asph, resolution=0.15)
    girdles = []
    for i, yc in enumerate((-2.9, -4.65, -6.3)):
        girdles.append(prune_far(sb2.cap_from(abd, lambda c, n, yc=yc: abs(c.y - yc) < 0.22 and n.z > -0.55, "Girdle%d" % i, thickness=0.3, grow=0.02, tris=110), ac, 4.5))
    # egg layout: (segment centre y, egg radius, [angles around the Y axis; 90 = top, 0 = right flank])
    layout = [(-2.2, 0.55, (40, 140)), (-3.8, 0.95, (12, 62, 118, 168)), (-5.5, 0.78, (25, 90, 155)), (-7.0, 0.5, (55, 125))]
    eggs, sockets = [], []
    k = 0
    for yc, er, angles in layout:
        for a in angles:
            ra = math.radians(a)
            d = Vector((math.cos(ra), 0.0, math.sin(ra)))
            p, n = on_mesh(abd, Vector((0, yc, ac.z + 0.1)), d)
            egg = sb2.lowpoly_sphere("Egg%d" % k, er, p - n * (er * 0.42), subdiv=2)
            sb2.paint_rules(egg, sb2.darken(acc, 0.8), [facing(n, deep, 1.0, 1.6), near(p + n * er * 0.35, er * 0.5, sb2.lighten(deep, 0.2), soft=0.6, amount=0.7)],
                            roughness=0.3, emission=1.2)
            eggs.append(egg)
            sockets.append(lp_torus("Socket%d" % k, er * 0.95, 0.14 + er * 0.1, p + n * 0.04, n, maj_seg=8, min_seg=4))
            k += 1
    sb2.facet(abd, 760)
    paint_body(abd, acc, sb2.darken(sb2.mix(SHELL, acc, 0.2), 0.85), extra=[masked(band(1, yc, 0.7, acc, soft=0.35, amount=0.9), lambda p, n, t: 1.0 if n.z > -0.15 else 0.0)
                                        for yc in (-3.8, -5.5, -7.0)])
    for g in girdles:
        if g is not None:
            paint_plate(g, STEEL_DARK)
    for s in sockets:
        paint_plate(s, STEEL_DARK)
    tail = sb2.horn("Tail", (0, -7.9, 4.3), (0, -1.0, -0.45), 1.7, 0.32, sides=6, curve=0.2)
    paint_bone(tail)
    parts["Abdomen"] = sb.join([abd, tail] + [g for g in girdles if g is not None] + sockets, "Abdomen")
    parts["Eggs_Glow"] = sb.join(eggs, "Eggs_Glow")

    # --- head: big and forward; crown plate cut from the top with a ring of bone spikes; brow; six eyes; mandibles
    hc = Vector((0, 3.25, 4.3))
    hr = (1.65, 1.45, 1.35)
    head = sb2.lowpoly_sphere("Head", 1.0, hc, scale=hr, subdiv=3)
    crown = sb2.cap_from(head, lambda c, n: n.z > 0.5 and c.z > hc.z + 0.75, "Crown", thickness=0.3, grow=0.03, tris=110)
    brow = sb2.cap_from(head, lambda c, n: n.y > 0.35 and n.z > -0.1 and hc.z + 0.15 < c.z < hc.z + 0.85 and abs(c.x) < 1.3, "Brow", thickness=0.22, grow=0.02, tris=100)
    prune_far(crown, hc, 3.0)
    prune_far(brow, hc, 3.0)
    sb2.facet(head, 340)
    paint_body(head, acc, shell)
    paint_plate(crown, STEEL)
    paint_plate(brow, STEEL_DARK)
    hbits = [head, crown, brow]
    for i in range(7):   # crown spikes: a ring on top, the middle ones tallest
        a = math.radians(-150 + i * 50)
        d = Vector((math.cos(a) * 0.9, math.sin(a) * 0.7, 1.0))
        p, n = sb.on_ellipsoid(hc, hr, d)
        L = 1.5 + 1.0 * (1.0 - abs(i - 3) / 3.0)
        s = sb2.horn("Crown%d" % i, p + n * 0.05, (d.x * 0.5, d.y * 0.5, 1.0), L, 0.27, sides=4, curve=0.0)
        paint_bone(s)
        hbits.append(s)
    irises = []
    for sx in (-1, 1):   # two big eyes forward, two small on the brow sides, two tiny near the crown
        p, n = sb.on_ellipsoid(hc, hr, (sx * 0.55, 1.0, 0.15))
        ps = small_eye("EyeA%d" % (sx + 1), p - n * 0.14, n, 0.5, acc, glow=2.6)
        hbits += [ps[0], ps[2]]
        irises.append(ps[1])
        p, n = sb.on_ellipsoid(hc, hr, (sx * 1.0, 0.75, 0.45))
        ps = small_eye("EyeB%d" % (sx + 1), p - n * 0.08, n, 0.26, acc, glow=2.6, white=False)
        hbits.append(ps[1])
        irises.append(ps[0])
        p, n = sb.on_ellipsoid(hc, hr, (sx * 0.35, 0.95, 0.6))
        ps = small_eye("EyeC%d" % (sx + 1), p - n * 0.06, n, 0.2, acc, glow=2.6, white=False)
        hbits.append(ps[1])
        irises.append(ps[0])
    for sx in (-1, 1):   # mandibles: thick at the root, hooking inward and a little down past the front
        p, n = sb.on_ellipsoid(hc, hr, (sx * 0.75, 0.8, -0.5))
        pts = [(0, 0, 0), (sx * 0.25, 1.05, -0.2), (-sx * 0.35, 2.0, -0.2), (-sx * 1.15, 2.55, 0.05)]
        m = sb2.seg_limb("Mand%d" % (sx + 1), pts, [0.38, 0.32, 0.22, 0.05], location=p - n * 0.2, sides=6, joint=1.0, fuse=0.09)
        sb2.facet(m, 110)
        paint_bone(m)
        hbits.append(m)
    parts["Head"] = sb.join(hbits, "Head")
    parts["Eyes_Glow"] = sb.join(irises, "Eyes_Glow")

    # --- six legs: long, knee high above the back, knee cap cut from the leg, two claws planted on the floor
    specs = [((1.7, 0.9, 1.9), (3.3, 1.7, 0.4), (3.6, 2.3, -3.25)),
             ((1.9, 0.1, 2.1), (3.6, 0.2, 0.5), (3.9, 0.3, -3.25)),
             ((1.7, -1.0, 1.9), (3.3, -2.0, 0.3), (3.5, -2.7, -3.25))]
    n = 1
    for row, y in enumerate((1.5, 0.6, -0.35)):
        for sx in (-1, 1):
            root = Vector((1.45 * sx, y, 3.8))
            a, b, c = specs[row]
            pts = [(0, 0, 0), (a[0] * sx, a[1], a[2]), (b[0] * sx, b[1], b[2]), (c[0] * sx, c[1], c[2])]
            leg = sb2.seg_limb("Leg_%d" % n, pts, [0.72, 0.58, 0.5, 0.24], location=root, sides=7, joint=1.25, fuse=0.13)
            sb2.facet(leg, 220)
            kz = root.z + a[2]
            knee = sb2.cap_from(leg, lambda cc, nn, kz=kz: nn.z > 0.35 and cc.z > kz - 0.35, "Knee%d" % n, thickness=0.2, grow=0.02, tris=70)
            paint_body(leg, acc, shell, extra=[masked(band(2, root.z + a[2] * 0.5, 0.45, acc, soft=0.3, amount=0.85), lambda p, nn, t: 1.0 if nn.z > -0.3 else 0.0)])
            if knee is not None:
                prune_far(knee, root + Vector((a[0] * sx, a[1], a[2])), 2.5)
                paint_plate(knee, STEEL_DARK)
            t = Vector(leg["tip"])
            cl = claw_fan("Claw%d" % n, (t.x, t.y, t.z - 0.05), (0.15 * sx, 0.35, -1.0), 2, 0.5, 0.12, 0.22, curve=0.0)
            parts["Leg_%d" % n] = sb.join([leg] + ([knee] if knee is not None else []) + cl, "Leg_%d" % n)
            n += 1
    return parts


def build():
    return build_queen()


# attack pose: front-right leg raised to strike, head tipped up at the player
POSE = {
    "Leg_2": ((1.45, 1.5, 3.8), (0, -38, 12)),
    "Leg_1": ((-1.45, 1.5, 3.8), (0, 12, -18)),
    "Head": ((0, 2.1, 4.1), (-12, 0, 0)),
    "Eyes_Glow": ((0, 2.1, 4.1), (-12, 0, 0)),
}
VIEW = (50, 20)
