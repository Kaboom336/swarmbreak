"""Cosmetic-only R3/R4 audit. Existing production tests are unchanged."""
import json,sys
from pathlib import Path
from collections import Counter
import numpy as np
H=Path(__file__).resolve().parent
tag=sys.argv[-1]
old=json.loads((H/'r2.json').read_text());new=json.loads((H/(tag+'.json')).read_text())
basevis=json.loads((H/'r2-visual.json').read_text());vis=json.loads((H/(tag+'-visual.json')).read_text())
enc=lambda p:json.dumps(p,sort_keys=True)
assert Counter(enc(p)for p in old['parts']if p.get('section')!='S10')==Counter(enc(p)for p in new['parts']if p.get('section')!='S10'),'protected native home changed'
assert new['lights']==old['lights'],'S9 lights changed'
# Reuse inspected SAT math at the existing .035 tolerance, without old R1 freeze.
source=(H/'audit.py').read_text();a=source.index('def box(');b=source.index('\nadded=',a)
exec(source[a:b])
beforeclient=[p for p in basevis['parts']if p.get('section')=='ClientDecorProxy']
afterclient=[p for p in vis['parts']if p.get('section')=='ClientDecorProxy'and not p['name'].startswith('ClientDecor_S10_')]
assert len(beforeclient)==len(afterclient)
changes=[];geometry=[]
for a,b in zip(beforeclient,afterclient):
 assert a['name']==b['name']
 for key in ('collidable','query','touch','tags'):assert a[key]==b[key]
 if a!=b:
  c=a['position'];s=a['size'];n=a['name']
  rail=n in ('ClientDecor_Wood','ClientDecor_DarkWood')and -120.01<=c[2]<=-101.99 and 11<c[1]<16 and abs(c[0])<=86
  portal=any(abs(c[0]-x)<=17 for x in (-66,-22,22,66))and -148<=c[2]<=-141 and c[1]+s[1]/2<=45
  steps=n=='ClientDecor_Stone'and -137<=c[2]<=-119 and 27<s[0]<29 and s[2]<4
  meadow=abs(c[0])<=21 and abs(c[2])<=3 and 0<c[1]<40
  assert rail or portal or steps or meadow,('unexpected client change',n,c)
  changes.append(b)
  if any(a[k]!=b[k]for k in ('size','position','rotation')):geometry.append(b)
added=[p for p in new['parts']if p.get('section')=='S10']+[p for p in vis['parts']if p['name'].startswith('ClientDecor_S10_')]
physical=[(p,box(p))for p in old['parts']if p['collidable']or p['query']]
contacts=[];bounds=[];margins=[];margin_exceptions=[]
for p in added+geometry:
 assert not(p['collidable']or p['query']or p['touch']or p['tags'])
 a=box(p);lo,hi=a[3:]
 # Explicit user stair/rail scope crosses S10 seam; no unrelated S9 changes.
 stair=p['name'].startswith('S10_Stair')and -103<=lo[2]<=hi[2]<=-89 and -21<=lo[0]<=hi[0]<=21
 rail=p['name']in ('ClientDecor_Wood','ClientDecor_DarkWood')and -122<=lo[2]<=hi[2]<=-101
 meadow=p['name'].startswith('ClientDecor_S10_Meadow')and -22<=lo[0]<=hi[0]<=22 and -4<=lo[2]<=hi[2]<=4
 if not(stair or rail or meadow)and (np.any(lo<[-176,-3,-176])or np.any(hi>[176,45,-110])):bounds.append(p['name'])
 if min(hi[0],21)>max(lo[0],-21)and min(hi[2],141)>max(lo[2],-141):
  if stair or rail or meadow:margin_exceptions.append(p['name'])
  else:margins.append(p['name'])
 for q,b in physical:
  if np.all(np.minimum(hi,b[4])-np.maximum(lo,b[3])>.035)and hit(a,b):contacts.append([p['name'],q['name']])
existing=[box(p)for p in basevis['parts']if p['transparency']<.99]
boxes=[box(p)for p in added+geometry]
def near(a,b):return np.all(np.minimum(a[4],b[4])-np.maximum(a[3],b[3])>=-.04)
attached={i for i,a in enumerate(boxes)if any(near(a,b)for b in existing)}
while True:
 grown=attached|{i for i,a in enumerate(boxes)if any(near(a,boxes[j])for j in attached)}
 if grown==attached:break
 attached=grown
unsupported=[(added+geometry)[i]['name']for i in range(len(boxes))if i not in attached]
labels=[p.get('label','')for p in new['parts']+vis['parts']]
assert not any(any(word in (s or '').upper()for word in ('FROST','VOLCANO','OCEAN'))for s in labels),'invented world visible'
assert sum(p.get('section')=='S9'for p in new['parts'])==1720
camera_errors=[]
for view in json.loads((H/'CAMERAS.json').read_text())['views']:
 eye=np.array(view['eye'])
 for p in vis['parts']:
  if p['transparency']>=.99:continue
  c,r,h,*_=box(p)
  if np.all(np.abs(r.T@(eye-c))<h-.001):camera_errors.append([view['name'],p['name']])
report=dict(native_home_physics_geometry_tags_palette_exact=True,S9_parts=1720,S9_lights_exact=True,new_cosmetics=len(added),client_changes=len(changes),client_geometry_changes=len(geometry),physical_contacts=contacts,bounds_errors=bounds,unsupported=unsupported,lane_margin_errors=margins,explicit_existing_stair_rail_portal_footprint_exceptions=margin_exceptions,camera_inside_visible_parts=camera_errors,tolerance=.035,scope_exceptions='explicit requested stair/rail cosmetics across S10 seam and existing Meadow portal finish; existing footprint exceptions recorded, no collider changes',live='UNKNOWN')
(H/('AUDIT-'+tag+'.json')).write_text(json.dumps(report,indent=2));print(json.dumps(report))
assert not(contacts or bounds or unsupported or margins or camera_errors)
