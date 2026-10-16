"""Duplicate-sensitive protected/floor preservation and frozen-rib evidence."""
import json,hashlib,sys
from collections import Counter
from pathlib import Path
H=Path(__file__).resolve().parent;ROOT=H.parents[2]
tag=sys.argv[1] if len(sys.argv)>1 else 'deliver'
a=json.loads((H/'before.json').read_text());b=json.loads((H/(tag+'.json')).read_text());lock=json.loads((H/'r2.json').read_text())
encode=lambda p:json.dumps(p,sort_keys=True)
protected=lambda p:p['collidable'] or p['query'] or p['touch'] or p.get('lane') or p.get('tags')
assert Counter(map(encode,filter(protected,a['parts'])))==Counter(map(encode,filter(protected,b['parts'])))
retained=Counter(encode(p) for p in b['parts'] if p.get('section')!='S3')
original=Counter(map(encode,a['parts']))
removed=[json.loads(p) for p,n in (original-retained).items() for _ in range(n)]
assert not retained-original,'unrelated native part changed or added'
allowed={'TunnelStalactite','TunnelArchedRockRib','TunnelWallRoot','TunnelWallMoss'}
assert all(p['name'] in allowed and not protected(p) and -90<=p['position'][0]<=-63 and -22<=p['position'][2]<=70 and 8<=p['position'][1]<=28 for p in removed)
rib=lambda p:p['name'].startswith(('S3_RibHeader','S3_RibLeg','S3_RibBrace'))
assert Counter(map(encode,filter(rib,lock['parts'])))==Counter(map(encode,filter(rib,b['parts'])))
added=[p for p in b['parts'] if p.get('section')=='S3']
assert added and all(not protected(p) for p in added)
assert all(-98<=p['position'][0]<=-40 and -37<=p['position'][2]<=98 and -3<=p['position'][1]<=28 for p in added)
assert min(p['position'][1]-p['size'][1]/2 for p in added)>9.5,'architecture below declared player clearance'
assert b['kits']==a['kits'],'retained kit placements changed'
contact=json.loads((H/(tag+'-physical-contact.json')).read_text())
for k in ('physical_penetrations','kit_physical_penetrations','kit_support_errors','floating_assemblies','lane_buffer_errors'):assert not contact[k],k
sha=lambda path:hashlib.sha256(path.read_bytes()).hexdigest()
out=dict(status='PASS',all_protected_native_signatures_exact=True,all_retained_floor_and_edge_art_exact=True,unrelated_native_cosmetics_exact=True,removed_old_overhead_cosmetics=removed,new_S3_parts=len(added),frozen_R2_rib_parts=sum(map(rib,b['parts'])),frozen_R2_ribs_exact=True,kit_placements_exact=True,contact=contact,artifact_sha256=sha(ROOT/'slice-v2/prototype/guardian-greybox.rbxl'),backup_sha256=sha(ROOT/'slice-v2/prototype/guardian-greybox.pre-s3.rbxl'),source_sha256=sha(ROOT/'prototype/meadow-v4/Section3.luau'),target_sha256=sha(H/'TARGET.png'),visual_acceptance='NOT CLAIMED; blind critics/owner review separate from contracts',live_StudioPassAll='UNKNOWN; all nine not run')
(H/(tag+'-SIGNATURES.json')).write_text(json.dumps(out,indent=2))
print('PASS exact protected and floor/edge signatures; frozen 40 rib parts; retained kits; zero contact errors;',len(added),'S3 parts')
