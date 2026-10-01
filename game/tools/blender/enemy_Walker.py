"""Walker (basic bruiser) and Brute (wave-5 boss, first version = big Walker; give it its own shape later).
Recipe: see RECIPE.md. Run: python3 enemies2.py Walker"""
import math
import os
import sys

import bpy
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sb
import sb2
from sb import rgb
from sb2 import top_light, belly, height, band, stripes, spots, region, near, facing
from enemies2 import BODY, SHELL, FLESH, BONE, STEEL, STEEL_DARK, ACCENT, masked, paint_body, paint_plate, paint_bone, crest, claw_fan, scale_parts


# Walker: ~5.5 studs, front = +Y
def build_walker(s=1.0, boss=False):
    parts = {}
    acc = ACCENT["Brute" if boss else "Walker"]
    shell = sb2.mix(SHELL, acc, 0.22) if not boss else sb2.mix(rgb(60, 20, 30), acc, 0.35)
    # --- torso: one fused shell, then plates cut from it so they hug the body
    spheres = [(-1.25, 0.0, 3.55, 1.1), (1.25, 0.0, 3.55, 1.1), (0, 0.55, 3.05, 1.25), (0, -0.55, 3.85, 1.15), (0, 0.15, 2.25, 0.85)]
    if boss:
        spheres.append((0, -0.9, 4.5, 1.2))
    torso = sb.blob("Torso", spheres, resolution=0.14)
    sb2.facet(torso, 1100)
    pads = sb2.cap_from(torso, lambda c, n: n.z > 0.25 and abs(c.x) > 0.85 and c.y < 0.75 and c.z > 3.3, "Pads", thickness=0.28, grow=0.03)
    chest = sb2.cap_from(torso, lambda c, n: n.y > 0.55 and 2.4 < c.z < 3.6 and abs(c.x) < 0.9, "Chest", thickness=0.2, grow=0.02)
    paint_body(torso, acc, shell, stripe=(2, 0.9, 0.4, 0.15))
    paint_plate(pads, STEEL)
    paint_plate(chest, STEEL_DARK)
    spine = crest("Spine", (0, -1.9, -1.1), (0, 0.2, 4.55), (0, -0.25, 1), 6 if boss else 5, 1.15 if boss else 0.85, 0.2, sides=4, curve=0.3)
    parts["Torso"] = sb.join([torso, pads, chest] + spine, "Torso")
    # --- head: big, forward, low; brow plate cut from it; two curved horns; huge eyes; wedge jaw with teeth
    hc = Vector((0, 1.85, 3.6))
    hr = (1.45, 1.3, 1.1)                                   # head radii: wide, deep, a little flat
    head = sb2.lowpoly_sphere("Head", 1.0, hc, scale=hr, subdiv=2)
    sb2.facet(head, 420)
    brow = sb2.cap_from(head, lambda c, n: n.z > 0.3 and n.y > -0.1 and c.z > hc.z + 0.2, "Brow", thickness=0.24, grow=0.03)
    paint_body(head, acc, shell)
    paint_plate(brow, STEEL_DARK)
    horns = []
    for i, x in enumerate((-1, 1)):
        p, n = sb.on_ellipsoid(hc, hr, (x * 0.7, -0.35, 1.0))
        h = sb2.horn("Horn%d" % i, p - n * 0.15, (x * 0.5, -0.45, 1.0), 1.35, 0.22, sides=5, curve=0.45)
        paint_bone(h)
        horns.append(h)
    whites = []
    irises = []
    for x in (-1, 1):
        p, n = sb.on_ellipsoid(hc, hr, (x * 0.55, 1.0, 0.25))
        ps = sb2.eye("Eye", p - n * 0.12, n, 0.42, acc, glow=3.0)
        whites.append(ps[0])
        irises.append(ps[1])
        whites.append(ps[2])
    parts["Head"] = sb.join([head, brow] + horns + whites, "Head")
    parts["Eyes_Glow"] = sb.join(irises, "Eyes_Glow")
    # jaw hangs from the front-bottom of the head, mouth open toward the player
    jp, jn = sb.on_ellipsoid(hc, hr, (0, 0.9, -0.55))
    jaw = sb2.wedge("Jaw", (2.1, 1.9, 0.5), (0, jp.y + 0.45, jp.z + 0.05), taper=0.55)
    sb2.paint_rules(jaw, sb2.darken(FLESH, 0.7), [top_light(FLESH, 1.0, 0.9)], roughness=0.4)
    teeth = []
    for i, x in enumerate((-0.65, -0.33, 0.0, 0.33, 0.65)):
        t = sb2.horn("Tooth%d" % i, (x, jp.y + 1.2 - abs(x) * 0.5, jp.z + 0.28), (0, 0.2, 1), 0.45 - abs(x) * 0.2, 0.1, sides=4)
        paint_bone(t)
        teeth.append(t)
    parts["Jaw"] = sb.join([jaw] + teeth, "Jaw")
    # --- arms: heavy, knuckle-dragging, forearm guard cut from the arm, three curved claws
    for side, sx in (("L", -1), ("R", 1)):
        root = Vector((1.95 * sx, 0.2, 3.5))
        pts = [(0, 0, 0), (0.6 * sx, -0.75, -1.15), (0.5 * sx, 0.95, -2.45), (0.35 * sx, 1.55, -3.15)]
        arm = sb2.seg_limb("Arm_" + side, pts, [0.58, 0.42, 0.62, 0.46], location=root, sides=7, joint=1.28, fuse=0.13)
        sb2.facet(arm, 700)
        guard = sb2.cap_from(arm, lambda c, n, sx=sx: n.x * sx > 0.45 and 0.5 < c.z < 2.6 and c.y > -0.4, "Guard" + side, thickness=0.22, grow=0.02)
        paint_body(arm, acc, shell, extra=[masked(band(2, 1.6, 0.22, acc, soft=0.2, amount=0.9), lambda p, n, t: 1.0 if n.z > -0.2 else 0.0)])
        paint_plate(guard, STEEL)
        t = Vector(arm["tip"])
        cl = claw_fan("Claw" + side, (t.x, t.y + 0.15, t.z - 0.1), (0.1 * sx, 0.75, -0.65), 3, 0.8, 0.14, 0.24, curve=0.4)
        el = sb2.horn("Elbow" + side, root + Vector(pts[1]) + Vector((0.3 * sx, -0.4, 0)), (0.5 * sx, -1, 0.2), 0.6, 0.12, sides=4, curve=0.2)
        paint_bone(el)
        parts["Arm_" + side] = sb.join([arm, guard, el] + cl, "Arm_" + side)
    # --- legs: short and thick, knee cap, three toes
    for side, sx in (("L", -1), ("R", 1)):
        root = Vector((0.72 * sx, -0.1, 2.25))
        pts = [(0, 0, 0), (0.22 * sx, 0.5, -1.0), (0.15 * sx, -0.1, -1.9), (0.2 * sx, 0.65, -2.2)]
        leg = sb2.seg_limb("Leg_" + side, pts, [0.5, 0.38, 0.42, 0.3], location=root, sides=7, joint=1.25, fuse=0.13)
        sb2.facet(leg, 500)
        knee = sb2.cap_from(leg, lambda c, n: n.y > 0.5 and 0.9 < c.z < 1.6, "Knee" + side, thickness=0.16, grow=0.02)
        paint_body(leg, acc, shell)
        paint_plate(knee, STEEL_DARK)
        ft = Vector(leg["tip"])
        toes = claw_fan("Toe" + side, (ft.x, ft.y + 0.2, ft.z - 0.05), (0, 1, -0.2), 3, 0.5, 0.11, 0.24, curve=0.15)
        parts["Leg_" + side] = sb.join([leg, knee] + toes, "Leg_" + side)
    if boss:
        crown = sb.torus("Crown_Glow", 1.0, 0.13, (0, -0.6, 5.55), (math.radians(90), 0, 0), smooth=False)
        sb2.flat_color(crown, acc, emission=1.2)
        parts["Crown_Glow"] = crown
    if s != 1.0:
        scale_parts(parts, s)
    return parts


WALKER_POSE = {
    "Arm_R": ((1.95, 0.2, 3.5), (-60, 0, -10)),       # right arm raised to strike
    "Head": ((0, 0.9, 3.4), (8, 0, -6)),              # head tips up at the player
    "Eyes_Glow": ((0, 0.9, 3.4), (8, 0, -6)),
    "Jaw": ((0, 2.2, 3.0), (22, 0, 0)),               # mouth open
}




def build():
    return build_walker()


POSE = WALKER_POSE
VIEW = (30, 10)
