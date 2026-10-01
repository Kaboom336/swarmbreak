"""Warden / Sky King (wave-15 flying boss, ~15 studs wide). Glyph: ONE giant eye that IS the body.
A pale glowing eyeball (Eye_Glow) with a blue iris disc and a black slit pupil sits in a dark chitin socket cut
from the same ellipsoid (back cup, upper and lower lids, steel cheek plates), bone lashes along the upper lid,
two bone brow horns, a bone crest down the back. A blue halo ring hangs on three steel struts above the socket.
Four bat wings (dark membrane, blue tips, bone finger claws) root in the socket sides. Two talons hang under it.
The eye body is ~6 studs wide = 40 % of the 15-stud wingspan. Floats: lowest point (talons) at z ~5.
Recipe: see RECIPE.md. Run: python3 enemies2.py Warden"""
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
from sb2 import top_light, belly, band, near, facing, spots
from enemies2 import BODY, SHELL, FLESH, BONE, STEEL, STEEL_DARK, ACCENT, masked, paint_body, paint_plate, paint_bone, crest, claw_fan

C = Vector((0.0, 0.0, 9.4))          # eye body centre
R = (3.05, 2.75, 2.9)                # socket ellipsoid radii (the eyeball is 0.12 smaller)
ER = (2.93, 2.63, 2.78)


# ---------------------------------------------------------------- helpers local to this file
def wing_frame(root, sx, sweep_deg, tilt_deg):
    """World matrix for a wing on side sx (-1 left, +1 right): X out along the wing, Y toward the leading edge."""
    sw, ti = math.radians(sweep_deg), math.radians(tilt_deg)
    d = Vector((sx * math.cos(sw) * math.cos(ti), -math.sin(sw) * math.cos(ti), math.sin(ti))).normalized()
    e = Vector((-d.y, d.x, 0.0)).normalized() * sx
    e = (e - d * e.dot(d)).normalized()
    f = d.cross(e).normalized()
    M = Matrix.Identity(4)
    for i in range(3):
        M[i][0], M[i][1], M[i][2] = d[i], e[i], f[i]
    return Matrix.Translation(Vector(root)) @ M


def bat_membrane(name, L, W, matrix, thickness=0.12):
    """A bat wing outline in the local XY plane (root at the origin, tip at +X, leading edge at +Y, two
    scallops on the trailing edge), solidified and placed with `matrix`."""
    pts = [(0, 0.22 * W), (0.3 * L, 0.42 * W), (0.66 * L, 0.32 * W), (1.0 * L, 0.04 * W),
           (0.86 * L, -0.34 * W), (0.72 * L, -0.2 * W), (0.56 * L, -0.62 * W), (0.4 * L, -0.4 * W),
           (0.22 * L, -0.78 * W), (0.04 * L, -0.46 * W)]
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


def build_wing(name, root, sx, sweep, tilt, L, W, acc, shell):
    M = wing_frame(root, sx, sweep, tilt)
    mem = bat_membrane(name + "_M", L, W, M)
    # membrane: dark chitin, lit from above, the outer 40 % of the wing floods with the accent (a real area of blue)
    tipc = acc
    tx = (lambda p, n, t: t["x"]) if sx > 0 else (lambda p, n, t: 1.0 - t["x"])
    tiprule = lambda p, n, t: (tipc, sb2.smoothstep(0.5, 0.85, tx(p, n, t)))
    sb2.paint_rules(mem, sb2.mix(BODY, acc, 0.12), [top_light(sb2.mix(shell, acc, 0.2), 0.8, 0.8), tiprule], roughness=0.55)
    bits = [mem]
    # leading-edge arm with an elbow, finger bones along the membrane, a bone claw at the elbow
    elbow = Vector((0.66 * L, 0.3 * W, 0))
    arm_pts = [(0, 0.12 * W, 0), tuple(elbow), (1.0 * L, 0.04 * W, 0)]
    pa = M @ Vector(arm_pts[0])
    arm = sb2.seg_limb(name + "_Arm", [tuple(M @ Vector(p) - pa) for p in arm_pts], [0.34, 0.24, 0.07], location=pa, sides=6, joint=1.35, fuse=0.1)
    sb2.facet(arm, 220)
    paint_body(arm, acc, shell)
    bits.append(arm)
    for i, (a, b) in enumerate(((elbow, (0.86 * L, -0.34 * W, 0)), (elbow, (0.56 * L, -0.62 * W, 0)), ((0.3 * L, 0.3 * W, 0), (0.22 * L, -0.78 * W, 0)))):
        qa, qb = M @ Vector(a), M @ Vector(b)
        f = sb2.seg_limb("%s_F%d" % (name, i), [(0, 0, 0), tuple(qb - qa)], [0.14, 0.05], location=qa, sides=5, joint=1.0)
        paint_bone(f)
        bits.append(f)
    ep = M @ elbow
    cl = sb2.horn(name + "_Claw", ep, (M.to_3x3() @ Vector((0.35, 1.0, 0.1))).normalized(), 0.95, 0.17, sides=4, curve=0.35)
    paint_bone(cl)
    bits.append(cl)
    return sb.join(bits, name)


# ---------------------------------------------------------------- the Sky King
def build_warden():
    parts = {}
    acc = ACCENT["Warden"]
    shell = sb2.mix(SHELL, acc, 0.3)
    pale = sb2.mix(acc, (1, 1, 1, 1), 0.5)          # the eyeball tone (low emission so it does not blow out)

    # --- the socket is cut from one reference ellipsoid so every plate hugs the eyeball
    ref = sb2.lowpoly_sphere("Ref", 1.0, C, scale=R, subdiv=4)
    cz = C.z
    cup = sb2.cap_from(ref, lambda c, n: n.y < 0.42, "Cup", thickness=0.6, grow=0.02, tris=650)
    lid_up = sb2.cap_from(ref, lambda c, n: n.y >= 0.42 and n.z > 0.3, "LidUp", thickness=0.5, grow=0.05, tris=220)
    lid_lo = sb2.cap_from(ref, lambda c, n: n.y >= 0.42 and n.z < -0.42, "LidLo", thickness=0.42, grow=0.05, tris=180)
    cheeks = []
    for sx in (-1, 1):
        ch = sb2.cap_from(ref, lambda c, n, sx=sx: n.x * sx > 0.72 and abs(c.z - cz) < 1.4 and c.y < 1.2 and c.y > -1.4, "Cheek%d" % (sx + 1), thickness=0.3, grow=0.58, tris=140)   # grow = cup thickness: sits on the cup
        cheeks.append(ch)
    bpy.data.objects.remove(ref, do_unlink=True)
    paint_body(cup, acc, shell, stripe=(2, 1.3, 0.38, 0.2))
    paint_body(lid_up, acc, shell, extra=[band(2, cz + 2.4, 0.5, acc, soft=0.4, amount=0.85)])
    paint_body(lid_lo, acc, shell)
    for ch in cheeks:
        paint_plate(ch, STEEL)
    torso = [cup, lid_up, lid_lo] + cheeks
    # lashes of bone along the upper lid edge, two brow horns, a crest down the back
    for i, x in enumerate((-0.85, -0.45, 0.0, 0.45, 0.85)):
        p, n = sb.on_ellipsoid(C, R, (x, 0.95, 0.5))
        L = 1.25 - abs(x) * 0.45
        h = sb2.horn("Lash%d" % i, p + n * 0.35, (x * 0.35, 0.7, 0.55), L, 0.17, sides=4, curve=0.3)
        paint_bone(h)
        torso.append(h)
    for i, x in enumerate((-1, 1)):
        p, n = sb.on_ellipsoid(C, R, (x * 0.75, -0.2, 1.0))
        h = sb2.horn("Horn%d" % i, p + n * 0.3, (x * 0.55, -0.35, 1.0), 2.2, 0.36, sides=5, curve=0.45)
        paint_bone(h)
        torso.append(h)
    torso += crest("Spine", (0, -1.6, -3.6), (0, -1.9, cz + 2.0), (0, -0.7, 0.7), 5, 1.3, 0.26, sides=4, curve=0.3)
    # halo struts: three steel bars from the top of the cup to the ring
    hc = C + Vector((0, -0.5, 4.0))
    Rh = Matrix.Rotation(math.radians(10), 3, "X")
    for i, a in enumerate((90, 210, 330)):
        d = Vector((math.cos(math.radians(a)), math.sin(math.radians(a)), 0))
        p, n = sb.on_ellipsoid(C, R, (d.x * 0.5, d.y * 0.5, 1.0))
        top = hc + Rh @ (d * 2.6)
        st = sb2.seg_limb("Strut%d" % i, [(0, 0, 0), tuple(top - (p + n * 0.3))], [0.2, 0.14], location=p + n * 0.3, sides=5, joint=1.0)
        paint_plate(st, STEEL)
        torso.append(st)
    # --- talons: two short thick legs under the eye, three bone claws each, tips at z ~5
    talons = []
    for i, sx in enumerate((-1, 1)):
        p, n = sb.on_ellipsoid(C, R, (sx * 0.45, 0.3, -1.0))
        root = p + n * 0.25
        pts = [(0, 0, 0), (0.2 * sx, 0.25, -0.95), (-0.05 * sx, 0.6, -1.65)]
        leg = sb2.seg_limb("Talon%d" % i, pts, [0.5, 0.36, 0.26], location=root, sides=7, joint=1.3, fuse=0.1)
        sb2.facet(leg, 240)
        paint_body(leg, acc, shell)
        t = Vector(leg["tip"])
        cl = claw_fan("TalonClaw%d" % i, (t.x, t.y + 0.1, t.z - 0.05), (0, 0.55, -1), 3, 0.75, 0.13, 0.28, curve=0.3)
        talons += [leg] + cl
    parts["Torso"] = sb.join(torso, "Torso")
    parts["Talons"] = sb.join(talons, "Talons")

    # --- the eyeball: pale blue, brighter around the iris, blue veins toward the back; low emission (big mass)
    eye = sb2.lowpoly_sphere("Eye_Glow", 1.0, C, scale=ER, subdiv=3)
    sb2.facet(eye, 520)
    look = Vector((0, 1.0, -0.12)).normalized()
    ip, inrm = sb.on_ellipsoid(C, ER, look)
    sb2.paint_rules(eye, pale, [near(ip, 2.3, sb2.lighten(pale, 0.25), soft=0.6, amount=0.8),
                                masked(spots(0.9, 0.3, sb2.darken(acc, 0.85), seed=3.0, amount=0.9), lambda p, n, t: 1.0 if n.y < 0.55 else 0.0),
                                belly(sb2.mix(pale, acc, 0.5), 0.5)], roughness=0.3, emission=0.85)
    parts["Eye_Glow"] = eye
    iris = sb.cylinder("Iris_Glow", 1.35, 0.3, ip - inrm * 0.02, verts=14, smooth=False)
    iris.rotation_euler = inrm.to_track_quat("Z", "Y").to_euler()
    sb.apply_transforms(iris)
    sb2.paint_rules(iris, acc, [facing(inrm, sb2.lighten(acc, 0.2), 0.8, 2.0)], roughness=0.3, emission=2.2)
    parts["Iris_Glow"] = iris
    pupil = sb.cylinder("Pupil", 0.7, 0.14, ip + inrm * 0.2, verts=12, smooth=False)
    pupil.scale = (0.42, 1.0, 1.0)
    pupil.rotation_euler = inrm.to_track_quat("Z", "Y").to_euler()
    sb.apply_transforms(pupil)
    sb2.flat_color(pupil, (0.02, 0.02, 0.03, 1), roughness=0.2)
    parts["Pupil"] = pupil

    # --- halo: one fat blue ring at emission 1.0 plus six small bright spikes
    halo = sb.torus("Halo_Glow", 2.6, 0.24, hc, (math.radians(10), 0, 0), smooth=False)
    sb2.facet(halo, 520)
    sb2.flat_color(halo, acc, emission=1.0)
    hbits = [halo]
    for i in range(6):
        a = i / 6 * 2 * math.pi + math.pi / 6
        d = Vector((math.cos(a), math.sin(a), 0))
        sp = sb2.horn("HaloSpike%d" % i, hc + Rh @ (d * 2.75), Rh @ Vector((d.x, d.y, 0.15)), 0.9, 0.16, sides=4)
        sb2.flat_color(sp, sb2.lighten(acc, 0.3), emission=1.8)
        hbits.append(sp)
    parts["Halo_Glow"] = sb.join(hbits, "Halo_Glow")

    # --- wings: Wing_1 (+x front), Wing_2 (-x front), Wing_3 (+x rear), Wing_4 (-x rear), rooted inside the cup
    for i, (sx, fwd) in enumerate(((1, 1), (-1, 1), (1, -1), (-1, -1))):
        if fwd > 0:
            p, n = sb.on_ellipsoid(C, R, (sx * 0.9, 0.25, 0.5))
            root = p - n * 0.45
            parts["Wing_%d" % (i + 1)] = build_wing("Wing_%d" % (i + 1), root, sx, 12, 14, 5.0, 2.5, acc, shell)
        else:
            p, n = sb.on_ellipsoid(C, R, (sx * 0.85, -0.55, 0.35))
            root = p - n * 0.45
            parts["Wing_%d" % (i + 1)] = build_wing("Wing_%d" % (i + 1), root, sx, 48, 2, 3.9, 2.0, acc, shell)
    return parts


def build():
    return build_warden()


def _root(sx, fwd):
    if fwd > 0:
        p, n = sb.on_ellipsoid(C, R, (sx * 0.9, 0.25, 0.5))
    else:
        p, n = sb.on_ellipsoid(C, R, (sx * 0.85, -0.55, 0.35))
    return tuple(p - n * 0.45)


# hover pose: front wings beating up, rear wings down, eye tipped a touch toward the player
POSE = {
    "Wing_1": (_root(1, 1), (0, -26, 0)),
    "Wing_2": (_root(-1, 1), (0, 26, 0)),
    "Wing_3": (_root(1, -1), (0, 14, 0)),
    "Wing_4": (_root(-1, -1), (0, -14, 0)),
}
VIEW = (34, 8)
