import json, numpy as np
from pathlib import Path
d=json.loads((Path(__file__).parent/'r2.json').read_text())
floors=[p for p in d['parts'] if p['collidable'] and abs(p['rotation'][4]-1)<.0001 and -3<=p['position'][1]+p['size'][1]/2<=1]
lanes=[p for p in d['parts'] if p.get('lane') and p['name'] not in ('PortalPad','ProtectedPortalApron')]
lc=np.array([p['position'] for p in lanes]);lr=np.array([p['rotation'] for p in lanes]).reshape(-1,3,3);lh=np.array([p['size'] for p in lanes])/2
def clear(x,z,w,h,depth):
 c=np.array([x,h/2,z]);delta=np.einsum('nji,nj->ni',lr,c-lc);ext=np.einsum('nji,j->ni',np.abs(lr),[w/2,h/2,depth/2])
 return not np.any((np.abs(delta[:,0])<=ext[:,0]+lh[:,0]+1)&(np.abs(delta[:,2])<=ext[:,2]+lh[:,2]+1))
def ground(x,z,w,depth):
 xx,zz=np.meshgrid(np.linspace(x-w/2,x+w/2,int(np.ceil(w))+1),np.linspace(z-depth/2,z+depth/2,int(np.ceil(depth))+1))
 tops=np.full(xx.shape,-np.inf)
 for p in floors:
  if abs(p['position'][0]-x)>p['size'][0]/2+w/2+2 or abs(p['position'][2]-z)>p['size'][2]/2+depth/2+2:continue
  r=np.array(p['rotation']).reshape(3,3);dx=xx-p['position'][0];dz=zz-p['position'][2]
  mask=(np.abs(dx*r[0,0]+dz*r[2,0])<=p['size'][0]/2+.001)&(np.abs(dx*r[0,2]+dz*r[2,2])<=p['size'][2]/2+.001)
  tops[mask]=np.maximum(tops[mask],p['position'][1]+p['size'][1]/2)
 return float(tops.max()) if np.isfinite(tops).all() and tops.max()-tops.min()<=.15 else None
if __name__=='__main__':
 for w,h,depth in [(8,5,3),(7,24,7),(6,6,6),(3.5,4,3.5),(.6,8,.6),(4,5,8)]:
  for side in [-1,1]:
   sites=[]
   for ax in np.arange(16+w/2+.02,45,1):
    x=side*ax
    for z in range(116,156):
     if not clear(x,z,w,h,depth):continue
     y=ground(x,z,w,depth)
     if y is not None:sites.append((round((x*x+(154-z)**2)**.5,2),round(x,2),z,y))
   print(w,h,depth,side,sorted(sites)[:8],flush=True)
