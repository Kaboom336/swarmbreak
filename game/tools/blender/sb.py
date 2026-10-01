"""Swarm Break model library for Blender (bpy 4.x/5.x, headless).

Every model is built from code so it lives in files and can be rebuilt any time.
Style: stylized low-poly. Chunky silhouettes, smooth organic shells, hard beveled
plates, vertex colors (no textures), glowing accent meshes exported as *_Glow so
Studio can give them the Neon material.

Units: 1 Blender unit = 1 stud. Y is up in Roblox, Blender is Z up; exporters convert.

Usage from a build script:
    import sb
    sb.reset()
    parts = {...}                    # name -> bpy object
    sb.export_model("enemies/Walker", parts.values())
    sb.render_model("Walker", parts.values(), "renders/enemies/Walker.png")
"""
import bpy
import bmesh
import math
import os
import json
from mathutils import Vector, Matrix

ASSETS = os.environ.get("SB_ASSETS", os.path.join(os.path.dirname(__file__), "..", "..", "..", "assets"))
ASSETS = os.path.abspath(ASSETS)

# ---------------------------------------------------------------- palette (0..1)
def rgb(r, g, b):
    return (r / 255.0, g / 255.0, b / 255.0, 1.0)

PAL = {
    "chitin": rgb(16, 11, 26),      # dark purple-black shell
    "chitin2": rgb(48, 32, 78),     # lighter shell
    "flesh": rgb(150, 80, 120),     # soft underside
    "bone": rgb(214, 204, 186),     # pale plates / claws
    "steel": rgb(74, 82, 96),     # station metal
    "steel_dark": rgb(40, 44, 54),
    "rubber": rgb(30, 30, 34),
    "orange": rgb(255, 140, 40),
    "teal": rgb(40, 220, 200),
    "green": rgb(90, 220, 110),
    "red": rgb(240, 70, 60),
    "purple": rgb(180, 80, 240),
    "blue": rgb(60, 160, 255),
    "yellow": rgb(255, 210, 60),
    "white": rgb(240, 240, 250),
}

_mats = {}


# ---------------------------------------------------------------- scene
def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    _mats.clear()
    scene = bpy.context.scene
    scene.unit_settings.system = "NONE"
    return scene


def _link(ob):
    bpy.context.scene.collection.objects.link(ob)
    return ob


def _active(ob):
    for o in bpy.context.view_layer.objects:
        o.select_set(False)
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob


# ---------------------------------------------------------------- materials / colors
_mats = {}


def material(color, emission=0.0, roughness=0.55, metallic=0.0, name=None):
    key = (tuple(color), emission, roughness, metallic)
    if key in _mats and _mats[key].name in bpy.data.materials:
        return _mats[key]
    m = bpy.data.materials.new(name or "M_%d" % len(_mats))
    m.use_nodes = True
    bsdf = m.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = color
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    if emission > 0:
        bsdf.inputs["Emission Color"].default_value = color
        bsdf.inputs["Emission Strength"].default_value = emission
    m.diffuse_color = color
    _mats[key] = m
    return m


def paint(ob, color, emission=0.0, roughness=0.55, metallic=0.0, alpha=1.0):
    """Give an object one flat color: vertex colors (for Roblox) + a material (for renders).
    alpha < 1 makes the render material translucent (in Studio: set the part's Transparency)."""
    me = ob.data
    ob.data.materials.clear()
    m = material(color, emission, roughness, metallic)
    if alpha < 1.0:
        m = m.copy()
        m.name = m.name + "_a"
        bsdf = m.node_tree.nodes["Principled BSDF"]
        bsdf.inputs["Alpha"].default_value = alpha
        try:
            m.surface_render_method = "BLENDED"
        except Exception:
            pass
    ob.data.materials.append(m)
    if alpha < 1.0:
        ob["alpha"] = alpha
    attr = me.color_attributes.get("Color")
    if attr is None:
        attr = me.color_attributes.new(name="Color", type="BYTE_COLOR", domain="CORNER")
    for d in attr.data:
        d.color_srgb = color
    me.color_attributes.active_color = attr
    me.color_attributes.render_color_index = me.color_attributes.find("Color")
    if emission > 0 and not ob.name.endswith("_Glow"):
        ob.name = ob.name + "_Glow"
    return ob


def gradient(ob, top, bottom, axis=2, emission=0.0):
    """Two-tone vertex gradient along an axis (world Z by default): top color at the highest verts."""
    me = ob.data
    ob.data.materials.clear()
    ob.data.materials.append(material(top, emission))
    attr = me.color_attributes.get("Color") or me.color_attributes.new(name="Color", type="BYTE_COLOR", domain="CORNER")
    mw = ob.matrix_world
    zs = [(mw @ v.co)[axis] for v in me.vertices]
    lo, hi = min(zs), max(zs)
    span = max(hi - lo, 1e-6)
    for poly in me.polygons:
        for li in poly.loop_indices:
            v = me.loops[li].vertex_index
            t = ((mw @ me.vertices[v].co)[axis] - lo) / span
            attr.data[li].color_srgb = tuple(bottom[i] * (1 - t) + top[i] * t for i in range(4))
    me.color_attributes.active_color = attr
    return ob


# ---------------------------------------------------------------- primitives
def _finish(name, location, rotation, scale, smooth):
    ob = bpy.context.active_object
    ob.name = name
    ob.location = location
    ob.rotation_euler = rotation
    ob.scale = scale
    if smooth:
        for p in ob.data.polygons:
            p.use_smooth = True
    return ob


def sphere(name, radius=1.0, location=(0, 0, 0), scale=(1, 1, 1), rotation=(0, 0, 0), subdiv=3, smooth=True):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=subdiv, radius=radius)
    return _finish(name, location, rotation, scale, smooth)


def box(name, size=(1, 1, 1), location=(0, 0, 0), rotation=(0, 0, 0), bevel=0.0, segments=2, smooth=False):
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    ob = _finish(name, location, rotation, (1, 1, 1), smooth)
    # bake the size into the mesh so bevel widths are in world units
    for v in ob.data.vertices:
        v.co = Vector((v.co.x * size[0], v.co.y * size[1], v.co.z * size[2]))
    if bevel > 0:
        add_bevel(ob, bevel, segments)
    return ob


def cylinder(name, radius=0.5, depth=1.0, location=(0, 0, 0), rotation=(0, 0, 0), verts=16, bevel=0.0, smooth=True, r2=None):
    if r2 is None:
        bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=radius, depth=depth)
    else:
        bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=radius, radius2=r2, depth=depth)
    ob = _finish(name, location, rotation, (1, 1, 1), smooth)
    if bevel > 0:
        add_bevel(ob, bevel, 2)
    return ob


def cone(name, radius=0.5, depth=1.0, location=(0, 0, 0), rotation=(0, 0, 0), verts=12, smooth=True):
    bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=radius, radius2=0.0, depth=depth)
    return _finish(name, location, rotation, (1, 1, 1), smooth)


def torus(name, major=1.0, minor=0.2, location=(0, 0, 0), rotation=(0, 0, 0), smooth=True):
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor, major_segments=32, minor_segments=12)
    return _finish(name, location, rotation, (1, 1, 1), smooth)


def plane(name, size=(1, 1), location=(0, 0, 0), rotation=(0, 0, 0), thickness=0.05):
    bpy.ops.mesh.primitive_plane_add(size=1.0)
    ob = _finish(name, location, rotation, (size[0], size[1], 1), False)
    apply_transforms(ob, scale=True)
    if thickness > 0:
        m = ob.modifiers.new("Solid", "SOLIDIFY")
        m.thickness = thickness
        m.offset = 0
    return ob


def wing(name, length, width, location=(0, 0, 0), rotation=(0, 0, 0), thickness=0.04, taper=0.35):
    """A tapered insect wing: a hexagon-ish plane pointing +X from its root, solidified."""
    me = bpy.data.meshes.new(name)
    bm = bmesh.new()
    pts = [
        (0, -width * 0.35, 0), (length * 0.35, -width * 0.5, 0), (length * 0.8, -width * 0.5 * taper, 0),
        (length, 0, 0), (length * 0.8, width * 0.5 * taper, 0), (length * 0.35, width * 0.5, 0), (0, width * 0.35, 0),
    ]
    vs = [bm.verts.new(p) for p in pts]
    bm.faces.new(vs)
    bmesh.ops.triangulate(bm, faces=bm.faces[:])
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    _link(ob)
    ob.location = location
    ob.rotation_euler = rotation
    if thickness > 0:
        m = ob.modifiers.new("Solid", "SOLIDIFY")
        m.thickness = thickness
        m.offset = 0
    return ob


def limb(name, points, radii, location=(0, 0, 0), subdiv=1, smooth=True, joints=1.2):
    """Organic tapered limb through `points` (local coords) using the Skin modifier.
    radii: one radius per point. Inner points get a joint bulge (x joints). Smooth jointed shell.
    ob.tip / ob.root hold the world positions of the last / first point (for claws, feet)."""
    me = bpy.data.meshes.new(name)
    me.from_pydata(points, [(i, i + 1) for i in range(len(points) - 1)], [])
    ob = bpy.data.objects.new(name, me)
    _link(ob)
    ob.location = location
    skin = ob.modifiers.new("Skin", "SKIN")
    skin.use_smooth_shade = smooth
    me.update()
    n = len(points)
    for i, sv in enumerate(me.skin_vertices[0].data):
        r = radii[i] * (joints if 0 < i < n - 1 else 1.0)
        sv.radius = (r, r)
    me.skin_vertices[0].data[0].use_root = True
    if subdiv > 0:
        s = ob.modifiers.new("Sub", "SUBSURF")
        s.levels = subdiv
        s.render_levels = subdiv
    ob["tip"] = [location[i] + points[-1][i] for i in range(3)]
    ob["root"] = [location[i] + points[0][i] for i in range(3)]
    return ob


def tip(ob):
    return Vector(ob["tip"])


def cone_dir(name, base, direction, length, radius, verts=10, smooth=True):
    """Cone whose base sits at `base` and which points along `direction` (world). Spikes, claws, teeth, horns."""
    d = Vector(direction).normalized()
    bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=radius, radius2=0.0, depth=length)
    ob = bpy.context.active_object
    ob.name = name
    ob.rotation_euler = d.to_track_quat("Z", "Y").to_euler()
    ob.location = Vector(base) + d * (length / 2)
    if smooth:
        for p in ob.data.polygons:
            p.use_smooth = True
    return ob


def claws(base_name, at, direction, count=3, length=0.6, radius=0.1, spread=0.18, color=None):
    """A fan of claws at a limb tip. `direction` is where they point; spread is sideways."""
    d = Vector(direction).normalized()
    side = d.cross(Vector((0, 0, 1)))
    if side.length < 1e-3:
        side = Vector((1, 0, 0))
    side.normalize()
    out = []
    for i in range(count):
        off = side * ((i - (count - 1) / 2) * spread)
        c = cone_dir("%s%d" % (base_name, i), Vector(at) + off, d, length, radius)
        paint(c, color or PAL["bone"], roughness=0.35)
        out.append(c)
    return out


def plate_on(name, at, normal, size, color, bevel=0.05, roll=0.0):
    """A beveled plate lying on a surface point, its thickness (local Z) along `normal`."""
    n = Vector(normal).normalized()
    b = box(name, size, (0, 0, 0), (0, 0, 0), bevel=bevel)
    q = n.to_track_quat("Z", "Y")
    b.rotation_euler = (q.to_matrix() @ Matrix.Rotation(roll, 3, "Z")).to_euler()
    b.location = Vector(at) + n * (size[2] * 0.1)
    paint(b, color, roughness=0.4, metallic=0.15)
    return b


def blob(name, spheres, location=(0, 0, 0), resolution=0.18, threshold=0.6, smooth=True):
    """Organic body from metaballs: spheres = [(x,y,z, radius, stiffness?)...]. Converted to a mesh."""
    mb = bpy.data.metaballs.new(name)
    mb.resolution = resolution
    mb.threshold = threshold
    for s in spheres:
        el = mb.elements.new()
        el.co = Vector(s[:3])
        el.radius = s[3]
        el.stiffness = s[4] if len(s) > 4 else 2.0
    tmp = bpy.data.objects.new(name + "_mb", mb)
    _link(tmp)
    tmp.location = location
    bpy.context.view_layer.update()
    dg = bpy.context.evaluated_depsgraph_get()
    ev = tmp.evaluated_get(dg)
    me = bpy.data.meshes.new_from_object(ev)
    ob = bpy.data.objects.new(name, me)
    _link(ob)
    ob.location = location
    bpy.data.objects.remove(tmp)
    bpy.data.metaballs.remove(mb)
    if smooth:
        for p in ob.data.polygons:
            p.use_smooth = True
    return ob


def segments(name, centers, radii, squash=0.85, subdiv=2, smooth=True):
    """Insect abdomen / thorax: overlapping spheres along `centers`, each squashed on Z.
    Joined into one mesh. Give radii a little larger than half the spacing so they overlap."""
    objs = []
    for i, (c, r) in enumerate(zip(centers, radii)):
        o = sphere("%s_%d" % (name, i), r, c, scale=(1, 1, squash), subdiv=subdiv, smooth=smooth)
        apply_transforms(o)
        objs.append(o)
    ob = join(objs, name)
    return ob


def on_ellipsoid(center, radii, direction):
    """Surface point and outward normal of an axis-aligned ellipsoid, in the given direction.
    For dropping plates, spikes and eyes exactly onto a body."""
    d = Vector(direction).normalized()
    # scale to unit sphere, normalize, scale back
    u = Vector((d.x / radii[0], d.y / radii[1], d.z / radii[2])).normalized()
    p = Vector(center) + Vector((u.x * radii[0], u.y * radii[1], u.z * radii[2]))
    n = Vector((u.x / radii[0], u.y / radii[1], u.z / radii[2])).normalized()
    return p, n


def spikes_on(base_name, center, radii, directions, length, radius, color=None):
    out = []
    for i, d in enumerate(directions):
        p, n = on_ellipsoid(center, radii, d)
        c = cone_dir("%s%d" % (base_name, i), p - n * (length * 0.15), n, length, radius)
        paint(c, color or PAL["bone"], roughness=0.35)
        out.append(c)
    return out


def plates_on(base_name, center, radii, directions, size, color, bevel=0.05):
    out = []
    for i, d in enumerate(directions):
        p, n = on_ellipsoid(center, radii, d)
        out.append(plate_on("%s%d" % (base_name, i), p - n * (size[2] * 0.4), n, size, color, bevel))
    return out


# ---------------------------------------------------------------- modifiers / edits
def add_bevel(ob, width=0.08, segments=2, angle=30):
    m = ob.modifiers.new("Bevel", "BEVEL")
    m.width = width
    m.segments = segments
    m.limit_method = "ANGLE"
    m.angle_limit = math.radians(angle)
    return m


def add_subsurf(ob, levels=1):
    m = ob.modifiers.new("Sub", "SUBSURF")
    m.levels = levels
    m.render_levels = levels
    return m


def add_decimate(ob, ratio=0.5):
    m = ob.modifiers.new("Dec", "DECIMATE")
    m.ratio = ratio
    return m


def mirror(ob, axis="X"):
    m = ob.modifiers.new("Mirror", "MIRROR")
    m.use_axis = tuple(a == axis for a in "XYZ")
    m.use_clip = True
    return m


def apply_transforms(ob, location=False, rotation=True, scale=True):
    _active(ob)
    bpy.ops.object.transform_apply(location=location, rotation=rotation, scale=scale)


def apply_modifiers(ob):
    _active(ob)
    for m in list(ob.modifiers):
        try:
            bpy.ops.object.modifier_apply(modifier=m.name)
        except RuntimeError as e:
            print("modifier_apply failed", ob.name, m.name, e)
    return ob


def join(objs, name):
    objs = [o for o in objs if o is not None]
    for o in objs:
        apply_modifiers(o)
    for o in bpy.context.view_layer.objects:
        o.select_set(False)
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    ob = bpy.context.active_object
    ob.name = name
    return ob


def displace_noise(ob, strength=0.08, scale=0.6):
    tex = bpy.data.textures.new(ob.name + "_noise", "CLOUDS")
    tex.noise_scale = scale
    m = ob.modifiers.new("Noise", "DISPLACE")
    m.texture = tex
    m.strength = strength
    m.mid_level = 0.5
    return m


def set_origin(ob, point):
    """Move the object's origin to a world point without moving the mesh."""
    mw = ob.matrix_world.copy()
    delta = mw.inverted() @ Vector(point)
    for v in ob.data.vertices:
        v.co -= delta
    ob.matrix_world = mw @ Matrix.Translation(delta)


def center_origin(ob):
    _active(ob)
    bpy.ops.object.origin_set(type="ORIGIN_GEOMETRY", center="BOUNDS")


def parent(child, parent_ob):
    child.parent = parent_ob
    child.matrix_parent_inverse = parent_ob.matrix_world.inverted()


# ---------------------------------------------------------------- measurements
def tri_count(ob):
    dg = bpy.context.evaluated_depsgraph_get()
    ev = ob.evaluated_get(dg)
    me = ev.to_mesh()
    n = sum(len(p.vertices) - 2 for p in me.polygons)
    ev.to_mesh_clear()
    return n


def bounds(objs):
    lo = Vector((1e9, 1e9, 1e9))
    hi = Vector((-1e9, -1e9, -1e9))
    dg = bpy.context.evaluated_depsgraph_get()
    for ob in objs:
        ev = ob.evaluated_get(dg)
        for c in ev.bound_box:
            w = ev.matrix_world @ Vector(c)
            lo = Vector(map(min, lo, w))
            hi = Vector(map(max, hi, w))
    return lo, hi


# ---------------------------------------------------------------- export
def export_model(rel_name, objs, manifest_extra=None):
    """Export objs as one FBX + one GLB under assets/models/<rel_name>.{fbx,glb} and record a manifest entry."""
    objs = [o for o in objs if o is not None]
    out = os.path.join(ASSETS, "models", rel_name)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    for o in bpy.context.view_layer.objects:
        o.select_set(False)
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.export_scene.fbx(
        filepath=out + ".fbx",
        use_selection=True,
        apply_scale_options="FBX_SCALE_UNITS",
        axis_forward="-Z",
        axis_up="Y",
        mesh_smooth_type="FACE",
        colors_type="SRGB",
        add_leaf_bones=False,
        bake_anim=False,
        use_mesh_modifiers=True,
        path_mode="COPY",
        embed_textures=False,
    )
    bpy.ops.export_scene.gltf(
        filepath=out + ".glb",
        export_format="GLB",
        use_selection=True,
        export_yup=True,
        export_apply=True,
        export_vertex_color="ACTIVE",
        export_materials="EXPORT",
    )
    lo, hi = bounds(objs)
    size = hi - lo
    entry = {
        "name": rel_name,
        "parts": [{"name": o.name, "tris": tri_count(o), "glow": o.name.endswith("_Glow")} for o in objs],
        "size_studs": [round(size.x, 2), round(size.z, 2), round(size.y, 2)],  # x, height(y in Roblox), depth
        "tris": sum(tri_count(o) for o in objs),
    }
    if manifest_extra:
        entry.update(manifest_extra)
    for p in entry["parts"]:
        if p["tris"] > 10000:
            print("WARNING: %s/%s has %d tris (Roblox MeshPart limit is 10k)" % (rel_name, p["name"], p["tris"]))
    _manifest_add(entry)
    return entry


def _manifest_add(entry):
    """Read-modify-write under a file lock: several build processes may export at the same time."""
    import fcntl
    path = os.path.join(ASSETS, "models", "manifest.json")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path + ".lock", "w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        data = {}
        if os.path.exists(path):
            try:
                with open(path) as f:
                    data = json.load(f)
            except Exception as e:
                print("manifest unreadable, keeping a copy:", e)
                os.replace(path, path + ".broken")
        data[entry["name"]] = entry
        tmp = path + ".tmp"
        with open(tmp, "w") as f:
            json.dump(data, f, indent=1, sort_keys=True)
        os.replace(tmp, path)
        fcntl.flock(lock, fcntl.LOCK_UN)


# ---------------------------------------------------------------- rendering
def _look_at(cam, target):
    d = Vector(target) - cam.location
    cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()


def setup_render(samples=48, res=640):
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = samples
    scene.cycles.use_denoising = True
    try:
        scene.cycles.denoiser = "OPENIMAGEDENOISE"
    except Exception:
        pass
    scene.render.resolution_x = res
    scene.render.resolution_y = res
    scene.render.film_transparent = False
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    scene.view_settings.exposure = 0.0
    # world: dark blue-grey
    world = bpy.data.worlds.new("W") if scene.world is None else scene.world
    scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    bg.inputs[0].default_value = (0.012, 0.014, 0.02, 1)
    bg.inputs[1].default_value = 1.0
    return scene


def _light(name, kind, location, energy, color=(1, 1, 1), size=4.0, target=(0, 0, 1)):
    ld = bpy.data.lights.new(name, kind)
    ld.energy = energy
    ld.color = color
    if kind == "AREA":
        ld.size = size
    ob = bpy.data.objects.new(name, ld)
    _link(ob)
    ob.location = location
    _look_at(ob, target)
    return ob


def render_model(title, objs, rel_out, angle_deg=35, elev_deg=18, pad=1.25, samples=48, res=640, floor=True):
    """Studio-style still of the objects: three lights, dark backdrop, camera framing the bounds."""
    objs = [o for o in objs if o is not None]
    scene = setup_render(samples, res)
    lo, hi = bounds(objs)
    center = (lo + hi) / 2
    size = max((hi - lo).x, (hi - lo).y, (hi - lo).z)
    dist = size * pad * 2.2
    a = math.radians(angle_deg)
    e = math.radians(elev_deg)
    cam_data = bpy.data.cameras.new("Cam")
    cam_data.lens = 50
    cam = bpy.data.objects.new("Cam", cam_data)
    _link(cam)
    cam.location = center + Vector((math.sin(a) * math.cos(e), math.cos(a) * math.cos(e), math.sin(e))) * dist
    _look_at(cam, center)
    scene.camera = cam
    extras = [cam]
    extras.append(_light("Key", "AREA", center + Vector((size * 1.5, size * 1.5, size * 1.6)), 300 * size * size / 4, (1, 0.95, 0.9), size * 1.2, center))
    extras.append(_light("Fill", "AREA", center + Vector((-size * 2, size * 1.0, size * 0.6)), 120 * size * size / 4, (0.7, 0.8, 1.0), size * 2, center))
    extras.append(_light("Rim", "AREA", center + Vector((-size * 0.5, -size * 2.0, size * 1.2)), 500 * size * size / 4, (0.6, 0.9, 1.0), size * 0.8, center))
    if floor:
        bpy.ops.mesh.primitive_plane_add(size=size * 12)
        fl = bpy.context.active_object
        fl.name = "Floor"
        fl.location = (center.x, center.y, lo.z - 0.01)
        paint(fl, (0.035, 0.04, 0.05, 1), roughness=0.9)
        extras.append(fl)
    out = os.path.join(ASSETS, "renders", rel_out)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    scene.render.filepath = out
    bpy.ops.render.render(write_still=True)
    for o in extras:
        bpy.data.objects.remove(o, do_unlink=True)
    return out


def hide_all_but(objs):
    keep = set(o.name for o in objs)
    for o in bpy.context.scene.objects:
        o.hide_render = o.name not in keep
        o.hide_viewport = o.name not in keep


def show_all():
    for o in bpy.context.scene.objects:
        o.hide_render = False
        o.hide_viewport = False
