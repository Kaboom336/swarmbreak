"""Duplicate-sensitive scope proof against the immediate R3 backup export."""
import json,sys,hashlib
from pathlib import Path
from collections import Counter
H=Path(__file__).resolve().parent;tag=sys.argv[1]
read=lambda n:json.loads((H/n).read_text(encoding='utf-8-sig'))
old,new=read('r3-start.json'),read(tag+'.json')
enc=lambda p:json.dumps(p,sort_keys=True)
def owned(p):
 x,y,z=p['position'];return -65<=x<=125 and -158<=z<=-35 and 0<=y<=54 and not(y>=44 and -32<=x<=32 and -132<=z<=-72)
def cosmetic(p):return not(p['collidable'] or p['query'] or p['touch'] or p.get('lane') or p.get('laneId') or p['tags'])
def retired(p):
 x,y,z=p['position']
 return owned(p) and cosmetic(p) and (p['name']=='StonePathEdge' or (x>=75 and p['name']=='Round4PaleRockTop') or (tag=='r4' and p['name'] in ('Round4ShelfRockRelief','Round4ShelfLightFacet','Round4StackedRock','LookLightRockTop')))
def normal(p):
 p=json.loads(enc(p));x,y,z=p['position'];n=p['name']
 finish=owned(p) and ((n=='SolidMountainStone' and y+p['size'][1]/2<=54 and not(-32<=x<=32 and -132<=z<=-72)) or (cosmetic(p) and n in ('Round4ShelfRockRelief','Round4ShelfLightFacet','Round4StackedRock')))
 landing=cosmetic(p) and n=='WindingCobble' and 112<=x<=125 and -98<=z<=-85 and 23<=y<=(31 if tag=='r4' else 25)
 if finish or landing:p.pop('color');p.pop('material')
 return enc(p)
a=Counter(normal(p) for p in old['parts'] if not retired(p));b=Counter(map(normal,new['parts']))
assert not a-b,('unapproved change',list((a-b).items())[:1])
added=[json.loads(s) for s,n in (b-a).items() for _ in range(n)]
assert added and all(p.get('section')=='S6' and cosmetic(p) for p in added)
assert old['kits']==new['kits']
for g in read(tag+'-kits.json'):
 name='S6_RockAnchor'+g['id'].removeprefix('WallRock') if tag=='r3' else 'S6_VisibleRockAnchor'+g['id'].removeprefix('VisibleRock')
 p=next(p for p in new['parts'] if p['name']==name)
 assert p['transparency']==1 and max(abs(a-b) for a,b in zip(p['size'],g['size']))<.002
 assert max(abs(a-b) for a,b in zip(p['position'],[g['x'],g['y']+g['size'][1]/2,g['z']]))<.002
assert Counter(enc(p) for p in old['parts'] if p.get('lane'))==Counter(enc(p) for p in new['parts'] if p.get('lane'))
contact=read(tag+'-physical-contact.json')
for k in ('physical_penetrations','kit_physical_penetrations','kit_support_errors','floating_assemblies','lane_buffer_errors'):assert not contact[k],k
assert all(l['brightness']<=1.5 and l['range']<=18 and not l['shadows'] for l in new['lights'] if l['kind']=='PointLight')
audit=read('AUDIT-'+tag+'.json');assert audit['compiled_O0_O1_O2']==76 and audit['unrelated_sources_preserved']==75 and audit['workspace_exact']
out=dict(state='PASS offline',sources_compiled_O0_O1_O2=76,unrelated_sources_preserved=75,serialized_place_exact_except_Section6_Source=True,all_lane_signatures_exact=True,solid_edits='color/material only',unrelated_art_exact=True,contact_errors=0,retired_owned_cosmetics=sum(map(retired,old['parts'])),new_native_cosmetics=len(added),new_kit_envelopes=len(read(tag+'-kits.json')),live_safe_lights=True,kerb_setback='surface trim replaces existing edging footprint; excluded from prop headroom setback; collider penetration still checked',live_Studio='UNKNOWN')
(H/('SIGNATURES-'+tag+'.json')).write_text(json.dumps(out,indent=2));print(json.dumps(out))
