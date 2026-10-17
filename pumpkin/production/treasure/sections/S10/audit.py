"""S10 native+actual client bounds audit; never changes production tests."""
from pathlib import Path
from collections import Counter
import json,sys,numpy as np
H=Path(__file__).resolve().parent;tag=sys.argv[-1]
old=json.loads((H/'before.json').read_text());new=json.loads((H/(tag+'.json')).read_text())
vis=json.loads((H/(tag+'-visual.json')).read_text());basevis=json.loads((H/'before-visual.json').read_text())
enc=lambda p:json.dumps(p,sort_keys=True)
def normalized(p):
 p=json.loads(json.dumps(p))
 if p['name'].startswith(('S9_PlotBoard','S9_NumberBanner')):
  p.pop('label',None);p['attributes'].pop('RouteLabel',None);p['attributes'].pop('S9Caption',None)
 return enc(p)
assert Counter(map(normalized,old['parts']))==Counter(normalized(p)for p in new['parts']if p.get('section')!='S10'),'old home fields changed'
beforeclient=[p for p in basevis['parts']if p.get('section')=='ClientDecorProxy']
afterclient=[p for p in vis['parts']if p.get('section')=='ClientDecorProxy']
assert len(beforeclient)==len(afterclient)
finishes=[]
for a,b in zip(beforeclient,afterclient):
 aa=dict(a);bb=dict(b)
 for k in ('color','material','transparency','label','labelFace','labelSize'):aa.pop(k,None);bb.pop(k,None)
 # S10's private caption metadata is presentation only, and cannot trigger UIWorld.
 for d in (aa,bb):
  d['attributes']=dict(d['attributes'])
  for key in ('S10Caption','LabelFace','LabelSize','S10LabelLift'):d['attributes'].pop(key,None)
 assert aa==bb,'client geometry/flags/tags changed '+a['name']
 if a!=b:finishes.append(b)
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
added=[p for p in new['parts']if p.get('section')=='S10']
added += [p for p in vis['parts']if p['name'].startswith('ClientDecor_S10_')]
physical=[(p,box(p))for p in old['parts']if p['collidable']or p['query']]
contacts=[];margins=[];bounds=[]
for p in added:
 assert not(p['collidable']or p['query']or p['touch']or p['tags'])
 a=box(p);lo,hi=a[3:]
 if np.any(lo<[-176,-3,-176])or np.any(hi>[176,45,-110]):bounds.append(p['name'])
 # Existing 40x280 central paving; strict all-height one-stud expanded footprint.
 if min(hi[0],21)>max(lo[0],-21)and min(hi[2],141)>max(lo[2],-141):margins.append(p['name'])
 for q,b in physical:
  if np.all(np.minimum(hi,b[4])-np.maximum(lo,b[3])>.035)and hit(a,b):contacts.append([p['name'],q['name']])
for p in finishes:
 lo,hi=box(p)[3:]
 assert np.all(lo>=[-176,-3,-176])and np.all(hi<=[176,45,-110]),'finish out of S10'
existing=[box(p)for p in basevis['parts']if p['transparency']<.99]
boxes=[box(p)for p in added]
def near(a,b):return np.all(np.minimum(a[4],b[4])-np.maximum(a[3],b[3])>=-.04)
attached={i for i,a in enumerate(boxes)if any(near(a,b)for b in existing)}
while True:
 grown=attached|{i for i,a in enumerate(boxes)if any(near(a,boxes[j])for j in attached)}
 if grown==attached:break
 attached=grown
unsupported=[added[i]['name']for i in range(len(added))if i not in attached]
frozen=True
if tag=='r2':
 r1=json.loads((H/'r1.json').read_text())
 frozen=not(Counter(enc(p)for p in r1['parts']if p.get('section')=='S10')-Counter(map(enc,added)))
 assert frozen,'R1 silhouette changed'
assert new['lights']==old['lights'],'unexpected light change'
camera_errors=[]
cameras=json.loads((H/'CAMERAS.json').read_text())['views']
for v in cameras:
 eye=np.array(v['eye'])
 for p in vis['parts']:
  if p['transparency']>=.99:continue
  a=box(p)
  if np.all(np.abs(a[1].T@(eye-a[0]))<a[2]-.001):camera_errors.append([v['name'],p['name']])
report=dict(original_native_home_exact_except_private_S9_caption=True,client_geometry_flags_attributes_exact=True,new_cosmetics=len(added),client_finishes=len(finishes),physical_contacts=contacts,lane_margin_errors=margins,bounds_errors=bounds,unsupported=unsupported,frozen_r1=frozen,new_lights=0,camera_inside_visible_parts=camera_errors,tolerance=.035)
(H/('AUDIT-'+tag+'.json')).write_text(json.dumps(report,indent=2));print(json.dumps(report))
assert not(contacts or margins or bounds or unsupported or camera_errors)
