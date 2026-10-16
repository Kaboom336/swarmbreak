"""Probe conservative wall pockets with the existing OBB/SAT functions."""
import json,numpy as np
from pathlib import Path
H=Path(__file__).resolve().parent
s=(H.parent/'S2/contact.py').read_text();ns={'np':np};exec(s[s.index('def box('):s.index('physical=[')],ns)
box,penetrates=ns['box'],ns['penetrates'];d=json.loads((H/'before.json').read_text())
physical=[(p,box(p)) for p in d['parts'] if p['collidable']]
lo=np.array([b[3] for _,b in physical]);hi=np.array([b[4] for _,b in physical])
lanes=[]
for p in d['parts']:
 if p.get('lane'):
  q=dict(p);q['size']=[p['size'][0]+2,p['size'][1]+7,p['size'][2]+2];q['position']=[p['position'][0],p['position'][1]+3.5,p['position'][2]];lanes.append((p,box(q)))
def inspect(pos,size):
 a=box(dict(position=pos,size=size,rotation=[1,0,0,0,1,0,0,0,1]))
 hits=[physical[i][0]['name'] for i in np.where(np.all(np.minimum(a[4],hi)-np.maximum(a[3],lo)>.035,axis=1))[0] if penetrates(a,physical[i][1])]
 lane=[p['name'] for p,b in lanes if np.all(np.minimum(a[4],b[4])-np.maximum(a[3],b[3])>.035) and penetrates(a,b)]
 contacts=[p['name'] for p,b in physical if np.max(np.maximum(a[3]-b[4],b[3]-a[4]))<=.035]
 return dict(at=pos,size=size,hits=hits,lanes=lane,contact=contacts[:4])
for x in [-48,-42,28,36,52,64]:
 for z in [-15.7,15.7]:print(inspect([x,-10,z],[6,12,.6]))
for x in [-33.5,-32.6,-11.4,-10.5]:
 for z in [20,40,60,80]:print(inspect([x,-32+(z-18)*32/70+2,z],[.3,4,.5]))
