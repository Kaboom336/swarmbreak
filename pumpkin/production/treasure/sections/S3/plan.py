"""Find timber faces outside full lane margins, against exact retained OBBs."""
import json,sys,math
from pathlib import Path
import numpy as np
H=Path(__file__).resolve().parent
src=(H.parent/'S2/contact.py').read_text()
scope={'np':np};exec(src[src.index('def box('):src.index('physical=[')],scope)
box,penetrates=scope['box'],scope['penetrates']
d=json.loads((H/'before.json').read_text());physical=[(p,box(p)) for p in d['parts'] if p['collidable']]
lo=np.array([b[3] for p,b in physical]);hi=np.array([b[4] for p,b in physical])
identity=[1,0,0,0,1,0,0,0,1]
def safe(pos,size):
 p=dict(position=pos,size=size,rotation=identity);a=box(p)
 for i in np.where(np.all(np.minimum(a[4],hi)-np.maximum(a[3],lo)>.035,axis=1))[0]:
  if penetrates(a,physical[i][1]):return False
 return True
for z in range(-16,74,11):
 print('station',z)
 for x in (-84.6,-84.3,-84,-83.7,-68.3,-68,-67.7,-67.4):
  print(x,'floor-post',safe([x,12.2,z],[.5,24,1]),'upper-post',safe([x,17,z],[.5,14,1]))
 print('header',safe([-76,24.6,z],[16,1.2,1.2]))
a=box(dict(position=[-84.3,12.2,28],size=[.5,24,1],rotation=identity))
print('BLOCKERS',[(physical[i][0]['name'],physical[i][0]['position']) for i in np.where(np.all(np.minimum(a[4],hi)-np.maximum(a[3],lo)>.035,axis=1))[0] if penetrates(a,physical[i][1])])
