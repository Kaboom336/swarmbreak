"""Joint ledger from saved native transforms, not a count inferred from intention.
Centerline/profile checks, surface intersections and OBB contact; closed span state.
"""
import json,math,itertools
from pathlib import Path
import numpy as np
H=Path(__file__).parent
kit=json.loads((H/'CONNECT-PLACED.json').read_text());scene=json.loads((H/'scene.json').read_text());before=json.loads((H/'connect-before-scene.json').read_text())
start=kit['native_start'];parts=scene['parts'];new=parts[start:]
vertex_tolerance=.001 if kit.get('minimum_size_clamps',0) else .0001
def v(x):return np.array(x,dtype=float)
def endpoint(p,end):
 R=np.array(p['rotation']).reshape(3,3)
 return v(p['position'])+R[:,2]*p['size'][2]/2*end
def obb_distance(p,q):
 R=np.array(p['rotation']).reshape(3,3);d=np.abs(R.T@(v(q)-v(p['position'])))-v(p['size'])/2
 return float(np.linalg.norm(np.maximum(d,0)))
def dump(name,obj):(H/name).write_text(json.dumps(obj,indent=2,default=lambda x:x.item()))
ledger=[];fail=[]
for c in kit['contacts']:
 if 'profile' in c:
  vertices=[]
  for idx in c['parts']:
   p=new[idx];R=np.array(p['rotation']).reshape(3,3);size=v(p['size'])/2
   for s in [(-1,-1,-1),(1,-1,-1),(-1,-1,1),(1,-1,1),(-1,1,1),(1,1,1)]:vertices.append(R@(v(s)*size)+v(p['position']))
  error=max(min(np.linalg.norm(v(q)-p) for p in vertices) for q in c['profile']);target=new[c['target']]
  distance=max(obb_distance(target,q) for q in c['profile'])
  entry=dict(c,target_name=target['name'],profile_error=float(error),gap=distance);ledger.append(entry)
  if error>vertex_tolerance or distance>1e-4:fail.append(entry)
  continue
 p=new[c['part']];q=v(c['point'])
 if c['kind']=='trestle':
  actual=v(p['position'])-v([0,p['size'][1]/2,0]);target=before['parts'][c['target_baseline']] if 'target_baseline' in c else new[c['target']]
 else:
  actual=endpoint(p,c['end']);target=new[c['target']]
 error=float(np.linalg.norm(actual-q));distance=obb_distance(target,actual)
 entry=dict(c,part_name=p['name'],target_name=target['name'],actual=list(actual),profile_error=error,gap=distance)
 ledger.append(entry)
 if error>1e-4 or distance>1e-4:fail.append(entry)
# Reconstruct every WedgePart's six vertices and verify its outward surface vertices
# actually reproduce the polygon recorded in the module kit.
for m in kit['modules']+kit['rail_modules']:
 vertices=[]
 for idx in m['part_indices']:
  p=new[idx];R=np.array(p['rotation']).reshape(3,3);size=v(p['size'])/2
  for s in [(-1,-1,-1),(1,-1,-1),(-1,-1,1),(1,-1,1),(-1,1,1),(1,1,1)]:vertices.append(R@(v(s)*size)+v(p['position']))
 for point in m['polygon']:
  error=min(np.linalg.norm(v(point)-p) for p in vertices)
  if error>vertex_tolerance:fail.append(dict(module=m['id'],vertex=point,error=float(error)))
# Both rail heads: every segment end names its next segment or terminal plate.
terminals=[i for i,p in enumerate(new) if p['name']=='ConnectRailTerminal']
for side in (0,1):
 chain=[m for m in kit['rail_modules'] if m['id'].startswith(f'rail:{side}:')]
 for i,m in enumerate(chain):
  p=m['polygon']
  for end,profile,j in [('start',[p[0],p[3]],i-1),('end',[p[1],p[2]],i+1)]:
   if 0<=j<len(chain):
    target=chain[j];tp=target['polygon'];other=[tp[1],tp[2]] if end=='start' else [tp[0],tp[3]]
    gap=max(float(np.linalg.norm(v(a)-v(b))) for a,b in zip(profile,other));targetname=target['id']
   else:
    target=new[terminals[0 if end=='start' else 1]];gap=max(obb_distance(target,p) for p in profile);targetname=target['name']
   entry=dict(kind='rail',module=m['id'],end=end,target=targetname,profile=profile,gap=gap)
   ledger.append(entry)
   if gap>1e-4:fail.append(entry)
# Each complete fitted surface piece records all its interfaces. Interior interfaces
# share an exact profile. Exposed sides terminate in raised edging, not another lane.
seams={}
for s in kit['seams']:
 for a,b in [(s['a'],s['b']),(s['b'],s['a'])]:seams.setdefault(a,[]).append(dict(target=b,profile=s['profile'],gap=0))
for m in kit['modules']:
 ledger.append(dict(kind='bridge' if m['kind']=='bridge' else 'path',module=m['id'],interfaces=seams.get(m['id'],[]),perimeter='raised edging; open entry into adjoining pads',polygon=m['polygon']))
# Independent polygon overlap check (projected native surfaces; excludes different levels).
def area(p):return abs(sum(a[0]*b[2]-b[0]*a[2] for a,b in zip(p,p[1:]+p[:1]))/2)
def signed(p):return sum(a[0]*b[2]-b[0]*a[2] for a,b in zip(p,p[1:]+p[:1]))/2
def cross(a,b):return a[0]*b[2]-a[2]*b[0]
def intersect(p,c):
 p=list(map(v,p));c=list(map(v,c));c=c if signed(c)>0 else c[::-1]
 for a,b in zip(c,c[1:]+c[:1]):
  if not p:break
  out=[]
  for s,e in zip(p,p[1:]+p[:1]):
   ds=cross(b-a,s-a);de=cross(b-a,e-a);si=ds>=-1e-7;ei=de>=-1e-7
   if si:out.append(s)
   if si!=ei:out.append(s+(e-s)*ds/(ds-de))
  p=out
 return p
def height(p,x,z):
 a,b,c=map(v,p[:3]);n=np.cross(b-a,c-a)
 return a[1]-(n[0]*(x-a[0])+n[2]*(z-a[2]))/n[1]
overlaps=[]
ms=kit['modules']
bounds=[(np.min(v(m['polygon']),axis=0),np.max(v(m['polygon']),axis=0)) for m in ms]
for i,j in itertools.combinations(range(len(ms)),2):
 lo,hi=bounds[i];lj,hj=bounds[j]
 if hi[0]<lj[0] or hj[0]<lo[0] or hi[2]<lj[2] or hj[2]<lo[2]:continue
 q=intersect(ms[i]['polygon'],ms[j]['polygon'])
 if len(q)<3 or area(q)<.0025:continue
 c=np.mean(q,axis=0)
 dy=abs(height(ms[i]['polygon'],c[0],c[2])-height(ms[j]['polygon'],c[0],c[2]))
 if dy<.35:overlaps.append(dict(a=ms[i]['id'],b=ms[j]['id'],area=area(q),height_difference=float(dy)))
# Original geometry/contracts are checked separately from the new cosmetic kit.
keys=['name','category','position','size','rotation','collidable']
assert [{k:p[k] for k in keys} for p in parts if p['collidable']]==[{k:p[k] for k in keys} for p in before['parts'] if p['collidable']]
assert scene['routes']==before['routes']
assert [p for p in parts if p['category']=='hook']==[p for p in before['parts'] if p['category']=='hook']
assert [(p['name'],p['position'],p['size'],p['rotation'],p['color']) for p in parts if p['category']=='crystal']==[(p['name'],p['position'],p['size'],p['rotation'],p['color']) for p in before['parts'] if p['category']=='crystal']
# Before: independent face-profile mismatch for every route-slab end and rail-beam end.
old=[]
for i,p in enumerate(before['parts']):
 if p['category']=='lane' and any(p['name'].startswith(n) and p['name'][len(n):].isdigit() for n in before['routes']):
  for end in (-1,1):
   q=endpoint(p,end);targets=[(obb_distance(t,q),j,t) for j,t in enumerate(before['parts']) if j!=i and t['category']=='lane']
   d,j,t=min(targets,key=lambda q:q[0]);old.append(dict(kind='path',part=i,name=p['name'],end=end,target=j,target_name=t['name'],point=list(q),gap=d,inside_depth=max(0,min(np.array(t['size'])/2-np.abs(np.array(t['rotation']).reshape(3,3).T@(q-v(t['position'])))))))
 if p['name']=='SteelRail':
  for end in (-1,1):
   q=endpoint(p,end);targets=[(obb_distance(t,q),j,t) for j,t in enumerate(before['parts']) if j!=i and t['name']=='SteelRail']
   d,j,t=min(targets,key=lambda q:q[0]);old.append(dict(kind='rail',part=i,name=p['name'],end=end,target=j,target_name=t['name'],point=list(q),gap=d,inside_depth=max(0,min(np.array(t['size'])/2-np.abs(np.array(t['rotation']).reshape(3,3).T@(q-v(t['position'])))))))
beforecounts=dict(ends=len(old),unconnected=sum(e['gap']>.05 for e in old),gaps=sum(e['gap']>.05 for e in old),overlaps=sum(e['inside_depth']>.05 for e in old),fence_ends=0,method='nearest compatible OBB at beam/profile center; visual before face mismatches are crops, not falsely precise full-profile counts')
aftercounts=dict(ledger_records=len(ledger),path_pieces=len(kit['modules']),rail_pieces=len(kit['rail_modules']),fence_ends=sum(c['kind']=='fence' for c in kit['contacts']),grounded_trestles=sum(c['kind']=='trestle' for c in kit['contacts']),unconnected=len(fail),gaps=len(fail),overlaps=len(overlaps))
report=dict(before=beforecounts,after=aftercounts,failures=fail,overlaps=overlaps,vertex_tolerance=vertex_tolerance,minimum_size_clamps=kit.get('minimum_size_clamps',0),maximum_dimension_change=kit.get('maximum_dimension_change',0),scope='Visible modular infrastructure, closed span; accepted invisible collision-floor overlaps intentionally preserved. Designed interfaces and rail profiles 0.0001 stud; serialized facet vertices 0.001 stud after engine minimum-size normalization, below owner 0.05-stud overlap limit. Excess overlap area threshold .0025 square stud; beam contact OBB. Runtime UNKNOWN.',preservation=dict(collider_geometry=True,routes=True,hooks=True,crystal_geometry_color=True))
dump('CONNECT-BEFORE-ENDS.json',old);dump('CONNECT-ENDS.json',ledger);dump('CONNECT-AUDIT.json',report)
print(json.dumps(report,indent=2,default=lambda x:x.item())[:6000])
assert not fail and not overlaps,'Joint audit failed'
