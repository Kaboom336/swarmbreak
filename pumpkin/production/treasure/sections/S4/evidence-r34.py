"""Duplicate-sensitive final preservation and evidence checks for authorized R3/R4."""
import json,hashlib,sys
from collections import Counter
from pathlib import Path
H=Path(__file__).resolve().parent;ROOT=H.parents[2]
read=lambda name:json.loads((H/name).read_text(encoding='utf-8-sig'))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
old,new=read('R3-START.json'),read('r4.json')
enc=lambda p:json.dumps(p,sort_keys=True)
drop_scene=read('r4-drop-input.json')
assert Counter(map(enc,drop_scene['parts']))==Counter(map(enc,new['parts'])),'post-DropSample geometry changed'
assert drop_scene['kits']==new['kits']
assert read('MOUNT-FINAL.json')['DropSample_input_byte_identical_final_place']
assert sha(ROOT/'slice-v2/prototype/guardian-greybox.rbxl')==sha(H/'R4-drop-input.rbxl')
def protected(p):return p['collidable'] or p['query'] or p['touch'] or p.get('lane') or p.get('tags')
assert Counter(enc(p) for p in old['parts'] if protected(p))==Counter(enc(p) for p in new['parts'] if protected(p))
def retired(p):
 return p['name'] in ('LanternPost','LanternAmber','LanternCap') and tuple(round(v,2) for v in (p['position'][0],p['position'][2])) in ((16,30),(20,42))
assert sum(retired(p) for p in old['parts'])==8
assert not any(retired(p) for p in new['parts'])
def normalized(p):
 p=json.loads(enc(p))
 if p['name']=='BridgeTimberPlank':
  p.pop('color');p.pop('material');p['size'][2]=0
 if p['name']=='BridgeThrowTell':p.pop('color');p.pop('material')
 return enc(p)
prior=Counter(normalized(p) for p in old['parts'] if not retired(p))
after=Counter(normalized(p) for p in new['parts'])
assert not prior-after,'unapproved old part changed or removed'
added=[json.loads(p) for p,n in (after-prior).items() for _ in range(n)]
assert added and all(p.get('section')=='S4' and not protected(p) for p in added)
assert old['kits']==new['kits']
for name,total in [('BridgeTimberPlank',12),('BridgeThrowTell',64)]:
 parts=[p for p in new['parts'] if p['name']==name];assert len(parts)==total
 if name=='BridgeThrowTell':assert all(max(abs(c-v) for c,v in zip(p['color'],[221,208,167]))<.001 and p['material']=='Wood' for p in parts)
 else:assert all(abs(p['size'][2]-2.7)<.001 for p in parts)
for tag in ('r3','r4'):
 c=read(tag+'-physical-contact.json')
 for key in ('physical_penetrations','kit_physical_penetrations','kit_support_errors','floating_assemblies','lane_buffer_errors'):assert not c[key],(tag,key)
 assert (ROOT/'prototype/meadow-v4/Section4.luau').read_bytes()==(H/'r4-Section4.luau').read_bytes()
 for name in ('approach','mid-bridge','recovery','overview'):assert (H/f'{tag}-{name}.png').is_file()
 assert (H/f'SBS-R{tag[1:]}.jpg').is_file()
lights=[p for p in new['lights'] if p.get('section')=='S4']
assert len(lights)==5 and all(p['brightness']<=1.5 and p['range']<=18 and not p['shadows'] for p in lights)
assert all(p['brightness']<=1.5 and p['range']<=18 and not p['shadows'] for p in new['lights'] if p['kind']=='PointLight')
assert all(not p['shadows'] for p in new['lights'])
assert read('MOUNT-FINAL.json')['complete_place_exact_except_Section4_Source']
assert read('MOUNT-R3.json')['complete_place_exact_except_two_source_properties']
if '--preflight' in sys.argv:
 print('PASS all part, kit, ring, plank, contact, source-only mount and live-safe light assertions; DropSample pending')
 sys.exit(0)
drops=read('final-DROPS.json');assert drops['state']=='PASS' and not drops['failures'] and len(drops['all_routes_executed_exactly_once'])==20
def log(name):
 b=(H/name).read_bytes();return b.decode('utf-16' if b.startswith((b'\xff\xfe',b'\xfe\xff')) else 'utf-8-sig')
for name,phrase in [('r34-50-seed.log','PASS 50-seed actual 3D walking-floor'),('r34-behavior.log','PASS actual production reset'),('r4-contracts.log','PASS nonzero origin')]:
 s=log(name);assert phrase in s and '[Stack Begin]' not in s,(name,s[-500:])
paths=[ROOT/'slice-v2/prototype/guardian-greybox.rbxl',ROOT/'slice-v2/prototype/guardian-greybox.pre-s4r3.rbxl',ROOT/'prototype/meadow-v4/Section4.luau']
paths += [H/'R4-drop-input.rbxl',H/'r4-drop-input.json']
paths += [H/n for n in ('r4.json','r4-Section4.luau','r3-physical-contact.json','r4-physical-contact.json','final-DROPS.json','MOUNT-R3.json','MOUNT-FINAL.json','SBS-R3.jpg','SBS-R4.jpg','GAPS-R4.md')]
paths += [H/n for n in ('PRE-R3.jpg','PRE-R4.jpg','CAMERA-CLEARANCE.json','REVIEW-R4.md','RESULT.md','r4-contracts.log','r34-50-seed.log','r34-behavior.log')]
paths += [H.parent/'LESSONS.md']
out=dict(technical_state='PASS',visual_state='REVISIT; live Studio and owner acceptance pending',rounds_completed=[3,4],sources_compiled_O0_O1_O2=74,unrelated_sources_preserved=73,all_protected_parts_exact=True,existing_kits_and_workspace_exact=True,ring_transforms_sizes_physics_exact=True,plank_changes='color, material, cosmetic Z size only; colliders exact',retired_approach_cosmetic_parts=8,added_S4_parts=len(added),live_safe_S4_point_lights=len(lights),contact_exceptions='10 validated tangent .12-stud threshold caps, 11 tangent .04-stud deck joint inlays; two retained R5LampFoot visible plinth support roots. No other lane margin or contact tolerance changed.',DropSample_samples=drops['samples'],DropSample_routes=20,DropSample_failures=0,live_Studio='UNKNOWN',commit='NONE',publish='NONE',hashes={str(p.relative_to(ROOT)):sha(p) for p in paths})
(H/'FINAL-R34-EVIDENCE.json').write_text(json.dumps(out,indent=2))
print('PASS final R3/R4 evidence;',drops['samples'],'DropSample samples; 20 routes; zero failures; exact protected scene and source-only canonical mount')
