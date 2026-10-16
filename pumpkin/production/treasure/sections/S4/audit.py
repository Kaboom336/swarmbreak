"""Duplicate-sensitive parity; must-keep art; only owned nonphysical removals."""
import json,hashlib,sys
from collections import Counter
from pathlib import Path
H=Path(__file__).resolve().parent;ROOT=H.parents[2];tag=sys.argv[1]
a=json.loads((H/'before.json').read_text());b=json.loads((H/(tag+'.json')).read_text())
encode=lambda p:json.dumps(p,sort_keys=True)
old_warning=lambda p:p.get('section')=='S1' and p['name'] in ('S1_SignBoard','S1_SignPost') and abs(p['position'][0]-24)<.01 and abs(p['position'][2]-101)<.01 and p.get('tags')==['S1FrameProp'] and not(p['collidable'] or p['query'] or p['touch'] or p.get('lane'))
protected=lambda p:(p['collidable'] or p['query'] or p['touch'] or p.get('lane') or p.get('tags')) and not old_warning(p)
assert Counter(map(encode,filter(protected,a['parts'])))==Counter(map(encode,filter(protected,b['parts'])))
original=Counter(map(encode,a['parts']));retained=Counter(encode(p) for p in b['parts'] if p.get('section')!='S4')
removed=[json.loads(p) for p,n in (original-retained).items() for _ in range(n)]
assert not retained-original,'unrelated cosmetic mutated'
def allowed_removal(p):
 if protected(p):return False
 if p['name'] in ('R5FencePost','R5FenceRail'):return abs(abs(p['position'][0])-11.6)<.02 and abs(p['position'][2])<=24.01
 return tag!='r1' and p.get('section')=='S1' and p['name'] in ('S1_SignBoard','S1_SignPost') and abs(p['position'][0]-24)<.01 and abs(p['position'][2]-101)<.01
assert all(map(allowed_removal,removed))
added=[p for p in b['parts'] if p.get('section')=='S4'];assert added and all(not protected(p) for p in added)
assert all(-55<=p['position'][0]<=80 and -36<=p['position'][1]<=26 and -46<=p['position'][2]<=98 for p in added)
assert b['kits']==a['kits']
if tag!='r1':
 r1=json.loads((H/'r1.json').read_text());frozen=Counter(encode(p) for p in r1['parts'] if p.get('section')=='S4');assert not frozen-Counter(map(encode,b['parts'])),'R1 silhouette changed in R2'
contact=json.loads((H/(tag+'-physical-contact.json')).read_text())
for k in ('physical_penetrations','kit_physical_penetrations','kit_support_errors','floating_assemblies','lane_buffer_errors'):assert not contact[k],k
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
out=dict(status='PASS',protected_gameplay_geometry_palette_floor_tags_exact=True,tagged_art_exception='Only owner-requested old S1 BRIDGE board/post with S1FrameProp art tag; no gameplay/floor/query tag exception',all_retained_cosmetics_exact=True,must_keep_warm_paving_edge_stones_planks_exact=True,unchanged_existing_kits=True,new_S4_parts=len(added),removed=removed,contact=contact,artifact_sha256=sha(ROOT/'slice-v2/prototype/guardian-greybox.rbxl'),backup_sha256=sha(ROOT/'slice-v2/prototype/guardian-greybox.pre-s4.rbxl'),live_Studio='UNKNOWN')
(H/(tag+'-SIGNATURES.json')).write_text(json.dumps(out,indent=2));print('PASS exact protected/must-keep art/kits;',len(added),'S4 parts; zero contact errors')
