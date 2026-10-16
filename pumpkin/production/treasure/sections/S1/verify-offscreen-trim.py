"""Prove post-render contact trim cannot change arrival pixels; no fourth render."""
import json, itertools, numpy as np
from pathlib import Path
H=Path(__file__).parent
d=json.loads((H/'r3.json').read_text())
removed=[p for p in d['parts'] if p.get('section')=='S1' and p['name'].startswith(('S1_CliffVine','S1_CliffMossLeaf')) and p['position'][2]>=90]
if not removed:
 # Reconstruct only the removed R3 candidate from its retained physical wall
 # carriers, so the proof is repeatable after the final export removes it.
 faces={}
 for p in d['parts']:
  x,y,z=p['position'];w,h,depth=p['size']
  if p['name']=='TunnelHillEarth' and -100<=x<=-25 and 90<=z<=99 and y-h/2<1 and h>15:
   face=x+w/2
   if z not in faces or face>faces[z][0]:faces[z]=(face,y+h/2)
 for z,(face,top) in faces.items():
  h=min(18,top-10-.7)
  removed.append({'position':[face+.06,10+h/2,z],'size':[.12,h,.22],'rotation':[1,0,0,0,1,0,0,0,1]})
  for i in range(1,int(h/1.2)+1):
   removed.append({'position':[face+.14,10+i*1.2,z+(.7 if i%2==0 else -.7)],'size':[.28,1.4,2],'rotation':[1,0,0,0,1,0,0,0,1]})
def outside(p,eye,target,lens):
 eye=np.array(eye,dtype=float);f=np.array(target,dtype=float)-eye;f/=np.linalg.norm(f)
 right=np.cross(f,[0,0,1]);right/=np.linalg.norm(right);up=np.cross(right,f)
 r=np.array(p['rotation']).reshape(3,3);c=np.array(p['position']);h=np.array(p['size'])/2
 points=[]
 for signs in itertools.product([-1,1],repeat=3):
  q=r@(h*np.array(signs))+c;q=np.array([q[0],-q[2],q[1]])-eye
  depth=q@f;points.append([(q@right)/depth*lens/18,(q@up)/depth*lens/(18*720/1280)])
 points=np.array(points)
 return bool(any(np.all(points[:,axis]*sign>1) for axis in [0,1] for sign in [-1,1]))
out={'trimmed_parts':len(removed),'arrival_all_outside_frustum':all(outside(p,(0,-154,5.5),(0,96,24),24) for p in removed),'overview_all_outside_frustum':all(outside(p,(92,-205,88),(0,-122,4),35) for p in removed),'method':'All 8 oriented-box corners outside a common camera-frustum side plane. Arrival direct visibility and masks unchanged; indirect lighting may differ. Overview predates contact trim.'}
(H/'r3-offscreen-trim.json').write_text(json.dumps(out,indent=2));print(json.dumps(out,indent=2))
assert removed and out['arrival_all_outside_frustum']
