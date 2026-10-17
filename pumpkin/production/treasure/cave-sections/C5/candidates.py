"""Select contact-free envelopes from the native-bearing/lane-filtered pockets."""
import sys,json,math
from pathlib import Path
H=Path(__file__).resolve().parent
sys.argv=[__file__,'before']
scope={'__file__':str(H/'contact.py')}
exec((H/'contact.py').read_text().split('errors=[dict')[0],scope)
np=scope['np'];old=scope['old']
centers=np.array([p['position']for p in old]);extents=np.array([np.abs(scope['obb'](p)[2])@scope['obb'](p)[1]for p in old])
out=[]
for x,y,z in json.loads((H/'POCKETS.json').read_text()):
 if not(45<=x<=230 and -100<=z<=100):continue
 for height in [24,20,16,12,8,4]:
  p=dict(name='candidate',position=[x,y+height/2,z],size=[6,height,6],rotation=[1,0,0,0,1,0,0,0,1])
  c,h,r=scope['obb'](p);indices=np.flatnonzero(np.all(np.abs(centers-c)<=extents+h-.035,axis=1))
  if not any(scope['penetration'](p,old[i])for i in indices):
   out.append([x,y,z,height]);break
(H/'CANDIDATES.json').write_text(json.dumps(out,indent=2));print(out)
