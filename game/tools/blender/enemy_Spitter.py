"""Spitter (acid bug, 4.5 studs): a hunched back carrying THREE big glowing acid sacs, each sunk into a dark
chitin rim; a wide flat head with a spout maw pointed at the player; pink-purple belly on the lowest third only.
Glyph: the three sacs on the hump. Front = +Y, up = +Z, feet on z = 0.
Recipe: see RECIPE.md. Run: python3 enemies2.py Spitter"""
import math
import os
import sys

import bpy
from mathutils import Vector, Matrix

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sb
import sb2
from sb import rgb
from sb2 import top_light, belly, band, stripes, region, near, facing
from enemies2 import BODY, SHELL, FLESH, BONE, STEEL, STEEL_DARK, ACCENT, masked, paint_body, paint_plate, paint_bone

PINK = rgb(205, 90, 165)          # belly flesh, only on the lowest third


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
    """A cheap curved spike / claw / tooth: three faceted frustums along a bent path (about 36 tris)."""
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


def ring(name, center, normal, major, minor, segs=12, msegs=5):
    """A low-poly chitin collar lying on the body around a sac (about 120 tris)."""
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor, major_segments=segs, minor_segments=msegs)
    ob = bpy.context.active_object
    ob.name = name
    ob.rotation_euler = Vector(normal).normalized().to_track_quat("Z", "Y").to_euler()
    ob.location = center
    sb.apply_transforms(ob)
    sb2.shade_flat(ob)
    return ob


# ---------------------------------------------------------------- Spitter: 4.5 studs tall, ~4.5 long, front = +Y
def build_spitter():
    parts = {}
    acc = ACCENT["Spitter"]
    shell = sb2.darken(sb2.mix(SHELL, acc, 0.18), 0.85)
    sac_col = sb2.mix(acc, (1, 1, 1, 1), 0.02)
    rim_col = sb2.darken(BODY, 0.8)

    # --- torso: a hunched hump (thorax low in front, the hump high behind the head, wide flanks), one fused shell
    # metaball element radius is about 1.75x the visible radius (threshold 0.6)
    spheres = [(0, 0.85, 1.7, 1.9), (0, -0.3, 2.45, 2.5), (0, -1.45, 2.15, 1.8), (-0.9, 0.2, 1.7, 1.55), (0.9, 0.2, 1.7, 1.55)]
    torso = sb.blob("Torso", spheres, resolution=0.14)
    sb2.facet(torso, 950)
    lo, hi = sb.bounds([torso])
    z_belly = lo.z + (hi.z - lo.z) * 0.34
    # paint: dark chitin, lit purple-grey shell on top, purple veins/bands across the hump, pink belly on the lowest third
    sb2.paint_rules(torso, BODY, [
        top_light(shell, power=0.9, amount=0.9),
        masked(stripes(1, 0.9, 0.34, acc, phase=0.72, amount=0.95), lambda p, n, t: 1.0 if (n.z > -0.05 and p.z > z_belly + 0.3) else 0.0),
        region(lambda p, n: 1.0 - sb2.smoothstep(z_belly - 0.2, z_belly + 0.15, p.z), PINK, amount=0.95),
    ], roughness=0.62)
    # --- the glyph: three big acid sacs sunk into the hump, each in a dark chitin collar
    sacs, rims = [], []
    for i, (y, rad) in enumerate(((0.55, 0.72), (-0.5, 0.86), (-1.5, 0.66))):
        p, n = surf(torso, (0, y, 1.6), (0, -0.1 * (i - 1), 1))
        c = p + n * (rad * 0.32)                                  # a third buried in the hump
        sac = sb2.lowpoly_sphere("Sac%d" % i, rad, c, subdiv=2)
        sb2.flat_color(sac, sac_col, emission=0.9, roughness=0.3)
        sacs.append(sac)
        rm = ring("Rim%d" % i, p + n * (rad * 0.2), n, rad * 0.98, 0.16)
        sb2.paint_rules(rm, rim_col, [top_light(sb2.mix(rim_col, shell, 0.35), 0.8, 1.0)], roughness=0.5)
        rims.append(rm)
    # two short bone spikes on the rear flanks, sitting on the shell
    spikes = []
    for x in (-1, 1):
        p, n = surf(torso, (0, -1.3, 2.0), (x * 0.8, -0.5, 0.55), sink=0.1)
        spikes.append(blade("Spike%d" % (x + 1), p, (x * 0.6, -0.7, 0.6), 0.7, 0.14, sides=4, curve=0.3, bend=(0, -1, 0)))
    parts["Torso"] = sb.join([torso] + rims + spikes, "Torso")
    parts["Sacs_Glow"] = sb.join(sacs, "Sacs_Glow")

    # --- head: wide and flat, low in front of the hump, brow plate cut from it, three eyes, a spout maw
    hc = Vector((0, 2.3, 1.95))
    hr = (1.85, 1.45, 0.9)
    head = sb2.lowpoly_sphere("Head", 1.0, hc, scale=hr, subdiv=2)
    sb2.facet(head, 400)
    brow = sb2.cap_from(head, lambda c, n: n.z > 0.4 and c.y < hc.y + 0.55 and c.y > hc.y - 0.9, "Brow", thickness=0.2, grow=0.03, tris=200)
    sb2.paint_rules(head, BODY, [top_light(shell, 0.8, 1.0), belly(sb2.darken(FLESH, 0.8), 0.6, 1.3),
                                 facing((0, 1, 0), sb2.mix(BODY, acc, 0.45), 0.7, 2.0)], roughness=0.6)
    if brow is not None:
        paint_plate(brow, STEEL_DARK)
    whites, irises = [], []
    for x, d, r in ((-1, (-0.6, 0.85, 0.55), 0.46), (1, (0.6, 0.85, 0.55), 0.46), (0, (0, 0.6, 1.0), 0.24)):
        p, n = sb.on_ellipsoid(hc, hr, d)
        ps = sb2.eye("Eye", p - n * (r * 0.35), n, r, acc, glow=3.0)
        whites += [ps[0], ps[2]]
        irises.append(ps[1])
    # spout: a short wide tube from the front of the head pointed at the player, purple ring at its lip
    sp, sn = sb.on_ellipsoid(hc, hr, (0, 1.0, -0.2))
    sdir = Vector((0, 1.0, -0.12)).normalized()
    s_end = sp + sdir * 0.85
    spout = _frustum("Spout", sp - sdir * 0.3, s_end, 0.72, 0.58, 8)
    sb2.shade_flat(spout)
    sb2.paint_rules(spout, BODY, [top_light(shell, 0.8, 1.0), band(1, s_end.y - 0.12, 0.14, acc, soft=0.2, amount=0.95)], roughness=0.55)
    parts["Head"] = sb.join([head] + ([brow] if brow is not None else []) + whites + [spout], "Head")
    parts["Eyes_Glow"] = sb.join(irises, "Eyes_Glow")
    # the acid inside the spout: a small bright disc (small, so it can burn bright)
    core = sb.cylinder("Spout_Glow", 0.48, 0.18, s_end + sdir * 0.04, verts=10, smooth=False)
    core.rotation_euler = sdir.to_track_quat("Z", "Y").to_euler()
    sb.apply_transforms(core)
    sb2.flat_color(core, sb2.mix(acc, (1, 1, 1, 1), 0.3), emission=2.2)
    parts["Spout_Glow"] = core

    # --- jaw: wide flat lower lip under the spout, four teeth on its front rim; hinge at its back
    jp = Vector((0, hc.y + 0.8, hc.z - 0.75))
    jq = 0.5                                                  # a rounded faceted lower lip (squashed blob), not a slab
    jaw = sb.blob("Jaw", [(0, jp.y - 0.45, jp.z / jq, 1.05), (0, jp.y + 0.3, jp.z / jq, 1.0), (0, jp.y + 0.95, jp.z / jq, 0.85), (-0.6, jp.y + 0.1, jp.z / jq, 0.75), (0.6, jp.y + 0.1, jp.z / jq, 0.75)], resolution=0.1)
    for v in jaw.data.vertices:
        v.co.z *= jq
    bpy.context.view_layer.update()
    sb2.facet(jaw, 120)
    sb2.paint_rules(jaw, sb2.darken(FLESH, 0.75), [top_light(sb2.mix(PINK, FLESH, 0.35), 0.9, 0.9), belly(sb2.darken(FLESH, 0.5), 0.6)], roughness=0.4)
    teeth = []
    for i, x in enumerate((-0.62, -0.22, 0.22, 0.62)):
        tp, tn = surf(jaw, (0, jp.y + 0.3, jp.z), (x, 1, 0.45), sink=0.05)
        t = blade("Tooth%d" % i, tp, (x * 0.12, 0.55, 1), 0.55 - abs(x) * 0.2, 0.12, sides=4, curve=0.15, bend=(0, -1, 0))
        teeth.append(t)
    parts["Jaw"] = sb.join([jaw] + teeth, "Jaw")

    # --- legs: four thick short bug legs, knees up and out, purple band on the shin, bone knee spike, two claws
    n_leg = 1
    for y, fwd in ((0.6, 1.0), (-0.9, -1.0)):
        for sx in (-1, 1):
            root = Vector((0.95 * sx, y, 1.45))
            pts = [(0, 0, 0), (0.95 * sx, 0.2 * fwd, 0.7), (1.4 * sx, 0.4 * fwd, -0.55), (1.3 * sx, 0.62 * fwd, -1.4)]
            name = "Leg_%d" % n_leg
            leg = sb2.seg_limb(name, pts, [0.44, 0.36, 0.27, 0.17], location=root, sides=6, joint=1.35, fuse=0.12)
            sb2.facet(leg, 380)
            paint_body(leg, acc, shell, extra=[masked(band(2, 0.55, 0.32, acc, soft=0.25, amount=0.9), lambda p, n, t: 1.0 if n.z > -0.35 else 0.0)])
            knee = root + Vector(pts[1])
            kb = blade("Knee%d" % n_leg, knee + Vector((0.15 * sx, 0, 0.15)), (0.4 * sx, -0.3 * fwd, 1), 0.5, 0.11, sides=4, curve=0.3, bend=(0, -1, 0))
            foot = Vector(leg["tip"])
            claws = [blade("Claw%d%d" % (n_leg, j), foot + Vector((0.1 * cx, 0.05, 0.0)), (0.18 * cx, 1, -0.25), 0.5, 0.09, sides=4, curve=0.25, bend=(0, 0, -1))
                     for j, cx in enumerate((-1, 1))]
            parts[name] = sb.join([leg, kb] + claws, name)
            n_leg += 1

    # feet exactly on the floor, then scale the whole bug to 4.5 studs tall (sacs included)
    lo, hi = sb.bounds(list(parts.values()))
    for ob in parts.values():
        ob.location.z -= lo.z
        sb.apply_transforms(ob, location=True)
    k = 4.5 / (hi.z - lo.z)
    for ob in parts.values():
        ob.scale = (k, k, k)
        sb.apply_transforms(ob)
    global SCALE, SHIFT
    SCALE, SHIFT = k, -lo.z
    return parts


SPITTER_POSE = {
    "Head": ((0, 0.9, 1.8), (10, 0, 0)),              # head rears up at the player, spout aimed
    "Eyes_Glow": ((0, 0.9, 1.8), (10, 0, 0)),
    "Spout_Glow": ((0, 0.9, 1.8), (10, 0, 0)),
    "Jaw": ((0, 2.1, 1.2), (-10, 0, 0)),              # maw open (hinge at the back of the jaw, inside the head)
    "Leg_1": ((-0.95, 0.6, 1.45), (0, 0, -14)),       # front legs braced wide
    "Leg_2": ((0.95, 0.6, 1.45), (0, 0, 14)),
}


SCALE, SHIFT = 1.0, 0.0


def build():
    """Build, then rewrite POSE so its pivots follow the floor shift and the 4.5-stud scale."""
    global POSE
    parts = build_spitter()
    POSE = {k: (((px * SCALE), (py * SCALE), ((pz + SHIFT) * SCALE)), rot) for k, ((px, py, pz), rot) in SPITTER_POSE.items()}
    return parts


POSE = SPITTER_POSE
VIEW = (38, 14)
