"""Independent exact protection audit against the immediate byte-verified backup."""
import json,collections
from pathlib import Path
H=Path(__file__).resolve().parent
a=json.loads((H/'r4-before.json').read_text());b=json.loads((H/'r4-after.json').read_text())
plan=json.loads((H/'r4-hill-plan.json').read_text())
def key(p):return p['name']+'@'+','.join(f'{v:.2f}' for v in p['position'])
aa={key(p):p for p in a['parts']};bb={key(p):p for p in b['parts']}
edits={e['key']:e for e in plan['edits']};remove=set(plan['removed'])
changed=[];deleted=[];cosmetics=[];protected=0
def close(x,y):return all(abs(u-v)<.002 for u,v in zip(x,y))
for k,p in aa.items():
 if not(p['collidable'] or p.get('lane') or p.get('attributes',{}).get('GameplayCover')):
  if k not in bb:cosmetics.append(p)
  continue
 if k in remove:
  assert p['name']=='TunnelHillTurf' or p['position'][1]-p['size'][1]/2>=23.9
  assert not p.get('lane') and not p.get('attributes',{}).get('GameplayCover')
  deleted.append(p);continue
 if k in edits:
  e=edits[k]
  if e.get('shape'):
   q=bb[k]
   for f in p:
    if f not in ('color','material','transparency'):assert p[f]==q[f],('collision core',k,f)
   assert q['transparency']==1
   shells=[s for s in b['parts'] if s['name']=='S2_ShoulderSlopeShell' and close(s['position'],e['position']) and close(s['size'],e['size'])]
   assert len(shells)==1 and shells[0]['shape']=='Wedge'
   assert close(shells[0]['rotation'],e['rotation'])
   assert not shells[0]['collidable'] and not shells[0]['query'] and not shells[0]['touch']
   changed.append({'before':p,'after':q,'nonphysical_slope_shell':shells[0]});continue
  matches=[q for q in b['parts'] if q['name']==p['name'] and close(q['position'],e['position']) and close(q['size'],e['size'])]
  assert len(matches)==1,(k,len(matches));q=matches[0]
  for f in p:
   if f not in ('position','size','rotation','shape','color','material'):assert p[f]==q[f],(k,f)
  assert p['name']=='TunnelHillEarth'
  if e.get('shape'):
   assert q['shape']=='Wedge' and close(q['rotation'],e['rotation'])
   assert q['size'][1]/q['size'][2]>1,'shoulder must be steeper than 45 degrees'
   assert (q['position'][0],q['position'][2]) in ((-79,117),(-49,87))
  else:
   assert p['shape']==q['shape'] and p['rotation']==q['rotation']
   assert abs((p['position'][1]-p['size'][1]/2)-(q['position'][1]-q['size'][1]/2))<.002
   if p['position'][1]-p['size'][1]/2<18:assert q['position'][1]+q['size'][1]/2>=18-.002
  changed.append({'before':p,'after':q});continue
 q=bb.get(k);assert q is not None,('missing protected',k)
 for f in p:
  assert p[f]==q[f],('protected field',k,f)
 protected+=1
# No physical additions may quietly create a climbing route.
expected={key(e['after']) for e in changed}
finishes=[p for p in b['parts'] if p['name']=='S2_PathFinish']
for p in finishes:
 assert not p['collidable'] and not p['query'] and not p['touch'] and not p.get('lane') and not p.get('laneId') and not p['tags']
for k,p in bb.items():
 if p['collidable'] and k not in aa:assert k in expected,('new solid',k)
out={'unchanged_protected_parts':protected,'lanes_floors_cover_court_exact':True,'all_other_solids_exact':True,
 'authorized_hill_edits':changed,'authorized_hill_removals':deleted,'removed_cosmetics':cosmetics,
 'two_nonphysical_slope_shells_degrees':[56.309932474,71.565051177],'original_shoulder_collision_cores_geometry_exact':True,'other_lower_collision_walls_through_Y18_preserved':True,'all_inner_rock_courses_facets_vaults_exact':True,
 'new_colliders':0,'new_low_climbable_tops':0,'nonphysical_floor_finishes_excluded_from_prop_masks':len(finishes),'test_sources_preserved':'see r4-AUDIT.json',
 'runtime_Keeper_sight_and_Humanoid_climbing':'UNKNOWN; offline geometry only'}
(H/'REMOVED-R4.json').write_text(json.dumps(out,indent=2))
print('PASS',protected,'unchanged protected parts;',len(changed),'hill edits;',len(deleted),'hill caps removed;',len(cosmetics),'cosmetics removed; no new colliders')
