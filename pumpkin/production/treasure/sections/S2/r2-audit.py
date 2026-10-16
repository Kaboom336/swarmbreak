"""Immediate backup comparison; removals, palettes and protected solids are explicit."""
import json,collections,hashlib
from pathlib import Path
import numpy as np
H=Path(__file__).resolve().parent
a=json.loads((H/'r2-before.json').read_text());b=json.loads((H/'r2-after.json').read_text())
def key(p):return (p['name'],*p['position'],*p['rotation'],*p['size'])
aa={key(p):p for p in a['parts']};bb={key(p):p for p in b['parts']}
removed=[];palettes=[];restyled=[]
for k,p in aa.items():
 q=bb.get(k)
 if p['collidable'] or p.get('lane'):
  assert q is not None,('removed solid',p['name'])
  for field in p:
   if field not in ('color','material'):assert p[field]==q[field],('solid field changed',field,p['name'])
  if p['color']!=q['color'] or p['material']!=q['material']:
   assert not p.get('lane') and p['name'] in ('TunnelHillEarth','TunnelRockCourse','TunnelInnerRockFacet','SolidMountainStone','R5BoulderFoot')
   palettes.append({'name':p['name'],'position':p['position'],'before_color':p['color'],'after_color':q['color'],'before_material':p['material'],'after_material':q['material']})
 elif q is None:
  assert not p.get('attributes',{}).get('GameplayCover'),p['name']
  removed.append(p)
 elif p['color']!=q['color'] or p['material']!=q['material']:restyled.append({'name':p['name'],'position':p['position'],'before':p['color'],'after':q['color']})
for k,p in bb.items():
 if k not in aa:assert not p['collidable'] and not p.get('lane'),('new solid',p['name'])
summary={'backup':'slice-v2/prototype/guardian-greybox.pre-s2r2.rbxl','removed_noncollidable_parts':removed,'removed_count':len(removed),'removed_counts_by_name':dict(collections.Counter(p['name'] for p in removed)),'restyled_cosmetics':restyled,'physical_color_material_only':palettes,'protected_solids_all_other_fields_equal':True,'floor_palette_equal':True,'source_of_scope':'Owner S2 round 2 widened scope, two locked cameras; revealed cosmetic clumps removed as complete groups.'}
(H/'REMOVED-R2.json').write_text(json.dumps(summary,indent=2))
print('PASS protected geometry/query/tags/attributes; removed',len(removed),'cosmetics; recolored',len(palettes),'solids;',len(restyled),'cosmetic palettes')
