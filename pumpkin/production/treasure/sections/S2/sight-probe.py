import sys,json,math
from pathlib import Path
H=Path(__file__).resolve().parent
exec(compile((H/'render.py').read_text().split('coverage={}')[0],str(H/'render.py'),'exec'))
results={}
for name,eye,target in [('walk',(-35,-130,7),(-68,-92,5)),('mouth',(-53,-115,6),(-69,-86,6))]:
 cam.location=eye;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.lens=24
 bpy.context.view_layer.update();hits=[]
 for px,py in [(280,160),(430,300),(525,250),(850,350),(950,350),(1100,300),(700,220),(600,370)]:
  dx=(px/1280-.5)*36/24;dy=(.5-py/720)*36/24*720/1280
  ray=cam.matrix_world.to_3x3()@Vector((dx,dy,-1));hit,pos,normal,index,obj,matrix=scene.ray_cast(bpy.context.evaluated_depsgraph_get(),cam.location,ray.normalized())
  hits.append({'pixel':[px,py],'world':[pos.x,pos.z,-pos.y],'normal':[normal.x,normal.z,-normal.y],'object':obj.name if hit else None})
 results[name]=hits
(H/'sight-probe.json').write_text(json.dumps(results,indent=2))
print(json.dumps(results))
