"""Swarm Break model library, pass 2: the techniques that make a model read like a real stylized game asset.

What changed from sb.py (which stays for primitives, export and the manifest):
- FACETED low-poly: bodies are remeshed and decimated to a triangle budget and shaded flat, so they read as
  sculpted chunks instead of balloons (facet()).
- MERGED forms: parts that belong together are voxel-remeshed into one shell (merge()); armour is cut from the
  body surface itself so it hugs the curve (cap_from()).
- SEGMENTED limbs with real joints (seg_limb()), not skin-modifier hoses.
- PAINT BY RULES: one vertex-color material per object, colors decided per face by rules (dark base, light from
  above, belly, stripes, bands, spots, height gradients) and multiplied by baked ambient occlusion (paint_rules(),
  bake_ao()). Roblox imports the vertex colors, so the shading survives in game with no textures.
- ATTACK POSES for renders (pose()), applied after export so the rig stays neutral.
- A render setup that looks like a store thumbnail: dark gradient world, warm key + cool rim, glossy floor,
  bloom on glow parts, AgX (render_model2(), render_scene()).
- Kitbash import of CC0 GLB/GLTF packs with their palette texture baked to vertex colors (import_kit()).

Usage:
    import sb, sb2
    sb.reset()
    ...build parts...
    sb.export_model("enemies/Walker", parts.values())
    sb2.pose(parts, {...}); sb2.render_model2("Walker", parts.values(), "renders/enemies/Walker.png")
"""
import bpy
import bmesh
import math
import os
from mathutils import Vector, Matrix, noise

import sb
from sb import PAL, rgb, _link, _active

# ---------------------------------------------------------------- vertex-color material
_vmats = {}


def vmat(roughness=0.6, metallic=0.0, emission=0.0, alpha=1.0, name=None):
    """Material whose base color (and emission color) comes from the 'Color' vertex attribute."""
    key = (roughness, metallic, emission, alpha)
    if key in _vmats:
        try:
            if _vmats[key].name in bpy.data.materials:
                return _vmats[key]
        except ReferenceError:
            pass  # a previous sb.reset() removed it
    m = bpy.data.materials.new(name or "V_%d" % len(_vmats))
    m.use_nodes = True
    nt = m.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    attr = nt.nodes.new("ShaderNodeVertexColor")
    attr.layer_name = "Color"
    nt.links.new(attr.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    if emission > 0:
        nt.links.new(attr.outputs["Color"], bsdf.inputs["Emission Color"])
        bsdf.inputs["Emission Strength"].default_value = emission
    if alpha < 1.0:
        bsdf.inputs["Alpha"].default_value = alpha
        try:
            m.surface_render_method = "BLENDED"
        except Exception:
            pass
    _vmats[key] = m
    return m


def _color_attr(me):
    attr = me.color_attributes.get("Color")
    if attr is None:
        attr = me.color_attributes.new(name="Color", type="BYTE_COLOR", domain="CORNER")
    me.color_attributes.active_color = attr
    try:
        me.color_attributes.render_color_index = me.color_attributes.find("Color")
    except Exception:
        pass
    return attr


def use_vcol(ob, roughness=0.6, metallic=0.0, emission=0.0, alpha=1.0):
    ob.data.materials.clear()
    ob.data.materials.append(vmat(roughness, metallic, emission, alpha))
    if alpha < 1.0:
        ob["alpha"] = alpha
    if emission > 0 and not ob.name.endswith("_Glow"):
        ob.name = ob.name + "_Glow"
    return ob


# ---------------------------------------------------------------- color helpers
def mix(a, b, t):
    t = max(0.0, min(1.0, t))
    return tuple(a[i] * (1 - t) + b[i] * t for i in range(3)) + (1.0,)


def darken(c, k):
    return (c[0] * k, c[1] * k, c[2] * k, 1.0)


def lighten(c, k):
    return mix(c, (1, 1, 1, 1), k)


def smoothstep(e0, e1, x):
    t = max(0.0, min(1.0, (x - e0) / max(e1 - e0, 1e-6)))
    return t * t * (3 - 2 * t)


# ---------------------------------------------------------------- paint by rules
# A rule is a callable (p, n, t) -> (color, weight). p = world position, n = world face normal,
# t = dict with 'z' (0..1 height within the object), 'y', 'x' (0..1 along the axes).
def top_light(color, power=1.0, amount=1.0):
    """Light falling from above: faces that point up take `color` (the shell tone)."""
    return lambda p, n, t: (color, amount * max(0.0, n.z) ** power)


def belly(color, amount=1.0, power=1.0):
    """Faces that point down take `color` (a soft underside tone)."""
    return lambda p, n, t: (color, amount * max(0.0, -n.z) ** power)


def facing(direction, color, amount=1.0, power=2.0):
    d = Vector(direction).normalized()
    return lambda p, n, t: (color, amount * max(0.0, n.dot(d)) ** power)


def height(bottom, top, curve=1.0):
    """Gradient by height within the object (t['z'] 0 at the lowest vertex, 1 at the top)."""
    return lambda p, n, t: (mix(bottom, top, t["z"] ** curve), 1.0)


def band(axis, center, width, color, soft=0.3, amount=1.0):
    """A band of `color` around `center` on a world axis (0=x,1=y,2=z); width is the half width."""
    def r(p, n, t):
        d = abs(p[axis] - center)
        return color, amount * (1.0 - smoothstep(width * (1 - soft), width, d))
    return r


def stripes(axis, period, duty, color, phase=0.0, amount=1.0):
    def r(p, n, t):
        f = ((p[axis] - phase) / period) % 1.0
        return color, amount * (1.0 if f < duty else 0.0)
    return r


def spots(scale, threshold, color, seed=0.0, amount=1.0):
    def r(p, n, t):
        v = noise.noise(p * scale + Vector((seed, seed * 2, seed * 3)))
        return color, amount * (1.0 if v > threshold else 0.0)
    return r


def region(mask, color, amount=1.0):
    """mask(p, n) -> 0..1"""
    return lambda p, n, t: (color, amount * mask(p, n))


def near(point, radius, color, soft=0.4, amount=1.0):
    c = Vector(point)
    return lambda p, n, t: (color, amount * (1.0 - smoothstep(radius * (1 - soft), radius, (p - c).length)))


def paint_rules(ob, base, rules=(), per_face=True, roughness=0.6, metallic=0.0, emission=0.0, alpha=1.0):
    """Give the object a vertex-color material and paint every face corner from the rules, in order."""
    me = ob.data
    attr = _color_attr(me)
    mw = ob.matrix_world
    nm = mw.to_3x3().inverted().transposed()
    xs = [(mw @ v.co) for v in me.vertices]
    lo = Vector((min(v.x for v in xs), min(v.y for v in xs), min(v.z for v in xs)))
    hi = Vector((max(v.x for v in xs), max(v.y for v in xs), max(v.z for v in xs)))
    span = Vector((max(hi.x - lo.x, 1e-6), max(hi.y - lo.y, 1e-6), max(hi.z - lo.z, 1e-6)))
    for poly in me.polygons:
        n = (nm @ poly.normal).normalized()
        pc = mw @ poly.center
        for li in poly.loop_indices:
            p = pc if per_face else xs[me.loops[li].vertex_index]
            t = {"x": (p.x - lo.x) / span.x, "y": (p.y - lo.y) / span.y, "z": (p.z - lo.z) / span.z}
            c = tuple(base[:3]) + (1.0,)
            for rule in rules:
                col, w = rule(p, n, t)
                if w > 0:
                    c = mix(c, col, w)
            attr.data[li].color_srgb = c
    use_vcol(ob, roughness, metallic, emission, alpha)
    return ob


def flat_color(ob, color, roughness=0.6, metallic=0.0, emission=0.0, alpha=1.0):
    """One color through the vertex-color material (so AO can still be multiplied in)."""
    return paint_rules(ob, color, (), True, roughness, metallic, emission, alpha)


def bake_ao(objs, strength=0.65, distance=1.2, samples=16, floor_z=None):
    """Bake ambient occlusion (Cycles, all scene objects occlude) into each object's 'Color' attribute.
    strength 0..1 = how dark the crevices get. Call after painting and before export."""
    objs = [o for o in objs if o is not None and o.type == "MESH"]
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = samples
    if scene.world is None:
        scene.world = bpy.data.worlds.new("W")
    try:
        scene.world.light_settings.distance = distance
    except Exception:
        pass
    scene.render.bake.target = "VERTEX_COLORS"
    scene.render.bake.use_selected_to_active = False
    scene.render.bake.use_clear = True
    plane = None
    if floor_z is not None:
        bpy.ops.mesh.primitive_plane_add(size=200, location=(0, 0, floor_z))
        plane = bpy.context.active_object
        plane.name = "_aofloor"
    for ob in objs:
        me = ob.data
        if not me.polygons:
            continue
        colors = me.color_attributes.get("Color")
        if colors is None:
            flat_color(ob, (0.5, 0.5, 0.5, 1))
            colors = me.color_attributes.get("Color")
        ao = me.color_attributes.get("AO") or me.color_attributes.new(name="AO", type="BYTE_COLOR", domain="CORNER")
        me.color_attributes.active_color = ao
        if not me.materials:
            me.materials.append(vmat())
        _active(ob)
        try:
            bpy.ops.object.bake(type="AO")
        except Exception as e:
            print("AO bake failed on", ob.name, e)
            me.color_attributes.remove(ao)
            me.color_attributes.active_color = colors
            continue
        colors = me.color_attributes.get("Color")
        ao = me.color_attributes.get("AO")
        for i in range(len(colors.data)):
            a = ao.data[i].color[0]
            k = 1.0 - strength * (1.0 - a)
            c = colors.data[i].color_srgb
            colors.data[i].color_srgb = (c[0] * k, c[1] * k, c[2] * k, 1.0)
        me.color_attributes.remove(ao)
        me.color_attributes.active_color = me.color_attributes.get("Color")
    if plane is not None:
        bpy.data.objects.remove(plane, do_unlink=True)
    return objs


# ---------------------------------------------------------------- shaping
def shade_flat(ob):
    for p in ob.data.polygons:
        p.use_smooth = False
    return ob


def shade_smooth(ob):
    for p in ob.data.polygons:
        p.use_smooth = True
    return ob


def merge(objs, name, voxel=0.12, adaptivity=0.0, smooth_iters=0):
    """Join several meshes and voxel-remesh them into ONE watertight shell (overlaps fuse, no floating parts).
    voxel = detail size in studs (smaller = finer, more triangles). Follow with facet() to set the budget."""
    ob = sb.join(objs, name)
    m = ob.modifiers.new("Remesh", "REMESH")
    m.mode = "VOXEL"
    m.voxel_size = voxel
    m.adaptivity = adaptivity
    m.use_smooth_shade = False
    sb.apply_modifiers(ob)
    if smooth_iters > 0:
        s = ob.modifiers.new("Smooth", "SMOOTH")
        s.iterations = smooth_iters
        s.factor = 0.6
        sb.apply_modifiers(ob)
    return ob


def facet(ob, tris=900, planar_deg=0.0, flat=True):
    """Decimate to about `tris` triangles (collapse), optionally planar-dissolve first, then shade flat."""
    if planar_deg > 0:
        d = ob.modifiers.new("Planar", "DECIMATE")
        d.decimate_type = "DISSOLVE"
        d.angle_limit = math.radians(planar_deg)
        d.use_dissolve_boundaries = False
        sb.apply_modifiers(ob)
    cur = sb.tri_count(ob)
    if cur > tris > 0:
        d = ob.modifiers.new("Dec", "DECIMATE")
        d.decimate_type = "COLLAPSE"
        d.ratio = tris / float(cur)
        d.use_collapse_triangulate = True
        sb.apply_modifiers(ob)
    if flat:
        shade_flat(ob)
    return ob


def smooth_verts(ob, iterations=2, factor=0.5):
    s = ob.modifiers.new("Smooth", "SMOOTH")
    s.iterations = iterations
    s.factor = factor
    sb.apply_modifiers(ob)
    return ob


def union(base, others, exact=True):
    """Boolean-union `others` into `base` (hard-surface merge); the others are deleted."""
    for o in others:
        if o is None:
            continue
        m = base.modifiers.new("Bool", "BOOLEAN")
        m.operation = "UNION"
        m.object = o
        m.solver = "EXACT" if exact else "FAST"
        sb.apply_modifiers(base)
        bpy.data.objects.remove(o, do_unlink=True)
    return base


def cap_from(body, keep, name, thickness=0.22, grow=0.02, bevel=0.03, flat=True, tris=260):
    """Armour cut from the body's own surface: keep(center, normal) -> bool selects faces, which are then
    pushed out and thickened so the plate follows the body curve exactly (pauldrons, crowns, plated backs)."""
    dg = bpy.context.evaluated_depsgraph_get()
    ev = body.evaluated_get(dg)
    me = bpy.data.meshes.new_from_object(ev)
    ob = bpy.data.objects.new(name, me)
    _link(ob)
    ob.matrix_world = body.matrix_world.copy()
    mw = ob.matrix_world
    nm = mw.to_3x3().inverted().transposed()
    bm = bmesh.new()
    bm.from_mesh(me)
    bm.faces.ensure_lookup_table()
    kill = [f for f in bm.faces if not keep(mw @ f.calc_center_median(), (nm @ f.normal).normalized())]
    bmesh.ops.delete(bm, geom=kill, context="FACES")
    bm.to_mesh(me)
    bm.free()
    if not me.polygons:
        bpy.data.objects.remove(ob, do_unlink=True)
        return None
    if grow:
        d = ob.modifiers.new("Grow", "DISPLACE")
        d.strength = grow
        d.mid_level = 0.0
        d.direction = "NORMAL"
    s = ob.modifiers.new("Solid", "SOLIDIFY")
    s.thickness = thickness
    s.offset = 1.0
    s.use_even_offset = True
    s.use_rim = True
    sb.apply_modifiers(ob)
    if bevel > 0:
        sb.add_bevel(ob, bevel, 1, 40)
        sb.apply_modifiers(ob)
    if tris:
        facet(ob, tris, flat=flat)
    elif flat:
        shade_flat(ob)
    return ob


def seg_limb(name, points, radii, location=(0, 0, 0), sides=7, joint=1.3, joint_subdiv=1, flat=True, fuse=0.0):
    """A limb from tapered segments with a low-poly ball at each inner joint. points are local to `location`.
    fuse > 0 voxel-remeshes the segments into one shell with that voxel size (then call facet())."""
    pts = [Vector(location) + Vector(p) for p in points]
    parts = []
    for i in range(len(pts) - 1):
        a, b = pts[i], pts[i + 1]
        d = b - a
        L = d.length
        if L < 1e-5:
            continue
        bpy.ops.mesh.primitive_cone_add(vertices=sides, radius1=radii[i], radius2=radii[i + 1], depth=L)
        seg = bpy.context.active_object
        seg.name = "%s_s%d" % (name, i)
        seg.rotation_euler = d.normalized().to_track_quat("Z", "Y").to_euler()
        seg.location = (a + b) / 2
        sb.apply_transforms(seg)
        parts.append(seg)
    for i in range(1, len(pts) - 1):
        r = radii[i] * joint
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=joint_subdiv, radius=r, location=pts[i])
        j = bpy.context.active_object
        j.name = "%s_j%d" % (name, i)
        parts.append(j)
    ob = sb.join(parts, name) if fuse <= 0 else merge(parts, name, voxel=fuse)
    if flat:
        shade_flat(ob)
    ob["tip"] = list(pts[-1])
    ob["root"] = list(pts[0])
    ob["joints"] = [list(p) for p in pts]
    return ob


def lowpoly_sphere(name, radius, location=(0, 0, 0), scale=(1, 1, 1), subdiv=2, flat=True):
    ob = sb.sphere(name, radius, location, scale, subdiv=subdiv, smooth=not flat)
    sb.apply_transforms(ob)
    return ob


def wedge(name, size, location=(0, 0, 0), rotation=(0, 0, 0), taper=0.5, flat=True):
    """A box that narrows toward +Y (jaws, snouts, blade tips): taper = width at the front / width at the back."""
    ob = sb.box(name, size, location, rotation)
    me = ob.data
    for v in me.vertices:
        if v.co.y > 0:
            v.co.x *= taper
            v.co.z *= (taper + 1) / 2
    if flat:
        shade_flat(ob)
    return ob


def horn(name, base, direction, length, radius, sides=5, curve=0.0, flat=True):
    """A faceted horn / claw / spike, optionally curved (curve = sideways bend 0..1) via 3 stacked cones."""
    d = Vector(direction).normalized()
    if curve <= 0:
        ob = sb.cone_dir(name, base, d, length, radius, verts=sides, smooth=not flat)
        return ob
    up = Vector((0, 0, 1)) if abs(d.z) < 0.9 else Vector((0, 1, 0))
    side = d.cross(up).normalized()
    bend = up * curve
    pts = [Vector(base), Vector(base) + d * (length * 0.45), Vector(base) + (d + bend * 0.6).normalized() * (length * 0.8),
           Vector(base) + (d + bend * 1.2).normalized() * length]
    rads = [radius, radius * 0.7, radius * 0.4, 0.03]
    ob = seg_limb(name, [p - Vector(base) for p in pts], rads, location=base, sides=sides, joint=1.0, flat=flat)
    return ob


def eye(name, center, direction, radius, iris_color, white=(0.93, 0.93, 0.9, 1), pupil=True, glow=2.0):
    """A big readable eye: white ball, glowing iris disc facing `direction`, dark pupil. Returns [parts]."""
    d = Vector(direction).normalized()
    ball = lowpoly_sphere(name + "_White", radius, center, subdiv=2, flat=True)
    flat_color(ball, white, roughness=0.25)
    iris = sb.cylinder(name + "_Glow", radius * 0.62, radius * 0.25, Vector(center) + d * (radius * 0.85), verts=12, smooth=False)
    iris.rotation_euler = d.to_track_quat("Z", "Y").to_euler()
    sb.apply_transforms(iris)
    flat_color(iris, iris_color, emission=glow)
    out = [ball, iris]
    if pupil:
        pu = sb.cylinder(name + "_Pupil", radius * 0.28, radius * 0.12, Vector(center) + d * (radius * 1.02), verts=10, smooth=False)
        pu.rotation_euler = d.to_track_quat("Z", "Y").to_euler()
        sb.apply_transforms(pu)
        flat_color(pu, (0.02, 0.02, 0.03, 1), roughness=0.2)
        out.append(pu)
    return out


# ---------------------------------------------------------------- posing (renders only; export first)
def pose(parts, moves):
    """moves: {part_name: (pivot_xyz, (rx, ry, rz) degrees)}. Rotates the part's mesh about the pivot (world)."""
    for name, (pivot, rot) in moves.items():
        ob = parts.get(name) if isinstance(parts, dict) else None
        if ob is None:
            continue
        piv = Vector(pivot)
        R = (Matrix.Rotation(math.radians(rot[0]), 4, "X") @ Matrix.Rotation(math.radians(rot[1]), 4, "Y")
             @ Matrix.Rotation(math.radians(rot[2]), 4, "Z"))
        ob.matrix_world = Matrix.Translation(piv) @ R @ Matrix.Translation(-piv) @ ob.matrix_world
    return parts


def place_copy(objs, location=(0, 0, 0), rotation_deg=0.0, scale=1.0, suffix="_c"):
    """Instance a built model elsewhere in the scene (linked mesh data) for scene renders."""
    out = []
    R = Matrix.Rotation(math.radians(rotation_deg), 4, "Z")
    for o in objs:
        if o is None:
            continue
        c = bpy.data.objects.new(o.name + suffix, o.data)
        _link(c)
        c.matrix_world = Matrix.Translation(Vector(location)) @ R @ Matrix.Scale(scale, 4) @ o.matrix_world
        out.append(c)
    return out


# ---------------------------------------------------------------- kitbash import (CC0 packs)
def _sample_image(img, cache):
    import numpy as np
    if img.name not in cache:
        w, h = img.size
        px = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)
        cache[img.name] = (w, h, px)
    return cache[img.name]


def texture_to_vcol(ob, cache=None):
    """Bake the material's image texture (palette atlas) into the 'Color' vertex attribute by UV sampling.
    Objects without a texture take their material base color."""
    cache = cache if cache is not None else {}
    me = ob.data
    attr = _color_attr(me)
    uv = me.uv_layers.active
    slot_img = {}
    slot_col = {}
    for i, slot in enumerate(ob.material_slots):
        m = slot.material
        img, col = None, (0.6, 0.6, 0.6, 1)
        if m and m.use_nodes:
            for n in m.node_tree.nodes:
                if n.type == "TEX_IMAGE" and n.image and img is None:
                    img = n.image
                if n.type == "BSDF_PRINCIPLED":
                    c = n.inputs["Base Color"].default_value
                    col = (c[0], c[1], c[2], 1)
        slot_img[i] = img
        slot_col[i] = col
    for poly in me.polygons:
        img = slot_img.get(poly.material_index)
        for li in poly.loop_indices:
            if img is not None and uv is not None:
                w, h, px = _sample_image(img, cache)
                u, v = uv.data[li].uv
                x = int((u % 1.0) * w) % w
                y = int((v % 1.0) * h) % h
                c = px[y, x]
                attr.data[li].color = (float(c[0]), float(c[1]), float(c[2]), 1.0)   # image pixels are linear
            else:
                attr.data[li].color_srgb = slot_col.get(poly.material_index, (0.6, 0.6, 0.6, 1))
    me.color_attributes.active_color = attr
    return ob


def import_kit(path, name=None, scale=1.0, to_vcol=True, join_all=True, flat=True):
    """Import a GLB/GLTF/FBX asset, scale it to studs, bake its palette texture to vertex colors, join to one object."""
    before = set(bpy.context.scene.objects)
    if path.lower().endswith((".glb", ".gltf")):
        bpy.ops.import_scene.gltf(filepath=path)
    else:
        bpy.ops.import_scene.fbx(filepath=path)
    new = [o for o in bpy.context.scene.objects if o not in before]
    meshes = [o for o in new if o.type == "MESH"]
    for o in meshes:
        o.parent = None
    for o in new:
        if o.type != "MESH":
            bpy.data.objects.remove(o, do_unlink=True)
    cache = {}
    for o in meshes:
        if scale != 1.0:
            o.matrix_world = Matrix.Scale(scale, 4) @ o.matrix_world
        sb.apply_transforms(o, location=False, rotation=True, scale=True)
        if to_vcol:
            texture_to_vcol(o, cache)
            use_vcol(o, roughness=0.6)
        if flat:
            shade_flat(o)
    if join_all and len(meshes) > 1:
        ob = sb.join(meshes, name or os.path.splitext(os.path.basename(path))[0])
        return ob
    if meshes:
        meshes[0].name = name or os.path.splitext(os.path.basename(path))[0]
        return meshes[0]
    return None


# ---------------------------------------------------------------- rendering
def _world_gradient(scene, bottom=(0.012, 0.010, 0.02), top=(0.05, 0.045, 0.09), strength=0.6):
    w = bpy.data.worlds.new("W2")
    w.use_nodes = True
    nt = w.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    out = nt.nodes.new("ShaderNodeOutputWorld")
    bg = nt.nodes.new("ShaderNodeBackground")
    bg.inputs["Strength"].default_value = strength
    tc = nt.nodes.new("ShaderNodeTexCoord")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].position = 0.0
    ramp.color_ramp.elements[0].color = tuple(bottom) + (1,)
    ramp.color_ramp.elements[1].position = 1.0
    ramp.color_ramp.elements[1].color = tuple(top) + (1,)
    nt.links.new(tc.outputs["Window"], sep.inputs["Vector"])
    nt.links.new(sep.outputs["Y"], ramp.inputs["Fac"])
    nt.links.new(ramp.outputs["Color"], bg.inputs["Color"])
    nt.links.new(bg.outputs["Background"], out.inputs["Surface"])
    scene.world = w
    return w


def _bloom(scene, threshold=1.0, size=7, strength=0.35):
    """Glare (bloom) in the compositor; tolerant of the 4.x and 5.x APIs."""
    try:
        nt = None
        if hasattr(scene, "compositing_node_group"):
            nt = bpy.data.node_groups.new("Comp", "CompositorNodeTree")
            scene.compositing_node_group = nt
        else:
            scene.use_nodes = True
            nt = scene.node_tree
            for n in list(nt.nodes):
                nt.nodes.remove(n)
        rl = nt.nodes.new("CompositorNodeRLayers")
        glare = nt.nodes.new("CompositorNodeGlare")
        try:
            comp = nt.nodes.new("CompositorNodeComposite")
        except Exception:
            # Blender 5: the compositing node group ends in a Group Output with an Image socket
            nt.interface.new_socket("Image", in_out="OUTPUT", socket_type="NodeSocketColor")
            comp = nt.nodes.new("NodeGroupOutput")
        for attr, val in (("glare_type", "BLOOM"), ("quality", "MEDIUM")):
            try:
                setattr(glare, attr, val)
            except Exception:
                pass
        for key, val in (("Threshold", threshold), ("Size", size), ("Strength", strength), ("Mix", 0.0)):
            try:
                glare.inputs[key].default_value = val
            except Exception:
                try:
                    setattr(glare, key.lower(), val)
                except Exception:
                    pass
        nt.links.new(rl.outputs["Image"], glare.inputs["Image"])
        nt.links.new(glare.outputs["Image"], comp.inputs["Image"])
        return True
    except Exception as e:
        print("bloom setup failed:", e)
        return False


def _light(name, kind, location, energy, color, size, target):
    ld = bpy.data.lights.new(name, kind)
    ld.energy = energy
    ld.color = color
    if kind == "AREA":
        ld.size = size
    elif kind == "SPOT":
        ld.spot_size = math.radians(70)
        ld.shadow_soft_size = size
    ob = bpy.data.objects.new(name, ld)
    _link(ob)
    ob.location = location
    sb._look_at(ob, Vector(target))
    return ob


def setup_look(scene, samples=64, res=768, bloom=True, contrast="AgX - Medium High Contrast"):
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = samples
    scene.cycles.use_denoising = True
    scene.render.resolution_x = res
    scene.render.resolution_y = res
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = False
    scene.render.image_settings.file_format = "PNG"
    try:
        scene.view_settings.view_transform = "AgX"
    except Exception:
        scene.view_settings.view_transform = "Filmic"
    for look in (contrast, contrast.replace("AgX - ", ""), "None"):
        try:
            scene.view_settings.look = look
            break
        except Exception:
            continue
    scene.view_settings.exposure = 0.15
    _world_gradient(scene)
    if bloom:
        _bloom(scene)
    return scene


def _camera(scene, location, target, lens=45):
    cam_data = bpy.data.cameras.new("Cam")
    cam_data.lens = lens
    cam = bpy.data.objects.new("Cam", cam_data)
    _link(cam)
    cam.location = location
    sb._look_at(cam, Vector(target))
    scene.camera = cam
    return cam


def _floor(center, lo_z, size, color=(0.03, 0.03, 0.045, 1), roughness=0.28):
    bpy.ops.mesh.primitive_plane_add(size=size)
    fl = bpy.context.active_object
    fl.name = "Floor"
    fl.location = (center.x, center.y, lo_z - 0.005)
    sb.paint(fl, color, roughness=roughness)
    return fl


def render_model2(title, objs, rel_out, angle_deg=32, elev_deg=14, pad=1.12, samples=64, res=768, floor=True, lens=45,
                  key=(1.0, 0.93, 0.85), rim=(0.55, 0.75, 1.0), rim_energy=1.0, fill_energy=1.0, key_energy=1.0):
    """Store-thumbnail style still: dark gradient world, warm key, cool rim from behind, glossy floor, bloom."""
    objs = [o for o in objs if o is not None]
    scene = bpy.context.scene
    setup_look(scene, samples, res)
    lo, hi = sb.bounds(objs)
    center = (lo + hi) / 2
    size = max((hi - lo).x, (hi - lo).y, (hi - lo).z)
    dist = size * pad * 2.0
    a = math.radians(angle_deg)
    e = math.radians(elev_deg)
    cam_pos = center + Vector((math.sin(a) * math.cos(e), math.cos(a) * math.cos(e), math.sin(e))) * dist
    _camera(scene, cam_pos, center, lens)
    extras = []
    s2 = size * size / 4
    extras.append(_light("Key", "AREA", center + Vector((size * 1.6, size * 1.3, size * 1.8)), 420 * s2 * key_energy, key, size * 1.0, center))
    extras.append(_light("Fill", "AREA", center + Vector((-size * 2.2, size * 1.2, size * 0.5)), 90 * s2 * fill_energy, (0.6, 0.7, 1.0), size * 2.5, center))
    extras.append(_light("Rim", "AREA", center + Vector((-size * 0.6, -size * 2.2, size * 1.5)), 900 * s2 * rim_energy, rim, size * 0.7, center))
    extras.append(_light("Rim2", "AREA", center + Vector((size * 1.4, -size * 1.8, size * 0.9)), 500 * s2 * rim_energy, (1.0, 0.6, 0.85), size * 0.6, center))
    if floor:
        extras.append(_floor(center, lo.z, size * 14))
    out = os.path.join(sb.ASSETS, "renders", rel_out)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    scene.render.filepath = out
    bpy.ops.render.render(write_still=True)
    for o in extras:
        bpy.data.objects.remove(o, do_unlink=True)
    if scene.camera:
        bpy.data.objects.remove(scene.camera, do_unlink=True)
    return out


def render_scene(rel_out, cam_from, cam_at, lens=35, samples=64, res=(1280, 720), floor_z=None, floor_size=200,
                 sun=True, fog=False):
    """A gameplay-style shot of whatever is in the scene (arena kit + enemies + a weapon)."""
    scene = bpy.context.scene
    setup_look(scene, samples, res[0])
    scene.render.resolution_x, scene.render.resolution_y = res
    _camera(scene, cam_from, cam_at, lens)
    extras = []
    c = Vector(cam_at)
    if sun:
        sd = bpy.data.lights.new("Sun", "SUN")
        sd.energy = 2.5
        sd.color = (1.0, 0.92, 0.82)
        sd.angle = math.radians(8)
        so = bpy.data.objects.new("Sun", sd)
        _link(so)
        so.location = c + Vector((30, 20, 60))
        sb._look_at(so, c)
        extras.append(so)
    extras.append(_light("RimS", "AREA", c + Vector((-25, -40, 30)), 60000, (0.5, 0.7, 1.0), 12, c))
    if floor_z is not None:
        extras.append(_floor(c, floor_z, floor_size))
    if fog:
        try:
            w = scene.world
            nt = w.node_tree
            vol = nt.nodes.new("ShaderNodeVolumePrincipled")
            vol.inputs["Density"].default_value = 0.012
            vol.inputs["Color"].default_value = (0.4, 0.35, 0.6, 1)
            out = [n for n in nt.nodes if n.type == "OUTPUT_WORLD"][0]
            nt.links.new(vol.outputs["Volume"], out.inputs["Volume"])
        except Exception as e:
            print("fog failed", e)
    out = os.path.join(sb.ASSETS, "renders", rel_out)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    scene.render.filepath = out
    bpy.ops.render.render(write_still=True)
    for o in extras:
        bpy.data.objects.remove(o, do_unlink=True)
    if scene.camera:
        bpy.data.objects.remove(scene.camera, do_unlink=True)
    return out
