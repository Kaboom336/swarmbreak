"""Flyer: a wasp-lantern that hovers at z 4-6 and dives. Glyph: the fat glowing lantern abdomen with a stinger.
Big horned head with huge faceted compound eyes and a yellow face, a real waist, dark ribbed lantern, four
translucent wings with dark veins, four short clawed legs tucked under the thorax.
Recipe: see RECIPE.md. Run: python3 enemies2.py Flyer"""
import math
import os
import sys

import bpy
import bmesh
from mathutils import Vector, Matrix

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sb
import sb2
from sb import rgb
from sb2 import top_light, belly, band, near, facing
from enemies2 import BODY, SHELL, FLESH, BONE, STEEL, STEEL_DARK, ACCENT, masked, paint_body, paint_plate, paint_bone, claw_fan, scale_parts

# The model is designed in "design units" around Z0 and scaled by S at the end: hover centre lands at z = 5.0.
S = 0.9
Z0 = 5.0 / S
MB = 1.75          # metaball element radius / visible surface radius (threshold 0.6, stiffness 2)


# ---------------------------------------------------------------- helpers local to this file
def scale_all(parts, s):
    """Scale every part about the WORLD origin (scale_parts scales about each object's own origin)."""
    for ob in parts.values():
        ob.matrix_world = Matrix.Scale(s, 4) @ ob.matrix_world
        sb.apply_transforms(ob, location=True, rotation=True, scale=True)
    return parts


def paint_accent_plate(ob, acc):
    """A saturated yellow chitin plate (non-glow): darker rim, lit from above, bright toward the player."""
    return sb2.paint_rules(ob, sb2.darken(acc, 0.55), [top_light(acc, 0.7, 1.0), facing((0, 1, 0), sb2.lighten(acc, 0.12), 0.8, 1.5),
                                                        belly(sb2.darken(acc, 0.4), 0.6)], roughness=0.5)


def wing_membrane(name, length, width, matrix, thickness=0.05):
    """A wasp wing outline in the local XY plane (root at the origin, tip at +X, leading edge at +Y),
    solidified, placed with `matrix` (4x4 world)."""
    L, W = length, width
    pts = [(0, -0.18 * W), (0.22 * L, -0.42 * W), (0.55 * L, -0.5 * W), (0.82 * L, -0.4 * W), (1.0 * L, -0.08 * W),
           (0.97 * L, 0.18 * W), (0.8 * L, 0.4 * W), (0.5 * L, 0.5 * W), (0.18 * L, 0.36 * W), (0, 0.16 * W)]
    me = bpy.data.meshes.new(name)
    bm = bmesh.new()
    vs = [bm.verts.new((x, y, 0.0)) for x, y in pts]
    bm.faces.new(vs)
    bmesh.ops.triangulate(bm, faces=bm.faces[:])
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    sb._link(ob)
    ob.matrix_world = matrix
    sb.apply_transforms(ob)
    m = ob.modifiers.new("Solid", "SOLIDIFY")
    m.thickness = thickness
    m.offset = 0.0
    sb.apply_modifiers(ob)
    sb2.shade_flat(ob)
    return ob


def wing_frame(root, sx, sweep_deg, tilt_deg):
    """World matrix for a wing on side sx (-1 left, +1 right): X out along the wing, Y toward the leading edge."""
    sw, ti = math.radians(sweep_deg), math.radians(tilt_deg)
    d = Vector((sx * math.cos(sw) * math.cos(ti), -math.sin(sw) * math.cos(ti), math.sin(ti))).normalized()
    e = Vector((-d.y, d.x, 0.0)).normalized() * sx          # in-plane, pointing forward (+Y-ish) on both sides
    e = (e - d * e.dot(d)).normalized()
    f = d.cross(e).normalized()
    M = Matrix.Identity(4)
    for i in range(3):
        M[i][0], M[i][1], M[i][2] = d[i], e[i], f[i]
    return Matrix.Translation(Vector(root)) @ M


def build_wing(name, root, sx, sweep_deg, tilt_deg, length, width, membrane, vein_col, vein_top):
    M = wing_frame(root, sx, sweep_deg, tilt_deg)
    w = wing_membrane(name + "_M", length, width, M)
    sb2.flat_color(w, membrane, roughness=0.2, alpha=0.5)
    L, W = length, width
    veins = []
    # leading-edge vein (thick at the root) and one mid vein: dark, opaque, so the wing keeps a silhouette when see-through
    for i, (a, b, r0, r1) in enumerate((((0, -0.12 * W, 0), (0.86 * L, -0.36 * W, 0), 0.075, 0.03),
                                        ((0, 0.06 * W, 0), (0.78 * L, 0.34 * W, 0), 0.055, 0.025))):
        pa, pb = M @ Vector(a), M @ Vector(b)
        v = sb2.seg_limb("%s_v%d" % (name, i), [(0, 0, 0), tuple(pb - pa)], [r0, r1], location=pa, sides=5, joint=1.0)
        sb2.paint_rules(v, vein_col, [top_light(vein_top, 0.8, 1.0)], roughness=0.5)
        veins.append(v)
    ob = sb.join([w] + veins, name)
    ob["alpha"] = 0.5
    return ob


# ---------------------------------------------------------------- the wasp
def build_flyer():
    parts = {}
    acc = ACCENT["Flyer"]
    shell = sb2.mix(SHELL, acc, 0.3)
    amber = sb2.mix(BODY, acc, 0.22)                          # dark amber for wing veins / antennae
    z = Z0

    # --- thorax: one fused blob with a hump for the wing roots and a thin waist stalk reaching into the lantern
    spheres = [(0, 0.12, z, 0.46 * MB), (0, 0.0, z + 0.2, 0.34 * MB), (0, 0.32, z - 0.18, 0.32 * MB),
               (0, -0.22, z - 0.05, 0.3 * MB), (0, -0.48, z - 0.02, 0.12 * MB), (0, -0.72, z - 0.03, 0.1 * MB), (0, -0.92, z - 0.04, 0.11 * MB)]
    thorax = sb.blob("Torso", spheres, resolution=0.07)
    saddle = sb2.cap_from(thorax, lambda c, n: n.z > 0.3 and -0.28 < c.y < 0.42 and abs(c.x) < 0.4 and c.z > z + 0.12, "Saddle", thickness=0.14, grow=0.02, tris=110)
    sb2.facet(thorax, 450)
    paint_body(thorax, acc, shell)
    paint_accent_plate(saddle, acc)
    torso_bits = [thorax, saddle]

    # --- lantern abdomen (Core_Glow): a fat teardrop, ribs and a dark tip cut from its own surface (into Torso)
    core = sb.blob("Core_Glow", [(0, -1.28, z - 0.05, 0.66 * MB), (0, -1.66, z - 0.1, 0.62 * MB), (0, -2.06, z - 0.2, 0.42 * MB)], resolution=0.06)
    ribs = []
    ribs.append(sb2.cap_from(core, lambda c, n: c.y > -0.9 and n.y > -0.2, "Collar", thickness=0.11, grow=0.015, bevel=0.0, tris=100))
    for i, yc in enumerate((-1.38, -1.92)):
        ribs.append(sb2.cap_from(core, lambda c, n, yc=yc: abs(c.y - yc) < 0.085, "Rib%d" % i, thickness=0.1, grow=0.015, bevel=0.0, tris=100))
    ribs.append(sb2.cap_from(core, lambda c, n: n.y < -0.62 and c.y < -2.18, "Tip", thickness=0.12, grow=0.015, bevel=0.0, tris=100))
    sb2.facet(core, 460)
    hot = sb2.lighten(acc, 0.35)
    deep = sb2.mix(acc, rgb(255, 130, 30), 0.3)
    sb2.paint_rules(core, acc, [near((0, -1.45, z - 0.06), 0.75, hot, soft=0.7, amount=1.0), belly(deep, 0.5)], roughness=0.35, emission=2.0)
    for r in ribs:
        if r is not None:
            paint_body(r, acc, sb2.mix(SHELL, acc, 0.15))
    torso_bits += [r for r in ribs if r is not None]
    # stinger: bone, out of the dark tip, hooked a little
    st = sb2.horn("Stinger", (0, -2.34, z - 0.34), (0, -0.8, -1.0), 0.9, 0.15, sides=6, curve=0.2)
    paint_bone(st)
    torso_bits.append(st)

    # --- legs: four short thick legs tucked under the thorax, two bone claws each
    for i, (sx, y, fwd) in enumerate(((-1, 0.3, 1), (1, 0.3, 1), (-1, -0.08, -1), (1, -0.08, -1))):
        root = Vector((0.3 * sx, y, z - 0.26))
        if fwd > 0:
            pts = [(0, 0, 0), (0.3 * sx, 0.2, -0.32), (0.22 * sx, 0.5, -0.6), (0.12 * sx, 0.72, -0.74)]
        else:
            pts = [(0, 0, 0), (0.32 * sx, -0.15, -0.3), (0.22 * sx, -0.42, -0.58), (0.1 * sx, -0.62, -0.7)]
        leg = sb2.seg_limb("Lg%d" % i, pts, [0.16, 0.12, 0.12, 0.07], location=root, sides=7, joint=1.3, fuse=0.06)
        sb2.facet(leg, 95)
        paint_body(leg, acc, shell)
        t = Vector(leg["tip"])
        cl = claw_fan("LgClaw%d" % i, (t.x, t.y + 0.04 * fwd, t.z - 0.02), (0.05 * sx, 0.45 * fwd, -1), 2, 0.24, 0.05, 0.1, curve=0.0)
        torso_bits += [leg] + cl
    parts["Torso"] = sb.join(torso_bits, "Torso")
    parts["Core_Glow"] = core

    # --- head: big, forward; brow plate; yellow face plate; two curved mandibles; two antennae; huge compound eyes
    hc = Vector((0, 0.9, z + 0.06))
    hr = (0.6, 0.53, 0.5)
    head = sb2.lowpoly_sphere("Head", 1.0, hc, scale=hr, subdiv=3)
    sb2.facet(head, 360)
    brow = sb2.cap_from(head, lambda c, n: n.z > 0.3 and n.y > -0.25 and c.z > hc.z + 0.1, "Brow", thickness=0.13, grow=0.02, tris=140)
    face = sb2.cap_from(head, lambda c, n: n.y > 0.5 and c.z < hc.z + 0.1 and c.z > hc.z - 0.4 and abs(c.x) < 0.34, "Face", thickness=0.1, grow=0.015, tris=120)
    paint_body(head, acc, shell)
    paint_plate(brow, STEEL_DARK)
    paint_accent_plate(face, acc)
    bits = [head, brow, face]
    for sx in (-1, 1):
        p, n = sb.on_ellipsoid(hc, hr, (sx * 0.5, 0.85, -0.5))
        m = sb2.horn("Mand%d" % (sx + 1), p - n * 0.08, (-sx * 0.45, 1.0, -0.25), 0.65, 0.13, sides=5, curve=0.3)
        paint_bone(m)
        p, n = sb.on_ellipsoid(hc, hr, (sx * 0.4, 0.7, 0.8))
        a = sb2.horn("Ant%d" % (sx + 1), p - n * 0.06, (sx * 0.35, 0.9, 0.55), 0.7, 0.09, sides=4, curve=0.6)
        sb2.paint_rules(a, amber, [top_light(sb2.mix(shell, acc, 0.3), 0.8, 1.0)], roughness=0.5)
        bits += [m, a]
    eyes = []
    for sx in (-1, 1):
        p, n = sb.on_ellipsoid(hc, hr, (sx * 0.8, 0.62, 0.35))
        ec = p - n * 0.16
        e = sb2.lowpoly_sphere("Eye%d" % (sx + 1), 0.36, ec, scale=(0.8, 1.05, 1.2), subdiv=3)
        sb2.facet(e, 200)
        sb2.paint_rules(e, sb2.mix(acc, rgb(255, 150, 40), 0.2), [facing(n, sb2.lighten(acc, 0.3), 1.0, 1.2)], roughness=0.25, emission=2.6)
        eyes.append(e)
        pd = (n + Vector((0, 0.5, 0.05))).normalized()               # pupil looks forward-out
        pu = sb.cylinder("Pupil%d" % (sx + 1), 0.11, 0.07, ec + Vector((pd.x * 0.8 * 0.36, pd.y * 1.05 * 0.36, pd.z * 1.2 * 0.36)) * 0.98, verts=10, smooth=False)
        pu.rotation_euler = pd.to_track_quat("Z", "Y").to_euler()
        sb.apply_transforms(pu)
        sb2.flat_color(pu, (0.03, 0.02, 0.04, 1), roughness=0.2)
        bits.append(pu)
    parts["Head"] = sb.join(bits, "Head")
    parts["Eyes_Glow"] = sb.join(eyes, "Eyes_Glow")

    # --- wings: Wing_1 left front, Wing_2 right front, Wing_3 left rear, Wing_4 right rear (matches EnemyBuilder)
    membrane = (0.96, 0.88, 0.58, 1.0)
    for i, (sx, y, sweep, tilt, L, W) in enumerate(((-1, 0.14, 26, 10, 2.15, 0.82), (1, 0.14, 26, 10, 2.15, 0.82),
                                                    (-1, -0.1, 52, 3, 1.6, 0.62), (1, -0.1, 52, 3, 1.6, 0.62))):
        root = (0.22 * sx, y, z + 0.36)
        parts["Wing_%d" % (i + 1)] = build_wing("Wing_%d" % (i + 1), root, sx, sweep, tilt, L, W, membrane, amber, sb2.mix(shell, acc, 0.35))
    scale_all(parts, S)
    return parts


def build():
    return build_flyer()


def _p(x, y, z):
    return (x * S, y * S, z * S)


# hover pose: head tipped down at the player, fore wings up and hind wings down mid-beat
POSE = {
    "Head": (_p(0, 0.45, Z0 + 0.02), (-18, 0, 0)),
    "Eyes_Glow": (_p(0, 0.45, Z0 + 0.02), (-18, 0, 0)),
    "Wing_1": (_p(-0.22, 0.14, Z0 + 0.36), (0, 28, 0)),
    "Wing_2": (_p(0.22, 0.14, Z0 + 0.36), (0, -28, 0)),
    "Wing_3": (_p(-0.22, -0.1, Z0 + 0.36), (0, -14, 0)),
    "Wing_4": (_p(0.22, -0.1, Z0 + 0.36), (0, 14, 0)),
}
VIEW = (70, 16)
