import json, numpy as np
from pathlib import Path
H=Path(__file__).resolve().parent
d=json.loads((H/'before.json').read_text())
parts=[p for p in d['parts'] if p['collidable']]
c=np.array([p['position'] for p in parts]);h=np.array([p['size'] for p in parts])/2;r=np.array([p['rotation'] for p in parts]).reshape(-1,3,3);ext=np.einsum('nij,nj->ni',abs(r),h)
def support(x,z,w,d):
    heights=[]
    for xx in (x-w/2,x,x+w/2):
      for zz in (z-d/2,z,z+d/2):
        q=np.einsum('nji,nj->ni',r,np.array([xx,0,zz])-c)
        valid=(abs(q[:,0])<=h[:,0]+.001)&(abs(q[:,2])<=h[:,2]+.001)&(c[:,1]+ext[:,1]<=1)&(c[:,1]+ext[:,1]>=-3)&(abs(r[:,1,1])>.9999)
        if not valid.any():return None
        heights.append(max((c+ext)[valid,1]))
    return max(heights) if max(heights)-min(heights)<.15 else None
lanes=[p for p in d['parts'] if p.get('lane')]
def clear(x,z,w,d,y=0,height=23):
    center=np.array([x,y+height/2,z]);half=np.array([w,height,d])/2
    hit=np.all(np.minimum(center+half,c+ext)-np.maximum(center-half,c-ext)>.035,axis=1)
    if hit.any():return False
    for p in lanes:
      rr=np.array(p['rotation']).reshape(3,3);hh=np.array(p['size'])/2
      q=rr.T@(center-np.array(p['position']));ee=abs(rr.T)@half
      if abs(q[0])<hh[0]+ee[0]+1 and abs(q[2])<hh[2]+ee[2]+1 and y< p['position'][1]+hh[1]+7 and y+height>p['position'][1]-hh[1]:return False
    return True
sites=[]
for x in range(-116,-41,2):
 for z in range(0,125,2):
  if x>=-58 and z>=98:continue
  y=support(x,z,5,5)
  if y is not None and clear(x,z,5,5,y):sites.append(dict(x=x,z=z,y=float(y)))
(H/'sites-fast.json').write_text(json.dumps(sites,indent=2))
print('sites',sites)
