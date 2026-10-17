"""Find existing supported surface pockets outside ALL projected lane margins."""
import json,numpy as np
from pathlib import Path
H=Path(__file__).resolve().parent
d=json.loads((H/'before.json').read_text());ps=d['parts']
def bounds(p,margin=0):
 c=np.array(p['position']);r=np.array(p['rotation']).reshape(3,3);h=np.array(p['size'])/2+np.array([margin,0,margin]);e=np.abs(r)@h;return c-e,c+e
lanes=[bounds(p,1) for p in ps if p.get('lane')]
def safe(x,z,w=1,depth=1):
 return not any(min(x+w/2,b[0])-max(x-w/2,a[0])>.02 and min(z+depth/2,b[2])-max(z-depth/2,a[2])>.02 for a,b in lanes)
out=[]
for p in ps:
 if not p['collidable'] or p['name']!='SolidMountainStone':continue
 a,b=bounds(p);x,y,z=p['position'];top=b[1]
 if -31<x<31 and -131<z<-73 and top>=44 and safe(x,z,3,3):out.append(dict(x=x,z=z,top=round(top,4)))
(H/'POCKETS.json').write_text(json.dumps(out,indent=2));print(out)
