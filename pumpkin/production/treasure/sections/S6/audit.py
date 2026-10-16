"""Duplicate-sensitive protection, bounds, strict horizontal margins and freeze."""
import json,sys
from collections import Counter
from pathlib import Path
import numpy as np
H=Path(__file__).resolve().parent;tag=sys.argv[1]
read=lambda n:json.loads((H/n).read_text(encoding='utf-8-sig'))
old,new=read('before.json'),read(tag+'.json')
enc=lambda p:json.dumps(p,sort_keys=True)
def normalize(p):
 p=json.loads(enc(p));x,y,z=p['position']
 if p['name']=='SolidMountainStone' and 0<=y+p['size'][1]/2<=54 and -65<=x<=125 and -158<=z<=-35 and not(-32<=x<=32 and -132<=z<=-72):p.pop('color');p.pop('material')
 if tag=='r2' and p['name'] in ('Round4ShelfRockRelief','Round4ShelfLightFacet','Round4StackedRock') and -65<=x<=125 and 0<=y<=54 and -158<=z<=-35 and not(y>=44 and -32<=x<=32 and -132<=z<=-72) and not(p['collidable'] or p['query'] or p['touch'] or p.get('lane') or p.get('laneId') or p['tags']):p.pop('color');p.pop('material')
 return enc(p)
a,b=Counter(map(normalize,old['parts'])),Counter(map(normalize,new['parts']))
assert not a-b,'unapproved prior change/removal'
added=[json.loads(s) for s,n in (b-a).items() for _ in range(n)]
assert added and all(p.get('section')=='S6' and not(p['collidable'] or p['query'] or p['touch'] or p.get('lane') or p.get('laneId') or p['tags']) for p in added)
mustkeep=lambda p:p.get('lane') or p['name'] in ('WindingCobble','StonePathEdge','GrassShoulder')
assert Counter(enc(p) for p in old['parts'] if mustkeep(p))==Counter(enc(p) for p in new['parts'] if mustkeep(p))
court=lambda p:p['position'][1]>=44 and -32<=p['position'][0]<=32 and -132<=p['position'][2]<=-72
assert Counter(enc(p) for p in old['parts'] if court(p))==Counter(enc(p) for p in new['parts'] if court(p))
lanes=[]
for p in old['parts']:
 if not p.get('lane'):continue
 r=np.array(p['rotation']).reshape(3,3);e=np.abs(r)@np.array(p['size'])/2
 c=np.array(p['position']);h=np.array(p['size'])/2+np.array([1,0,1])
 corners=np.array([(c+r@np.array([x*h[0],y*h[1],z*h[2]]))[[0,2]] for x in (-1,1) for y in (-1,1) for z in (-1,1)])
 lanes.append((corners,r))
def horizontal_overlap(p,corners,r):
 c=np.array(p['position']);h=np.array(p['size'])/2;s=np.array(p['rotation']).reshape(3,3)
 a=np.array([(c+s@np.array([x*h[0],y*h[1],z*h[2]]))[[0,2]] for x in (-1,1) for y in (-1,1) for z in (-1,1)])
 # SAT on horizontal projections, with no altitude exception.
 for rotation in (r,s):
  for axis in rotation.T:
   v=axis[[0,2]];norm=np.linalg.norm(v)
   if norm<1e-5:continue
   v=v/norm;aa=a@v;bb=corners@v
   if min(aa.max(),bb.max())-max(aa.min(),bb.min())<=.035:return False
 return True
for p in added:
 r=np.array(p['rotation']).reshape(3,3);e=np.abs(r)@np.array(p['size'])/2;c=np.array(p['position']);lo=c-e;hi=c+e
 assert lo[0]>=-65 and hi[0]<=125 and lo[1]>=0 and hi[1]<=54 and lo[2]>=-158 and hi[2]<=-35,p['name']
 assert not(-32<=c[0]<=32 and -132<=c[2]<=-72),p['name']
 assert not any(horizontal_overlap(p,corners,r) for corners,r in lanes),('strict horizontal margin',p['name'])
assert old['kits']==new['kits']
assert all(l['brightness']<=1.5 and l['range']<=18 and not l['shadows'] for l in new['lights'] if l['kind']=='PointLight')
clear=[]
for v in read('CAMERAS.json'):
 if v['name']=='overview':continue
 hits=[]
 for p in new['parts']:
  if not(p['collidable'] or p['query']):continue
  local=np.array(p['rotation']).reshape(3,3).T@(np.array(v['eye'])-np.array(p['position']))
  if np.all(np.abs(local)<np.array(p['size'])/2-.002):hits.append(p['name'])
 assert not hits,(v['name'],hits)
 clear.append(v['name'])
if tag=='r2':
 r1=read('r1.json')['parts']
 frozen=[p for p in r1 if p.get('section')=='S6']
 assert not Counter(map(enc,frozen))-Counter(map(enc,new['parts'])),'R1 silhouette changed'
 assert Counter(enc(p) for p in r1 if p['name']=='SolidMountainStone')==Counter(enc(p) for p in new['parts'] if p['name']=='SolidMountainStone'),'R1 cliff finish changed'
contact=read(tag+'-physical-contact.json')
for k in ('physical_penetrations','kit_physical_penetrations','kit_support_errors','floating_assemblies','lane_buffer_errors'):assert not contact[k],k
out=dict(collider_geometry_flags_tags_attributes_exact=True,solid_finish_only=True,mustkeep_paving_edges_exact=True,summit_court_exact=True,unrelated_art_exact=True,serialized_kit_manifest_exact=True,strict_horizontal_lane_margin_studs=1,added_cosmetics=len(added),contact_errors=0,cameras_outside_solids=clear,point_lights_live_safe=True,r1_frozen=tag=='r2',live_Studio='UNKNOWN')
(H/('SIGNATURES-'+tag+'.json')).write_text(json.dumps(out,indent=2));print('PASS',tag,json.dumps(out))
