"""Occlusion-aware native-box probe; original scene identity, no art synthesis."""
import json, math, sys
from pathlib import Path
import numpy as np
H=Path(__file__).resolve().parent
prefix='r3' if len(sys.argv)>1 and sys.argv[1]=='r3' else 'r2'
d=json.loads((H/('r3-after.json' if prefix=='r3' else 'after.json')).read_text())
def key(p):return p['name']+'@'+','.join(f'{v:.3f}' for v in p['position'])
visible={}; samples={}
for name,eye,target in [('walk',(-35,7,130),(-68,5,92)),('mouth',(-53,6,115),(-69,6,86))]:
 eye=np.array(eye,float);f=np.array(target)-eye;f/=np.linalg.norm(f);r=np.cross(f,[0,1,0]);r/=np.linalg.norm(r);u=np.cross(r,f)
 xx,yy=np.meshgrid((np.arange(160)+.5)/160-.5,.5-(np.arange(90)+.5)/90)
 rays=f+xx.reshape(-1,1)*1.5*r+yy.reshape(-1,1)*1.5*720/1280*u
 near=np.full(len(rays),np.inf);ids=np.full(len(rays),-1)
 for i,p in enumerate(d['parts']):
  if p.get('transparency',0)>.95:continue
  c=np.array(p['position']);h=np.array(p['size'])/2;R=np.array(p['rotation']).reshape(3,3)
  delta=c-eye;dist=delta@f;rad=np.linalg.norm(h)
  if dist+rad<0 or abs(delta@r)>max(0,dist)*.75+rad*1.5 or abs(delta@u)>max(0,dist)*.422+rad*1.5:continue
  o=(eye-c)@R;v=rays@R
  with np.errstate(divide='ignore',invalid='ignore'):
   a=(-h-o)/v;b=(h-o)/v
  enter=np.maximum(np.min([a,b],axis=0).max(axis=1),0);leave=np.max([a,b],axis=0).min(axis=1)
  hit=(leave>=enter)&(enter<near);near[hit]=enter[hit];ids[hit]=i
 counts=np.bincount(ids[ids>=0],minlength=len(d['parts']))
 for i in np.where(counts>0)[0]:visible.setdefault(int(i),{})[name]=int(counts[i])
 samples[name]=[{'pixel':[x*8+4,y*8+4],'part':d['parts'][int(ids[y*160+x])]['name'],'point':(eye+rays[y*160+x]*near[y*160+x]).tolist()} for x,y in [(35,20),(53,37),(65,31),(106,43),(118,43),(137,37),(87,27),(75,46)]]
out=[dict(index=i,key=key(d['parts'][i]),views=v,part=d['parts'][i]) for i,v in visible.items()]
(H/(prefix+'-visible.json')).write_text(json.dumps(out,indent=2));(H/(prefix+'-rays.json')).write_text(json.dumps(samples,indent=2))
for a in sorted(out,key=lambda a:sum(a['views'].values()),reverse=True)[:45]:
 p=a['part'];print(a['views'],p['name'],[round(x,2) for x in p['position']],p['size'],p['collidable'],p.get('lane'))
