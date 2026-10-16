"""Duplicate-sensitive scene preservation, camera and live-safe light checks."""
import json,sys,hashlib
from collections import Counter
from pathlib import Path
import numpy as np
H=Path(__file__).resolve().parent;ROOT=H.parents[2]
tag=sys.argv[1]
read=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
old,new=read(H/'before.json'),read(H/(tag+'.json'))
enc=lambda p:json.dumps(p,sort_keys=True)
protected=lambda p:p['collidable'] or p['query'] or p['touch'] or p.get('lane') or p.get('tags')
def retired(p):
 x,y,z=p['position']
 return 90<x<130 and -8<z<45 and p['name'] in ('Round4StackedRock','Round4PaleRockTop') and not protected(p)
def normalized(p):
 p=json.loads(enc(p))
 if p['name']=='Round4JumpPalePad' and 140<p['position'][0]<156:
  p.pop('color');p.pop('material')
 if tag=='r2' and palette(p):
  p.pop('color');p.pop('material')
 return enc(p)
def palette(p):
 x,y,z=p['position']
 return 124<=x<=144 and -15<z<15 and not protected(p) and p['name'] in ('Round4ShelfRockRelief','Round4ShelfLightFacet','Round4ShelfMossDrop','Round4ShelfMossLedge')
assert Counter(enc(p) for p in old['parts'] if protected(p))==Counter(enc(p) for p in new['parts'] if protected(p))
a=Counter(normalized(p) for p in old['parts'] if not retired(p));b=Counter(normalized(p) for p in new['parts'])
assert not a-b,'unapproved old art changed'
added=[json.loads(s) for s,n in (b-a).items() for _ in range(n)]
assert all(p.get('section')=='S5' and not protected(p) for p in added)
assert old['kits']==new['kits']
assert not any(retired(p) for p in new['parts'])
assert all(p['brightness']<=1.5 and p['range']<=18 and not p['shadows'] for p in new['lights'] if p['kind']=='PointLight')
assert all(not p['shadows'] for p in new['lights'])
mustkeep=lambda p:p.get('lane') or p['name'] in ('WindingCobble','StonePathEdge','GrassShoulder')
assert Counter(enc(p) for p in old['parts'] if mustkeep(p))==Counter(enc(p) for p in new['parts'] if mustkeep(p))
eyes=read(H/'CAMERAS.json');clear=[]
for v in eyes:
 if v['name']=='overview':continue
 hits=[]
 for p in new['parts']:
  if not(p['collidable'] or p['query']):continue
  local=np.array(p['rotation']).reshape(3,3).T@(np.array(v['eye'])-np.array(p['position']))
  if np.all(np.abs(local)<np.array(p['size'])/2-.002):hits.append(p['name'])
 assert not hits,(v['name'],hits)
 clear.append(dict(camera=v['name'],eye=v['eye'],eye_inside_solid=False))
if tag=='r2':
 r1=read(H/'r1.json');frozen=[p for p in r1['parts'] if p.get('section')=='S5']
 assert not Counter(map(enc,frozen))-Counter(map(enc,new['parts'])),'R1 silhouette changed'
 assert (ROOT/'prototype/meadow-v4/Section5.luau').read_bytes()==(H/'r2-Section5.luau').read_bytes()
contact=read(H/(tag+'-physical-contact.json'))
for key in ('physical_penetrations','kit_physical_penetrations','kit_support_errors','floating_assemblies','lane_buffer_errors'):assert not contact[key],key
out=dict(protected_signatures_exact=True,must_keep_paving_edges_exact=True,unrelated_art_exact=True,kit_manifest_exact=True,retired_cosmetic_columns=sum(map(retired,old['parts'])),added_cosmetics=len(added),new_query_touch_collision_false=True,all_point_lights_live_safe=True,cameras=clear,contact_errors=0,live_Studio='UNKNOWN')
(H/('SIGNATURES-'+tag+'.json')).write_text(json.dumps(out,indent=2))
print('PASS',tag,json.dumps(out))
