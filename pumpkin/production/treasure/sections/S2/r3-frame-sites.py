import json,sys
from pathlib import Path
import numpy as np
H=Path(__file__).resolve().parent
sys.argv=['contact.py','r3-after'];scope={'__file__':str(H/'contact.py')};exec((H/'contact.py').read_text().split('physical=')[0],scope)
box,penetrates=scope['box'],scope['penetrates'];d=json.loads((H/'r3-after.json').read_text())
solids=[(p,box(p)) for p in d['parts'] if p['collidable']]
lo=np.array([b[3] for _,b in solids]);hi=np.array([b[4] for _,b in solids])
lanes=[]
for p in d['parts']:
 if p.get('lane'):
  q=dict(p);q['size']=[p['size'][0]+2,p['size'][1]+7,p['size'][2]+2];q['position']=[p['position'][0],p['position'][1]+3.5,p['position'][2]];lanes.append(box(q))
for label,anchor,xs,zs in [('left',[-75.2,99],np.arange(-82,-70,.4),np.arange(94,114,.5)),('right',[-52.7,88],np.arange(-58,-46,.4),np.arange(82,102,.5))]:
 found=[]
 for y in [0,2,4,6,7.6]:
  for x in xs:
   for z in zs:
    size=[1.2,13.5-y,2.5];q={'position':[x,y+size[1]/2,z],'size':size,'rotation':[1,0,0,0,1,0,0,0,1]};a=box(q)
    if any(np.all(np.minimum(a[4],b[4])-np.maximum(a[3],b[3])>.035) and penetrates(a,b) for b in lanes):continue
    cand=np.where(np.all(np.minimum(a[4],hi)-np.maximum(a[3],lo)>.035,axis=1))[0]
    if any(penetrates(a,solids[i][1]) for i in cand):continue
    # A wall-facing post needs side contact, not a floating candidate in corridor space.
    if not any(np.max(np.maximum(a[3]-b[4],b[3]-a[4]))<.05 for _,b in solids):continue
    found.append((round((x-anchor[0])**2+(z-anchor[1])**2,2),round(float(x),3),y,round(float(z),3)))
  if found:break
 print(label,sorted(found)[:20])
