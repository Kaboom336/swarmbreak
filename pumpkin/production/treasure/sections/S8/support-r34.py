"""Convex native wedge/box support graph, with .035 touching tolerance.
Water ribbons and mist are deliberately suspended effects, not loose rocks.
"""
from pathlib import Path
import json,sys,hashlib,numpy as np
H=Path(__file__).resolve().parent;tag=sys.argv[1]
data=json.loads((H/(tag+'.json')).read_text())['parts']
def convex(p):
 h=np.array(p['size'])/2;r=np.array(p['rotation']).reshape(3,3);c=np.array(p['position'])
 if p['shape']=='Wedge':
  vs=np.array([[-1,-1,-1],[1,-1,-1],[-1,-1,1],[1,-1,1],[-1,1,1],[1,1,1]])*h
  fs=[(0,2,3,1),(2,4,5,3),(0,1,5,4),(0,4,2),(1,3,5)]
 else:
  vs=np.array([[-1,-1,-1],[1,-1,-1],[1,1,-1],[-1,1,-1],[-1,-1,1],[1,-1,1],[1,1,1],[-1,1,1]])*h
  fs=[(0,1,2,3),(4,5,6,7),(0,4,5,1),(3,2,6,7),(0,3,7,4),(1,5,6,2)]
 vs=vs@r.T+c
 normals=[];edges=[]
 for f in fs:
  normals.append(np.cross(vs[f[1]]-vs[f[0]],vs[f[2]]-vs[f[0]]))
  edges.extend(vs[f[(i+1)%len(f)]]-vs[f[i]] for i in range(len(f)))
 def unique(items):
  out={}
  for v in items:
   length=np.linalg.norm(v)
   if length>1e-7:
    v=v/length
    if v[np.argmax(np.abs(v))]<0:v=-v
    out[tuple(np.round(v,5))]=v
  return list(out.values())
 return vs,unique(normals),unique(edges),vs.min(axis=0),vs.max(axis=0)
def joins(a,b):
 if np.any(np.minimum(a[4],b[4])-np.maximum(a[3],b[3])<-.035):return False
 for v in [*a[1],*b[1]]+[np.cross(x,y) for x in a[2] for y in b[2]]:
  length=np.linalg.norm(v)
  if length<1e-7:continue
  v=v/length;aa=a[0]@v;bb=b[0]@v
  if min(aa.max(),bb.max())-max(aa.min(),bb.min())<-.035:return False
 return True
added=[p for p in data if p.get('section')=='S8' and p['name'] not in ('S8_Waterfall','S8_Mist')]
retained=[p for p in data if p.get('section')!='S8' and p['transparency']<.99 and p['position'][1]<0]
A=[convex(p) for p in added];R=[convex(p) for p in retained]
lo=np.array([b[3] for b in R]);hi=np.array([b[4] for b in R]);direct=set();links={i:set() for i in range(len(A))}
for i,a in enumerate(A):
 for j in np.where(np.all(np.minimum(a[4],hi)-np.maximum(a[3],lo)>=-.035,axis=1))[0]:
  if joins(a,R[j]):direct.add(i);break
 for j in range(i):
  if joins(a,A[j]):links[i].add(j);links[j].add(i)
connected=set(direct);todo=list(direct)
while todo:
 for j in links[todo.pop()]-connected:connected.add(j);todo.append(j)
missing=[dict(name=p['name'],position=p['position']) for i,p in enumerate(added) if i not in connected]
def contains(p,v):
 q=np.array(p['rotation']).reshape(3,3).T@(v-np.array(p['position']));h=np.array(p['size'])/2
 return np.all(np.abs(q)<=h+.035) and (p['shape']!='Wedge' or q[1]/h[1]<=q[2]/h[2]+.001)
water=[]
for p in data:
 if p['name']!='S8_Waterfall':continue
 v=np.array(p['position'])+np.array([0,p['size'][1]/2,0])
 owners=[q['name'] for q in retained if contains(q,v)]
 water.append(dict(top=list(v),attached=bool(owners),owners=owners))
out=dict(state='PASS' if not missing and all(w['attached'] for w in water) else 'FAIL',manifest_sha256=hashlib.sha256((H/(tag+'.json')).read_bytes()).hexdigest(),directly_attached=len(direct),connected_parts=len(connected),unsupported=missing,water_source_joints=water,method='native convex wedge/box SAT graph; exact geometry, .035 join tolerance; cosmetic unions intentional; falling water/mist excluded from structural support, all ribbon tops anchored')
(H/('SUPPORT-'+tag+'.json')).write_text(json.dumps(out,indent=2));print(json.dumps(out));assert out['state']=='PASS'
