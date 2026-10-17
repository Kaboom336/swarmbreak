from pathlib import Path
import json,hashlib
H=Path(__file__).resolve().parent;ROOT=H.parents[2]
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
read=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
main=ROOT/'slice-v2/prototype/guardian-greybox.rbxl';backup=main.with_name('guardian-greybox.pre-s8.rbxl');source=ROOT/'prototype/meadow-v4/Section8.luau'
assert main.read_bytes()==(H/'R2-review.rbxl').read_bytes()
assert source.read_bytes()==(H/'r2-Section8.luau').read_bytes()
for tag,count in [('r1',237),('r2',315)]:
 a=read(H/('AUDIT-'+tag+'.json'));m=read(H/('MOUNT-'+tag+'.json'))
 assert a['state']=='PASS' and a['new_parts']==count and not(a['physical_penetrations'] or a['lane_buffer_errors'] or a['unsupported'])
 assert m['compiled_O0_O1_O2']==79 and m['unrelated_sources_preserved']==78 and m['workspace_exact'] and m['all_protected_signatures_exact']
 for v in read(H/'CAMERAS.json'):assert (H/(tag+'-'+v['name']+'.png')).stat().st_mtime>backup.stat().st_mtime
assert read(H/'AUDIT-r2.json')['frozen_R1']
r=read(H/'RENDER-r2.json')
assert r['manifest_sha256']==sha(H/'r2.json') and r['module_snapshot_sha256']==sha(source)
for l in read(H/'r2.json')['lights']:
 if l['kind']=='PointLight':assert l['brightness']<=1.5 and l['range']<=18 and not l['shadows']
def log(n):
 b=(H/n).read_bytes();return b.decode('utf-16' if b.startswith((b'\xff\xfe',b'\xfe\xff')) else 'utf-8-sig')
assert 'PASS nonzero origin' in log('contracts.log')
assert 'PASS 50-seed actual 3D' in log('50-seed.log')
assert 'PASS production Arena.reset and overlapping path completion epochs' in log('behavior.log')
assert read(H/'CONTRACTS.json')['offset_origin_once']
d=read(H/'final-DROPS.json');assert d['state']=='PASS' and d['samples']==31824 and not d['failures']
assert len(d['all_routes_executed_exactly_once'])==20
assert all(w['input_sha256']==sha(main) for w in d['workers'])
files=[main,backup,source,H/'TARGET.png',H/'TARGET-PROMPT.md',H/'CAMERAS.json',H/'PRE-R1.jpg',H/'PRE-R2.jpg',H/'SBS-R1.jpg',H/'SBS-R2.jpg',H/'AUDIT-r1.json',H/'AUDIT-r2.json',H/'MOUNT-r1.json',H/'MOUNT-r2.json',H/'contracts.log',H/'behavior.log',H/'50-seed.log',H/'final-DROPS.json',H/'RENDER-r2.json',H/'CRITIC-R1.md',H/'CRITIC-R2.md']
files += [H/n for n in ('R1-review.rbxl','R2-review.rbxl','GAPS-R1.md','GAPS-R2.md','RESULT.md','SPEC.md','CRITIC-TECHNICAL.md','build.luau','audit.py','render.py','contracts.luau','drop.luau','REMOVED-r1.json','REMOVED-r2.json')]
out=dict(state='PASS offline',visual='REVISIT',rounds_completed=[1,2],stop_before_rounds=[3,4],canonical_sha256=sha(main),backup_sha256=sha(backup),source_sha256=sha(source),new_source_only='Section8',unrelated_sources_preserved=78,compiled_O0_O1_O2=79,serialized_place_exact_after_removing_Section8=True,protected_and_other_art_exact_except_documented_cosmetic_replacements_and_palette=True,must_keep_warm_paving_edge_stones_exact=True,contact_errors=0,all_height_margin=1,all_R1_facets_frozen=True,DropSample_cases=31824,DropSample_routes=20,DropSample_failures=0,live_Studio='UNKNOWN',Claude_review='PENDING',owner_acceptance='UNKNOWN',commit='NONE',publish='NONE',hashes={str(p.relative_to(ROOT)):sha(p) for p in files})
(H/'BACKUP.json').write_text(json.dumps(dict(byte_verified_before_first_mount=True,backup_sha256=sha(backup),path=str(backup.relative_to(ROOT))),indent=2))
(H/'FINAL-EVIDENCE.json').write_text(json.dumps(out,indent=2));print(json.dumps({k:v for k,v in out.items() if k!='hashes'},indent=2))
