"""Runner (fast melee bug): a long low body that is all legs and speed, a grey skull head with crossed
mandibles, a glowing teal tail tip. 3 studs tall, about 7 long, front = +Y.
Recipe: see RECIPE.md. Run: python3 enemies2.py Runner"""
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
from enemies2 import BODY, SHELL, FLESH, BONE, STEEL, STEEL_DARK, ACCENT, masked, paint_body, paint_plate, paint_bone

RUNNER_SCALE = 0.9      # built a little large for detail, then scaled about the world origin (feet stay on z=0)


# ---------------------------------------------------------------- helpers local to this file (do not edit sb2 / enemies2)
def _frustum(name, a, b, r1, r2, sides):
    """One faceted cone frustum from world point a to b."""
    v = Vector(b) - Vector(a)
    bpy.ops.mesh.primitive_cone_add(vertices=sides, radius1=r1, radius2=r2, depth=v.length)
    s = bpy.context.active_object
    s.name = name
    s.rotation_euler = v.normalized().to_track_quat("Z", "Y").to_euler()
    s.location = (Vector(a) + Vector(b)) / 2
    sb.apply_transforms(s)
    return s


def blade(name, base, direction, length, radius, sides=4, curve=0.3, bend=(0, 0, 1), tip=0.02, color=BONE):
    """A cheap curved spike / claw / mandible: three faceted frustums along a bent path (about 36 tris for
    4 sides, no joint balls). `bend` is the world direction the tip curves toward, curve 0..1 how much."""
    b = Vector(base)
    d = Vector(direction).normalized()
    bv = Vector(bend)
    bv = bv.normalized() * curve if bv.length > 1e-6 else Vector((0, 0, 0))
    pts = [b, b + d * (length * 0.42), b + (d + bv * 0.6).normalized() * (length * 0.78), b + (d + bv * 1.25).normalized() * length]
    rads = [radius, radius * 0.72, radius * 0.42, tip]
    segs = [_frustum("%s_s%d" % (name, i), pts[i], pts[i + 1], rads[i], rads[i + 1], sides) for i in range(3)]
    ob = sb.join(segs, name)
    sb2.shade_flat(ob)
    ob["tip"] = list(pts[-1])
    if color is not None:
        paint_bone(ob, color)
    return ob


def surf(ob, origin, direction, sink=0.0):
    """Exact surface point and outward normal of a built mesh along a ray from `origin` (world coords), so
    eyes, spikes and dots sit ON the sculpted surface instead of on an estimated ellipsoid."""
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


def scale_world(parts, s):
    """Uniform scale of every part about the WORLD origin (enemies2.scale_parts scales about each part's own
    origin, which would pull the legs away from the body)."""
    S = Matrix.Scale(s, 4)
    for ob in parts.values():
        ob.matrix_world = S @ ob.matrix_world
        sb.apply_transforms(ob, scale=True)


# ---------------------------------------------------------------- Runner: ~3 studs tall, ~7 long, front = +Y
def build_runner(s=RUNNER_SCALE):
    parts = {}
    acc = ACCENT["Runner"]
    shell = sb2.mix(SHELL, acc, 0.32)
    grey_lit = sb2.mix(STEEL, BONE, 0.45)
    plate_grey = sb2.mix(STEEL_DARK, STEEL, 0.45)

    # --- torso: one long low fused shell (thorax fat, abdomen tapering and rising), squashed on Z
    q = 0.8                                                # Z squash
    spheres = [(0, 0.75, 1.55 / q, 1.45), (0, -0.1, 1.58 / q, 1.55), (0, -1.0, 1.58 / q, 1.45),
               (0, -1.8, 1.62 / q, 1.2), (0, -2.5, 1.7 / q, 1.0), (0, -3.05, 1.8 / q, 0.8), (0, -3.5, 1.92 / q, 0.62)]
    torso = sb.blob("Torso", spheres, resolution=0.14)
    for v in torso.data.vertices:                          # squash in place (apply_transforms trips on the blob's stale tmp object)
        v.co.z *= q
    bpy.context.view_layer.update()
    sb2.facet(torso, 820)
    # three steel shingles cut from the thorax top so they hug the shell
    shingles = []
    for i, (y0, y1) in enumerate(((1.0, 0.4), (0.28, -0.32), (-0.44, -1.1))):
        sh = sb2.cap_from(torso, lambda c, n, y0=y0, y1=y1: n.z > 0.3 and y1 < c.y < y0 and abs(c.x) < 0.72, "Shingle%d" % i,
                          thickness=0.2, grow=0.03, tris=150)
        if sh is not None:
            paint_plate(sh, plate_grey)
            shingles.append(sh)
    # paint: dark chitin, teal bands across the abdomen top, teal racing stripe along the thorax flanks
    paint_body(torso, acc, shell, extra=[
        masked(stripes(1, 0.62, 0.42, acc, phase=-1.32, amount=0.95), lambda p, n, t: 1.0 if (n.z > -0.15 and p.y < -1.2) else 0.0),
        region(lambda p, n: 0.9 if (abs(n.x) > 0.5 and 1.15 < p.z < 1.85 and -1.25 < p.y < 1.1) else 0.0, acc),
    ])
    # crest: four bone spikes along the abdomen ridge, swept back (speed)
    crest = []
    for i, y in enumerate((-1.45, -2.0, -2.5, -3.0)):
        p, n = surf(torso, (0, y, 1.5), (0, 0, 1), sink=0.12)
        L = 0.72 - 0.06 * i
        crest.append(blade("Spine%d" % i, p, (0, -0.5, 1), L, 0.13 - 0.01 * i, sides=4, curve=0.35, bend=(0, -1, 0)))
    # tail stalk out of the abdomen end, dark with a teal ring before the lantern
    tp, tn = surf(torso, (0, -3.3, 1.9), (0, -1, 0.42), sink=0.18)
    tdir = Vector((0, -1, 0.42)).normalized()
    tail_end = tp + tdir * 0.62
    tail = _frustum("Tail", tp, tail_end, 0.3, 0.17, 7)
    sb2.shade_flat(tail)
    paint_body(tail, acc, shell, extra=[band(1, tail_end.y + 0.16, 0.13, acc, soft=0.2, amount=0.95)])
    parts["Torso"] = sb.join([torso] + shingles + crest + [tail], "Torso")

    # --- head: a grey skull (cranium + muzzle + cheeks fused), lighter crown, swept horns, crossed mandibles, big eyes
    head = sb.blob("Head", [(0, 1.55, 1.62, 1.45), (0, 2.35, 1.42, 1.05), (-0.45, 1.85, 1.38, 0.95), (0.45, 1.85, 1.38, 0.95)], resolution=0.13)
    sb2.facet(head, 400)
    cap = sb2.cap_from(head, lambda c, n: n.z > 0.35 and 1.05 < c.y < 2.45 and abs(c.x) < 0.62, "Skullcap", thickness=0.18, grow=0.03, tris=160)
    eye_pts = []
    for x in (-1, 1):
        p, n = surf(head, (0, 1.95, 1.5), (x * 0.8, 0.75, 0.32))
        eye_pts.append((p, n))
    sb2.paint_rules(head, STEEL, [top_light(grey_lit, 0.7, 1.0), belly(sb2.darken(STEEL, 0.5), 0.75)] +
                    [near(p, 0.52, sb2.darken(STEEL, 0.3), soft=0.35, amount=0.9) for p, n in eye_pts], roughness=0.5)
    if cap is not None:
        paint_plate(cap, sb2.mix(STEEL, BONE, 0.25))
    whites, irises = [], []
    for p, n in eye_pts:
        ps = sb2.eye("Eye", p - n * 0.14, n, 0.33, acc, glow=3.0)
        whites += [ps[0], ps[2]]
        irises.append(ps[1])
    horns = []
    for x in (-1, 1):
        p, n = surf(head, (0, 1.6, 1.6), (x * 0.6, -0.45, 0.8), sink=0.1)
        horns.append(blade("Horn%d" % (x + 1), p, (x * 0.35, -0.9, 0.5), 1.05, 0.14, sides=4, curve=0.4, bend=(0, -1, -0.25)))
    mands = []
    for x in (-1, 1):
        p, n = surf(head, (0, 2.1, 1.3), (x * 0.9, 0.7, -0.3), sink=0.14)
        mands.append(blade("Mand%d" % (x + 1), p, (-x * 0.22, 1, -0.05), 1.55, 0.21, sides=5, curve=0.6, bend=(-x, 0, 0)))
    parts["Head"] = sb.join([head] + ([cap] if cap is not None else []) + horns + mands + whites, "Head")
    parts["Eyes_Glow"] = sb.join(irises, "Eyes_Glow")

    # --- jaw: a rounded faceted lower jaw (squashed blob) under the muzzle, four teeth on its rim; hinge at its back
    jp, jn = surf(head, (0, 2.25, 1.4), (0, 0.55, -1))
    jq = 0.55
    jaw = sb.blob("Jaw", [(0, jp.y - 0.05, (jp.z - 0.02) / jq, 0.8), (0, jp.y + 0.5, jp.z / jq, 0.62)], resolution=0.1)
    for v in jaw.data.vertices:
        v.co.z *= jq
    bpy.context.view_layer.update()
    sb2.facet(jaw, 90)
    sb2.paint_rules(jaw, FLESH, [top_light(sb2.lighten(FLESH, 0.3), 0.8, 1.0), belly(sb2.darken(FLESH, 0.6), 0.7)], roughness=0.4)
    teeth = []
    for i, x in enumerate((-0.55, -0.2, 0.2, 0.55)):
        tpnt, tnrm = surf(jaw, (0, jp.y + 0.25, jp.z - 0.02), (x, 1, 0.25), sink=0.06)
        t = sb2.horn("Tooth%d" % i, tpnt, (x * 0.15, 0.3, 1), 0.34 - abs(x) * 0.2, 0.08, sides=4)
        paint_bone(t)
        teeth.append(t)
    parts["Jaw"] = sb.join([jaw] + teeth, "Jaw")

    # --- legs: four blade legs, knees higher than the back, teal band on the shin, bone knee blade, two claws
    n_leg = 1
    for y, fwd in ((0.6, 1.0), (-1.0, -1.0)):
        for sx in (-1, 1):
            root = Vector((0.55 * sx, y, 1.5))
            pts = [(0, 0, 0), (1.0 * sx, 0.25 * fwd, 0.95), (1.25 * sx, 0.65 * fwd, -0.65), (1.1 * sx, 0.9 * fwd, -1.36)]
            name = "Leg_%d" % n_leg
            leg = sb2.seg_limb(name, pts, [0.4, 0.32, 0.22, 0.14], location=root, sides=6, joint=1.35, fuse=0.11)
            sb2.facet(leg, 420)
            paint_body(leg, acc, shell, extra=[masked(band(2, 1.4, 0.4, acc, soft=0.25, amount=0.9), lambda p, n, t: 1.0 if n.z > -0.35 else 0.0)])
            knee = root + Vector(pts[1])
            kb = blade("Knee" + name[-1], knee + Vector((0.12 * sx, -0.05 * fwd, 0.14)), (0.3 * sx, -0.5, 1), 0.62, 0.12, sides=4, curve=0.35, bend=(0, -1, 0))
            foot = Vector(leg["tip"])
            claws = [blade("Claw%s%d" % (name[-1], j), foot + Vector((0.1 * cx, 0.08, -0.02)), (0.16 * cx, 1, -0.18), 0.46, 0.085, sides=4, curve=0.22, bend=(0, 0, -1))
                     for j, cx in enumerate((-1, 1))]
            parts[name] = sb.join([leg, kb] + claws, name)
            n_leg += 1

    # --- glow: the tail lantern (small, so it can burn bright) plus three pairs of teal dots on the abdomen flanks
    glow = []
    tip = sb2.horn("TailTip", tail_end - tdir * 0.08, tdir, 0.66, 0.2, sides=5)
    sb2.flat_color(tip, acc, emission=1.6)
    glow.append(tip)
    for i, y in enumerate((-1.7, -2.2, -2.7)):
        for x in (-1, 1):
            p, n = surf(torso, (0, y, 1.6), (x, 0, 0.35), sink=0.05)
            d = sb.sphere("Dot%d%d" % (i, x + 1), 0.09, p, subdiv=1, smooth=False)
            sb2.flat_color(d, acc, emission=1.5)
            glow.append(d)
    parts["Dots_Glow"] = sb.join(glow, "Dots_Glow")

    # feet exactly on the floor, then the overall size
    lo, hi = sb.bounds(list(parts.values()))
    for ob in parts.values():
        ob.location.z -= lo.z
    if s != 1.0:
        scale_world(parts, s)
    return parts


def _pose(moves, s=RUNNER_SCALE):
    """Pose pivots are written in build units; scale them with the model."""
    return {k: (tuple(c * s for c in piv), rot) for k, (piv, rot) in moves.items()}


RUNNER_POSE = _pose({
    "Head": ((0, 1.0, 1.5), (5, 0, 0)),               # skull lifts a touch at the player
    "Eyes_Glow": ((0, 1.0, 1.5), (5, 0, 0)),
    "Jaw": ((0, 2.1, 0.95), (-12, 0, 0)),             # mouth open (hinge at the back of the jaw)
    "Leg_1": ((-0.55, 0.6, 1.5), (0, 0, -22)),        # gallop: front-left and rear-right reach forward
    "Leg_2": ((0.55, 0.6, 1.5), (0, 0, -12)),
    "Leg_3": ((-0.55, -1.0, 1.5), (0, 0, 12)),
    "Leg_4": ((0.55, -1.0, 1.5), (0, 0, 22)),
})


def build():
    return build_runner()


POSE = RUNNER_POSE
VIEW = (36, 14)
