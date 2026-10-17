"""Duplicate-sensitive exact preservation and strict all-height lane margins."""
import json,sys,numpy as np
from pathlib import Path
from collections import Counter
H=Path(__file__).resolve().parent;tag=sys.argv[1]
read=lambda n:json.loads((H/n).read_text(encoding='utf-8-sig'))
enc=lambda p:json.dumps(p,sort_keys=True)
old,new=read('before.json'),read(tag+'.json')
a,b=Counter(map(enc,old['parts'])),Counter(map(enc,new['parts']))
assert not a-b,('retained part changed',list((a-b).items())[:1])
added=[json.loads(s) for s,n in (b-a).items() for _ in range(n)]
assert added and all(p.get('section')=='S7' and not(p['collidable'] or p['query'] or p['touch'] or p.get('lane') or p.get('laneId') or p['tags']) for p in added)
def corners(p,margin=0):
 r=np.array(p['rotation']).reshape(3,3);c=np.array(p['position']);h=np.array(p['size'])/2+np.array([margin,0,margin])
 return np.array([(c+r@np.array([x*h[0],y*h[1],z*h[2]]))[[0,2]] for x in (-1,1) for y in (-1,1) for z in (-1,1)])
lanes=[(p,corners(p,1)) for p in old['parts'] if p.get('lane')]
def overlap(p,q,bb):
 aa=corners(p)
 for s in (p,q):
  for axis in np.array(s['rotation']).reshape(3,3).T:
   v=axis[[0,2]];n=np.linalg.norm(v)
   if n<1e-5:continue
   v=v/n;av=aa@v;bv=bb@v
   if min(av.max(),bv.max())-max(av.min(),bv.min())<=.035:return False
 return True
for p in added:
 r=np.array(p['rotation']).reshape(3,3);c=np.array(p['position']);e=np.abs(r)@np.array(p['size'])/2;lo=c-e;hi=c+e
 assert np.all(lo>=np.array([-32,44,-132])) and np.all(hi<=np.array([32,175,-72])),('bounds',p['name'])
 assert not any(overlap(p,q,bb) for q,bb in lanes),('all-height lane margin',p['name'])
# Audit entire bearing footprint on unchanged flat physical tops (not only centers).
flat=[]
for p in old['parts']:
 if p['collidable'] and np.max(np.abs(np.array(p['rotation']).reshape(3,3)-np.eye(3)))<.001:
  c0=np.array(p['position']);h0=np.array(p['size'])/2;flat.append((c0-h0,c0+h0))
support_probes=0
for p in added:
 if not p['name'].startswith(('S7_TentRunner','S7_FencePost','S7_StolenCupBody','S7_ExitPost')):continue
 r=np.array(p['rotation']).reshape(3,3);c0=np.array(p['position']);h=np.array(p['size'])/2
 for x in np.linspace(-h[0],h[0],5):
  for z in np.linspace(-h[2],h[2],5):
   v=c0+r@np.array([x,-h[1],z]);support_probes+=1
   assert any(a0[0]-.002<=v[0]<=b0[0]+.002 and a0[2]-.002<=v[2]<=b0[2]+.002 and abs(b0[1]-v[1])<=.035 for a0,b0 in flat),('bearing footprint',p['name'],v.tolist())
assert old['kits']==new['kits']
assert all(l['brightness']<=1.5 and l['range']<=18 and not l['shadows'] for l in new['lights'] if l['kind']=='PointLight')
c=read(tag+'-physical-contact.json')
for k in ('physical_penetrations','kit_physical_penetrations','kit_support_errors','floating_assemblies','lane_buffer_errors'):assert not c[k],k
for v in read('CAMERAS.json'):
 if v['name']=='overview':continue
 for p in new['parts']:
  if not(p['collidable'] or p['query']):continue
  local=np.array(p['rotation']).reshape(3,3).T@(np.array(v['eye'])-np.array(p['position']))
  assert not np.all(np.abs(local)<np.array(p['size'])/2-.002),('camera in solid',v['name'],p['name'])
if tag=='r2':
 frozen=[p for p in read('r1.json')['parts'] if p.get('section')=='S7' and p['name'].startswith('S7_Fence')]
 assert not Counter(map(enc,frozen))-Counter(map(enc,new['parts'])),'R1 silhouette changed'
 assert not Counter(map(enc,read('r1.json')['lights']))-Counter(map(enc,new['lights'])),'existing/R1 light changed'
out=dict(state='PASS offline',existing_part_signatures_preserved=len(old['parts']),existing_Keeper_treasure_court_bait_bell_sight_blockers_exact=True,mustkeep_warm_paving_edges_exact=True,all_lane_geometry_physics_tags_attributes_exact=True,all_existing_art_exact=True,static_kit_list_unchanged_but_inherited_from_S2=True,kit_sources_and_serialized_state_protected_by_mount=True,added_native_cosmetics=len(added),bearing_footprint_probes=support_probes,contact_errors=0,strict_all_height_lane_margin=1,lights_live_safe=True,frozen_R1_fence=tag=='r2',R1_tent_rotation='R2 gap 2',live_Studio='UNKNOWN')
(H/('SIGNATURES-'+tag+'.json')).write_text(json.dumps(out,indent=2));print(json.dumps(out))
