"""Read-only projection diagnostics for the matched hill camera."""
import json, math
import importlib.util
from pathlib import Path
from mathutils import Vector
H=Path(__file__).parent
s=json.loads((H/'scene.json').read_bytes())
spec=importlib.util.spec_from_file_location('pa',H/'placement-audit.py');pa=importlib.util.module_from_spec(spec);spec.loader.exec_module(pa)
eye=Vector((-205,112,158));target=Vector((-76,-30,23))
forward=(target-eye).normalized();right=forward.cross(Vector((0,0,1))).normalized();up=right.cross(forward).normalized()
for p in s['parts']:
 if p['name']!='TunnelHillTurf':continue
 r=p['rotation'];c=p['position'];v=[c[i]+r[i*3+1]*.7 for i in range(3)]
 q=Vector((v[0],-v[2],v[1]))-eye
 x,y=.5+q.dot(right)/210,.5+q.dot(up)/140
 if x>.91 and .22<y<.7:
  support=[]
  for other in s['parts']:
   if not other['collidable'] or other['category'].startswith('tunnel'):continue
   hit=pa.vertical(other,v[0],v[2])
   if hit and -2<hit[1]<10:support.append((other['name'],other['category'],round(hit[1],2)))
  print('right tab cell',v,'image',round(x,3),round(y,3),'underlying',support[:3])
