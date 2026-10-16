import json,numpy as np
from pathlib import Path
H=Path(__file__).resolve().parent
d=json.loads((H/'r4-after.json').read_text())
parts=[p for p in d['parts'] if p.get('transparency',0)<.99]
c=np.array([p['position'] for p in parts]);h=np.array([p['size'] for p in parts])/2;r=np.array([p['rotation'] for p in parts]).reshape(-1,3,3)
eye=np.array([-35,7,130.]);f=np.array([-68,5,92])-eye;f/=np.linalg.norm(f);right=np.cross(f,[0,1,0]);right/=np.linalg.norm(right);up=np.cross(right,f)
o=np.einsum('nji,nj->ni',r,eye-c)
for px,py in [(300,10),(500,10),(700,10),(900,10),(1100,10),(300,80),(500,80),(700,80),(900,80),(1100,80),(500,160)]:
 ray=f+right*((px/1280-.5)*1.5)+up*((.5-py/720)*1.5*720/1280)
 v=np.einsum('nji,j->ni',r,ray);v=np.where(abs(v)<1e-9,1e-9,v)
 a=(-h-o)/v;b=(h-o)/v;en=np.minimum(a,b).max(1);ex=np.maximum(a,b).min(1);en=np.where((ex>=np.maximum(en,0)),np.maximum(en,0),np.inf)
 i=en.argmin();p=parts[i];print(px,py,p['name'],p['position'],p['size'])
