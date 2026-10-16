"""Measure safe tangent kit envelopes against the frozen R2 scene."""
import json,numpy as np
from pathlib import Path
H=Path(__file__).resolve().parent
d=json.loads((H/'r2.json').read_text())
def bounds(p,expand=False):
 c=np.array(p['position']);s=np.array(p['size'])/2
 if expand:s+=np.array([1,3.5,1]);c=c+np.array([0,3.5,0])
 e=np.abs(np.array(p['rotation']).reshape(3,3))@s
 return c-e,c+e
sol=[bounds(p) for p in d['parts'] if p['collidable']]
lanes=[bounds(p,True) for p in d['parts'] if p.get('lane')]
lo=np.array([a for a,b in sol+lanes]);hi=np.array([b for a,b in sol+lanes])
def free(c,s):
 a=np.array(c)-np.array(s)/2;b=np.array(c)+np.array(s)/2
 return not np.any(np.all(np.minimum(b,hi)-np.maximum(a,lo)>.025,axis=1))
rocks=[]
for z in [-2,10,22,34,46]:
 for side in [-1,1]:
  for y in [7,12,17,22,27,32]:
   row=[p for p in d['parts'] if p['name']=='SolidMountainStone' and abs(p['position'][2]-z)<1 and p['position'][1]-p['size'][1]/2<y-1.5 and p['position'][1]+p['size'][1]/2>y+1.5 and (p['position'][0]-110)*side>0]
   if not row:continue
   wall=min(row,key=lambda p:abs(p['position'][0]-110))
   x=wall['position'][0]-side*wall['size'][0]/2
   for depth in [2.4,1.5,.8]:
    c=[x-side*depth/2,y,z];s=[depth,4.2,3.4]
    if free(c,s):rocks.append(dict(x=c[0],y=y-2.1,z=z,size=s));break
pines=[]
for x,z in [(128,24),(92,28),(128,48),(88,12),(132,-8),(90,48)]:
 supports=[p for p in d['parts'] if p['collidable'] and abs(p['position'][0]-x)<p['size'][0]/2+.01 and abs(p['position'][2]-z)<p['size'][2]/2+.01 and p['name']=='SolidMountainStone']
 if not supports:continue
 y=max(p['position'][1]+p['size'][1]/2 for p in supports)
 if free([x,y+6,z],[5,12,5]):pines.append(dict(x=x,y=y,z=z,size=[5,12,5]))
plates=[p for p in d['parts'] if 85<p['position'][0]<140 and -10<p['position'][2]<60 and p['name']=='LookLightRockTop' and p['position'][1]>4]
print('rocks',json.dumps(rocks));print('pines',json.dumps(pines));print('plate examples',json.dumps(plates[:3]))
(H/'PLAN-R3.json').write_text(json.dumps(dict(rocks=rocks,pines=pines[:3]),indent=2))
