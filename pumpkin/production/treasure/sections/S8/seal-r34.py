"""Seal final artifact, fresh unchanged tests and explicitly limited visual evidence."""
from pathlib import Path
from collections import Counter
import hashlib,json
H=Path(__file__).resolve().parent;ROOT=H.parents[2]
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
read=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
def log(name):
 b=(H/name).read_bytes()
 return b.decode('utf-16' if b.startswith((b'\xff\xfe',b'\xfe\xff')) else 'utf-8-sig')
main=ROOT/'slice-v2/prototype/guardian-greybox.rbxl';source=ROOT/'prototype/meadow-v4/Section8.luau'
parity=read(H/'PARITY-R34.json');audit=read(H/'AUDIT-r4.json');support=read(H/'SUPPORT-r4.json')
assert parity['state']=='PASS' and parity['canonical_sha256']==sha(main)
assert parity['compiled_O0_O1_O2']==79 and parity['unrelated_sources_preserved']==76
assert parity['serialized_place_exact_after_restoring_three_sources'] and parity['HomeArt_only_Lava_finish']
assert main.read_bytes()==(H/'R4-review.rbxl').read_bytes()
assert source.read_bytes()==(H/'r4-Section8.luau').read_bytes()
assert audit['state']=='PASS' and not audit['physical_penetrations'] and audit['new_parts']==303
assert audit['manifest_sha256']==support['manifest_sha256']==sha(H/'r4.json')
assert support['state']=='PASS' and not support['unsupported'] and support['connected_parts']==285
assert len(support['water_source_joints'])==9 and all(w['attached'] for w in support['water_source_joints'])
for tag in ('r3','r4'):
 r=read(H/('RENDER-'+tag+'.json'))
 assert r['manifest_sha256']==sha(H/(tag+'.json'))
 assert r['module_snapshot_sha256']==sha(H/(tag+'-Section8.luau'))
 for v in read(H/'CAMERAS.json'):assert (H/(tag+'-'+v['name']+'.png')).is_file()
for tag in ('r2-context','r4-context'):
 r=read(H/('RENDER-'+tag+'.json'));assert r['manifest_sha256']==sha(H/(tag+'.json'))
old=[p for p in read(H/'r2-context.json')['parts'] if p.get('section')=='ClientDecorProxy']
new=[p for p in read(H/'r4-context.json')['parts'] if p.get('section')=='ClientDecorProxy']
def fixture(p):
 p=dict(p)
 if p['name']=='ClientDecor_Lava':p.pop('color');p.pop('material')
 return json.dumps(p,sort_keys=True)
assert len(old)==len(new)==2191
assert Counter(map(fixture,old))==Counter(map(fixture,new)),'client proxy geometry/other finishes changed'
assert 'PASS nonzero origin' in log('r34-contracts.log')
assert 'PASS production Arena.reset and overlapping path completion epochs' in log('r34-behavior.log')
assert 'PASS 50-seed actual 3D walking-floor' in log('r34-50-seed.log')
assert 'PASS built binary sources' in log('r34-50-seed.log')
d=read(H/'r34-DROPS.json')
assert d['state']=='PASS' and d['samples']==31824 and not d['failures']
assert len(d['all_routes_executed_exactly_once'])==20
for i,w in enumerate(d['workers'],1):
 assert w['input_sha256']==sha(main) and w['state']=='PASS' and not w['failures']
 assert '194 swaps, 0 fallbacks' in log(f'r34-drop-{i}.log')
 assert (H/f'r34-DROPS-{i}.json').stat().st_mtime>main.stat().st_mtime
for n in ('r34-contracts.log','r34-behavior.log','r34-50-seed.log'):
 assert (H/n).stat().st_mtime>main.stat().st_mtime,'stale final check '+n
files=[main,ROOT/'slice-v2/prototype/guardian-greybox.pre-s8r3.rbxl',source,ROOT/'slice-v2/prototype/Scene.luau',ROOT/'slice-v2/prototype/HomeArt.client.luau']
names=['RESULT.md','RESULT-R2.md','SPEC.md','GAPS-R3.md','GAPS-R4.md','R3-review.rbxl','R4-review.rbxl','PARITY-R34.json','MOUNT-r3.json','MOUNT-r4.json','AUDIT-r3.json','AUDIT-r4.json','SUPPORT-r3.json','SUPPORT-r4.json','REMOVED-r3.json','REMOVED-r4.json','r3-Section8.luau','r4-Section8.luau','r4-Scene.luau','r4-HomeArt.luau','SBS-R3.jpg','SBS-R4.jpg','SBS-R3-phone.jpg','SBS-R4-phone.jpg','CONTEXT-R34.jpg','CONTEXT-R34-phone.jpg','CAMERAS.json','TARGET.png','studio-r2-underside.jpg','RENDER-r3.json','RENDER-r4.json','RENDER-r2-context.json','RENDER-r4-context.json','r2-context-underside.png','r4-context-underside.png','r34-contracts.log','r34-behavior.log','r34-50-seed.log','r34-DROPS.json','r34-drop-1.log','r34-drop-2.log','r34-drop-3.log','r34-DROPS-1.json','r34-DROPS-2.json','r34-DROPS-3.json','build-r34.luau','verify-r34.luau','audit-r34.py','support-r34.py','drop-r34.luau','merge-r34.py','context-r34.luau','render.py','seal-r34.py']
files += [H/n for n in names]+[H.parent/n for n in ('LESSONS.md','SECTIONS.md','SECTION-CHECKLIST.md')]
out=dict(state='PASS offline',visual='REVISIT',rounds_completed=[3,4],total_round_cap=4,canonical_sha256=sha(main),backup_sha256=parity['backup_sha256'],compiled_O0_O1_O2=79,unrelated_sources_preserved=76,changed_sources=['Section8','GreyboxScene: LavaFall size/color','HomeArt: Decor Lava finish'],serialized_place_exact_after_restoring_three_sources=True,protected_and_S1_S7_art_exact=True,physical_penetrations=0,supported_rock_and_plant_parts=285,water_source_joints=9,new_parts=303,rock_facets=76,new_lights=0,all_cosmetics_collision_query_touch_false=True,contact_tolerance=.035,old_all_height_lane_reserve='NOT MET by lower geology; actual lane volumes/headroom preserved; see RESULT',drop_samples=31824,drop_routes=20,drop_failures=0,final_live_Studio='UNKNOWN',Claude_final_review='PENDING',visual_review='self-review; offline native and NativeBlocks client proxies',owner_acceptance='UNKNOWN',commit='NONE',publish='NONE',hashes={str(p.relative_to(ROOT)):sha(p) for p in files})
(H/'FINAL-R34-EVIDENCE.json').write_text(json.dumps(out,indent=2))
print('PASS final artifact/source hashes; contracts/behavior/50 seeds; 31,824 DropSample cases / 20 routes / 0 failures; contact 0; visual REVISIT')
