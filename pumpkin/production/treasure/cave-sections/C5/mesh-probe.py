"""Read the reused CC0 source FBX; no mesh editing or upload."""
import bpy,json
from pathlib import Path
from mathutils import Vector
H=Path(__file__).resolve().parent;ROOT=H.parents[2]
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.fbx(filepath=str(ROOT/'assets/kits2/cave/quaternius-nature__Rock_Medium_1__cave.fbx'))
m=next(o for o in bpy.data.objects if o.type=='MESH')
pts=[m.matrix_world@v.co for v in m.data.vertices]
lo=Vector(tuple(min(v[i]for v in pts)for i in range(3)));hi=Vector(tuple(max(v[i]for v in pts)for i in range(3)))
vs=[[(v.x-lo.x)/(hi.x-lo.x)-.5,(v.z-lo.z)/(hi.z-lo.z)-.5,-(v.y-lo.y)/(hi.y-lo.y)+.5]for v in pts]
(H/'ROCK-SOURCE.json').write_text(json.dumps(dict(vertices=vs,faces=[list(f.vertices)for f in m.data.polygons])))
