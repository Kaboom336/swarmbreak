"""Gameplay hero shot: the arena corner with enemies and a weapon, from a third-person camera, like a store thumbnail.
Uses the exported GLBs (vertex colours baked) so it works with whatever the current models are.
Run: python3 hero.py [samples]  -> assets/renders/hero.png"""
import math
import os
import sys

import bpy
from mathutils import Vector, Matrix

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sb
import sb2

MODELS = os.path.join(sb.ASSETS, "models")


def glb(group, name):
    p = os.path.join(MODELS, group, name + ".glb")
    return p if os.path.exists(p) else None


def put(group, name, location, rot=0.0, scale=1.0):
    p = glb(group, name)
    if not p:
        print("missing", group, name)
        return None
    ob = sb2.import_kit(p, name="%s_%s_%d" % (group, name, int(location[0] * 10 + location[1])), scale=scale, to_vcol=False, join_all=True, flat=False)
    if ob is None:
        return None
    # our GLBs carry the 'Color' attribute already; make the render read it, keep glow parts glowing
    parts = [o for o in bpy.context.scene.objects if o.name.startswith(ob.name)]
    ob.rotation_euler = (0, 0, math.radians(rot))
    ob.location = Vector(location)
    sb2.use_vcol(ob, roughness=0.6)
    return ob


def import_model_parts(group, name, location, rot=0.0, scale=1.0):
    """Import keeping parts separate so *_Glow parts get emission."""
    p = glb(group, name)
    if not p:
        print("missing", group, name)
        return []
    before = set(bpy.context.scene.objects)
    bpy.ops.import_scene.gltf(filepath=p)
    new = [o for o in bpy.context.scene.objects if o not in before]
    meshes = [o for o in new if o.type == "MESH"]
    for o in meshes:
        o.parent = None
    for o in new:
        if o.type != "MESH":
            bpy.data.objects.remove(o, do_unlink=True)
    R = math.radians(rot)
    for o in meshes:
        sb.apply_transforms(o, location=False, rotation=True, scale=True)
        glow = "_Glow" in o.name
        alpha = float(o.get("alpha", 1.0)) if o.get("alpha") is not None else 1.0
        sb2.use_vcol(o, roughness=0.6, emission=1.6 if glow else 0.0, alpha=alpha)
        o.matrix_world = Matrix.Translation(Vector(location)) @ Matrix.Rotation(R, 4, "Z") @ Matrix.Scale(scale, 4) @ o.matrix_world
    return meshes


def build_scene():
    sb.reset()
    objs = []
    # floor: 6x6 tiles of 8 studs (v1 FloorTile is 8x8) with grates
    tile = glb("arena", "FloorTile")
    if tile:
        for i in range(6):
            for j in range(6):
                name = "FloorGrate" if (i + j) % 5 == 2 else "FloorTile"
                objs += import_model_parts("arena", name, (i * 8 - 20, j * 8 - 20, 0))
    for i in range(6):
        objs += import_model_parts("arena", "Wall", (i * 8 - 20, 28, 0))
    objs += import_model_parts("arena", "Wall", (28, 4, 0), rot=90)
    objs += import_model_parts("arena", "Wall", (28, 20, 0), rot=90)
    objs += import_model_parts("arena", "Gate", (28, 12, 0), rot=90)
    objs += import_model_parts("arena", "Pillar", (-20, 28, 0))
    objs += import_model_parts("arena", "Pillar", (28, 28, 0))
    objs += import_model_parts("arena", "Crate", (6, 10, 0), rot=20)
    objs += import_model_parts("arena", "Crate", (9, 12, 0), rot=-10)
    objs += import_model_parts("arena", "Barrel", (-8, 14, 0))
    objs += import_model_parts("arena", "Lamp", (-16, 22, 0))
    objs += import_model_parts("arena", "SpawnHole", (14, 22, 0))
    objs += import_model_parts("arena", "NestRoot", (18, 26, 0), rot=30)
    # enemies pouring in from the spawn hole toward the camera
    objs += import_model_parts("enemies", "Walker", (10, 14, 0), rot=200)
    objs += import_model_parts("enemies", "Walker", (2, 20, 0), rot=215)
    objs += import_model_parts("enemies", "Runner", (-6, 6, 0), rot=190)
    objs += import_model_parts("enemies", "Runner", (16, 8, 0), rot=230)
    objs += import_model_parts("enemies", "Flyer", (4, 12, 6), rot=200)
    objs += import_model_parts("enemies", "Tank", (12, 24, 0), rot=205)
    objs += import_model_parts("enemies", "Spitter", (-12, 18, 0), rot=170)
    objs += import_model_parts("enemies", "Brute", (20, 34, 0), rot=210)
    # a weapon floating where the player's hands would be (bottom right)
    objs += import_model_parts("weapons", "Nova", (-4, -14, 4), rot=15)
    return [o for o in objs if o is not None]


if __name__ == "__main__":
    samples = int(sys.argv[1]) if len(sys.argv) > 1 else 96
    objs = build_scene()
    print("scene objects", len(objs))
    out = sb2.render_scene("hero.png", cam_from=(-16, -30, 16), cam_at=(4, 10, 3), lens=30, samples=samples, res=(1280, 720), floor_z=-0.05, floor_size=400, sun=True, fog=False)
    print("rendered", out)
