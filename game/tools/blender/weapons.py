"""Builds the 15 weapons as chunky stylized sci-fi models and exports them.

Convention (Blender): muzzle / blade points +Y, up is +Z, the grip hangs below the origin.
Each model exports as a few parts: Body (metal), Glow parts in the rarity color (*_Glow -> Neon in
Studio), and for orbital weapons an Orb_Glow part that the OrbitalRunner spins around the player.
Ids match src/ReplicatedStorage/Shared/Weapons.luau.

Run:  python3 weapons.py            (all)      python3 weapons.py Saber Nova   (some)
      SB_NO_RENDER=1 python3 weapons.py
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

RARITY = {
    "Starter": "Common", "Burst": "Common", "Blade": "Common",
    "Scatter": "Rare", "Marksman": "Rare", "Hammer": "Rare", "Guardian": "Rare",
    "Arc": "Epic", "Hornet": "Epic", "Saber": "Epic", "Storm": "Epic", "Ion": "Epic",
    "Nova": "Legendary", "Reaper": "Legendary", "Halo": "Legendary",
}
RARITY_COLOR = {  # same as Theme.Rarity
    "Common": rgb(190, 190, 200), "Rare": rgb(70, 140, 255), "Epic": rgb(170, 80, 255), "Legendary": rgb(255, 170, 30),
}
NAMES = {
    "Starter": "Starter Pistol", "Burst": "Burst SMG", "Blade": "Rusty Blade", "Scatter": "Shotgun",
    "Marksman": "Sniper Rifle", "Hammer": "Shock Hammer", "Guardian": "Spinning Blades", "Arc": "Laser Rifle",
    "Hornet": "Triple Rocket", "Saber": "Energy Sword", "Storm": "Lightning Orbs", "Ion": "Laser Beam",
    "Nova": "Heavy Cannon", "Reaper": "Dark Scythe", "Halo": "Sun Orbs",
}
METAL = rgb(58, 62, 74)
METAL_DARK = rgb(34, 36, 44)
METAL_LIGHT = rgb(120, 126, 140)
GRIP = rgb(28, 26, 30)
WOOD = rgb(96, 64, 40)
RUST = rgb(120, 78, 50)
GOLD = rgb(200, 150, 60)            # Legendary metal trim
COMMON_GLOW = rgb(150, 155, 170)    # dull grey-white LEDs at strength ~1: the theme grey at 2.2 blows out to white
COMMON_DIM = rgb(120, 125, 140)     # Common LEDs at strength ~0.9: stays grey in the render instead of bleaching to white
AMBER = rgb(255, 150, 25)           # Legendary glow: a bright emissive gold drifts to lemon, an orange-gold reads as gold


# ---------------------------------------------------------------------------- building blocks
def metal(ob, color=METAL, rough=0.45):
    return sb.paint(ob, color, roughness=rough, metallic=0.35)


def _lin(c):
    def f(u):
        return u / 12.92 if u <= 0.04045 else ((u + 0.055) / 1.055) ** 2.4
    return (f(c[0]), f(c[1]), f(c[2]), c[3])


def glow(ob, color, strength=2.2, alpha=1.0):
    """Emissive accent (alpha < 1 for translucent blades / shells). sb.paint feeds the palette tuple straight into the
    material, which Blender reads as linear, so every accent rendered as a paler version of the theme color it exports
    (Rare blue -> cyan, Epic -> lavender-pink, gold -> lemon). The render material gets the sRGB->linear version;
    the exported vertex colors are untouched. With linear colors the sweet spot is strength ~1.0-1.8."""
    sb.paint(ob, color, emission=strength, alpha=alpha)
    m = ob.data.materials[0]
    if not m.get("lin"):
        bsdf = m.node_tree.nodes["Principled BSDF"]
        bsdf.inputs["Base Color"].default_value = _lin(color)
        bsdf.inputs["Emission Color"].default_value = _lin(color)
        m["lin"] = 1
    return ob


def barrel(name, radius, length, at, verts=14, bevel=0.02):
    """Cylinder along +Y whose back end sits at `at`."""
    ob = sb.cylinder(name, radius, length, (at[0], at[1] + length / 2, at[2]), (math.radians(90), 0, 0), verts=verts, bevel=bevel)
    return ob


def ring(name, major, minor, at, axis="Y"):
    rot = {"Y": (math.radians(90), 0, 0), "X": (0, math.radians(90), 0), "Z": (0, 0, 0)}[axis]
    return sb.torus(name, major, minor, at, rot)


def disc(name, radius, at, thickness=0.04, verts=16):
    """Flat disc facing +Y (a lit bore at a muzzle)."""
    return sb.cylinder(name, radius, thickness, at, (math.radians(90), 0, 0), verts=verts)


def orient(ob, x_dir, y_dir):
    """Rotate ob so its local X points along x_dir and local Y along y_dir (world)."""
    x = Vector(x_dir).normalized()
    y = Vector(y_dir).normalized()
    z = x.cross(y).normalized()
    y = z.cross(x).normalized()
    ob.rotation_euler = Matrix((x, y, z)).transposed().to_euler()
    return ob


def plate_poly(name, pts2d, thickness, location, x_dir, y_dir):
    """Solid plate from a 2D outline (u, v): u runs along x_dir, v along y_dir, thickness along their normal.
    Good for swept fins whose silhouette a box cannot make."""
    me = bpy.data.meshes.new(name)
    bm = bmesh.new()
    vs = [bm.verts.new((u, v, 0)) for u, v in pts2d]
    bm.faces.new(vs)
    bmesh.ops.triangulate(bm, faces=bm.faces[:])
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    ob.location = location
    orient(ob, x_dir, y_dir)
    m = ob.modifiers.new("Solid", "SOLIDIFY")
    m.thickness = thickness
    m.offset = 0
    return ob


def gradient_metal(ob, top, bottom, axis=2, roughness=0.5, metallic=0.3, power=1.0):
    """Two-tone vertex gradient that also shows in renders: sb.gradient only writes vertex colors, so give the
    render material a Color-attribute node. Apply modifiers first so the whole shell gets colored.
    power < 1 pushes the blend toward `top` (e.g. 0.45: steel over the top two thirds, rust only at the base)."""
    bpy.context.view_layer.update()  # matrix_world must be current or a rotated part is graded along its local axis
    if power == 1.0:
        sb.gradient(ob, top, bottom, axis)
    else:
        me = ob.data
        attr = me.color_attributes.get("Color") or me.color_attributes.new(name="Color", type="BYTE_COLOR", domain="CORNER")
        mw = ob.matrix_world
        zs = [(mw @ v.co)[axis] for v in me.vertices]
        lo, hi = min(zs), max(zs)
        span = max(hi - lo, 1e-6)
        for poly in me.polygons:
            for li in poly.loop_indices:
                t = (((mw @ me.vertices[me.loops[li].vertex_index].co)[axis] - lo) / span) ** power
                attr.data[li].color_srgb = tuple(bottom[i] * (1 - t) + top[i] * t for i in range(4))
        me.color_attributes.active_color = attr
    m = bpy.data.materials.new(ob.name + "_grad")
    m.use_nodes = True
    nodes = m.node_tree.nodes
    bsdf = nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    attr = nodes.new("ShaderNodeAttribute")
    attr.attribute_name = "Color"
    m.node_tree.links.new(attr.outputs["Color"], bsdf.inputs["Base Color"])
    ob.data.materials.clear()
    ob.data.materials.append(m)
    return ob


def bolt(name, base, direction, length, radius, color, strength=2.5):
    """Two-segment lightning bolt: a cone out of the surface plus a kinked second cone at its tip."""
    d = Vector(direction).normalized()
    a = sb.cone_dir(name, base, d, length, radius)
    glow(a, color, strength)
    perp = d.cross(Vector((0, 0, 1)))
    if perp.length < 1e-3:
        perp = Vector((1, 0, 0))
    perp.normalize()
    k = math.radians(40)
    d2 = (d * math.cos(k) + perp * math.sin(k)).normalized()
    b = sb.cone_dir(name + "k", Vector(base) + d * (length * 0.55), d2, length * 0.65, radius * 0.7)
    glow(b, color, strength)
    return [a, b]


def zigzag(name, p0, direction, perp, seg=0.2, kinks=(0.1, -0.13, 0.06), widths=(0.11, 0.08, 0.06, 0.02), thickness=0.06,
           color=rgb(225, 235, 255), strength=2.0):
    """Flat jagged lightning ribbon: a 4-point zigzag from p0 along `direction`, kinking sideways along `perp`
    (in-plane, so the bolt is a wide jagged shape seen from the plane normal, which reads as lightning at 64px)."""
    d = Vector(direction).normalized()
    p = Vector(perp).normalized()
    pts = [Vector(p0)]
    for k in kinks:
        pts.append(pts[-1] + d * seg + p * k)
    s = strip(name, pts, list(widths), thickness, up=p)
    glow(s, color, strength)
    return s


def grip(name="Grip", at=(0, 0, 0), size=(0.3, 0.42, 0.8), tilt=-18):
    g = sb.box(name, size, (at[0], at[1] - 0.05, at[2] - size[2] / 2), (math.radians(tilt), 0, 0), bevel=0.05)
    return sb.paint(g, GRIP, roughness=0.8)


def strip(name, centers, widths, thickness=0.06, up=(0, 0, 1)):
    """Flat ribbon (blade) through `centers` (world), width per point, lying in the plane spanned by the
    path and `up`. Solidified to `thickness`. Good for straight and curved blades."""
    up = Vector(up).normalized()
    me = bpy.data.meshes.new(name)
    bm = bmesh.new()
    rows = []
    n = len(centers)
    for i, c in enumerate(centers):
        c = Vector(c)
        prev = Vector(centers[max(i - 1, 0)])
        nxt = Vector(centers[min(i + 1, n - 1)])
        t = (nxt - prev).normalized()
        side = up.cross(t).cross(t).normalized() * -1  # in-plane perpendicular
        side = t.cross(up.cross(t)).normalized()
        w = widths[i] / 2
        rows.append((bm.verts.new(c + side * w), bm.verts.new(c - side * w)))
    for i in range(n - 1):
        a, b = rows[i]
        c, d = rows[i + 1]
        bm.faces.new((a, c, d, b))
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    if thickness > 0:
        m = ob.modifiers.new("Solid", "SOLIDIFY")
        m.thickness = thickness
        m.offset = 0
    return ob


def arc_points(center, radius, a0, a1, n, plane="YZ"):
    pts = []
    for i in range(n):
        a = math.radians(a0 + (a1 - a0) * i / (n - 1))
        if plane == "YZ":
            pts.append((center[0], center[1] + math.cos(a) * radius, center[2] + math.sin(a) * radius))
        else:
            pts.append((center[0] + math.cos(a) * radius, center[1] + math.sin(a) * radius, center[2]))
    return pts


# ---------------------------------------------------------------------------- guns
def gun_common(acc, receiver=(0.42, 1.3, 0.5), rec_at=(0, 0.45, 0.3), barrel_r=0.11, barrel_len=0.8, stock=None, mag=None,
               gs=2.2, barrels=True, muzzle=True, mag_tilt=8, mag_color=METAL_DARK, sides=True, panel=True, panel_color=METAL_DARK):
    """Receiver + dark front panel + top rail + barrel with a slim dark muzzle crown and a lit bore + grip/guard.
    gs = glow strength for the accents (Common uses 0.7 with COMMON_DIM so grey stays grey). barrels/muzzle=False
    lets a builder make its own front end; sides/panel=False let it make its own side accents / front panel."""
    body = []
    rec = sb.box("Receiver", receiver, rec_at, bevel=0.06)
    metal(rec)
    body.append(rec)
    if panel:
        pn = sb.box("Panel", (receiver[0] + 0.02, receiver[1] * 0.45, receiver[2] * 0.6), (0, rec_at[1] + receiver[1] * 0.15, rec_at[2]), bevel=0.04)
        metal(pn, panel_color)
        body.append(pn)
    top = sb.box("Top", (receiver[0] * 0.6, receiver[1] * 0.8, 0.12), (rec_at[0], rec_at[1] - 0.05, rec_at[2] + receiver[2] / 2 + 0.04), bevel=0.03)
    metal(top, METAL_LIGHT)
    body.append(top)
    glows = []
    bz = rec_at[2] + 0.05
    muzzle_y = rec_at[1] + receiver[1] / 2 - 0.1 + barrel_len
    if barrels:
        b = barrel("Barrel", barrel_r, barrel_len, (0, rec_at[1] + receiver[1] / 2 - 0.1, bz))
        metal(b, METAL_DARK)
        body.append(b)
        if muzzle:
            # slim dark crown, never fatter or brighter than the barrel (a light fat ring reads as a plunger cup)
            mz = ring("Muzzle", barrel_r * 0.95, barrel_r * 0.25, (0, muzzle_y, bz))
            metal(mz, METAL_DARK)
            body.append(mz)
            mg = disc("MuzzleGlow", barrel_r * 0.55, (0, muzzle_y + 0.01, bz))
            glow(mg, acc, min(gs, 1.8))
            glows.append(mg)
    body.append(grip("Grip", (0, rec_at[1] - receiver[1] / 2 + 0.25, rec_at[2] - receiver[2] / 2 + 0.05)))
    guard = ring("Guard", 0.16, 0.03, (0, rec_at[1] - receiver[1] / 2 + 0.55, rec_at[2] - receiver[2] / 2 - 0.05), axis="X")
    metal(guard, METAL_DARK)
    body.append(guard)
    if stock:
        st = sb.box("Stock", stock, (0, rec_at[1] - receiver[1] / 2 - stock[1] / 2 + 0.05, rec_at[2] - 0.05), bevel=0.05)
        metal(st, METAL_DARK)
        body.append(st)
    if mag:
        mg = sb.box("Mag", mag, (0, rec_at[1] + 0.15, rec_at[2] - receiver[2] / 2 - mag[2] / 2 + 0.05), (math.radians(mag_tilt), 0, 0), bevel=0.04)
        metal(mg, mag_color)
        body.append(mg)
    for sx in ((-1, 1) if sides else ()):
        s = sb.box("Side", (0.07, receiver[1] * 0.55, 0.08), (sx * (receiver[0] / 2 + 0.02), rec_at[1] + 0.05, rec_at[2] + 0.02), bevel=0)
        glow(s, acc, gs)
        glows.append(s)
    return body, glows


def build_starter():
    acc = COMMON_DIM
    # receiver > shroud > barrel, stepping down toward the muzzle like a pistol (no under-rail: it read as a 2nd receiver)
    body, glows = gun_common(acc, receiver=(0.4, 1.1, 0.42), rec_at=(0, 0.35, 0.22), barrel_r=0.15, barrel_len=0.7, gs=0.9,
                             sides=False, panel=False)
    shroud = sb.box("Shroud", (0.34, 0.42, 0.34), (0, 1.06, 0.27), bevel=0.05)  # squared slide front, not a round lamp head
    metal(shroud, METAL_LIGHT)
    sight = sb.box("Sight", (0.08, 0.15, 0.16), (0, 0.82, 0.51), bevel=0.02)
    metal(sight, METAL_LIGHT)
    body += [shroud, sight]
    # two dark cheek plates per side break the slab, with a small grey LED window in the gap between them
    for sx in (-1, 1):
        for j, y in enumerate((0.08, 0.62)):
            body.append(sb.plate_on("Cheek%d%d" % (sx + 1, j), (sx * 0.2, y, 0.22), (sx, 0, 0), (0.34, 0.2, 0.05), METAL_DARK, bevel=0.03))
        led = sb.box("Side", (0.06, 0.14, 0.12), (sx * 0.215, 0.35, 0.22), bevel=0)
        glow(led, acc, 0.9)
        glows.append(led)
    return {"Body": sb.join(body, "Body"), "Accent_Glow": sb.join(glows, "Accent_Glow")}


def build_burst():
    acc = COMMON_DIM
    body, glows = gun_common(acc, receiver=(0.44, 1.5, 0.5), rec_at=(0, 0.5, 0.3), barrel_r=0.12, barrel_len=0.8, mag=(0.24, 0.36, 1.0),
                             gs=0.9, mag_tilt=15, mag_color=METAL)
    # skeleton stock: two thick bars joined by a rear plate
    for i, z in enumerate((0.45, 0.1)):
        bar = sb.box("StockBar%d" % i, (0.3, 0.6, 0.14), (0, -0.5, z), bevel=0.02)
        metal(bar, METAL_DARK)
        body.append(bar)
    plate = sb.box("StockPlate", (0.3, 0.12, 0.45), (0, -0.76, 0.275), bevel=0.02)
    metal(plate, METAL_DARK)
    body.append(plate)
    # slimmer shroud in the receiver's tone (a fat light one read as a flashlight head) with dark cooling fins on top
    # and a grey LED slot on each side; the barrel steps down out of it to the dark muzzle crown
    shroud = barrel("Shroud", 0.2, 0.6, (0, 1.2, 0.35), bevel=0.03)
    metal(shroud)
    body.append(shroud)
    for i in range(3):
        v = sb.box("Vent%d" % i, (0.46, 0.06, 0.12), (0, 1.32 + i * 0.18, 0.5), bevel=0)
        metal(v, METAL_DARK)
        body.append(v)
    dots = []
    for sx in (-1, 1):
        for i, z in enumerate((0.29, 0.41)):
            d = sb.box("Slot%d%d" % (sx + 1, i), (0.05, 0.3, 0.06), (sx * 0.2, 1.5, z), bevel=0)
            glow(d, acc, 0.9)
            dots.append(d)
    # glow strip flush with the tilted mag's front face
    mag_c = Vector((0, 0.65, -0.4))
    off = Matrix.Rotation(math.radians(15), 3, "X") @ Vector((0, 0.2, 0))
    mg = sb.box("MagGlow", (0.26, 0.04, 0.6), mag_c + off, (math.radians(15), 0, 0), bevel=0)
    glow(mg, acc, 0.9)
    return {"Body": sb.join(body, "Body"), "Accent_Glow": sb.join(glows + dots + [mg], "Accent_Glow")}


def build_scatter():
    acc = RARITY_COLOR["Rare"]
    navy = rgb(28, 48, 90)  # Rare body tint so the tier reads on the metal, not only on the slots
    body, glows = gun_common(acc, receiver=(0.5, 1.2, 0.55), rec_at=(0, 0.45, 0.3), stock=(0.34, 0.55, 0.45), barrels=False,
                             gs=1.5, panel_color=navy)
    # stubby fat twin barrels bridged into one over-under assembly, ending in a sawn-off muzzle block with two lit bores
    y0 = 0.45 + 0.6 - 0.1
    blen = 1.0
    for i, sx in enumerate((-1, 1)):
        b = barrel("Barrel%d" % i, 0.19, blen, (sx * 0.25, y0, 0.35))
        metal(b, METAL_DARK)
        body.append(b)
        d = disc("MuzzleGlow%d" % i, 0.15, (sx * 0.25, y0 + blen + 0.01, 0.35))
        glow(d, acc, 1.6)
        glows.append(d)
    bridge = sb.box("Bridge", (0.2, 0.9, 0.3), (0, y0 + 0.5, 0.35), bevel=0.04)
    metal(bridge, METAL_DARK)
    body.append(bridge)
    mblock = sb.box("MuzzleBlock", (0.74, 0.22, 0.5), (0, y0 + blen - 0.11, 0.35), bevel=0.05)
    metal(mblock, METAL_DARK)
    body.append(mblock)
    # shell tube under the barrels, behind and ahead of the pump
    tube = barrel("MagTube", 0.11, 0.9, (0, y0, 0.08))
    metal(tube, METAL_LIGHT)
    body.append(tube)
    # heat shield over the barrels with fat blue glow slots
    shield = sb.box("Shield", (0.64, 0.8, 0.14), (0, y0 + 0.45, 0.55), bevel=0.03)
    metal(shield, METAL_LIGHT)
    body.append(shield)
    for i in range(3):
        s = sb.box("Slot%d" % i, (0.68, 0.1, 0.06), (0, y0 + 0.2 + i * 0.25, 0.63), bevel=0)
        glow(s, acc, 1.5)
        glows.append(s)
    # boxy blue pump grip with grooves; a blue slot on the stock so the rear carries the tier too
    pump = sb.box("Pump", (0.6, 0.55, 0.3), (0, y0 + 0.35, 0.08), bevel=0.06)
    metal(pump, rgb(50, 80, 140))
    body.append(pump)
    for i, y in enumerate((y0 + 0.2, y0 + 0.5)):
        g = ring("Groove%d" % i, 0.32, 0.03, (0, y, 0.08))
        metal(g, METAL_DARK)
        body.append(g)
    ss = sb.box("StockSlot", (0.24, 0.38, 0.05), (0, -0.375, 0.48), bevel=0)
    glow(ss, acc, 1.5)
    glows.append(ss)
    return {"Body": sb.join(body, "Body"), "Accent_Glow": sb.join(glows, "Accent_Glow")}


def build_marksman():
    acc = RARITY_COLOR["Rare"]
    body, glows = gun_common(acc, receiver=(0.4, 1.6, 0.5), rec_at=(0, 0.5, 0.3), barrel_r=0.16, barrel_len=1.8, stock=(0.3, 1.0, 0.42),
                             mag=(0.2, 0.36, 0.5), muzzle=False, gs=1.5)
    my = 0.5 + 0.8 - 0.1 + 1.8  # muzzle y
    # fat shroud with cooling rings (kept blue), one more ring on the exposed barrel so it is not a bare pencil
    shroud = barrel("Shroud", 0.22, 0.9, (0, 1.2, 0.35), verts=12)
    metal(shroud, METAL_LIGHT)
    body.append(shroud)
    for i in range(3):
        c = ring("Cool%d" % i, 0.23, 0.03, (0, 1.4 + i * 0.25, 0.35))
        glow(c, acc, 1.5)
        glows.append(c)
    c = ring("Cool3", 0.18, 0.03, (0, 2.3, 0.35))
    glow(c, acc, 1.5)
    glows.append(c)
    # boxy muzzle brake with vent slots and a lit bore
    brake = sb.box("Brake", (0.42, 0.45, 0.42), (0, my - 0.2, 0.35), bevel=0.05)
    metal(brake, METAL_LIGHT)
    body.append(brake)
    for i, y in enumerate((my - 0.3, my - 0.12)):
        s = sb.box("BrakeSlot%d" % i, (0.46, 0.08, 0.14), (0, y, 0.35), bevel=0)
        metal(s, METAL_DARK)
        body.append(s)
    mg = disc("MuzzleGlow", 0.11, (0, my + 0.03, 0.35))
    glow(mg, acc, 1.6)
    glows.append(mg)
    # blue slot on top of the stock so the rear carries the tier color too
    ss = sb.box("StockSlot", (0.22, 0.5, 0.05), (0, -0.75, 0.47), bevel=0)
    glow(ss, acc, 1.5)
    glows.append(ss)
    # long fat scope with an objective bell, lens and rear glow
    scope = barrel("Scope", 0.17, 1.3, (0, 0.05, 0.78))
    metal(scope, METAL_DARK)
    body.append(scope)
    for y in (0.35, 1.05):
        mount = sb.box("Mount", (0.14, 0.14, 0.24), (0, y, 0.64), bevel=0.02)
        metal(mount, METAL_LIGHT)
        body.append(mount)
    bell = ring("Bell", 0.19, 0.05, (0, 1.32, 0.78))
    metal(bell, METAL_LIGHT)
    body.append(bell)
    lens = sb.cylinder("Lens", 0.17, 0.04, (0, 1.36, 0.78), (math.radians(90), 0, 0))
    glow(lens, acc, 1.8)
    glows.append(lens)
    sg = ring("ScopeGlow", 0.15, 0.03, (0, 0.05, 0.78))
    glow(sg, acc, 1.8)
    glows.append(sg)
    # forestock under the shroud + a folded bipod: two legs lying back along the forestock's lower edges from the
    # hinge, feet at their rear ends (dangling cone legs read as claws)
    fore = sb.box("Forestock", (0.32, 0.95, 0.2), (0, 1.62, 0.17), bevel=0.04)
    metal(fore, METAL_DARK)
    body.append(fore)
    hinge = sb.box("Hinge", (0.5, 0.18, 0.16), (0, my - 0.55, 0.14), bevel=0.03)
    metal(hinge, METAL_DARK)
    body.append(hinge)
    for i, sx in enumerate((-1, 1)):
        leg = sb.cylinder("Bipod%d" % i, 0.055, 0.95, (sx * 0.2, my - 0.55 - 0.475, 0.06), (math.radians(90), 0, 0), verts=10)
        metal(leg, METAL_LIGHT)
        body.append(leg)
        foot = sb.box("Foot%d" % i, (0.11, 0.12, 0.11), (sx * 0.2, my - 0.55 - 0.95, 0.06), bevel=0.01)
        metal(foot, METAL_DARK)
        body.append(foot)
    return {"Body": sb.join(body, "Body"), "Accent_Glow": sb.join(glows, "Accent_Glow")}


def build_arc():
    acc = RARITY_COLOR["Epic"]
    body, glows = gun_common(acc, receiver=(0.44, 1.7, 0.6), rec_at=(0, 0.55, 0.3), stock=(0.3, 0.7, 0.4), mag=(0.24, 0.4, 0.4), barrels=False,
                             sides=False)
    # tall split rails with an energy channel between them (proud above and below), capped by a lit muzzle
    for sx in (-1, 1):
        r = sb.box("Rail", (0.12, 1.4, 0.32), (0.15 * sx, 2.0, 0.35), bevel=0.04)
        metal(r, METAL_LIGHT)
        body.append(r)
    channel = sb.box("Channel", (0.12, 1.3, 0.4), (0, 2.0, 0.35), bevel=0)
    glow(channel, acc, 1.3)
    glows.append(channel)
    mz = ring("Muzzle", 0.24, 0.05, (0, 2.72, 0.35))
    metal(mz, METAL_DARK)
    body.append(mz)
    md = disc("MuzzleGlow", 0.18, (0, 2.73, 0.35))
    glow(md, acc, 1.3)
    glows.append(md)
    # two coils at a strength that stays purple, with a dark clamp block between them to break the hoop rhythm
    for i, y in enumerate((1.65, 2.25)):
        c = ring("Coil%d" % i, 0.26, 0.035, (0, y, 0.35))
        glow(c, acc, 1.1)
        glows.append(c)
    clamp = sb.box("Clamp", (0.6, 0.16, 0.6), (0, 1.95, 0.35), bevel=0.04)
    metal(clamp, METAL_DARK)
    body.append(clamp)
    # one swept crest fin over the receiver (a plate, not a mohawk of cones) with a purple inlay + two swept muzzle fins
    crest = [(0, 0), (0.65, 0), (0.5, 0.38), (0.12, 0.32)]
    fin = plate_poly("Fin0", crest, 0.1, (0, 0.8, 0.58), (0, 1, 0), (0, 0, 1))
    metal(fin, METAL_LIGHT)
    body.append(fin)
    inlay = plate_poly("FinGlow", [(0.08, 0.06), (0.55, 0.06), (0.44, 0.31), (0.16, 0.26)], 0.14, (0, 0.8, 0.58), (0, 1, 0), (0, 0, 1))
    glow(inlay, acc, 1.2)
    glows.append(inlay)
    fins = [sb.cone_dir("Fin%d" % (i + 3), (sx * 0.2, 2.6, 0.35), (sx * 0.7, -1, 0), 0.4, 0.06) for i, sx in enumerate((-1, 1))]
    for f in fins:
        metal(f, METAL_LIGHT)
    body += fins
    # twin power cells on the receiver sides (the old one under the receiver was hidden), each caged by two dark rings
    for sx in (-1, 1):
        cell = barrel("Cell", 0.13, 0.5, (sx * 0.29, 0.25, 0.3))
        glow(cell, acc, 1.1)
        glows.append(cell)
        for i, y in enumerate((0.32, 0.68)):
            cr = ring("CellRing%d" % i, 0.15, 0.03, (sx * 0.29, y, 0.3))
            metal(cr, METAL_DARK)
            body.append(cr)
    return {"Body": sb.join(body, "Body"), "Accent_Glow": sb.join(glows, "Accent_Glow")}


def build_hornet():
    acc = RARITY_COLOR["Epic"]
    body, glows = [], []
    launcher = sb.box("Launcher", (0.7, 1.4, 0.6), (0, 0.6, 0.35), bevel=0.06)
    metal(launcher)
    body.append(launcher)
    vent = sb.box("Vent", (0.7, 0.3, 0.6), (0, -0.25, 0.35), bevel=0.06)
    metal(vent, METAL_DARK)
    body.append(vent)
    for i, (x, z) in enumerate(((-0.22, 0.25), (0.22, 0.25), (0, 0.6))):
        t = barrel("Tube%d" % i, 0.18, 1.5, (x, 1.1, z), verts=12, bevel=0.03)
        sb.paint(t, rgb(48, 38, 68), roughness=0.45, metallic=0.35)  # dark violet: the Epic body reads at thumbnail size
        body.append(t)
        rim = ring("Rim%d" % i, 0.2, 0.04, (x, 2.6, z))
        glow(rim, acc, 1.2)
        glows.append(rim)
        # warheads poke well past the rims
        tip = sb.cone_dir("Tip%d" % i, (x, 2.5, z), (0, 1, 0), 0.5, 0.15)
        glow(tip, acc, 1.4)
        glows.append(tip)
        # flared exhaust nozzles with a lit throat so the rear says 'loaded'
        ex = sb.cylinder("Exhaust%d" % i, 0.13, 0.4, (x, -0.6, z), (math.radians(90), 0, 0), verts=12, r2=0.2)
        metal(ex, METAL_DARK)
        body.append(ex)
        eg = disc("ExGlow%d" % i, 0.14, (x, -0.81, z))
        glow(eg, acc, 1.1)
        glows.append(eg)
    # flush box bands around the launcher (tori only touched the box at its corners) + a shield plate between them
    for i, y in enumerate((0.4, 0.9)):
        b = sb.box("Band%d" % i, (0.76, 0.08, 0.66), (0, y, 0.35), bevel=0.02)
        glow(b, acc, 1.1)
        glows.append(b)
    body.append(sb.plate_on("Shield", (0, 0.65, 0.65), (0, 0, 1), (0.5, 0.4, 0.06), METAL_LIGHT, bevel=0.03))
    slot = sb.box("Slot", (0.5, 0.05, 0.08), (0, -0.41, 0.42), bevel=0)
    glow(slot, acc, 1.2)
    glows.append(slot)
    handle = sb.box("Handle", (0.2, 0.7, 0.12), (0, 0.5, 1.0), bevel=0.03)
    metal(handle, METAL_LIGHT)
    posts = [sb.box("Post%d" % i, (0.12, 0.12, 0.3), (0, y, 0.82), bevel=0.02) for i, y in enumerate((0.2, 0.8))]
    for p in posts:
        metal(p, METAL_LIGHT)
    body += [handle] + posts
    body.append(grip("Grip", (0, 0.35, 0.05), size=(0.36, 0.5, 0.95), tilt=-12))
    return {"Body": sb.join(body, "Body"), "Accent_Glow": sb.join(glows, "Accent_Glow")}


def build_nova():
    acc = RARITY_COLOR["Legendary"]
    body, glows = [], []
    # big drum that outweighs every Epic, glowing rear core, wraparound vent rings
    # dark bronze drum and barrel (the Common METAL palette said nothing about the tier), bolted gold armor plates
    drum = barrel("Drum", 0.6, 0.9, (0, -0.2, 0.45), verts=18, bevel=0.05)
    sb.apply_modifiers(drum)
    gradient_metal(drum, rgb(82, 68, 52), rgb(36, 34, 40), roughness=0.45, metallic=0.5)
    body.append(drum)
    cg = disc("CoreGlow", 0.32, (0, -0.22, 0.45), thickness=0.06)
    glow(cg, AMBER, 1.3)
    glows.append(cg)
    for i in range(3):
        v = ring("Vent%d" % i, 0.56, 0.06, (0, 0.0 + i * 0.25, 0.45))  # only a lit sliver shows: a groove, not a hoop
        glow(v, AMBER, 1.1)
        glows.append(v)
    body += sb.plates_on("Plate", (0, 0.25, 0.45), (0.6, 0.45, 0.6),
                         [(math.cos(math.radians(a)), 0, math.sin(math.radians(a))) for a in (45, 135, 225, 315)],
                         (0.32, 0.3, 0.06), GOLD, bevel=0.03)
    big = barrel("Barrel", 0.3, 2.2, (0, 0.7, 0.45), verts=18, bevel=0.03)
    sb.apply_modifiers(big)
    gradient_metal(big, rgb(72, 64, 58), rgb(36, 34, 40), roughness=0.45, metallic=0.5)
    body.append(big)
    for i, y in enumerate((1.2, 2.4)):
        r = ring("Band%d" % i, 0.34, 0.08, (0, y, 0.45))
        glow(r, AMBER, 1.3)
        glows.append(r)
    clamp = sb.box("Clamp", (0.8, 0.22, 0.8), (0, 1.8, 0.45), bevel=0.05)  # gold clamp breaks the slinky of three hoops
    metal(clamp, GOLD, rough=0.3)
    body.append(clamp)
    # flared gold brake with a lit bore and six gold spikes
    brake = sb.cylinder("Brake", 0.44, 0.5, (0, 3.05, 0.45), (math.radians(90), 0, 0), verts=18, r2=0.32)
    sb.paint(brake, GOLD, roughness=0.3, metallic=0.5)
    body.append(brake)
    mzr = ring("MuzzleGlow", 0.36, 0.06, (0, 3.3, 0.45))
    glow(mzr, AMBER, 1.3)
    glows.append(mzr)
    bore = disc("Bore", 0.3, (0, 3.31, 0.45))
    glow(bore, AMBER, 1.3)
    glows.append(bore)
    for i in range(6):
        a = i / 6 * 2 * math.pi
        d = Vector((math.cos(a), 0.7, math.sin(a))).normalized()
        s = sb.cone_dir("Spike%d" % i, (math.cos(a) * 0.4, 3.1, 0.45 + math.sin(a) * 0.4), d, 0.3, 0.09)
        metal(s, GOLD)
        body.append(s)
    # gold carry handle
    handle = sb.box("Handle", (0.22, 0.9, 0.14), (0, 0.2, 1.24), bevel=0.03)
    metal(handle, GOLD)
    posts = [sb.box("Post%d" % i, (0.14, 0.14, 0.24), (0, y, 1.1), bevel=0.02) for i, y in enumerate((-0.15, 0.55))]
    for p in posts:
        metal(p, GOLD)
    body += [handle] + posts
    leather = rgb(44, 34, 28)
    g = grip("Grip", (0, 0.2, 0.0), size=(0.32, 0.45, 0.85), tilt=-14)
    sb.paint(g, leather, roughness=0.8)
    body.append(g)
    fore = grip("Fore", (0, 1.4, 0.15), size=(0.3, 0.4, 0.6), tilt=-8)
    sb.paint(fore, leather, roughness=0.8)
    body.append(fore)
    fp = sb.box("ForePlate", (0.34, 0.44, 0.06), (0, 1.39, 0.16), (math.radians(-8), 0, 0), bevel=0.02)
    metal(fp, GOLD, rough=0.3)
    body.append(fp)
    return {"Body": sb.join(body, "Body"), "Accent_Glow": sb.join(glows, "Accent_Glow")}


def build_ion():
    acc = RARITY_COLOR["Epic"]
    body, glows = [], []
    core = barrel("Core", 0.34, 2.0, (0, 0.0, 0.45), verts=18, bevel=0.04)
    metal(core)
    body.append(core)
    # receiver block under the core that the grips attach to
    block = sb.box("Block", (0.46, 1.3, 0.4), (0, 0.8, 0.2), bevel=0.05)
    metal(block, METAL_DARK)
    body.append(block)
    # three swept fins (shark-fin outline in the (Y, radial) plane, tapering forward): beveled, a lit rim along the
    # outer edge and a dark vent slot on each face so they are not blank sails
    outline = [(1.45, 0.28), (1.0, 0.58), (0.4, 0.66), (-0.1, 0.42), (-0.1, 0.28)]
    rim = [(1.45, 0.33), (1.0, 0.63), (0.4, 0.71), (0.4, 0.6), (1.0, 0.52), (1.45, 0.22)]
    for i in range(3):
        a = math.radians(90 + i * 120)
        rd = Vector((math.cos(a), 0, math.sin(a)))
        fin = plate_poly("Fin%d" % i, outline, 0.14, (0, 0, 0.45), (0, 1, 0), rd)
        sb.apply_modifiers(fin)
        sb.add_bevel(fin, 0.04, 2)
        metal(fin, METAL_LIGHT)
        body.append(fin)
        fr = plate_poly("FinRim%d" % i, rim, 0.18, (0, 0, 0.45), (0, 1, 0), rd)
        glow(fr, acc, 1.2)
        glows.append(fr)
        n = Vector((0, 1, 0)).cross(rd).normalized()
        c = Vector((0, 0.65, 0.45)) + rd * 0.44
        for s in (-1, 1):
            body.append(sb.plate_on("FinVent%d%d" % (i, s + 1), c + n * (s * 0.07), n * s, (0.45, 0.1, 0.03), METAL_DARK, bevel=0.01))
    # flared nozzle with the emitter sphere inside, a focus ring and four prongs (teeth)
    nozzle = sb.cylinder("Nozzle", 0.42, 0.5, (0, 2.2, 0.45), (math.radians(90), 0, 0), verts=18, r2=0.32)
    metal(nozzle, METAL_LIGHT)
    body.append(nozzle)
    focus = ring("Focus", 0.4, 0.06, (0, 2.45, 0.45))
    glow(focus, acc, 1.2)
    glows.append(focus)
    emitter_s = sb.sphere("Emitter", 0.26, (0, 2.35, 0.45), subdiv=2)
    glow(emitter_s, acc, 1.3)
    glows.append(emitter_s)
    for i in range(4):
        a = math.radians(45 + i * 90)
        p = sb.cone_dir("Prong%d" % i, (math.cos(a) * 0.36, 2.42, 0.45 + math.sin(a) * 0.36), (0, 1, 0), 0.45, 0.11)
        metal(p, METAL_LIGHT)
        body.append(p)
    for i in range(4):
        w = ring("Win%d" % i, 0.36, 0.03, (0, 0.3 + i * 0.4, 0.45))
        glow(w, acc, 1.1)
        glows.append(w)
    body.append(grip("Grip", (0, 0.3, 0.05)))
    body.append(grip("Fore", (0, 1.3, 0.05), size=(0.28, 0.36, 0.55), tilt=-6))
    back = barrel("Back", 0.26, 0.4, (0, -0.4, 0.45), verts=18)
    metal(back, METAL_DARK)
    body.append(back)
    return {"Body": sb.join(body, "Body"), "Accent_Glow": sb.join(glows, "Accent_Glow")}


# ---------------------------------------------------------------------------- melee
def build_blade():
    # Blade strip: width along Y (face normal X, toward the render camera), thickness along X.
    # Cutting edge = -Y side (glow strip), back edge = +Y side (bites).
    acc = COMMON_GLOW
    handle = sb.cylinder("Handle", 0.15, 1.0, (0, 0, -0.5), verts=10)
    sb.paint(handle, GRIP, roughness=0.8)
    wraps = [ring("Wrap%d" % i, 0.165, 0.03, (0, 0, -0.25 - i * 0.25), axis="Z") for i in range(3)]
    for w in wraps:
        sb.paint(w, rgb(60, 50, 40), roughness=0.9)
    # dark iron guard and pommel, rust only on the quillon spikes and the blade base (all-rust read as one tan object)
    pommel = sb.sphere("Pommel", 0.2, (0, 0, -1.05), subdiv=2)
    sb.paint(pommel, METAL, roughness=0.5, metallic=0.4)
    # wide crossguard along the blade's width (Y) with quillon spikes
    guard = sb.box("Guard", (0.32, 1.1, 0.24), (0, 0, 0.05), bevel=0.05)
    sb.paint(guard, METAL, roughness=0.5, metallic=0.4)
    quillons = [sb.cone_dir("Quillon%d" % i, (0, sy * 0.55, 0.05), (0, sy, 0), 0.28, 0.11) for i, sy in enumerate((-1, 1))]
    for q in quillons:
        metal(q, RUST)
    zs = [0.1, 1.2, 2.2, 2.7, 2.85]
    ws = [0.42, 0.5, 0.46, 0.12, 0.02]
    blade = strip("Blade", [(0, 0, z) for z in zs], ws, 0.14, up=(0, 1, 0))
    sb.apply_modifiers(blade)
    # jagged back edge: three triangular chips out of the +Y side (boxes turned 45 degrees, so the bites are V-shaped)
    for i, (z, s) in enumerate(((1.5, 0.3), (2.1, 0.26), (0.8, 0.24))):
        notch = sb.box("Notch%d" % i, (0.4, s, s), (0, 0.25, z), (math.radians(45), 0, 0), bevel=0)
        m = blade.modifiers.new("Notch", "BOOLEAN")
        m.operation = "DIFFERENCE"
        m.object = notch
        m.solver = "EXACT"
        sb.apply_modifiers(blade)
        bpy.data.objects.remove(notch, do_unlink=True)
    # dull steel over the top two thirds, rust only at the ricasso (power 0.45 pushes the blend up), plus rust patches
    gradient_metal(blade, rgb(140, 148, 160), rgb(105, 62, 36), roughness=0.55, metallic=0.45, power=0.45)
    rust = []
    for sx in (-1, 1):
        for j, (y, z, sy, sz, roll) in enumerate(((0.06, 0.55, 0.14, 0.24, 0.35), (-0.1, 1.35, 0.1, 0.3, -0.25), (0.05, 1.9, 0.12, 0.16, 0.2))):
            rust.append(sb.plate_on("Rust%d%d" % (sx + 1, j), (sx * 0.072, y, z), (sx, 0, 0), (sy, sz, 0.02), rgb(96, 54, 32), bevel=0.01, roll=roll * sx))
    # sharpened edge: pale (not white-neon) strip following the -Y edge, proud of both faces
    e_pts = [(0, -(w / 2 - 0.03), z) for z, w in ((0.15, 0.42), (1.2, 0.5), (2.2, 0.46), (2.62, 0.17))]
    edge = strip("Edge", e_pts, [0.08] * 4, 0.15, up=(0, 1, 0))
    glow(edge, rgb(205, 210, 220), 0.6)
    return {"Body": sb.join([handle, pommel, guard, blade] + wraps + quillons + rust, "Body"), "Accent_Glow": edge}


def build_saber():
    acc = RARITY_COLOR["Epic"]
    hilt = sb.cylinder("Hilt", 0.14, 1.0, (0, 0, -0.5), verts=12, bevel=0.02)
    metal(hilt, METAL_DARK)
    rings = [ring("R%d" % i, 0.16, 0.04, (0, 0, -0.2 - i * 0.3), axis="Z") for i in range(3)]
    for r in rings:
        metal(r, METAL_LIGHT)
    pommel = sb.sphere("Pommel", 0.17, (0, 0, -1.05), subdiv=2)
    glow(pommel, acc, 1.2)
    # emitter is wide along Y (the blade's width) with two outward-tilted prongs flanking the blade
    em = sb.box("Emitter", (0.42, 0.72, 0.35), (0, 0, 0.15), bevel=0.05)
    metal(em, METAL_LIGHT)
    prongs, accents = [], [pommel]
    for i, sy in enumerate((-1, 1)):
        rot = (-sy * math.radians(10), 0, 0)
        c = Vector((0, sy * 0.3, 0.7))
        p = sb.box("Prong%d" % i, (0.2, 0.16, 0.9), c, rot, bevel=0.02)
        metal(p, METAL_LIGHT)
        prongs.append(p)
        off = Matrix.Rotation(rot[0], 3, "X") @ Vector((0, sy * 0.085, 0.05))
        g = sb.box("ProngGlow%d" % i, (0.06, 0.04, 0.6), c + off, rot, bevel=0)
        glow(g, acc, 1.2)
        accents.append(g)
    wings = [sb.cone_dir("Wing%d" % i, (0, sy * 0.3, 0.02), (0, sy, -0.25), 0.5, 0.08) for i, sy in enumerate((-1, 1))]
    for w in wings:
        metal(w, METAL_LIGHT)
    # tapered translucent blade in a deep violet (a pale core over a lighter shell washed it pink) with a thin core,
    # three energy barbs on the +Y edge and a sharp point cone so it looks like it cuts
    violet = acc
    blade = strip("Blade", [(0, 0, 0.35), (0, 0, 1.6), (0, 0, 2.9), (0, 0, 3.3)], [0.42, 0.5, 0.3, 0.04], 0.16, up=(0, 1, 0))
    glow(blade, violet, 1.0, alpha=0.85)
    core = strip("Core", [(0, 0, 0.35), (0, 0, 1.6), (0, 0, 2.9), (0, 0, 3.2)], [0.07, 0.09, 0.05, 0.02], 0.05, up=(0, 1, 0))
    glow(core, rgb(220, 190, 255), 1.0)
    barbs = []
    for i, (z, hw) in enumerate(((1.0, 0.23), (1.7, 0.245), (2.4, 0.19))):
        b = sb.cone_dir("Barb%d" % i, (0, hw - 0.03, z), (0, 1, 0.35), 0.26, 0.06)
        glow(b, violet, 1.2)
        barbs.append(b)
    point = sb.cone_dir("Point", (0, 0, 3.18), (0, 0, 1), 0.3, 0.05)
    glow(point, violet, 1.2)
    barbs.append(point)
    return {"Body": sb.join([hilt, em] + rings + prongs + wings, "Body"), "Blade_Glow": sb.join([blade, core] + barbs, "Blade_Glow"),
            "Accent_Glow": sb.join(accents, "Accent_Glow")}


def build_hammer():
    acc = RARITY_COLOR["Rare"]
    # thick tapered haft with a torus-stack grip wrap, two light rings and a collar under the head
    haft = sb.cylinder("Haft", 0.14, 2.6, (0, 0, 0.6), verts=10, r2=0.11)
    sb.paint(haft, rgb(52, 48, 58), roughness=0.7, metallic=0.2)
    # one chunky grip block between two light rings (a stack of wrap tori read as a screw thread)
    gripbox = sb.box("Grip", (0.3, 0.3, 0.8), (0, 0, -0.45), bevel=0.06)
    sb.paint(gripbox, GRIP, roughness=0.9)
    wraps = [ring("Wrap%d" % i, 0.19, 0.03, (0, 0, z), axis="Z") for i, z in enumerate((-0.05, -0.85))]
    for w in wraps:
        metal(w, METAL_LIGHT)
    hrings = [ring("HaftRing%d" % i, 0.17, 0.03, (0, 0, z), axis="Z") for i, z in enumerate((0.4, 1.3))]
    for r in hrings:
        metal(r, METAL_LIGHT)
    collar = sb.box("Collar", (0.5, 0.5, 0.3), (0, 0, 1.55), bevel=0.05)
    metal(collar, METAL_LIGHT)
    head = sb.box("Head", (1.5, 0.75, 0.8), (0, 0, 2.05), bevel=0.1)
    metal(head)
    faces = [sb.box("Face%d" % i, (0.4, 1.0, 1.05), (sx * 0.77, 0, 2.05), bevel=0.06) for i, sx in enumerate((-1, 1))]
    for f in faces:
        metal(f, rgb(90, 96, 110))  # mid tone so the blue coils read against it
    # coils at a strength that stays blue, so the striking faces read first
    coils = [ring("Coil%d" % i, 0.45, 0.07, (x, 0, 2.05), axis="X") for i, x in enumerate((-0.35, 0, 0.35))]
    for c in coils:
        glow(c, acc, 1.3)
    studs = []
    for sx in (-1, 1):
        for j, (y, z) in enumerate(((-0.28, 2.32), (0.28, 2.32), (-0.28, 1.78), (0.28, 1.78))):
            s = sb.cone_dir("Stud%d%d" % (sx + 1, j), (sx * 0.96, y, z), (sx, 0, 0), 0.4, 0.14)
            metal(s, METAL_DARK)
            studs.append(s)
    # a blue slot across each striking face, so the tier color sits on the part that hits
    faceglow = []
    for i, sx in enumerate((-1, 1)):
        fg = sb.box("FaceGlow%d" % i, (0.05, 0.6, 0.1), (sx * 0.98, 0, 2.05), bevel=0)
        glow(fg, acc, 1.5)
        faceglow.append(fg)
    # dark top plate with two blue slots along its long edges and four spikes at its corners: the top is dangerous too
    top = sb.plate_on("TopPlate", (0, 0, 2.45), (0, 0, 1), (0.9, 0.5, 0.08), METAL_DARK, bevel=0.03)
    topglow = []
    for i, sy in enumerate((-1, 1)):
        tg = sb.box("TopGlow%d" % i, (0.7, 0.05, 0.05), (0, sy * 0.22, 2.52), bevel=0)
        glow(tg, acc, 1.4)
        topglow.append(tg)
    spikes = []
    for j, (sx, sy) in enumerate(((-1, -1), (-1, 1), (1, -1), (1, 1))):
        sp = sb.cone_dir("TopSpike%d" % j, (sx * 0.38, sy * 0.17, 2.5), (0, 0, 1), 0.35, 0.09)
        metal(sp, METAL_DARK)
        spikes.append(sp)
    cap = sb.sphere("Cap", 0.16, (0, 0, 2.55), subdiv=2)
    glow(cap, acc, 1.8)
    return {"Body": sb.join([haft, gripbox, collar, head, top] + wraps + hrings + faces + studs + spikes, "Body"),
            "Accent_Glow": sb.join(coils + faceglow + topglow + [cap], "Accent_Glow")}


def build_reaper():
    acc = RARITY_COLOR["Legendary"]
    haft = sb.cylinder("Haft", 0.16, 3.2, (0, 0, 0.9), verts=10, r2=0.12)
    sb.paint(haft, rgb(24, 20, 30), roughness=0.7)
    bands = [ring("Band%d" % i, 0.17 - 0.04 * (z + 0.7) / 3.2, 0.035, (0, 0, z), axis="Z") for i, z in enumerate((-0.3, 0.5, 1.3, 2.05))]
    for b in bands:
        glow(b, AMBER, 1.2)
    collar = sb.cylinder("Collar", 0.16, 0.3, (0, 0, 2.3), verts=10)
    metal(collar, METAL_DARK)
    collar2 = ring("Collar2", 0.2, 0.05, (0, 0, 2.17), axis="Z")
    metal(collar2, GOLD, rough=0.3)
    # arc from the top of the haft sweeping forward (+Y) and down, like a reaper's blade
    pts = [(0, 0.2 + 2.4 * math.sin(math.radians(a)), 2.9 - 1.9 * (1 - math.cos(math.radians(a)))) for a in range(0, 100, 7)]
    n = len(pts)
    widths = [0.25 + 0.75 * math.sin(math.pi * (i / (n - 1)) ** 0.8) for i in range(n)]
    widths[-1] = 0.04
    blade = strip("Blade", pts, widths, 0.1, up=(1, 0, 0))
    sb.apply_modifiers(blade)
    gradient_metal(blade, rgb(72, 56, 98), rgb(26, 20, 34), roughness=0.4, metallic=0.5)  # Dark-element purple on the face
    # amber cutting edge along the outer (lower) side of the blade (2.5 rendered lemon-yellow)
    epts = [(p[0], p[1] + 0.02, p[2] - w * 0.42) for p, w in zip(pts, widths)]
    edge = strip("Edge", epts, [0.12] * n, 0.12, up=(1, 0, 0))
    glow(edge, AMBER, 1.3)
    # gold vein down the blade middle + three barbs on the convex spine
    vein = strip("Vein", pts, [0.06] * n, 0.16, up=(1, 0, 0))
    glow(vein, AMBER, 0.9)
    spikes = []
    for i in (3, 6, 9):
        p = Vector(pts[i])
        nrm = Vector((0, (p.y - 0.2) / 2.4 ** 2, (p.z - 1.0) / 1.9 ** 2)).normalized()
        s = sb.cone_dir("Spike%d" % i, p + nrm * 0.02, nrm, 0.3, 0.08)
        sb.paint(s, rgb(60, 48, 80), roughness=0.4, metallic=0.5)
        spikes.append(s)
    # bigger skull with dark sockets, gold eyes, long horns, a jaw and readable teeth
    sc = Vector((0, 0, 2.55))
    skull = sb.sphere("Skull", 0.36, sc, subdiv=2)
    sb.paint(skull, PAL["bone"], roughness=0.5)
    jaw = sb.box("Jaw", (0.3, 0.26, 0.16), (0, 0.12, 2.26), bevel=0.03)
    sb.paint(jaw, PAL["bone"], roughness=0.5)
    sockets, eyes = [], []
    for i, sx in enumerate((-1, 1)):
        d = Vector((sx * 0.45, 1, 0.2)).normalized()
        c = sc + d * 0.36
        so = sb.sphere("Socket%d" % i, 0.1, c - d * 0.02, subdiv=2)
        sb.paint(so, rgb(20, 16, 28), roughness=0.6)
        sockets.append(so)
        e = sb.sphere("Eye%d" % i, 0.055, c + d * 0.05, subdiv=1)
        glow(e, AMBER, 1.8)
        eyes.append(e)
    horns = []
    for i, sx in enumerate((-1, 1)):
        d = Vector((sx * 0.5, 0.1, 1)).normalized()
        h = sb.cone_dir("Horn%d" % i, sc + d * 0.34, d, 0.5, 0.08)
        sb.paint(h, PAL["bone"], roughness=0.5)
        horns.append(h)
    teeth = sb.claws("Tooth", (0, 0.22, 2.2), (0, 0, -1), count=4, length=0.2, radius=0.05, spread=0.08)
    return {"Body": sb.join([haft, collar, collar2, blade, skull, jaw] + spikes + sockets + horns + teeth, "Body"),
            "Accent_Glow": sb.join(bands + [edge, vein] + eyes, "Accent_Glow")}


# ---------------------------------------------------------------------------- orbital emitters + orbs
def emitter(acc, rings_n, head="sphere", head_color=None, ring_color=None, ring_strength=2.5):
    """Handle + head + glowing core + gyroscope rings. head="drum" makes a flat disc launcher (lit rim seam, core
    showing on top); head_color paints the head as polished metal (GOLD for Legendary) instead of METAL_LIGHT."""
    handle = sb.cylinder("Handle", 0.1, 0.9, (0, 0, -0.45), verts=10, bevel=0.02)
    sb.paint(handle, GRIP, roughness=0.8)
    extra = []
    if head == "drum":
        hd = sb.cylinder("Head", 0.36, 0.22, (0, 0, 0.25), verts=18, bevel=0.03)
        core = sb.sphere("Core", 0.14, (0, 0, 0.36), subdiv=2)
        glow(core, acc, 2.0)
        seam = ring("Slot", 0.37, 0.025, (0, 0, 0.25), axis="Z")
        glow(seam, acc, 1.5)
        extra.append(seam)
    else:
        hd = sb.sphere("Head", 0.32, (0, 0, 0.25), subdiv=2)
        core = sb.sphere("Core", 0.2, (0, 0, 0.25), subdiv=2)
        glow(core, acc, 4)
    if head_color is None:
        metal(hd, METAL_LIGHT)
    else:
        sb.paint(hd, head_color, roughness=0.3, metallic=0.6)
    rings = []
    tilts = ((20, 0), (55, 40), (90, 80))
    for i in range(rings_n):
        r = ring("Ring%d" % i, 0.5 + i * 0.25, 0.03, (0, 0, 0.25), axis="Z")
        r.rotation_euler = (math.radians(tilts[i][0]), math.radians(tilts[i][1]), 0)
        glow(r, ring_color or acc, ring_strength)
        rings.append(r)
    return [handle, hd], [core] + extra + rings


def build_guardian():
    acc = RARITY_COLOR["Rare"]
    # emitter = flat disc launcher (drum with a lit rim seam) instead of a second grey ball
    body, glows = emitter(acc, 1, head="drum", ring_strength=1.6)
    # three thick claws curving outward from the drum rim, cupping the disc as it launches
    for i in range(3):
        a = math.radians(90 + i * 120)
        c = sb.cone_dir("Claw%d" % i, (math.cos(a) * 0.3, math.sin(a) * 0.3, 0.3), (math.cos(a), math.sin(a), 0.45), 0.42, 0.09)
        metal(c)
        body.append(c)
    # the orb: dark hub + three curved scimitar blades (plate_poly in the XY plane) pitched like a fan, each with a
    # lit leading edge, so the silhouette says 'spinning' (straight wings read as a toy jet)
    hub_c = Vector((2.0, 0, 0.6))
    hub = sb.sphere("Hub", 0.3, hub_c, subdiv=2)
    metal(hub, METAL_DARK)
    orb, orb_glow = [hub], []
    # the blade disc is tipped ~30 degrees toward the render view: flat in XY it foreshortens to a sliver at 22 degrees
    n = Vector((0.5, 0.23, 1.0)).normalized()
    u = Vector((0, 1, 0)).cross(n).normalized()
    v = n.cross(u).normalized()
    hg = ring("HubGlow", 0.28, 0.06, hub_c, axis="Z")
    hg.rotation_euler = n.to_track_quat("Z", "Y").to_euler()
    glow(hg, acc, 1.5)
    orb_glow.append(hg)
    outline = [(0.15, 0.12), (0.5, 0.24), (0.85, 0.2), (1.05, 0.0), (0.75, -0.1), (0.35, -0.14), (0.15, -0.12)]
    edge = [(0.15, 0.12), (0.5, 0.24), (0.85, 0.2), (1.05, 0.0), (0.98, 0.0), (0.83, 0.13), (0.5, 0.17), (0.15, 0.05)]
    pitch = math.radians(22)
    for i in range(3):
        a = math.radians(i * 120)
        x_dir = u * math.cos(a) + v * math.sin(a)
        y_dir = (-u * math.sin(a) + v * math.cos(a)) * math.cos(pitch) + n * math.sin(pitch)
        b = plate_poly("B%d" % i, outline, 0.14, hub_c, x_dir, y_dir)
        metal(b)
        orb.append(b)
        e = plate_poly("Edge%d" % i, edge, 0.18, hub_c, x_dir, y_dir)
        glow(e, acc, 1.7)
        orb_glow.append(e)
    return {"Body": sb.join(body, "Body"), "Accent_Glow": sb.join(glows, "Accent_Glow"), "Orb": sb.join(orb, "Orb"), "Orb_Glow": sb.join(orb_glow, "Orb_Glow")}


def build_storm():
    acc = RARITY_COLOR["Epic"]
    body, glows = emitter(acc, 2, ring_strength=1.2)
    # tesla coil: tapered dark ring stack under the head, core stub with glow coils and two prongs on top
    for i, (mj, z) in enumerate(((0.3, -0.05), (0.24, -0.2), (0.18, -0.35))):
        r = ring("Base%d" % i, mj, 0.05, (0, 0, z), axis="Z")
        metal(r, METAL_DARK)
        body.append(r)
    coil = sb.cylinder("Coil", 0.12, 0.45, (0, 0, 0.75), verts=8)
    metal(coil, METAL_DARK)
    body.append(coil)
    for i in range(3):
        c = ring("CoilGlow%d" % i, 0.19, 0.04, (0, 0, 0.62 + i * 0.13), axis="Z")
        glow(c, acc, 1.2)
        glows.append(c)
    # two fat prongs with a jagged spark arcing between their tips, and two small bolts leaping off it
    for i, sy in enumerate((-1, 1)):
        p = sb.cone_dir("Prong%d" % i, (0, sy * 0.08, 0.95), (0, sy * 0.5, 1), 0.55, 0.1)
        metal(p, METAL_LIGHT)
        body.append(p)
    pale = rgb(225, 235, 255)
    spark = strip("Spark", [(0, -0.3, 1.42), (0, -0.14, 1.52), (0, 0.02, 1.38), (0, 0.16, 1.5), (0, 0.3, 1.42)],
                  [0.04, 0.08, 0.1, 0.08, 0.04], 0.05, up=(0, 0, 1))
    glow(spark, pale, 1.6)
    glows.append(spark)
    glows.append(zigzag("Spark1", (0, 0.02, 1.4), (0.5, 0.3, 1), (0.8, 0, -0.4), seg=0.12, widths=(0.07, 0.05, 0.04, 0.015), strength=1.6))
    glows.append(zigzag("Spark2", (0, 0.02, 1.4), (-0.3, -0.4, 1), (0.9, -0.3, 0.15), seg=0.11, widths=(0.06, 0.05, 0.03, 0.015), strength=1.6))
    # the orb: a dark storm core under a translucent purple shell, with six flat zigzag bolts (cones read as a sea
    # urchin, and a ring made it a planet like Halo's sun)
    oc = Vector((1.6, 0, 0.6))
    core = sb.sphere("Orb", 0.2, oc, subdiv=2)
    sb.paint(core, rgb(40, 28, 64), roughness=0.5, metallic=0.2)
    shell = sb.sphere("Shell", 0.3, oc, subdiv=3)
    glow(shell, acc, 0.9, alpha=0.55)
    parts = [core, shell]
    cam = Vector((0.84, 0.39, 0.37))  # render camera direction: bolts face it so the zigzags read
    dirs = [(1, 0.3, 0.45), (-0.2, 1, 0.3), (-1, -0.2, 0.5), (0.4, -1, -0.3), (0.8, 0.5, -0.6), (-0.6, -0.7, -0.5)]
    for i, d in enumerate(dirs):
        dv = Vector(d).normalized()
        perp = dv.cross(cam)
        if perp.length < 0.2:
            perp = dv.cross(Vector((0, 0, 1)))
        parts.append(zigzag("Bolt%d" % i, oc + dv * 0.28, dv, perp, seg=0.2 if i % 2 == 0 else 0.16, strength=1.6))
    return {"Body": sb.join(body, "Body"), "Accent_Glow": sb.join(glows, "Accent_Glow"), "Orb_Glow": sb.join(parts, "Orb_Glow")}


def build_halo():
    acc = RARITY_COLOR["Legendary"]
    # gold head and golden rings; the outer ring is solid gold metal so the gyroscope reads as a gold cage
    body, glows = emitter(acc, 3, head_color=GOLD, ring_color=AMBER, ring_strength=1.2)
    cage = glows.pop()
    metal(cage, GOLD, rough=0.3)
    body.append(cage)
    # gold crown cupping the head from below (clear of the rings) + a gold band on the handle
    crown = []
    for i in range(6):
        a = i / 6 * 2 * math.pi
        c = sb.cone_dir("Ray%d" % i, (math.cos(a) * 0.3, math.sin(a) * 0.3, 0.0), (math.cos(a), math.sin(a), 0.35), 0.3, 0.09)
        metal(c, GOLD)
        crown.append(c)
    body += crown
    band = ring("Band", 0.12, 0.03, (0, 0, -0.2), axis="Z")
    metal(band, GOLD)
    body.append(band)
    # the sun: a visibly hot orange center under a low, translucent gold shell (shell + core used to add up to one
    # cream blob), a star of long/short orange rays plus short secondary rays between them for a starburst
    sc = Vector((2.2, 0, 0.6))
    sun = sb.sphere("Sun", 0.35, sc, subdiv=3)
    glow(sun, rgb(255, 190, 60), 0.35, alpha=0.45)
    sun_core = sb.sphere("SunCore", 0.22, sc, subdiv=2)
    glow(sun_core, rgb(255, 100, 20), 2.0)
    rays = []
    ray_col = rgb(255, 140, 35)
    for i in range(8):
        a = i / 8 * 2 * math.pi
        d = Vector((math.cos(a), math.sin(a), 0))
        r = sb.cone_dir("SunRay%d" % i, sc + d * 0.3, d, 0.6 if i % 2 == 0 else 0.35, 0.15)
        glow(r, ray_col, 1.0)
        rays.append(r)
    for i, sz in enumerate((-1, 1)):
        r = sb.cone_dir("SunRay%d" % (8 + i), sc + Vector((0, 0, sz * 0.3)), (0, 0, sz), 0.35, 0.15)
        glow(r, ray_col, 1.0)
        rays.append(r)
    for i in range(8):
        a = (i + 0.5) / 8 * 2 * math.pi
        d = Vector((math.cos(a), math.sin(a), 0))
        r = sb.cone_dir("SunRay%d" % (10 + i), sc + d * 0.3, d, 0.22, 0.08)
        glow(r, ray_col, 1.0)
        rays.append(r)
    for i in range(4):
        a = math.radians(45 + i * 90)
        d = Vector((math.cos(a), 0, math.sin(a)))
        r = sb.cone_dir("SunRay%d" % (18 + i), sc + d * 0.3, d, 0.22, 0.08)
        glow(r, ray_col, 1.0)
        rays.append(r)
    return {"Body": sb.join(body, "Body"), "Accent_Glow": sb.join(glows, "Accent_Glow"), "Orb_Glow": sb.join([sun, sun_core] + rays, "Orb_Glow")}


BUILDERS = {
    "Starter": build_starter, "Burst": build_burst, "Blade": build_blade, "Scatter": build_scatter,
    "Marksman": build_marksman, "Hammer": build_hammer, "Guardian": build_guardian, "Arc": build_arc,
    "Hornet": build_hornet, "Saber": build_saber, "Storm": build_storm, "Ion": build_ion,
    "Nova": build_nova, "Reaper": build_reaper, "Halo": build_halo,
}


def build_all(names=None, render=True):
    names = names or list(BUILDERS.keys())
    for name in names:
        sb.reset()
        parts = BUILDERS[name]()
        objs = list(parts.values())
        entry = sb.export_model("weapons/" + name, objs, {"kind": "weapon", "rarity": RARITY[name], "display": NAMES[name], "forward": "+Y (Blender)"})
        print("%-9s parts=%d tris=%5d size=%s" % (name, len(objs), entry["tris"], entry["size_studs"]))
        if render:
            sb.render_model(name, objs, "weapons/%s.png" % name, angle_deg=65, elev_deg=22, floor=False)


if __name__ == "__main__":
    names = [a for a in sys.argv[1:] if a in BUILDERS] or None
    build_all(names, render=os.environ.get("SB_NO_RENDER") != "1")
