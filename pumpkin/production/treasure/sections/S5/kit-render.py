"""Render the same fitted CC0 kits2 meshes used by Section5.spawnKits."""
import bpy,json
from pathlib import Path
from mathutils import Vector
H=Path(__file__).resolve().parent
def add_kits(tag):
 for g in json.loads((H/(tag+'-kits.json')).read_text()):
  before=set(bpy.data.objects)
  file=H.parents[2]/'assets/kits2/meadow'/(g['name']+'__meadow.fbx')
  bpy.ops.import_scene.fbx(filepath=str(file))
  objects=[o for o in bpy.data.objects if o not in before];meshes=[o for o in objects if o.type=='MESH']
  points=[o.matrix_world@Vector(c) for o in meshes for c in o.bound_box]
  lo=Vector(tuple(min(v[i] for v in points) for i in range(3)));hi=Vector(tuple(max(v[i] for v in points) for i in range(3)))
  # Blender FBX is Z-up; Roblox is Y-up. Fit world mesh into the exact envelope.
  size=(g['size'][0],g['size'][2],g['size'][1]);base=Vector((g['x'],-g['z'],g['y']))
  mat=bpy.data.materials.new(g['id']);mat.diffuse_color=tuple(v/255 for v in g['color'])+(1,)
  for o in meshes:
   world=o.matrix_world.copy();o.parent=None;o.matrix_world.identity()
   for v in o.data.vertices:
    p=world@v.co;t=Vector(tuple((p[i]-lo[i])/(hi[i]-lo[i])*size[i] for i in range(3)))
    v.co=base+t-Vector((size[0]/2,size[1]/2,0))
   o.data.materials.clear();o.data.materials.append(mat)
  for o in objects:
   if o.type!='MESH':bpy.data.objects.remove(o,do_unlink=True)
