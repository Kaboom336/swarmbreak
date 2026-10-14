"""Diagnostic render of saved Roblox part geometry. NEVER a Studio screenshot."""
import bpy, json, math
from pathlib import Path
from mathutils import Matrix, Vector

ROOT = Path(__file__).resolve().parents[3]
OUT = Path(__file__).resolve().parent
for letter in "ABC":
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    materials = {}
    data = json.loads((ROOT / f"treasure/map-v3/ingame/{letter}-geometry.json").read_text())
    for p in data:
        if p["transparency"] > 0.5:
            continue
        cf = p["cf"]
        if p["shape"].endswith("Ball"):
            bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=6)
            obj = bpy.context.object
            obj.scale = Vector(p["size"]) / 2
        elif p["shape"].endswith("Cylinder"):
            bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=1, depth=2, rotation=(0, math.pi/2, 0))
            obj = bpy.context.object
            bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
            obj.scale = Vector(p["size"]) / 2
        else:
            bpy.ops.mesh.primitive_cube_add(size=1)
            obj = bpy.context.object
            obj.scale = Vector(p["size"])
        # Roblox Y-up -> Blender Z-up; world Z negated into image north.
        transform = Matrix(((cf[3],cf[4],cf[5],cf[0]),(cf[6],cf[7],cf[8],cf[1]),(cf[9],cf[10],cf[11],cf[2]),(0,0,0,1)))
        convert = Matrix(((1,0,0,0),(0,0,-1,0),(0,1,0,0),(0,0,0,1)))
        scale = Vector(p["size"]) / (2 if p["shape"].endswith(("Ball","Cylinder")) else 1)
        obj.matrix_world = convert @ transform @ Matrix.Diagonal((*scale,1))
        obj.name = p["name"]
        key = tuple(p["color"]) + ("Neon" in p["material"],)
        if key not in materials:
            mat = bpy.data.materials.new(str(key))
            mat.diffuse_color = (*p["color"],1)
            mat.use_nodes = True
            bsdf = mat.node_tree.nodes.get("Principled BSDF")
            bsdf.inputs["Base Color"].default_value = (*p["color"],1)
            bsdf.inputs["Roughness"].default_value = 0.8
            if key[-1]:
                bsdf.inputs["Emission Color"].default_value = (*p["color"],1)
                bsdf.inputs["Emission Strength"].default_value = 1.5
            materials[key] = mat
        obj.data.materials.append(materials[key])
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.eevee.taa_render_samples = 8
    scene.render.resolution_x = 1000
    scene.render.resolution_y = 800
    scene.render.resolution_percentage = 100
    scene.world.color = (0.35,0.60,0.8)
    scene.world.use_nodes = True
    scene.world.node_tree.nodes.get("Background").inputs["Color"].default_value = (0.35,0.60,0.8,1)
    bpy.ops.object.light_add(type="SUN", location=(0,-60,120))
    sun = bpy.context.object
    sun.rotation_euler = (math.radians(20),math.radians(-25),math.radians(-35))
    sun.data.energy = 2
    bpy.ops.object.light_add(type="AREA", location=(-100,-80,150))
    fill = bpy.context.object
    fill.data.energy = 20000
    fill.data.shape = "DISK"
    fill.data.size = 200
    bpy.ops.object.camera_add()
    cam = bpy.context.object
    scene.camera = cam
    for view, eye, target, scale in [("top",(0,0,400),(0,0,0),260),("34",(-145,-240,155),(0,8,0),300)]:
        cam.location = eye
        cam.rotation_euler = (Vector(target)-cam.location).to_track_quat("-Z","Y").to_euler()
        cam.data.type = "ORTHO"
        cam.data.ortho_scale = scale
        scene.render.filepath = str(OUT / f"{letter}-{view}-offline.png")
        bpy.ops.render.render(write_still=True)
print("OFFLINE diagnostic renders, not Studio captures")
