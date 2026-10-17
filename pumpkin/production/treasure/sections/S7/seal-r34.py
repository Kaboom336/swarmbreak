from pathlib import Path
import json,hashlib
H=Path(__file__).resolve().parent;root=H.parents[2]
read=lambda n:json.loads((H/n).read_text(encoding='utf-8-sig'))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def log(n):
 b=(H/n).read_bytes();return b.decode('utf-16' if b[:2] in (b'\xff\xfe',b'\xfe\xff') else 'utf-8-sig')
canonical=root/'slice-v2/prototype/guardian-greybox.rbxl'
assert canonical.read_bytes()==(H/'R4-review.rbxl').read_bytes()
assert read('MOUNT-r4.json')['canonical_sha256']==sha(canonical)
for stage in ('r3','r4'):
 m=read('MOUNT-'+stage+'.json');a=read('SIGNATURES-'+stage+'.json');c=read(stage+'-physical-contact.json')
 assert m['unrelated_serialized_place_exact'] and m['workspace_exact'] and m['compiled_O0_O1_O2']==78
 assert a['contact_errors']==0 and a['bearing_footprint_probes']==575
 for key in ('physical_penetrations','kit_physical_penetrations','kit_support_errors','floating_assemblies','lane_buffer_errors'):assert not c[key],(stage,key)
 assert read('RENDER-'+stage+'.json')['views']==read('CAMERAS.json')
 for v in read('CAMERAS.json'):assert (H/(stage+'-'+v['name']+'.png')).stat().st_mtime>(H/(stage+'-visual.json')).stat().st_mtime
for name,path in [('Section7','prototype/meadow-v4/Section7.luau'),('SummitAcorn','prototype/meadow-v4/SummitAcorn.luau'),('HomeArt','slice-v2/prototype/HomeArt.client.luau')]:
 assert (H/('r4-'+name+'.luau')).read_bytes()==(root/path).read_bytes()
for name,phrase in [('r34-contracts.log','PASS nonzero origin'),('r34-behavior.log','PASS production Arena.reset and overlapping path completion epochs'),('r34-50-seed.log','PASS 50-seed actual 3D walking-floor')]:
 s=log(name);assert phrase in s and '[Stack Begin]' not in s,(name,s[-800:])
d=read('final-DROPS.json');assert d['state']=='PASS' and d['samples']==31824 and not d['failures']
assert len(d['all_routes_executed_exactly_once'])==20
assert all(w['input_sha256']==sha(canonical) for w in d['workers'])
out=dict(technical_state='PASS offline',visual_state='REVISIT',rounds_completed=[3,4],canonical_sha256=sha(canonical),backup_sha256=sha(root/'slice-v2/prototype/guardian-greybox.pre-s7r3.rbxl'),changed_sources=['Section7','HomeArt'],new_source='SummitAcorn',unrelated_serialized_place_exact=True,protected_native_parts_exact_except_authorized_nest_material_color=True,loot_root_and_Gameplay_Greybox_Config_sources_unchanged=True,contact_errors=0,bearing_probes_per_round=575,DropSample_cases=31824,DropSample_routes=20,DropSample_failures=0,live_Studio='UNKNOWN',independent_final_Claude_review='PENDING',owner_acceptance='UNKNOWN',commit='NONE',publish='NONE')
files=[canonical,root/'slice-v2/prototype/guardian-greybox.pre-s7r3.rbxl',root/'prototype/meadow-v4/Section7.luau',root/'prototype/meadow-v4/SummitAcorn.luau',root/'slice-v2/prototype/HomeArt.client.luau']
files += [p for p in H.iterdir() if p.is_file() and (p.name.startswith(('r3','r4','MOUNT-','SIGNATURES-r3','SIGNATURES-r4','SBS-R3','SBS-R4','GAPS-R3','GAPS-R4','final-DROP')) or p.name=='RESULT.md')]
out['hashes']={str(p.relative_to(root)):sha(p) for p in files}
(H/'FINAL-R34-EVIDENCE.json').write_text(json.dumps(out,indent=2));print('PASS R3/R4 evidence sealed; visual REVISIT pending live review')
