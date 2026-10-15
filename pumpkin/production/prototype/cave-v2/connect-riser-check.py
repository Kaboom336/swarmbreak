"""Additional actual-end audit for the step risers, including surface connectivity."""
import json,itertools
from pathlib import Path
import numpy as np
H=Path(__file__).parent;kit=json.loads((H/'CONNECT-PLACED.json').read_text());scene=json.loads((H/'scene.json').read_text());parts=scene['parts'][kit['native_start']:];modules=kit['modules']
nodes={m['id']:set() for m in modules}
for s in kit['seams']:nodes[s['a']].add(s['b']);nodes[s['b']].add(s['a'])
edges=[]
for m in modules:
 p=list(map(lambda q:np.array(q),m['polygon']))
 for a,b in zip(p,p[1:]+p[:1]):edges.append((m['id'],a,b))
def matches(a,b):
 length=np.linalg.norm(b-a);axis=(b-a)/length;found=[]
 for ident,c,d in edges:
  if max(a[0],b[0])+1e-4<min(c[0],d[0]) or max(c[0],d[0])+1e-4<min(a[0],b[0]) or max(a[2],b[2])+1e-4<min(c[2],d[2]) or max(c[2],d[2])+1e-4<min(a[2],b[2]):continue
  if max(np.linalg.norm(np.cross(c-a,axis)),np.linalg.norm(np.cross(d-a,axis)))>1e-4:continue
  low,high=sorted([np.dot(c-a,axis),np.dot(d-a,axis)]);low=max(0,low);high=min(length,high)
  if high-low>1e-5:found.append((float(low),float(high),ident))
 covered=0.
 for low,high,_ in sorted(found):
  if low>covered+1e-4:break
  covered=max(covered,high)
 return found,float(length-covered)
ends=[];fail=[]
for i,p in enumerate(parts):
 if p['name']!='ConnectStoneStepRiser':continue
 R=np.array(p['rotation']).reshape(3,3);c=np.array(p['position']);groups=[]
 for sign in (-1,1):
  q=c+R[:,1]*p['size'][1]/2*sign;a=q-R[:,2]*p['size'][2]/2;b=q+R[:,2]*p['size'][2]/2
  found,gap=matches(a,b);groups.extend(ident for _,_,ident in found)
  row=dict(part=i,end='bottom' if sign==-1 else 'top',profile=[list(a),list(b)],targets=[ident for _,_,ident in found],unmatched_length=gap);ends.append(row)
  if gap>1e-4:fail.append(row)
 for a,b in itertools.combinations(set(groups),2):nodes[a].add(b);nodes[b].add(a)
seen=set();components=[]
for ident in nodes:
 if ident in seen:continue
 group=[];queue=[ident];seen.add(ident)
 while queue:
  a=queue.pop();group.append(a)
  for b in nodes[a]:
   if b not in seen:seen.add(b);queue.append(b)
 components.append(group)
# A branch can terminate flush inside a larger native deck face (a T joint),
# rather than at one of that face's tessellation edges. Check the whole contact
# interval analytically with barycentric coordinates, never just center distance.
face_contacts=[];lookup={m['id']:m for m in modules}
largest=max(components,key=len);candidate_ids=[ident for group in components if group is not largest for ident in group]
for ident in candidate_ids:
 p=list(map(np.array,lookup[ident]['polygon']))
 for a,b in zip(p,p[1:]+p[:1]):
  if np.linalg.norm(b-a)<1e-5:continue
  for other in modules:
   if other['id']==ident or other['id'] in nodes[ident]:continue
   x,y,z=map(np.array,other['polygon'])
   if max(a[0],b[0])+1e-4<min(x[0],y[0],z[0]) or max(x[0],y[0],z[0])+1e-4<min(a[0],b[0]) or max(a[2],b[2])+1e-4<min(x[2],y[2],z[2]) or max(x[2],y[2],z[2])+1e-4<min(a[2],b[2]):continue
   M=np.column_stack([(y-x)[[0,2]],(z-x)[[0,2]]])
   try:uv0=np.linalg.solve(M,(a-x)[[0,2]]);uv1=np.linalg.solve(M,(b-x)[[0,2]])
   except np.linalg.LinAlgError:continue
   lo,hi=0.,1.
   for s,e in zip([uv0[0],uv0[1],1-sum(uv0)],[uv1[0],uv1[1],1-sum(uv1)]):
    delta=e-s
    if abs(delta)<1e-10:
     if s< -1e-5:hi=-1;break
    elif delta>0:lo=max(lo,-s/delta)
    else:hi=min(hi,-s/delta)
   if hi-lo<1e-5:continue
   error=0
   for t in (lo,(lo+hi)/2,hi):
    uv=uv0+(uv1-uv0)*t;pred=x[1]+uv[0]*(y[1]-x[1])+uv[1]*(z[1]-x[1]);actual=a[1]+(b[1]-a[1])*t;error=max(error,abs(pred-actual))
   if error>1e-4:continue
   nodes[ident].add(other['id']);nodes[other['id']].add(ident)
   face_contacts.append(dict(kind='path-face',module=ident,target=other['id'],profile=[list(a+(b-a)*lo),list(a+(b-a)*hi)],gap=float(error)))
seen=set();components=[]
for ident in nodes:
 if ident in seen:continue
 queue=[ident];seen.add(ident);group=[]
 while queue:
  a=queue.pop();group.append(a)
  for b in nodes[a]:
   if b not in seen:seen.add(b);queue.append(b)
 components.append(group)
landing=next(p for p in scene['parts'] if p['name']=='BroadLanding');lc=np.array(landing['position']);lh=np.array(landing['size'])/2
landing_sleepers=[]
for i,p in enumerate(parts):
 if p['name']!='ConnectRailSleeper':continue
 R=np.array(p['rotation']).reshape(3,3);bounds=np.abs(R)@ (np.array(p['size'])/2)
 if all(abs(np.array(p['position'])-lc)<=bounds+lh+1e-4):landing_sleepers.append(i)
main_components=[c for c in components if not all(n.startswith('BroadLanding:') for n in c)]
report=dict(riser_ends=len(ends),failed_riser_ends=len(fail),failures=fail,surface_components=len(components),main_navigation_components=len(main_components),cart_landing_connected_to_track=bool(landing_sleepers),landing_sleepers=landing_sleepers,component_sizes=[len(c) for c in components],small_components=[c for c in components if len(c)<10],face_contacts=face_contacts,ends=ends)
(H/'CONNECT-RISERS.json').write_text(json.dumps(report,indent=2));print(json.dumps({k:v for k,v in report.items() if k not in ('ends','failures')},indent=2));print(json.dumps(fail[:4],indent=2))
assert not fail and len(main_components)==1 and landing_sleepers,'Step or landing connection failed'
