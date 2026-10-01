"""Builds the 8 Swarm enemies as multi-part models (one mesh per rig part) and exports them.

Part names match the Motor6D rig in src/ServerStorage/EnemyBuilder.luau so the laptop step can
swap each Part for the MeshPart with the same name: Torso, Head, Jaw, Arm_L/R, Leg_L/R, Leg_1..n, Wing_1..n.
Glow parts end in _Glow (Neon in Studio). Front is +Y. Sizes are in studs.

Look: dark chitin bodies, lighter shell plates on top, station-steel armour, one glowing accent
color per enemy (eyes, cores, sacs), bone-white claws, horns and teeth.

Run:  python3 enemies.py            (exports assets/models/enemies/*.fbx|glb + renders)
      python3 enemies.py Walker     (one enemy)
      SB_NO_RENDER=1 python3 enemies.py
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import bpy
import bmesh
import sb
from sb import PAL, rgb
from mathutils import Vector, Matrix

ACCENT = {
    "Walker": PAL["orange"], "Runner": PAL["teal"], "Flyer": PAL["yellow"], "Tank": PAL["green"],
    "Spitter": PAL["purple"], "Brute": PAL["red"], "Queen": PAL["purple"], "Warden": PAL["blue"],
}
SHELL = rgb(88, 58, 140)      # lighter shell; raised from PAL["chitin2"] (48,32,78) so the two-tone reads against BODY
BODY = PAL["chitin"]
BELLY = PAL["flesh"]
GLOW_EYE = 2.0                # eye spheres r >= 0.15
GLOW_EYE_SMALL = 3.0          # tiny eye dots (r < 0.15) can take more without blowing out
GLOW_BIG = 1.8                # cap for any glow mass wider than ~0.3 studs: Neon and emission saturate to white above this
GLOW_THIN = 2.0               # thin rings, seams, slots
HOVER = ("Flyer", "Warden")   # rendered with the floor at z=0 so they hang in the air instead of standing on their claws


def tint(c, acc, k):
    """Lerp a palette color k of the way toward the accent (alpha stays 1)."""
    return tuple(c[i] * (1 - k) + acc[i] * k for i in range(3)) + (1.0,)


_gmats = {}


def gradient(ob, top, bottom, axis=2, emission=0.0, roughness=0.55, alpha=1.0, curve=1.7):
    """Two-tone vertex gradient like sb.gradient, plus a render material that actually shows the vertex colors
    (sb's render material is flat `top`, so the two-tone never showed in renders). curve > 1 keeps `top` on the
    upper shell only so the belly stays dark. Modifiers are applied first: a skinned limb has no faces to color
    until then (its vertex colors came out empty). The Gamma node makes the stored sRGB bytes render as bright as
    sb.paint's flat colors so plates and shells keep their relative brightness."""
    if ob.modifiers:
        sb.apply_modifiers(ob)
    bpy.context.view_layer.update()
    me = ob.data
    mw = ob.matrix_world
    zs = [(mw @ v.co)[axis] for v in me.vertices]
    lo, hi = min(zs), max(zs)
    span = max(hi - lo, 1e-6)
    attr = me.color_attributes.get("Color") or me.color_attributes.new(name="Color", type="BYTE_COLOR", domain="CORNER")
    for poly in me.polygons:
        for li in poly.loop_indices:
            t = (((mw @ me.vertices[me.loops[li].vertex_index].co)[axis] - lo) / span) ** curve
            attr.data[li].color_srgb = tuple(bottom[i] * (1 - t) + top[i] * t for i in range(4))
    me.color_attributes.active_color = attr
    me.color_attributes.render_color_index = me.color_attributes.find("Color")
    key = (emission, roughness, alpha)
    m = _gmats.get(key)
    if m is None:
        m = bpy.data.materials.new("VC_%d" % len(_gmats))
        m.use_nodes = True
        nt = m.node_tree
        bsdf = nt.nodes["Principled BSDF"]
        vc = nt.nodes.new("ShaderNodeVertexColor")
        vc.layer_name = "Color"
        gam = nt.nodes.new("ShaderNodeGamma")
        gam.inputs["Gamma"].default_value = 1 / 2.2
        nt.links.new(vc.outputs["Color"], gam.inputs["Color"])
        nt.links.new(gam.outputs["Color"], bsdf.inputs["Base Color"])
        bsdf.inputs["Roughness"].default_value = roughness
        if emission > 0:
            nt.links.new(gam.outputs["Color"], bsdf.inputs["Emission Color"])
            bsdf.inputs["Emission Strength"].default_value = emission
        if alpha < 1.0:
            bsdf.inputs["Alpha"].default_value = alpha
            try:
                m.surface_render_method = "BLENDED"
            except Exception:
                pass
        m.diffuse_color = top
        _gmats[key] = m
    ob.data.materials.clear()
    ob.data.materials.append(m)
    if alpha < 1.0:
        ob["alpha"] = alpha
    return ob


def eyes(head_pos, accent, count=2, spread=0.35, r=0.12, forward=0.4, up=0.05, curve=0.0):
    """Glowing eye spheres in front of a head position (+Y forward). curve pulls outer eyes back."""
    out = []
    for i in range(count):
        t = (i - (count - 1) / 2) * spread
        back = abs(t) * curve
        e = sb.sphere("Eye%d" % i, r, (head_pos[0] + t, head_pos[1] + forward - back, head_pos[2] + up), subdiv=2)
        sb.paint(e, accent, emission=GLOW_EYE_SMALL if r < 0.15 else GLOW_EYE)
        out.append(e)
    return sb.join(out, "Eyes_Glow")


def ellipsoid(name, center, radii, color=BODY, subdiv=3):
    ob = sb.sphere(name, 1.0, center, scale=radii, subdiv=subdiv)
    sb.apply_transforms(ob)
    sb.paint(ob, color)
    return ob


def torus_lr(name, major, minor, location=(0, 0, 0), rotation=(0, 0, 0), maj_seg=20, min_seg=8):
    """Low-poly torus (320 tris at the defaults vs 768 for sb.torus) for sockets, collars and girdles."""
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor, major_segments=maj_seg, minor_segments=min_seg)
    ob = bpy.context.active_object
    ob.name = name
    ob.location = location
    ob.rotation_euler = rotation
    for p in ob.data.polygons:
        p.use_smooth = True
    return ob


def plate_along(name, at, normal, along, size, color, bevel=0.05, sink=0.4):
    """Beveled plate at `at` whose thickness (local Z) follows `normal` and whose length (local Y) follows `along`
    (projected into the plate plane), for guards on limbs and seams that run along a body. sink: fraction of the
    thickness pushed under `at`."""
    n = Vector(normal).normalized()
    a = Vector(along)
    a = (a - n * a.dot(n)).normalized()
    x = a.cross(n).normalized()
    b = sb.box(name, size, (0, 0, 0), (0, 0, 0), bevel=bevel)
    b.rotation_euler = Matrix((x, a, n)).transposed().to_euler()
    b.location = Vector(at) - n * (size[2] * sink)
    sb.paint(b, color, roughness=0.4, metallic=0.15)
    return b


def bar(name, a, b, w, color):
    """Square strut from point a to point b."""
    a, b = Vector(a), Vector(b)
    d = b - a
    ob = sb.box(name, (w, d.length, w), (0, 0, 0), (0, 0, 0), bevel=0)
    ob.rotation_euler = d.normalized().to_track_quat("Y", "Z").to_euler()
    ob.location = (a + b) / 2
    sb.paint(ob, color, roughness=0.45, metallic=0.2)
    return ob


def shell_cap(name, center, radii, keep, thickness=0.25, color=None, subdiv=3, grow=1.02):
    """Curved armour plate that hugs an ellipsoid body: the piece of its surface on the normal side of every
    (point, normal) plane in `keep` (coords relative to `center`), thickened outward. Unlike a flat plate_on box it
    has no floating corners, so it works for big elytra and carapace halves."""
    ob = sb.sphere(name, 1.0, center, scale=tuple(x * grow for x in radii), subdiv=subdiv)
    sb.apply_transforms(ob)
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    for co, no in keep:
        bmesh.ops.bisect_plane(bm, geom=bm.verts[:] + bm.edges[:] + bm.faces[:], dist=1e-4,
                               plane_co=Vector(co), plane_no=Vector(no).normalized(), clear_inner=True)
    bm.to_mesh(ob.data)
    bm.free()
    m = ob.modifiers.new("Solid", "SOLIDIFY")
    m.thickness = thickness
    m.offset = 1.0
    sb.paint(ob, color or PAL["steel"], roughness=0.4, metallic=0.15)
    return ob


def claw_leg(name, root, pts, radii, claw_dir=(0, 1, -0.4), claw_len=0.45, claw_r=0.09, joints=1.4, color_top=SHELL, color_bot=BODY,
             knee=None, knee_len=0.4, knee_r=0.07, shin=None, shin_seg=1, shin_color=None):
    """Jointed leg from `root` through relative `pts`, with a claw at the tip. joints > 1.4 gives a visible knee knob.
    knee: direction of a bone spike out of the knee (pts[1]). shin: (normal, size) of a plate along segment `shin_seg`."""
    leg = sb.limb(name, pts, radii, location=root, joints=joints)
    gradient(leg, color_top, color_bot)
    t = sb.tip(leg)
    extras = [sb.cone_dir(name + "_claw", (t.x, t.y, t.z), claw_dir, claw_len, claw_r)]
    if knee is not None:
        kd = Vector(knee).normalized()
        kb = Vector(root) + Vector(pts[1]) + kd * (radii[1] * joints * 0.5)
        extras.append(sb.cone_dir(name + "_knee", kb, kd, knee_len, knee_r))
    for e in extras:
        sb.paint(e, PAL["bone"], roughness=0.35)
    if shin is not None:
        a, b = Vector(root) + Vector(pts[shin_seg]), Vector(root) + Vector(pts[shin_seg + 1])
        n = Vector(shin[0]).normalized()
        last = len(pts) - 1
        rad = sum(radii[k] * (joints if 0 < k < last else 1.0) for k in (shin_seg, shin_seg + 1)) / 2
        extras.append(plate_along(name + "_shin", (a + b) / 2 + n * (rad + shin[1][2] * 0.15), n, b - a, shin[1],
                                  shin_color or PAL["steel_dark"], bevel=0.04))
    return sb.join([leg] + extras, name)


def ring_dirs(n, z=0.0, offset=0.0):
    return [(math.cos(offset + i / n * 2 * math.pi), math.sin(offset + i / n * 2 * math.pi), z) for i in range(n)]


# ------------------------------------------------------------------------------------ Walker / Brute
def build_walker(s=1.0, boss=False):
    """Bipedal bug-brute, gorilla stance: wide armoured shoulders, a real horned head with a toothy jaw,
    knuckle-dragging claw arms with fat guarded forearms and elbow spikes, thick short legs with knee spikes.
    About 5 studs tall (Brute: x2.2, a taller hump, shoulder horns, a double spike ridge and a crown of light)."""
    parts = {}
    acc = ACCENT["Brute" if boss else "Walker"]
    top = tint(SHELL, acc, 0.35)
    spheres = [
        (-1.15, 0.0, 3.55, 1.0), (1.15, 0.0, 3.55, 1.0),   # shoulders
        (0, 0.45, 3.15, 1.15),                              # chest
        (0, -0.55, 3.7, 1.05),                              # upper back hump
        (0, 0.1, 2.35, 0.78),                               # waist
    ]
    if boss:
        spheres.append((0, -0.7, 4.4, 1.15))                # taller hump: the boss hunches over its own head
    torso = sb.blob("Torso", spheres, resolution=0.16)
    gradient(torso, top, BODY)
    back1 = (0, -1.1, 4.85) if boss else (0, -0.95, 3.95)
    n1 = Vector((0, -0.6, 0.8)).normalized()
    armour = [
        sb.plate_on("PadL", (-1.25, 0.0, 4.0), (-0.45, 0, 1), (1.7, 1.5, 0.7), PAL["steel"], bevel=0.1),
        sb.plate_on("PadR", (1.25, 0.0, 4.0), (0.45, 0, 1), (1.7, 1.5, 0.7), PAL["steel"], bevel=0.1),
        sb.plate_on("Back1", back1, n1, (1.8, 1.0, 0.5), PAL["steel_dark"], bevel=0.07),
        sb.plate_on("Back2", (0, -1.3, 3.15), (0, -0.95, 0.3), (1.5, 0.9, 0.45), PAL["steel_dark"], bevel=0.07),
        sb.plate_on("Chest", (0, 1.35, 2.75), (0, 1, -0.2), (1.3, 0.7, 0.3), PAL["steel_dark"], bevel=0.06),
    ]
    for i, x in enumerate((-1.55, 1.55)):
        for j, y in enumerate((-0.35, 0.35)):
            sp = sb.cone_dir("PadSpike%d%d" % (i, j), (x, y, 4.2), (x * 0.25, 0, 1), 0.7, 0.12)
            sb.paint(sp, PAL["bone"], roughness=0.35)
            armour.append(sp)
    parts["Torso"] = sb.join([torso] + armour, "Torso")
    # head: metaballs render at ~0.57x their radius, so these are big on purpose
    hp = (0, 1.5, 3.55)
    head = sb.blob("Head", [(hp[0], hp[1], hp[2], 1.2), (hp[0], hp[1] + 0.5, hp[2] - 0.1, 1.0)], resolution=0.12)
    gradient(head, top, BODY)
    hparts = [head]
    if not boss:
        for i, x in enumerate((-0.45, 0.45)):
            h = sb.cone_dir("Horn%d" % i, (x, 1.3, 3.95), (x * 0.5, -0.3, 1), 0.85, 0.14)
            sb.paint(h, PAL["bone"], roughness=0.35)
            hparts.append(h)
        hparts.append(sb.plate_on("Brow", (0, 1.8, 4.05), (0, 0.5, 1), (1.1, 0.55, 0.2), PAL["steel_dark"], bevel=0.05))
    parts["Head"] = sb.join(hparts, "Head")
    parts["Eyes_Glow"] = eyes((0, 2.0, 3.6), acc, 2, 0.48, 0.18, 0.55, 0.1)
    jaw = ellipsoid("Jaw", (0, 2.15, 3.05), (0.55, 0.55, 0.2), BELLY)
    sb.paint(jaw, BELLY, roughness=0.3)
    tx = (-0.36, -0.22, -0.08, 0.08, 0.22, 0.36) if boss else (-0.3, -0.1, 0.1, 0.3)
    tl, tr = (0.5, 0.08) if boss else (0.32, 0.06)
    teeth = [sb.cone_dir("T%d" % i, (x, 2.6 - abs(x) * 0.4, 3.1), (0, 0.35, 1), tl, tr) for i, x in enumerate(tx)]
    for t in teeth:
        sb.paint(t, PAL["bone"])
    parts["Jaw"] = sb.join([jaw] + teeth, "Jaw")
    for side, sx in (("L", -1), ("R", 1)):
        root = Vector((1.75 * sx, 0.1, 3.55))
        pts = [(0, 0, 0), (0.6 * sx, -0.8, -1.0), (0.45 * sx, 0.9, -2.3), (0.25 * sx, 1.45, -2.95)]
        arm = sb.limb("Arm_" + side, pts, [0.5, 0.32, 0.42, 0.28], location=root, joints=1.55)   # fat forearm, knob elbow
        gradient(arm, top, BODY)
        t = sb.tip(arm)
        extras = sb.claws("Claw" + side, (t.x, t.y + 0.1, t.z - 0.05), (0.15 * sx, 0.7, -0.7), 3, 0.75, 0.11, 0.2)
        ed = Vector((0.4 * sx, -1, 0.2)).normalized()
        sp = sb.cone_dir("Elbow" + side, root + Vector(pts[1]) + ed * 0.3, ed, 0.55, 0.1)
        sb.paint(sp, PAL["bone"], roughness=0.35)
        extras.append(sp)
        gn = Vector((sx, 0, 0.3)).normalized()
        mid = root + (Vector(pts[1]) + Vector(pts[2])) / 2
        extras.append(plate_along("Guard" + side, mid + gn * 0.62, gn, Vector(pts[2]) - Vector(pts[1]), (0.7, 1.1, 0.28), PAL["steel_dark"], bevel=0.06))
        parts["Arm_" + side] = sb.join([arm] + extras, "Arm_" + side)
        lroot = Vector((0.65 * sx, -0.05, 2.2))
        lpts = [(0, 0, 0), (0.2 * sx, 0.45, -0.95), (0.15 * sx, -0.05, -1.8), (0.15 * sx, 0.55, -2.05)]
        leg = sb.limb("Leg_" + side, lpts, [0.48, 0.32, 0.36, 0.28], location=lroot, joints=1.5)
        gradient(leg, top, BODY)
        ft = sb.tip(leg)
        lextras = sb.claws("Toe" + side, (ft.x, ft.y + 0.2, ft.z - 0.05), (0, 1, -0.15), 3, 0.5, 0.1, 0.22)
        kd = Vector((0.3 * sx, 1, 0.3)).normalized()
        ks = sb.cone_dir("Knee" + side, lroot + Vector(lpts[1]) + kd * 0.3, kd, 0.45, 0.09)
        sb.paint(ks, PAL["bone"], roughness=0.35)
        lextras.append(ks)
        ln = Vector((0.5 * sx, 1, 0.2)).normalized()
        lmid = lroot + (Vector(lpts[1]) + Vector(lpts[2])) / 2
        lextras.append(plate_along("Shin" + side, lmid + ln * 0.55, ln, Vector(lpts[2]) - Vector(lpts[1]), (0.6, 0.8, 0.24), PAL["steel_dark"], bevel=0.05))
        if boss:
            tn = Vector((sx, 0.2, 0.3)).normalized()
            tmid = lroot + Vector(lpts[1]) / 2
            lextras.append(plate_along("Thigh" + side, tmid + tn * 0.55, tn, Vector(lpts[1]), (0.6, 0.8, 0.22), PAL["steel"], bevel=0.05))
        parts["Leg_" + side] = sb.join([leg] + lextras, "Leg_" + side)
    # accent: a slot in the chest plate (not a ball under the eyes), seams on the pads, a glowing spine seam on the back
    core = sb.box("Core", (0.55, 0.14, 0.16), (0, 1.55, 2.72), (math.radians(-11), 0, 0), bevel=0.02)
    sb.paint(core, acc, emission=2.5)
    glow = [core]
    for i, x in enumerate((-1.35, 1.35)):
        sm = sb.box("Seam%d" % i, (0.9, 0.08, 0.08), (x, 0.55, 4.43), (0, 0, 0), bevel=0)
        sb.paint(sm, acc, emission=GLOW_THIN)
        glow.append(sm)
    spine = plate_along("Spine", Vector(back1) + n1 * 0.32, n1, (0, -1, -0.4), (0.14, 1.2 if boss else 0.8, 0.1), acc, bevel=0.0, sink=0.5)
    sb.paint(spine, acc, emission=GLOW_THIN)
    glow.append(spine)
    if boss:
        n2 = Vector((0, -0.95, 0.3)).normalized()
        sp2 = plate_along("Spine2", Vector((0, -1.3, 3.15)) + n2 * 0.29, n2, (0, -0.3, -1), (0.14, 0.7, 0.1), acc, bevel=0.0, sink=0.5)
        sb.paint(sp2, acc, emission=GLOW_THIN)
        glow.append(sp2)
    parts["Core_Glow"] = sb.join(glow, "Core_Glow")
    if boss:
        spikes = []
        for i in range(7):   # main ridge over the hump: longest in the middle, swept back
            a = (i / 6) * math.pi
            p, nrm = sb.on_ellipsoid((0, -0.6, 4.35), (1.65, 1.0, 0.95), (math.cos(a), -0.6, 0.2 + math.sin(a)))
            d = Vector((math.cos(a) * 0.7, -0.8, 0.25 + math.sin(a) * 0.7))
            sp = sb.cone_dir("Spike%d" % i, p - nrm * 0.2, d, 1.2 + 0.6 * math.sin(a), 0.17 + 0.08 * math.sin(a))
            sb.paint(sp, PAL["bone"], roughness=0.35)
            spikes.append(sp)
        for i, x in enumerate((-0.6, -0.3, 0.0, 0.3, 0.6)):   # second, shorter row on the lower back plate
            sp = sb.cone_dir("Spike2%d" % i, (x, -1.45, 3.05 + 0.25 * (1 - abs(x) / 0.6)), (x * 0.5, -0.9, 0.35), 0.8 - 0.2 * abs(x), 0.12)
            sb.paint(sp, PAL["bone"], roughness=0.35)
            spikes.append(sp)
        for sx in (-1, 1):
            h = sb.cone_dir("ShoulderHorn%d" % (sx + 1), (1.65 * sx, 0, 4.25), (0.7 * sx, -0.2, 1), 2.0, 0.3)
            sb.paint(h, PAL["bone"], roughness=0.35)
            spikes.append(h)
        parts["Torso"] = sb.join([parts["Torso"]] + spikes, "Torso")
        # crown of light: a ring that sits on the brow with five glowing spikes rising from it
        cc = Vector((0, 1.55, 4.02))
        R = Matrix.Rotation(math.radians(12), 3, "X")
        crown = sb.torus("Crown", 0.66, 0.12, cc, (math.radians(12), 0, 0))
        sb.paint(crown, acc, emission=1.4)   # red clips to pink above ~1.5
        cparts = [crown]
        for i in range(5):
            a = math.radians(-100 + 50 * i)
            d = Vector((math.sin(a), math.cos(a), 0))
            sp = sb.cone_dir("CrownSpike%d" % i, cc + R @ (d * 0.66), R @ (d * 0.35 + Vector((0, 0, 1))), 0.75, 0.1)
            sb.paint(sp, acc, emission=1.7)
            cparts.append(sp)
        parts["Crown_Glow"] = sb.join(cparts, "Crown_Glow")
    return scale_parts(parts, s)


# ------------------------------------------------------------------------------------ Runner
def build_runner(s=1.0):
    """Low four-legged sprinter: segmented insect body under three steel shingles, a spined back with glowing
    tips and a glowing tail tip, an armoured skull with long crossed mandibles, blade legs with knee knobs and
    knee blades. 2.5 studs tall, about 6 long."""
    parts = {}
    acc = ACCENT["Runner"]
    top = tint(SHELL, acc, 0.35)
    th_c, th_r = [(0, 0.7, 1.35), (0, 0.0, 1.4), (0, -0.7, 1.4)], [0.55, 0.62, 0.55]
    thorax = sb.segments("Thorax", th_c, th_r, squash=0.9)
    gradient(thorax, top, BODY)
    ab_c, ab_r = [(0, -1.45, 1.45), (0, -2.05, 1.5), (0, -2.55, 1.55)], [0.5, 0.42, 0.32]
    abdomen = sb.segments("Abdomen", ab_c, ab_r, squash=0.9)
    gradient(abdomen, top, BODY)
    tail = sb.cone_dir("Tail", (0, -2.7, 1.6), (0, -1, 0.35), 1.1, 0.22)
    sb.paint(tail, BODY)
    spines, tips = [], []
    sd = Vector((0, -0.35, 1)).normalized()
    for i, (y, z) in enumerate(((0.7, 1.9), (0.0, 1.97), (-0.7, 1.9), (-1.45, 1.92), (-2.05, 1.9))):
        L = 0.6 - i * 0.05
        sp = sb.cone_dir("Spine%d" % i, (0, y, z - 0.15), sd, L, 0.1)
        sb.paint(sp, PAL["bone"], roughness=0.35)
        spines.append(sp)
        tips.append(Vector((0, y, z - 0.15)) + sd * (L - 0.05))
    plates = []
    for i, (c, r) in enumerate(zip(th_c, th_r)):   # one flat shingle per thorax segment, sunk into the shell
        plates += sb.plates_on("Shell%d_" % i, c, (r, r, r * 0.9), [(0, 0.3, 1)], (0.85, 0.75, 0.12), PAL["steel_dark"], bevel=0.03)
    parts["Torso"] = sb.join([thorax, abdomen, tail] + spines + plates, "Torso")
    head = ellipsoid("Head", (0, 1.45, 1.4), (0.52, 0.72, 0.46))
    gradient(head, PAL["steel"], BODY)   # grey skull so the head reads apart from the purple thorax
    crest = sb.plate_on("Crest", (0, 1.5, 1.78), (0, 0.4, 1), (0.6, 0.7, 0.14), PAL["steel_dark"], bevel=0.03)
    mand = []
    for sx in (-1, 1):
        m = sb.cone_dir("Mand%d" % (sx + 1), (0.36 * sx, 2.0, 1.28), (-0.3 * sx, 1, -0.1), 1.1, 0.13)
        sb.paint(m, PAL["bone"], roughness=0.35)
        mand.append(m)
    ant = []
    for sx in (-1, 1):
        a = sb.limb("Ant%d" % (sx + 1), [(0, 0, 0), (0.35 * sx, 0.3, 0.5), (0.7 * sx, 0.1, 0.9)], [0.05, 0.04, 0.02], location=(0.2 * sx, 1.6, 1.75), subdiv=1, joints=1.0)
        sb.paint(a, BODY)
        ant.append(a)
    parts["Head"] = sb.join([head, crest] + mand + ant, "Head")
    parts["Eyes_Glow"] = eyes((0, 1.75, 1.52), acc, 4, 0.2, 0.08, 0.35, 0.08, curve=0.3)
    jaw = ellipsoid("Jaw", (0, 1.85, 1.1), (0.32, 0.42, 0.15), BELLY)
    teeth = [sb.cone_dir("T%d" % i, (x, 2.12, 1.15), (0, 0.3, 1), 0.22, 0.05) for i, x in enumerate((-0.15, 0, 0.15))]
    for t in teeth:
        sb.paint(t, PAL["bone"])
    parts["Jaw"] = sb.join([jaw] + teeth, "Jaw")
    n = 1
    for y in (0.6, -0.8):
        for sx in (-1, 1):
            parts["Leg_%d" % n] = claw_leg("Leg_%d" % n, (0.45 * sx, y, 1.3),
                                           [(0, 0, 0), (0.6 * sx, 0.1, 0.1), (0.85 * sx, -0.1, -0.7), (0.6 * sx, 0.2, -1.25)],
                                           [0.24, 0.18, 0.15, 0.08], claw_dir=(0.2 * sx, 0.4, -1), claw_len=0.4, claw_r=0.09, joints=1.5,
                                           knee=(0.3 * sx, -0.3, 1), knee_len=0.45, knee_r=0.07, color_top=top)
            n += 1
    glow = []
    for i, (c, r) in enumerate(zip(ab_c, ab_r)):   # teal dots on the abdomen flanks, on the surface this time
        for sx in (-1, 1):
            p, nrm = sb.on_ellipsoid(c, (r, r, r * 0.9), (sx, 0, 0.35))
            d = sb.sphere("Dot%d%d" % (i, sx + 1), 0.09, p + nrm * 0.02, subdiv=1)
            sb.paint(d, acc, emission=GLOW_EYE_SMALL)
            glow.append(d)
    for i, t in enumerate(tips):
        g = sb.sphere("SpineTip%d" % i, 0.06, t, subdiv=1)
        sb.paint(g, acc, emission=GLOW_THIN)
        glow.append(g)
    tt = sb.cone_dir("TailTip", (0, -3.55, 1.9), (0, -1, 0.35), 0.45, 0.12)
    sb.paint(tt, acc, emission=2.5)
    glow.append(tt)
    parts["Dots_Glow"] = sb.join(glow, "Dots_Glow")
    return scale_parts(parts, s)


# ------------------------------------------------------------------------------------ Flyer
def build_flyer(s=1.0):
    """Wasp-lantern: dark segmented body ending in a fat glowing lantern, glow bands sunk into the shell, a glowing
    stinger tip, a horned armoured head, four translucent wings each with a glowing leading-edge vein, four
    clawed legs. About 2.5 studs, hovers."""
    parts = {}
    acc = ACCENT["Flyer"]
    top = tint(SHELL, acc, 0.35)
    thorax = ellipsoid("Thorax", (0, 0.1, 2.3), (0.5, 0.62, 0.5), BODY)
    gradient(thorax, top, BODY)
    ab_c, ab_r = [(0, -0.75, 2.2), (0, -1.3, 2.1)], [0.45, 0.4]
    abdomen = sb.segments("Abdomen", ab_c, ab_r, squash=0.95)
    gradient(abdomen, top, BODY)
    sd = Vector((0, -1, -0.5)).normalized()
    stinger = sb.cone_dir("Stinger", (0, -2.2, 1.85), sd, 0.8, 0.12)
    sb.paint(stinger, PAL["bone"], roughness=0.35)
    plates = sb.plates_on("Shell", (0, 0.1, 2.3), (0.5, 0.62, 0.5), [(0, 0.2, 1), (0, -0.7, 1)], (0.55, 0.45, 0.16), PAL["steel_dark"], bevel=0.03)
    legs = []
    for i, (sx, y) in enumerate(((-1, 0.3), (1, 0.3), (-1, -0.2), (1, -0.2))):
        l = sb.limb("Lg%d" % i, [(0, 0, 0), (0.35 * sx, 0.1, -0.35), (0.25 * sx, 0.25, -0.75)], [0.12, 0.09, 0.05], location=(0.35 * sx, y, 1.95), joints=1.3)
        gradient(l, top, BODY)
        t = sb.tip(l)
        cl = sb.cone_dir("LgClaw%d" % i, t, (0.1 * sx, 0.3, -1), 0.2, 0.05)
        sb.paint(cl, PAL["bone"], roughness=0.35)
        legs += [l, cl]
    parts["Torso"] = sb.join([thorax, abdomen, stinger] + plates + legs, "Torso")
    core = sb.sphere("Core", 0.52, (0, -1.85, 2.0), subdiv=3)   # the lantern: the tell at range
    sb.paint(core, acc, emission=GLOW_BIG)
    glow = [core]
    for i, (c, r) in enumerate(zip(ab_c, ab_r)):   # bands sit in the shell, major = segment radius - 0.03
        b = sb.torus("Band%d" % i, r - 0.03, 0.06, c, (math.radians(90), 0, 0))
        sb.paint(b, acc, emission=GLOW_THIN)
        glow.append(b)
    st = sb.cone_dir("StingerTip", Vector((0, -2.2, 1.85)) + sd * 0.45, sd, 0.36, 0.06)
    sb.paint(st, acc, emission=2.5)
    glow.append(st)
    parts["Core_Glow"] = sb.join(glow, "Core_Glow")
    head = ellipsoid("Head", (0, 0.85, 2.35), (0.36, 0.38, 0.34), BODY)
    gradient(head, top, BODY)
    brow = sb.plate_on("Brow", (0, 1.0, 2.64), (0, 0.4, 1), (0.6, 0.35, 0.12), PAL["steel_dark"], bevel=0.03)
    horns = [sb.cone_dir("Horn%d" % (sx + 1), (0.2 * sx, 0.9, 2.6), (sx * 0.4, -0.4, 1), 0.45, 0.07) for sx in (-1, 1)]
    ant = []
    for sx in (-1, 1):
        a = sb.limb("Ant%d" % (sx + 1), [(0, 0, 0), (0.3 * sx, 0.35, 0.45), (0.55 * sx, 0.5, 0.8)], [0.05, 0.04, 0.02], location=(0.15 * sx, 1.0, 2.6), joints=1.0)
        sb.paint(a, BODY)
        ant.append(a)
    mand = [sb.cone_dir("Mand%d" % (sx + 1), (0.18 * sx, 1.15, 2.2), (-0.3 * sx, 1, -0.2), 0.35, 0.06) for sx in (-1, 1)]
    for m in mand + horns:
        sb.paint(m, PAL["bone"], roughness=0.35)
    parts["Head"] = sb.join([head, brow] + horns + ant + mand, "Head")
    parts["Eyes_Glow"] = eyes((0, 0.95, 2.42), acc, 2, 0.4, 0.15, 0.22, 0.02)
    wing_col = (0.95, 0.9, 0.7, 1.0)
    for i, (sx, sy, yaw) in enumerate(((1, 1, 25), (-1, 1, 155), (1, -1, -25), (-1, -1, 205))):
        loc = (0.35 * sx, 0.15 + 0.15 * sy, 2.75)
        rot = (0, math.radians(-18 * sx), math.radians(yaw))
        w = sb.wing("Wing_%d" % (i + 1), 2.3, 0.85, loc, rot, thickness=0.03, taper=0.4)
        sb.paint(w, wing_col, roughness=0.15, alpha=0.5)
        vein = sb.limb("Vein%d" % i, [(0, 0, 0), (1.2, 0.12, 0), (2.25, 0.02, 0)], [0.07, 0.05, 0.02], location=loc, joints=1.0)
        vein.rotation_euler = rot
        sb.paint(vein, acc, emission=1.5)   # a glowing bone along the wing so it does not vanish when translucent
        parts["Wing_%d" % (i + 1)] = sb.join([w, vein], "Wing_%d" % (i + 1))
    return scale_parts(parts, s)


# ------------------------------------------------------------------------------------ Tank
def build_tank(s=1.0):
    """Beetle: tall green-tinted chitin dome under two curved steel elytra split by a glowing seam, a steel
    pronotum, a skirt of rim spikes over a glow ring, a big horned head with pincers, six thick knee-jointed legs
    with shin guards. About 3.8 studs tall."""
    parts = {}
    acc = ACCENT["Tank"]
    top = tint(SHELL, acc, 0.35)
    c, r = (0, 0, 1.9), (1.8, 2.1, 1.7)
    dome = ellipsoid("Dome", c, r, BODY)
    for v in dome.data.vertices:          # flatten only the very bottom (world z < 0.7): a dome, not a dish
        if v.co.z < 0.7 - c[2]:
            v.co.z = 0.7 - c[2]
    gradient(dome, top, BODY)
    elytra = [shell_cap("Elytron%d" % (sx + 1), c, r, [((0, 0, -0.15), (0, 0, 1)), ((0, 0.55, 0), (0, -1, 0)), ((0.07 * sx, 0, 0), (sx, 0, 0))], 0.22,
                        tint(PAL["steel"], acc, 0.3)) for sx in (-1, 1)]
    pronotum = shell_cap("Pronotum", c, r, [((0, 0, 0.35), (0, 0, 1)), ((0, 0.75, 0), (0, 1, 0))], 0.2)
    spikes = sb.spikes_on("RimSpike", c, r, ring_dirs(8, -0.1, 0.2), 0.9, 0.16)   # just under the elytra edge
    parts["Torso"] = sb.join([dome, pronotum] + elytra + spikes, "Torso")
    split = []
    for i, t in enumerate((-1.0, -0.62, -0.25, 0.1, 0.42)):   # the beetle split, flush with the elytra
        p, nrm = sb.on_ellipsoid(c, r, (0, t, 1))
        sp = plate_along("Split%d" % i, p + nrm * 0.28, nrm, (0, 1, 0), (0.12, 0.62, 0.14), acc, bevel=0.0, sink=0.5)
        sb.paint(sp, acc, emission=GLOW_THIN)
        split.append(sp)
    ring = sb.torus("Rim", 1.0, 0.09, (0, 0, 1.5))
    ring.scale = (1.74, 2.03, 1.0)   # ellipsoid half-widths at z=1.5, so it half-sinks into the skirt
    sb.apply_transforms(ring)
    sb.paint(ring, acc, emission=GLOW_THIN)
    parts["Seam_Glow"] = sb.join([ring] + split, "Seam_Glow")
    head = ellipsoid("Head", (0, 2.45, 1.15), (0.8, 0.75, 0.6), BODY)
    gradient(head, top, BODY)
    horn = sb.cone_dir("Horn", (0, 2.7, 1.55), (0, 0.6, 1), 1.4, 0.2)   # rhino horn: the one feature that says beetle at 40 studs
    hplate = sb.plate_on("HeadPlate", (0, 2.4, 1.68), (0, 0.3, 1), (1.0, 0.8, 0.18), PAL["steel"], bevel=0.04)
    pincers = [sb.cone_dir("P%d" % (sx + 1), (0.45 * sx, 2.95, 0.95), (-0.5 * sx, 1, -0.1), 1.3, 0.16) for sx in (-1, 1)]
    for p in [horn] + pincers:
        sb.paint(p, PAL["bone"], roughness=0.35)
    parts["Head"] = sb.join([head, horn, hplate] + pincers, "Head")
    parts["Eyes_Glow"] = eyes((0, 2.75, 1.3), acc, 2, 0.4, 0.12, 0.4, 0.05)
    n = 1
    for y in (1.15, 0.0, -1.15):
        for sx in (-1, 1):
            parts["Leg_%d" % n] = claw_leg("Leg_%d" % n, (1.2 * sx, y, 1.15),
                                           [(0, 0, 0), (0.8 * sx, 0.05, 0.15), (1.05 * sx, 0.0, -0.75), (0.85 * sx, 0.15, -1.1)],
                                           [0.32, 0.24, 0.26, 0.12], claw_dir=(0.3 * sx, 0.3, -1), claw_len=0.5, claw_r=0.09, joints=1.5,
                                           knee=(0.6 * sx, 0, 1), knee_len=0.35, knee_r=0.07, shin=((sx, 0, 0.4), (0.4, 0.7, 0.2)), color_top=top)
            n += 1
    return scale_parts(parts, s)


# ------------------------------------------------------------------------------------ Spitter
def build_spitter(s=1.0):
    """Hunched bug with three boiling acid sacs down its spine set in chitin collars, a flesh-pink belly, a glowing
    throat ring and a wide maw with an acid spout. 3.6 studs tall."""
    parts = {}
    acc = ACCENT["Spitter"]
    top = tint(SHELL, acc, 0.3)
    belly = rgb(200, 95, 160)
    bc, br = (0, -0.3, 2.0), (0.95, 0.95, 0.85)
    body = sb.segments("Body", [(0, 0.55, 1.7), bc, (0, -1.15, 2.05)], [0.8, 0.95, 0.78], squash=0.9)
    gradient(body, top, belly)
    plates = sb.plates_on("Shell", bc, br, [(0.65, 0.55, 0.5), (-0.65, 0.55, 0.5)], (0.8, 0.9, 0.25), PAL["steel_dark"], bevel=0.05)
    spikes = sb.spikes_on("Spk", (0, -1.15, 2.05), (0.78, 0.78, 0.7), [(0.5, -0.5, 0.7), (-0.5, -0.5, 0.7), (0, -0.9, 0.5)], 0.6, 0.1)
    sacs, collars = [], []
    bubble_col = tint(acc, PAL["white"], 0.45)
    for i, (d, rad) in enumerate((((0, 0.6, 1), 0.5), ((0, -0.1, 1), 0.42), ((0, -0.8, 1), 0.34), ((-0.7, -0.05, 0.75), 0.24), ((0.7, -0.05, 0.75), 0.24))):
        p, nrm = sb.on_ellipsoid(bc, br, d)
        cp = p + nrm * (rad * 0.1)   # half-buried, not perched
        sc = sb.sphere("Sac%d" % i, rad, cp, subdiv=2)
        sb.paint(sc, acc, emission=1.3)   # purple clips to white above ~1.5
        sacs.append(sc)
        col = torus_lr("Collar%d" % i, rad * 0.95, 0.07, p + nrm * 0.02, nrm.to_track_quat("Z", "Y").to_euler())
        sb.paint(col, BODY)
        collars.append(col)
        for j in range(3):   # bubbles: boiling acid
            a = 0.9 + j * 2.1 + i
            bd = Vector((math.cos(a) * 0.6, math.sin(a) * 0.6, 0.55)).normalized()
            bb = sb.sphere("Bub%d%d" % (i, j), rad * 0.22, cp + bd * rad, subdiv=1)
            sb.paint(bb, bubble_col, emission=1.6)
            sacs.append(bb)
    parts["Torso"] = sb.join([body] + plates + spikes + collars, "Torso")
    throat = sb.torus("Throat", 0.62, 0.09, (0, 1.05, 1.62), (math.radians(90), 0, 0))   # accent visible from the front
    sb.paint(throat, acc, emission=GLOW_THIN)
    parts["Sacs_Glow"] = sb.join(sacs + [throat], "Sacs_Glow")
    head = ellipsoid("Head", (0, 1.45, 1.55), (0.55, 0.55, 0.45), BODY)
    gradient(head, top, BODY)
    brow = sb.plate_on("Brow", (0, 1.6, 1.9), (0, 0.4, 1), (1.0, 0.55, 0.2), PAL["steel_dark"], bevel=0.04)
    parts["Head"] = sb.join([head, brow], "Head")
    parts["Eyes_Glow"] = eyes((0, 1.55, 1.72), acc, 3, 0.3, 0.1, 0.4, 0.06, curve=0.25)
    maw = ellipsoid("Jaw", (0, 1.7, 1.05), (0.72, 0.55, 0.3), BELLY)
    sb.paint(maw, belly, roughness=0.3)
    spout = sb.cylinder("Spout", 0.2, 0.5, (0, 2.1, 1.32), (math.radians(90), 0, 0), verts=12)
    sb.paint(spout, acc, emission=2.5)
    teeth = [sb.cone_dir("T%d" % i, (x, 2.1 - abs(x) * 0.25, 1.22), (0, 0.25, 1), 0.3, 0.06) for i, x in enumerate((-0.5, -0.3, 0.3, 0.5))]
    for t in teeth:
        sb.paint(t, PAL["bone"])
    parts["Jaw"] = sb.join([maw, spout] + teeth, "Jaw")
    n = 1
    for y in (0.7, -0.7):
        for sx in (-1, 1):
            parts["Leg_%d" % n] = claw_leg("Leg_%d" % n, (0.75 * sx, y, 1.45),
                                           [(0, 0, 0), (0.75 * sx, 0.1, 0.05), (1.0 * sx, -0.1, -0.85), (0.75 * sx, 0.2, -1.35)],
                                           [0.3, 0.2, 0.24, 0.1], claw_dir=(0.2 * sx, 0.4, -1), claw_len=0.35, claw_r=0.08, joints=1.5,
                                           knee=(0.5 * sx, 0, 1), knee_len=0.35, knee_r=0.06, color_top=top)
            n += 1
    return scale_parts(parts, s)


# ------------------------------------------------------------------------------------ Queen
def build_queen(s=1.0):
    """A walking nest: armoured thorax with a steel collar, a huge ribbed abdomen with glowing eggs set in chitin
    sockets, girdles between its segments and bone ribs arching up its flanks, a crowned head with long mandibles,
    six long knee-jointed legs with shin plates. About 15 studs long, 7 tall."""
    parts = {}
    acc = ACCENT["Queen"]
    top = tint(SHELL, acc, 0.35)
    thorax = sb.segments("Thorax", [(0, 1.0, 4.0), (0, -0.4, 4.2)], [1.3, 1.5], squash=0.9)
    gradient(thorax, top, BODY)
    plates = sb.plates_on("Shell", (0, -0.4, 4.2), (1.5, 1.5, 1.35), [(0, 0.3, 1), (0.7, -0.2, 0.9), (-0.7, -0.2, 0.9)], (1.4, 1.3, 0.4), PAL["steel_dark"], bevel=0.07)
    spikes = sb.spikes_on("Spk", (0, -0.4, 4.2), (1.5, 1.5, 1.35), [(0.5, -0.6, 0.8), (-0.5, -0.6, 0.8), (0, -0.2, 1)], 1.2, 0.18)
    collar = sb.plate_on("Collar", (0, 1.9, 4.65), (0, 0.5, 1), (2.0, 0.8, 0.3), PAL["steel"], bevel=0.06)
    parts["Torso"] = sb.join([thorax, collar] + plates + spikes, "Torso")
    abd_c = [(0, -2.6, 4.3), (0, -4.6, 4.4), (0, -6.5, 4.3), (0, -7.8, 4.2)]
    abd_r = [2.2, 2.6, 2.0, 1.3]
    abdomen = sb.segments("Abdomen", abd_c, abd_r, squash=0.92, subdiv=3)
    gradient(abdomen, top, BELLY)
    tail = sb.cone_dir("Tail", (0, -8.6, 4.1), (0, -1, -0.2), 2.0, 0.5)
    sb.paint(tail, BODY)
    extra = [tail]
    for i in range(3):   # girdles: chitin rings in the creases between segments
        (c0, r0), (c1, r1) = (abd_c[i], abd_r[i]), (abd_c[i + 1], abd_r[i + 1])
        ym = (c0[1] + c1[1]) / 2
        rad = max(r0 * math.sqrt(max(1 - ((ym - c0[1]) / r0) ** 2, 0)), r1 * math.sqrt(max(1 - ((ym - c1[1]) / r1) ** 2, 0)))
        g = torus_lr("Girdle%d" % i, rad + 0.02, 0.16, (0, ym, (c0[2] + c1[2]) / 2), (math.radians(90), 0, 0), maj_seg=28, min_seg=8)
        g.scale = (1, 0.92, 1)   # local Y is world Z after the 90 deg turn: match the segment squash
        sb.apply_transforms(g)
        sb.paint(g, top)
        extra.append(g)
    for yi in range(3):   # bone ribs arching up each flank: the cage silhouette
        c, r = abd_c[yi], abd_r[yi]
        for sx in (-1, 1):
            pts = []
            for a in (8, 28, 48, 64):
                p, nrm = sb.on_ellipsoid(c, (r, r, r * 0.92), (sx * math.cos(math.radians(a)), 0, math.sin(math.radians(a))))
                pts.append(p + nrm * 0.18)
            rib = sb.limb("Rib%d%d" % (yi, sx + 1), [tuple(p - pts[0]) for p in pts], [0.28, 0.25, 0.2, 0.1], location=tuple(pts[0]), joints=1.0)
            sb.apply_modifiers(rib)
            sb.paint(rib, PAL["bone"], roughness=0.35)
            extra.append(rib)
        extra += sb.plates_on("AbdPlate%d_" % yi, c, (r, r, r * 0.92), [(0, 0.15, 1)], (1.3, 1.1, 0.25), PAL["steel_dark"], bevel=0.05)
    eggs, sockets = [], []
    k = 0
    for c, r, er in zip(abd_c[:3], abd_r[:3], (0.6, 0.48, 0.34)):
        for d in ring_dirs(7, 0.55, k * 0.4):
            p, nrm = sb.on_ellipsoid(c, (r, r, r * 0.92), (d[0], d[2], d[1]))  # ring around the Y axis
            e = sb.sphere("Egg%d" % k, er, p - nrm * (er * 0.15), subdiv=2)   # half-buried windows
            sb.paint(e, acc, emission=1.4)   # purple clips to white above ~1.5
            eggs.append(e)
            sk = torus_lr("Socket%d" % k, er * 0.95, 0.09, p + nrm * 0.02, nrm.to_track_quat("Z", "Y").to_euler(), maj_seg=16, min_seg=6)
            sb.paint(sk, BODY)
            sockets.append(sk)
            k += 1
    parts["Abdomen"] = sb.join([abdomen] + extra + sockets, "Abdomen")
    parts["Eggs_Glow"] = sb.join(eggs, "Eggs_Glow")
    head = ellipsoid("Head", (0, 2.7, 4.1), (1.15, 1.2, 1.0), BODY)
    gradient(head, top, BODY)
    hparts = [head]
    cc = Vector((0, 2.7, 4.6))
    for i, d in enumerate(ring_dirs(6, 1.2, 0.3)):   # crown: six bone spikes fanning out of a steel band
        dv = Vector(d).normalized()
        sp = sb.cone_dir("C%d" % i, cc + dv * 0.55, (d[0], d[1], 1.0), 1.4, 0.16)
        sb.paint(sp, PAL["bone"], roughness=0.35)
        hparts.append(sp)
    band = sb.torus("CrownBand", 0.88, 0.12, (0, 2.7, 4.8))
    sb.paint(band, PAL["steel"], roughness=0.4, metallic=0.15)
    hparts.append(band)
    for sx in (-1, 1):
        m = sb.cone_dir("M%d" % (sx + 1), (0.7 * sx, 3.5, 3.8), (-0.45 * sx, 1, -0.2), 2.0, 0.22)
        sb.paint(m, PAL["bone"], roughness=0.35)
        hparts.append(m)
    parts["Head"] = sb.join(hparts, "Head")
    cg = sb.torus("CrownRing", 0.64, 0.06, (0, 2.7, 4.98))
    sb.paint(cg, acc, emission=GLOW_THIN)
    parts["Eyes_Glow"] = sb.join([eyes((0, 3.3, 4.4), acc, 4, 0.36, 0.13, 0.55, 0.12, curve=0.2), cg], "Eyes_Glow")
    n = 1
    for y in (1.6, 0.2, -1.2):
        for sx in (-1, 1):
            parts["Leg_%d" % n] = claw_leg("Leg_%d" % n, (1.3 * sx, y, 3.9),
                                           [(0, 0, 0), (1.7 * sx, 0.1, 1.1), (3.1 * sx, -0.1, -0.6), (3.3 * sx, 0.3, -3.6)],
                                           [0.48, 0.32, 0.38, 0.14], claw_dir=(0.2 * sx, 0.3, -1), claw_len=0.6, claw_r=0.12, joints=1.5,
                                           knee=(0.2 * sx, 0, 1), knee_len=0.6, knee_r=0.12, shin=((sx, 0, 0.3), (0.5, 1.4, 0.25)), shin_seg=2, color_top=top)
            n += 1
    return scale_parts(parts, s)


# ------------------------------------------------------------------------------------ Warden / Sky King
def build_warden(s=1.0):
    """The Sky King: a great glowing eye with a pupil, an iris ring, a heavy brow and a lower lid, set in an armoured
    body that hangs 8 studs up under a spiked halo on a steel frame; four feathered wings with glowing blue tips,
    hanging talons. About 17 studs across."""
    parts = {}
    acc = ACCENT["Warden"]
    top = tint(SHELL, acc, 0.35)
    c, r = (0, 0, 8.5), (2.2, 2.0, 1.8)
    cz = c[2]
    body = ellipsoid("Body", c, r, BODY)
    gradient(body, top, BODY)
    plates = sb.plates_on("Plate", c, r, [(1, 0.15, 0.15), (-1, 0.15, 0.15), (0.6, -0.8, 0.2), (-0.6, -0.8, 0.2)], (1.6, 1.7, 0.45), PAL["steel"], bevel=0.08)
    back = sb.spikes_on("SpkB", c, r, [(math.cos(math.radians(a)), math.sin(math.radians(a)), 0.8) for a in (125, 160, 200, 235)] + [(0, -1, 0.3)], 2.0, 0.22)
    front = sb.spikes_on("SpkF", c, r, [(1, 0.5, 0.7), (-1, 0.5, 0.7)], 1.0, 0.16)
    brow = sb.plate_on("Lid", (0, 2.0, cz + 1.6), (0, 0.55, 1), (3.0, 1.1, 0.35), PAL["steel_dark"], bevel=0.08)
    lower = sb.plate_on("LidLow", (0, 2.0, cz - 1.55), (0, 0.5, -1), (2.6, 0.8, 0.3), PAL["steel_dark"], bevel=0.06)
    lashes = [sb.cone_dir("Lash%d" % i, (x, 2.05, cz + 1.75), (x * 0.3, 0.45, 1), 0.8, 0.1) for i, x in enumerate((-0.9, 0, 0.9))]
    for l in lashes:
        sb.paint(l, PAL["bone"], roughness=0.35)
    hc = Vector((0, 0, cz + 1.5))
    R = Matrix.Rotation(math.radians(8), 3, "X")
    frame = sb.torus("HaloFrame", 3.2, 0.1, hc, (math.radians(8), 0, 0))
    sb.paint(frame, PAL["steel"], roughness=0.45, metallic=0.2)
    struts = []
    for i, d in enumerate(ring_dirs(4, 0, math.pi / 4)):   # the halo hangs on an armoured collar, not in mid-air
        p, nrm = sb.on_ellipsoid(c, r, (d[0], d[1], 0.75))
        struts.append(bar("Strut%d" % i, p - nrm * 0.1, hc + R @ Vector((d[0] * 3.2, d[1] * 3.2, 0)), 0.14, PAL["steel"]))
    parts["Torso"] = sb.join([body, brow, lower, frame] + plates + back + front + lashes + struts, "Torso")
    eye = sb.sphere("Eye_Glow", 1.7, (0, 1.45, cz), subdiv=3)   # pokes ~1.2 studs out of the body: it IS the front
    sb.paint(eye, acc, emission=1.6)
    parts["Eye_Glow"] = eye
    pupil = sb.sphere("Pupil", 0.8, (0, 2.72, cz), subdiv=2)
    sb.paint(pupil, PAL["rubber"], roughness=0.25)
    parts["Pupil"] = pupil
    iris = sb.torus("Iris_Glow", 1.05, 0.1, (0, 2.8, cz), (math.radians(90), 0, 0))
    sb.paint(iris, tint(acc, PAL["white"], 0.6), emission=2.2)
    parts["Iris_Glow"] = iris
    halo = sb.torus("Halo", 3.6, 0.26, hc, (math.radians(8), 0, 0))
    sb.paint(halo, acc, emission=1.4)   # fat blue ring clips to white above ~1.5
    inner = sb.torus("HaloInner", 2.75, 0.1, hc, (math.radians(8), 0, 0))
    sb.paint(inner, acc, emission=1.8)
    hparts = [halo, inner]
    for i in range(6):
        a = i / 6 * 2 * math.pi + math.pi / 6
        d = Vector((math.cos(a), math.sin(a), 0))
        sp = sb.cone_dir("HaloSpike%d" % i, hc + R @ (d * 3.75), R @ Vector((d.x, d.y, 0.12)), 0.9, 0.14)
        sb.paint(sp, acc, emission=1.8)
        hparts.append(sp)
    parts["Halo_Glow"] = sb.join(hparts, "Halo_Glow")
    for i, (sx, sy, yaw) in enumerate(((1, 1, 20), (-1, 1, 160), (1, -1, -30), (-1, -1, 210))):
        root = (1.9 * sx, 0.5 * sy, cz + 0.9)
        feathers = []
        for k, (L, W) in enumerate(((7.0, 1.7), (5.8, 1.6), (4.4, 1.5))):   # three feathers fanning toward the side
            rot = (0, math.radians(-22 * sx - 5 * k * sx), math.radians(yaw - 11 * k * sx * sy))
            feathers.append(sb.wing("Feather%d%d" % (i, k), L, W, root, rot, thickness=0.08, taper=0.3))
        arm = sb.limb("WingArm%d" % i, [(0, 0, 0), (3.5, 0.3, 0), (7.0, 0.1, 0)], [0.24, 0.17, 0.06], location=root, joints=1.0)
        arm.rotation_euler = (0, math.radians(-22 * sx), math.radians(yaw))
        sb.paint(arm, BODY)
        w = sb.join(feathers + [arm], "Wing_%d" % (i + 1))
        if sx > 0:
            gradient(w, acc, top, axis=0, emission=0.4, alpha=0.85, curve=1.3)   # blue at the tips
        else:
            gradient(w, top, acc, axis=0, emission=0.4, alpha=0.85, curve=1.3)
        parts["Wing_%d" % (i + 1)] = w
    talons = []
    for i, sx in enumerate((-1, 1)):
        t = sb.limb("Talon%d" % i, [(0, 0, 0), (0.35 * sx, 0.3, -1.0), (0.1 * sx, 0.7, -1.8)], [0.34, 0.26, 0.1], location=(1.1 * sx, 0.3, cz - 1.6), joints=1.3)
        gradient(t, top, BODY)
        tp = sb.tip(t)
        cl = sb.claws("TalonClaw%d" % i, (tp.x, tp.y, tp.z), (0, 0.5, -1), 3, 0.7, 0.1, 0.22)
        talons += [t] + cl
    parts["Talons"] = sb.join(talons, "Talons")
    return scale_parts(parts, s)


# ------------------------------------------------------------------------------------ helpers
def scale_parts(parts, s):
    if s == 1.0:
        return parts
    for ob in parts.values():
        ob.location = Vector(ob.location) * s
        ob.scale = Vector(ob.scale) * s
    return parts


BUILDERS = {
    "Walker": lambda: build_walker(),
    "Runner": lambda: build_runner(),
    "Flyer": lambda: build_flyer(),
    "Tank": lambda: build_tank(),
    "Spitter": lambda: build_spitter(),
    "Brute": lambda: build_walker(2.2, boss=True),
    "Queen": lambda: build_queen(),
    "Warden": lambda: build_warden(),
}


def build_all(names=None, render=True):
    names = names or list(BUILDERS.keys())
    for name in names:
        sb.reset()
        _gmats.clear()
        parts = BUILDERS[name]()
        objs = list(parts.values())
        entry = sb.export_model("enemies/" + name, objs, {"kind": "enemy", "accent": [round(c * 255) for c in ACCENT[name][:3]]})
        print("%-8s parts=%2d tris=%6d size=%s" % (name, len(objs), entry["tris"], entry["size_studs"]))
        if render:
            extra = []
            if name in HOVER:   # a speck at the origin keeps the render floor at z=0 so hovering enemies hang in the air
                extra = [sb.sphere("_ground", 0.02, (0, 0, 0), subdiv=1)]
                sb.paint(extra[0], (0.035, 0.04, 0.05, 1), roughness=0.9)
            sb.render_model(name, objs + extra, "enemies/%s.png" % name, angle_deg=38, elev_deg=20)

if __name__ == "__main__":
    names = [a for a in sys.argv[1:] if a in BUILDERS] or None
    build_all(names, render=os.environ.get("SB_NO_RENDER") != "1")
