"""Independent duplicate-sensitive preservation, .035 OBB contact and full-height margins."""
from pathlib import Path
from collections import Counter
import json,sys,numpy as np
H=Path(__file__).resolve().parent;tag=sys.argv[1]
old=json.loads((H/'before.json').read_text());new=json.loads((H/(tag+'.json')).read_text())
enc=lambda p:json.dumps(p,sort_keys=True)
before=Counter(map(enc,old['parts']));after=Counter(map(enc,new['parts']))
removed=[json.loads(s) for s,n in (before-after).items() for _ in range(n)]
added=[p for p in new['parts'] if p.get('section')=='S8']
names={'R5MountainTier1','R5MountainTier2','Round4TaperChunk','TaperedIslandStone'}
if tag=='r2':names.add('R5IrregularRockFace')
lookup={(p['name'],tuple(p['position'])):p for p in new['parts'] if p.get('section')!='S8'}
palette=[];retired=[];allowed_replacements=[]
for p in removed:
 assert p['name'] in names and not(p['collidable'] or p['query'] or p['touch'] or p.get('lane') or p['tags'] or p.get('section'))
 c=np.array(p['position']);r=np.array(p['rotation']).reshape(3,3);e=np.abs(r)@np.array(p['size'])/2
 assert np.all(c-e>=np.array([-176,-160,-176])-.002) and np.all(c+e<=np.array([176,54,176])+.002),'old cosmetic exception escaped section bounds'
 q=lookup.get((p['name'],tuple(p['position'])))
 if q:
  a=dict(p);b=dict(q)
  for k in ('color','material'):a.pop(k);b.pop(k)
  assert a==b,'unauthorized cosmetic field edit';palette.append(p);allowed_replacements.append(enc(q))
 else:retired.append(p)
assert old['kits']==new['kits'] and old['lights']==new['lights']
non_section_delta=Counter({s:n for s,n in (after-before).items() if json.loads(s).get('section')!='S8'})
assert non_section_delta==Counter(allowed_replacements),'unexpected non-S8 addition or duplicate'
assert all(not(p['collidable'] or p['query'] or p['touch'] or p.get('lane') or p['tags']) for p in added)
def box(p,margin=0):
 c=np.array(p['position']);r=np.array(p['rotation']).reshape(3,3);h=np.array(p['size'])/2+np.array([margin,0,margin]);e=np.abs(r)@h
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
lanes=[(p,box(p,1)) for p in old['parts'] if p.get('lane')]
plo=np.array([b[3] for _,b in physical]);phi=np.array([b[4] for _,b in physical])
llo=np.array([b[3] for _,b in lanes]);lhi=np.array([b[4] for _,b in lanes])
errors=[];laneerrors=[];attachments=[];unsupported=[];attached=set();newboxes=[]
retained=[(p,box(p)) for p in new['parts'] if p.get('section')!='S8' and p['transparency']<.99 and p['shape']=='Block']
rlo=np.array([b[3] for _,b in retained]);rhi=np.array([b[4] for _,b in retained])
for index,p in enumerate(added):
 a=box(p);c,r,h,lo,hi=a
 newboxes.append(a)
 assert np.all(lo>=np.array([-176,-160,-176])-.002) and np.all(hi<=np.array([176,54,176])+.002)
 for i in np.where(np.all(np.minimum(hi,phi)-np.maximum(lo,plo)>.035,axis=1))[0]:
  if hit(a,physical[i][1]):errors.append([p['name'],p['position'],physical[i][0]['name']])
 for i in np.where((np.minimum(hi[0],lhi[:,0])-np.maximum(lo[0],llo[:,0])>.035)&(np.minimum(hi[2],lhi[:,2])-np.maximum(lo[2],llo[:,2])>.035))[0]:
  # Source uses conservative AABBs, stricter than exact oriented projection.
  laneerrors.append([p['name'],p['position'],lanes[i][0]['name']])
 if p['name'].startswith('S8_DownwardFacet'):
  # Top of inverted wedge is full rectangle. Prove it enters an unchanged
  # neighboring rock shell; generic AABB side contact is insufficient.
  probes=[c+r@np.array([x*h[0],-h[1],z*h[2]]) for x in (-.8,0,.8) for z in (-.8,0,.8)]
 else:probes=[c+r@np.array([0,h[1],0])]
 count=0
 for v in probes:
  candidates=np.where(np.all((rlo-.035<=v)&(v<=rhi+.035),axis=1))[0]
  for i in candidates:
   _,b=retained[i];local=b[1].T@(v-b[0])
   if np.all(np.abs(local)<=b[2]+.035):count+=1;break
 if count:attachments.append(count);attached.add(index)
# Each original stratum is a three-wedge assembly. Equal adjacent wedges share
# an entire triangular side, so a directly attached sibling carries its neighbor.
# Require exact local seam, size, rotation and producer; generic box overlap is
# not accepted as assembly support.
direct=len(attached)
changed=True
while changed:
 changed=False
 for i,p in enumerate(added):
  if i in attached:continue
  a=newboxes[i]
  for j in list(attached):
   q=added[j];b=newboxes[j]
   if p['attributes'].get('S8Original')!=q['attributes'].get('S8Original'):continue
   if np.max(np.abs(a[1]-b[1]))>.002 or np.max(np.abs(a[2]-b[2]))>.002:continue
   delta=a[1].T@(b[0]-a[0])
   if abs(abs(delta[0])-2*a[2][0])<=.035 and max(abs(delta[1]),abs(delta[2]))<=.002:
    attached.add(i);changed=True;break
unsupported=[[p['name'],p['position']] for i,p in enumerate(added) if i not in attached]
for v in json.loads((H/'CAMERAS.json').read_text()):
 for p,b in physical:
  if p['shape']=='Wedge':continue
  assert not np.all(np.abs(b[1].T@(np.array(v['eye'])-b[0]))<b[2]-.002),('camera inside solid',v['name'],p['name'])
if tag=='r2':
 frozen=[p for p in json.loads((H/'r1.json').read_text())['parts'] if p.get('section')=='S8']
 assert not Counter(map(enc,frozen))-after,'R1 silhouette mutated'
out=dict(state='PASS' if not(errors or laneerrors or unsupported) else 'FAIL',new_parts=len(added),palette_edits=len(palette),retired_cosmetics=len(retired),all_protected_and_all_other_art_exact=True,physical_penetrations=errors,lane_buffer_errors=laneerrors,unsupported=unsupported,attachment_probes_passed=sum(attachments),directly_attached_parts=direct,connected_by_exact_triangular_seam=len(attached)-direct,tolerance=.035,all_height_margin=1,frozen_R1=tag=='r2',lights_unchanged=True,live='UNKNOWN')
(H/('AUDIT-'+tag+'.json')).write_text(json.dumps(out,indent=2));(H/('REMOVED-'+tag+'.json')).write_text(json.dumps(dict(retired=retired,palette_only=palette),indent=2))
print(json.dumps(out));assert out['state']=='PASS'
