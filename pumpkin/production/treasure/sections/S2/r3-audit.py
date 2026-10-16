"""Compare rebuilt world to immediate R2 backup, excluding only authorized wall palettes."""
import json,collections
from pathlib import Path
H=Path(__file__).resolve().parent
a=json.loads((H/'r3-before.json').read_text());b=json.loads((H/'r3-after.json').read_text())
def key(p):return p['name'],*p['position'],*p['rotation'],*p['size']
aa={key(p):p for p in a['parts']};bb={key(p):p for p in b['parts']}
removed=[];palettes=[];restyled=[]
allowed=('TunnelHillEarth','TunnelRockCourse','TunnelInnerRockFacet','SolidMountainStone','R5BoulderFoot')
for k,p in aa.items():
 q=bb.get(k)
 if p['collidable'] or p.get('lane') or p.get('attributes',{}).get('GameplayCover'):
  assert q is not None,('removed protected',p['name'])
  for field in p:
   if field not in ('color','material'):assert p[field]==q[field],('protected field',field,p['name'])
  if (p['color'],p['material'])!=(q['color'],q['material']):
   assert not p.get('lane') and p['name'] in allowed,('protected palette',p['name'])
   palettes.append({'name':p['name'],'position':p['position'],'before_color':p['color'],'after_color':q['color'],'before_material':p['material'],'after_material':q['material']})
 elif q is None:removed.append(p)
 elif (p['color'],p['material'])!=(q['color'],q['material']):restyled.append({'name':p['name'],'position':p['position'],'before':p['color'],'after':q['color'],'material':q['material']})
for k,p in bb.items():
 if k not in aa:assert not p['collidable'] and not p.get('lane'),('new physical',p['name'])
out={'backup':'slice-v2/prototype/guardian-greybox.pre-s2r3.rbxl','protected_solids_all_other_fields_equal':True,'lanes_and_floor_tags_exactly_equal':True,'wall_palette_edits':palettes,'removed_or_replaced_cosmetics':removed,'restyled_cosmetics':restyled,'removed_counts':dict(collections.Counter(p['name'] for p in removed))}
(H/'REMOVED-R3.json').write_text(json.dumps(out,indent=2))
print('PASS protected geometry/query/tags/attributes; lanes and floor palettes unchanged;',len(palettes),'wall palettes;',len(removed),'replaced/removed cosmetics;',len(restyled),'cosmetic palettes')
