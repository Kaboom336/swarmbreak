"""Ray-probe actual player frames for attached off-lane wall lamp pockets."""
import json,numpy as np
from pathlib import Path
H=Path(__file__).resolve().parent
d=json.loads((H/'r1.json').read_text());views=json.loads((H/'CAMERAS.json').read_text())
ps=[p for p in d['parts'] if p['collidable']]
centers=np.array([p['position'] for p in ps]);half=np.array([p['size'] for p in ps])/2
rot=np.array([p['rotation'] for p in ps]).reshape(-1,3,3)
lane=[p for p in d['parts'] if p.get('lane')]
def ray(eye,direction):
 o=np.einsum('nji,nj->ni',rot,eye-centers);v=np.einsum('nji,j->ni',rot,direction)
 v=np.where(abs(v)<1e-8,1e-8,v);a=(-half-o)/v;b=(half-o)/v
 t0=np.minimum(a,b).max(axis=1);t1=np.maximum(a,b).min(axis=1)
 t=np.where((t0>0)&(t1>=t0),t0,np.inf);i=int(t.argmin())
 if not np.isfinite(t[i]):return None
 local=o[i]+t[i]*v[i];axis=int(np.abs(np.abs(local)-half[i]).argmin());normal=rot[i,:,axis]*np.sign(local[axis])
 return ps[i],eye+direction*t[i],normal,t[i]
def margin(c,s):
 for p in lane:
  r=np.array(p['rotation']).reshape(3,3);v=r.T@(c-np.array(p['position']));h=np.array(p['size'])/2+[1,100,1]
  ext=np.abs(r.T)@(np.array(s)/2)
  if abs(v[0])<h[0]+ext[0] and abs(v[2])<h[2]+ext[2]:return False
 return True
out=[]
for view in views[:3]:
 eye=np.array(view['eye'],dtype=float);f=np.array(view['target'],dtype=float)-eye;f/=np.linalg.norm(f);right=np.cross(f,[0,1,0]);right/=np.linalg.norm(right);up=np.cross(right,f)
 found=[]
 for sx in np.linspace(-.85,.85,15):
  for sy in [.5,.25,0,-.25]:
   direction=f+right*sx*.75+up*sy*.75*540/960;direction/=np.linalg.norm(direction)
   hit=ray(eye,direction)
   if not hit:continue
   p,point,n,dist=hit
   if p['name']!='SolidMountainStone' or abs(n[1])>.05 or not(8<dist<55):continue
   c=point+n*.7
   if not(-64<c[0]<124 and -157<c[2]<-36 and 3<c[1]<49):continue
   if -34<c[0]<34 and -134<c[2]<-70:continue
   if not margin(c,[1.8,2.5,1.8]):continue
   if any(np.linalg.norm(c-np.array(x['point']))<8 for x in found):continue
   found.append(dict(view=view['name'],point=point.tolist(),normal=n.tolist(),distance=float(dist),solid=p['position']))
 print(view['name'],json.dumps(found[:8],indent=2));out.extend(found[:8])
(H/'MOUNTS.json').write_text(json.dumps(out,indent=2))
