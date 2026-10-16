import json,numpy as np
from pathlib import Path
H=Path(__file__).resolve().parent
ns={'np':np};s=(H.parent/'S2/contact.py').read_text();exec(s[s.index('def box('):s.index('physical=[')],ns)
box,penetrates=ns['box'],ns['penetrates'];d=json.loads((H/'r3.json').read_text())
physical=[(p,box(p)) for p in d['parts'] if p['collidable']]
lanes=[]
for p in d['parts']:
 if p.get('lane'):
  q=dict(p);q['size']=[p['size'][0]+2,p['size'][1]+7,p['size'][2]+2];q['position']=[p['position'][0],p['position'][1]+3.5,p['position'][2]];lanes.append((p,box(q)))
def probe(pos,size):
 a=box(dict(position=pos,size=size,rotation=[1,0,0,0,1,0,0,0,1]))
 hits=lambda items:[p['name'] for p,b in items if np.all(np.minimum(a[4],b[4])-np.maximum(a[3],b[3])>.035) and penetrates(a,b)]
 print(pos,size,'physical',hits(physical),'lanes',hits(lanes))
for x in (73,76,79):probe([x,-28,0],[.16,7,1.5]);probe([x,-33,3],[2,1,1.5])
for z in (-17,17):probe([0,4.4,z],[17,.12,.8]);probe([12.8,4.7,z],[1.5,.7,1.5])
for x in (73,76,79):
 print('floor',x,[(p['name'],round(b[4][1],3)) for p,b in physical if b[3][0]<=x<=b[4][0] and b[3][2]<=0<=b[4][2] and b[4][1]<0][-6:])
