import json,numpy as np
from pathlib import Path
H=Path(__file__).resolve().parent
d=json.loads((H/'r3.json').read_text());eye=np.array([110,7,-18]);f=np.array([0,12,69]);f=f/np.linalg.norm(f);right=np.cross(f,[0,1,0]);right=right/np.linalg.norm(right);up=np.cross(right,f)
visible={}
for u in np.linspace(-.9,-.25,8):
 for v in np.linspace(-.4,.7,9):
  direction=f+right*u*.75+up*v*.422;hits=[]
  for p in d['parts']:
   if p['transparency']>.9:continue
   rot=np.array(p['rotation']).reshape(3,3);o=rot.T@(eye-p['position']);ray=rot.T@direction;h=np.array(p['size'])/2
   with np.errstate(divide='ignore',invalid='ignore'):a=(-h-o)/ray;b=(h-o)/ray
   start=max(np.minimum(a,b));end=min(np.maximum(a,b))
   if end>=max(start,0):hits.append((max(start,0),p))
  if hits:
   p=min(hits,key=lambda x:x[0])[1]
   if 'Rock' in p['name'] or 'Shelf' in p['name']:
    visible[tuple(p['position'])]=p
for p in visible.values():print(p['name'],p['position'],p['size'],p['collidable'])
(H/'VISIBLE-R3.json').write_text(json.dumps(list(visible.values()),indent=2))
