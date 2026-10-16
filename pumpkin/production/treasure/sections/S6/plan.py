"""Measure supported off-lane silhouette pockets; no route/solid changes."""
import json,numpy as np
from pathlib import Path
H=Path(__file__).resolve().parent
d=json.loads((H/'before.json').read_text())
def bounds(p,margin=False):
 c=np.array(p['position']);s=np.array(p['size'])/2
 if margin:s+=np.array([1,100,1])
 e=np.abs(np.array(p['rotation']).reshape(3,3))@s
 return c-e,c+e
physical=[bounds(p) for p in d['parts'] if p['collidable']]
lanes=[bounds(p,True) for p in d['parts'] if p.get('lane')]
lo=np.array([a for a,b in physical+lanes]);hi=np.array([b for a,b in physical+lanes])
routes=[p for p in d['parts'] if p.get('lane') and (p['name'].startswith('Fix2Lane_spiral_') or p['name'].startswith('Fix2Lane_shelf_')) and not p['name'].endswith('Base') and not 'link' in p['name']]
def free(c,s):
 a=np.array(c)-np.array(s)/2;b=np.array(c)+np.array(s)/2
 return not np.any(np.all(np.minimum(b,hi)-np.maximum(a,lo)>.025,axis=1))
candidates=[]
for p in d['parts']:
 if p['name']!='SolidMountainStone':continue
 x,y,z=p['position'];top=y+p['size'][1]/2
 if not(-64<x<124 and -157<z<-36 and 0<=top<=49):continue
 if -34<x<34 and -134<z<-70:continue
 if free([x,top+1.6,z],[1.1,3.2,1.1]):
  r=min(routes,key=lambda r:(r['position'][0]-x)**2+(r['position'][2]-z)**2)
  dist=np.linalg.norm(np.array([x,z])-np.array(r['position'])[::2])
  if 10<dist<17 and abs(top-r['position'][1])<9:
   candidates.append(dict(x=x,y=top,z=z,route=r['name'],dist=float(dist)))
print(json.dumps(candidates,indent=2))
(H/'POCKETS.json').write_text(json.dumps(candidates,indent=2))
