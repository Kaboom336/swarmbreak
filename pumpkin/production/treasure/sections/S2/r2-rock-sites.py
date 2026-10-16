"""Find tangent wall rock envelopes with zero physical and strict horizontal lane overlap."""
import json,sys
from pathlib import Path
import numpy as np
H=Path(__file__).resolve().parent
scope={'__file__':str(H/'contact.py')};sys.argv=['contact.py','r2-after'];exec((H/'contact.py').read_text().split('physical=')[0],scope)
box,penetrates=scope['box'],scope['penetrates']
d=json.loads((H/'r2-after.json').read_text());physical=[(p,box(p)) for p in d['parts'] if p['collidable']]
lo=np.array([b[3] for _,b in physical]);hi=np.array([b[4] for _,b in physical])
lanes=[]
for p in d['parts']:
 if p.get('lane'):
  q=dict(p);q['size']=[p['size'][0]+2,500,p['size'][2]+2];q['position']=[p['position'][0],0,p['position'][2]];lanes.append(box(q))
seen=json.loads((H/'r2-visible.json').read_text());indices={a['key'] for a in seen}
selected=[]
for p,b in physical:
 if p['name']!='TunnelHillEarth' or p['position'][0]>-35 or p['position'][0]<-120 or p['position'][2]<0 or p['position'][2]>114:continue
 if p['name']+'@'+','.join(f'{v:.3f}' for v in p['position']) not in indices:continue
 c,R,h,low,high=b
 for axis,sign in [(0,1),(0,-1),(2,1),(2,-1)]:
  # Work from the outer face, wholly outside all solid bounding boxes.
  for size in [4,3,2]:
   for y in [3,7,11,15]:
    center=c.copy();center[1]=y;center[axis]+=sign*(h[axis]+size/2)
    q={'position':center.tolist(),'rotation':[1,0,0,0,1,0,0,0,1],'size':[size]*3};a=box(q)
    if any(np.all(np.minimum(a[4],l[4])-np.maximum(a[3],l[3])>.035) and penetrates(a,l) for l in lanes):continue
    cand=np.where(np.all(np.minimum(a[4],hi)-np.maximum(a[3],lo)>.035,axis=1))[0]
    if any(penetrates(a,physical[i][1]) for i in cand):continue
    # The cladding must face at least one locked camera.
    if not any((np.array(eye)-center)[axis]*sign>0 for eye in [(-35,7,130),(-53,6,115)]):continue
    if any(np.linalg.norm(center-np.array(g['position']))<size*1.1 for g in selected):continue
    selected.append(dict(position=center.tolist(),size=size,axis=axis,sign=sign,support=p['position']))
(H/'r2-rock-sites.json').write_text(json.dumps(selected,indent=2))
print(json.dumps(selected[:35],indent=2));print('sites',len(selected))
