"""Duplicate-sensitive protection and OBB contact; cosmetic joins are intentional."""
from pathlib import Path
from collections import Counter
import json,sys,hashlib,numpy as np
H=Path(__file__).resolve().parent;tag=sys.argv[1]
old=json.loads((H/'before-r34.json').read_text());new=json.loads((H/(tag+'.json')).read_text())
enc=lambda p:json.dumps(p,sort_keys=True)
protected=lambda p:p['collidable'] or p['query'] or p['touch'] or p.get('lane') or p['tags'] or p.get('section') not in (None,'S8')
assert Counter(enc(p) for p in old['parts'] if protected(p))==Counter(enc(p) for p in new['parts'] if protected(p)),'protected or other-section art changed'
assert old['kits']==new['kits'] and old['lights']==new['lights']
before,after=Counter(map(enc,old['parts'])),Counter(map(enc,new['parts']))
removed=[json.loads(s) for s,n in (before-after).items() for _ in range(n)]
allowed={'R5MountainTier1','R5MountainTier2','R5MountainTier3','R5MountainTier4','R5IrregularRockFace','Round4TaperChunk','TaperedIslandStone','R5HangingApex','R5SecondaryHangingPoint','R5IntentionalFloatingRock','LookLightRockTop','LookRockFragment','LookRockMoss','MountainMossTop'}
for p in removed:
 assert p.get('section')=='S8' or (p['name'] in allowed and not protected(p)),p['name']
lookup={(p['name'],tuple(p['position'])):p for p in new['parts'] if p.get('section')!='S8'}
palette_replacements=[]
for p in removed:
 q=lookup.get((p['name'],tuple(p['position'])))
 if q:
  a,b=dict(p),dict(q)
  for k in ('color','material'):a.pop(k);b.pop(k)
  assert a==b,'non-palette edit'
  palette_replacements.append(enc(q))
non_section_delta=Counter({s:n for s,n in (after-before).items() if json.loads(s).get('section')!='S8'})
restored=[]
baseline=json.loads((H/'before.json').read_text())['parts']
baseline_counts=Counter(map(enc,baseline))
for s,n in (non_section_delta-Counter(palette_replacements)).items():
 p=json.loads(s)
 candidates=[q for q in baseline if q['name']==p['name'] and q['position']==p['position']]
 assert p['name'] in allowed and not protected(p),'unexpected non-S8 addition'
 for q in candidates:
  a,b=dict(q),dict(p)
  for k in ('color','material'):a.pop(k);b.pop(k)
  if a==b and baseline_counts[enc(q)]>=n:break
 else:raise AssertionError('restored cosmetic not exact original geometry')
 restored.extend([s]*n)
assert non_section_delta==Counter(palette_replacements)+Counter(restored),'unexpected addition or duplicate'
def box(p):
 c=np.array(p['position']);r=np.array(p['rotation']).reshape(3,3);h=np.array(p['size'])/2;e=np.abs(r)@h
 return c,r,h,c-e,c+e
def hit(a,b,tol=.035):
 ca,ra,ha,*_=a;cb,rb,hb,*_=b
 for axis in [*ra.T,*rb.T]+[np.cross(x,y) for x in ra.T for y in rb.T]:
  n=np.linalg.norm(axis)
  if n<1e-6:continue
  v=axis/n
  if np.sum(np.abs(v@ra)*ha)+np.sum(np.abs(v@rb)*hb)-abs(v@(cb-ca))<=tol:return False
 return True
physical=[(p,box(p)) for p in old['parts'] if p['collidable'] or p['query']]
plo=np.array([b[3] for _,b in physical]);phi=np.array([b[4] for _,b in physical])
added=[p for p in new['parts'] if p.get('section')=='S8'];errors=[]
for p in added+[json.loads(s) for s in restored]:
 assert not protected(p)
 a=box(p);lo,hi=a[3:]
 for i in np.where(np.all(np.minimum(hi,phi)-np.maximum(lo,plo)>.035,axis=1))[0]:
  if hit(a,physical[i][1]):errors.append([p['name'],p['position'],physical[i][0]['name']])
assert not any(p['name']=='R5IntentionalFloatingRock' for p in new['parts'])
out=dict(state='PASS' if not errors else 'FAIL',manifest_sha256=hashlib.sha256((H/(tag+'.json')).read_bytes()).hexdigest(),protected_and_other_section_art_exact=True,physical_penetrations=errors,contact_tolerance=.035,new_parts=len(added),boulders=sum(p['name']=='S8_Boulder' for p in added),removed_cosmetic_records=len(removed),palette_only_edits=len(palette_replacements),restored_original_cosmetic_boxes=len(restored),restored_exact_original_geometry=[json.loads(s) for s in restored],lights_exact=True,lowest_gameplay_solid=min(b[3][1] for _,b in physical),live='UNKNOWN')
(H/('AUDIT-'+tag+'.json')).write_text(json.dumps(out,indent=2))
(H/('REMOVED-'+tag+'.json')).write_text(json.dumps(removed,indent=2))
print(json.dumps(out));assert not errors
