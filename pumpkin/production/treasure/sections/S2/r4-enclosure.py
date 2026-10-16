"""Convex native geometry, 50 deterministic seeds. No engine visibility claims."""
import json,math,re,numpy as np
from pathlib import Path
H=Path(__file__).resolve().parent
def geometry(file):
 p=[p for p in json.loads((H/file).read_text())['parts'] if p['collidable'] and p['query']]
 return np.array([q['position'] for q in p]),np.array([q['rotation'] for q in p]).reshape(-1,3,3),np.array([q['size'] for q in p])/2,np.array([q['shape']=='Wedge' for q in p])
a=geometry('r4-before.json');b=geometry('r4-after.json')
def hit(g,start,end):
 c,r,h,w=g;start=np.array(start);v=np.einsum('nji,j->ni',r,np.array(end)-start);o=np.einsum('nji,nj->ni',r,start-c)
 vv=np.where(abs(v)<1e-10,1e-10,v);u=(-h-o)/vv;t=(h-o)/vv
 en=np.minimum(u,t).max(1);ex=np.maximum(u,t).min(1)
 # Wedge top clips the oriented box by y/hY-z/hZ <= 0.
 rate=v[:,1]/h[:,1]-v[:,2]/h[:,2];dist=-(o[:,1]/h[:,1]-o[:,2]/h[:,2]);q=dist/np.where(abs(rate)<1e-10,1e-10,rate)
 en=np.where(w&(rate<0),np.maximum(en,q),en);ex=np.where(w&(rate>0),np.minimum(ex,q),ex)
 valid=(ex>=np.maximum(en,0))&(en<.999)&(ex>1e-5)&~(w&(abs(rate)<1e-10)&(dist<0))
 return bool(valid.any())
policy=(H.parents[2]/'prototype/meadow-v4/TunnelPolicy.luau').read_text()
surface=policy.split('P.Surface={')[1].split('}\nlocal function')[0]
keepers=[tuple(map(float,t)) for t in re.findall(r'x=([-\d.]+),y=([-\d.]+),z=([-\d.]+)',surface)]
fail=[];rays=0;roof=0;baseline_roof_misses=0
for seed in range(50):
 rng=np.random.default_rng(seed)
 for i in range(9):
  z=-20+i*12
  x=-76 if z<=54 else -76+(z-54)*16/28
  x+=rng.uniform(-2,2);z+=rng.uniform(-1,1)
  target=(x,3,z)
  # Interior beyond the original diagonal mouth; approach is deliberately open.
  if z>93.5-(x+63.95)*11/22.5-3:continue
  roof+=1
  old_roof=hit(a,target,(x,80,z));new_roof=hit(b,target,(x,80,z))
  if not old_roof:baseline_roof_misses+=1
  if old_roof and not new_roof:fail.append({'seed':seed,'new_roof_hole':target})
  for keeper in keepers:
   rays+=1
   if hit(a,keeper,target) and not hit(b,keeper,target):fail.append({'seed':seed,'new_sightline':target,'from':keeper})
out={'seeds':50,'keeper_segments_compared':rays,'interior_upward_closure_rays':roof,'baseline_upward_misses_unchanged':baseline_roof_misses,'failures':fail,
 'definition':'Exact convex box/wedge segment intersections on collidable/query geometry; policy Surface points at Y3 to jittered tunnel interior at Y3; upward closure behind existing mouth plane. No simulation of Humanoid/navmesh or real rendered line of sight.',
 'runtime_Keeper_visibility_climbing':'UNKNOWN'}
(H/'r4-ENCLOSURE.json').write_text(json.dumps(out,indent=2));print(json.dumps(out,indent=2));assert not fail
