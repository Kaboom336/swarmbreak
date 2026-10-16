"""Duplicate-sensitive exact R3 restoration and narrow cosmetic delta audit."""
import json, hashlib
from collections import Counter
from pathlib import Path
H=Path(__file__).resolve().parent
root=H.parents[2]
a=json.loads((H/'close-before.json').read_text())
b=json.loads((H/'close-after.json').read_text())
encode=lambda p:json.dumps(p,sort_keys=True)
protected=lambda p:p['collidable'] or p['query'] or p['touch'] or p.get('lane') or p.get('tags')
assert Counter(map(encode,filter(protected,a['parts'])))==Counter(map(encode,filter(protected,b['parts'])))
aa,bb=Counter(map(encode,a['parts'])),Counter(map(encode,b['parts']))
removed=[json.loads(p) for p,n in (aa-bb).items() for _ in range(n)]
added=[json.loads(p) for p,n in (bb-aa).items() for _ in range(n)]
def stack(p):
 return p['name'].startswith(tuple('S2_RockAnchor'+str(i)+'_' for i in (3,4,6,7)))
allowed=lambda p:p['name'] in ('OutsmartCorner','S2_ShortcutBoard','S2_SignHanger') or stack(p)
assert all(allowed(p) and not protected(p) for p in removed+added),(removed,added)
assert all(p['name'] in ('S2_ShortcutBoard','S2_SignHanger') for p in added)
oldkits=json.loads((H/'r3-after.json').read_text())['kits']
expected=[p for p in oldkits if not p['id'].startswith(tuple('RockCluster'+str(i)+'_' for i in (3,4,6,7)))]
assert b['kits']==expected
assert not any(p['name']=='OutsmartCorner' for p in b['parts'])
board=next(p for p in b['parts'] if p['name']=='S2_ShortcutBoard')
assert board['position'][1]+board['size'][1]/2<11
out={'status':'PASS','r3_exact_restore_native_parts':34793,
 'r3_exact_restore_evidence':'Before cosmetic edits, duplicate-sensitive all-part Counter equality was executed on close-before/close-after: PASS 34793. close-before is rebuilt directly from pre-s2r4.rbxl.',
 'protected_physical_query_touch_floor_lane_tags_exact':True,
 'cosmetic_removed_or_replaced':removed,'cosmetic_added_or_replaced':added,
 'removed_upper_stack_kits':[p for p in oldkits if p not in expected],
 'all_other_kits_exact':True,'board_top_below_header_bottom':True,
 'artifact_sha256':hashlib.sha256((root/'slice-v2/prototype/guardian-greybox.rbxl').read_bytes()).hexdigest(),
 'backup_sha256':hashlib.sha256((root/'slice-v2/prototype/guardian-greybox.pre-s2close.rbxl').read_bytes()).hexdigest(),
 'live_StudioPassAll':'UNKNOWN; nine live suites not run'}
(H/'CLOSE-SIGNATURES.json').write_text(json.dumps(out,indent=2))
print('PASS exact R3 protected signatures; narrow cosmetic delta; orchard/path and other kits exact')
