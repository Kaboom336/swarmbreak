"""Candidate scan, not acceptance: supported two-stud ore-cache pockets off all lanes."""
from pathlib import Path
import numpy as np,json
H=Path(__file__).resolve().parent
code=(H/'plan.py').read_text().split('for z in range')[0]
exec(compile(code,str(H/'plan.py'),'exec'))
floors=[]
for p,b in physical:
 if np.max(np.abs(b[1]-np.eye(3)))<.001 and -.5<b[4][1]<1:floors.append((p,b))
lanes=[]
for p in d['parts']:
 if not p.get('lane'):continue
 q=dict(p);q['position']=[p['position'][0],p['position'][1]+3.5,p['position'][2]];q['size']=[p['size'][0]+2,p['size'][1]+7,p['size'][2]+2];lanes.append(box(q))
sites=[]
for x in np.arange(-95,-42,1):
 for z in np.arange(-22,96,1):
  # Trunk/branch interior footprint, including potential pockets immediately outside policy width.
  distance=min(abs(x+76) if -22<=z<=78 else 999,math.hypot(x+60,max(82-z,0,z-96)))
  if distance>12:continue
  candidates=[b[4][1] for p,b in floors if b[3][0]-.001<=x-1.1 and b[4][0]+.001>=x+1.1 and b[3][2]-.001<=z-1.1 and b[4][2]+.001>=z+1.1]
  if not candidates:continue
  y=max(candidates);a=box(dict(position=[x,y+1.25,z],size=[2.2,2.5,2.2],rotation=identity))
  if any(penetrates(a,b) for b in lanes if np.all(np.minimum(a[4],b[4])-np.maximum(a[3],b[3])>.035)):continue
  if not safe([x,y+1.25,z],[2.2,2.5,2.2]):continue
  roof=[p for p,b in physical if b[3][0]<=x<=b[4][0] and b[3][2]<=z<=b[4][2] and 18<=b[3][1]<=27]
  if not roof:continue
  sites.append(dict(x=float(x),y=float(y),z=float(z)))
(H/'POCKET-CANDIDATES.json').write_text(json.dumps(dict(footprint=[2.2,2.2],height=2.5,sites=sites,method='Full common axis-aligned physical support footprint, OBB/SAT collision and all lane margins; conservative overhead roof-bounds filter. Any accepted site still needs full contact audit and player-image review.'),indent=2))
print(len(sites),'candidate pockets',sites[:15])
