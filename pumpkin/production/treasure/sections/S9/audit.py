from pathlib import Path
from collections import Counter
import json,sys,numpy as np
H=Path(__file__).resolve().parent;tag=sys.argv[sys.argv.index('--')+1]
old=json.loads((H/'before.json').read_text());new=json.loads((H/(tag+'.json')).read_text())
enc=lambda p:json.dumps(p,sort_keys=True)
baseline=Counter(map(enc,old['parts']));kept=Counter(enc(p) for p in new['parts'] if p.get('section')!='S9')
assert baseline==kept,'original home parts changed'
added=[p for p in new['parts'] if p.get('section')=='S9']
assert all(not(p['collidable']or p['query']or p['touch']or p['tags'])for p in added)
def box(p):
 c=np.array(p['position']);r=np.array(p['rotation']).reshape(3,3);h=np.array(p['size'])/2;e=np.abs(r)@h
 return c,r,h,c-e,c+e
def hit(a,b,tol=.035):
 ca,ra,ha,*_=a;cb,rb,hb,*_=b
 for axis in [*ra.T,*rb.T]+[np.cross(x,y)for x in ra.T for y in rb.T]:
  n=np.linalg.norm(axis)
  if n<1e-6:continue
  v=axis/n
  if np.sum(np.abs(v@ra)*ha)+np.sum(np.abs(v@rb)*hb)-abs(v@(cb-ca))<=tol:return False
 return True
physical=[(p,box(p))for p in old['parts']if p['collidable']or p['query']]
errors=[];margins=[];bounds=[];placement=[]
for p in added:
 a=box(p);c,r,h,lo,hi=a
 if np.any(lo<[-176,-30,-110])or np.any(hi>[176,65,135]):bounds.append(p['name'])
 # Central path is 40 studs wide. New cosmetics must clear its full-height x reserve.
 if lo[0]<21 and hi[0]>-21:margins.append(p['name'])
 for q,b in physical:
  if np.all(np.minimum(hi,b[4])-np.maximum(lo,b[3])>.035)and hit(a,b):errors.append([p['name'],q['name']])
 # All posts/garden details stay outside possible legal pet extents +/-28,+/-20.
 if 'Foundation' not in p['name']:
  for plot in old['bounds']:
   x,y,z=plot['center']
   if min(hi[0],x+28)>max(lo[0],x-28)+.035 and min(hi[2],z+20)>max(lo[2],z-20)+.035:placement.append([p['name'],plot['slot']])
lights=[q for q in new['lights']if q not in old['lights']]
assert all(q['brightness']<=1.5 and q['range']<=18 and not q['shadows']for q in lights)
frozen=True
if tag=='r2':
 r1=json.loads((H/'r1.json').read_text())
 def geom(p):
  p=dict(p)
  for k in ('label','labelFace','labelSize'):p.pop(k,None)
  p['attributes']=dict(p['attributes'])
  for k in ('RouteLabel','LabelFace','LabelSize'):p['attributes'].pop(k,None)
  return enc(p)
 # Round 2 may add lettering; all R1 native form/material fields are frozen.
 frozen=not(Counter(geom(p)for p in r1['parts']if p.get('section')=='S9')-Counter(geom(p)for p in added))
report=dict(original_home_exact=True,new_parts=len(added),contact_errors=errors,lane_margin_errors=margins,bounds_errors=bounds,placement_errors=placement,frozen_r1=frozen,new_lights=len(lights),tolerance=.035)
if tag=='r2':
 before_visual=json.loads((H/'before-visual.json').read_text())
 after_visual=json.loads((H/'r2-visual.json').read_text())
 before_client=[p for p in before_visual['parts']if p.get('section')=='ClientDecorProxy']
 after_client=[p for p in after_visual['parts']if p.get('section')=='ClientDecorProxy']
 assert len(before_client)==len(after_client)
 finishes=0
 for a,b in zip(before_client,after_client):
  if a==b:continue
  assert a['name']=='ClientDecor_Slate' and abs(a['size'][0]-66)<.01 and abs(a['size'][2]-50)<.01
  assert a['position'][2]-a['size'][2]/2>=-110
  aa=dict(a);bb=dict(b)
  for k in ('color','material'):aa.pop(k);bb.pop(k)
  assert aa==bb,'client geometry/flags changed';finishes+=1
 assert finishes==6
 report['client_platform_finish_only']=finishes
# Conservative attachment graph: new parts must join an assembly that reaches an
# existing surface. Cosmetic joint overlap is intentional, not physical contact.
boxes=[box(p)for p in added];attached=set();edges={i:set()for i in range(len(added))}
existing=[box(p)for p in old['parts']if p['transparency']<.99]
def near(a,b):return np.all(np.minimum(a[4],b[4])-np.maximum(a[3],b[3])>=-.04)
for i,a in enumerate(boxes):
 if any(near(a,b)for b in existing):attached.add(i)
 for j in range(i):
  if near(a,boxes[j]):edges[i].add(j);edges[j].add(i)
while True:
 grow=attached|set(j for i in attached for j in edges[i])
 if grow==attached:break
 attached=grow
report['unsupported_new_assemblies']=[added[i]['name']for i in range(len(added))if i not in attached]
(H/('AUDIT-'+tag+'.json')).write_text(json.dumps(report,indent=2));print(json.dumps(report))
assert not(errors or margins or bounds or placement or report['unsupported_new_assemblies'])and frozen
