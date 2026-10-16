"""Scope proof for the owner-authorized R3/R4 finish-only pass."""
import json,hashlib,sys
from pathlib import Path
from collections import Counter
H=Path(__file__).resolve().parent;ROOT=H.parents[2];tag=sys.argv[1]
read=lambda f:json.loads((H/f).read_text(encoding='utf-8-sig'))
old,new=read('r3-start.json'),read(tag+'.json')
def ridge(p):
 x,y,z=p['position'];return 80<=x<=144 and -12<=z<=64
def retired(p):
 x,y,z=p['position']
 cap=ridge(p) and y>4 and p['size'][1]<.5 and p['name'] in ('LookLightRockTop','Round4ShelfLightFacet')
 foreground=tag=='r4' and 116<=x<=124 and -12<=z<=40 and p['name'] in ('Round4ShelfRockRelief','Round4ShelfMossLedge','Round4ShelfMossDrop')
 return (cap or foreground) and not(p['collidable'] or p['query'] or p['touch'] or p.get('lane') or p['tags'])
def normalized(p):
 p=json.loads(json.dumps(p));n=p['name'];x,y,z=p['position']
 if (ridge(p) and n in ('SolidMountainStone','SolidRampBody','SolidRampWedge','Round4ShelfRockRelief','Round4ShelfLightFacet')) or n.startswith('OptionalJumpLanding') or (140<x<156 and n in ('Round4JumpPalePad','Round4JumpAmberEdge')):
  p.pop('color');p.pop('material')
 return json.dumps(p,sort_keys=True)
prior=Counter(normalized(p) for p in old['parts'] if not retired(p));after=Counter(map(normalized,new['parts']))
assert not prior-after,'unapproved part change/removal'
added=[json.loads(s) for s,n in (after-prior).items() for _ in range(n)]
assert added and all(p.get('section')=='S5' and not(p['collidable'] or p['query'] or p['touch'] or p.get('lane') or p['tags']) for p in added)
assert old['kits']==new['kits']
c=read(tag+'-physical-contact.json')
for k in ('physical_penetrations','kit_physical_penetrations','kit_support_errors','floating_assemblies','lane_buffer_errors'):assert not c[k],k
assert all(l['brightness']<=1.5 and l['range']<=18 and not l['shadows'] for l in new['lights'] if l['kind']=='PointLight')
assert old['lights']==new['lights']
kits=read(tag+'-kits.json')
for i,g in enumerate(kits,1):
 p=next(p for p in new['parts'] if p['name']=='S5_RockAnchor'+str(i))
 assert p['transparency']==1
 assert max(abs(a-b) for a,b in zip(p['size'],g['size']))<.001
 assert max(abs(a-b) for a,b in zip(p['position'],[g['x'],g['y']+g['size'][1]/2,g['z']]))<.001
out=dict(physics_lane_collider_transforms_sizes_tags_attributes_exact=True,permitted_solid_edits='color/material only',unrelated_art_exact=True,existing_kits_and_lights_exact=True,contact_errors=0,retired_cosmetic_caps=sum(map(retired,old['parts'])),new_native_cosmetics=len(added),new_fitted_kits=len(kits),live_Studio='UNKNOWN')
(H/('SIGNATURES-'+tag+'.json')).write_text(json.dumps(out,indent=2));print('PASS',tag,json.dumps(out))
