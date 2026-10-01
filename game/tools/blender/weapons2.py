"""Swarm Break weapons, pass 2 (v2): the shared recipe (rarity palette, two-tone paint, layered glow, gun / melee /
orb helpers) and the build loop. Mirrors enemies2.py. See RECIPE.md, last section.

One file per weapon: weapon_<Name>.py with
    build() -> {part_name: object}    parts: Body, Accent_Glow, optional Halo_Glow, Blade_Glow / Edge_Glow, Orb, Orb_Glow
    VIEW = (angle_deg, elev_deg)      render camera, default (62, 20)
Run:  cd tools/blender && python3 weapons2.py [Starter Burst ...]
      SB_NO_RENDER=1 skips renders, SB_NO_AO=1 skips the AO bake (10-second shape check), SB_ASSETS=<dir> redirects output.

Conventions (the game attaches by these, WeaponModels.luau / Meshes.luau):
- Guns: grip at the origin (the grip's top centre), barrel toward +Y, up = +Z, 1 unit = 1 stud. A rifle is ~3.5 studs
  long, a pistol ~2. The receiver sits over the grip with its barrel axis around z = 0.45..0.6.
- Melee: handle at the origin, blade along +Z, cutting edge toward +Y, the flat faces toward +/-X (the render camera
  looks mostly from +X at angle 62).
- Orbital: the hand emitter at the origin; the orbs are separate parts (Orb = metal, Orb_Glow = light) placed beside
  it at x = 1.5..2.5 so the render shows them; the game spins them round the player.
- Exported part names: Body (all the metal, one joined mesh), Accent_Glow (the bright glow cores), Halo_Glow (the
  dimmer wider halos; give it Transparency in Studio), Blade_Glow / Edge_Glow for blades, Orb and Orb_Glow for
  orbitals. Anything ending in _Glow becomes Neon in Studio. Keep the names the v1 model exported; add more if needed.

The recipe (the v1 judges + the top games):
- TWO-TONE body before any glow: a dark base (paint_base: gunmetal / navy / ink) plus ONE bright panel colour per
  weapon (paint_panel with PANEL[name]) over a real area (a slide, a cover, a stock, a mag, a pump). Legendary flips
  it: the base is gold metal and the second tone is dark.
- Rarity is also a MATERIAL (STYLE): Epic panels are glossy dark purple, Legendary bodies are gold metal, not trim.
- ONE accent glow in the rarity colour, layered: a small bright core (glow_core) plus a wider dimmer halo (glow_halo).
  glow_slot / glow_disc / glow_ring / glow_edge make the pairs. Cores in Accent_Glow, halos in Halo_Glow.
- Pushed proportions: muzzle brake as big as the receiver (muzzle_brake), magazines twice real size (magazine), barrels
  stepping down in three clear stages (stepped_barrel), fat grips (grip), short stocks (stock). Higher tiers add real
  geometry (fins, rings, spikes, wings via fin / ring / sb2.horn), not just a colour swap.
- Melee: a curved blade with an asymmetric tip and serrations (blade_outline + plate_poly), a guard as wide as the
  blade (guard), glow that follows the edge (glow_edge). Orbs: ONE bold shape each (orb_ball / orb_ring / orb_star /
  orb_blade), no small sub-parts, because they read while spinning.
- Faceted: flat shading, chamfers (bevel segments=1), 400-1500 tris per weapon, under 10 exported parts. finish()
  checks all of that and prints a WARNING when a model is over budget.
"""
import importlib
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
from sb2 import top_light, belly, facing, band, stripes, spots, near, region, mix, darken, lighten

# ---------------------------------------------------------------- registry (ids match Weapons.luau)
WEAPONS = ["Starter", "Burst", "Blade", "Scatter", "Marksman", "Hammer", "Guardian", "Arc", "Hornet", "Saber", "Storm",
           "Ion", "Nova", "Reaper", "Halo"]
RARITY = {
    "Starter": "Common", "Burst": "Common", "Blade": "Common",
    "Scatter": "Rare", "Marksman": "Rare", "Hammer": "Rare", "Guardian": "Rare",
    "Arc": "Epic", "Hornet": "Epic", "Saber": "Epic", "Storm": "Epic", "Ion": "Epic",
    "Nova": "Legendary", "Reaper": "Legendary", "Halo": "Legendary",
}
NAMES = {
    "Starter": "Starter Pistol", "Burst": "Burst SMG", "Blade": "Rusty Blade", "Scatter": "Shotgun",
    "Marksman": "Sniper Rifle", "Hammer": "Shock Hammer", "Guardian": "Spinning Blades", "Arc": "Laser Rifle",
    "Hornet": "Triple Rocket", "Saber": "Energy Sword", "Storm": "Lightning Orbs", "Ion": "Laser Beam",
    "Nova": "Heavy Cannon", "Reaper": "Dark Scythe", "Halo": "Sun Orbs",
}
KIND = {  # the game's Weapons.Defs[id].Kind
    "Starter": "Hitscan", "Burst": "Hitscan", "Blade": "Melee", "Scatter": "Hitscan", "Marksman": "Hitscan",
    "Hammer": "Melee", "Guardian": "Orbital", "Arc": "Hitscan", "Hornet": "Hitscan", "Saber": "Melee",
    "Storm": "Orbital", "Ion": "Beam", "Nova": "Hitscan", "Reaper": "Melee", "Halo": "Orbital",
}
DEFAULT_VIEW = (62, 20)
RENDER_PAD = 0.85   # camera distance factor for render_model2 (1.12 is the enemy default; weapons are long and thin)

# ---------------------------------------------------------------- palette
RARITY_COLOR = {  # Theme.Rarity (the UI colours)
    "Common": rgb(190, 190, 200), "Rare": rgb(70, 140, 255), "Epic": rgb(170, 80, 255), "Legendary": rgb(255, 170, 30),
}
GLOW = {  # emissive core colour per rarity, tuned to keep its hue under bloom + AgX (a bright pure gold drifts to lemon)
    "Common": rgb(212, 216, 228), "Rare": rgb(62, 132, 255), "Epic": rgb(168, 72, 255), "Legendary": rgb(255, 150, 28),
}
GUNMETAL = rgb(42, 44, 54)      # Common base
NAVY = rgb(30, 36, 60)          # Rare base
INK = rgb(24, 18, 34)           # Epic base (near-black with a purple cast)
GOLD = rgb(224, 168, 56)        # Legendary base (metallic)
BRONZE_DARK = rgb(54, 38, 32)   # Legendary second tone
PLUM = rgb(98, 42, 162)         # Epic panels (glossy)
RUBBER = rgb(26, 25, 30)        # grips
BONE = rgb(228, 220, 200)       # teeth, skulls, pale edges
STEEL = rgb(140, 146, 160)      # bare metal bits (bolts, sights) when you want a third, neutral tone
RUST = rgb(150, 82, 40)

# Per-rarity material and glow strengths. base/panel are the defaults; PANEL[name] is the bright tone per weapon.
STYLE = {
    "Common": dict(base=GUNMETAL, base_rough=0.6, base_metal=0.2, panel=rgb(236, 184, 44), panel_rough=0.5, panel_metal=0.05,
                   core=1.4, halo=0.55),
    "Rare": dict(base=NAVY, base_rough=0.55, base_metal=0.25, panel=rgb(226, 230, 236), panel_rough=0.45, panel_metal=0.1,
                 core=2.0, halo=0.8),
    "Epic": dict(base=INK, base_rough=0.5, base_metal=0.3, panel=PLUM, panel_rough=0.2, panel_metal=0.15,
                 core=2.0, halo=0.8),
    "Legendary": dict(base=GOLD, base_rough=0.3, base_metal=0.85, panel=BRONZE_DARK, panel_rough=0.45, panel_metal=0.3,
                      core=1.6, halo=0.7),
}
# The second tone per weapon: a bright panel colour (Legendary: the dark second tone on the gold body). Override in the
# weapon file with kit(name, panel=...) if you must, but keep it ONE colour per weapon.
PANEL = {
    "Starter": rgb(236, 184, 44), "Burst": rgb(52, 196, 190), "Blade": rgb(196, 104, 46),
    "Scatter": rgb(226, 74, 52), "Marksman": rgb(226, 230, 236), "Hammer": rgb(150, 214, 60), "Guardian": rgb(240, 140, 40),
    "Arc": rgb(104, 46, 170), "Hornet": rgb(150, 40, 130), "Saber": rgb(76, 44, 168), "Storm": rgb(124, 32, 120), "Ion": rgb(96, 50, 184),
    "Nova": BRONZE_DARK, "Reaper": rgb(30, 22, 30), "Halo": rgb(236, 230, 214),
}


# ---------------------------------------------------------------- paint (vertex colours through sb2.paint_rules)
def paint_base(ob, rarity, color=None, roughness=None, metallic=None, extra=()):
    """The body tone: dark metal lit from above, darker underneath (Legendary: gold). Receivers, barrels, brakes, guards.
    color overrides STYLE[rarity]['base']; extra = more sb2 paint rules applied after the lighting."""
    st = STYLE[rarity]
    c = color or st["base"]
    rules = [top_light(lighten(c, 0.28), power=0.8, amount=1.0), belly(darken(c, 0.55), amount=0.7, power=1.2)] + list(extra)
    return sb2.paint_rules(ob, c, rules, roughness=st["base_rough"] if roughness is None else roughness,
                           metallic=st["base_metal"] if metallic is None else metallic)


def paint_panel(ob, rarity, color=None, roughness=None, metallic=None, extra=()):
    """The second tone over a real area (slide, cover, stock, mag, pump): bright colour, lit from above.
    color = PANEL[name] usually (default STYLE[rarity]['panel']); Epic panels are glossy, Legendary panels dark."""
    st = STYLE[rarity]
    c = color or st["panel"]
    rules = [top_light(lighten(c, 0.12), power=0.8, amount=1.0), belly(darken(c, 0.5), amount=0.7, power=1.2)] + list(extra)
    return sb2.paint_rules(ob, darken(c, 0.86), rules, roughness=st["panel_rough"] if roughness is None else roughness,
                           metallic=st["panel_metal"] if metallic is None else metallic)


def paint_grip(ob, color=RUBBER):
    """Matte rubber for grips, handles and pumps' finger grooves."""
    return sb2.paint_rules(ob, color, [top_light(lighten(color, 0.18), 0.8, 1.0), belly(darken(color, 0.6), 0.6)], roughness=0.85)


def paint_metal(ob, color, roughness=0.5, metallic=0.2, extra=()):
    """Any other hard-surface tone (STEEL bolts and sights, BONE teeth, RUST): lit from above, darker underneath."""
    rules = [top_light(lighten(color, 0.22), 0.8, 1.0), belly(darken(color, 0.55), 0.7, 1.2)] + list(extra)
    return sb2.paint_rules(ob, darken(color, 0.9), rules, roughness=roughness, metallic=metallic)


def glow_core(ob, rarity, strength=None, color=None):
    """The bright small glow: emission STYLE[rarity]['core'] (1.4-2.0). The object's name gets a _Glow suffix."""
    return sb2.flat_color(ob, color or GLOW[rarity], roughness=0.4, emission=STYLE[rarity]["core"] if strength is None else strength)


def glow_halo(ob, rarity, strength=None, color=None, alpha=1.0):
    """The dimmer wider glow around a core: a darker vertex colour (so it stays dimmer as Neon in game) at emission
    STYLE[rarity]['halo'] (0.55-0.8). alpha < 1 makes it translucent in renders (Studio: set Transparency)."""
    c = color or mix(GLOW[rarity], (0, 0, 0, 1), 0.42)
    return sb2.flat_color(ob, c, roughness=0.5, emission=STYLE[rarity]["halo"] if strength is None else strength, alpha=alpha)


class Kit:
    """Everything one weapon file needs: its rarity, style, the two tones and paint shortcuts.
        k = weapons2.kit("Starter")           # k.rarity, k.style, k.panel_color, k.glow
        k.base(ob); k.panel(ob); k.grip(ob); k.metal(ob, STEEL); k.core(ob); k.halo(ob)
        k.finish(body_pieces, cores, halos, extra={...}) -> the parts dict for build()."""

    def __init__(self, name, panel=None):
        self.name = name
        self.rarity = RARITY[name]
        self.style = STYLE[self.rarity]
        self.panel_color = panel or PANEL.get(name) or self.style["panel"]
        self.glow = GLOW[self.rarity]

    def base(self, ob, color=None, **kw):
        return paint_base(ob, self.rarity, color, **kw)

    def panel(self, ob, color=None, **kw):
        return paint_panel(ob, self.rarity, color or self.panel_color, **kw)

    def grip(self, ob, color=RUBBER):
        return paint_grip(ob, color)

    def metal(self, ob, color=STEEL, **kw):
        return paint_metal(ob, color, **kw)

    def core(self, ob, strength=None, color=None):
        return glow_core(ob, self.rarity, strength, color)

    def halo(self, ob, strength=None, color=None, alpha=1.0):
        return glow_halo(ob, self.rarity, strength, color, alpha)

    def finish(self, body, cores=(), halos=(), extra=None, core_name="Accent_Glow", halo_name="Halo_Glow", budget=1500):
        """Join the painted pieces into the exported parts: body -> Body, cores -> core_name, halos -> halo_name, plus
        extra {name: object or [objects]} (Orb, Orb_Glow, Blade_Glow ...). Returns the parts dict, checked by finish()."""
        parts = {"Body": join(body, "Body")}
        if cores:
            parts[core_name] = join(cores, core_name)
        if halos:
            parts[halo_name] = join(halos, halo_name)
        for k, v in (extra or {}).items():
            parts[k] = join(v, k) if isinstance(v, (list, tuple)) else v
        return finish(parts, budget)


def kit(name, panel=None):
    """Kit for weapon id `name`; panel overrides PANEL[name] (one bright colour per weapon)."""
    return Kit(name, panel)


# ---------------------------------------------------------------- small utilities
def join(objs, name):
    """sb.join that also accepts a single object or an empty list (returns None)."""
    if objs is None:
        return None
    if not isinstance(objs, (list, tuple)):
        objs = [objs]
    objs = [o for o in objs if o is not None]
    if not objs:
        return None
    if len(objs) == 1:
        sb.apply_modifiers(objs[0])
        objs[0].name = name
        return objs[0]
    return sb.join(list(objs), name)


def _flat(ob):
    sb2.shade_flat(ob)
    return ob


def _shift(ob, offset):
    """Move the mesh inside the object (local space) without moving the object."""
    off = Vector(offset)
    for v in ob.data.vertices:
        v.co += off
    return ob


def _rad(rot_deg):
    return tuple(math.radians(a) for a in rot_deg)


def _track(direction):
    """Euler that turns local +Z onto `direction`."""
    return Vector(direction).normalized().to_track_quat("Z", "Y").to_euler()


def cut(ob, cutters, solver="EXACT"):
    """Boolean-subtract each cutter object from ob (vents, slots, bores, notches); cutters are deleted."""
    for c in cutters:
        if c is None:
            continue
        m = ob.modifiers.new("Cut", "BOOLEAN")
        m.operation = "DIFFERENCE"
        m.object = c
        m.solver = solver
        sb.apply_modifiers(ob)
        bpy.data.objects.remove(c, do_unlink=True)
    return _flat(ob)


# ---------------------------------------------------------------- primitives (faceted, transforms applied)
def block(name, size, at, rot_deg=(0, 0, 0), bevel=0.05, segments=1, anchor=(0, 0, 0)):
    """Chamfered box. size = full extents (x, y, z); at = world point where the anchor lands; anchor = (-1..1 per axis)
    picks the point inside the box that sits on `at`: (0,0,0) centre, (0,0,1) top-centre, (0,-1,0) back-face centre,
    (0,1,-1) front-bottom edge. rot_deg (degrees, XYZ) rotates the box about the anchor. Modifiers applied, flat."""
    ob = sb.box(name, size, at, _rad(rot_deg), bevel=bevel, segments=segments)
    if any(anchor):
        _shift(ob, (-anchor[0] * size[0] / 2, -anchor[1] * size[1] / 2, -anchor[2] * size[2] / 2))
    sb.apply_modifiers(ob)
    sb.apply_transforms(ob)
    return _flat(ob)


def tube(name, at, length, radius, r2=None, direction=(0, 1, 0), sides=10, anchor=-1):
    """Faceted cylinder (cone when r2 is given: r2 = radius at the far end) running `length` along `direction`.
    anchor -1: `at` is the near end (default), 0: the centre, 1: the far end."""
    d = Vector(direction).normalized()
    bpy.ops.mesh.primitive_cone_add(vertices=sides, radius1=radius, radius2=radius if r2 is None else r2, depth=length)
    ob = bpy.context.active_object
    ob.name = name
    ob.rotation_euler = _track(d)
    ob.location = Vector(at) - d * (length / 2 * anchor)
    sb.apply_transforms(ob)
    return _flat(ob)


def disc(name, radius, at, thickness=0.05, direction=(0, 1, 0), sides=12):
    """Flat faceted disc centred at `at`, its face normal along `direction` (a lit bore, a lens, a cap)."""
    return tube(name, at, thickness, radius, direction=direction, sides=sides, anchor=0)


def ring(name, major, minor, at, axis="Y", segs=12, msegs=5, rot_deg=None):
    """Low-poly torus (segs x msegs, ~120 tris) centred at `at`, its axis along X / Y / Z, or any rot_deg (axis = local Z)."""
    bpy.ops.mesh.primitive_torus_add(major_segments=segs, minor_segments=msegs, major_radius=major, minor_radius=minor)
    ob = bpy.context.active_object
    ob.name = name
    ob.location = at
    if rot_deg is not None:
        ob.rotation_euler = _rad(rot_deg)
    else:
        ob.rotation_euler = {"X": (0, math.radians(90), 0), "Y": (math.radians(90), 0, 0), "Z": (0, 0, 0)}[axis]
    sb.apply_transforms(ob)
    return _flat(ob)


def ball(name, radius, at, subdiv=2, scale=(1, 1, 1)):
    """Faceted icosphere (subdiv 1 = 20 tris, 2 = 80, 3 = 320)."""
    return sb2.lowpoly_sphere(name, radius, at, scale=scale, subdiv=subdiv, flat=True)


def wedge(name, size, at, rot_deg=(0, 0, 0), taper=0.5, anchor=(0, 0, 0)):
    """sb2.wedge with an anchor: a box that narrows toward +Y (taper = front width / back width)."""
    ob = sb2.wedge(name, size, at, _rad(rot_deg), taper=taper)
    if any(anchor):
        _shift(ob, (-anchor[0] * size[0] / 2, -anchor[1] * size[1] / 2, -anchor[2] * size[2] / 2))
    sb.apply_transforms(ob)
    return _flat(ob)


def orient(ob, x_dir, y_dir):
    """Rotate ob so its local X points along x_dir and local Y along y_dir (world)."""
    x = Vector(x_dir).normalized()
    y = Vector(y_dir).normalized()
    z = x.cross(y).normalized()
    y = z.cross(x).normalized()
    ob.rotation_euler = Matrix((x, y, z)).transposed().to_euler()
    return ob


def plate_poly(name, pts2d, thickness, at, u_dir=(0, 1, 0), v_dir=(0, 0, 1), bevel=0.0):
    """Solid faceted plate from a 2D outline [(u, v), ...] lying in the plane spanned by u_dir and v_dir through `at`,
    thickness along their normal (u x v). Any silhouette: swept fins, blades with asymmetric tips, stars, wings.
    Default plane: u = +Y (forward), v = +Z (up), thickness along X. Modifiers applied."""
    me = bpy.data.meshes.new(name)
    bm = bmesh.new()
    vs = [bm.verts.new((u, v, 0)) for u, v in pts2d]
    # bug fix: bmesh's ngon triangulation folds thin concave outlines (glow_edge strips) into overlapping triangles
    # that cover half the blade; tessellate_polygon is exact. Triangles keep the outline's winding.
    from mathutils.geometry import tessellate_polygon
    sgn = sum(pts2d[i][0] * pts2d[(i + 1) % len(pts2d)][1] - pts2d[(i + 1) % len(pts2d)][0] * pts2d[i][1] for i in range(len(pts2d)))
    for tri in tessellate_polygon([[Vector((u, v, 0)) for u, v in pts2d]]):
        a, b, c = (pts2d[i] for i in tri)
        if ((b[0] - a[0]) * (c[1] - a[1]) - (c[0] - a[0]) * (b[1] - a[1])) * sgn < 0:
            tri = (tri[0], tri[2], tri[1])
        try:
            bm.faces.new([vs[i] for i in tri])
        except ValueError:
            pass
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    ob.location = at
    orient(ob, u_dir, v_dir)
    m = ob.modifiers.new("Solid", "SOLIDIFY")
    m.thickness = thickness
    m.offset = 0
    m.use_even_offset = True
    if bevel > 0:
        sb.add_bevel(ob, bevel, 1, 40)
    sb.apply_modifiers(ob)
    sb.apply_transforms(ob)
    return _flat(ob)


fin = plate_poly  # a swept fin / wing / crest is just a plate with a silhouette


def bolt(name, at, normal, radius=0.06, height=0.05):
    """Kenney-style hex bolt head sitting on a surface point, its axis along `normal` (out of the surface)."""
    n = Vector(normal).normalized()
    return tube(name, Vector(at) - n * (height * 0.3), height, radius, direction=n, sides=6)


def bolts(name, points, normal, radius=0.06, height=0.05):
    """Several hex bolts (a row on a side plate): points = world points on the surface, one shared normal."""
    return [bolt("%s%d" % (name, i), p, normal, radius, height) for i, p in enumerate(points)]


# ---------------------------------------------------------------- gun helpers
def receiver(name, size, at, bevel=0.07, anchor=(0, 0, 0)):
    """The receiver: a big chamfered block (alias of block with a bigger chamfer). at/anchor as in block."""
    return block(name, size, at, bevel=bevel, anchor=anchor)


def stepped_barrel(name, at, steps, sides=10, collar=0.05, collar_len=0.1, direction=(0, 1, 0)):
    """A barrel that steps DOWN toward the muzzle: steps = [(radius, length), ...] from the receiver outward, e.g.
    [(0.22, 0.5), (0.16, 0.4), (0.11, 0.3)]. Every step starts with a short fatter collar (radius + collar, collar_len
    long) so the three stages read at a distance. One joined object; ob["muzzle"] = the far end point,
    ob["length"] = total length. Paint it with paint_base."""
    d = Vector(direction).normalized()
    p = Vector(at)
    pieces = []
    for i, (r, L) in enumerate(steps):
        if collar > 0 and collar_len > 0:
            pieces.append(tube("%s_c%d" % (name, i), p, collar_len, r + collar, direction=d, sides=sides))
        pieces.append(tube("%s_s%d" % (name, i), p, L, r, direction=d, sides=sides))
        p = p + d * L
    ob = join(pieces, name)
    ob["muzzle"] = list(p)
    ob["length"] = (p - Vector(at)).length
    return ob


def muzzle_brake(name, at, size, slots=2, slot_w=0.08, slot_depth=0.65, bore=0.12, shape="box", sides=10, bevel=0.05,
                 direction=(0, 1, 0), top_slots=False):
    """The compensator: a block as fat as the receiver at the muzzle. at = its back centre (the barrel's ob["muzzle"]);
    size = (width, length, height) for shape="box" or (radius, length) for shape="cyl". `slots` vent slots (slot_w wide,
    slot_depth of the height deep) are cut through it side to side, top_slots=True cuts them from the top as well, and
    `bore` is the radius of the hole cut into the front face (0 = none). ob["bore"] = the front centre point.
    Put a glow_disc at ob["bore"] for the lit bore."""
    d = Vector(direction).normalized()
    if shape == "cyl":
        r, L = size[0], size[1]
        ob = tube(name, at, L, r, direction=d, sides=sides)
        w = h = r * 2
    else:
        w, L, h = size
        ob = block(name, (w, L, h), Vector(at) + d * (L / 2), bevel=bevel)
    cutters = []
    for i in range(slots):
        y = L * (0.25 + 0.5 * (i + 0.5) / slots) if slots > 1 else L * 0.5
        c = Vector(at) + d * y
        cutters.append(block("%s_slot%d" % (name, i), (w + 0.2, slot_w, h * slot_depth), c, bevel=0))
        if top_slots:
            cutters.append(block("%s_top%d" % (name, i), (w * slot_depth, slot_w, h + 0.2), c, bevel=0))
    if bore > 0:
        cutters.append(tube("%s_bore" % name, Vector(at) + d * (L - L * 0.45), L * 0.45 + 0.05, bore, direction=d, sides=10))
    cut(ob, cutters)
    ob["bore"] = list(Vector(at) + d * L)
    return ob


def magazine(name, at, size, rake_deg=8, curve_deg=0, plate=0.08, bevel=0.04):
    """Oversized magazine hanging from `at` (its top centre, on the receiver's underside). size = (width, depth, length);
    rake_deg tilts the bottom backwards; curve_deg > 0 kinks the lower half forward (a banana mag); a fatter floor
    plate (`plate` studs thick) finishes the bottom. One joined object."""
    w, dp, L = size
    top = Vector(at)
    up_len = L if curve_deg <= 0 else L * 0.55
    R1 = Matrix.Rotation(math.radians(-rake_deg), 4, "X")
    pieces = [block(name + "_u", (w, dp, up_len), top, rot_deg=(-rake_deg, 0, 0), bevel=bevel, anchor=(0, 0, 1))]
    bottom = top + (R1 @ Vector((0, 0, -up_len)))
    ang = -rake_deg
    if curve_deg > 0:
        ang = -rake_deg + curve_deg
        R2 = Matrix.Rotation(math.radians(ang), 4, "X")
        lo_len = L - up_len
        pieces.append(block(name + "_l", (w, dp, lo_len + 0.05), bottom + (R2 @ Vector((0, 0, 0.05))), rot_deg=(ang, 0, 0), bevel=bevel, anchor=(0, 0, 1)))
        bottom = bottom + (R2 @ Vector((0, 0, -lo_len)))
    if plate > 0:
        pieces.append(block(name + "_p", (w + 0.06, dp + 0.06, plate), bottom, rot_deg=(ang, 0, 0), bevel=0.02, anchor=(0, 0, 1)))
    ob = join(pieces, name)
    ob["bottom"] = list(bottom)
    return ob


def grip(name="Grip", at=(0, 0, 0), size=(0.44, 0.5, 0.95), rake_deg=16, finger=True, bevel=0.06):
    """Fat pistol grip hanging from `at` (its top centre), bottom swept back by rake_deg. finger=True adds two chunky
    finger ridges on the front face and a flared heel. Paint with paint_grip / kit.grip."""
    w, dp, L = size
    pieces = [block(name + "_b", (w, dp, L), at, rot_deg=(-rake_deg, 0, 0), bevel=bevel, anchor=(0, 0, 1))]
    R = Matrix.Rotation(math.radians(-rake_deg), 4, "X")
    if finger:
        for i, f in enumerate((0.3, 0.55)):
            c = Vector(at) + (R @ Vector((0, dp / 2, -L * f)))
            pieces.append(block("%s_f%d" % (name, i), (w * 0.9, 0.09, 0.11), c, rot_deg=(-rake_deg, 0, 0), bevel=0.02))
        heel = Vector(at) + (R @ Vector((0, 0, -L)))
        pieces.append(block(name + "_h", (w + 0.04, dp + 0.08, 0.1), heel, rot_deg=(-rake_deg, 0, 0), bevel=0.03, anchor=(0, 0, -1)))
    return join(pieces, name)


def stock(name, at, size, drop=0.0, bevel=0.06, pad=0.08):
    """Short stock going BACK (-Y) from `at` (the receiver's back-face centre). size = (width, length, height); drop
    lowers the rear end (a slanted stock); pad > 0 adds a fatter butt plate. One joined object."""
    w, L, h = size
    ob = block(name + "_s", (w, L, h), at, bevel=bevel, anchor=(0, 1, 0))
    if drop:
        for v in ob.data.vertices:
            if v.co.y < -L * 0.5:
                v.co.z -= drop
    pieces = [ob]
    if pad > 0:
        pieces.append(block(name + "_p", (w + 0.06, pad, h + 0.08), Vector(at) + Vector((0, -L, -drop)), bevel=0.03, anchor=(0, 1, 0)))
    return join(pieces, name)


def trigger_guard(name, at, radius=0.2, thick=0.05, segs=10, trigger=True):
    """Low-poly ring in the YZ plane (axis X) under the receiver at `at` (its centre), with a trigger nub inside."""
    pieces = [ring(name + "_r", radius, thick, at, axis="X", segs=segs, msegs=4)]
    if trigger:
        pieces.append(block(name + "_t", (0.08, 0.06, radius * 0.9), Vector(at) + Vector((0, 0, radius * 0.5)), rot_deg=(-12, 0, 0), bevel=0.01, anchor=(0, 0, 1)))
    return join(pieces, name)


def rail(name, at, length, width=0.22, height=0.08, teeth=5, anchor=(0, -1, -1)):
    """Top rail: a bar with `teeth` notches on top, from `at` (default anchor: back-bottom centre) forward along +Y."""
    pieces = [block(name + "_b", (width, length, height), at, bevel=0.01, anchor=anchor)]
    y0 = at[1] - (anchor[1] * length / 2) - length / 2
    z0 = at[2] - (anchor[2] * height / 2) + height / 2
    for i in range(teeth):
        y = y0 + length * (i + 0.5) / teeth
        pieces.append(block("%s_t%d" % (name, i), (width, length / teeth * 0.5, 0.04), (at[0], y, z0), bevel=0, anchor=(0, 0, -1)))
    return join(pieces, name)


def sight(name, at, kind="post", width=0.12, height=0.16, depth=0.12):
    """Iron sight on top of the receiver at `at` (its bottom centre): kind 'post' (a fat blade) or 'notch' (two ears)."""
    if kind == "notch":
        a = block(name + "_l", (width * 0.4, depth, height), (at[0] - width * 0.4, at[1], at[2]), bevel=0.01, anchor=(0, 0, -1))
        b = block(name + "_r", (width * 0.4, depth, height), (at[0] + width * 0.4, at[1], at[2]), bevel=0.01, anchor=(0, 0, -1))
        return join([a, b], name)
    return block(name, (width, depth, height), at, bevel=0.02, anchor=(0, 0, -1))


def vents(name, at, count, size, gap, axis="Y"):
    """A row of `count` thin plates (cooling fins / vent slats) of `size`, spaced `gap` apart along `axis` from `at`."""
    out = []
    for i in range(count):
        p = Vector(at)
        p["XYZ".index(axis)] += i * gap
        out.append(block("%s%d" % (name, i), size, p, bevel=0.01))
    return out


# ---------------------------------------------------------------- layered glow shapes: return (core, halo), unpainted
def glow_slot(name, size, at, rot_deg=(0, 0, 0), halo=1.7, halo_thin=0.5):
    """A light strip on a surface: a bright core box of `size` (make its thinnest axis point out of the surface) and a
    wider dimmer halo plate behind it (halo x the two long extents, halo_thin x the thin one, same centre so the core
    stands proud). Returns (core, halo): paint with kit.core(core), kit.halo(halo)."""
    thin = min(range(3), key=lambda i: size[i])
    hs = tuple(size[i] * (halo_thin if i == thin else halo) for i in range(3))
    core = block(name, size, at, rot_deg=rot_deg, bevel=0)
    hal = block(name + "H", hs, at, rot_deg=rot_deg, bevel=0)
    return core, hal


def glow_disc(name, radius, at, direction=(0, 1, 0), halo=1.7, thickness=0.05, sides=12):
    """A lit bore / lens / cap facing `direction` at `at`: a bright core disc plus a wider dimmer halo disc just
    behind it (the core hides its centre, so it reads as a ring of glow). Returns (core, halo)."""
    d = Vector(direction).normalized()
    core = disc(name, radius, Vector(at) + d * (thickness * 0.5), thickness, direction=d, sides=sides)
    hal = disc(name + "H", radius * halo, Vector(at) + d * (thickness * 0.2), thickness * 0.6, direction=d, sides=sides)
    return core, hal


def glow_ring(name, major, minor, at, axis="Y", halo=2.0, rot_deg=None):
    """A glowing hoop (a coil, a floating ring): a thin bright core torus plus a fatter dimmer halo torus around it."""
    core = ring(name, major, minor, at, axis=axis, rot_deg=rot_deg)
    hal = ring(name + "H", major, minor * halo, at, axis=axis, rot_deg=rot_deg)
    return core, hal


def glow_strip(name, centers, widths, thickness, up=(0, 0, 1), halo=1.8):
    """A glowing ribbon through `centers` (world points; a coil path, a channel, a curved edge): core ribbon of the
    given widths plus a wider, slightly thinner halo ribbon. Returns (core, halo)."""
    core = strip(name, centers, widths, thickness, up)
    hal = strip(name + "H", centers, [w * halo for w in widths], thickness * 0.7, up)
    return core, hal


def strip(name, centers, widths, thickness=0.06, up=(0, 0, 1)):
    """Flat faceted ribbon through `centers` (world), width per point, lying in the plane of the path and `up`,
    solidified to `thickness`. Straight or curved blades, channels, veins."""
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
        sb.apply_modifiers(ob)
    return _flat(ob)


# ---------------------------------------------------------------- melee helpers (u = +Y edge side, v = +Z along the blade)
def blade_outline(length, width, root=0.42, curve=0.25, belly=0.6, tip=0.3, clip=0.12, serrations=0, tooth=0.1,
                  serr_span=(0.25, 0.6), samples=6):
    """Outline (u, v) of a curved single-edged blade for plate_poly: v runs from 0 (root) to `length` (point), u sideways.
    The blade sweeps toward -u (the spine side) by curve * length at the point, so the +u cutting edge is convex.
    Width grows from `root` at the base to `width` at the `belly` fraction of the length, then the edge sweeps to an
    asymmetric clipped point: the spine drops away over the last `tip` fraction and the point sits `clip` inside the
    edge line. `serrations` outward teeth (`tooth` deep) on the spine between serr_span fractions of the length.
    Returns (outline, edge) where edge = the cutting-edge polyline [(u, v), ...] root -> point, for glow_edge."""
    def cen(v):
        f = v / length
        return -curve * length * f * f

    def wid(v):
        f = v / length
        if f <= belly:
            return root + (width - root) * math.sin(0.5 * math.pi * f / belly)
        return width
    edge = []
    n = samples
    for i in range(n + 1):
        v = length * (1 - tip) * i / n
        edge.append((cen(v) + wid(v) / 2, v))
    # point: the edge keeps sweeping to the point, which sits `clip` inside the edge line
    pu = cen(length) + wid(length * (1 - tip)) / 2 - clip
    edge.append((pu, length))
    spine = []
    for i in range(n + 1):
        v = length * (1 - tip) * i / n
        spine.append((cen(v) - wid(v) / 2, v))
    if serrations > 0:
        a, b = serr_span
        serr = []
        for k in range(serrations):
            v0 = length * (a + (b - a) * k / serrations)
            v1 = length * (a + (b - a) * (k + 1) / serrations)
            u0 = cen(v0) - wid(v0) / 2
            um = cen((v0 + v1) / 2) - wid((v0 + v1) / 2) / 2 - tooth
            u1 = cen(v1) - wid(v1) / 2
            serr += [(u0, v0), (um, (v0 + v1) / 2), (u1, v1)]
        spine = [p for p in spine if not (length * a <= p[1] <= length * b)]
        spine = sorted(spine + serr, key=lambda p: p[1])
    outline = edge + list(reversed(spine))
    return outline, edge


def offset_polyline(pts, inward, closed_strip=True):
    """Polygon of a strip that follows the polyline `pts` (u, v), `inward` wide toward -u (perpendicular to each segment).
    For glow_edge; also good for a rim along any fin outline."""
    n = len(pts)
    off = []
    for i, (u, v) in enumerate(pts):
        u0, v0 = pts[max(i - 1, 0)]
        u1, v1 = pts[min(i + 1, n - 1)]
        tu, tv = u1 - u0, v1 - v0
        L = math.hypot(tu, tv) or 1.0
        nu, nv = -tv / L, tu / L      # left normal of the tangent (points to -u for a +v-running edge)
        off.append((u + nu * inward, v + nv * inward))
    return list(pts) + list(reversed(off))


def glow_edge(name, edge, at, thickness, u_dir=(0, 1, 0), v_dir=(0, 0, 1), core_w=0.06, halo_w=0.16, proud=0.03):
    """Glow that follows a blade's cutting edge: a thin bright core strip along `edge` (from blade_outline) and a wider
    dimmer halo strip inside it, both a little thicker than the blade (`thickness` + proud) so they show on both faces.
    Returns (core, halo)."""
    core = plate_poly(name, offset_polyline(edge, core_w), thickness + proud * 2, at, u_dir, v_dir)
    hal = plate_poly(name + "H", offset_polyline(edge, halo_w), thickness + proud, at, u_dir, v_dir)
    return core, hal


def guard(name, at, width, depth=0.3, height=0.2, flare=0.12, bevel=0.04):
    """Crossguard as wide as the blade, centred at `at` (the blade root): a bar along Y (`width` long, `depth` along X)
    whose two ends turn up by `flare` (wedge tips). One joined object."""
    pieces = [block(name + "_b", (depth, width, height), at, bevel=bevel)]
    if flare > 0:
        for i, s in enumerate((-1, 1)):
            # a stub at each end, rotated so it points outward and up (flare = its length)
            tipb = block("%s_t%d" % (name, i), (depth * 0.85, flare + height * 0.3, height * 0.85),
                         (at[0], at[1] + s * (width / 2 - height * 0.3), at[2]), rot_deg=(s * 38, 0, 0), bevel=bevel * 0.7, anchor=(0, -s, 0))
            pieces.append(tipb)
    return join(pieces, name)


def handle(name, at, length, radius=0.15, sides=8, wraps=2, wrap_r=0.025, direction=(0, 0, -1)):
    """Faceted handle / haft starting at `at` and running `length` along `direction` (default: down from the origin),
    with `wraps` raised bands. Returns (handle, [bands]) so the bands can take the panel colour."""
    d = Vector(direction).normalized()
    h = tube(name, at, length, radius, direction=d, sides=sides)
    bands = []
    for i in range(wraps):
        p = Vector(at) + d * (length * (i + 1) / (wraps + 1))
        bands.append(tube("%s_w%d" % (name, i), p, 0.1, radius + wrap_r, direction=d, sides=sides, anchor=0))
    return h, bands


def pommel(name, at, radius=0.18, height=0.16, direction=(0, 0, -1), sides=6):
    """Hex-nut pommel / butt cap at the end of a handle (its top face centre at `at`, extending along `direction`)."""
    return tube(name, at, height, radius, direction=direction, sides=sides)


# ---------------------------------------------------------------- orbs: ONE bold shape each, unpainted
def orb_ball(name, center, radius, subdiv=2):
    """A faceted ball (subdiv 2 = 80 tris). Paint the core with kit.core; for a halo add orb_ball(..., radius * 1.35)
    painted with kit.halo(alpha=0.5)."""
    return ball(name, radius, center, subdiv=subdiv)


def orb_ring(name, center, major, minor, tilt_deg=(30, 0, 0), segs=12, msegs=5):
    """A single ring around a ball (tilted by tilt_deg) - 'a ball with a ring' is one bold silhouette."""
    return ring(name, major, minor, center, rot_deg=tilt_deg, segs=segs, msegs=msegs)


def orb_star(name, center, radius, points=5, inner=0.45, thickness=0.14, normal=(0, 1, 0), spin_deg=0):
    """A flat star plate (points spikes, inner = inner radius fraction) facing `normal`, centred at `center`."""
    pts = []
    for i in range(points * 2):
        a = math.radians(spin_deg) + math.pi * i / points
        r = radius if i % 2 == 0 else radius * inner
        pts.append((math.cos(a) * r, math.sin(a) * r))
    n = Vector(normal).normalized()
    u = Vector((0, 0, 1)).cross(n)
    if u.length < 1e-3:
        u = Vector((1, 0, 0))
    u.normalize()
    v = n.cross(u).normalized()
    return plate_poly(name, pts, thickness, center, u, v)


def orb_blade(name, center, length, width, thickness=0.12, curve=0.35, normal=(0, 0, 1), spin_deg=0):
    """One curved blade (a scimitar plate from blade_outline) lying flat in the plane facing `normal`, its root at
    `center`, spun by spin_deg about the normal. For spinning-blade orbs: one bold shape, no sub-parts."""
    outline, _ = blade_outline(length, width, root=width * 0.6, curve=curve, tip=0.3, clip=width * 0.2)
    n = Vector(normal).normalized()
    u = Vector((0, 1, 0)) if abs(n.z) > 0.9 else Vector((0, 0, 1)).cross(n).normalized()
    v = n.cross(u).normalized()
    R = Matrix.Rotation(math.radians(spin_deg), 3, n)
    return plate_poly(name, outline, thickness, center, R @ u, R @ v)


# ---------------------------------------------------------------- checks, build loop
def finish(parts, budget=1500):
    """Flat-shade every part, decimate a Body over `budget` tris (with a WARNING), check the names. Returns parts."""
    for name, ob in list(parts.items()):
        if ob is None:
            del parts[name]
            continue
        ob.name = name
        sb2.shade_flat(ob)
    total = sum(sb.tri_count(o) for o in parts.values())
    if total > budget:
        print("WARNING: %d tris > budget %d; faceting Body down" % (total, budget))
        body = parts.get("Body")
        if body is not None:
            sb2.facet(body, max(200, budget - (total - sb.tri_count(body))))
    if "Body" not in parts:
        print("WARNING: no Body part")
    if len(parts) > 10:
        print("WARNING: %d parts (keep it under 10)" % len(parts))
    for name in parts:
        if "Glow" in name and not name.endswith("_Glow"):
            print("WARNING: glow part %s must end in _Glow" % name)
    return parts


def load(name):
    """Each weapon lives in weapon_<Name>.py with build() -> {part: object} and VIEW = (angle_deg, elev_deg)."""
    return importlib.import_module("weapon_" + name)


def build_all(names=None, render=True, ao=True):
    """Build, AO-bake, export (assets/models/weapons/<Name>.fbx/.glb + manifest) and render (assets/renders/weapons/<Name>.png)."""
    here = os.path.dirname(os.path.abspath(__file__))
    names = names or [n for n in WEAPONS if os.path.exists(os.path.join(here, "weapon_%s.py" % n))]
    for name in names:
        mod = load(name)
        sb.reset()
        parts = mod.build()
        objs = [o for o in parts.values() if o is not None]
        if ao:
            sb2.bake_ao(objs, strength=0.6, distance=0.7, samples=12)
        entry = sb.export_model("weapons/%s" % name, objs, {"display": NAMES[name], "rarity": RARITY[name], "kind": KIND[name],
                                                             "recipe": "v2", "forward": "+Y (Blender)"})
        big = [(o.name, sb.tri_count(o)) for o in objs if sb.tri_count(o) > 1500]
        print("built", name, "parts=%d tris=%d size=%s" % (len(objs), entry["tris"], entry["size_studs"]),
              ("WARNING big parts: %s" % big) if big else "")
        sys.stdout.flush()
        if render:
            a, e = getattr(mod, "VIEW", DEFAULT_VIEW)
            out = sb2.render_model2(name, objs, "weapons/%s.png" % name, angle_deg=a, elev_deg=e, floor=False, pad=RENDER_PAD)
            print("rendered", out)
            sys.stdout.flush()


if __name__ == "__main__":
    build_all(sys.argv[1:] or None, render=os.environ.get("SB_NO_RENDER") != "1", ao=os.environ.get("SB_NO_AO") != "1")
